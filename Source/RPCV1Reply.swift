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

    // MARK: - Properties
    var type    : RPCV1MessageType { return .reply }
    let id      : Int
    let error   : MedKitError?
    let content : AnyCodable?

    // MARK: - Private
    private enum CodingKeys: CodingKey {
        case id
        case error
        case content
    }

    // MARK: - Initializers

    init(id: Int, error: MedKitError?, content: AnyCodable?)
    {
        self.id      = id
        self.error   = error
        self.content = content
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id      = try container.decode(Int.self, forKey: .id)
        error   = try container.decodeIfPresent(MedKitError.self, forKey: .error)
        content = try container.decodeIfPresent(AnyCodable.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(error, forKey: .error)

        if let content = self.content {
            try container.encode(content, forKey: .content)
        }
    }

    // MARK: - RPCV1Decodable

    func send(to rpc: RPCV1) throws
    {
        try rpc.received(message: self)
    }

}


// End of File

