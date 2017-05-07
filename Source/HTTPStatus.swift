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


/**
 HTTP Status
 */
enum HTTPStatus: Int {
    case Continue           = 100;
    case SwitchingProtocols = 101;
    case Processing         = 102;
    case OK                 = 200;
    case BadRequest         = 400;
    case Unauthorized       = 401;
    case PaymentRequired    = 402;
    case Forbidden          = 403;
    case NotFound           = 404;
}


// End of File
