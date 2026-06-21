//
//  BBAEInstanceVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 29/07/2021.
//

import Cocoa
import UMOmniaFramework

class BBAERecordVC :	UMViewController {
	
	static let storyboardId = 	"BBAERecordVC"
	static let storyboardName =	"BBAETemplatePanel"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblList: UMTableView!
	
	// MARK: - Vars
	var project :			BBAEProject!
	var record :			BBAERecord!
	var hostController :	NSViewController!
	
	var template :	BBAEComp? {
		project.getComp (withId: record.compId)
	}
	
	// MARK: - Display
	func displayData () {
		tblList.reloadData ()
		windowTitle = (template?.name ?? "Template") + " Instance"
		
//		project.observeUpdate { [weak self] in
//			self?.displayData ()
//			self?.tblList.reloadDataInMainThread ()
//		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
		

	}
	
	// MARK: - Table
	func setupTable () {
		tblList.rowCount = {
			1
		}
		tblList.registerCell (cellId: "BBAERecordCell")
		tblList.cellHandler = { [self] row in
			BBAERecordCell.getCell (tblList,
									record: record,
									project: project,
									fatherController: self,
									delegate: self)
		}
		tblList.cellHeight = { [self] row in
			record.cellHeight ()
		}
	}
	
	override func loaded () {
		setupTable ()
	}
	
	// MARK: - Show
	static func showWindow (instance :	BBAERecord,
							project :	BBAEProject) {
		//		if let uniqueId = uniqueId {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.bbaeinstancevc.\(instance.id)",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									bundle: nil,
//									windowTitle: "INSTANCE (CHANGE ME!)",
									disableResize: false,
									minWidth: 620,
									maxWidth: 620,
									minHeight: 288) { vc in
			guard let vc = vc as? Self else { return }
			vc.record = instance
			vc.project = project
		}

	}
	
	// MARK: - Actions
}


// MARK: - BBAEInstanceCellDelegate
extension BBAERecordVC :	BBAERecordCellDelegate {
	
	func updateRecord () {
		project.save ()
//		updateLiveData ()
	}
	
	func removeRecord (_ id: String) {
//		bbaeProject.itemInstanceList.removeAll { $0.id == id }
//		bbaeProject.save ()
//		updateLiveData ()
	}
	
	func displayInstanceCtxMenu (item :				BBAERecord,
								 button sender :	NSButton) {
//		currentItem = item
//		if let event = NSApplication.shared.currentEvent {
//			NSMenu.popUpContextMenu (mnuCtxRender,
//									 with: event,
//									 for: sender)
//		}
	}
	
	// MARK: - renderRecord
	func renderRecord (item: BBAERecord) {
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			item.status = .rendering
			project.notifyUpdate ()
//			updateLiveData ()
//			BBAERenderingVC.showSheet (currentController: <#T##NSViewController#>)
			project.renderRecord (item) { success, error in
				item.status = success
					? .rendered
					: .toBeRendered
//				self.updateLiveData ()
			}
		}
//		self.currentItem = nil
	}
	
	// MARK: - renderPlaceholderInstance
	func renderPlaceholderInstance (item: BBAERecord) {
		Queue.execute { [self] in
			item.status = .rendering
			project.notifyUpdate ()
//			updateLiveData ()
			project.renderPlaceholderItem (item) { value in
				item.status = value
					? .rendered
					: .toBeRendered
//				self.updateLiveData ()
			}
		}
//		self.currentItem = nil
	}
	
	
	func duplicateRecord (_ id: String) {
//		bbaeProject.duplicateItem (id)
//		bbaeProject.save ()
//		updateLiveData ()
//		tblList.scroll (toRow: bbaeProject.itemInstanceList.count - 1)
	}
}
