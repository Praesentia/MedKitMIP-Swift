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
import SecurityKit


class MIPV1ResourceCall: MIPV1ResourceMethod {

    // MARK: - Private
    var type    : MIPV1ResourceMethodType { return .call }
    let message : AnyCodable

    // MARK: - Initializers

    init(message: AnyCodable)
    {
        self.message = message
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        message = try container.decode(AnyCodable.self)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1MethodCodingKeys.self)

        try container.encode(type,    forKey: .method)
        try container.encode(message, forKey: .args)
    }

    // MARK: - MIPV1ResourceMethod

    func send(to server: MIPV1Server, resource: Resource, principal: Principal?, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        try server.resource(resource, principal, didCallWith: message) { reply, error in
            completion(reply, error)
        }
    }

}


// End of File


