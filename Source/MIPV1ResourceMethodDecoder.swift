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


class MIPV1ResourceMethodDecoder: Decodable {

    let message : MIPV1ResourceMethod

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        let method    = try container.decode(MIPV1ResourceMethodType.self, forKey: .method)

        switch method {
        case .enableNotification :
            message = try container.decode(MIPV1ResourceEnableNotification.self, forKey: .args)

        case .call :
            message = try container.decode(MIPV1ResourceCall.self, forKey: .args)
        }
    }

}


// End of File

