//
//  BBAEInstanceCheckboxRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 18/11/21.
//

import Cocoa
import UMOmniaFramework



class BBAEInstanceCheckboxRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceCheckboxRow"
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: UMTextField!
	@IBOutlet weak var chkCheckbox: UMCheckButton!
	
	// MARK: - var
	//	var project :				BBAEProject!
	//	var template :				BBAETemplateComp!
	//	var templateCompItem :		BBAETemplateCompItem!
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	// MARK: - Display
	func displayData () {
		lblFieldName.setValue ((templateItem?.fieldName ?? "UNDEFINED") + ":")
		chkCheckbox.setup (initialValue: recordFieldValue.valueContent == 1) { [self] newValue in
			recordFieldValue.valueContent = newValue ? 1 : 0
			rowModifiedCallback? ()
		}
	}
	
	// MARK: - Observer
	func setupObserver () {
		UMNotify.observe (keyword: "media.ulti.bbae.\(recordFieldValue.compFieldId)") { [weak self] in
			self?.displayData ()
		}
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  		NSTableView,
						 //						 project :				BBAEProject,
						 //						 template :				BBAETemplateComp,
						 recordFieldValue :		BBAERecordFieldValue,
						 rowModifiedCallback :	@escaping () -> ()) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.recordFieldValue = recordFieldValue
		cell.rowModifiedCallback = rowModifiedCallback
		cell.displayData ()
		cell.setBackground ()
		cell.setupObserver ()
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
