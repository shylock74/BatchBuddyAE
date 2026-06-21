//
//  BBAEInstanceColorRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 23/07/2021.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceColorRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceColorRow"
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: NSTextField!
	@IBOutlet weak var popColor: UMPopUpButton!
	@IBOutlet weak var colColor: NSColorWell!
	
	// MARK: - var
		var project :				BBAEProject!
	//	var template :				BBAETemplateComp!
	//	var templateCompItem :		BBAETemplateCompItem!
	var recordFieldValue :				BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	var templateItem :	BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	// MARK: - Display
	func fillPopColor () {
		popColor.addItem (title: "Custom",
							 value: "*")
		
		for color in project.colorList {
			popColor.addItem (title: color.name,
								 value: color.id)
		}
		popColor.setValueAsString (value: recordFieldValue.colorId ?? "*")
		popColor.userSelectedCallback = { [weak self] value in
			guard let s = self else { return }
			guard let valueS = value as? String else { return }
			let newId = valueS == "*"
				? nil
				: valueS
			if newId != s.recordFieldValue.colorId {
				s.recordFieldValue.colorId = newId
				s.setColorWell ()
			}
			s.rowModifiedCallback? ()
		}
	}
	
	func setColorWell () {
		if let colorId = recordFieldValue.colorId,
		   let color = project.getColor (colorId) {
			colColor.color = color.color.getColor ()
		} else {
			colColor.color = .black
		}
	}
	
	func displayData () {
		lblFieldName.setValue ((templateItem?.fieldName ?? "UNDEFINED") + ":")
		fillPopColor ()
		setColorWell ()
	}
	
	// MARK: - Observer
	func setupObserver () {
		UMNotify.observe (keyword: "media.ulti.bbae.\(recordFieldValue.compFieldId)") { [weak self] in
			self?.displayData ()
		}
	}

	// MARK: - Show
	static func getCell (_ tableView :  		NSTableView,
						 project :				BBAEProject,
						 recordFieldValue :		BBAERecordFieldValue,
						 rowModifiedCallback :	@escaping () -> ()) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.recordFieldValue = recordFieldValue
		cell.project = project
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
