/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2016-2017 Jon Griffeth
 
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
 MIP device registry.
 */
class MIPClientRegistry {
    
    private var registry = [UUID : DeviceBackend]()
    
    /**
     Initialize instance.
     */
    init()
    {
    }
    
    func addDevice(_ device: DeviceBackend)
    {
        registry[device.identifier] = device
    }
    
    func removeDevice(_ device: DeviceBackend)
    {
        registry[device.identifier] = nil
    }
    
    /**
     Find device.
     
     - Parameters:
     - path:
     */
    func findDevice(path: [UUID]) -> DeviceBackend?
    {
        return registry[path[0]]
    }
    
    /**
     Find service.
     
     - Parameters:
     - path:
     */
    func findService(path: [UUID]) -> ServiceBackend?
    {
        return findDevice(path: path)?.getService(withIdentifier: path[1])
    }
    
    /**
     Find resource.
     
     - Parameters:
     - path:
     */
    func findResource(path: [UUID]) -> ResourceBackend?
    {
        return findService(path: path)?.getResource(withIdentifier: path[2])
    }
    
}


// End of File
