//
//  BBAEProjectTemplateListCell-v2.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 23/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAEProjectTemplateListCellV2 :	UMTableCell {
	
	static let cellId =	"BBAEProjectTemplateListCellV2"
	
	// MARK: - UI
	@IBOutlet weak var lblTemplateName: NSTextField!
	
	// MARK: - var
	var template :	BBAEComp!
	var delegate :	BBAEProjectTemplateListCellDelegate!
	
	// MARK: - Display
	func displayData () {
		lblTemplateName.setValue (template.name)
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 template :		BBAEComp,
						 delegate :		BBAEProjectTemplateListCellDelegate,
						 selected :		Bool) -> Self? {
		guard let cell = tableView.getCell (id: "BBAEProjectTemplateListCellV2") as? Self else { return nil }
		cell.template = template
		cell.delegate = delegate
		cell.displayData ()
		cell.setBackground ()
		cell.hilite = selected
		return cell
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplate (bbaeTemplate: template)
	}
	
	@IBAction func btnDuplicatePressed (_ sender: Any) {
		delegate.duplicateTemplate (bbaeTemplate: template)
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
