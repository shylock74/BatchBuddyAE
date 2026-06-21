//
//  BBAEProjectItemCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAEProjectItemCellDelegate {
	func removeItem (bbaeItem :	BBAERecord)
	func updateItem (bbaeItem :	BBAERecord)
}

class BBAERecordItemCell :	UMTableCell {
	
	// MARK: - UI
	@IBOutlet weak var chkRender: UMCheckButton!
	@IBOutlet weak var lblStatus: NSTextField!
	@IBOutlet weak var fldText01: NSTextField!
	@IBOutlet weak var fldText02: NSTextField!
	@IBOutlet weak var popTemplate: UMPopUpButton!
	@IBOutlet weak var popColor1: UMPopUpButton!
	@IBOutlet weak var popColor2: UMPopUpButton!
	
	// MARK: - var
	var id =			UMId.newId (useCounter: false)
	var bbaeItem :		BBAERecord!
	var bbaeProject :	BBAEProject!
	var delegate :		BBAEProjectItemCellDelegate!
	
	private var observedKeys = [String] ()
	
	func cleanPreviousObservers () {
		for key in observedKeys {
			UMDispatch.remove (key: key, myId: id)
		}
		observedKeys.removeAll ()
	}
	
	override func prepareForReuse () {
		super.prepareForReuse ()
		cleanPreviousObservers ()
	}
	
	// MARK: - Display
	func populateTemplate () {
		popTemplate.clear ()
//		for template in bbaeProject.compList {
//			popTemplate.addItem (title: template.name,
//								 value: template.id)
//		}
		popTemplate.add (items: bbaeProject.compList.map { .init (title: $0.name,
																  value: $0.id)} )
		popTemplate.setValueAsString (value: bbaeItem.compId ?? "Not Set")
		popTemplate.userSelectedCallback = { [weak self] value in
			self?.bbaeItem.compId = value as! String
			self?.delegate.updateItem (bbaeItem: self!.bbaeItem)
		}
	}
	
	func displayUpdate () {
		chkRender.value = bbaeItem.status == .toBeRendered
		lblStatus.setValue (bbaeItem.status.displayString ())
	}
	
	func populateData () {
		chkRender.setup (initialValue: bbaeItem.status == .toBeRendered) { [weak self] value in
			self?.bbaeItem.status = value ? .toBeRendered : .dontRender		}
		populateTemplate ()

	}
	
	func displayData () {
		cleanPreviousObservers ()
		populateData ()
		
		let key = bbaeItem.id
		UMDispatch.observe (key: key,
							myId: id) { [weak self] in
			XMain.execute {
				self?.populateData ()
			}
		}
		observedKeys.append (key)
	}
	
	@IBAction func btnRenderPressed (_ sender: Any) {
		bbaeItem.status = .rendering
		bbaeProject.save ()
		displayUpdate ()
		
		Queue.execute {
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			self.bbaeProject.renderRecord (self.bbaeItem) { success, error in
				XMain.execute { [weak self] in
					if !success {
						UMAlert.ok (message: "After Effects Render Error",
									informativeText: error)
					}
					self?.displayUpdate ()
				}
			}
		}
	}
	
	@IBAction func btnRemovePressed(_ sender: Any) {
		delegate.removeItem (bbaeItem: bbaeItem)
	}
	
	
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 bbaeItem :		BBAERecord,
						 bbaeProject :	BBAEProject,
						 delegate :		BBAEProjectItemCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: "BBAERecordItemCell") as? Self else { return nil }
		cell.bbaeItem = bbaeItem
		cell.bbaeProject = bbaeProject
		cell.delegate = delegate
		cell.displayData ()
		
		//cancella se non la vuoi
		cell.setBackground ()
		
		return cell
	}
}
