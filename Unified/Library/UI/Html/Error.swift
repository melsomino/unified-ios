// Error.swift
// Copyright (c) 2015 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
*  XMLError enumeration.
*/
enum XMLError: ErrorType {
  /// No error
  case NoError
  /// Contains a libxml2 error with error code and message
  case LibXMLError(code: Int, message: String)
  /// Failed to convert String to bytes using given string encoding
  case InvalidData
  /// XML Parser failed to parse the document
  case ParserFailure
  
  internal static func lastError(defaultError: XMLError = .NoError) -> XMLError {
    let errorPtr = xmlGetLastError()
    guard errorPtr != nil else {
      return defaultError
    }
    let message = String.fromCString(errorPtr.memory.message)?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    let code = Int(errorPtr.memory.code)
    xmlResetError(errorPtr)
    return .LibXMLError(code: code, message: message ?? "")
  }
}