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
 RPCV1 Sequencer
 */
class RPCV1Sequencer {

    /**
     Completion handler type.

     The type of the completion handler used to receive replies to synchronous
     messages.

     Completion handlers may throw exceptions to indicate an error when
     decoding a reply.
     */
    typealias CompletionHandler = (AnyCodable?, Error?) throws -> Void //: Completion handler signature for synchronous messages.
    typealias IDType            = UInt32

    // MARK: - Private
    private var completionHandlers = [IDType : CompletionHandler]()
    private var sequence           = SecurityManagerShared.main.random(IDType.self)

    // MARK: - Initializers

    init()
    {
    }

    // MARK: -

    /**
     */
    func complete(id: IDType, reply: AnyCodable?, error: Error?) throws
    {
        let completion = try pop(id)
        try completion(reply, error)
    }

    /**
     */
    func push(completionHandler completion: @escaping CompletionHandler) -> IDType
    {
        let id = generateID()

        completionHandlers[id] = completion
        return id
    }

    /**
     */
    func shutdown(for reason: Error?)
    {
        for (_, completion) in completionHandlers {
            try? completion(nil, reason)
        }

        completionHandlers.removeAll()
    }

    // MARK: - Private

    /**
     Generate message ID.

     - Returns:
     Returns the generated message ID.
     */
    private func generateID() -> IDType
    {
        let id = sequence
        sequence += 1
        return id
    }

    /**
     Pop completion handler.

     - Parameters:
        - id: A message identifier.

     - Returns:
        Returns the completion handler assigned to the message ID, or nil if
        no such completion handler exists.
     */
    private func pop(_ id: IDType) throws -> CompletionHandler
    {
        if let completion = completionHandlers[id] {
            completionHandlers.removeValue(forKey: id)
            return completion
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unexpected message idenitfier."))
    }

}


// End of File
