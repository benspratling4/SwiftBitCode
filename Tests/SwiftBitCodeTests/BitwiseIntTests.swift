//
//  BitwiseIntTests.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/2/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import XCTest

@testable import SwiftBitCode

class BitwiseIntTests: XCTestCase {

	func testBitExtraction() {
		//byte values, bit positions, and final values
		let values:[(UInt8, UInt8, Bool)] = [
			 (0x00, 0, false)
			,(0b11111110, 0, false)
			,(0b11111101, 1, false)
			,(0b11111011, 2, false)
			,(0b11110111, 3, false)
			,(0b11101111, 4, false)
			,(0b11011111, 5, false)
			,(0b10111111, 6, false)
			,(0b01111111, 7, false)
			,(0b11111101, 0, true)
			,(0b11111101, 2, true)
			,(0b11111101, 3, true)
			,(0b11111101, 4, true)
			,(0b11111101, 5, true)
			,(0b11111101, 6, true)
			,(0b11111101, 7, true)
		]
		
		for (byte, at, result) in values {
			let retrieved:Bool = byte.bit(at: at)
			XCTAssertEqual(retrieved, result)
		}
	}
	
	func testIntegerFormation() {
		let values:[([Bool], Int)] = [
			 ([], 0)
			,([false], 0)
			,([true], 1)
			,([true,false], 1)	//remember, lsb first
			,([false,true], 2)
			,([false, false,true], 0b100)
			,([true, false,true], 0b101)
		]
		
		for (bits, integer) in values {
			let calculated = Int(bits:bits)
			XCTAssertEqual(calculated, integer)
		}
	}
	
	
}
