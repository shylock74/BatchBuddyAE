//
//  BBAEProjectTemplateListCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAEProjectTemplateListCellDelegate {
	func removeTemplate (bbaeTemplate :	BBAEComp)
	func updateTemplate (bbaeTemplate :	BBAEComp)
	func duplicateTemplate (bbaeTemplate :	BBAEComp)
}

class BBAEProjectTemplateListCell :	UMTableCell {
	var bbaeTemplate :	BBAEComp!
	var bbaeProject :	BBAEProject!
	var delegate :		BBAEProjectTemplateListCellDelegate!
}
