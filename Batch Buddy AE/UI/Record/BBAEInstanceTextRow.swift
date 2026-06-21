//
//  BBAEInstanceTextRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceTextRow :	UMTableCell {
	
	deinit {
		timer.stop ()
	}
	
	static let cellId = "BBAEInstanceTextRow"
	
	// MARK: - UI
	@IBOutlet weak var imgFieldType: NSImageView!
	@IBOutlet weak var lblFieldName: UMTextField!
	@IBOutlet weak var fldText: UMTextField!
	@IBOutlet weak var chkLarge: UMCheckButton!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	var timer = UMTimer ()
	
	// MARK: - Display
	func displayData () {
		switch templateItem?.type {
			case .recordId: imgFieldType.image = Draw.getImage ("Btn__Id_00000")
			case .text: imgFieldType.image = Draw.getImage ("Btn__Type-Text_00000")
			default: break
		}
		
		if templateItem?.type == .recordId {
			lblFieldName.setValue ("Record Id:")
		} else {
			lblFieldName.setValue ((templateItem?.fieldName ?? "UNDEFINED") + ":")
		}
		
		if recordFieldValue.type () == .text || recordFieldValue.type () == .recordId {
			fldText.setup (defaultValue: recordFieldValue.textContent ?? "") { [self] newValue in
				if newValue != recordFieldValue.textContent {
					recordFieldValue.textContent = newValue
					rowModifiedCallback? ()
				}
			}
		} else {
			fldText.setup (defaultValue: recordFieldValue.valueContentString ?? "") { [self] newValue in
				if Double (newValue) != recordFieldValue.valueContent {
					recordFieldValue.valueContent = Double (newValue)
					rowModifiedCallback? ()
				}
			}
		}
		chkLarge.setup (initialValue: recordFieldValue.showAsLargeText) { [self] newValue in
			recordFieldValue.showAsLargeText = newValue
			if newValue {
				recordFieldValue.textContent = recordFieldValue.textContent?.replace (BBAESettings.shared.carriageReturnString, with: "\n")
			} else {
				recordFieldValue.textContent = recordFieldValue.textContent?.replace ("\n", with: BBAESettings.shared.carriageReturnString)
			}
			rowModifiedCallback? ()
		}
		
		if recordFieldValue.textContent?.contains ("\n") == true && !recordFieldValue.showAsLargeText {
			recordFieldValue.showAsLargeText = true
			displayData ()
		}
	}
	
	func startIdle () {
		timer.loop (interval: 1) { [weak self] in
			self?.idle2 ()
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
		cell.startIdle ()
		
		return cell
	}
	
	func idle2 () {
		if recordFieldValue.textContent?.contains ("\n") == true {
			recordFieldValue.showAsLargeText = true
			displayData ()
		}
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
