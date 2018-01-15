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


class AuthenticateV1MessageCoder: Codable {

    let message: AuthenticateV1Message

    // MARK: - Private
    enum CodingKeys: CodingKey {
        case method
        case args
    }

    // MARK: - Initializers

    init(message: AuthenticateV1Message)
    {
        self.message = message
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method    = try container.decode(AuthenticateV1MessageType.self, forKey: .method)

        switch method {
        case .phase1:
            message = try container.decode(AuthenticateV1Phase1.self, forKey: .args)

        case .phase2:
            message = try container.decode(AuthenticateV1Phase2.self, forKey: .args)

        case .phase3:
            message = try container.decode(AuthenticateV1Phase3.self, forKey: .args)

        case .accept:
            message = try container.decode(AuthenticateV1Accept.self, forKey: .args)

        case .reject:
            message = try container.decode(AuthenticateV1Reject.self, forKey: .args)
        }
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(message.type,               forKey: .method)
        try container.encode(ConcreteEncodable(message), forKey: .args)
    }

    // MARK: -

    func send(to authenticator: AuthenticatorV1)
    {
        message.send(to: authenticator)
    }

}


// End of File


