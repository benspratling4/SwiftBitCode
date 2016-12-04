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
	case prematureEndOfFile	//which always happens at the end
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
		let _ = stream.variableInt(width: 4)
		//round up
		stream.roundUpCursorTo32Bits()
		//read the number of words in this block
		let subBlockLength:Int = stream.fixedInt(width: 32)
		var c = stream.cursor
		c.byte += subBlockLength * 4
		c.bit = 0
		stream.seek(to: c)
		//make the cursor skip it
		return Block(blockID: code, totalLength: subBlockLength)
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
		var block:Block = Block(blockID: code, totalLength: subBlockLength)
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
				//not right
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
		return DataRecord(primitives:primitives)
	}
	
	public func newAbbreviation(stream:BitStream)->Abbreviation {
		return AbbreviationFactory().newAbbreviation(stream:stream)
	}
	
}



/// The first assumed Block Factory, which knows only how to open subblacks and unabbreviated records
public class PrimaryBlockFactory : BlockFactory, BlockFactoryFactory {
	public init() {
	}
	
	///don't use
	public required init(code: Int, info:BlockInfo?) {
		fatalError()
	}
	
	var blockInfoByCode:[Int:BlockInfo] = [:]
	
	public func newBlock(stream:BitStream)->Block {
		var mainBlock = Block(blockID:0, totalLength: stream.data.count - stream.cursor.byte)
		//somehow, loop this
		//read an abbreviation
		while true {
			if stream.cursor.byte >= stream.data.count {
				return mainBlock
			}
			var abbreviation:Int = stream.fixedInt(width: 2)
			if abbreviation == 0 {	//end
				return mainBlock
			} else if abbreviation == 1 {	//new sub block
				//new block
				//read block type
				let blockIDs:Int = stream.variableInt(width: 8)
				let factory = self.factory(code: blockIDs)
				let subBlock:Block = factory.newBlock(stream:stream)
				mainBlock.items.append(subBlock)
				if let infoBlock = factory as? BlockInfoFactory {
					blockInfoByCode = infoBlock.infosByCode
				}
			} else if abbreviation == 3 {//unabbreviated entry
				let record:DataRecord = UnabbreviatedRecordFactory().newRecord(stream:stream)
				mainBlock.items.append(record)
			} else {
				//TODO: write me
				fatalError()
			}
		}
		
	}
	
	public func factory(code:Int)->BlockFactory {
		let factoryType:BlockFactory.Type = catalog[code] ?? GenericBlockFactory.self //SkipBlockFactory.self
		var factory:BlockFactory = factoryType.init(code: code, info:blockInfoByCode[code])
		factory.factoryFactory = self
		return factory
	}
	
	//populate with factories which know how to build
	private var catalog:[Int:BlockFactory.Type] = [0:BlockInfoFactory.self]
	
	//is this even used?
	public weak var factoryFactory:BlockFactoryFactory?
}


class UnabbreviatedRecordFactory {
	func newRecord(stream:BitStream)->DataRecord {
		var primitives:[Primitive] = []
		let code:Int = stream.variableInt(width: 6)
		primitives.append(.integer(code))
		let numberOfOperands:Int = stream.variableInt(width: 6)
		for _ in 0..<numberOfOperands {
			let operand:Int = stream.variableInt(width: 6)
			primitives.append(.integer(operand))
		}
		return DataRecord(primitives:primitives)
	}
}


class AbbreviationFactory {
	
	func newAbbreviation(stream:BitStream)->Abbreviation {
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
