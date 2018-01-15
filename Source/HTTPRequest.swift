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


/**
 HTTP Request
 */
class HTTPRequest: HTTPMessage {
    
    var method: String? { return CFHTTPMessageCopyRequestMethod(message)?.takeRetainedValue() as String? }
    var url   : URL?    { return CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() as URL? }
    
    /**
     Initialize instance
     
     - Parameters:
       - method:
       - url:
     */
    init(method: HTTPMethod, url: String)
    {
        let request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, method.rawValue as CFString, URL(string: url)! as CFURL, kCFHTTPVersion1_1).takeRetainedValue()
        super.init(message: request)
    }
    
    /**
     Initialize instance from data.
     
     - Parameters:
        - data:
     */
    init(fromData data: Data)
    {
        let bytes   = [UInt8](data)
        let request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        
        CFHTTPMessageAppendBytes(request, bytes, bytes.count)
        
        super.init(message: request)
    }
    
}


// End of File
