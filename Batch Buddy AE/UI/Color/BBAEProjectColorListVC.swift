//
//  BBAEProjectColorListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 21/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAEProjectColorListVC :	UMViewController {
	
	static let storyboardId = 	"BBAEProjectColorListVC"
//	static let storyboardName =	"STORYBOARDNAME"
	
	// MARK: - UI Elements
	@IBOutlet weak var lblColorN: NSTextField!
	@IBOutlet weak var tblList: NSTableView!
	
	// MARK: - Vars
	var bbaeProject :	BBAEProject!
	
	// MARK: - Display
	func updateColorCountlabel () {
		lblColorN.setValue ("Project Colors Count: \(bbaeProject.colorList.count)")
	}
	
	func displayData () {
		updateColorCountlabel ()
	}
	
	func registerTableCells () {
		BBAEProjectColorListCell.register (tblList)
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	override func loaded () { 
		registerTableCells ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   bbaeProject :		BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
//							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	static func showWindow (bbaeProject :		BBAEProject) {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.\(bbaeProject.id).colorList",
									viewControllerId: Self.storyboardId,
									windowTitle: "\(bbaeProject.name) Color List",
									minWidth: 600,
									maxWidth: 600,
									minHeight: 320,
									maxHeight: nil) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	override func disappeared () {
		UMWindowsGroup.shared.didClose (id: "media.ulti.bbae.\(bbaeProject.id).colorList")
	}
	
	// MARK: - Actions
	@IBAction func btnAddPressed (_ sender: Any) {
		let newColor = BBAEProjectColor (name: "New Color",
										 color: UMColor (0, 0, 0))
		bbaeProject.colorList.append (newColor)
		bbaeProject.notifyUpdate ()
		tblList.reloadData ()
		updateColorCountlabel ()
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
//		ACTION
		close ()
	}
	
	@IBAction func btnCancelPressed(_ sender: Any) {
		close ()
	}
}

extension BBAEProjectColorListVC :	BBAEProjectColorListCellDelegate {
	
	func removeColor (bbaeColor :	BBAEProjectColor) {
		bbaeProject.colorList = bbaeProject.colorList.filter { $0.id != bbaeColor.id }
		bbaeProject.notifyUpdate ()
		updateColorCountlabel ()
		tblList.reloadDataInMainThread ()
	}
}

// MARK: - Table
extension BBAEProjectColorListVC : NSTableViewDelegate, NSTableViewDataSource {
	
	func numberOfRows (in tableView: NSTableView) -> Int {
		bbaeProject.colorList.count
	}
	
	func tableView (_ tableView: NSTableView,
					viewFor tableColumn: NSTableColumn?,
					row: Int) -> NSView? {
		let cell = BBAEProjectColorListCell.getCell (tableView,
													 bbaeProject: bbaeProject,
													 bbaeColor: bbaeProject.colorList [row],
													 delegate: self)
		return cell
	}
	
//	func tableViewSelectionDidChange (_ notification: Notification) {
//		let table = notification.object as! NSTableView
//		let selectedRow = table.selectedRow
//	}
}

