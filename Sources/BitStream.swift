//
//  BitStream.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/3/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

public class BitStream {
	public var cursor:Cursor
	public var data:Data
	public init(data:Data, cursor:Cursor) {
		self.data = data
		self.cursor = cursor
	}
	
	public func seek(to: Cursor) {
		cursor = to
	}
	
	public func roundUpCursorTo32Bits() {
		cursor = cursor.roundingUpTo32()
	}
	
	///all of these functions advance the cursor
	
	public func bits(width:Int)->[Bool] {
		let bits:[Bool]
		(bits, cursor) = data.bits(at: cursor, count: width)
		return bits
	}
	
	public func fixedInt(width:Int)->Int {
		let bits:[Bool]
		(bits, cursor) = data.bits(at: cursor, count: width)
		return Int(bits:bits)
	}
	
	public func char()->UInt8 {
		//6 bits in a bit-code char
		return UInt8(fixedInt(width:6))
	}
	
	public func byte()->UInt8 {
		//6 bits in a bit-code char
		return UInt8(fixedInt(width:8))
	}
	
	public func variableInt(width:Int)->Int {
		var allBits:[Bool] = []
		repeat {
			let bits = self.bits(width:width)
			let lastBit = bits.last!
			allBits.append(contentsOf: bits.dropLast())
			if lastBit == false { break }
		} while true
		return Int(bits:allBits)
	}
	
}
