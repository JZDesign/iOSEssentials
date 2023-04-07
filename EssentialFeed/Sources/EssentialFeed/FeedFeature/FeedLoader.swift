//
//  FeedLoader.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
