//
//  REST.swift
//  Carangas
//
//  Created by Vinícius Tinajero Salomão on 28/09/20.
//  Copyright © 2020 Eric Brito. All rights reserved.
//

import Foundation

enum CarError {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}

class REST {
    
    private static let basePath = "https://carangas.herokuapp.com/cars"
    
//    private static let session = URLSession.shared
    
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        config.timeoutIntervalForRequest = 120.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    private static let session  = URLSession(configuration: configuration)
    
    class func loadCars(onComplete: @escaping ([Car]) -> Void, onError: @escaping (CarError) -> Void) {
        guard let url = URL(string: basePath) else {
            onError(.url)
            return
        }
        
        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error) in
            
            if error == nil {
                
                guard let response = response as? HTTPURLResponse else {
                    onError(.noResponse)
                    return
                }
                if response.statusCode == 200 {
                    
                    guard let data = data else {return}
                    
                    do {
                        
                        let cars = try JSONDecoder().decode([Car].self, from: data)
                        
                        onComplete(cars)
                        
                    } catch {
                        print(error.localizedDescription)
                        onError(.invalidJSON)
                    }
                    
                } else {
                    onError(.responseStatusCode(code: response.statusCode))
                }
                
                
            } else {
                onError(.taskError(error: error!))
            }
            
        }
        
        dataTask.resume()
    }
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void) {
        guard let url = URL(string: basePath) else {
            onComplete(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let json = try? JSONEncoder().encode(car) else {
            onComplete(false)
            return
        }
        
        request.httpBody = json
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, response.statusCode == 200, let _ = data else {
                    onComplete(false)
                    return
                }
                
                onComplete(true)
                
            } else {
                onComplete(false)
                return
            }
        }
        
        dataTask.resume()
        
    }
    
}
