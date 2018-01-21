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


// WebSocket Constants
let MIPV1Priority     = 0        //: Protocol priority.
let MIPV1WSPath       = "/mip"   //: WebSocket URL path.
let ProtocolNameMIPV1 = "mip-v1" //: Protocol type.


class MIPV1: ProtocolPlugin {
    
    static let main = MIPV1()

    let localizedDescription : String       = "Medical Interoperability Protocol, Version 1 Beta"
    let priority             : Int          = 0
    let type                 : ProtocolType = ProtocolType(withIdentifier: ProtocolNameMIPV1)
    let version              : String       = "1"
    
    let clientFactory : ClientConnectionFactory = MIPV1ClientConnection.factory
    let serverFactory : ServerConnectionFactory = MIPV1ServerConnection.factory
    
}

/**
 MIP Version 1, Device Method
 */
enum MIPV1DeviceMethodType: Int, Codable {
    case getProfile = 1
    case updateName = 2
}

/**
 MIP Version 1, Device Notification
 */
enum MIPV1DeviceNotificationType: Int, Codable {
    case didUpdateName          = 1
    case didAddBridgedDevice    = 2
    case didRemoveBridgedDevice = 3
    case didAddService          = 4
    case didRemoveService       = 5
}

/**
 MIP Version 1, Service Method
 */
enum MIPV1ServiceMethodType: Int, Codable {
    case updateName = 1
}

/**
 MIP Version 1, Service Notification
 */
enum MIPV1ServiceNotificationType: Int, Codable {
    case didUpdateName     = 1
    case didAddResource    = 2
    case didRemoveResource = 3
}

/**
 MIP Version 1, Resource Method
 */
enum MIPV1ResourceMethodType: Int, Codable {
    case call                = 1
    case enableNotification  = 2
}

/**
 MIP Version 1, Resource Notification
 */
enum MIPV1ResourceNotificationType: Int, Codable {
    case notify = 1
}


// End of File
