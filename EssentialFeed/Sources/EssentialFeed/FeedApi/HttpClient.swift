//
//  HttpClient.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

public typealias HttpClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HttpClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
