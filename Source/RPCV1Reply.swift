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


class RPCV1Reply: RPCV1Message {

    typealias IDType = RPCV1Sequencer.IDType

    // MARK: - Properties
    var type    : RPCV1MessageType { return .reply }
    let id      : IDType
    let error   : MedKitError?
    let content : AnyCodable?

    // MARK: - Private
    private enum CodingKeys: CodingKey {
        case id
        case content
        case error
    }

    // MARK: - Initializers

    init(id: IDType, content: AnyCodable?, error: MedKitError?)
    {
        self.id      = id
        self.content = content
        self.error   = error
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id      = try container.decode(IDType.self, forKey: .id)
        content = try container.decodeIfPresent(AnyCodable.self,  forKey: .content)
        error   = try container.decodeIfPresent(MedKitError.self, forKey: .error)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id,      forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(error,   forKey: .error)
    }

    // MARK: - RPCV1Decodable

    func send(to rpc: RPCV1) throws
    {
        try rpc.received(message: self)
    }

}


// End of File

