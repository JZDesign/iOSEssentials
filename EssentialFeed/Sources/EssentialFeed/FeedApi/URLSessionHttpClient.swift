//
//  URLSessionHttpClient.swift
//  
//
//  Created by Jacob Rakidzich on 4/2/23.
//

import Foundation

public class URLSessionHttpClient: HttpClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL, completion: @escaping (HttpClient.Result) -> Void) {
        session.dataTask(with: url, completionHandler: { data, response, error in
            completion(Result {
                if let error {
                    throw error
                } else if let data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }).resume()
    }
    
    private class UnexpectedValuesRepresentation: Error {}
}
