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
 MIP Server Connection
 */
class MIPV1ServerConnection: ServerConnection {
    
    static let factory = ServerConnectionFactoryTemplate<MIPV1ServerConnection>(protocolType: "mip-v1");
    
    override var dataSink: DataSink? {
        get        { return loggerA.dataSink;  }
        set(value) { loggerA.dataSink = value; loggerB.dataSink = value }
    }
    
    // MIP stack
    private var wsfp         : WSFP;
    private var loggerA      : PortLogger;
    private var rpc          : RPCV1;
    private let authenticator: AuthenticatorV1;
    private var decoder      : MIPV1ServerDecoder;
    private var encoder      : MIPV1ServerEncoder;
    private var mip          : MIPV1Server;
    
    // HTTP stack
    private var loggerB      : PortLogger;
    private var http         : HTTPServer;
    private var webc         : WebSocketServer;
    
    /**
     Initialize protocol stack.
     */
    required init(from port: MedKitCore.Port, to device: DeviceFrontend, as principal: Principal)
    {
        // websocket
        wsfp          = WSFP(nil);
        loggerA       = PortLogger(wsfp, decoderFactory: RPCDecoder.factory);
        rpc           = RPCV1(loggerA);
        authenticator = AuthenticatorV1(rpc: rpc, myself: principal);
        encoder       = MIPV1ServerEncoder(rpc: rpc);
        mip           = MIPV1Server(device: device, encoder: encoder);
        decoder       = MIPV1ServerDecoder(authenticator: authenticator);
        
        rpc.messageHandler = decoder;
        decoder.server     = mip;

        // http
        loggerB = PortLogger(port, decoderFactory: HTTPDecoder.factory);
        http    = HTTPServer(loggerB);
        webc    = WebSocketServer(http: http, port: port, wsfp: wsfp);
        
        super.init(from: port, to: device, as: principal);
        
        http.delegate = self;
        rpc.delegate  = self;
    }
    
    /**
     ProtocolStack did close.
     
     - Parameters:
        - stack:  The ProtocolStack instance generating the call.
        - reason: The reason the stack closed.
     */
    override func protocolStackDidClose(_ stack: ProtocolStack, reason: Error?)
    {
        authenticator.didClose();
        mip.close();
        
        super.protocolStackDidClose(stack, reason: reason);
    }
    
}


// End of File
