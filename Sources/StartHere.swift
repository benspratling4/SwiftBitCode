//
//  StartHere.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/3/16.
//
//

import Foundation

///Designed to read any bit-code file, described here
///http://llvm.org/docs/BitCodeFormat.html
open class BitCode {
	
	///this should be data after the magic number, not including it
	public init(data:Data) {
		self.data = data
	}
	
	open let data:Data
	
	///override-this to start at a different point in the data
	///not to rename the beginning of the data
	open var startingCursor:Cursor {
		return Cursor(byte:0, bit:0)
	}
	
	/// returns top-level blocks
	open func topLevelBlocks()->[Block] {
		let factory:TopLevelBlockFactory = TopLevelBlockFactory(stream: BitStream(data: data, cursor:startingCursor))
		return factory.topLevelBlocks()
	}
	
}


open class MagicCookieVerifyingBitCode : BitCode {
	open var magicCookie:[UInt8]
	public init(data:Data, magicCookie:[UInt8]) {
		self.magicCookie = magicCookie
		super.init(data:data)
	}
	
	open override var startingCursor:Cursor {
		return Cursor(byte:magicCookie.count, bit:0)
	}
	
	//TODO: verify the magic cookie before proceeding
	//public override func findTopLevelBlocks()->[Block] {
	
}
