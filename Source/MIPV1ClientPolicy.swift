/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2017 Jon Griffeth
 
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
 MIP Version 1, client connection policy.
 */
class MIPV1ClientPolicy: PortSecurePolicy {
    
    // MARK: - Private Properties
    private var peerIdentity: Identity;
    
    // MARK: - Initializers
    
    init(for peerIdentity: Identity)
    {
        self.peerIdentity = peerIdentity;
    }
    
    // MARK: -
    
    func portShouldAuthenticatePeer(_ port: PortSecure) -> Bool
    {
        return true;
    }
    
    func port(_ port: PortSecure, shouldAccept peer: Principal) -> Bool
    {
        return peer.identity == peerIdentity;
    }
    
}


// End of File
