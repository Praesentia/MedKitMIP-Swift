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


/**
 MIP Device Schema
 */
class MIPV1DeviceSchema {
    
    func verifySync(method: MIPV1DeviceMethod, args: JSON) -> Bool
    {
        return true // TODO
    }
    
    func verifyReply(method: MIPV1DeviceMethod, reply: JSON?) -> Bool
    {
        return true // TODO
    }
    
    func verifyAsync(method: MIPV1DeviceNotification, args: JSON) -> Bool
    {
        return true
    }
    
}


// End of File
