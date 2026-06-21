//
//  BBAEInstanceLongTextRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 08/06/2021.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAEInstanceLongTextRow :	UMTableCell,
								NSTextViewDelegate {
	
	static let cellId = "BBAEInstanceLongTextRow"
	
	static let pressureQueue = UMPressureTask ()
	
	// MARK: - UI
	@IBOutlet weak var lblFieldName: NSTextField!
	@IBOutlet var txtText: NSTextView!
	@IBOutlet weak var chkLarge: UMCheckButton!
	
	//	@IBOutlet weak var fldText: UMTextField!
	
	// MARK: - var
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	var timer =					UMTimer ()
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	var previousText :			String?
	let pressureQueue =			UMPressureTask ()
	
	// MARK: - Display
	func displayData () {
		XMain.execute { [self] in
			ih_setTextView (txtText, recordFieldValue.textContent ?? "")
			previousText = recordFieldValue.textContent
			if let textStorage = txtText.textStorage {
				let area = NSRange (location: 0, length: textStorage.length)
				textStorage.removeAttribute (.foregroundColor, range: area)
				textStorage.addAttribute (.foregroundColor,
										  value: NSColor (red: 0.25, green: 0.25, blue: 0.25, alpha: 1),
										  range: area)
			}
			txtText.delegate = self
			txtText.forceDark ()
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
	}
	
	override func prepareForReuse () {
//		collectText ()
		timer.stop ()
//		rowModifiedCallback ()
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
	
	func collectText () {
//		recordFieldValue.textContent = txtText.stringValue //ih_getTextView (txtText)
		recordFieldValue.textContent = ih_getTextView (txtText)

//		print (recordFieldValue)
		let rmf = rowModifiedCallback
		pressureQueue.perform (after: 10) {
			rmf? ()
		}
	}
	
//	override func textShouldEndEditing (textObject: NSText) -> Bool {
//		let event = NSApplication.sharedApplication().currentEvent
//		if event?.type == NSEventType.KeyDown && event?.keyCode == 36 {
//			self.stringValue = self.stringValue.stringByAppendingString("\n")
//			return false
//		} else {
//			return super.textShouldEndEditing(textObject)
//		}
//	}
	
	func textDidEndEditing (_ notification: Notification) {
		collectText ()
	}
	
	func textDidChange (_ notification: Notification) {
		let id = recordFieldValue.id
		BBAEInstanceLongTextRow.pressureQueue.perform (after: 1) { [weak self] in
			if let s = self,
			   id == s.recordFieldValue.id {
//				s.recordFieldValue.textContent = s.txtText.stringValue // ih_getTextView (s.txtText)
				s.recordFieldValue.textContent = ih_getTextView (s.txtText)
				if s.recordFieldValue.textContent != s.previousText {
					s.previousText = s.recordFieldValue.textContent
				}
			}
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
