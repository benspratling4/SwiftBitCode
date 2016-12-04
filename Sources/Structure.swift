//
//  Structure.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/2/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//


import Foundation

public protocol BlockItem {
	
}


public enum Primitive {
	case char(UnicodeScalar)
	case integer(Int)
	case array([Primitive])
	case blob([UInt8])
	
	private static let allChars:[UnicodeScalar] = [UnicodeScalar]("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._".unicodeScalars)
	public static func scalar(forChar index:Int)->UnicodeScalar {
		return allChars[index]
	}
	
	public var integerValue:Int? {
		guard case let .integer(int) = self
			else { return nil }
		return int
	}
	
	public var description:String {
		get {
			switch self {
			case .integer(let int):
				return "\(int)"
			case .char(let scalar):
				return String(String.UnicodeScalarView([scalar]))
			case .array(let primitives):
				var chars:[UnicodeScalar] = []
				var ints:[Int] = []
				for prim in primitives {
					if case let .char(code) = prim {
						chars.append(code)
					} else if case let .integer(value) = prim {
						ints.append(value)
					}
				}
				if chars.count > 0 {
					return String(String.UnicodeScalarView(chars))
				} else if ints.count > 0 {
					let inner = ints.map({ (int) -> String in
						return "\(int)"
					}).joined(separator:",")
					return "[\(inner)]"
				} else {
					return "[]"
				}
			case .blob(let bytes):
				return "\(Data(bytes))"
			}
		}
	}
}


public struct DataRecord : BlockItem {
	///all the primitives stored in the record
	public var primitives:[Primitive] = []
	
	/// the first primitive, if it can be interpretted as a record
	public var code:Int? {
		get {
			return primitives.first?.integerValue
		}
	}
	///primitives after the first one, i.e. "operands"
	public var operands:[Primitive] {
		get {
			if primitives.count == 0 {
				return []
			}
			return [Primitive](primitives.dropFirst())
		}
	}
	
	public init(primitives:[Primitive]) {
		self.primitives = primitives
	}
}


public class Block : BlockItem {
	public var blockID:Int
	public var totalLength:Int	//consider changing to Int to eliminate impedence mismatch
	
	public var info:BlockInfo?
	
	public var items:[BlockItem] = []	//stack, or map with integer keys?
	
	public init(blockID:Int, totalLength:Int) {
		self.blockID = blockID
		self.totalLength = totalLength
	}
}


public struct Abbreviation {
	public enum Operand {
		case literal(Int)	//scan it be bigger than int?
		case fixed(Int)	//width of field
		case char
		case array
		case variable(Int)	//width of field
		case blob
	}
	public var operands:[Operand]
	
	public init(operands:[Operand]) {
		self.operands = operands
	}
}


public class BlockInfo {
	public var name:String?
	public var code:Int
	public var abbreviations:[Abbreviation] = []
	public var recordNames:[Int:String] = [:]
	
	public init(code:Int) {
		self.code = code
	}
	
	public func rootAbbreviations()->[Int:Abbreviation] {
		var finalAbbrevs:[Int:Abbreviation] = [:]
		for (index, abbreviation) in abbreviations.enumerated() {
			finalAbbrevs[4 + index] = abbreviation
		}
		return finalAbbrevs
	}
}

