//
//  HttpClient.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

public typealias HttpClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HttpClient {
    /// The completeion handler can be invoked on any thread
    /// Clients are responsible to dispatch to the appropriate threads if needed.
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
