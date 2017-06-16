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
 Medical Interoperability Protocol backend.
 */
class MIPV1Server: DeviceObserver, ServiceObserver, ResourceObserver {
    
    let registry = MIPServerRegistry();
    
    private var client : MIPV1ServerEncoder;
    private let device : DeviceFrontend;
    
    /**
     Initialize instance.
     */
    init(device: DeviceFrontend, encoder: MIPV1ServerEncoder)
    {
        self.device = device;
        self.client = encoder;
        
        attach(device);
    }
    
    /**
     Close
     
     Cleans up after connection has closed.
     */
    func close()
    {
        detach(device);
    }
    
    private func attach(_ device: DeviceFrontend)
    {
        registry.addDevice(device);
        device.addObserver(self);
        
        for service in device.services {
            service.addObserver(self);
        }
        
        for bridgedDevice in device.bridgedDevices {
            attach(bridgedDevice as! DeviceFrontend);
        }
    }
    
    private func detach(_ device: DeviceFrontend)
    {
        for bridgedDevice in device.bridgedDevices {
            detach(bridgedDevice as! DeviceFrontend);
        }
        
        for service in device.services {
            for resource in service.resources {
                resource.removeObserver(self) { error in }
            }
            service.removeObserver(self);
        }
        
        device.removeObserver(self);
        registry.removeDevice(device);
    }
    
    // MARK: - MIPV1Server1
    
    func deviceGetProfile(_ principal: Principal?, _ device: DeviceFrontend, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        if device.acl.authorized(principal: principal, operation: OperationTypeDeviceGetProfile) {
            DispatchQueue.main.async() { completion(device.profile, nil); }
        }
        else {
            DispatchQueue.main.async() { completion(nil, MedKitError.NotAuthorized); }
        }
    }
    
    func device(_ principal: Principal?, _ device: DeviceFrontend, updateName name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        if device.acl.authorized(principal: principal, operation: OperationTypeDeviceUpdateName) {
            device.updateName(name, completionHandler: completion);
        }
        else {
            DispatchQueue.main.async() { completion(MedKitError.NotAuthorized); }
        }
    }
    
    func service(_ principal: Principal?, _ service: Service, updateName name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        let acl = (service.device as! DeviceFrontend).acl;
        
        if acl.authorized(principal: principal, operation: OperationTypeServiceUpdateName) {
            service.updateName(name, completionHandler: completion);
        }
        else {
            DispatchQueue.main.async() { completion(MedKitError.NotAuthorized); }
        }
    }
    
    func resourceEnableNotifcation(_ principal: Principal?, _ resource: Resource, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let acl = (resource.service!.device as! DeviceFrontend).acl;
        
        if acl.authorized(principal: principal, operation: OperationTypeResourceEnableNotification) {
            resource.addObserver(self) { error in
                completion(resource.cache, error);
            }
        }
        else {
            DispatchQueue.main.async() { completion(nil, MedKitError.NotAuthorized); }
        }
    }
    
    func resourceDisableNotifcation(_ principal: Principal?, _ resource: Resource, completionHandler completion: @escaping (Error?) -> Void)
    {
        let acl = (resource.service!.device as! DeviceFrontend).acl;
        
        if acl.authorized(principal: principal, operation: OperationTypeResourceEnableNotification) {
            resource.removeObserver(self, completionHandler: completion);
        }
        else {
            DispatchQueue.main.async() { completion(MedKitError.NotAuthorized); }
        }
    }
    
    func resourceReadValue(_ principal: Principal?, _ resource: Resource, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let acl = (resource.service!.device as! DeviceFrontend).acl;
        
        if acl.authorized(principal: principal, operation: OperationTypeResourceReadValue) {
            resource.readValue(completionHandler: completion);
        }
        else {
            DispatchQueue.main.async() { completion(nil, MedKitError.NotAuthorized); }
        }
    }
    
    func resourceWriteValue(_ principal: Principal?, _ resource: Resource, _ value: JSON?, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let acl = (resource.service!.device as! DeviceFrontend).acl;
        
        if acl.authorized(principal: principal, operation: OperationTypeResourceWriteValue) {
            resource.writeValue(value, completionHandler: completion);
        }
        else {
            DispatchQueue.main.async() { completion(nil, MedKitError.NotAuthorized); }
        }
    }

    // MARK: - DeviceObserver
    
    func deviceDidUpdateName(_ device: Device)
    {
        client.device(device, didUpdateName: device.name);
    }
    
    func device(_ device: Device, didAdd bridgedDevice: Device)
    {
        attach(bridgedDevice as! DeviceFrontend);
    }
    
    func device(_ device: Device, didRemove bridgedDevice: Device)
    {
        detach(bridgedDevice as! DeviceFrontend);
    }
    
    func device(_ device: Device, didAdd service: Service)
    {
        service.addObserver(self);
        client.device(device, didAddService: service.profile);
    }
    
    func device(_ device: Device, didRemove service: Service)
    {
        service.removeObserver(self);
        client.device(device, didRemoveService: service.identifier);
    }
    
    // MARK: - ServiceObserver
    
    func serviceDidUpdateName(_ service: Service)
    {
        client.service(service, didUpdateName: service.name);
    }
    
    // MARK: - ResourceObserver
    
    func resourceDidUpdate(_ resource: Resource)
    {
        if let cache = resource.cache {
            client.resource(resource, didUpdate: cache.value, at: cache.timeModified)
        }
    }
    
}


// End of File
