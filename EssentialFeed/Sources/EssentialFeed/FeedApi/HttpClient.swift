//
//  HttpClient.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation


public protocol HttpClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    /// The completeion handler can be invoked on any thread
    /// Clients are responsible to dispatch to the appropriate threads if needed.
    func get(from url: URL, completion: @escaping (HttpClient.Result) -> Void)
}
