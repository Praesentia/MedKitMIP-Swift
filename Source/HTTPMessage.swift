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


/**
 HTTP Message
 */
class HTTPMessage {
    
    var message : CFHTTPMessage

    init(message: CFHTTPMessage)
    {
        self.message = message
    }
    
    func getField(key: HTTPHeader) -> String?
    {
        return (CFHTTPMessageCopyHeaderFieldValue(message, key.rawValue as CFString)?.takeRetainedValue()) as String?
    }
    
    func getField(key: String) -> String?
    {
        return (CFHTTPMessageCopyHeaderFieldValue(message, key as CFString)?.takeRetainedValue()) as String?
    }
    
    func setField(key: HTTPHeader, value: String)
    {
        CFHTTPMessageSetHeaderFieldValue(message, key.rawValue as CFString, value as CFString)
    }

    func setField(key: String, value: String)
    {
        CFHTTPMessageSetHeaderFieldValue(message, key as CFString, value as CFString)
    }
    
    func toData() -> Data?
    {
        var data : Data?
        
        if let dataRef = CFHTTPMessageCopySerializedMessage(message) {
            data = dataRef.takeRetainedValue() as Data
        }
        return data
    }
    
}


// End of File
