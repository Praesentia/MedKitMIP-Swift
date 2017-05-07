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
 WebSocket Framing Protocol
 */
class WSFP: MedKitCore.Port, MedKitCore.PortDelegate {
    
    weak var delegate : MedKitCore.PortDelegate?; //: Delegate
    
    private let Heartbeat : TimeInterval = 10;
    private var port      : MedKitCore.Port?;
    private let queue     = DataQueue();
    private let reader    = WSFPReader();
    private let writer    = WSFPWriter(mode: .Client);
    private var heartbeat : Timer?;
    private var pingCount : Int = 0;
    private var pongCount : Int = 0;
    
    /**
     Initialize instance.
     */
    init(_ port: MedKitCore.Port?)
    {
        self.port      = port;
        port?.delegate = self;
    }
    
    /**
     Enable port.
     */
    func enable(port: MedKitCore.Port)
    {
        self.port = port;
        port.delegate = self;
        
        startHeartbeat();
        
        delegate?.portDidInitialize(self, with: nil);
    }
    
    func send(_ data: Data)
    {
        port?.send(writer.makeFrame(opcode: .BinaryFrame, payload: data));
    }
    
    func shutdown(reason: Error?)
    {
        port?.shutdown(reason: reason);
    }
    
    func start()
    {
    }
    
    func close()
    {
        sendClose();
        port?.shutdown(reason: nil);
    }
    
    private func sendClose()
    {
        port?.send(writer.makeFrame(opcode: .Close, payload: Data()));
    }
    
    private func sendPing(payload: Data)
    {
        port?.send(writer.makeFrame(opcode: .Ping, payload: payload));
    }
    
    private func sendPong(payload: Data)
    {
        port?.send(writer.makeFrame(opcode: .Pong, payload: payload));
    }
    
    private func recvPong()
    {
        pongCount += 1;
    }
    
    private func terminate()
    {
        heartbeat?.invalidate();
        port?.shutdown(reason: nil);
    }
    
    private func startHeartbeat()
    {
        heartbeat = Timer.scheduledTimer(withTimeInterval: Heartbeat, repeats: true) { timer in
            self.heartbeatTimeout();
        }
    }
    
    private func heartbeatTimeout()
    {
        if pingCount > pongCount {
            terminate();
        }
        else {
            pingCount += 1;
            sendPing(payload: Data());
        }
    }
    
    // MARK: - PortDelegate
    
    func portDidInitialize(_ port: MedKitCore.Port, with error: Error?)
    {
        if error == nil {
            startHeartbeat();
        }
        else {
            // TODO
        }
    }
    
    func portDidClose(_ port: MedKitCore.Port, reason: Error?)
    {
        delegate?.portDidClose(self, reason: reason);
    }
    
    func port(_ port: MedKitCore.Port, didReceive data: Data)
    {
        queue.append(data);
        
        while reader.getMessage(from: queue) {
            switch reader.code! {
            case .ContinuationFrame, .TextFrame, .BinaryFrame :
                delegate?.port(self, didReceive: Data(reader.payload));
                
            case .Close :
                close();
                
            case .Ping :
                sendPong(payload: reader.payload);
                break;
                
            case .Pong :
                recvPong();
                break;
            }
            
            reader.reset();
        }
        
    }
    
}


// End of File
