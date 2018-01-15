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
import SecurityKit


/**
 MIP Server Connection
 */
class MIPV1ServerConnection: ServerConnectionBase {
    
    // MARK: - Class Properties
    static let factory = ServerConnectionFactoryTemplate<MIPV1ServerConnection>(protocolType: "mip-v1")
    
    // MARK: - Properties
    override var dataTap: DataTap? {
        get        { return wsfpTap.dataTap  }
        set(value) { wsfpTap.dataTap = value; httpTap.dataTap = value }
    }
    
    // MARK: - Common Stack
    private let tls       : PortSecure
    private let tlsPolicy : MIPV1ServerPolicy

    // MARK: - WebSocket Stack
    private let wsfp         : WSFP
    private let wsfpTap      : PortTap
    private let rpc          : RPCV1
    private let authenticator: AuthenticatorV1
    private let decoder      : MIPV1ServerDecoder
    private let encoder      : MIPV1ServerEncoder
    private let mip          : MIPV1Server

    // MARK: - HTTP Stack
    private let httpTap : PortTap
    private let http    : HTTPServer
    private let webc    : WebSocketServer
    
    // MARK: - Initializers
    
    /**
     Initialize protocol stack.
     */
    required init(from port: MedKitCore.Port, to device: DeviceFrontend, using principalManager: PrincipalManager)
    {
        // tls
        tlsPolicy            = MIPV1ServerPolicy(principalManager: principalManager)
        tls                  = PortSecure(port: port, mode: .server)
        tls.context.delegate = tlsPolicy
        
        // websocket
        wsfp          = WSFP(nil)
        wsfpTap       = PortTap(wsfp, decoderFactory: RPCDecoder.factory)
        rpc           = RPCV1(wsfpTap)
        authenticator = AuthenticatorV1(rpc: rpc, using: principalManager)
        encoder       = MIPV1ServerEncoder(rpc: rpc)
        mip           = MIPV1Server(device: device, encoder: encoder)
        decoder       = MIPV1ServerDecoder(authenticator: authenticator)
        
        rpc.messageHandler = decoder
        decoder.server     = mip

        // http
        httpTap = PortTap(tls, decoderFactory: HTTPDecoder.factory)
        http    = HTTPServer(httpTap)
        webc    = WebSocketServer(http: http, port: tls, wsfp: wsfp)
        
        super.init(from: port, to: device, using: principalManager)
        
        http.delegate = self
        rpc.delegate  = self
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
        authenticator.didClose()
        mip.close()
        
        super.protocolStackDidClose(stack, for: reason)
    }
    
}


// End of File
