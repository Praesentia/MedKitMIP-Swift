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
 Authenticator Version 1, message schema.
 */
class AuthenticatorV1Schema {
    
    func verifyAsync(method: Int, args: JSON) -> Bool
    {
        switch method {
        case 1 :
            return verifyPhase1(args: args)
            
        case 2 :
            return verifyPhase2(args: args)
            
        case 3 :
            return verifyPhase3(args: args)
            
        case 4 :
            return true
            
        case 5 :
            return true
            
        default :
            return false
        }
    }
    
    private func verifyPhase1(args: JSON) -> Bool
    {
        let check = Check()
        
        check += args.type == .Object
        check += args.contains(key: KeyNonce)
        
        if check.value {
            check += args[KeyNonce].type == .String
        }
        
        return check.value
    }
    
    private func verifyPhase2(args: JSON) -> Bool
    {
        let check = Check()
        
        check += args.type == .Object
        check += args.contains(key: KeyNonce)
        
        if check.value {
            check += args[KeyNonce].type == .String
        }
        
        return check.value
    }
    
    private func verifyPhase3(args: JSON) -> Bool
    {
        let check = Check()
        
        check += args.type == .Object
        check += args.contains(key: KeyPrincipal)
        check += args.contains(key: KeyKey)
        
        if check.value {
            check += verifyPrincipal(args: args[KeyPrincipal])
            check += args[KeyKey].type == .String
        }
        
        return check.value
    }
    
    private func verifyPrincipal(args: JSON) -> Bool
    {
        let check = Check()
        
        check += args.type == .Object
        check += args.contains(key: KeyAuthorization)
        check += args.contains(key: KeyCredentials)
        check += args.contains(key: KeyIdentity)
        
        if check.value {
            check += verifyTrust(profile: args[KeyIdentity])
            check += verifyCredentials(profile: args[KeyCredentials])
        }
        
        return check.value
    }
    
    private func verifyTrust(profile: JSON) -> Bool
    {
        let check = Check()
        
        check += profile.type == .Object
        check += profile.contains(key: SecurityKit.KeyName)
        check += profile.contains(key: SecurityKit.KeyType)
        
        if check.value {
            check += profile[SecurityKit.KeyName].type == .String
            check += profile[SecurityKit.KeyType].type == .String // TODO
        }
        
        return check.value
    }
    
    private func verifyCredentials(profile: JSON) -> Bool
    {
        let check = Check()
        
        check += profile.type == .Object
        check += profile.contains(key: SecurityKit.KeyType)
        
        if check.value {
            check += profile[SecurityKit.KeyType].type == .String
        }
        
        return check.value
    }
    
}


// End of File
