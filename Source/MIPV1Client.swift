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


import Foundation;
import MedKitCore;


/**
 MIP Version 1, client backend.
 */
class MIPV1Client: Backend {
    
    let registry = MIPClientRegistry();
    
    private var server        : MIPV1ClientEncoder;
    private let authenticator : Authenticator;
    
    /**
     Initialize instance.
     
     - Parameters:
        - decoder:
        - encoder:
     */
    init(encoder: MIPV1ClientEncoder, authenticator: Authenticator)
    {
        self.server        = encoder;
        self.authenticator = authenticator;
    }
    
    private func attach(_ device: DeviceBackend)
    {
        registry.addDevice(device);
        
        device.backend = self;
        
        for bridgedDevice in device.bridgedDeviceBackends {
            attach(bridgedDevice);
        }
        
        for service in device.serviceBackends {
            service.backend = self;
            for resource in service.resourceBackends {
                resource.backend = self;
            }
        }
    }
    
    private func detach(_ device: DeviceBackend)
    {
        for bridgedDevice in device.bridgedDeviceBackends {
            detach(bridgedDevice);
        }
        
        for service in device.serviceBackends {
            for resource in service.resourceBackends {
                resource.backend = resource.getDefaultBackend();
            }
            service.backend = service.getDefaultBackend();
        }
        
        device.backend = device.defaultBackend;
        registry.removeDevice(device);
    }
    
    // MARK: - MIPV1Client1
    
    func device(_ device: DeviceBackend, didUpdateName name: String)
    {
        device.updateName(name, notify: true);
    }
    
    func device(_ device: DeviceBackend, didAddBridgedDevice profile: JSON)
    {
        let identifier = profile[KeyIdentifier].uuid!;
        
        if device.getBridgedDevice(withIdentifier: identifier) == nil {
            let bridgedDevice = device.addBridgedDevice(from: profile, notify: true);
            attach(bridgedDevice);
        }
    }
    
    func device(_ device: DeviceBackend, didRemoveBridgedDevice identifier: UUID)
    {
        if let bridgedDevice = device.getBridgedDevice(withIdentifier: identifier) {
            device.removeBridgedDevice(bridgedDevice, notify: true);
        }
    }
    
    func device(_ device: DeviceBackend, didAddService profile: JSON)
    {
        let service = device.addService(from: profile, notify: true);
        service.backend = self;
    }
    
    func device(_ device: DeviceBackend, didRemoveService identifier: UUID)
    {
        device.removeService(withIdentifier: identifier, notify: true);
    }
    
    func service(_ service: ServiceBackend, didUpdateName name: String)
    {
        service.updateName(name, notify: true);
    }
    
    func service(_ service: ServiceBackend, didAddResource profile: JSON)
    {
        let resource = ResourceBase(service as! ServiceBase, from: profile);
        
        resource.backend = self;
        service.addResource(resource, notify: true);
    }
    
    func service(_ service: ServiceBackend, didRemoveResource identifier: UUID)
    {
        service.removeResource(withIdentifier: identifier, notify: true);
    }
    
    func resource(_ resource: ResourceBackend, didUpdate changes: JSON, at time: TimeInterval)
    {
        resource.update(changes: changes, at: time);
    }
    
    // MARK: - DeviceBackendDelegate
    
    func deviceOpen(_ device: DeviceBackend, completionHandler completion: @escaping (Error?) -> Void)
    {
        let sync = Sync();
        
        sync.incr();
        authenticator.authenticate() { error in
            
            if error == nil {
                sync.incr();
                self.getProfile(for: device) { error in
                    if error == nil {
                        self.attach(device);
                    }
                    sync.decr(error);
                }
            }

            sync.decr(error);
        }
        
        sync.close(completionHandler: completion);
    }
    
    func deviceClose(_ device: DeviceBackend, reason: Error?, completionHandler completion: @escaping (Error?) -> Void)
    {
        detach(device);
        DispatchQueue.main.async() { completion(nil); }
    }
    
    private func getProfile(for device: DeviceBackend, completionHandler completion: @escaping (Error?) -> Void)
    {
        server.deviceGetProfile(device) { profile, error in
            if error == nil, let profile = profile {
                device.update(from: profile);
            }
            completion(error);
        }
    }
    
    func device(_ device: DeviceBackend, updateName name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        server.deviceUpdateName(device, name: name) { error in
            if error == nil {
                device.updateName(name, notify: false);
            }
            completion(error);
        }
    }
    
    // MARK: - ServiceBackendDelegate
    
    func service(_ service: ServiceBackend, updateName name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        server.serviceUpdateName(service, name: name) { error in
            if error == nil {
                service.updateName(name, notify: false);
            }
            completion(error);
        }
    }
    
    // MARK: - ResourceBackendDelegate
    
    func resourceEnableNotification(_ resource: ResourceBackend, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        server.resourceEnableNotification(resource, completionHandler: completion);
    }
    
    func resourceDisableNotification(_ resource: ResourceBackend, completionHandler completion: @escaping (Error?) -> Void)
    {
        server.resourceDisableNotification(resource, completionHandler: completion);
    }
    
    func resourceReadValue(_ resource: ResourceBackend, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        server.resourceReadValue(resource, completionHandler: completion);
    }
    
    func resourceWriteValue(_ resource: ResourceBackend, _ value: JSON?, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        server.resourceWriteValue(resource, value, completionHandler: completion);
    }
    
}


// End of File
