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
class MIPV1ServerConnection: ServerConnectionBase {
    
    // MARK: - Class Properties
    static let factory = ServerConnectionFactoryTemplate<MIPV1ServerConnection>(protocolType: "mip-v1");
    
    // MARK: - Properties
    override var dataTap: DataTap? {
        get        { return wsfpTap.dataTap;  }
        set(value) { wsfpTap.dataTap = value; httpTap.dataTap = value }
    }
    
    // MARK: - Private Properties
    private var wsfp         : WSFP;
    private var wsfpTap      : PortTap;
    private var rpc          : RPCV1;
    private let authenticator: AuthenticatorV1;
    private var decoder      : MIPV1ServerDecoder;
    private var encoder      : MIPV1ServerEncoder;
    private var mip          : MIPV1Server;
    
    private var httpTap : PortTap;
    private var http    : HTTPServer;
    private var webc    : WebSocketServer;
    
    // MARK: - Initializers
    
    /**
     Initialize protocol stack.
     */
    required init(from port: MedKitCore.Port, to device: DeviceFrontend, as principal: Principal)
    {
        // websocket
        wsfp          = WSFP(nil);
        wsfpTap       = PortTap(wsfp, decoderFactory: RPCDecoder.factory);
        rpc           = RPCV1(wsfpTap);
        authenticator = AuthenticatorV1(rpc: rpc, myself: principal);
        encoder       = MIPV1ServerEncoder(rpc: rpc);
        mip           = MIPV1Server(device: device, encoder: encoder);
        decoder       = MIPV1ServerDecoder(authenticator: authenticator);
        
        rpc.messageHandler = decoder;
        decoder.server     = mip;

        // http
        httpTap = PortTap(port, decoderFactory: HTTPDecoder.factory);
        http    = HTTPServer(httpTap);
        webc    = WebSocketServer(http: http, port: port, wsfp: wsfp);
        
        super.init(from: port, to: device, as: principal);
        
        http.delegate = self;
        rpc.delegate  = self;
    }
    
    // MARK: - ProtocolStackDelegate
    
    /**
     ProtocolStack did close.
     
     - Parameters:
        - stack:  The ProtocolStack instance generating the call.
        - reason: The reason the stack closed.
     */
    override func protocolStackDidClose(_ stack: ProtocolStack, for reason: Error?)
    {
        authenticator.didClose();
        mip.close();
        
        super.protocolStackDidClose(stack, for: reason);
    }
    
}


// End of File
