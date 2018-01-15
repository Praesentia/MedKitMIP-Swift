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


class MIPV1DeviceDidRemoveBridgedDevice: MIPV1DeviceNotification {

    var type : MIPV1DeviceNotificationType { return .didRemoveBridgedDevice }

    let bridgedDevice: UUID

    private enum CodingKeys: CodingKey {
        case bridgedDevice
    }

    init(_ bridgedDevice: UUID)
    {
        self.bridgedDevice = bridgedDevice
    }

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bridgedDevice = try container.decode(UUID.self, forKey: .bridgedDevice)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        try container.encode(MIPV1DeviceNotificationType.didAddBridgedDevice, forKey: .method)

        var args = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .args)
        try args.encode(bridgedDevice, forKey: .bridgedDevice)
    }

    func send(to client: MIPV1Client, from device: DeviceBackend)
    {
        client.device(device, didRemoveBridgedDevice: bridgedDevice)
    }

}


// End of File
