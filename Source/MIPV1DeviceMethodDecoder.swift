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


class MIPV1DeviceMethodDecoder: Decodable {

    let message: MIPV1DeviceMethod

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        let method    = try container.decode(MIPV1DeviceMethodType.self, forKey: .method)

        switch method {
        case .getProfile :
            message = try container.decode(MIPV1DeviceGetProfile.self, forKey: .args)

        case .updateName :
            message = try container.decode(MIPV1DeviceUpdateName.self, forKey: .args)
        }
    }

}


// End of File
