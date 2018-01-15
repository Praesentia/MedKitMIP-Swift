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


class MIPV1ServiceNotificationDecoder: Decodable {

    let message : MIPV1ServiceNotification

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        let method    = try container.decode(MIPV1ServiceNotificationType.self, forKey: .method)

        switch method {
        case .didUpdateName :
            message = try container.decode(MIPV1ServiceDidUpdateName.self, forKey: .args)

        case .didAddResource :
            message = try container.decode(MIPV1ServiceDidAddResource.self, forKey: .args)

        case .didRemoveResource :
            message = try container.decode(MIPV1ServiceDidRemoveResource.self, forKey: .args)
        }
    }

}


// End of File


