//
//  KnownRecords.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/3/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

public struct RecordLayout {
	public var blockName:String
	public var recordName:String
	public var fields:[Descriptor] = []
	
	public init(blockName:String, recordName:String, fields:[Descriptor]) {
		self.blockName = blockName
		self.recordName = recordName
		self.fields = fields
	}
	
	public struct Descriptor {
		public var label:String
		
		public enum ViewAs {
			case bool
			case integer
			case string
			case literal	//whatever it is, like an array of ints, or an int
			case lookup([String])	//the integer value is an index into this array
		}
		
		public var view:ViewAs = .literal
		public init(label:String, view:ViewAs = .literal) {
			self.label = label
			self.view = view
		}
		
	}
	
	public func describe(record:DataRecord)->String {
		let args:[Primitive] = [Primitive](record.primitives.dropFirst())
		var propLines:[String] = []
		for (index, descript) in fields.enumerated() {
			var propLine:String = "\(descript.label):"
			defer {
				propLines.append(propLine)
			}
			if record.primitives.count <= index {
				propLine += "_"
				continue
			}
			let arg:Primitive = args[index]
			switch (descript.view, arg) {
				case (.bool,.integer(let value)):
					propLine += value == 0 ? "false" : "true"
				case (.bool, _):
					propLine += "bad combo"
				case (.string, .blob(let bytes)):
					propLine += String(data:Data(bytes), encoding:.utf8) ?? "couldn't read string"
				case (.integer, let any):
					let value:String
					if let intValue = any.integerValue {
						value = "\(intValue)"
					} else {
						value = "couldn't be int"
					}
					propLine += value
				case (.lookup(let constants), let any):
					guard let index = any.integerValue, constants.count > index
						else {
							propLine += "bad lookup index"
							continue
						}
					propLine += constants[index]
				default:
					propLine += args[index].description
			}
		}
		return propLines.joined(separator: ",")
	}
	
	
}
