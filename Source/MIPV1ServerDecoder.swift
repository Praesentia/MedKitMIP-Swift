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
 MIPV1 server-side decoder.
 */
class MIPV1ServerDecoder: RPCV1MessageHandler {
    
    weak var server: MIPV1Server?
    
    // MARK: - Private
    private let AuthIdentifier = UUID.null
    private let authenticator  : Authenticator
    private let schema         = MIPV1MessageSchema()
    private let schemaDevice   = MIPV1DeviceSchema()
    private let schemaService  = MIPV1ServiceSchema()
    private let schemaResource = MIPV1ResourceSchema()
    
    /**
     Initialize instance.
     
     - Parameters:
     - rpc:
     */
    init(authenticator: Authenticator)
    {
        self.authenticator = authenticator
    }
    
    /**
     */
    private func findAuthenticator(path: [UUID]) -> Authenticator?
    {
        return path[0] == AuthIdentifier ? authenticator : nil
    }

    
    private func decodeDevice(_ device: DeviceFrontend, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        let principal = authenticator.principal
        
        if let method = MIPV1DeviceMethod(rawValue: method) {
            if schemaDevice.verifySync(method: method, args: args) {
                switch method {
                case .GetProfile :
                    server?.deviceGetProfile(principal, device, completionHandler: completion)

                case .UpdateName :
                    server?.device(principal, device, updateName: args[KeyName].string!) { error in
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    private func decodeDevice(_ device: DeviceFrontend, method: Int, args: JSON)
    {
    }
    
    private func decodeService(_ service: Service, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        let principal = authenticator.principal
        
        if let method = MIPV1ServiceMethod(rawValue: method) {
            if schemaService.verifySync(method: method, args: args) {
                switch method {
                case .UpdateName :
                    server?.service(principal, service, updateName: args[KeyName]) { error in
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    private func decodeService(_ service: Service, method: Int, args: JSON)
    {
    }
    
    private func decodeResource(_ resource: Resource, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        let principal = authenticator.principal
        
        if let method = MIPV1ResourceMethod(rawValue: method) {
            if schemaResource.verifySync(method: method, args: args) {
                switch method {
                case .DisableNotification :
                    server?.resourceDisableNotifcation(principal, resource) { error in
                        completion(nil, error)
                    }
                
                case .EnableNotification :
                    server?.resourceEnableNotifcation(principal, resource) { reply, error in
                        completion(reply?.json, error)
                    }
                    
                case .ReadValue :
                    server?.resourceReadValue(principal, resource) { reply, error in
                        completion(reply?.json, error)
                    }
                    
                case .WriteValue :
                    server?.resourceWriteValue(principal, resource, args[KeyValue]) { reply, error in
                        completion(reply?.json, error)
                    }
                }
            }
        }
    }
    
    private func decodeResource(_ resource: Resource, method: Int, args: JSON)
    {
    }
    
    // MARK: - RPCV1MessageHandler
    
    /**
     RPC did receive call.
     
     - Parameters:
     - rpc
     - method:
     - args:
     - completion:
     */
    func rpc(_ rpc: RPCV1, didReceive message: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        if schema.verify(message: message) {
            
            let path   : [UUID] = message[KeyPath].array!.map() { $0.uuid! }
            let method : Int    = message[KeyMethod].int!
            let args   : JSON   = message[KeyArgs]
            
            switch path.count {
            case 1 :
                if let authenticate = findAuthenticator(path: path) {
                    authenticate.decode(method: method, args: args, completionHandler: completion)
                }
                else {
                    if let device = server?.registry.findDevice(path: path) {
                        decodeDevice(device, method: method, args: args, completionHandler: completion)
                    }
                    else {
                        DispatchQueue.main.async { completion(nil, MedKitError.notFound) }
                    }
                }
                
            case 2 :
                if let service = server?.registry.findService(path: path) {
                    decodeService(service, method: method, args: args, completionHandler: completion)
                }
                else {
                    DispatchQueue.main.async { completion(nil, MedKitError.notFound) }
                }
                
            case 3 :
                if let resource = server?.registry.findResource(path: path) {
                    decodeResource(resource, method: method, args: args, completionHandler: completion)
                }
                else {
                    DispatchQueue.main.async { completion(nil, MedKitError.notFound) }
                }
                
            default :
                DispatchQueue.main.async { completion(nil, MedKitError.notFound) }
            }
        }
    }
    
    /**
     RPC did receive notification.
     
     - Parameters:
     - rpc
     - method:
     - args:
     */
    func rpc(_ rpc: RPCV1, didReceive message: JSON)
    {
        if schema.verify(message: message) {
            
            let path   : [UUID] = message[KeyPath].array!.map() { $0.uuid! }
            let method : Int    = message[KeyMethod].int!
            let args   : JSON   = message[KeyArgs]
            
            switch path.count {
            case 1 :
                if let authenticate = findAuthenticator(path: path) {
                    authenticate.decode(method: method, args: args)
                }
                if let device = server?.registry.findDevice(path: path) {
                    decodeDevice(device, method: method, args: args)
                }
                
            case 2 :
                if let service = server?.registry.findService(path: path) {
                    decodeService(service, method: method, args: args)
                }
                
            case 3 :
                if let resource = server?.registry.findResource(path: path) {
                    decodeResource(resource, method: method, args: args)
                }
                
            default :
                break
            }
        }
    }
    
}


// End of File
