//
//  BBAEInstanceNumberSliderRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 09/01/22.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceNumberSliderRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceNumberSliderRow"
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: NSTextField!
	@IBOutlet weak var sldValue: UMSlider!
	@IBOutlet weak var lblValue: NSTextField!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	// MARK: - Display
	func displayData () {
		XMain.execute { [weak self] in
			guard let s = self else { return }
			s.lblFieldName.setValue ((s.templateItem?.fieldName ?? "UNDEFINED") + ":")
			
			s.sldValue.minValue = s.templateItem?.numericFieldSettings.minValue ?? 0
			s.sldValue.maxValue = s.templateItem?.numericFieldSettings.maxValue ?? 100
			s.sldValue.setup (label: s.lblValue,
							  defaultValue: s.recordFieldValue.valueContent,
							  labelDecimalDigits: 1) { [weak self] newValue in
				self?.recordFieldValue.valueContent = newValue
				self?.rowModifiedCallback? ()
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
