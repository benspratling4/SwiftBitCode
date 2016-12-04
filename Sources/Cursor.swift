//
//  Cursor.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/2/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

public struct Cursor : Comparable, CustomDebugStringConvertible {
	public var byte:Int
	public var bit:UInt8	//only value 0-7 are valid
	
	public init(byte:Int = 0, bit:UInt8 = 0) {
		self.byte = byte
		self.bit = bit
	}
	
	///create a new cursor which is advanced by the given number of bits, and normalized
	public func adding(bits count:Int)->Cursor {
		let newTotalBits:Int = Int(bit) + count
		return Cursor(byte: byte + (newTotalBits / 8), bit: UInt8(newTotalBits % 8))
	}
	
	///round the cursor up to the next multiple of 4 bytes, or 32 bits
	public func roundingUpTo32()->Cursor {
		var newByte:Int = byte
		if bit > 0 { newByte += 1}
		let remainder:Int = newByte % 4
		if remainder != 0{
			newByte += 4 - remainder
		}
		return Cursor(byte:newByte, bit:0)
	}
	
	/// Equatable
	
	public static func ==(lhs:Cursor, rhs:Cursor)->Bool {
		return lhs.byte == rhs.byte && lhs.bit == rhs.bit
	}
	
	/// Comparable
	
	public static func <(lhs: Cursor, rhs: Cursor) -> Bool {
		if lhs.byte == rhs.byte { return lhs.bit < rhs.bit }
		return lhs.byte < rhs.byte
	}
	
	///CustomDebugStringConvertible
	public var debugDescription: String {
		return "\(byte):\(bit)"
	}
	
}
