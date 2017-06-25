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
 HTTP Reader
 */
class HTTPReader {
    
    private let EOH: [UInt8] = [ 0x0d, 0x0a, 0x0d, 0x0a ] //: End of header byte sequence.
    
    /**
     Get request from queue
     */
    func getRequest(from queue: DataQueue) -> HTTPRequest?
    {
        if let bytes = getHeader(from: queue) {
            return HTTPRequest(fromData: Data(bytes))
        }
        
        return nil
    }
    
    /**
     Get response from queue
     */
    func getResponse(from queue: DataQueue) -> HTTPResponse?
    {
        if let bytes = getHeader(from: queue) {
            return HTTPResponse(fromData: Data(bytes))
        }
        
        return nil
    }
    
    /**
     Get header from queue.
     */
    private func getHeader(from queue: DataQueue) -> [UInt8]?
    {
        if let count = queue.scan(for: EOH) {
            return queue.read(count: count)
        }
        return nil
    }
    
}


// End of File
