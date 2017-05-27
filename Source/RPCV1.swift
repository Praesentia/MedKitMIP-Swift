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
 Remote Procedure Call
 */
class RPCV1: ProtocolStackBase {

    weak var messageHandler: RPCV1MessageHandler?;
    
    // internal
    enum MessageType: Int {
        case Sync  = 1;
        case Reply = 2;
        case Async = 3;
    };
    
    typealias MessageID         = Int;
    typealias CompletionHandler = (JSON?, Error?) -> Void; //: Completion handler signature for synchronous messages.

    // MARK: - Private
    private var completionHandlers = [MessageID : CompletionHandler]();
    private var nextID             : MessageID { return generateMessageID(); }
    private let schema             = RPCV1Schema();
    private var sequence           : MessageID = 0;
    
    /**
     Send synchronous message.
     
     - Parameters:
        - message: The message to be sent.
        - completion: A completion handler used to handle the reply.
     */
    func sync(message: JSON, completionHandler completion: @escaping (JSON?, Error?) -> Void)
    {
        let sync = JSON();
        let id   = nextID;
        
        sync[KeyType]    = MessageType.Sync.rawValue;
        sync[KeyId]      = id;
        sync[KeyMessage] = message;
        
        completionHandlers[id] = completion;
        
        sendMessage(sync);
    }
    
    /**
     Send asynchronous message.
     
     - Parameters:
        - message: The message to be sent.
     */
    func async(message: JSON)
    {
        let async = JSON();
        
        async[KeyType]    = MessageType.Async.rawValue;
        async[KeyMessage] = message;
        
        sendMessage(async);
    }
    
    /**
     Pop completion handler.
     
     - Parameters:
        - id: A message identifier.
     
     - Returns:
        Returns the completion handler assigned to the message ID, or nil if
        no such completion handler exists.
     */
    private func pop(_ id: MessageID) -> CompletionHandler?
    {
        var completionHandler: CompletionHandler?;
        
        if let completion = completionHandlers[id] {
            completionHandlers.removeValue(forKey: id);
            completionHandler = completion;
        }
        
        return completionHandler;
    }
    
    /**
     Generate message ID.
     
     - Returns:
        Returns the generated message ID.
     */
    private func generateMessageID() -> MessageID
    {
        let id = sequence;
        
        sequence += 1;
        return id;
    }
    
    /**
     Send message.
     
     This method is used to encode a single JSON message as UTF-8 text which is
     then sent to the downstream port.
     
     - Parameters:
        - message: The JSON message to be sent.
     */
    private func sendMessage(_ message: JSON)
    {
        if let text = JSONWriter.write(json: message) {
            port.send(text.data(using: .utf8)!);
        }
        else {
            // TODO
        }
    }
    
    /**
     Send reply.
     
     - Parameters:
        - message:
     */
    private func sendReply(id: Int, reply: JSON?, error: MedKitError?)
    {
        let message = JSON();
        
        message[KeyType] = MessageType.Reply.rawValue;
        message[KeyId]   = id;
        
        if error != nil {
            message[KeyError] = error!.rawValue;
        }
        if reply != nil {
            message[KeyReply] = reply!;
        }
        
        sendMessage(message);
        
    }
    
    /**
     Decode message.
     
     This method is used to decode and verify a data block containing UTF-8
     encoded text for a single RPC message.
     
     - Parameters:
        - data: Bytes for a single message.
     
     - Returns:
        Returns a JSON structure representing the RPC message, or nil if the
        data is invalid and could not be decoded or verified.
     */
    private func decode(data: Data) -> JSON?
    {
        do {
            let message = try JSONParser.parse(data: data);
            
            if schema.verify(message: message) {
                return message;
            }
            
            Logger.main.log(message: "Invalid RPC schema");
        }
        catch {
            Logger.main.log(message: "Invalid JSON.");
        }
        
        return nil;
    }

    /**
     Received message.
     
     - precondition:
        schema.verify(message: message)
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    private func received(message: JSON)
    {
        if let type = MessageType(rawValue: message[KeyType].int!) {
            switch type {
            case .Sync:
                receivedSync(message);
                
            case .Reply:
                receivedReply(message);
                
            case .Async:
                receivedAsync(message);
            }
        }
    }
    
    /**
     Received synchronous message.
     
     - precondition:
        schema.verifySync(message: message)
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    private func receivedSync(_ message: JSON)
    {
        let id: MessageID = message[KeyId];
        
        messageHandler?.rpc(self, didReceive: message[KeyMessage]) { reply, error in
            self.sendReply(id: id, reply: reply, error: error as? MedKitError); // TODO: error
        }
    }
    
    /**
     Received reply.
     
     - precondition:
        schema.verifyReply(message: message)
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    private func receivedReply(_ message: JSON)
    {
        let id: MessageID = message[KeyId];
        
        if let completion = pop(id) {
            var error: Error?;
            var reply: JSON?;
            
            if message.contains(key: KeyError) {
                error = MedKitError(rawValue: message[KeyError].int!);
            }
            if message.contains(key: KeyReply) {
                reply = message[KeyReply];
            }
            
            completion(reply, error);
        }
        else {
            // TODO:
        }
    }
    
    /**
     Received asynchronous message.
     
     - precondition:
        schema.verifyAsync(message: message)
     
     - Parameters:
        - message: A JSON message received from downstream.
     */
    private func receivedAsync(_ message: JSON)
    {
        messageHandler?.rpc(self, didReceive: message[KeyMessage]);
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
        if let message = decode(data: data) {
            received(message: message);
        }
    }
    
}


// End of File
