//
//  Factory.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/2/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

//TODO: flesh this out and use it
public enum BitCodeError : Error {
	///location in file, the abbreviation value
	case unknownAbbreviation(Cursor, Int)
	
	/// Bits can only have values from 0-7
	case bitValueOutOfRange
	
	//which always happens at the end
	case prematureEndOfFile
}

/// Concrete instances build particular kinds of blocks
public protocol BlockFactory {
	weak var factoryFactory:BlockFactoryFactory? { get set }
	
	///the cursor is after the code, but before the abbreviation length
	func newBlock(stream:BitStream)->Block
	
	init(code:Int, info:BlockInfo?)
}

/// Creates block factories for a given block code
public protocol BlockFactoryFactory : class {
	func factory(code:Int)->BlockFactory
}

/// Skips over a block that begins at a cursor
public class SkipBlockFactory : BlockFactory {
	var code:Int
	public required init(code:Int, info:BlockInfo?) {
		self.code = code
	}
	
	public weak var factoryFactory:BlockFactoryFactory?
	
	public func newBlock(stream:BitStream)->Block {
		//although we discard this value, it's variable length, so we have to read it to skip it
		let abbreviationWidth:Int = stream.variableInt(width: 4)
		//round up
		stream.roundUpCursorTo32Bits()
		//read the number of words in this block
		let subBlockLength:Int = stream.fixedInt(width: 32)
		let start:Cursor = stream.cursor
		var c = stream.cursor
		c.byte += subBlockLength * 4
		c.bit = 0
		stream.seek(to: c)
		//make the cursor skip it
		return Block(blockID: code, abbreviationWidth:abbreviationWidth, totalLength: subBlockLength, start:start)
	}
}


public class BlockInfoFactory : GenericBlockFactory {
	
	//keys are block codes,
	var infosByCode:[Int:BlockInfo] = [:]
	
	public required init(code:Int, info:BlockInfo?) {
		super.init(code: code, info:info)
	}
	
	///retrieves or creates it
	private func blockInfo(for code:Int)->BlockInfo {
		if let existingInfo = infosByCode[code] {
			return existingInfo
		}
		let newInfo = BlockInfo(code: code)
		infosByCode[code] = newInfo
		return newInfo
	}
	
	///instead of hanging onto an index, put new names, record names and abbreviations in here
	var currentBlockInfo:BlockInfo?
	
	
	public override func newUnabbreviatedRecord(stream:BitStream, abbreviation:Int)->DataRecord {
		let record = super.newUnabbreviatedRecord(stream:stream, abbreviation: abbreviation)
		//figure out what to do
		if record.code == 1 {	//TODO: add enum for code values
			let code:Int = record.operands.first?.integerValue ?? 0
			currentBlockInfo = blockInfo(for:code)
		} else if record.code == 2 {	//blockname
			//bytes form a string
			let bytes:[UInt8] = record.operands.map({ (int) -> UInt8 in
				return UInt8(int.integerValue!)
			})
			let data = Data(bytes)
			currentBlockInfo?.name = String(data:data, encoding:.utf8)
		} else if record.code == 3 {	//set record name
			//code for the record ID
			let recordNumber:Int = record.operands.first!.integerValue!
			//variable ints making bytes for string name
			let ops = record.operands.dropFirst()
			let bytes:[UInt8] = ops.map({ (int) -> UInt8 in
				return UInt8(int.integerValue!)
			})
			let data = Data(bytes)
			if let name = String(data:data, encoding:.utf8) {
				currentBlockInfo?.recordNames[recordNumber] = name
			}
		}
		return record
	}
	
	public override func newAbbreviation(stream:BitStream)->Abbreviation {
		let newAbbreviation = super.newAbbreviation(stream:stream)
		currentBlockInfo?.abbreviations.append(newAbbreviation)
		return newAbbreviation
	}
	
}


public class GenericBlockFactory : BlockFactory {
	
	var code:Int
	var info:BlockInfo?
	public required init(code:Int, info:BlockInfo?) {
		self.code = code
		self.info = info
		self.knownAbbreviations = info?.rootAbbreviations() ?? [:]
	}
	public weak var factoryFactory:BlockFactoryFactory?
	
	var knownAbbreviations:[Int:Abbreviation]
	
	var nextAbbreviationIndex:Int {
		return 4 + knownAbbreviations.count
	}
	
	public func newBlock(stream:BitStream)->Block {
		//read the abbreviation length
		let abbrevitationLength:Int = stream.variableInt(width: 4)
		//round up
		stream.roundUpCursorTo32Bits()
		let subBlockLength:Int = stream.fixedInt(width: 32)
		let start:Cursor = stream.cursor
		let block:Block = Block(blockID: code, abbreviationWidth:abbrevitationLength, totalLength: subBlockLength, start:start)
		block.info = info
		while true {
			//read an abbreviation
			let abbreviation:Int = stream.fixedInt(width: abbrevitationLength)
			switch abbreviation {
			case 0:	//end block
				stream.roundUpCursorTo32Bits()
				return block
			case 1:	//enter sub block
				let blockID:Int = stream.variableInt(width: 8)
				let factory = factoryFactory!.factory(code: blockID)
				let subBlock:Block = factory.newBlock(stream:stream)
				block.items.append(subBlock)
			case 2:	//define abbreviation
				let abbrev:Abbreviation = newAbbreviation(stream:stream)
				knownAbbreviations[nextAbbreviationIndex] = abbrev
			case 3:	//unabbreviated record
				let record:DataRecord = newUnabbreviatedRecord(stream:stream, abbreviation: abbreviation)
				block.items.append(record)
			default:
				//record abbreviation
				let abbreviationFormat = knownAbbreviations[abbreviation]!
				let record:DataRecord = newRecord(stream:stream, abbreviation: abbreviationFormat)
				block.items.append(record)
			}
		}
		fatalError()
	}
	
	public func newUnabbreviatedRecord(stream:BitStream, abbreviation:Int)->DataRecord {
		return UnabbreviatedRecordFactory().newRecord(stream:stream)
	}
	
	public func newRecord(stream:BitStream, abbreviation:Abbreviation)->DataRecord {
		//reads a value described by the operand from the stream
		let primitiveCreator:(Abbreviation.Operand)->(Primitive?) = { (op)->(Primitive?) in
			switch op {
			case .char:
				let charValue:Int = stream.fixedInt(width: 6)
				let scalar = Primitive.scalar(forChar:charValue)
				return .char(scalar)
			case .literal(let int):
				return .integer(int)
			case .fixed(let width):
				let value:Int = stream.fixedInt(width: width)
				return .integer(value)
			case .variable(let width):
				let value:Int = stream.variableInt(width: width)
				return .integer(value)
			case .blob:
				//read the length
				let byteCount:Int = stream.variableInt(width: 6)
				stream.roundUpCursorTo32Bits()
				//read the bytes
				var bytes:[UInt8] = []
				for _ in 0..<byteCount {
					let byteInt:UInt8 = stream.byte()
					bytes.append(byteInt)
				}
				stream.roundUpCursorTo32Bits()
				return .blob(bytes)
			default:
				return nil
			}
		}
		let start:Cursor = stream.cursor
		var primitives:[Primitive] = []
		for op in abbreviation.operands {
			if let prim:Primitive = primitiveCreator(op) {
				primitives.append(prim)
				continue
			}
			//only arrays don't parse
			//parse the number of prims
			let arrayCount:Int = stream.variableInt(width: 6)
			//get last op
			let lastOp = abbreviation.operands.last!
			var arrayPrims:[Primitive] = []
			for _ in 0..<arrayCount {
				let prim = primitiveCreator(lastOp)!
				arrayPrims.append(prim)
			}
			primitives.append(.array(arrayPrims))
			break	//we cheated on the last element, skip it
		}
		let code:Int? = primitives.first?.integerValue
		let name:String? = code != nil ? info?.recordNames[code!] : nil
		return DataRecord(start:start, primitives:primitives, name:name)
	}
	
	public func newAbbreviation(stream:BitStream)->Abbreviation {
		return AbbreviationFactory().newAbbreviation(stream:stream)
	}
	
}



/// The first assumed Block Factory, which knows only how to open subblacks and unabbreviated records
open class TopLevelBlockFactory : BlockFactoryFactory {
	open let stream:BitStream
	public init(stream:BitStream) {
		self.stream = stream
	}
	
	private var blockInfoByCode:[Int:BlockInfo] = [:]
	
	open func topLevelBlocks()->[Block] {
		var blocks:[BlockItem] = []
		//somehow, loop this
		//read an abbreviation
		while true {
			//top level ends when we run out of bytes
			if stream.cursor.byte >= stream.data.count {
				return blocks.flatMap({ (item) -> Block? in
					return item as? Block
				})
			}
			let abbreviation:Int = stream.fixedInt(width: 2)
			if abbreviation == 0 {	//end
				//theoretically this shouldn't happen at the top level, but just in case...
				return blocks.flatMap({ (item) -> Block? in
					return item as? Block
				})
			} else if abbreviation == 1 {	//new sub block
				//new block
				//read block type
				let blockIDs:Int = stream.variableInt(width: 8)
				//get the right factory
				let factory = self.factory(code: blockIDs)
				//make the block
				let subBlock:Block = factory.newBlock(stream:stream)
				blocks.append(subBlock)
				if let infoBlock = factory as? BlockInfoFactory {
					blockInfoByCode = infoBlock.infosByCode
				}
			} else if abbreviation == 3 {//unabbreviated entry
				let record:DataRecord = UnabbreviatedRecordFactory().newRecord(stream:stream)
				blocks.append(record)
			} else {
				//only other case is 2
				//new abbreviations can't be defined at the top level, because we only have 2 abbreviation bits and they're all in use.
			}
		}
		
	}
	
	open func factory(code:Int)->BlockFactory {
		let factoryType:BlockFactory.Type = catalog[code] ?? GenericBlockFactory.self //SkipBlockFactory.self
		var factory:BlockFactory = factoryType.init(code: code, info:blockInfoByCode[code]?.copy)
		factory.factoryFactory = self
		return factory
	}
	
	//populate with factories which know how to build
	open var catalog:[Int:BlockFactory.Type] = [0:BlockInfoFactory.self]
	
}


public struct UnabbreviatedRecordFactory {
	public func newRecord(stream:BitStream)->DataRecord {
		var primitives:[Primitive] = []
		let start:Cursor = stream.cursor
		let code:Int = stream.variableInt(width: 6)
		primitives.append(.integer(code))
		let numberOfOperands:Int = stream.variableInt(width: 6)
		for _ in 0..<numberOfOperands {
			let operand:Int = stream.variableInt(width: 6)
			primitives.append(.integer(operand))
		}
		return DataRecord(start:start, primitives:primitives, name:nil)
	}
}


public class AbbreviationFactory {
	
	public func newAbbreviation(stream:BitStream)->Abbreviation {
		let numberOfOperands:Int = stream.variableInt(width: 5)
		var operands:[Abbreviation.Operand] = []
		for _ in 0..<numberOfOperands {
			let isLiteralBits:[Bool] = stream.bits(width: 1)
			if isLiteralBits.first! {
				//literal
				let value:Int = stream.variableInt(width: 8)
				operands.append(.literal(value))
				continue
			}
			let encoding:Int = stream.fixedInt(width: 3)
			switch encoding {
			case 1:	//fixed width
				let width:Int = stream.variableInt(width: 5)
				operands.append(.fixed(width))
			case 2:	//variable bit
				let width:Int = stream.variableInt(width: 5)
				operands.append(.variable(width))
			case 3:	//array
				operands.append(.array)
			case 4:	//char
				operands.append(.char)
			case 5://blob
				operands.append(.blob)
			default:
				fatalError()
			}
		}
		return Abbreviation(operands:operands)
	}
	
}
