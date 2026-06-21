//
//  BBAEProjectTemplateListCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAEProjectTemplateListCellDelegate {
	func removeTemplate (bbaeTemplate :	BBAEComp)
	func updateTemplate (bbaeTemplate :	BBAEComp)
	func duplicateTemplate (bbaeTemplate :	BBAEComp)
}

class BBAEProjectTemplateListCell :	UMTableCell {
	
	// MARK: - UI
	@IBOutlet weak var fldShortName: NSTextField!
	@IBOutlet weak var fldName: NSTextField!
	@IBOutlet weak var popColor: UMPopUpButton!
	
	// MARK: - var
	var bbaeTemplate :	BBAEComp!
	var bbaeProject :	BBAEProject!
	var delegate :		BBAEProjectTemplateListCellDelegate!
	
	// MARK: - Display
	func populateColorList () {
		popColor.clear ()
		for color in bbaeProject.colorList {
			popColor.addItem (title: color.name,
							  value: color.id)
		}
		popColor.setValueAsString (value: bbaeTemplate.defaultColorId ?? "Not Set")
		popColor.userSelectedCallback = { [weak self] value in
			let valueS = value as! String
			self?.bbaeTemplate.defaultColorId = valueS != "*"
				? valueS
				: nil
			self?.delegate.updateTemplate (bbaeTemplate: self!.bbaeTemplate)
		}
		popColor.addItem (title: "Not Set",
						  value: "*")
	}
	
	func displayData () {
		populateColorList ()
		fldShortName.setValue (bbaeTemplate.shortName)
		fldName.setValue (bbaeTemplate.name)
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 bbaeTemplate :	BBAEComp,
						 bbaeProject :	BBAEProject,
						 delegate :		BBAEProjectTemplateListCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: "BBAEProjectTemplateListCell") as? Self else { return nil }
		cell.bbaeTemplate = bbaeTemplate
		cell.bbaeProject = bbaeProject
		cell.delegate = delegate
		cell.displayData ()
		
		//cancella se non la vuoi
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Actions
	@IBAction func btnRemovePressed(_ sender: Any) {
		delegate.removeTemplate( bbaeTemplate: bbaeTemplate)
	}
	
	@IBAction func textUpdated (_ sender: Any) {
		bbaeTemplate.setShortName (fldShortName.stringValue)
		bbaeTemplate.name = fldName.stringValue
		delegate.updateTemplate (bbaeTemplate: bbaeTemplate)
	}
}
