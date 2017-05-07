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
            rejected(reason: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    override func didClose()
    {
        if state != .idle {
            rejected(reason: .ProtocolError, fatal: false);
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
    
    /**
     Phase 0 (Client-Side).
     
     Initiates an authentication exchange with the server, sending a message
     containing the client's nonce.
     */
    private func phase0()
    {
        guard(state == .idle) else { rejected(reason: MedKitError.ProtocolError, fatal: true); return; }
        
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
        guard(state == .idle) else { rejected(reason: MedKitError.ProtocolError, fatal: true); return; }
        
        nonceClient = decodeBase64(args[KeyNonce].string!);
        nonceServer = SecurityManagerShared.main.randomBytes(count: NonceSize);
        
        let reply = JSON();
        
        reply[KeyPrincipal] = myself.profile;
        reply[KeyNonce]     = nonceServer.base64EncodedString;
        
        state = .Phase3;
        send(method: .Phase2, args: reply);
    }
    
    /**
     Phase 2 (Client-Side).
     */
    private func phase2(_ args: JSON)
    {
        guard(state == .Phase2) else { rejected(reason: MedKitError.ProtocolError, fatal: true); return; }
        
        peer        = Principal(from: args[KeyPrincipal]);
        nonceServer = decodeBase64(args[KeyNonce].string!);
        
        if let clientKey = calculateClientKey(client: myself) {
            let reply = JSON();
            
            reply[KeyPrincipal] = myself.profile;
            reply[KeyKey] = clientKey.base64EncodedString;
        
            state = .Phase4;
            send(method: .Phase3, args: reply);
        }
        else {
            reject(reason: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    /**
     Phase 3 (Server-Side).
     */
    private func phase3(_ args: JSON)
    {
        guard(state == .Phase3) else { rejected(reason: MedKitError.ProtocolError, fatal: true); return; }
        
        let client = Principal(from: args[KeyPrincipal])
        let key    = decodeBase64(args[KeyKey].string!)!;
        
        if verifyClientKey(client: client, key: key) {
            if shouldAccept(principal: client) {
                accept(principal: client);
            }
            else {
                reject(reason: MedKitError.Rejected, fatal: true);
            }
        }
        else {
            reject(reason: MedKitError.BadCredentials, fatal: true);
        }
    }
    
    /**
     Phase 4 (Client-Side).
     
     Authenication accepted by the server.
     */
    private func phase4()
    {
        guard(state == .Phase4) else { rejected(reason: MedKitError.ProtocolError, fatal: true); return; }
    
        accepted(principal: peer!);
    }
    
    /**
     Accept
     */
    private func accept(principal: Principal)
    {
        send(method: .Accept);
        accepted(principal: principal);
    }
    
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
     Reject
     */
    private func reject(reason error: MedKitError, fatal: Bool)
    {
        sendReject(reason: error);
        rejected(reason: error, fatal: fatal);
    }
    
    /**
     Generate client key for myself.
     */
    private func calculateClientKey(client: Principal) -> [UInt8]?
    {
        let sha256 = SecurityManagerShared.main.digest(using: .SHA256);
        
        sha256.update(bytes: nonceClient);
        sha256.update(bytes: nonceServer);
        sha256.update(string: client.identity.string);
        sha256.update(string: client.authorization.string);
        
        return client.credentials.sign(bytes: sha256.final());
    }
    
    /**
     Verify client key.
     */
    private func verifyClientKey(client: Principal, key: [UInt8]) -> Bool
    {
        let sha256 = SecurityManagerShared.main.digest(using: .SHA256);
        
        sha256.update(bytes: nonceClient);
        sha256.update(bytes: nonceServer);
        sha256.update(string: client.identity.string);
        sha256.update(string: client.authorization.string);
        
        return client.credentials.verify(signature: key, bytes: sha256.final());
    }
    
    /**
     Generate server key for myself.
     */
    private func calculateServerKey(server: Principal) -> [UInt8]?
    {
        let sha256 = SecurityManagerShared.main.digest(using: .SHA256);
        
        sha256.update(bytes: nonceServer);
        sha256.update(bytes: nonceClient);
        sha256.update(string: server.identity.string);
        
        return server.credentials.sign(bytes: sha256.final());
    }
    
    /**
     Verify server key.
     */
    private func verifyServerKey(server: Principal, key: [UInt8]) -> Bool
    {
        let sha256 = SecurityManagerShared.main.digest(using: .SHA256);
        
        sha256.update(bytes: nonceServer);
        sha256.update(bytes: nonceClient);
        sha256.update(string: server.identity.string);
        
        return server.credentials.verify(signature: key, bytes: sha256.final());
    }
    
    override func decode(method: Int, args: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        DispatchQueue.main.async() { completion(nil, MedKitError.NotSupported); }
    }
    
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
                rejected(reason: MedKitError(rawValue: args[KeyError].int!)!, fatal: false);
            }
        }
        else {
            reject(reason: MedKitError.BadArgs, fatal: true);
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
    private func sendReject(reason error: MedKitError)
    {
        let args = JSON();
        
        args[KeyError] = error.rawValue;
        
        send(method: .Reject, args: args);
    }
    
}


// End of File
