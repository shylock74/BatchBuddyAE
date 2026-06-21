//
//  BBAETemplateStructureRecordIdCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 06/12/21.
//

import Cocoa
import UMOmniaFramework


// MARK: - BBAETemplateStructureTextCell
class BBAETemplateStructureRecordIdCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureRecordIdCell"
	
	// MARK: - UI
	
	// MARK: - var
	var compField :	BBAECompField!
	var comp :		BBAEComp!
	var project :	BBAEProject!
	var delegate :	BBAETemplateStructureCellDelegate!
	var selected =	false {
		didSet {
			hilite = selected
		}
	}
	
	// MARK: - Notifications
	func notifyUpdates () {
		delegate.updateTemplate ()
		comp.notifyUpdate ()
		project.notifyUpdate ()
		UMNotify.notify (keyword: "media.ulti.bbae.\(compField.id)")
	}
	
	func displayData () {
		//		switch compField.type {
		//
		//			case .text:
		//				lblFieldType.setValue ("Text")
		//			case .longText:
		//				lblFieldType.setValue ("Long Text")
		//			case .colorFill:
		//				lblFieldType.setValue ("Color Fill")
		//			case .numericValue:
		//				lblFieldType.setValue ("Number")
		//			default: break
		//		}
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 compField :	BBAECompField,
						 comp :			BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.compField = compField
		cell.project = project
		cell.delegate = delegate
		cell.comp = comp
		cell.displayData ()
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
	
	// MARK: - Actions
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplateItem (compField.id)
	}
	
}
