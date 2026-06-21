//
//  BBAEProjectVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAEProjectVC :	UMViewController {
	
	static let storyboardId = 	"BBAEProjectVC"
	
	// MARK: - UI Elements
	@IBOutlet weak var srcSearch: UMSearchField!
	@IBOutlet weak var popTemplateList: UMPopUpButton!
	@IBOutlet weak var btnShowToRender: NSButton!
	@IBOutlet weak var tblRecordList: UMTableView!
	@IBOutlet weak var chkRenderAll: UMCheckButton!
	@IBOutlet weak var lblItemsCount: NSTextField!
	@IBOutlet weak var lblStatus: NSTextField!
	@IBOutlet var mnuCtxRender: NSMenu!
	
	@IBOutlet weak var cnsTableLeading: NSLayoutConstraint!
	@IBOutlet weak var cnsTableTrailing: NSLayoutConstraint!
	
	// MARK: - Vars
	var project :		BBAEProject!
	var searchText :	String =	""
	var searchComp =	"*"
	var searchQueue =	UMPressureTask ()
	var isNew :			Bool!
	
	private let vcObserverId = UMId.newId (useCounter: false)
	
	var displayMode :	BBAERecord.DisplayMode =	.normal
	
	static var currentProject :	BBAEProject?
	
	@UMDef (key: "firstLaunch", def: true) var firstlaunch

	var showToBeRenderedOnly =	false
	
	func itemFoundList () -> [BBAERecord] {
		var itemInstanceListFilteredByTemplate = searchComp == "*"
			? project.recordList
			: project.recordList.filter { $0.compId == searchComp }
		if showToBeRenderedOnly {
			itemInstanceListFilteredByTemplate = itemInstanceListFilteredByTemplate.filter { $0.status == .toBeRendered }
		}
		if searchText == "" {
			return itemInstanceListFilteredByTemplate
		}
		let searchTextLowercased = searchText.lowercased ()
		return itemInstanceListFilteredByTemplate.filter { $0.umSearchContains (searchTextLowercased) }
	}
	
	// MARK: - Display
	func displayButtonToBeRenderedOnly () {
		XMain.execute { [self] in
			btnShowToRender.image = Draw.getImage (showToBeRenderedOnly ? "Icon_Render_00001" : "Icon_Render_00000")
		}
	}
	
	func populateTemplate () {
		popTemplateList.clear ()
		popTemplateList.addItem (title: "All Comp Templates",
								 value: "*")
		popTemplateList.addSeparator ()
		for template in project.compList {
			popTemplateList.addItem (title: template.name,
									 value: template.id)
		}
		popTemplateList.setValueAsString (value: "*")
		popTemplateList.userSelectedCallback = { [weak self] value in
			guard let valueS = value as? String else { return }
			self?.searchComp = valueS
			self?.performSearch ()
		}
	}
	
	// MARK: - table
	func setupTable () {
		tblRecordList.rowCount = {
			self.itemFoundList ().count
		}
		tblRecordList.registerCell (cellId: "BBAERecordCell")
		tblRecordList.registerCell (cellId: BBAERecordCompactRow.cellId)
		tblRecordList.cellHandler = { [self] row in
			let found = itemFoundList ()
			guard row < found.count else { return nil }
			if found [row].displayMode == .normal {
				return BBAERecordCell.getCell (tblRecordList,
											   record: found [row],
											   project: project,
											   fatherController: self,
											   delegate: self)
			} else {
				return BBAERecordCompactRow.getCell (tblRecordList,
													   record: found [row],
													   project: project,
													   fatherController: self,
													   delegate: self)
			}
		}
		tblRecordList.cellHeight = { [self] row in
			let record = itemFoundList () [row]
			return record.displayMode == .normal ? record.cellHeight () : 28
		}
	}
	
//	func setupProjectMissingWarning () {
//		imgProjectMissingWarning.isHidden = bbaeProject.aepFilePresent ()
//	}
	
	func displatItemsCount () {
		lblItemsCount.setValue ("Items: \(self.itemFoundList ().count)/\(project.recordList.count) (\((project.recordList.filter { $0.status == .toBeRendered }).count ) to be rendered)")
	}
	
	func setupSearch () {
		srcSearch.searchTextChanged = { text in
			self.searchText = text
			self.performSearch ()
		}
	}
	
	func displayData () {
		XMain.execute { [self] in
			setupSearch ()
			
			chkRenderAll.setup (initialValue: false) { value in
				self.itemFoundList ().forEach {
					$0.status = value ? .toBeRendered : .rendered
				}
				self.updateLiveData ()
			}
			displatItemsCount ()
			
			populateTemplate ()
			srcSearch.delegate = self
			
			lblStatus.setValue ("")
		}
		displayButtonToBeRenderedOnly ()
	}
	
	func updateLiveData () {
		tblRecordList.reloadDataInMainThread ()
		displayButtonToBeRenderedOnly ()
		displatItemsCount ()
	}
	
	// MARK: - Observer
	func setupObservers () {
		project.observeUpdate (observerId: vcObserverId) { [weak self] in
			self?.updateLiveData ()
			self?.displayData ()
			self?.displayButtonToBeRenderedOnly ()
		}
		UMNotify.observeString (keyword: project.statusUpdateKey) { [weak self] status in
			self?.lblStatus.setValue (status)
			self?.displayButtonToBeRenderedOnly ()
		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		setupTable ()
		displayData ()
		tblRecordList.reloadData ()
		setupObservers ()
		if isNew {
			isNew = false
			BBAEProjectSettingsVC.showSheet (currentController: self,
											 project: project)
		}
		
		if #available(OSX 11.0, *) {
			cnsTableLeading.constant = 0
			cnsTableTrailing.constant = 0
		}
		tblRecordList.addRoundedBackground (color: NSColor (deviceWhite: 0.15, alpha: 1))
	}
	
	override func appeared () {
		idleTimer.loop (interval: 1) { [weak self] in
			XMain.execute { [weak self] in
				if self?.view.window?.isOnActiveSpace == true {
					BBAEProjectVC.currentProject = self?.project
				}
			}
		}
		if firstlaunch {
			firstlaunch = false
			UMAlert.twoButtons (message: "AERender Missing",
								informativeText: """
It seems it's the firts time you launch Batch Buddy AE.
In order to render the comps this app needs to know where the executable AERender in the app folder of Adobe Affter Effects is.
Would you like me to search it?
""",
								button0Txt: "No, Thanks, Later",
								button1Txt: "Yes, continue") {
//				BBAESettingsVC.showWindow (goToTab: .rendering)
				AERenderSearcherVC.showWindow ()
			}
		}
	}
	
	override func willDisppear() {
		idleTimer.stop ()
		UMDispatch.remove (key: "media.ulti.bbae.projectUpdate.\(project.id)", myId: vcObserverId)
	}
	
	// MARK: - Show
	static func showWindow (bbaeProject :	BBAEProject,
							isNew :			Bool) {
		UMWindowsGroup.shared.show (id: UMId.newId (),
									viewControllerId: Self.storyboardId,
									windowTitle: bbaeProject.name,
									disableResize: false,
									minWidth: 640,
									maxWidth: 960,
									minHeight: 480) { vc in
			guard let vc = vc as? Self else { return }
			vc.project = bbaeProject
			vc.isNew = isNew
		}
		
	}
	
	// MARK: - Actions
	@IBAction func btnTemplatePanelPressed(_ sender: Any) {
		BBAETemplatePanelVC.showWindow (project: project)
	}
	
	@IBAction func btnTemplates (_ sender: Any) {
		BBAETemplateListVC.showWindow (bbaeProject: project)
	}
	
	@IBAction func btnColorsPressed (_ sender: Any) {
		BBAEProjectColorListVC.showWindow (bbaeProject: project)
	}
	
	@IBAction func btnaddItemPressed (_ sender: Any) {
		var lastComp = BBAEProject.getComp (withId: project.lastTemplateId)
		if lastComp == nil {
			lastComp = project.compList.first
		}
		let newRecord = BBAERecord (comp: lastComp)
		project.recordList.append (newRecord)
		project.save ()
		updateLiveData ()
		tblRecordList.scroll (toRow: project.recordList.count - 1)
	}
	
	@IBAction func btnRenderPressed (_ sender: Any) {
		
		guard project.aepFilePresent () else {
			UMAlert.ok (message: "Alert",
						informativeText: "After Effects file (AEP) missing.")
			return
		}
		guard BBAESettings.shared.aeRenderExists () else {
			UMAlert.ok (message: "Alert",
						informativeText: "AERender not present.")
			return

		}
		
		BBAERenderingVC.showSheet (currentController: self)
		project.renderItemsNeedingRender () { success, error in
			if success {
				UMShowNotification (title: "Render",
									informativeText: "Comp(s) rendered with no errors")
			} else {
				if !success {
					UMAlert.ok (message: "After Effects Render Error",
								informativeText: error)
				}
			}
			self.updateLiveData ()
		}
	}
	
	@IBAction func btnRenderFolderPressed (_ sender: Any) {
		UMFileDialogs.chooseFolder (title: "Render Folder",
									message: "Choose Render Folder For Project",
									defaultPath: project.renderFolder_) { url in
			self.project.renderFolder_ = url
		}
	}
	
	@IBAction func btnProjectSettingsPressed (_ sender: Any) {
		if IHKeyModifier.commandIsPressed() {
			project.openAEproject ()
		} else {
			BBAEProjectSettingsVC.showSheet (currentController: self,
											 project: project)
		}
	}
	
	@IBAction func btnShowTpoBeRenderedPressed (_ sender: Any) {
		showToBeRenderedOnly.toggle ()
		self.updateLiveData ()
	}
	
	@IBAction func btnCompactPressed (_ sender: Any) {
		displayMode = displayMode == .normal ? .compact : .normal
		project.setDisplayModeForAllRecord (displayMode)
		project.notifyUpdate ()
	}
	
	
	
	// MARK: - CTX menu Render
	var currentRecord :	BBAERecord?
	
	@IBAction func ctxMenuDontRender (_ sender: Any) {
		guard let currentRecord = currentRecord else { return }
		if currentRecord.status == .rendered || currentRecord.status == .toBeRendered {
			currentRecord.status = .dontRender
		}
		self.currentRecord = nil
		updateLiveData ()
	}
	
	@IBAction func ctxMenuToRender (_ sender: Any) {
		guard let currentRecord = currentRecord else { return }
//		if currentItem.status == .rendered || currentItem.status == .dontRender {
		currentRecord.status = .toBeRendered
//		}
		self.currentRecord = nil
		updateLiveData ()
	}

}


// MARK: - BBAEInstanceCellDelegate
extension BBAEProjectVC :	BBAERecordCellDelegate {

	func updateRecord () {
		project.save ()
		updateLiveData ()
	}
	
	func removeRecord (_ id: String) {
		project.recordList.removeAll { $0.id == id }
		project.save ()
		updateLiveData ()
	}
	
	func displayInstanceCtxMenu (item :				BBAERecord,
								 button sender :	NSButton) {
		currentRecord = item
		if let event = NSApplication.shared.currentEvent {
			NSMenu.popUpContextMenu (mnuCtxRender,
									 with: event,
									 for: sender)
		}
	}
	
	func renderRecord (item: BBAERecord) {
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			BBAERenderingVC.showSheet (currentController: self)
			item.status = .rendering
			project.notifyUpdate ()
			updateLiveData ()
			project.renderRecord (item) { success, error in
				BBAERenderingVC.hide ()
				item.status = success
					? .rendered
					: .toBeRendered
				self.updateLiveData ()
				if !success {
					XMain.execute (after: 0.5) {
						UMAlert.ok (message: "After Effects Render Error",
									informativeText: error)
					}
				}
			}
		}
		self.currentRecord = nil
	}
	
	func renderPlaceholderInstance (item: BBAERecord) {
		Queue.execute { [self] in
			item.status = .rendering
			project.notifyUpdate ()
			updateLiveData ()
			project.renderPlaceholderItem (item) { value in
				item.status = value
					? .rendered
					: .toBeRendered
				self.updateLiveData ()
			}
		}
		self.currentRecord = nil
	}
	
	func duplicateRecord (_ id: String) {
		project.duplicateItem (id)
		project.save ()
		updateLiveData ()
		tblRecordList.scroll (toRow: project.recordList.count - 1)
	}
}


// MARK: - BBAEProjectItemCellDelegate
extension BBAEProjectVC :BBAEProjectItemCellDelegate {

	func removeItem (bbaeItem: BBAERecord) {
		project.recordList = project.recordList.filter { $0.id != bbaeItem.id }
		project.save ()
		updateLiveData ()
	}
	
	func updateItem (bbaeItem: BBAERecord) {
		updateLiveData ()
	}
}


extension BBAEProjectVC :	NSTextDelegate,
							 NSSearchFieldDelegate {
	
	func performSearch () {
		searchText = srcSearch.stringValue
		Queue.execute { [self] in
			searchQueue.perform {
				updateLiveData ()
			}
		}
	}
	
	func textDidChange (_ notification: Notification) {
		performSearch ()
	}
	
	func searchFieldDidStartSearching (_ sender: NSSearchField) {
		performSearch ()
	}
	
	func searchFieldDidEndSearching (_ sender: NSSearchField) {
		performSearch ()
	}
}
