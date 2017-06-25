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
 RPC schema.
 */
class RPCV1Schema {
    
    /**
     Verify message.
     
     - Parameters:
        - message: The message being verified for conformance to the schema.
     
     - Returns: Returns true if the message conforms to the schema, false
            otherwise.
     */
    func verify(message: JSON) -> Bool
    {
        if message.type == .Object && message[KeyType].type == .Number {
            if let messageType = RPCV1.MessageType(rawValue: message[KeyType].int!) {
                switch messageType {
                case .Sync :
                    return verifySync(message: message)
                    
                case .Reply :
                    return verifyReply(message: message)
                
                case .Async :
                    return verifyAsync(message: message)
                }
            }
        }
        
        return false
    }
    
    /**
     Verify synchronous message.
     
     - Parameters:
        - message: The message being verified for conformance to the schema.
     
     - Returns: Returns true if the message conforms to the schema, false
            otherwise.
     */
    private func verifySync(message: JSON) -> Bool
    {
        let check = Check()
        
        check += (message[KeyId].type      == .Number)
        check += (message[KeyMessage].type == .Object)
        
        check += message.object!.count == 3
        return check.value
    }
    
    /**
     Verify reply.
     
     - Parameters:
        - message: The message being verified for conformance to the schema.
     
     - Returns: Returns true if the message conforms to the schema, false
            otherwise.
     */
    private func verifyReply(message: JSON) -> Bool
    {
        var count = Int(2)
        let check = Check()
        
        check += (message[KeyId].type == .Number)
        if message.contains(key: KeyError) {
            count += 1
            check += (message[KeyError].type == .Number)
            check += MedKitError(rawValue: message[KeyError]) != nil
        }
        if message.contains(key: KeyReply) {
            count += 1
        }
        
        check += message.object!.count == count
        return check.value
    }
    
    /**
     Verify asynchronous message.
     
     - Parameters:
        - message: The message being verified for conformance to the schema.
        - Returns: Returns true if the message conforms to the schema, false
            otherwise.
     */
    private func verifyAsync(message: JSON) -> Bool
    {
        let check = Check()
        
        check += (message[KeyMessage].type == .Object)
        
        check += message.object!.count == 2
        return check.value
    }
    
}


// End of File
