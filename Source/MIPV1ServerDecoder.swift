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
 MIPV1 server-side decoder.
 */
class MIPV1ServerDecoder: RPCV1MessageHandler {

    weak var server: MIPV1Server!
    
    // MARK: - Private
    private let AuthIdentifier = UUID.null
    private let authenticator  : Authenticator
    
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
    
    private func decode(device: DeviceFrontend, from content: AnyCodable) throws
    {
        throw MedKitError.notSupported
    }
    
    private func decode(service: Service, from content: AnyCodable) throws
    {
        throw MedKitError.notSupported
    }
    
    private func decode(resource: Resource, from content: AnyCodable) throws
    {
        throw MedKitError.notSupported
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
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        let container = try message.decoder.container(keyedBy: MIPV1RouteCodingKeys.self)
        let path      = try container.decode([UUID].self, forKey: .path)

        switch path.count {
        case 1 :
            if let authenticator = findAuthenticator(path: path) {
                //let message = try container.decode(AuthenticateV1MessageCoder.self, forKey: .content).message
                // TODO message.send(to: authenticator, completionHandler: completion)
            }
            else {
                if let device = server?.registry.findDevice(path: path) {
                    let message = try container.decode(MIPV1DeviceMethodDecoder.self, forKey: .content).message
                    message.send(to: server, device: device, principal: authenticator.principal, completionHandler: completion)
                }
                else {
                    throw MedKitError.notFound
                }
            }

        case 2 :
            if let service = server?.registry.findService(path: path) {
                let message = try container.decode(MIPV1ServiceMethodDecoder.self, forKey: .content).message
                message.send(to: server, service: service, principal: authenticator.principal, completionHandler: completion)
            }
            else {
                throw MedKitError.notFound
            } 

        case 3 :
            if let resource = server?.registry.findResource(path: path) {
                let message = try container.decode(MIPV1ResourceMethodDecoder.self, forKey: .content).message
                try message.send(to: server, resource: resource, principal: authenticator.principal, completionHandler: completion)
            }
            else {
                throw MedKitError.notFound
            }

        default :
            throw MedKitError.notFound
        }
    }
    
    /**
     RPC did receive notification.
     
     - Parameters:
     - rpc
     - method:
     - args:
     */
    func rpc(_ rpc: RPCV1, didReceive message: AnyCodable) throws
    {
        let container = try message.decoder.container(keyedBy: MIPV1RouteCodingKeys.self)
        let path      = try container.decode([UUID].self, forKey: .path)
        let content   = try container.decode(AnyCodable.self, forKey: .content)

        switch path.count {
        case 1 :
            if let authenticate = findAuthenticator(path: path) {
                try authenticate.received(message: content)
            }
            if let device = server?.registry.findDevice(path: path) {
                try decode(device: device, from: content)
            }

        case 2 :
            if let service = server?.registry.findService(path: path) {
                try decode(service: service, from: content)
            }

        case 3 :
            if let resource = server?.registry.findResource(path: path) {
                try decode(resource: resource, from: content)
            }

        default :
            throw MedKitError.notFound
        }
    }
    
}


// End of File
