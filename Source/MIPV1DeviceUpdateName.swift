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


class MIPV1DeviceUpdateName: MIPV1DeviceMethod {

    var type : MIPV1DeviceMethodType { return .updateName }

    let name: String

    private enum CodingKeys: CodingKey {
        case name
    }

    init(_ name: String)
    {
        self.name = name
    }

    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: MIPV1MethodCodingKeys.self)
        try container.encode(MIPV1DeviceMethodType.updateName, forKey: .method)

        var args = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .args)
        try args.encode(name, forKey: .name)
    }

    func send(to server: MIPV1Server, device: DeviceFrontend, principal: Principal?, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void)
    {
        server.device(device, principal, updateName: name) { error in
            completion(nil, error)
        }
    }

}


// End of File


