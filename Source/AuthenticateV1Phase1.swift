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


class AuthenticateV1Phase1: AuthenticateV1Message {

    var type  : AuthenticateV1MessageType { return .phase1 }
    let nonce : Data

    private enum CodingKeys: CodingKey {
        case nonce
    }

    init(nonce: Data)
    {
        self.nonce = nonce
    }

    required init(from decoder: Decoder) throws
    {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        let nonceString = try container.decode(String.self, forKey: .nonce)
        
        nonce = try Data(base64: nonceString)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nonce.base64EncodedString, forKey: .nonce)
    }

    func send(to authenticator: AuthenticatorV1)
    {
        authenticator.received(message: self)
    }

}


// End of File

