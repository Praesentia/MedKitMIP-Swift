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


class RPCV1MessageDecodable: Decodable {

    // MARK: - Properties
    let content: RPCV1Message

    // MARK: - Private
    private enum CodingKeys: CodingKey {
        case type
        case content
    }

    // MARK: - Decodable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type      = try container.decode(RPCV1MessageType.self, forKey: CodingKeys.type)

        switch type {
        case .sync :
            content = try container.decode(RPCV1Sync.self, forKey: .content)

        case .reply :
            content = try container.decode(RPCV1Reply.self, forKey: .content)

        case .async :
            content = try container.decode(RPCV1Async.self, forKey: .content)
        }
    }

    // MARK: - RPCV1Decodable

    func send(to rpc: RPCV1) throws
    {
        try content.send(to: rpc)
    }

}


// End of File
