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
 Authenticator delegate.
 */
protocol AuthenticatorDelegate: class {
    
    func authenticate(_ authenticate: Authenticator, didAccept principal: Principal)
    func authenticate(_ authenticate: Authenticator, shouldAccept principal: Principal) -> Bool
    
}

/**
 Authenticator
 
 A base class for various authentication implementations.
 */
class Authenticator {
    
    // MARK: - Properties
    weak var delegate  : AuthenticatorDelegate?
    var      principal : Principal?
    
    // protected
    let rpc              : RPCV1
    let principalManager : PrincipalManager
    var myself           : Principal?
    var peer             : Principal?
    
    // MARK: - Private
    private var completion : ((Error?) -> Void)?
    
    /**
     Initialize instance.
     */
    init(rpc: RPCV1, using principalManager: PrincipalManager)
    {
        self.rpc              = rpc
        self.principalManager = principalManager
    }
    
    /**
     Authenticate identity.
     */
    func authenticate(completionHandler completion: @escaping (Error?) -> Void)
    {
        self.completion = completion
    }
    
    func didClose()
    {
    }
    
    func received(message: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) -> Void) throws
    {
        throw MedKitError.notSupported
    }
    
    func received(message: AnyCodable) throws
    {
        throw MedKitError.notImplemented
    }
    
    /**
     Determine whether or not the principal should be accepted.
     */
    func shouldAccept(principal: Principal) -> Bool
    {
        return delegate?.authenticate(self, shouldAccept: principal) ?? true
    }
    
    /**
     Principal has been accepted.
     */
    func accepted(principal: Principal)
    {
        self.principal = principal
        
        delegate?.authenticate(self, didAccept: principal)
        
        if let completion = self.completion {
            DispatchQueue.main.async { completion(nil) }
        }
        
        reset()
    }
    
    /**
     Terminate authentication exchange.
     
     Rejection may be received from the peer or as the result of a internal
     error.
     
     - Parameters:
        - reason: The reason for rejection.
        - fatal:  Indicates whether or not the connection should be closed.
     */
    func rejected(for reason: MedKitError, fatal: Bool)
    {
        if let completion = self.completion {
            DispatchQueue.main.async {
                completion(reason)
            }
        }
        
        reset()
        
        if fatal {
            DispatchQueue.main.async {
                self.rpc.shutdown(for: reason)
            }
        }
    }
    
    /**
     Reset authentiction instance.
     */
    func reset()
    {
        myself     = nil
        completion = nil
    }
    
}


// End of File
