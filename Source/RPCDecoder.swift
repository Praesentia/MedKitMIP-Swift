/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2017 Jon Griffeth
 
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


public class RPCDecoder: Decoder {
    
    public static let factory : DecoderFactory = RPCDecoderFactory()
    
    // MARK: - Private
    private let Sync   = "RPC.Sync"
    private let Reply  = "RPC.Reply"
    private let Async  = "RPC.Async"
    
    public func type(data: Data) -> String?
    {
        let message: JSON? = try? JSONParser.parse(data: data)
        
        if let message = message {
            if let messageType = RPCV1.MessageType(rawValue: message[KeyType]) {
                switch messageType {
                case .Sync :
                    return Sync
         
                case .Reply :
                    return Reply
         
                case .Async :
                    return Async
                }
            }
        }
        
        return "Bad"
    }
    
    public func string(data: Data) -> String?
    {
        return String(data: data, encoding: .utf8)
    }
    
}

class RPCDecoderFactory: DecoderFactory {
    
    func instantiateDecoder() -> Decoder
    {
        return RPCDecoder()
    }
}


// End of File
