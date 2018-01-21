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


/**
 RPCV1 Message Decodable
 */
class RPCV1MessageCodable: Codable {

    // MARK: - Properties
    let message: RPCV1Message

    // MARK: - Initializers

    init(message: RPCV1Message)
    {
        self.message = message
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: RPCV1MessageCodingKeys.self)
        let type      = try container.decode(RPCV1MessageType.self, forKey: .type)

        switch type {
        case .sync :
            message = try container.decode(RPCV1Sync.self, forKey: .content)

        case .reply :
            message = try container.decode(RPCV1Reply.self, forKey: .content)

        case .async :
            message = try container.decode(RPCV1Async.self, forKey: .content)
        }
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: RPCV1MessageCodingKeys.self)

        try container.encode(message.type,               forKey: .type)
        try container.encode(ConcreteEncodable(message), forKey: .content)
    }

    // MARK: -

    func send(to rpc: RPCV1) throws
    {
        try message.send(to: rpc)
    }

}


// End of File
