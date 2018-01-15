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
import SecurityKit


/**
 Authenticator Version 1, challange-response protocol.
 */
class AuthenticatorV1: Authenticator {

    // MARK: - Private Properties
    
    private enum State {
        case idle                      // Idle state.
        case waitingForServerResponse  // Waiting for server response.
        case processingServerResponse  // Processing server response.
        case waitingForClientResponse  // Waiting for client response.
        case processingClientResponse  // Processing client response.
        case waitingForServer          // Waiting for accept/reject message
    }
    
    private let path        = [ UUID.null ]
    private let nonceSize   = 32
    private var state       : State = .idle
    private var nonceClient : Data!
    private var nonceServer : Data!
    
    // MARK: -
    
    /**
     Authenticator identity.
     */
    override func authenticate(completionHandler completion: @escaping (Error?) -> Void)
    {
        super.authenticate(completionHandler: completion)
        
        myself = principalManager.primary
        
        if myself != nil {
            initiateAuthentication()
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
     Initiate authentication exchange.
     
     Initiates an authentication exchange with the server, sending a message
     containing the client's nonce.
     */
    private func initiateAuthentication()
    {
        guard(state == .idle) else { rejected(for: MedKitError.protocolError, fatal: true); return }

        nonceClient = Data(SecurityManagerShared.main.randomBytes(count: nonceSize))
        state       = .waitingForServerResponse

        send(message: AuthenticateV1Phase1(nonce: nonceClient))
    }
    
    /**
     Phase 1 (Server-Side).
     */
    func received(message: AuthenticateV1Phase1)
    {
        guard(state == .idle) else { rejected(for: MedKitError.protocolError, fatal: true); return }
        
        nonceClient = message.nonce
        nonceServer = Data(SecurityManagerShared.main.randomBytes(count: nonceSize))
        myself      = principalManager.primary
        
        if let principal = myself, let key = calculateServerKey(server: principal) {
            state = .waitingForClientResponse
            send(message: AuthenticateV1Phase2(principal: principal, nonce: nonceServer, key: key))
        }
        else {
            reject(for: MedKitError.badCredentials, fatal: true)
        }
    }
    
    /**
     Phase 2 (Client-Side).
     */
    func received(message: AuthenticateV1Phase2)
    {
        guard(state == .waitingForServerResponse) else { rejected(for: .protocolError, fatal: true); return }

        let server = message.principal
        let sync   = MedKitCore.SyncT<MedKitError>(.badCredentials)

        state       = .processingServerResponse
        nonceServer = message.nonce

        sync.incr()
        server.credentials.verifyTrust() { error in

            if true { // TODO
                if server.credentials.valid(for: Date()) && self.verifyServer(server: server, key: message.key) {
                    if let client = self.myself, let key = self.calculateClientKey(client: client) {
                        self.state = .waitingForServer
                        self.send(message: AuthenticateV1Phase3(principal: client, key: key))
                        sync.clear()
                    }
                }
            }
            else {
                NSLog("Credentials for \"\(server.identity.string)\" are not trusted.")
            }

            sync.decr(error as? MedKitError) // TODO
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
    func received(message: AuthenticateV1Phase3)
    {
        guard(state == .waitingForClientResponse) else { rejected(for: .protocolError, fatal: true); return }

        let client = message.principal
        let sync   = SecurityKit.SyncT<MedKitError>(.badCredentials)
        
        state = .processingClientResponse

        sync.incr()
        client.credentials.verifyTrust() { error in
            
            if true { // TODO
                if client.credentials.valid(for: Date()) && self.verifyClientKey(client: client, key: message.key) {
                    if self.shouldAccept(principal: client) {
                        self.accept(principal: client)
                        sync.clear()
                    }
                }
            }
            else {
                NSLog("Credentials for \"\(client.identity.string)\" are not trusted.")
            }
    
            sync.decr(error as? MedKitError) // TODO
        }

        sync.close() { error in
            if error != nil {
                self.reject(for: error!, fatal: true)
            }
        }
    }
    
    /**
     Phase 4 (Client-Side).
     
     Authentication accepted by the server.
     */
    func received(message: AuthenticateV1Accept)
    {
        guard(state == .waitingForServer) else { rejected(for: MedKitError.protocolError, fatal: true); return }
        accepted(principal: peer!)
    }

    /**
     Phase 5 (Client-Side).

     Authentication accepted by the server.
     */
    func received(message: AuthenticateV1Reject)
    {
        rejected(for: message.error, fatal: true)
    }

    /**
     Accept
     */
    private func accept(principal: Principal)
    {
        send(message: AuthenticateV1Accept())
        accepted(principal: principal)
    }
    
    /**
     Reject
     */
    private func reject(for reason: MedKitError, fatal: Bool)
    {
        send(message: AuthenticateV1Reject(error: reason))
        rejected(for: reason, fatal: fatal)
    }
    
    // MARK: - Utilities
    
    /**
     Clear authenticator state. TODO
     */
    private func clear(nonce: Data?)
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
    private func calculateClientKey(client: Principal) -> Data?
    {
        let data = Data(nonceClient + nonceServer)

        return client.credentials.sign(data: data, using: .sha256)
    }
    
    /**
     Verify client key.
     */
    private func verifyClientKey(client: Principal, key: Data) -> Bool
    {
        let data = Data(nonceClient + nonceServer)
        
        return client.credentials.verify(signature: key, for: data, using: .sha256)
    }
    
    /**
     Generate server key for myself.
     */
    private func calculateServerKey(server: Principal) -> Data?
    {
        let data = Data(nonceServer + nonceClient)
        
        return server.credentials.sign(data: data, using: .sha256)
    }
    
    /**
     Verify server identity.
     
     - Parameters:
        - server: A principal representing the server.
        - key:    The key presented by the server.
     */
    private func verifyServer(server: Principal, key: Data) -> Bool
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
    private func verifyServerKey(server: Principal, key: Data) -> Bool
    {
        let bytes = nonceServer + nonceClient
        
        return server.credentials.verify(signature: key, for: bytes, using: .sha256)
    }

    /**
     Send message.

     - Parameters:
        - method: Method identifier.
        - args:   Message arguments.
     */
    private func send(message: AuthenticateV1Message)
    {
        let message = MIPV1Route(path: [ UUID.null ], content: try! AnyCodable(AuthenticateV1MessageCoder(message: message)))

        DispatchQueue.main.async { self.rpc.async(content: try! AnyEncoder().encode(message)) }
    }
    
    // MARK: - Message Handling
    
    /**
     Decode asynchronous message.
     */
    override func received(message: AnyCodable) throws
    {
        let message = try AuthenticateV1MessageCoder(from: message.decoder).message
        message.send(to: self)
    }
    
}


// End of File
