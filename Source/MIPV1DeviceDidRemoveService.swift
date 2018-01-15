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


class MIPV1DeviceDidRemoveService: MIPV1DeviceNotification {

    var type : MIPV1DeviceNotificationType { return .didRemoveService }

    let service: UUID

    private enum CodingKeys: CodingKey {
        case service
    }

    init(_ service: UUID)
    {
        self.service = service
    }

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        service = try container.decode(UUID.self, forKey: .service)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        try container.encode(MIPV1DeviceNotificationType.didAddService, forKey: .method)

        var args = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .args)
        try args.encode(service, forKey: .service)
    }

    func send(to client: MIPV1Client, from device: DeviceBackend)
    {
        client.device(device, didRemoveService: service)
    }

}


// End of File

