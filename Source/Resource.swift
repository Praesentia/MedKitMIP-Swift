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
 Resource extensions.
 */
extension Resource {
    
    /**
     Make path.
     */
    var path: JSON
    {
        return JSON([ JSON(service!.device!.identifier), JSON(service!.identifier), JSON(identifier) ]);
    }
    
}

/**
 ResourceBackend extensions.
 */
extension ResourceBackend {
    
    /**
     Make path.
     */
    var path: JSON
    {
        return JSON([ JSON(serviceBackend.deviceBackend.identifier), JSON(serviceBackend.identifier), JSON(identifier) ]);
    }
    
}


// End of File
