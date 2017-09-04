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


import Foundation
import MedKitCore
import SecurityKit


/**
 MIP Version 1, server connection policy.
 */
class MIPV1ServerPolicy: PortSecurePolicy {
    
    // MARK: Private Properties
    private let principalManager: PrincipalManager
    
    // MARK: - Initializers
    
    init(principalManager: PrincipalManager)
    {
        self.principalManager = principalManager
    }
    
    // MARK: -
    
    func portCredentials(_ port: PortSecure) -> Credentials?
    {
        return principalManager.primary?.credentials
    }
    
    func portPeerName(_ port: PortSecure) -> String?
    {
        return nil
    }
    
    func portShouldAuthenticatePeer(_ port: PortSecure) -> Bool
    {
        return false
    }
    
    func port(_ port: PortSecure, shouldAccept peer: Principal) -> Bool
    {
        return true
    }
    
}


// End of File
