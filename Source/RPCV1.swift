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


/**
 Remote Procedure Call
 */
class RPCV1: ProtocolStackBase {

    /**
     Message delegate.
     */
    weak var messageDelegate: RPCV1MessageDelegate?

    /**
     Completion handler type.

     The type of the completion handler used to receive replies to synchronous
     messages.

     Completion handlers may throw exceptions to indicate an error when
     decoding a reply.
     */
    typealias CompletionHandler = RPCV1Sequencer.CompletionHandler

    // MARK: - Private
    private let decoder   = JSONDecoder()
    private let encoder   = JSONEncoder()
    private let sequencer = RPCV1Sequencer()

    // MARK: - Send

    /**
     Send synchronous message.

     - Parameters:
        - content: The content of the message to be sent.
     */
    func sync(content: Encodable, completionHandler completion: @escaping (AnyCodable?, Error?) throws -> Void)
    {
        do {
            let id      = sequencer.push(completionHandler: completion)
            let content = RPCV1Sync(id: id, content: try AnyCodable(content))
            let message = RPCV1MessageCodable(message: content)
            let data    = try encoder.encode(message)

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }
    
    /**
     Send synchronous message.
     
     - Parameters:
        - content:    The content of the message to be sent.
        - completion: A completion handler used to receive the reply.
     */
    func sync(content: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) throws -> Void)
    {
        do {
            let id      = sequencer.push(completionHandler: completion)
            let content = RPCV1Sync(id: id, content: content)
            let message = RPCV1MessageCodable(message: content)
            let data    = try encoder.encode(message)

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }

    /**
     Send reply.

     - Parameters:
        - id:      The identifier assigned to the sychronous message.
        - content: The content of the reply.
        - error:   The reply error.
     */
    private func reply(id: RPCV1Reply.IDType, content: AnyCodable?, error: MedKitError?)
    {
        do {
            let content = RPCV1Reply(id: id, content: content, error: error)
            let message = RPCV1MessageCodable(message: content)
            let data    = try encoder.encode(message)

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }

    /**
     Send asynchronous message.

     - Parameters:
        - content: The content of the message to be sent.
     */
    func async(content: Encodable)
    {
        do {
            let content = RPCV1Async(content: try AnyCodable(content))
            let message = RPCV1MessageCodable(message: content)
            let data    = try encoder.encode(message)

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }
    
    /**
     Send asynchronous message.
     
     - Parameters:
        - content: The content of the message to be sent.
     */
    func async(content: AnyCodable)
    {
        do {
            let content = RPCV1Async(content: content)
            let message = RPCV1MessageCodable(message: content)
            let data    = try encoder.encode(message)

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }

    // MARK: - Receive
    
    /**
     Received synchronous message.
     
     - Parameters:
        - message: A message received from downstream.
     */
    func received(message: RPCV1Sync) throws
    {
        try messageDelegate?.rpc(self, didReceive: message.content) { reply, error in
            self.reply(id: message.id, content: reply, error: error as? MedKitError) // TODO: error
        }
    }
    
    /**
     Received reply.
     
     - Parameters:
        - message: A message received from downstream.
     */
    func received(message: RPCV1Reply) throws
    {
        try sequencer.complete(id: message.id, reply: message.content, error: message.error)
    }
    
    /**
     Received asynchronous message.
     
     - Parameters:
        - message: A message received from downstream.
     */
    func received(message: RPCV1Async) throws
    {
        try messageDelegate?.rpc(self, didReceive: message.content)
    }
    
    // MARK: - PortDelegate

    override func portDidClose(_ port: MedKitCore.Port, for reason: Error?)
    {
        super.portDidClose(port, for: reason)
        sequencer.shutdown(for: reason)
    }
    
    /**
     Port did receive data.
     
     This method is called whenever the downstream port has received data that
     constitutes a single complete message.
     
     - Parameters:
        - port: Port that received the message.
        - data: Bytes for a single message.
     */
    override func port(_ port: MedKitCore.Port, didReceive data: Data)
    {
        do {
            let message = try decoder.decode(RPCV1MessageCodable.self, from: data)
            try message.send(to: self)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }
    
}


// End of File
