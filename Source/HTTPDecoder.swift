/*
 -----------------------------------------------------------------------------
 This source file is part of MedKitMIP.
 
 Copyright 2017-2018 Jon Griffeth
 
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


public class HTTPDecoder: DataDecoder {
    
    public static let factory : DataDecoderFactory = HTTPDecoderFactory()
    
    public func type(data: Data) -> String?
    {
        return "HTTP"
    }
    
    public func string(data: Data) -> String?
    {
        return String(data: data, encoding: .utf8)
    }
    
}

class HTTPDecoderFactory: DataDecoderFactory {
    
    func instantiateDecoder() -> DataDecoder
    {
        return HTTPDecoder()
    }
}


// End of File
