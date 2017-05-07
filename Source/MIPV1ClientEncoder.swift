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
 MIPV1 client-side encoder.
 */
class MIPV1ClientEncoder {
    
    var rpc: RPCV1;
    
    private let schemaDevice   = MIPV1DeviceSchema();
    private let schemaService  = MIPV1ServiceSchema();
    private let schemaResource = MIPV1ResourceSchema();
    
    /**
     Initialize instance.
     */
    init(rpc: RPCV1)
    {
        self.rpc = rpc;
    }
 
    // MARK: - Server
    
    func deviceGetProfile(_ device: DeviceBackend, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]   = device.path;
        message[KeyMethod] = MIPV1DeviceMethod.GetProfile.rawValue;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            
            if error == nil {
                if !self.schemaDevice.verifyReply(method: .GetProfile, reply: reply) {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(reply, error);
        }
    }
    
    func deviceUpdateName(_ device: DeviceBackend, name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]          = device.path;
        message[KeyMethod]        = MIPV1DeviceMethod.UpdateName.rawValue;
        message[KeyArgs][KeyName] = name;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            
            if error == nil {
                if !self.schemaDevice.verifyReply(method: .UpdateName, reply: reply) {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(error);
        }
    }
    
    func serviceUpdateName(_ service: ServiceBackend, name: String, completionHandler completion: @escaping (Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]          = service.path;
        message[KeyMethod]        = MIPV1ServiceMethod.UpdateName.rawValue;
        message[KeyArgs][KeyName] = name;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            
            if error == nil {
                if !self.schemaService.verifyReply(method: .UpdateName, reply: reply) {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(error);
        }
    }
    
    func resourceEnableNotification(_ resource: ResourceBackend, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]   = resource.path;
        message[KeyMethod] = MIPV1ResourceMethod.EnableNotification.rawValue;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            var cache : ResourceCache?;
            
            if error == nil {
                if self.schemaResource.verifyReply(method: .EnableNotification, reply: reply) {
                    cache = ResourceCacheBase(from: reply!);
                }
                else {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(cache, error);
        }
    }
    
    func resourceDisableNotification(_ resource: ResourceBackend, completionHandler completion: @escaping (Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]   = resource.path;
        message[KeyMethod] = MIPV1ResourceMethod.DisableNotification.rawValue;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            
            if error == nil {
                if !self.schemaResource.verifyReply(method: .DisableNotification, reply: reply) {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(error);
        }
    }
    
    func resourceReadValue(_ resource: ResourceBackend, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]   = resource.path;
        message[KeyMethod] = MIPV1ResourceMethod.ReadValue.rawValue;
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            var cache : ResourceCache?;
            
            if error == nil {
                if self.schemaResource.verifyReply(method: .ReadValue, reply: reply) {
                    cache = ResourceCacheBase(from: reply!);
                }
                else {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(cache, error);
        }
    }
    
    func resourceWriteValue(_ resource: ResourceBackend, _ value: JSON?, completionHandler completion: @escaping (ResourceCache?, Error?) -> Void)
    {
        let message = JSON();
        
        message[KeyPath]           = resource.path;
        message[KeyMethod]         = MIPV1ResourceMethod.WriteValue.rawValue;
        message[KeyArgs][KeyValue] = value!; // TODO
        
        rpc.sync(message: message) { reply, error in
            var error = error;
            var cache : ResourceCache?;
            
            if error == nil {
                if self.schemaResource.verifyReply(method: .WriteValue, reply: reply) {
                    cache = ResourceCacheBase(from: reply!);
                }
                else {
                    error = MedKitError.BadReply;
                }
            }
            
            completion(cache, error);
        }
    }
    
}


// End of File
