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
 MIPV1 client-side decoder.
 */
class MIPV1ClientDecoder: RPCV1MessageDelegate {
   
    weak var client: MIPV1Client!

    // MARK: - Private
    private let AuthIdentifier = UUID.null
    private let authenticator  : AuthenticatorV1
    
    /**
     Initialize instance.
     
     - Parameters:
        - rpc:
     */
    init(authenticator: Authenticator)
    {
        self.authenticator = authenticator as! AuthenticatorV1
    }
    
    /**
     */
    private func findAuthenticator(path: [UUID]) -> AuthenticatorV1?
    {
        return path[0] == AuthIdentifier ? authenticator : nil
    }
    
    private func decodeDevice(_ device: DeviceBackend, from message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        throw MedKitError.notSupported
    }
    
    private func decodeService(_ service: ServiceBackend, from message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        throw MedKitError.notSupported
    }

    private func decodeResource(_ resource: ResourceBackend, from message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        throw MedKitError.notSupported
    }
    
    // MARK: - RPCV1MessageDelegate
    
    /**
     RPC did receive call.
     
     - Parameters:
         - rpc
         - message:
         - completion:
     
     - todo: Clean up
     */
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        let container = try message.decoder.container(keyedBy: MIPV1RouteCodingKeys.self)
        let path      = try container.decode([UUID].self, forKey: .path)
        let content   = try container.decode(AnyCodable.self, forKey: .content)

        switch path.count {
        case 1 :
            if let authenticate = findAuthenticator(path: path) {
                try authenticate.received(message: content, completionHandler: completion)
            }
            else if let device = client?.registry.findDevice(path: path) {
                try decodeDevice(device, from: content, completionHandler: completion)
            }
            else {
                throw MedKitError.notFound
            }

        case 2 :
            if let service = client?.registry.findService(path: path) {
                try decodeService(service, from: content, completionHandler: completion)
            }
            else {
                throw MedKitError.notFound
            }

        case 3 :
            if let resource = client?.registry.findResource(path: path) {
                try decodeResource(resource, from: content, completionHandler: completion)
            }
            else {
                throw MedKitError.notFound
            }

        default :
            throw MedKitError.notFound
        }
    }
    
    /**
     Device did receive asynchronous message.
     
     - Parameters:
     - rpc:
     - message:
     
     - todo: Clean up
     */
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable) throws
    {
        let container = try message.decoder.container(keyedBy: MIPV1RouteCodingKeys.self)
        let path      = try container.decode([UUID].self, forKey: .path)

        switch path.count {
        case 1 :
            if let authenticator = findAuthenticator(path: path) {
                let message = try container.decode(AuthenticateV1MessageCoder.self, forKey: .content).message
                message.send(to: authenticator)
            }
            else if let device = client?.registry.findDevice(path: path) {
                let message = try container.decode(MIPV1DeviceNotificationDecoder.self, forKey: .content).message
                message.send(to: client, from: device)
            }

        case 2 :
            if let service = client?.registry.findService(path: path) {
                let message = try container.decode(MIPV1ServiceNotificationDecoder.self, forKey: .content).message
                message.send(to: client, from: service)
            }

        case 3 :
            if let resource = client?.registry.findResource(path: path) {
                let message = try container.decode(MIPV1ResourceNotificationDecoder.self, forKey: .content).message
                message.send(to: client, from: resource)
            }

        default :
            break
        }
    }

}


// End of File
