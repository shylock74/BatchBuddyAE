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
	
	// MARK: - UI
	@IBOutlet weak var fldName: UMTextField!
	@IBOutlet weak var colColor: NSColorWell!
	
	// MARK: - var
	var bbaeProject :	BBAEProject!
	var bbaeColor :		BBAEProjectColor!
	var delegate :		BBAEProjectColorListCellDelegate!
	
	// MARK: - Display
	func displayData () {
		fldName.setup (defaultValue: bbaeColor.name) { value in
			self.bbaeColor.name = value
			self.bbaeProject.saveColorFile (customAEProjectUrl: nil)
			self.bbaeProject.save ()
		}
		let c = bbaeColor.color.getColor ()
		colColor.color = c
	}
	
	// MARK: - Actions
	@IBAction func colColorChanged (_ sender: Any) {
		bbaeColor.color = UMColor (colColor.color)
		bbaeProject.saveColorFile (customAEProjectUrl: nil)
		bbaeProject.save ()
	}
	
	@IBAction func btnCopyHex (_ sender: Any) {
		UMPasteboard.setString (bbaeColor.hex)
	}
	
	@IBAction func btnCopyAEcodePressed(_ sender: Any) {
		bbaeProject.saveColorFile (customAEProjectUrl: nil)
		let code = BBAESettings.shared.getColorAECodeString (color: bbaeColor)
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "Color \(bbaeColor.name) Successfully Copied.")
	}
	
	@IBAction func btnCopyColorFillPressed(_ sender: Any) {
		bbaeProject.saveColorFile (customAEProjectUrl: nil)
		let code = BBAESettings.shared.getColorFillString (color: bbaeColor)
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "Color \(bbaeColor.name) Successfully Copied.")
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeColor (bbaeColor: bbaeColor)
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 bbaeProject :	BBAEProject,
						 bbaeColor : 	BBAEProjectColor,
						 delegate :		BBAEProjectColorListCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.bbaeColor = bbaeColor
		cell.bbaeProject = bbaeProject
		cell.delegate = delegate
		cell.displayData ()
		
		//cancella se non la vuoi
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
}
