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
 RPCV1 Message Delegate protocol.

 A delegate used to process messages received from an RPCV1 protocol instance.
 */
protocol RPCV1MessageDelegate: class {

    /**
     Did receive synchronous message.

     - Parameters:
        - rpc:        The RPC instance from which the message is received.
        - message:    The content of the synchronous message.
        - completion: A completion handler used to reply to the message.
     */
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws

    /**
     Did receive asynchronous message.


     - Parameters:
        - rpc:     The RPC instance from which the message is received.
        - message: The content of the asynchronous message.
     */
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable) throws
    
}


// End of File
