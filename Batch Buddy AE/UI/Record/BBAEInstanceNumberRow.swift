//
//  BBAEInstanceNumberRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 24/05/2021.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceNumberRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceNumberRow"
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: UMTextField!
	@IBOutlet weak var fldText: UMTextField!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	// MARK: - Display
	func displayData () {
		lblFieldName.setValue ((templateItem?.fieldName ?? "UNDEFINED") + ":")
		
		if recordFieldValue.type () == .text {
			fldText.setup (defaultValue: recordFieldValue.textContent ?? "") { [self] newValue in
				recordFieldValue.textContent = newValue
				rowModifiedCallback? ()
			}
		} else {
			fldText.setup (defaultValue: recordFieldValue.valueContentString ?? "") { [self] newValue in
				recordFieldValue.valueContent = Double (newValue)
				rowModifiedCallback? ()
			}
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
	
	// MARK: - Actions
	//	@IBAction func btnRemovePressed(_ sender: Any) {
	//		delegate.remove (id)
	//	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
}
