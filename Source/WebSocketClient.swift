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


import Foundation;
import MedKitCore;


/**
 WebSocket HTTP client.
 */
class WebSocketClient: WebSocket {
    
    private var http: HTTPClient;

    /**
     Constructor
     
     - Parameters:
        - http:
     */
    init(http: HTTPClient)
    {
        self.http = http;
    }
    
    /**
     Start WebSocket on connection.
     
     */
    func upgrade(_ host: String, _ target: String, _ proto: String, completionHandler completion: @escaping (Error?)->Void)
    {
        let key     = generateKey(count: 16);
        let request = upgrade(host, target, proto, key);
        
        http.send(request) { response, httpError in
            var error: Error? = httpError;
            
            if error == nil {
                if !self.verify(response!, proto, key) {
                    error = MedKitError.Failed;
                }
            }

            completion(error);
        }
    }
    
    /**
     Generate key.
     
     This method is used to generate a random key of count bytes.
     
     - Parameters:
        - count: The size of the key in bytes.
     - Returns:
        Returns a base64 encoded string of the key.
     */
    private func generateKey(count: Int) -> String
    {
        return SecurityManagerShared.main.randomBytes(count: count).base64EncodedString;
    }
    
    /**
     Upgrade
     */
    private func upgrade(_ host: String, _ target: String, _ proto: String, _ key: String) -> HTTPRequest
    {
        let request = HTTPRequest(method: HTTPMethod.Get, url: target);
        
        request.setField(key: HTTPHeader.Connection,           value: Upgrade);
        request.setField(key: HTTPHeader.Upgrade,              value: WebSocket);
        request.setField(key: HTTPHeader.Host,                 value: host);
        request.setField(key: HTTPHeader.SecWebSocketKey,      value: key);
        request.setField(key: HTTPHeader.SecWebSocketProtocol, value: proto);
        request.setField(key: HTTPHeader.SecWebSocketVersion,  value: Version);
        
        return request;
    }
 
    /**
     Verify upgrade response.
     */
    private func verify(_ response: HTTPResponse, _ proto: String, _ key: String) -> Bool
    {
        let check  = Check();
        let sha1  = SecurityManagerShared.main.digest(using: .SHA1);
        var accept : String;
        
        // generate expected accept response
        sha1.update(string: key);
        sha1.update(string: Key);
        accept = sha1.final().base64EncodedString;
        
        check += (response.status == .SwitchingProtocols);
        check += (response.getField(key: HTTPHeader.Connection)           == Upgrade);
        check += (response.getField(key: HTTPHeader.Upgrade)              == WebSocket);
        check += (response.getField(key: HTTPHeader.SecWebSocketAccept)   == accept);
        check += (response.getField(key: HTTPHeader.SecWebSocketProtocol) == proto);
        check += (response.getField(key: HTTPHeader.SecWebSocketVersion)  == Version);
 
        return check.value;
    }
 
}


// End of File
