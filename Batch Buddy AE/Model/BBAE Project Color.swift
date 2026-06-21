//
//  BBAEProjectColor.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework


class BBAEProjectColor :	Codable {
	var id =	UMId.newId (useCounter: false)
	var name :	String =	"Color"
	var color : UMColor =	UMColor (255, 255, 255)

	init (name :	String,
		  color :	UMColor) {
		self.name = name
		self.color = color
	}
	
	var aeVariableName :	String {
		"bbaeColor_\(id)"
	}
	
	static func aeColorArray (_ color :	UMColor) -> String {
		"[\(color.red), \(color.green), \(color.blue), \(color.alpha!)]"
	}
	
	var aeVariableAssignation :	String {
		"\(aeVariableName) = \(BBAEProjectColor.aeColorArray (color));"
	}
	
	var hex :	String {
		color.hex.uppercased ()
	}
	
//	func aeVariableAssignation (colorId :	String) -> String {
//		"\(aeVariableName) = \(BBAEProjectColor.aeColorArray (color));"
//	}
}
