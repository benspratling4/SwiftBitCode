//
//  BitReading.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/5/16.
//
//

import XCTest
@testable import SwiftBitCode

class BitReading: XCTestCase {

	func testReadOneBit() {
		let bits:[Bool] = [true, false]
		let byte:UInt8 = UInt8(Int(bits: bits))
		XCTAssertEqual(byte, 1)
		let stream = BitStream(data: Data([byte]), cursor: Cursor(byte: 0, bit: 0))
		let bit:Int = stream.fixedInt(width: 1)
		XCTAssertEqual(bit, 1)
		XCTAssertEqual(stream.cursor, Cursor(byte: 0, bit: 1))
	}
	
	func testReadTwoBits() {
		let bits:[Bool] = [false, true]
		let byte:UInt8 = UInt8(Int(bits: bits))
		XCTAssertEqual(byte, 2)
		let stream = BitStream(data: Data([byte]), cursor: Cursor(byte: 0, bit: 0))
		let bit:Int = stream.fixedInt(width: 2)
		XCTAssertEqual(bit, 2)
		XCTAssertEqual(stream.cursor, Cursor(byte: 0, bit: 2))
	}
	
	func testReadThreeBits() {
		let bits:[Bool] = [false, false, true, true, true, true]
		let byte:UInt8 = UInt8(Int(bits: bits))
		XCTAssertEqual(byte, 60)
		let stream = BitStream(data: Data([byte]), cursor: Cursor(byte: 0, bit: 0))
		let bit:Int = stream.fixedInt(width: 3)
		XCTAssertEqual(bit, 4)
		XCTAssertEqual(stream.cursor, Cursor(byte: 0, bit: 3))
	}
	
	
	func testReadTwoVariableBits() {
		let bits:[Bool] = [false, true, true, false]
		let byte:UInt8 = UInt8(Int(bits: bits))
		XCTAssertEqual(byte, 6)
		let stream = BitStream(data: Data([byte]), cursor: Cursor(byte: 0, bit: 0))
		let bit:Int = stream.variableInt(width: 2)
		XCTAssertEqual(bit, 2)
		XCTAssertEqual(stream.cursor, Cursor(byte: 0, bit: 4))
	}
	
	func testReadThreeVariableBits() {
		let bits:[Bool] = [false, true, false, false, true, false]
		let byte:UInt8 = UInt8(Int(bits: bits))
		XCTAssertEqual(byte, 18)
		let stream = BitStream(data: Data([byte]), cursor: Cursor(byte: 0, bit: 0))
		let bit:Int = stream.variableInt(width: 3)
		XCTAssertEqual(bit, 2)
		XCTAssertEqual(stream.cursor, Cursor(byte: 0, bit: 3))
	}
	
	

}
