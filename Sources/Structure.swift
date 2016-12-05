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

//TODO: add methods for "seeing" this as various quantities like a string, or an array of integers
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

//TODO: add cursor for beginning and end of record
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
	
	///the start of the record, after the abbreviation
	public var start:Cursor
	///the name of the record, if provided by an abbreviation
	public var name:String?
	public init(start:Cursor, primitives:[Primitive], name:String? = nil) {
		self.primitives = primitives
		self.start = start
		self.name = name
	}
}

//TODO: add cursor tracking for beginning and end of block
//TODO: add tracking for abbreviation width
public class Block : BlockItem {
	public var blockID:Int
	
	///the number of bits in abbreviation
	public var abbreviationWidth:Int
	public var totalLength:Int	//consider changing to Int to eliminate impedence mismatch
	
	public var info:BlockInfo?
	
	public var items:[BlockItem] = []	//stack, or map with integer keys?
	
	public init(blockID:Int, abbreviationWidth:Int, totalLength:Int) {
		self.blockID = blockID
		self.abbreviationWidth = abbreviationWidth
		self.totalLength = totalLength
	}
}


public struct Abbreviation {
	public enum Operand {
		///scan it be bigger than int?
		case literal(Int)
		///Int is width of the field
		case fixed(Int)
		case char
		case array
		///Int is width of the field
		case variable(Int)
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

