/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2016-2017 Jon Griffeth
 
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
 HTTP Server Router
 */
protocol HTTPServerRouter: class {
    
    func server(_ server: HTTPServer, didReceive request: HTTPRequest, completionHandler completion: (HTTPResponse?, Error?) -> Void)
    
}

/**
 HTTP Server
 */
class HTTPServer: ProtocolStackBase {
    
    // MARK: - Properties
    weak var messageHandler: HTTPServerRouter?

    // MARK: - Private
    private var input  = DataQueue()
    private var reader = HTTPReader()
    
    /**
     Receive request.
     */
    private func receive(_ request: HTTPRequest)
    {
        messageHandler?.server(self, didReceive: request) { response, error in
            if let data = response?.toData() {
                self.port.send(data)
            }
        }
    }
    
    // MARK: - PortDelegate
    
    /**
     Port did receive data.
     */
    override func port(_ port: MedKitCore.Port, didReceive data: Data)
    {
        input.append(data)
        
        while let request = reader.getRequest(from: input) {
            receive(request)
        }
    }
    
}


// End of File
