import CoreData

public class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle = .feedCache) throws {
        container = try NSPersistentContainer.load(moduleName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
//         TODO:
    }
    
    public func insert(_ items: [EssentialFeed.LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timeStamp
                managedCache.feed = NSOrderedSet(array: items.map { local in
                    let managed = ManagedFeedImage(context: context)
                    managed.id = local.id
                    managed.imageDescription = local.description
                    managed.location = local.location
                    managed.url = local.url
                    return managed
                })
                
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        context.perform { [weak self] in
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false
                if let cache = try context.fetch(request).first {
                    let feed = cache.feed
                        .compactMap { $0 as? ManagedFeedImage }
                        .map {
                            LocalFeedImage(
                                id: $0.id,
                                description: $0.imageDescription,
                                location: $0.location,
                                url: $0.url
                            )
                        }
                    completion(.found(feed: feed, timeStamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

// MARK: - CoreData extensions

public extension Bundle {
    static let feedCache: Bundle = .module
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
            case modelNotFound
            case failedToLoadPersistentStores(Swift.Error)
        }
    static func load(moduleName: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let objectModel = NSManagedObjectModel.with(name: moduleName, in: bundle) else {
            throw LoadingError.modelNotFound
        }
    
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: "FeedStore", managedObjectModel: objectModel)
        container.persistentStoreDescriptions = [description]
    
        var loadError: Error?

        container.loadPersistentStores { _, error in
            if let error {
                loadError = error
            }
        }

        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }

        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        bundle.url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
