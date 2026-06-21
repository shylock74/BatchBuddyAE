//
//  BBAEInstanceRecordIdRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 12/01/22.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceRecordIdRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceRecordIdRow"
	
	// MARK: - UI
	@IBOutlet weak var fldText: UMTextField!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	var record :				BBAERecord!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	// MARK: - Display
	func displayData () {
		fldText.setup (defaultValue: recordFieldValue.textContent ?? "") { [self] newValue in
			if newValue != recordFieldValue.textContent {
				recordFieldValue.textContent = newValue
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
						 record :				BBAERecord,
						 rowModifiedCallback :	@escaping () -> ()) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.recordFieldValue = recordFieldValue
		cell.record = record
		cell.rowModifiedCallback = rowModifiedCallback
		cell.displayData ()
		cell.setBackground ()
		cell.setupObserver ()
		return cell
	}
	
	// MARK: - Actions
		@IBAction func btnFillRecordIdPressed (_ sender: Any) {
			recordFieldValue.textContent = record.suggestedRecordID ()
			rowModifiedCallback? ()
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
