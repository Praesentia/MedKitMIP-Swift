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


class RPCV1Sync: RPCV1Message {

    typealias IDType = RPCV1Sequencer.IDType

    // MARK: - Properties
    var type    : RPCV1MessageType { return .sync }
    let id      : IDType
    let content : AnyCodable

    // MARK: - Private
    private enum CodingKeys: CodingKey {
        case id
        case content
    }

    // MARK: - Initializers

    init(id: IDType, content: AnyCodable)
    {
        self.id      = id
        self.content = content
    }

    // MARK: - Decodable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id      = try container.decode(IDType.self, forKey: .id)
        content = try container.decode(AnyCodable.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
    }

    // MARK: - RPCV1Decodable

    func send(to rpc: RPCV1) throws
    {
        try rpc.received(message: self)
    }

}


// End of File
