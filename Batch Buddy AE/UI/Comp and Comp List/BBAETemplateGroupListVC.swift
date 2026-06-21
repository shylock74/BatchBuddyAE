//
//  BBAETemplateGroupListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 09/09/2021.
//

import Cocoa
import UMOmniaFramework

class BBAETemplateGroupListVC :	UMViewController,
								BBAETemplateGroupCellDelegate {

	static let storyboardId = 	"BBAETemplateGroupListVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
	@IBOutlet weak var fldName: UMTextField!
	@IBOutlet weak var tblList: UMTableView!
	
	// MARK: - Vars
	var project :	BBAEProject!
	var comp :		BBAEComp!
	
	// MARK: - Display
	func displayData () {
		fldName.setup (defaultValue: comp.name) { [weak self] newValue in
			self?.comp.name = newValue
			self?.project.notifyUpdate ()
		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
//	func registerTableCells () {
//		BBAETemplateGroupCell.register (tblList)
//	}
//
//	func setupTableList () {
//		registerTableCells ()
//		tblList.dataSource = self
//		tblList.delegate = self
//	}
	func setupTable () {
		tblList.rowCount = {
			self.comp.compGroupList!.count
		}
		tblList.registerCell (cellId: "BBAETemplateGroupCell")
		tblList.cellHandler = { [self] row in
			BBAETemplateGroupCell.getCell (tblList,
										   project: project,
										   template: comp,
										   templateGroup: comp.compGroupList! [row],
										   delegate: self,
										   currentController: self)
		}
		tblList.cellHeight = { [self] row in
//			instance.cellHeight ()
			24
		}
	}
	
	override func loaded () {
		setupTable ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   project :			BBAEProject,
						   template :			BBAEComp) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.project = project
			vc.comp = template
		}
	}
	
	// MARK: - Actions
	@IBAction func btnAddGroupPressed(_ sender: Any) {
		let newGroup = BBAECompGroup (name: "", shortName: "")
		comp.compGroupList!.append (newGroup)
		tblList.reloadData ()
		project.notifyUpdate ()
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
//		ACTION
		close ()
	}
	
	// cell delegate
	func duplicateTemplateGroup (_ templateGroup :	BBAECompGroup) {
		let newGroup = templateGroup.duplicate ()
		comp.compGroupList!.append (newGroup)
		project.notifyUpdate ()
		tblList.reloadDataInMainThread ()
	}
	
	func updateTemplateGroup () {
//		let newGroup = BBAETemplateGroup (name: "", shortName: "")
//		template.templateGroupList!.append (newGroup)
	}
	
	func removeTemplateGroup (_ id: String) {
		comp.compGroupList!.removeAll { $0.id == id }
		tblList.reloadDataInMainThread ()
		project.notifyUpdate ()
	}
	
	
//	@IBAction func btnCancelPressed(_ sender: Any) {
//		close ()
//	}
}
