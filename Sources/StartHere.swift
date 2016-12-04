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
public class BitCode {
	
	///this should be data after the magic number, not including it
	public init(data:Data) {
		self.data = data
	}
	
	let data:Data
	
	///override-this to start at a different point in the data
	public var startingCursor:Cursor {
		return Cursor(byte:0, bit:0)
	}
	
	/// returns top-level blocks
	public func findTopLevelBlocks()->[Block] {
		let factory:BlockFactory = PrimaryBlockFactory()
		let topBlock:Block = factory.newBlock(stream: BitStream(data: data, cursor:startingCursor))
		return topBlock.items.flatMap { (item) -> Block? in
			return item as? Block
		}
	}
	
}
