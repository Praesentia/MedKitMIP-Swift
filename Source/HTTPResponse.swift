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


/**
    HTTP Response
 */
class HTTPResponse: HTTPMessage {
    
    var status : HTTPStatus? { return HTTPStatus(rawValue: CFHTTPMessageGetResponseStatusCode(message)); }
    
    init(status: HTTPStatus)
    {
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, status.rawValue, nil, kCFHTTPVersion1_1).takeRetainedValue();

        super.init(message: response);
    }
    
    init(fromData data: Data)
    {
        let bytes    = [UInt8](data);
        let response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false).takeRetainedValue();
        
        CFHTTPMessageAppendBytes(response, bytes, bytes.count);

        super.init(message: response);
    }
    
}


// End of File
