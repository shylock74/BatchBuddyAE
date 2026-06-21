//
//  BBAERenderOutputListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 12/09/21.
//

import Cocoa
import UMOmniaFramework

class BBAERenderOutputListVC :	UMViewController {
	
	static let storyboardId = 	"BBAERenderOutputListVC"
	static let storyboardName =	"BBAESettings"
	
	enum Show {
		case render
		case ouput
	}
	
	// MARK: - UI Elements
	@IBOutlet weak var lblTitle: NSTextField!
	@IBOutlet weak var lblName: NSTextField!
	@IBOutlet weak var lblExtension: NSTextField!
	@IBOutlet weak var tblList: UMTableView!
	
	// MARK: - Vars
	var show :		Show!
	var settings =	BBAESettings.shared

	var aeTemplateList :	[BBAESettings.AETemplate] {
		show == .render
			? settings.aeRenderSettingList ?? []
			: settings.aeOutputModuleList ?? []
	}
	
	func remove (_ id :	String) {
		if show == .render {
			settings.aeRenderSettingList = settings.aeRenderSettingList?.filter { $0.id != id}
		} else {
			settings.aeOutputModuleList = settings.aeOutputModuleList?.filter { $0.id != id}
		}
		settings.save ()
	}
	
	// MARK: - Table
	func setupTable () {
		tblList.rowCount = { [self] in
			aeTemplateList.count
		}
		tblList.registerCell (cellId: "BBAEOutputModuleCell")
		tblList.cellHandler = { [self] row in
			BBAEOutputModuleCell.getCell (tblList,
										  type: show,
										  aeTemplate: aeTemplateList [row]) { [weak self] idToRemove in
				self?.remove (idToRemove)
				self?.tblList.reloadDataInMainThread ()
			}
		}
		tblList.cellHeight = { row in
			28
		}
		
		tblList.sortCallback = { [self] in
			if show == .render {
				settings.aeRenderSettingList?.move (fromOffsets: IndexSet (integer: $0),
													toOffset: $1)
			} else {
				settings.aeOutputModuleList?.move (fromOffsets: IndexSet (integer: $0),
												   toOffset: $1)
			}
			tblList.reloadDataInMainThread ()
			settings.save ()
		}
	}
	
	// MARK: - Display
	func displayData () {
		lblTitle.setValue (show == .render ? "Render Settings" : "Output Modules")
		lblName.setValue (show == .render ? "Setting Name" : "Module name")
		lblExtension.isHidden = show == .render
		setupTable ()
		tblList.reloadData ()
	}
	
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   show :				Show) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.show = show
		}
	}
	
//	static func showWindow (uniqueId :	String?,
//							PARAM :		PARAM) {
//		if let uniqueId = uniqueId {
//			UMWindowsGroup.shared.show (id: uniqueId,
//										viewControllerId: Self.storyboardId,
//										storyboardName: Self.storyboardName,
//										bundle: nil,
//										windowTitle: "WINDOWTITLE",
//										disableResize: false) { vc in
//				guard let vc = vc as? Self else { return }
//				vc.PARAM = PARAM
//			}
//		} else {
//			_ = UMWindows.instantiateWindowAndController (viewControllerId: Self.storyboardId,
//														  storyboardName: Self.storyboardName,
//														  bundle: nil,
//														  windowTitle: "WINDOWTITLE",
//														  resizable: true) { vc in
//				guard let vc = vc as? Self else { return }
//				vc.PARAM = PARAM
//			}
//		}
//	}
	
	// MARK: - Actions
	@IBAction func btnAddPressed(_ sender: Any) {
		let newTemplate = BBAESettings.AETemplate (title: "Untitled",
												   fileExtension: "mov")
		if show == .render {
			settings.aeRenderSettingList!.append (newTemplate)
		} else {
			settings.aeOutputModuleList!.append (newTemplate)
		}
		tblList.reloadData ()
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
}

