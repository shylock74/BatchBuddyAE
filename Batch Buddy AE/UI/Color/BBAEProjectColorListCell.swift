//
//  BBAEProjectColorListCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 21/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAEProjectColorListCellDelegate {
	func removeColor (bbaeColor :	BBAEProjectColor)
}

class BBAEProjectColorListCell :	UMTableCell {
	static let cellId = "BBAEProjectColorListCell"
}
