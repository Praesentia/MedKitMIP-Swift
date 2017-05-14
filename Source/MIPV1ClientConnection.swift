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
 MIP Version 1 client connection.
 */
class MIPV1ClientConnection: ClientConnection {
    
    // public
    static let factory = ClientConnectionFactoryTemplate<MIPV1ClientConnection>(priority: MIPV1Priority);
    
    override var backend  : Backend   { return mip; }
    override var dataSink : DataSink? {
        get        { return loggerA.dataSink;  }
        set(value) { loggerA.dataSink = value; loggerB.dataSink = value; }
    }
    
    // MARK: - Private
    private let authenticator: AuthenticatorV1;
    private let wsfp         : WSFP;
    private let loggerA      : PortLogger; // TODO: make dynamically insertable
    private let rpc          : RPCV1;
    private let decoder      : MIPV1ClientDecoder;
    private let encoder      : MIPV1ClientEncoder;
    private let mip          : MIPV1Client;
    
    private let loggerB      : PortLogger; // TODO: make dynamically insertable
    private let http         : HTTPClient;
    private let webc         : WebSocketClient;
    
    /**
     Initialize instance.
     
     - Parameters:
        - port:      The base port, typically TCP.
        - principal: The client principal associated with the connection.
     */
    required init(to port: MedKitCore.Port, as principal: Principal?)
    {
        // websocket
        wsfp          = WSFP(nil);
        loggerA       = PortLogger(wsfp, decoderFactory: RPCDecoder.factory);
        rpc           = RPCV1(loggerA);
        authenticator = AuthenticatorV1(rpc: rpc, myself: principal);
        encoder       = MIPV1ClientEncoder(rpc: rpc);
        mip           = MIPV1Client(encoder: encoder, authenticator: authenticator);
        decoder       = MIPV1ClientDecoder(authenticator: authenticator);
        
        rpc.messageHandler = decoder;
        decoder.client     = mip;
        
        // http
        loggerB = PortLogger(port, decoderFactory: HTTPDecoder.factory);
        http    = HTTPClient(loggerB);
        webc    = WebSocketClient(http: http);
        
        super.init(to: port, as: principal);
        
        http.delegate = self;
        rpc.delegate  = self;
    }
    
    // MARK: - ProtocolStackDelegate
    
    /**
     ProtocolStack did initialize.
     
     A delegate call used to signal that the ProtocolStack instance has
     finished initializing.
     
     In this context, there are two seperate ProtocolStack instances; an HTTP
     instance and a WebSocket instance.   The HTTP instance initializes first,
     which triggers the initiation of an upgrade request to the WebSocket
     protocol.
     
     - Parameters:
        - stack: The ProtocolStack instance generating the call.
     */
    override func protocolStackDidInitialize(_ stack: ProtocolStack, with error: Error?)
    {
        let sync = Sync(error);
        
        if error == nil && stack === http {
            
            sync.incr();
            webc.upgrade("", MIPV1WSPath, ProtocolNameMIPV1) { error in
                
                if error == nil {
                    sync.incr();
                    self.rpc.start() { error in
                        sync.decr(error);
                    }
                    self.wsfp.enable(port: self.port);
                }
                
                sync.decr(error);
            }
        }
        
        sync.close() { error in
            self.complete(error);
        }
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
        super.protocolStackDidClose(stack, reason: reason)
    }
    
}


// End of File
