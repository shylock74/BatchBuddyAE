//
//  BBAEOutputModuleCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 12/09/21.
//

import Cocoa
import UMOmniaFramework

class BBAEOutputModuleCell :	UMTableCell {
	
	// MARK: - UI
	@IBOutlet weak var fldName: UMTextField!
	@IBOutlet weak var fldExt: UMTextField!
	
	// MARK: - var
	var type :				BBAERenderOutputListVC.Show!
	var aeTemplate :		BBAESettings.AETemplate!
	var removeCallback :	((String) -> ())!
	
	// MARK: - Display
	func displayData () {
		fldName.setup (defaultValue: aeTemplate.title) { [weak self] newValue in
			self?.aeTemplate.title = newValue
			BBAESettings.shared.save ()
		}
		if type == .ouput {
			fldExt.setup (defaultValue: aeTemplate.fileExtension ?? "") { [weak self] newValue in
				self?.aeTemplate.fileExtension = newValue
				BBAESettings.shared.save ()
			}
		} else {
			fldExt.isHidden = true
		}
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  	NSTableView,
						 type :				BBAERenderOutputListVC.Show,
						 aeTemplate :		BBAESettings.AETemplate,
						 removeCallback :	@escaping (String) -> ()) -> Self? {
		guard let cell = tableView.getCell (id: "BBAEOutputModuleCell") as? Self else { return nil }
		cell.type = type
		cell.aeTemplate = aeTemplate
		BBAESettings.shared.save ()
		cell.removeCallback = removeCallback
		cell.displayData ()
		return cell
	}
	
	// MARK: - Actions
	@IBAction func btnRemovePressed (_ sender: Any) {
		removeCallback (aeTemplate.id)
	}
}
