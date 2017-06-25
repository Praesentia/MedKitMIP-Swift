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


// WebSocket Constants
let MIPV1Priority     = 0        //: Protocol priority.
let MIPV1WSPath       = "/mip"   //: WebSocket URL path.
let ProtocolNameMIPV1 = "mip-v1" //: Protocol type.


class MIPV1: DeviceProtocol {
    
    static let main = MIPV1()
    
    let description   : String = "Medical Interoperability Protocol, Version 1 Beta (1)"
    let identifier    : String = ProtocolNameMIPV1
    let name          : String = "MIP"
    let priority      : Int    = 0
    let version       : String = "1"
    
    let clientFactory : ClientConnectionFactory = MIPV1ClientConnection.factory
    let serverFactory : ServerConnectionFactory = MIPV1ServerConnection.factory
    
}

/**
 MIP Version 1, Device Method
 */
enum MIPV1DeviceMethod: Int {
    case GetProfile = 1
    case UpdateName = 2
}

/**
 MIP Version 1, Device Notification
 */
enum MIPV1DeviceNotification: Int {
    case DidUpdateName          = 1
    case DidAddBridgedDevice    = 2
    case DidRemoveBridgedDevice = 3
    case DidAddService          = 4
    case DidRemoveService       = 5
}

/**
 MIP Version 1, Service Method
 */
enum MIPV1ServiceMethod: Int {
    case UpdateName = 1
}

/**
 MIP Version 1, Service Notification
 */
enum MIPV1ServiceNotification: Int {
    case DidUpdateName     = 1
    case DidAddResource    = 2
    case DidRemoveResource = 3
}

/**
 MIP Version 1, Resource Method
 */
enum MIPV1ResourceMethod: Int {
    case DisableNotification = 1
    case EnableNotification  = 2
    case ReadValue           = 3
    case WriteValue          = 4
}

/**
 MIP Version 1, Resource Notification
 */
enum MIPV1ResourceNotification: Int {
    case DidUpdate = 1
}


// End of File
