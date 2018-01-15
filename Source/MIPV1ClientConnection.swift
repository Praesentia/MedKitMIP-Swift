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
 MIP Version 1 client connection.
 */
class MIPV1ClientConnection: ClientConnectionBase {
    
    // MARK: - Class Properties
    static let factory = ClientConnectionFactoryTemplate<MIPV1ClientConnection>(priority: MIPV1Priority)
    
    // MARK: - Properties
    override var dataTap : DataTap? {
        get        { return wsfpTap.dataTap  }
        set(value) { wsfpTap.dataTap = value; httpTap.dataTap = value }
    }
    
    // MARK: - Common Stack
    private let tls       : PortSecure
    private let tlsPolicy : MIPV1ClientPolicy

    // MARK: - WebSocket Stack
    private let authenticator: AuthenticatorV1
    private let wsfp         : WSFP
    private let wsfpTap      : PortTap
    private let rpc          : RPCV1
    private let decoder      : MIPV1ClientDecoder
    private let encoder      : MIPV1ClientEncoder
    private let mip          : MIPV1Client

    // MARK: - HTTP Stack
    private let httpTap : PortTap
    private let http    : HTTPClient
    private let webc    : WebSocketClient
    
    // MARK: - Initializers
    
    /**
     Initialize instance.
     
     - Parameters:
        - port:      The base port, typically TCP.
        - principal: The client principal associated with the connection.
     */
    required init(to port: MedKitCore.Port, for device: DeviceBackend, using principalManager: PrincipalManager)
    {
        // tls
        tlsPolicy            = MIPV1ClientPolicy(for: Identity(named: device.identifier.uuidstring, type: .device))
        tls                  = PortSecure(port: port, mode: .client)
        tls.context.delegate = tlsPolicy
        
        // websocket
        wsfp          = WSFP(nil)
        wsfpTap       = PortTap(wsfp, decoderFactory: RPCDecoder.factory)
        rpc           = RPCV1(wsfpTap)
        authenticator = AuthenticatorV1(rpc: rpc, using: principalManager)
        encoder       = MIPV1ClientEncoder(rpc: rpc)
        mip           = MIPV1Client(encoder: encoder, authenticator: authenticator)
        decoder       = MIPV1ClientDecoder(authenticator: authenticator)
        
        rpc.messageHandler = decoder
        decoder.client     = mip
        
        // http
        httpTap = PortTap(tls, decoderFactory: HTTPDecoder.factory)
        http    = HTTPClient(httpTap)
        webc    = WebSocketClient(http: http)
        
        super.init(to: port, for: device, using: principalManager)
        
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
        _backend = nil // retract the backend
        authenticator.didClose()
        
        super.protocolStackDidClose(stack, for: reason)
    }
    
    /**
     ProtocolStack did initialize.
     
     A delegate call used to signal that the ProtocolStack instance has
     finished initializing.
     
     In this context, there are two seperate ProtocolStack instances an HTTP
     instance and a WebSocket instance.   The HTTP instance initializes first,
     which triggers the initiation of an upgrade request to the WebSocket
     protocol.
     
     - Parameters:
        - stack: The ProtocolStack instance generating the call.
     */
    override func protocolStackDidInitialize(_ stack: ProtocolStack, with error: Error?)
    {
        let sync = Sync(error)
        
        if error == nil && stack === http {
            
            sync.incr()
            webc.upgrade("", MIPV1WSPath, ProtocolNameMIPV1) { error in
                
                if error == nil {
                    sync.incr()
                    self.rpc.start() { error in
                        sync.decr(error)
                    }
                    self.wsfp.enable(port: self.tls)
                }
                
                sync.decr(error)
            }
        }
        
        sync.close() { error in
            if error == nil {
                self._backend = self.mip // publish the backend
            }
            self.complete(error)
        }
    }
    
}


// End of File
