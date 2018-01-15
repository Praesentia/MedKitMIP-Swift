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


enum MIPV1RouteCodingKeys: CodingKey {
    case path
    case content
}

class MIPV1Route: Codable {

    // MARK: - Properties
    let path    : [UUID]
    let content : AnyCodable

    // MARK: - Private
    enum MIPV1RouteCodingKeys: CodingKey {
        case path
        case content
    }

    // MARK: - Initializers

    init(path: [UUID], content: AnyCodable)
    {
        self.path    = path
        self.content = content
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        var container = try decoder.container(keyedBy: MIPV1RouteCodingKeys.self)

        path    = try container.decode([UUID].self,     forKey: .path)
        content = try container.decode(AnyCodable.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1RouteCodingKeys.self)

        try container.encode(path,    forKey: .path)
        try container.encode(content, forKey: .content)
    }

}


// End of File


