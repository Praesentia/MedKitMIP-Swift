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
import SecurityKit


/**
 Authenticator Version 1, challange-response protocol.
 */
class AuthenticatorV1: Authenticator {
    
    enum Method: Int {
        case phase1 = 1
        case phase2 = 2
        case phase3 = 3
        case accept = 4
        case reject = 5
    }
    
    // MARK: - Private Properties
    
    private enum State {
        case idle                      // Idle state.
        case waitingForServerResponse  // Waiting for server response.
        case processingServerResponse  // Processing server response.
        case waitingForClientResponse  // Waiting for client response.
        case processingClientResponse  // Processing client response.
        case waitingForServer          // Waiting for accept/reject message
    }
    
    private let Path      = [ JSON(UUID.null) ]
    private let NonceSize = 32
    
    private let schema      = AuthenticatorV1Schema()
    private var state       : State = .idle
    private var nonceClient : [UInt8]!
    private var nonceServer : [UInt8]!
    
    // MARK: -
    
    /**
     Authenticator identity.
     */
    override func authenticate(completionHandler completion: @escaping (Error?) -> Void)
    {
        super.authenticate(completionHandler: completion)
        
        if myself != nil {
            phase0()
        }
        else {
            rejected(for: MedKitError.badCredentials, fatal: true)
        }
    }
    
    override func didClose()
    {
        if state != .idle {
            rejected(for: .protocolError, fatal: false)
        }
    }
    
    /**
     Reset state.
     */
    override func reset()
    {
        clear(nonce: nonceClient) // TODO
        clear(nonce: nonceServer)
        
        state       = .idle
        nonceClient = nil
        nonceServer = nil
        
        super.reset()
    }
    
    // MARK: - Phases
    
    /**
     Phase 0 (Client-Side).
     
     Initiates an authentication exchange with the server, sending a message
     containing the client's nonce.
     */
    private func phase0()
    {
        guard(state == .idle) else { rejected(for: MedKitError.protocolError, fatal: true); return }
        
        let args = JSON()
        
        nonceClient = SecurityManagerShared.main.randomBytes(count: NonceSize)
        
        args[KeyNonce] = nonceClient.base64EncodedString
        
        state = .waitingForServerResponse
        send(method: .phase1, args: args)
    }
    
    /**
     Phase 1 (Server-Side).
     */
    private func phase1(_ args: JSON)
    {
        guard(state == .idle) else { rejected(for: MedKitError.protocolError, fatal: true); return }
        
        nonceClient = decodeBase64(args[KeyNonce].string!)
        nonceServer = SecurityManagerShared.main.randomBytes(count: NonceSize)
        
        if let serverKey = calculateServerKey(server: myself) {
            let reply = JSON()
            
            reply[KeyPrincipal] = myself.profile
            reply[KeyNonce]     = nonceServer.base64EncodedString
            reply[KeyKey]       = serverKey.base64EncodedString
            
            state = .waitingForClientResponse
            send(method: .phase2, args: reply)
        }
        else {
            reject(for: MedKitError.badCredentials, fatal: true)
        }
    }
    
    /**
     Phase 2 (Client-Side).
     */
    private func phase2(_ args: JSON)
    {
        guard(state == .waitingForServerResponse) else { rejected(for: .protocolError, fatal: true); return }
        let sync = MedKitCore.SyncT<MedKitError>(.badCredentials)
        
        state       = .processingServerResponse
        nonceServer = decodeBase64(args[KeyNonce].string!)
        
        sync.incr()
        Principal.instantiate(from: args[KeyPrincipal]) { principal, error in
            
            if error == nil, let server = principal {
                if server.credentials.valid(for: Date()) {
                    let key = decodeBase64(args[KeyKey].string!)!
                    
                    if self.verifyServer(server: server, key: key) {
                        if let clientKey = self.calculateClientKey(client: self.myself) {
                            let reply = JSON()
                            
                            reply[KeyPrincipal] = self.myself.profile
                            reply[KeyKey]       = clientKey.base64EncodedString
                        
                            self.state = .waitingForServer
                            self.send(method: .phase3, args: reply)
                            sync.clear()
                        }
                    }
                }
            }
            
            sync.decr(nil)
        }
        
        sync.close() { error in
            if error != nil {
                self.reject(for: error!, fatal: true)
            }
        }
    }
    
    /**
     Phase 3 (Server-Side).
     */
    private func phase3(_ args: JSON)
    {
        guard(state == .waitingForClientResponse) else { rejected(for: .protocolError, fatal: true); return }
        let sync = SecurityKit.SyncT<MedKitError>(.badCredentials)
        
        state = .processingClientResponse
        
        sync.incr()
        Principal.instantiate(from: args[KeyPrincipal]) { principal, error in
            
            if error == nil, let client = principal {
                if client.credentials.valid(for: Date()) {
                    let key = decodeBase64(args[KeyKey].string!)!
                    
                    if self.verifyClientKey(client: client, key: key) {
                        if self.shouldAccept(principal: client) {
                            self.accept(principal: client)
                            sync.clear()
                        }
                    }
                }
            }
    
            sync.decr(nil)
        }
    
        sync.close() { error in
            if error != nil {
                self.reject(for: error!, fatal: true)
            }
        }
    }
    
    /**
     Phase 4 (Client-Side).
     
     Authenication accepted by the server.
     */
    private func phase4()
    {
        guard(state == .waitingForServer) else { rejected(for: MedKitError.protocolError, fatal: true); return }
        
        accepted(principal: peer!)
    }
    
    /**
     Accept
     */
    private func accept(principal: Principal)
    {
        send(method: .accept)
        accepted(principal: principal)
    }
    
    /**
     Reject
     */
    private func reject(for reason: MedKitError, fatal: Bool)
    {
        sendReject(for: reason)
        rejected(for: reason, fatal: fatal)
    }
    
    // MARK: - Utilities
    
    /**
     Clear authenticator state. TODO
     */
    private func clear(nonce: [UInt8]?)
    {
        if var data = nonce {
            for i in 0..<data.count {
                data[i] = UInt8(0)
            }
        }
    }
    
    /**
     Generate client key for myself.
     */
    private func calculateClientKey(client: Principal) -> [UInt8]?
    {
        let sha256 = SecurityManagerShared.main.digest(using: .sha256)
        
        sha256.update(bytes: nonceClient)
        sha256.update(bytes: nonceServer)
        
        return client.credentials.sign(bytes: sha256.final(), padding: .sha256)
    }
    
    /**
     Verify client key.
     */
    private func verifyClientKey(client: Principal, key: [UInt8]) -> Bool
    {
        let digest = SecurityManagerShared.main.digest(using: .sha256)
        
        digest.update(bytes: nonceClient)
        digest.update(bytes: nonceServer)
        
        return client.credentials.verify(signature: key, padding: .sha256, for: digest.final())
    }
    
    /**
     Generate server key for myself.
     */
    private func calculateServerKey(server: Principal) -> [UInt8]?
    {
        let digest = SecurityManagerShared.main.digest(using: .sha256)
        
        digest.update(bytes: nonceServer)
        digest.update(bytes: nonceClient)
        
        return server.credentials.sign(bytes: digest.final(), padding: .sha256)
    }
    
    /**
     Verify server identity.
     
     - Parameters:
        - server: A principal representing the server.
        - key:    The key presented by the server.
     */
    private func verifyServer(server: Principal, key: [UInt8]) -> Bool
    {
        if verifyServerKey(server: server, key: key) {
            if shouldAccept(principal: server) {
                self.peer = server
                return true
            }
            reject(for: MedKitError.rejected, fatal: true)
            return false
        }

        reject(for: MedKitError.badCredentials, fatal: true)
        return false
    }
    
    /**
     Verify server key.
     
     - Parameters:
        - server: A principal representing the server.
        - key:    The key presented by the server.
     */
    private func verifyServerKey(server: Principal, key: [UInt8]) -> Bool
    {
        let digest = SecurityManagerShared.main.digest(using: .sha256)
        
        digest.update(bytes: nonceServer)
        digest.update(bytes: nonceClient)
        
        return server.credentials.verify(signature: key, padding: .sha256, for: digest.final())
    }
    
    // MARK: - Message Handling
    
    /**
     Decode synchronous message.
     
     Unsupported.
     */
    override func decode(method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async { completion(nil, MedKitError.notSupported) }
    }
    
    /**
     Decode asynchronous message.
     */
    override func decode(method: Int, args: JSON)
    {
        if schema.verifyAsync(method: method, args: args) {
            switch Method(rawValue: method)! {
            case .phase1 :
                phase1(args)
                
            case .phase2 :
                phase2(args)
                
            case .phase3 :
                phase3(args)
                
            case .accept :
                phase4()
                
            case .reject :
                rejected(for: MedKitError(rawValue: args[KeyError].int!)!, fatal: false)
            }
        }
        else {
            reject(for: MedKitError.badArgs, fatal: true)
        }
    }
    
    /**
     Send message.
     
     - Parameters:
        - method: Method identifier.
        - args:   Message arguments.
     */
    private func send(method: Method, args: JSON? = nil)
    {
        let message = JSON()
        
        message[KeyPath]   = Path
        message[KeyMethod] = method.rawValue
        
        if let args = args {
            message[KeyArgs] = args
        }
        
        DispatchQueue.main.async { self.rpc.async(message: message) }
    }
    
    /**
     Send reject message.
     
     - Parameters:
        - reason: Reason for rejection.
     */
    private func sendReject(for reason: MedKitError)
    {
        let args = JSON()
        
        args[KeyError] = reason.rawValue
        
        send(method: .reject, args: args)
    }
    
}


// End of File
