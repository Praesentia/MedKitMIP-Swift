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
 Authenticator Version 1, challange-response protocol.
 */
class AuthenticatorV1: Authenticator {
    
    enum Method: Int {
        case Phase1 = 1;
        case Phase2 = 2;
        case Phase3 = 3;
        case Accept = 4;
        case Reject = 5;
    }
    
    // MARK: - Private Properties
    
    private enum State {
        case idle;   // Idle state.
        case Phase2; // waiting for phase2 message
        case Phase3; // waiting for phase3 message
        case Phase4; // waiting for accept/reject message
    }
    
    private let Path      = [ JSON(UUID.null) ];
    private let NonceSize = 32;
    
    private let schema      = AuthenticatorV1Schema();
    private var state       : State = .idle;
    private var nonceClient : [UInt8]!;
    private var nonceServer : [UInt8]!;
    
    // MARK: -
    
    /**
     Authenticator identity.
     */
    override func authenticate(completionHandler completion: @escaping (Error?) -> Void)
    {
        super.authenticate(completionHandler: completion);
        
        if myself != nil {
            phase0();
        }
        else {
            rejected(for: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    override func didClose()
    {
        if state != .idle {
            print("closed");
            rejected(for: .ProtocolError, fatal: false);
        }
    }
    
    /**
     Reset state.
     */
    override func reset()
    {
        clear(nonce: nonceClient); // TODO
        clear(nonce: nonceServer);
        
        state       = .idle;
        nonceClient = nil;
        nonceServer = nil;
        
        super.reset();
    }
    
    // MARK: - Phases
    
    /**
     Phase 0 (Client-Side).
     
     Initiates an authentication exchange with the server, sending a message
     containing the client's nonce.
     */
    private func phase0()
    {
        guard(state == .idle) else { rejected(for: MedKitError.ProtocolError, fatal: true); return; }
        
        let args = JSON();
        
        nonceClient = SecurityManagerShared.main.randomBytes(count: NonceSize);
        
        args[KeyNonce] = nonceClient.base64EncodedString;
        
        state = .Phase2;
        send(method: .Phase1, args: args);
    }
    
    /**
     Phase 1 (Server-Side).
     */
    private func phase1(_ args: JSON)
    {
        print("phase 1");
        
        guard(state == .idle) else { rejected(for: MedKitError.ProtocolError, fatal: true); return; }
        
        nonceClient = decodeBase64(args[KeyNonce].string!);
        nonceServer = SecurityManagerShared.main.randomBytes(count: NonceSize);
        
        if let serverKey = calculateServerKey(server: myself) {
            let reply = JSON();
            
            reply[KeyPrincipal] = myself.profile;
            reply[KeyNonce]     = nonceServer.base64EncodedString;
            reply[KeyKey]       = serverKey.base64EncodedString;
            
            state = .Phase3;
            send(method: .Phase2, args: reply);
        }
        else {
            reject(for: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    /**
     Phase 2 (Client-Side).
     */
    private func phase2(_ args: JSON)
    {
        print("phase 2");
        
        guard(state == .Phase2) else { rejected(for: MedKitError.ProtocolError, fatal: true); return; }
        
        peer        = Principal(from: args[KeyPrincipal]);
        nonceServer = decodeBase64(args[KeyNonce].string!);
        
        let key = decodeBase64(args[KeyKey].string!)!;
        
        if verifyServer(server: peer!, key: key) {
            if let clientKey = calculateClientKey(client: myself) {
                let reply = JSON();
                
                reply[KeyPrincipal] = myself.profile;
                reply[KeyKey]       = clientKey.base64EncodedString;
            
                state = .Phase4;
                send(method: .Phase3, args: reply);
            }
            else {
                reject(for: MedKitError.BadCredentials, fatal: true);
            }
        }
    }
    
    /**
     Phase 3 (Server-Side).
     */
    private func phase3(_ args: JSON)
    {
        print("phase 3");
        
        guard(state == .Phase3) else { rejected(for: MedKitError.ProtocolError, fatal: true); return; }
        
        let client = Principal(from: args[KeyPrincipal])
        let key    = decodeBase64(args[KeyKey].string!)!;
        
        if verifyClientKey(client: client, key: key) {
            if shouldAccept(principal: client) {
                accept(principal: client);
            }
            else {
                reject(for: MedKitError.Rejected, fatal: true);
            }
        }
        else {
            reject(for: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    /**
     Phase 4 (Client-Side).
     
     Authenication accepted by the server.
     */
    private func phase4()
    {
        print("phase 4");
        
        guard(state == .Phase4) else { rejected(for: MedKitError.ProtocolError, fatal: true); return; }
        
        accepted(principal: peer!);
    }
    
    /**
     Accept
     */
    private func accept(principal: Principal)
    {
        print("accept");
        
        send(method: .Accept);
        accepted(principal: principal);
    }
    
    /**
     Reject
     */
    private func reject(for reason: MedKitError, fatal: Bool)
    {
        print("reject \(reason.localizedDescription)");
        
        sendReject(for: reason);
        rejected(for: reason, fatal: fatal);
    }
    
    // MARK: - Utilities
    
    /**
     Clear authenticator state. TODO
     */
    private func clear(nonce: [UInt8]?)
    {
        if var data = nonce {
            for i in 0..<data.count {
                data[i] = UInt8(0);
            }
        }
    }
    
    /**
     Generate client key for myself.
     */
    private func calculateClientKey(client: Principal) -> [UInt8]?
    {
        let sha256 = SecurityManagerShared.main.digest(using: .SHA256);
        
        sha256.update(bytes: nonceClient);
        sha256.update(bytes: nonceServer);
        
        return client.credentials.sign(bytes: sha256.final());
    }
    
    /**
     Verify client key.
     */
    private func verifyClientKey(client: Principal, key: [UInt8]) -> Bool
    {
        let digest = SecurityManagerShared.main.digest(using: .SHA256);
        
        digest.update(bytes: nonceClient);
        digest.update(bytes: nonceServer);
        
        return client.credentials.verify(signature: key, for: digest.final());
    }
    
    /**
     Generate server key for myself.
     */
    private func calculateServerKey(server: Principal) -> [UInt8]?
    {
        let digest = SecurityManagerShared.main.digest(using: .SHA256);
        
        digest.update(bytes: nonceServer);
        digest.update(bytes: nonceClient);
        
        return server.credentials.sign(bytes: digest.final());
    }
    
    /**
     Verify server identity.
     
     - Parameters:
        - server: A principal representing the server.
        - key:    The key presented by the server.
     */
    private func verifyServer(server: Principal, key: [UInt8]) -> Bool
    {
        if server.trusted {
            if verifyServerKey(server: server, key: key) {
                if shouldAccept(principal: server) {
                    return true;
                }
                reject(for: MedKitError.Rejected, fatal: true);
                return false;
            }
        }

        reject(for: MedKitError.BadCredentials, fatal: true);
        return false;
    }
    
    /**
     Verify server key.
     
     - Parameters:
        - server: A principal representing the server.
        - key:    The key presented by the server.
     */
    private func verifyServerKey(server: Principal, key: [UInt8]) -> Bool
    {
        let digest = SecurityManagerShared.main.digest(using: .SHA256);
        
        digest.update(bytes: nonceServer);
        digest.update(bytes: nonceClient);
        
        return server.credentials.verify(signature: key, for: digest.final());
    }
    
    // MARK: - Message Handling
    
    /**
     Decode synchronous message.
     
     Unsupported.
     */
    override func decode(method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async() { completion(nil, MedKitError.NotSupported); }
    }
    
    /**
     Decode asynchronous message.
     */
    override func decode(method: Int, args: JSON)
    {
        if schema.verifyAsync(method: method, args: args) {
            switch Method(rawValue: method)! {
            case .Phase1 :
                phase1(args);
                
            case .Phase2 :
                phase2(args);
                
            case .Phase3 :
                phase3(args);
                
            case .Accept :
                phase4();
                
            case .Reject :
                rejected(for: MedKitError(rawValue: args[KeyError].int!)!, fatal: false);
            }
        }
        else {
            reject(for: MedKitError.BadArgs, fatal: true);
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
        let message = JSON();
        
        message[KeyPath]   = Path;
        message[KeyMethod] = method.rawValue;
        
        if let args = args {
            message[KeyArgs] = args;
        }
        
        DispatchQueue.main.async() { self.rpc.async(message: message); }
    }
    
    /**
     Send reject message.
     
     - Parameters:
        - reason: Reason for rejection.
     */
    private func sendReject(for reason: MedKitError)
    {
        let args = JSON();
        
        args[KeyError] = reason.rawValue;
        
        send(method: .Reject, args: args);
    }
    
}


// End of File
