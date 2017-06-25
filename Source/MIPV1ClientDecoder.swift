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
 MIPV1 client-side decoder.
 */
class MIPV1ClientDecoder: RPCV1MessageHandler {
   
    weak var client: MIPV1Client?
    
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
    
    private func decodeDevice(_ device: DeviceBackend, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async { completion(nil, MedKitError.notSupported) }
    }
    
    private func decodeDevice(_ device: DeviceBackend, method: Int, args: JSON)
    {
        if let method = MIPV1DeviceNotification(rawValue: method) {
            if schemaDevice.verifyAsync(method: method, args: args) {
                switch method {
                case .DidUpdateName :
                    client?.device(device, didUpdateName: args[KeyName])
                    
                case .DidAddBridgedDevice :
                    client?.device(device, didAddBridgedDevice: args[KeyBridgedDevice])
                    
                case .DidRemoveBridgedDevice :
                    client?.device(device, didRemoveBridgedDevice: args[KeyBridgedDevice].uuid!)
                    
                case .DidAddService :
                    client?.device(device, didAddService: args[KeyService])
                    
                case .DidRemoveService :
                    client?.device(device, didRemoveService: args[KeyService].uuid!)
                }
            }
        }
    }
    
    private func decodeService(_ service: ServiceBackend, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async { completion(nil, MedKitError.notSupported) }
    }
    
    private func decodeService(_ service: ServiceBackend, method: Int, args: JSON)
    {
        if let method = MIPV1ServiceNotification(rawValue: method) {
            if schemaService.verifyAsync(method: method, args: args) {
                switch method {
                case .DidUpdateName :
                    client?.service(service, didUpdateName: args[KeyName])
                    
                case .DidAddResource :
                    client?.service(service, didAddResource: args[KeyResource])
                    
                case .DidRemoveResource :
                    client?.service(service, didRemoveResource: args[KeyResource].uuid!)
                }
            }
        }
    }
    
    private func decodeResource(_ resource: ResourceBackend, method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async { completion(nil, MedKitError.notSupported) }
    }
    
    private func decodeResource(_ resource: ResourceBackend, method: Int, args: JSON)
    {
        if let method = MIPV1ResourceNotification(rawValue: method) {
            if schemaResource.verifyAsync(method: method, args: args) {
                switch method {
                case .DidUpdate :
                    client?.resource(resource, didUpdate: args[KeyChanges], at: Clock.convert(time: args[KeyTimeModified].time!))
                }
            }
        }
    }
    
    // MARK: - RPCV1MessageHandler
    
    /**
     RPC did receive call.
     
     - Parameters:
     - rpc
     - message:
     - completion:
     
     - todo: Clean up
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
                if let device = client?.registry.findDevice(path: path) {
                    decodeDevice(device, method: method, args: args, completionHandler: completion)
                }
                
            case 2 :
                if let service = client?.registry.findService(path: path) {
                    decodeService(service, method: method, args: args, completionHandler: completion)
                }
                else {
                    DispatchQueue.main.async { completion(nil, MedKitError.notFound) }
                }
                
            case 3 :
                if let resource = client?.registry.findResource(path: path) {
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
     Device did receive asynchronous message.
     
     - Parameters:
     - rpc:
     - message:
     
     - todo: Clean up
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
                if let device = client?.registry.findDevice(path: path) {
                    decodeDevice(device, method: method, args: args)
                }
                
            case 2 :
                if let service = client?.registry.findService(path: path) {
                    decodeService(service, method: method, args: args)
                }
                
            case 3 :
                if let resource = client?.registry.findResource(path: path) {
                    decodeResource(resource, method: method, args: args)
                }
                
            default :
                break
            }
        }
    }

}


// End of File
