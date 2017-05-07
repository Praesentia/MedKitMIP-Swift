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
 Queue
 */
class WSFPReader: WSFPReaderWriter {
    
    enum OpCode : UInt8 {
        case ContinuationFrame = 0x00;
        case TextFrame         = 0x01;
        case BinaryFrame       = 0x02;
        case Close             = 0x08;
        case Ping              = 0x09;
        case Pong              = 0x0a;
    }
    
    var code         : WSFPReaderWriter.OpCode? { return self.opcode; }
    var isData       : Bool                     { return opcode == .ContinuationFrame || opcode == .TextFrame || opcode == .BinaryFrame; }
    var isControl    : Bool                     { return opcode == .Close || opcode == .Ping || opcode == .Pong; }
    var payload      : Data                     { return Data(payloadData!); }
    
    // header state
    private var valid        : Bool = false;
    private var contBuf      : [UInt8]?;
    private var fin          : Bool = false;
    private var maskingKey   : [UInt8]?;
    private var opcode       : WSFPReaderWriter.OpCode?;
    private var rsv1         : Bool = false;
    private var rsv2         : Bool = false;
    private var rsv3         : Bool = false;
    private var payloadSize  : UInt64 = 0;
    private var payloadData  : [UInt8]?;

    func reset()
    {
        fin         = false;
        opcode      = nil;
        maskingKey  = nil;
        rsv1        = false;
        rsv2        = false;
        rsv3        = false;
        payloadData = nil;
        payloadSize = 0;
        valid       = false;

    }
    
    /**
     Get message from queue.
     
     - Parameters:
        - queue:
     */
    func getMessage(from queue: DataQueue) -> Bool
    {
        if getHeader(from: queue) {
            if let payload = getPayload(from: queue) {
                
                if isControl { // control messages can be received at anytime
                    payloadData = payload;
                    return true;
                }
                
                if contBuf == nil {
                    contBuf  = payload;
                }
                else {
                    contBuf! += payload;
                }
                
                if fin {
                    payloadData = contBuf;
                    contBuf     = nil;
                }
                
                return fin;
            }
        }
        
        return false;
    }
    
    /**
     Get header from queue.
     
     - Parameters:
        - queue:
     */
    private func getHeader(from queue: DataQueue) -> Bool
    {
        if !valid && queue.count >= UInt64(MinSize) {
            
            var headerSize       : Int = MinSize;
            var headerBuf        : [UInt8]!;
            var maskingKeyOffset : Int = MinSize;
            var payloadMode      : UInt8;
            
            headerBuf = queue.peek(count: headerSize);
            
            let x = headerBuf[1];
            
            payloadMode = x & PayloadSizeMask;
            switch payloadMode {
            case PayloadMode16Bit :
                headerSize       += 2;
                maskingKeyOffset += 2;
                
            case PayloadMode64Bit :
                headerSize       += 8;
                maskingKeyOffset += 8;
                
            default :
                break;
            }
            
            if (headerBuf[1] & MASKING_KEY) == MASKING_KEY {
                headerSize += MaskingKeySize;
            }
            
            if queue.count >= UInt64(headerSize) {
                headerBuf = queue.read(count: headerSize);
                
                fin    = (headerBuf[0] & FIN ) == FIN;
                rsv1   = (headerBuf[0] & RSV1) == RSV1;
                rsv2   = (headerBuf[0] & RSV2) == RSV2;
                rsv3   = (headerBuf[0] & RSV3) == RSV3;
                let x  = headerBuf[0] & OPCODE;
                opcode = OpCode(rawValue: x);
                
                switch payloadMode {
                case PayloadMode16Bit :
                    payloadSize = decode16(headerBuf, PayloadSizeOffset);
                    
                case PayloadMode64Bit :
                    payloadSize = decode64(headerBuf, PayloadSizeOffset);
                    
                default :
                    payloadSize = UInt64(payloadMode);
                    break;
                }
                
                if (headerBuf[1] & MASKING_KEY) != 0 {
                    maskingKey = Array<UInt8>(headerBuf[maskingKeyOffset..<headerBuf.count]);
                }
            }
            
            if !verify() {
                return false;
            }
            
            valid = true;
        }
        
        return valid;
    }
    
    private func decode16(_ buffer: [UInt8], _ offset: Int) -> UInt64
    {
        var data  = Data(repeating: 0, count: 2);
        var value = UInt16();
        
        for i in 0..<data.count {
            data[i] = buffer[offset + i];
        }
        
        withUnsafeMutablePointer(to: &value) {
            data.copyBytes(to: UnsafeMutableRawPointer($0).assumingMemoryBound(to: UInt8.self), count: 2);
        }
        
        return UInt64(value.bigEndian);
    }
    
    private func decode64(_ buffer: [UInt8], _ offset: Int) -> UInt64
    {
        var data  = Data(repeating: 0, count: 8);
        var value = UInt64();

        for i in 0..<data.count {
            data[i] = buffer[offset + i];
        }
        
        withUnsafeMutablePointer(to: &value) {
            data.copyBytes(to: UnsafeMutableRawPointer($0).assumingMemoryBound(to: UInt8.self), count: 8);
        }
        
        return value.bigEndian;
    }
    
    /**
     Get payload from queue.
     
     - Parameters:
        - queue:
     */
    private func getPayload(from queue: DataQueue) -> [UInt8]?
    {
        if queue.count >= payloadSize {
            var payload = queue.read(count: payloadSize);
            
            if let maskingKey = self.maskingKey {
                for i in 0..<payload.count {
                    payload[i] = payload[i] ^ maskingKey[i % 4];
                }
            }
            
            return payload;
        }
        
        return nil;
    }
    
    /**
     Verify header.
     */
    private func verify() -> Bool
    {
        if !rsv1 && !rsv2 && !rsv3 {
            if let opcode = self.opcode {
                switch opcode {
                case .ContinuationFrame :
                    return contBuf != nil;
                    
                case .TextFrame, .BinaryFrame :
                    return contBuf == nil;
                    
                case .Close, .Ping, .Pong :
                    return fin && payloadSize < PayloadMin16Bit;
                }
            }
        }
        
        return false;
    }
    
}


// End of File
