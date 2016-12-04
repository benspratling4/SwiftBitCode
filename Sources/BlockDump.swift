//
//  BlockDump.swift
//  SwiftBitCode
//
//  Created by Ben Spratling on 12/3/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation

extension Block {
	
	
	public func dump()->String {
		return dump(indentation: 0).joined(separator: "\n")
	}
	
	fileprivate func dump(indentation:Int)->[String] {
		if let info:BlockInfo = self.info {
			return withInfoDump(info: info, indentation:indentation)
		} else {
			return noInfoDump(indentation: indentation)
		}
	}
	
	fileprivate func noInfoDump(indentation:Int)->[String] {
		let indentationString:String = repeatElement("\t", count: indentation).joined()
		var allLines:[String] = []
		let line:String = "\(indentationString)code: \(self.blockID)"
		allLines.append(line)
		for item in items {
			if let subBlock = item as? Block {
				allLines.append(contentsOf: subBlock.dump(indentation: indentation + 1))
			} else if let record = item as? DataRecord {
				let args:[String] = record.operands.map({ (int) -> String in
					return "\(int.description)"
				})
				let codeString:String = "\(record.code ?? -1)"
				allLines.append("\(indentationString)\t\(codeString):\(args.joined(separator: ","))")
			}
		}
		return allLines
	}
	
	fileprivate func withInfoDump(info:BlockInfo, indentation:Int)->[String] {
		let indentationString:String = repeatElement("\t", count: indentation).joined()
		var allLines:[String] = []
		let name = info.name ?? "code: \(self.blockID)"
		allLines.append("\(indentationString)\(name)")
		for item in items {
			if let subBlock = item as? Block {
				allLines.append(contentsOf: subBlock.dump(indentation: indentation + 1))
			} else if let record = item as? DataRecord {
				if let recordCode = record.primitives.first?.integerValue {
					//name
					var line:String = "\(indentationString)\t"
					if let name:String = info.recordNames[recordCode] {
						line.append(name)
					} else {
						line.append("\(recordCode)")
					}
					line.append(":")
					let restOfLine:String = record.primitives.dropFirst().map({ (prim) -> String in
						return prim.description
					}).joined(separator: ",")
					line.append("(\(restOfLine))")
					//values
					
					allLines.append(line)
				} else {
					let args:[String] = record.operands.map({ (int) -> String in
						return "\(int.description)"
					})
					allLines.append("\(indentationString)\t\(record.code):\(args.joined(separator: ","))")
				}
			}
		}
		return allLines
	}
	
	
}

