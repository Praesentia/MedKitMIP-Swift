/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2016-2018 Jon Griffeth
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 -----------------------------------------------------------------------------
 */


import Foundation
import MedKitCore


/**
 HTTP Client
 */
class HTTPClient: ProtocolStackBase {
    
    typealias CompletionHandler = ((HTTPResponse?, Error?) -> Void)
    
    private var requestQueue = [CompletionHandler]()
    private var input        = DataQueue()
    private var reader       = HTTPReader()
    
    /**
     Send request.
     */
    func send(_ request: HTTPRequest, completionHandler completion: @escaping (HTTPResponse?, Error?)->Void)
    {
        if let data = request.toData() {
            requestQueue.append(completion)
            port.send(data)
        }
        else {
            DispatchQueue.main.async { completion(nil, MedKitError.failed) }
        }
    }
    
    /**
     Pop completion handler for oldest request.
     */
    private func pop() -> CompletionHandler?
    {
        var completion: CompletionHandler?
        
        if !requestQueue.isEmpty {
            completion = requestQueue[0]
            requestQueue.removeFirst(1)
        }
        
        return completion
    }
    
    // MARK: - PortDelegate
    
    /**
     Port did receive data.
     */
    override func port(_ port: MedKitCore.Port, didReceive data: Data)
    {
        input.append(data)
        
        while let response = reader.getResponse(from: input) {
            if let completion = pop() {
                completion(response, nil)
            }
        }
    }
    
}


// End of File
