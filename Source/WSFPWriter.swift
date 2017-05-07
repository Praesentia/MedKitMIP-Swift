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
class WSFPWriter: WSFPReaderWriter {
    
    private var mode: Mode;
    
    init(mode: Mode)
    {
        self.mode = mode;
        super.init();
    }
    
    func makeFrame(opcode: WSFPReaderWriter.OpCode, payload: Data) -> Data
    {
        var frame            : [UInt8];
        var headerSize       = MinSize;
        var maskingKeyOffset : Int = MinSize;
        var payloadMode      : UInt8;
        let payloadSize      = UInt64(payload.count);
        
        // calculate header size
        payloadMode = PayloadMode7Bit;
        if payloadSize >= PayloadMin16Bit {
            if payloadSize >= PayloadMin64Bit {
                payloadMode       = PayloadMode64Bit;
                headerSize       += 8;
                maskingKeyOffset += 8;
            }
            else
            {
                payloadMode       = PayloadMode16Bit;
                headerSize       += 2;
                maskingKeyOffset += 2;
            }
        }
            
        if mode == .Client
        {
            headerSize += MaskingKeySize;
        }
        
        frame = [UInt8](repeating: 0, count: headerSize + payload.count);
        
        // encode control bits
        frame[0]  = FIN | opcode.rawValue;
        frame[1]  = (mode == .Client) ? MASKING_KEY : UInt8(0);
        frame[1] |= payloadMode;
            
        // encode payload size
        switch payloadMode {
        case PayloadMode16Bit :
            encode16(&frame, PayloadSizeOffset, UInt16(payload.count));
            
        case PayloadMode64Bit :
            encode64(&frame, PayloadSizeOffset, UInt64(payload.count));
            
        default : // 7 bit length
            frame[1] |= UInt8(payload.count);
        }

        // encode masking key
        switch mode {
        case .Client :
            let maskingKey = SecurityManagerShared.main.randomBytes(count: MaskingKeySize);

            // copy key
            for i in 0..<maskingKey.count {
                frame[maskingKeyOffset + i] = maskingKey[i];
            }
            
            // mask payload
            for i in 0..<payload.count {
                frame[headerSize + i] = payload[i] ^ maskingKey[i % MaskingKeySize];
            }

        case .Server :
            for i in 0..<payload.count {
                frame[headerSize + i] = payload[i];
            }
        }
    
        return Data(frame);
    }
    
    private func encode16(_ buffer: inout [UInt8], _ offset: Int, _ value: UInt16)
    {
        var data = Data()
        var be   = value.bigEndian;
        
        withUnsafePointer(to: &be) {
            data.append(UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self), count: 2);
        }
        
        for i in 0..<data.count {
            buffer[offset + i] = data[i];
        }
    }
    
    private func encode64(_ buffer: inout [UInt8], _ offset: Int, _ value: UInt64)
    {
        var data = Data()
        var be   = value.bigEndian;
        
        withUnsafePointer(to: &be) {
            data.append(UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self), count: 8);
        }
        
        for i in 0..<data.count {
            buffer[offset + i] = data[i];
        }
    }

}


// End of File
