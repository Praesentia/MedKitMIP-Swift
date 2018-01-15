/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2016-2018 Jon Griffeth
 
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


/**
 MIPV1 client-side encoder.
 */
class MIPV1ClientEncoder {
    
    var rpc: RPCV1
    
    /**
     Initialize instance.
     */
    init(rpc: RPCV1)
    {
        self.rpc = rpc
    }
 
    // MARK: - Server
    
    func deviceGetProfile(_ device: DeviceBackend, completionHandler completion: @escaping (DeviceProfile?, Error?) -> Void)
    {
        let method  = MIPV1DeviceGetProfile()
        let message = MIPV1Route(path: device.path, content: try! AnyCodable(method))
        
        rpc.sync(content: try! AnyCodable(message)) { reply, error in
            var profile: DeviceProfile?
            
            if error == nil, let decoder = reply?.decoder { // TODO
                let container = try decoder.singleValueContainer()
                profile = try container.decode(DeviceProfile.self)
            }
            
            completion(profile, error)
        }
    }
    
    func deviceUpdateName(_ device: DeviceBackend, name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        let method  = MIPV1DeviceUpdateName(name)
        let message = MIPV1Route(path: device.path, content: try! AnyCodable(method))

        rpc.sync(content: try! AnyCodable(message)) { _, error in
            completion(error)
        }
    }
    
    func serviceUpdateName(_ service: ServiceBackend, name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        let method  = MIPV1ServiceUpdateName(name)
        let message = MIPV1Route(path: service.path, content: try! AnyCodable(method))

        rpc.sync(content: try! AnyCodable(message)) { _, error in
            completion(error)
        }
    }
    
    func resourceEnableNotification(_ resource: ResourceBackend, enable: Bool, completionHandler completion: @escaping (Error?) -> Void)
    {
        let method  = MIPV1ResourceEnableNotification(enable: enable)
        let message = MIPV1Route(path: resource.path, content: try! AnyCodable(method))

        rpc.sync(content: try! AnyCodable(message)) { _, error in
            completion(error)
        }
    }

    func resource(_ resource: ResourceBackend, didCallWith message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void)
    {
        let method  = MIPV1ResourceCall(message: message)
        let message = MIPV1Route(path: resource.path, content: try! AnyCodable(method))

        rpc.sync(content: try! AnyEncoder().encode(message)) { reply, error in
            var reply: AnyCodable?

            if error == nil, let decoder = reply?.decoder {
                let container = try decoder.singleValueContainer()
                reply = try container.decode(AnyCodable.self)
            }

            completion(reply, error)
        }
    }

    func resource(_ resource: ResourceBackend, didNotifyWith notification: AnyCodable)
    {
    }
}


// End of File
