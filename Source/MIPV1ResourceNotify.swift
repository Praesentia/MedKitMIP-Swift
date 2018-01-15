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


class MIPV1ResourceNotify: MIPV1ResourceNotification {

    // MARK: - Properties
    var type : MIPV1ResourceNotificationType { return .notify }
    let args : AnyCodable

    // MARK: - Initializers

    init(_ args: AnyCodable)
    {
        self.args = args
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        args = try container.decode(AnyCodable.self)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1MethodCodingKeys.self)

        try container.encode(type, forKey: .method)
        try container.encode(args, forKey: .args)
    }

    func send(to client: MIPV1Client, from resource: ResourceBackend)
    {
        client.resource(resource, didNotifyWith: args)
    }

}


// End of File

