import CoreData

public class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle = .feedCache) throws {
        container = try NSPersistentContainer.load(moduleName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache
                    .find(in: context)
                    .map(context.delete)
                    .map(context.save)
            })
        }
    }
    
    public func insert(_ items: [EssentialFeed.LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timeStamp
                managedCache.feed = ManagedFeedImage.images(from: items, in: context)
                try context.save()
                completion(.success(()))
            } catch {
                context.reset()
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.find(in: context).map {
                    CachedFeed(feed: $0.localFeed, timeStamp: $0.timestamp)
                }
            })
        }
    }

    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeed: [LocalFeedImage] {
        feed
            .compactMap { $0 as? ManagedFeedImage }
            .map(\.local)
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    internal static func newUniqueInstance(
        in context: NSManagedObjectContext
    ) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }

}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    static func images(from localFeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            return managed
        })
    }
    
    var local: LocalFeedImage {
        LocalFeedImage(
            id: id,
            description: imageDescription,
            location: location,
            url: url
        )

    }
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
