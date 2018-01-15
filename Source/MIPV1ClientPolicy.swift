/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2017-2018 Jon Griffeth
 
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
 MIP Version 1, client connection policy.
 */
class MIPV1ClientPolicy: TLSDelegate {

    
    // MARK: - Private Properties
    private var peerIdentity: Identity
    
    // MARK: - Initializers
    
    init(for peerIdentity: Identity)
    {
        self.peerIdentity = peerIdentity
    }
    
    // MARK: -
    
    func tlsCredentials(_ tls: TLS) -> PublicKeyCredentials?
    {
        return nil
    }
    
    func tlsPeerName(_ tls: TLS) -> String?
    {
        return peerIdentity.string
    }

    func tlsPeerAuthenticationComplete(_ tls: TLS) -> Error?
    {
        var error: Error?

        if !verifyCredentials() {
            error = SecurityKitError.badCredentials
        }
        return error
    }
    
    func tlsShouldAuthenticatePeer(_ tls: TLS) -> Bool
    {
        return true
    }
    
    func tls(_ tls: TLS, shouldAccept peer: Principal) -> Bool
    {
        return peer.identity == peerIdentity
    }

    /**
     */
    private func verifyCredentials() -> Bool
    {
        /*
        if let trust = tls.peerTrust {

            var status: OSStatus
            var result: SecTrustResultType = .invalid

            // set anchor certificates
            let (anchorCertificates, error) = Keychain.main.findRootCertificates()
            guard error == nil else { return false }

            status = trust.setAnchorCertificates(anchorCertificates!)
            guard status == errSecSuccess else { return false }

            // evaluate trust
            status = trust.evaluate(&result)
            guard status == errSecSuccess else { return false }

            return result == .unspecified
        }

        return false
        */
        return true
    }
    
}


// End of File
