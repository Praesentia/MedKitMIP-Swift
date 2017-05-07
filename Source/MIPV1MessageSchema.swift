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
 MIP Version 1, message schema.
 */
class MIPV1MessageSchema {
    
    func verify(message: JSON) -> Bool
    {
        let check = Check();
        var count : Int = 2;
        
        check += message.type == .Object;
        
        check += message.contains(key: KeyPath);
        check += message.contains(key: KeyMethod);
        if message.contains(key: KeyArgs) {
            count += 1;
        }
        
        check += message[KeyPath].type   == .Array;
        check += message[KeyMethod].type == .Number;

        if check.value {
            check += verifyPath(message[KeyPath].array!);
        }
        
        check += message.object!.count == count;
        return check.value;
    }
    
    private func verifyPath(_ path: [JSON]) -> Bool
    {
        let check = Check();
        
        for component in path {
            check += component.type == .String;
        }
        
        check += path.count >= 1;
        return check.value;
    }
    
}


// End of File
