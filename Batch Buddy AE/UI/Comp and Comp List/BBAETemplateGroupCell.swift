//
//  BBAETemplateGroupCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 09/09/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAETemplateGroupCellDelegate {
	func updateTemplateGroup ()
	func duplicateTemplateGroup (_ templateGroup :	BBAECompGroup)
	func removeTemplateGroup (_ id : String)
}

class BBAETemplateGroupCell :	UMTableCell {
	
	static let cellId = "BBAETemplateGroupCell"
	
	// MARK: - UI
	@IBOutlet weak var fldShort: UMTextField!
	@IBOutlet weak var fldName: UMTextField!
	@IBOutlet weak var chkActive: UMCheckButton!
	
	// MARK: - var
	var project :			BBAEProject!
	var template :			BBAEComp!
	var templateGroup :		BBAECompGroup!
	var delegate : 			BBAETemplateGroupCellDelegate!
	var currentController :	NSViewController!
	
	// MARK: - Display
	func displayData () {
		fldShort.setup (defaultValue: templateGroup.shortName) { [weak self] newValue in
			self?.templateGroup.shortName = newValue
			self?.project.notifyUpdate ()
		}
		fldName.setup (defaultValue: templateGroup.name) { [weak self] newValue in
			self?.templateGroup.name = newValue
			self?.project.notifyUpdate ()
		}
		chkActive.setup (initialValue: templateGroup.active) { [weak self] newValue in
			self?.templateGroup.active = newValue
			self?.project.notifyUpdate ()
		}
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  		NSTableView,
						 project :				BBAEProject,
						 template :				BBAEComp,
						 templateGroup :		BBAECompGroup,
						 delegate: 				BBAETemplateGroupCellDelegate,
						 currentController :	NSViewController) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.project = project
		cell.templateGroup = templateGroup
		cell.template = template
		cell.delegate = delegate
		cell.currentController = currentController
		cell.displayData ()
		
		//cancella se non la vuoi
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Actions
	@IBAction func btnDuplicatePressed(_ sender: Any) {
		delegate.duplicateTemplateGroup (templateGroup)
	}
	
	@IBAction func btnRemovePressed(_ sender: Any) {
		delegate.removeTemplateGroup (templateGroup.id)
	}
	
	@IBAction func btnSettingsPressed(_ sender: Any) {
		let tempTemplate = templateGroup.tempComp
		BBAECompSettingsVC.showSheet (currentController: currentController,
										  template: tempTemplate,
										  project: project) { [weak self] newTempTemplate in
			self?.templateGroup.update (withTempComp: newTempTemplate)
			self?.project.notifyUpdate ()
		}
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
