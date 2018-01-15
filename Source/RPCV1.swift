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

    weak var messageHandler: RPCV1MessageHandler?

    typealias CompletionHandler = (AnyCodable?, Error?) throws -> Void //: Completion handler signature for synchronous messages.

    // MARK: - Private
    private let decoder            = JSONDecoder()
    private let encoder            = JSONEncoder()
    private var completionHandlers = [Int : CompletionHandler]()
    private var nextID             : Int { return generateMessageID() }
    private var sequence           : Int = 0

    // MARK: - Send
    
    /**
     Send synchronous message.
     
     - Parameters:
        - content:    The content of the message to be sent.
        - completion: A completion handler used to handle the reply.
     */
    func sync(content: AnyCodable, completionHandler completion: @escaping (AnyCodable?, Error?) throws -> Void)
    {
        let id = nextID

        do {
            let content = RPCV1Sync(id: id, content: content)
            let message = RPCV1MessageEncodable(content: content)
            let data    = try encoder.encode(message)

            completionHandlers[id] = completion
            port.send(data)
        }
        catch let error {
            completionHandlers[id] = nil
            try? completion(nil, error)
            port.shutdown(for: error)
        }
    }

    func async(content: Encodable)
    {
        do {
            async(content: try AnyCodable(content))
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
            let message = RPCV1MessageEncodable(content: content)
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
        - message:
     */
    private func sendReply(id: Int, error: MedKitError?, content: AnyCodable?)
    {
        do {
            let content = RPCV1Reply(id: id, error: error, content: content)
            let data    = try encoder.encode(RPCV1MessageEncodable(content: content))

            port.send(data)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }
    
    /**
     Pop completion handler.
     
     - Parameters:
        - id: A message identifier.
     
     - Returns:
        Returns the completion handler assigned to the message ID, or nil if
        no such completion handler exists.
     */
    private func pop(_ id: Int) throws -> CompletionHandler
    {
        if let completion = completionHandlers[id] {
            completionHandlers.removeValue(forKey: id)
            return completion
        }
        
        throw MedKitError.failed
    }
    
    /**
     Generate message ID.
     
     - Returns:
        Returns the generated message ID.
     */
    private func generateMessageID() -> Int
    {
        let id = sequence
        sequence += 1
        return id
    }

    // MARK: - Receive
    
    /**
     Received synchronous message.
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    func received(message: RPCV1Sync) throws
    {
        try messageHandler?.rpc(self, didReceive: message.content) { reply, error in
            self.sendReply(id: message.id, error: error as? MedKitError, content: reply) // TODO: error
        }
    }
    
    /**
     Received reply.
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    func received(message: RPCV1Reply) throws
    {
        let completion = try pop(message.id)
        try completion(message.content, message.error)
    }
    
    /**
     Received asynchronous message.
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    func received(message: RPCV1Async) throws
    {
        try messageHandler?.rpc(self, didReceive: message.content)
    }
    
    // MARK: - PortDelegate interface
    
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
            let message = try decoder.decode(RPCV1MessageDecodable.self, from: data)
            try message.send(to: self)
        }
        catch let error {
            port.shutdown(for: error)
        }
    }
    
}


// End of File
