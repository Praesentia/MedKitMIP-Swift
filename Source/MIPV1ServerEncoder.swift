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
 MIPV1 service-side encoder.
 */
class MIPV1ServerEncoder {
    
    var rpc: RPCV1
    
    /**
     Initialize instance.
     */
    init(rpc: RPCV1)
    {
        self.rpc = rpc
    }
    
    func device(_ device: Device, didUpdateName name: String)
    {
        rpc.async(content: try! AnyCodable(MIPV1DeviceDidUpdateName(name)))
    }
    
    func device(_ device: Device, didAddBridgedDevice profile: DeviceProfile)
    {
        rpc.async(content: try! AnyCodable(MIPV1DeviceDidAddBridgedDevice(profile)))
    }
    
    func device(_ device: Device, didRemoveBridgedDevice identifier: UUID)
    {
        rpc.async(content: try! AnyCodable(MIPV1DeviceDidRemoveBridgedDevice(identifier)))
    }
    
    func device(_ device: Device, didAddService profile: ServiceProfile)
    {
        rpc.async(content: try! AnyCodable(MIPV1DeviceDidAddService(profile)))
    }
    
    func device(_ device: Device, didRemoveService identifier: UUID)
    {
        rpc.async(content: try! AnyCodable(MIPV1DeviceDidRemoveService(identifier)))
    }
    
    func service(_ service: Service, didUpdateName name: String)
    {
        rpc.async(content: try! AnyCodable(MIPV1ServiceDidUpdateName(name)))
    }
    
    func service(_ service: Service, didAddResource profile: ResourceProfile)
    {
        rpc.async(content: try! AnyCodable(MIPV1ServiceDidAddResource(profile)))
    }
    
    func service(_ service: Service, didRemoveResource identifier: UUID)
    {
        let content = MIPV1ServiceDidRemoveResource(identifier)
        let message = MIPV1Route(path: service.path, content: try! AnyCodable(content))

        rpc.async(content: message)
    }
    
    func resource(_ resource: Resource, didNotifyWith notification: AnyCodable)
    {
        let content = MIPV1ResourceNotify(notification)
        let message = MIPV1Route(path: resource.path, content: try! AnyCodable(content))

        rpc.async(content: message)
    }
    
}


// End of File
