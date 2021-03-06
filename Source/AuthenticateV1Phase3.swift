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


class AuthenticateV1Phase3: AuthenticateV1Message {

    var type      : AuthenticateV1MessageType { return .phase3 }
    let key       : Data
    let principal : Principal

    private enum CodingKeys: CodingKey {
        case key
        case principal
    }

    init(principal: Principal, key: Data)
    {
        self.key       = key
        self.principal = principal
    }

    required init(from decoder: Decoder) throws
    {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        let keyString   = try container.decode(String.self, forKey: .key)

        key       = try Data(base64: keyString)
        principal = try container.decode(Principal.self, forKey: .principal)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(key.base64EncodedString, forKey: .key)
        try container.encode(principal,               forKey: .principal)
    }

    func send(to authenticator: AuthenticatorV1)
    {
        authenticator.received(message: self)
    }

}


// End of File



