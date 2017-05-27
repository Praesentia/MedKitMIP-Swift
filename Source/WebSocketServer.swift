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
 WebSocket HTTP server.
 */
class WebSocketServer: WebSocket, HTTPServerRouter {
    
    private var http: HTTPServer;
    private var port: MedKitCore.Port;
    private var wsfp: WSFP;
    
    /**
     Constructor
     
     - Parameters:
        - http:
     */
    init(http: HTTPServer, port: MedKitCore.Port, wsfp: WSFP)
    {
        self.http = http;
        self.port = port;
        self.wsfp = wsfp;
        
        super.init();
        
        http.messageHandler = self;
    }
    
    private func verify(request: HTTPRequest) -> HTTPResponse
    {
        let check = Check();
        
        check += (request.getField(key: HTTPHeader.Connection)           == Upgrade);
        check += (request.getField(key: HTTPHeader.Upgrade)              == WebSocket);
        check += (request.getField(key: HTTPHeader.SecWebSocketKey)      != nil);
        check += (request.getField(key: HTTPHeader.SecWebSocketProtocol) == ProtocolNameMIPV1);
        check += (request.getField(key: HTTPHeader.SecWebSocketVersion)  == Version);
        
        if (check.value)
        {
            let response = HTTPResponse(status: .SwitchingProtocols);
            let digest   = SecurityManagerShared.main.digest(using: .SHA1);
            
            // generate acceptance signature
            digest.update(string: request.getField(key: HTTPHeader.SecWebSocketKey));
            digest.update(string: Key);
            
            // populate response
            response.setField(key: HTTPHeader.Connection,           value: Upgrade);
            response.setField(key: HTTPHeader.Upgrade,              value: WebSocket);
            response.setField(key: HTTPHeader.SecWebSocketAccept,   value: digest.final().base64EncodedString);
            response.setField(key: HTTPHeader.SecWebSocketProtocol, value: ProtocolNameMIPV1); // TODO
            response.setField(key: HTTPHeader.SecWebSocketVersion,  value: Version);
            
            wsfp.enable(port: port);
            return response;
        }
        
        return HTTPResponse(status: .Forbidden);
    }

    
    func server(_ server: HTTPServer, didReceive request: HTTPRequest, completionHandler completion: (HTTPResponse?, Error?) -> Void)
    {
        var response: HTTPResponse;

        if (request.method == HTTPMethod.Get.rawValue && request.url?.path == MIPV1WSPath) {
            response = verify(request: request);
        }
        else {
            response = HTTPResponse(status: .NotFound);
        }
        
        completion(response, nil);
    }
    
}


// End of File
