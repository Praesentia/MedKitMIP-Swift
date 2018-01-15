/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.

 Copyright 2017-2018 Jon Griffeth

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


enum RPCV1MessageType: Int, Codable {
    case sync  = 1
    case reply = 2
    case async = 3
}

extension RPCV1MessageType {

    var localizedDescription : String { return getString() }

    func getString() -> String
    {
        switch self {
        case .sync :
            return "RPC.Sync"

        case .reply :
            return "RPC.Reply"

        case .async :
            return "RPC.Async"
        }
    }

}


// End of File

