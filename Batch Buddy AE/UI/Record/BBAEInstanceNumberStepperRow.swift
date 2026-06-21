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

class BBAEInstanceNumberStepperRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceNumberStepperRow"
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: NSTextField!
	@IBOutlet weak var btnMinusStep: UMRoundedRectButton!
	@IBOutlet weak var btnPlusStep: UMRoundedRectButton!
	@IBOutlet weak var lblValue: NSTextField!
	@IBOutlet weak var chkIterator: UMCheckButton!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	var minV : Double {
		templateItem?.numericFieldSettings.minValue ?? 0
	}
	
	var maxV : Double {
		templateItem?.numericFieldSettings.maxValue ?? 100
	}
	
	var step :	Double {
		templateItem?.numericFieldSettings.step ?? 1
	}
	
	var stepS : String {
		step.string
	}
	
	// MARK: - Display
	func setupIterator () {
		chkIterator.isHidden = !(templateItem?.isIterator == true)
		chkIterator.setup (initialValue: recordFieldValue.iterator) { [weak self] newValue in
			guard let s = self else { return }
			s.recordFieldValue.iterator = newValue
			s.rowModifiedCallback? ()
			s.displayData ()
		}
		
		btnMinusStep.isHidden = recordFieldValue.iterator
		btnPlusStep.isHidden = recordFieldValue.iterator
	}
	
	func displayValue () {
		lblValue.setValue (recordFieldValue.iterator
						   ? "\(minV.int) -> \(maxV.int)"
						   : (String (recordFieldValue.valueContent ?? 0)))
	}
	
	func displayData () {
		XMain.execute { [weak self] in
			guard let s = self else { return }
			s.lblFieldName.setValue ((s.templateItem?.fieldName ?? "UNDEFINED") + ":")
			s.btnMinusStep.title = "- \(s.stepS)"
			s.btnPlusStep.title = "+ \(s.stepS)"
			s.displayValue ()
			s.setupIterator ()
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
	@IBAction func btnMinusSteoPressed(_ sender: Any) {
		recordFieldValue.valueContent = max ((recordFieldValue.valueContent ?? 0) - step,
											 minV)
		rowModifiedCallback? ()
		displayData ()
	}
	
	@IBAction func btnPlusStepPressed(_ sender: Any) {
		recordFieldValue.valueContent = min ((recordFieldValue.valueContent ?? 0) + step,
											 maxV)
		rowModifiedCallback? ()
		displayData ()
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
