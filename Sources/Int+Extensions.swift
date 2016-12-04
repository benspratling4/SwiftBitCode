//
//  Int+Extensions.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/2/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

extension UInt8 {
	
	static let masks:[UInt8] = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]
	
	/// pull a Bool representing a bit in a byte.
	/// true == 1, false == 0
	/// `at`: 0 == least significant bit, MSb = 7
	public func bit(at:UInt8)->Bool {
		let masked:UInt8 = self & UInt8.masks[Int(at)]
		return masked != 0
	}
	
}


extension Int {
	///up to an Int's worth of bits, LSB-first
	public init(bits:[Bool]) {
		var value:Int = 0
		for bit in bits.reversed() {
			value = value << 1
			value += bit ? 1 : 0
		}
		self = value
	}
}
