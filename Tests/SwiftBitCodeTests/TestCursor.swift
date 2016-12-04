//
//  CursorTests.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/1/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import XCTest

@testable import SwiftBitCode

class CursorTests: XCTestCase {
	
	func testAdvanceCursor() {
		//
		let testCases:[(Cursor, Int, Cursor)] = [(Cursor(byte:0, bit:0), 1, Cursor(byte:0, bit:1))
			,(Cursor(byte:0, bit:0), 7, Cursor(byte:0, bit:7))
			,(Cursor(byte:0, bit:7), 1, Cursor(byte:1, bit:0))
			,(Cursor(byte:0, bit:0), 9, Cursor(byte:1, bit:1))
			 ,(Cursor(byte:0, bit:2), 12, Cursor(byte:1, bit:6))
			,(Cursor(byte:2, bit:2), 12, Cursor(byte:3, bit:6))]
		for (start, advance, end) in testCases {
			let calculated:Cursor = start.adding(bits:advance)
			XCTAssertEqual(calculated, end)
		}
	}
	
	func testRoundUp() {
		let values:[(Cursor, Int)] = [
			 (Cursor(byte: 0, bit: 0), 0)
			,(Cursor(byte: 0, bit: 1), 4)
			,(Cursor(byte: 1, bit: 1), 4)
			,(Cursor(byte: 3, bit: 7), 4)
			,(Cursor(byte: 3, bit: 0), 4)
			,(Cursor(byte: 4, bit: 0), 4)
			,(Cursor(byte: 4, bit: 1), 8)
			,(Cursor(byte: 11, bit: 3), 12)
		]
		
		for (original, finalByteCount) in values {
			let computed:Cursor = original.roundingUpTo32()
			XCTAssertEqual(computed.bit, 0)
			XCTAssertEqual(computed.byte, finalByteCount)
		}
	}
	
}
