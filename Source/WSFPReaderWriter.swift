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


/**
 Queue
 */
class WSFPReaderWriter {
    
    enum OpCode: UInt8 {
        case ContinuationFrame = 0x00
        case TextFrame         = 0x01
        case BinaryFrame       = 0x02
        case Close             = 0x08
        case Ping              = 0x09
        case Pong              = 0x0a
    }
    
    // constants
    let MinSize           : Int    = 2
    let PayloadMode7Bit   : UInt8  = 0
    let PayloadMode16Bit  : UInt8  = 126
    let PayloadMode64Bit  : UInt8  = 127
    let PayloadMin16Bit   : UInt64 = 126
    let PayloadMin64Bit   : UInt64 = 65536
    let PayloadSizeOffset : Int    = 2
    let MaskingKeySize    : Int    = 4
    
    // bit masks
    let PayloadSizeMask  : UInt8  = 0x7f
    let MASKING_KEY      : UInt8  = 0x80
    let FIN              : UInt8  = 0x80
    let RSV1             : UInt8  = 0x40
    let RSV2             : UInt8  = 0x20
    let RSV3             : UInt8  = 0x10
    let OPCODE           : UInt8  = 0x0f
}


// End of File
