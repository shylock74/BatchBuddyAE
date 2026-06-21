//
//  BBAETemplateStructureNumericCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 08/01/22.
//

import Foundation
import Cocoa
import UMOmniaFramework

// MARK: - BBAETemplateStructureNumericCell
class BBAETemplateStructureNumericCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureNumericCell"
	
	// MARK: - UI
	@IBOutlet weak var fldFieldName: UMTextField!
	@IBOutlet weak var fldDefault: UMTextField!
	@IBOutlet weak var popAppearance: UMPopUpButton!
	@IBOutlet weak var fldStep: UMTextField!
	@IBOutlet weak var fldMin: UMTextField!
	@IBOutlet weak var fldMax: UMTextField!
	@IBOutlet weak var chkIterator: UMCheckButton!
	
	// MARK: - var
	var compField :	BBAECompField!
	var comp :		BBAEComp!
	var project :	BBAEProject!
	var delegate :	BBAETemplateStructureCellDelegate!
	var selected =	false {
		didSet {
			hilite = selected
		}
	}
	
	// MARK: - Notifications
	func notifyUpdates () {
		delegate.updateTemplate ()
		comp.notifyUpdate ()
		project.notifyUpdate ()
		UMNotify.notify (keyword: "media.ulti.bbae.\(compField.id)")
	}
	
	func setupPopAppearance () {
		popAppearance.clear ()
		popAppearance.addItem (title: BBAECompField.NumericFieldSettings.Appearance.field.displayString,
							   value: BBAECompField.NumericFieldSettings.Appearance.field.rawValue)
		popAppearance.addItem (title: BBAECompField.NumericFieldSettings.Appearance.slider.displayString,
							   value: BBAECompField.NumericFieldSettings.Appearance.slider.rawValue)
		popAppearance.addItem (title: BBAECompField.NumericFieldSettings.Appearance.stepper.displayString,
							   value: BBAECompField.NumericFieldSettings.Appearance.stepper.rawValue)
		popAppearance.setValueAsString (value: compField.numericFieldSettings.appearance.rawValue)
		popAppearance.userSelectedCallback = { [weak self] newValue in
			guard let s = self else { return }
			s.compField.numericFieldSettings.appearance = BBAECompField.NumericFieldSettings.Appearance (rawValue: newValue as! String)!
			s.delegate.updateTemplate ()
			s.notifyUpdates ()
			s.enableFields ()
		}
	}
	
	func enableFields () {
		fldMax.isEnabled = compField.numericFieldSettings.enableMinMax
		fldMin.isEnabled = compField.numericFieldSettings.enableMinMax
		fldStep.isEnabled = compField.numericFieldSettings.enableStep
	}
	
	func adjustDefault () {
		guard compField.defaultNumericValue != nil else { return }
		compField.defaultNumericValue = max (compField.defaultNumericValue!, compField.numericFieldSettings.minValue)
		compField.defaultNumericValue = min (compField.defaultNumericValue!, compField.numericFieldSettings.maxValue)
		var v = compField.numericFieldSettings.minValue - compField.numericFieldSettings.step
		while v <= compField.numericFieldSettings.maxValue {
			v += compField.numericFieldSettings.step
			if compField.defaultNumericValue == v {
				return
			}
		}
		v = compField.numericFieldSettings.minValue
	}
	
	func setupIteratorCheck () {
		chkIterator.isHidden = compField.numericFieldSettings.appearance != .stepper
		chkIterator.setup (initialValue: compField.numericFieldSettings.iterator) { [weak self] newValue in
			guard let s = self else { return }
			s.compField.numericFieldSettings.iterator = newValue
			s.delegate.updateTemplate ()
			s.notifyUpdates ()
			s.enableFields ()
		}
	}
	
	func displayData () {
		fldFieldName.setup (defaultValue: compField.fieldName) { [self] newValue in
			compField.fieldName = newValue
			BBAECompField.addFieldToGlobalList (compField)
			delegate.updateTemplate ()
			notifyUpdates ()
		}
		let dS = compField.type == .numericValue
		? (compField.defaultNumericValue != nil
		   ? String (compField.defaultNumericValue ?? 0)
		   : "")
		: ""
		fldDefault.setup (defaultValue: dS) { [self] newValue in
			if compField.type == .numericValue {
				compField.defaultNumericValue = Double (newValue)
			}
		}
		fldStep.setup (defaultValue: String (compField.numericFieldSettings.step)) { [self] newValue in
			compField.numericFieldSettings.step = Double (newValue) ?? compField.numericFieldSettings.step
			if compField.numericFieldSettings.step == 0 {
				compField.numericFieldSettings.step = 1
			}
			adjustDefault ()
		}
		fldMin.setup (defaultValue: String (compField.numericFieldSettings.minValue)) { [self] newValue in
			compField.numericFieldSettings.minValue = Double (newValue) ?? compField.numericFieldSettings.minValue
			if compField.numericFieldSettings.minValue > compField.numericFieldSettings.maxValue {
				compField.numericFieldSettings.minValue = compField.numericFieldSettings.maxValue
			}
			adjustDefault ()
		}
		fldMax.setup (defaultValue: String (compField.numericFieldSettings.maxValue)) { [self] newValue in
			compField.numericFieldSettings.maxValue = Double (newValue) ?? compField.numericFieldSettings.maxValue
			if compField.numericFieldSettings.maxValue < compField.numericFieldSettings.minValue {
				compField.numericFieldSettings.maxValue = compField.numericFieldSettings.minValue
			}
			adjustDefault ()
		}
		
		setupIteratorCheck ()
		setupPopAppearance()
		enableFields ()
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 compField :	BBAECompField,
						 comp :			BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.compField = compField
		cell.project = project
		cell.delegate = delegate
		cell.comp = comp
		cell.displayData ()
		cell.setBackground ()
		
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
	
	// MARK: - Actions
	@IBAction func fldFieldNameChanged (_ sender: Any) {
		compField.fieldName = fldFieldName.stringValue
		project.notifyUpdate ()
		notifyUpdates ()
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplateItem (compField.id)
		project.notifyUpdate ()
	}
	
	@IBAction func btnCopyCodePressed (_ sender: Any) {
		let code = compField.getAECode ()
		UMPasteboard.setString (code)
		
		var t :	String = ""
		switch compField.type {
			case .text, .longText:
				t = "Text"
			case .colorFill:
				t = "Color"
			case .numericValue:
				t = "Number"
			default: break
		}
		UMShowNotification (title: "Copied",
							informativeText: "After Effects \(t) Code Copied Successfully.")
	}
	
	@IBAction func btnCopyFillColorPressed (_ sender: Any) {
		let code = BBAESettings.shared.getDynamicColorFillString (variableName: compField.variableName ())
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "After Effects Color Fill Copied Successfully.")
	}
}
