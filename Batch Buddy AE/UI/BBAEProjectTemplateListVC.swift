//
//  BBAEProjectTemplateListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAEProjectTemplateListVC :	UMViewController {
	
	static let storyboardId = 	"BBAEProjectTemplateListVC"
//	static let storyboardName =	"STORYBOARDNAME"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblList: NSTableView!
	
	// MARK: - Vars
	var bbaeProject :	BBAEProject?
	
	// MARK: - Display
	func displayData () {
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	func setupTableList () {
		tblList.dataSource = self
		tblList.delegate = self
	}
	
	override func loaded () {
		setupTableList ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   bbaeProject :	BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	// MARK: - Actions
	@IBAction func btnAddTemplatePressed (_ sender: Any) {
		bbaeProject?.compList.append (BBAEComp (name: ""))
		bbaeProject?.notifyUpdate ()
		tblList.reloadData ()
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
}


extension BBAEProjectTemplateListVC :	BBAEProjectTemplateListCellDelegate {
	
	func removeTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject!.compList = bbaeProject!.compList.filter { $0.id != bbaeTemplate.id }
		bbaeProject!.save ()
		tblList.reloadData ()
	}
	
	func updateTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject!.save ()
		tblList.reloadData ()
	}
	
	func duplicateTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject?.duplicateTemplate (bbaeTemplate)
		tblList.reloadData ()
	}

}

// MARK: - Table
extension BBAEProjectTemplateListVC : NSTableViewDelegate, NSTableViewDataSource {
	
	func numberOfRows (in tableView: NSTableView) -> Int {
		bbaeProject?.compList.count ?? 0
	}
	
	func tableView (_ tableView: NSTableView,
					viewFor tableColumn: NSTableColumn?,
					row: Int) -> NSView? {
		let cell = BBAEProjectTemplateListCell.getCell (tableView,
														bbaeTemplate: bbaeProject!.compList [row],
														bbaeProject: bbaeProject!,
														delegate: self)
		return cell
	}
	
//	func tableViewSelectionDidChange (_ notification: Notification) {
//		let table = notification.object as! NSTableView
//		let selectedRow = table.selectedRow
//	}
}

