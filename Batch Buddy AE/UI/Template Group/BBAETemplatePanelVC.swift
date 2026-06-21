//
//  BBAETemplatePanel.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 29/07/2021.
//

import Cocoa
import UMOmniaFramework

class BBAETemplatePanelVC :	UMViewController {
	
	static let storyboardId = 	"BBAETemplatePanelVC"
	static let storyboardName =	"BBAETemplatePanel"
	
	// MARK: - UI Elements
	@IBOutlet weak var popTemplate: UMPopUpButton!
	@IBOutlet weak var srcSearch: UMSearchField!
	@IBOutlet weak var tblList: UMTableView!
	@IBOutlet weak var lblPlaceholderLabel: NSTextField!
	
	var labels :	[NSTextField] =	[]
	
	// MARK: - Vars
	var project :	BBAEProject!

	var searchText :		String =	""
	var searchTemplate =	"*"
	var searchQueue =		UMPressureTask ()

	var selectedComp :	BBAEComp? {
		project.compList.first { $0.id == searchTemplate }
	}
	
	func itemFoundList () -> [BBAERecord] {
		let itemInstanceListFilteredByTemplate = searchTemplate == "*"
			? project.recordList
			: project.recordList.filter { $0.compId == searchTemplate }
		
		if searchText == "" {
			return itemInstanceListFilteredByTemplate
		}
		let searchTextLowercased = searchText.lowercased ()
		return itemInstanceListFilteredByTemplate.filter { $0.umSearchContains (searchTextLowercased) }
	}
	
	// MARK: - Display
	func populateTemplate () {
		popTemplate.clear ()
		for template in project.compList {
			popTemplate.addItem (title: template.name,
									 value: template.id)
		}
		popTemplate.setValueAsString (value: project.compList.first?.id ?? "*")
		popTemplate.userSelectedCallback = { [weak self] value in
			guard let valueS = value as? String else { return }
			self?.searchTemplate = valueS
			self?.performSearch ()
		}
	}
	
	func populateLabels () {
		XMain.execute { [weak self] in
			guard let self = self else { return }
			self.labels.forEach { $0.removeFromSuperview () }
			self.labels = []
			guard let template = (self.project.compList.first { $0.id == self.searchTemplate }) else { return }
			var x : CGFloat = 8 + BBAETemplatePanelRow.buttonWidth + BBAETemplatePanelRow.fieldSeparation
			var w :	CGFloat = 0
			for item in template.fieldList {
				let label = NSTextField (labelWithString: item.fieldName)
				switch item.type {
					
					case .text:
						w = BBAETemplatePanelRow.textFieldWidth
									case .longText:
										w = BBAETemplatePanelRow.longTextFieldWidth
					//				case .colorFill:
					//					<#code#>
					case .image,
						 .video,
						 .audio,
						 .vectorAI:
						w = BBAETemplatePanelRow.urlFieldWidth
					case .numericValue:
						w = BBAETemplatePanelRow.numericFieldWidth
					default: break
				}
				let f = CGRect (origin: CGPoint (x: self.lblPlaceholderLabel.frame.origin.x + x,
												 y: self.lblPlaceholderLabel.frame.origin.y),
								size: CGSize (width: w,
											  height: self.lblPlaceholderLabel.frame.height))
				label.frame = f
				label.textColor =  NSColor (cgColor: self.foreColor)
				label.font = NSFont.systemFont (ofSize: 10)
				self.view.addSubview (label)
				self.labels.append (label)
				x += w + BBAETemplatePanelRow.fieldSeparation
				UMConstraints.alignBottoms (label, self.lblPlaceholderLabel)
			}
		}
	}
	
	func setupSearch () {
		searchTemplate = project.compList.first?.id ?? "*"
		srcSearch.searchTextChanged = { text in
			self.searchText = text
			self.performSearch ()
		}
	}
	
	func setWindowTitle () {
		guard let template = selectedComp else {
			windowTitle = "Template"
			return
		}
		windowTitle = template.name
	}
	
	func displayData () {
		lblPlaceholderLabel.isHidden = true
		setupSearch ()
		populateTemplate ()
		setWindowTitle ()
	}
	
	// MARK: - Observer
	func setupObservers () {
		project.observeUpdate { [weak self] in
			self?.updateLiveData ()
		}
//		UMNotify.observeString (keyword: project.statusUpdateKey) { [weak self] status in
//			self?.lblStatus.setValue (status)
//		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		setupTable ()
		displayData ()
		populateLabels ()
		tblList.reloadData ()
		setupObservers ()
	}
	
	func registerTableCells () {
		BBAETemplatePanelRow.register (tblList)
	}
	
	func updateLiveData () {
		populateLabels ()
		tblList.reloadDataInMainThread ()
		setWindowTitle ()
	}
	
	func setupTable () {
		tblList.rowCount = {
			self.itemFoundList ().count
		}
		tblList.registerCell (cellId: "BBAETemplatePanelRow")
		tblList.cellHandler = { [self] row in
			BBAETemplatePanelRow.getCell (tblList,
										  instance: itemFoundList () [row],
										  project: project,
										  delegate: self)
		}
		tblList.cellHeight = { [self] row in
			28
		}
	}
	
//	override func loaded () {
//		setupTableList ()
//	}
	
	
	// MARK: - Show
	static func showWindow (project :	BBAEProject) {
//		if let uniqueId = uniqueId {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.templatePanel.\(project.id)",
										viewControllerId: Self.storyboardId,
										storyboardName: Self.storyboardName,
										bundle: nil,
										windowTitle: "Template Panel",
										disableResize: false) { vc in
				guard let vc = vc as? Self else { return }
				vc.project = project
			}
	}
	
	// MARK: - Actions
//	@IBAction func btnOkPressed (_ sender: Any) {
//		ACTION
//		close ()
//	}
//
//	@IBAction func btnCancelPressed(_ sender: Any) {
//		close ()
//	}
	
	@IBAction func btnaddItemPressed (_ sender: Any) {
		guard let comp = selectedComp else { return }
		let newItem = BBAERecord (comp: comp)
		project.recordList.append (newItem)
		project.save ()
		updateLiveData ()
		tblList.scroll (toRow: project.recordList.count - 1)
	}
}



extension BBAETemplatePanelVC :	UMBasicTableVCDelegate {
	
}


// MARK: - BBAEProjectItemCellDelegate
extension BBAETemplatePanelVC :	BBAEProjectItemCellDelegate {
	
	func removeItem (bbaeItem: BBAERecord) {
		project.recordList = project.recordList.filter { $0.id != bbaeItem.id }
		project.save ()
//		updateLiveData ()
	}
	
	func updateItem (bbaeItem: BBAERecord) {
//		updateLiveData ()
	}
}


// MARK: - BBAEInstanceCellDelegate
extension BBAETemplatePanelVC :BBAERecordCellDelegate {
	
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
//		currentItem = item
//		if let event = NSApplication.shared.currentEvent {
//			NSMenu.popUpContextMenu (mnuCtxRender,
//									 with: event,
//									 for: sender)
//		}
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
			item.status = .rendering
			project.notifyUpdate ()
			updateLiveData ()
			project.renderRecord (item) { success, error in
				item.status = success
					? .rendered
					: .toBeRendered
				self.updateLiveData ()
				UMAlert.ok (message: "After Effects Render Error",
							informativeText: error)
			}
		}
//		self.currentItem = nil
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
//		self.currentItem = nil
	}
	
	func duplicateRecord (_ id: String) {
		project.duplicateItem (id)
		project.save ()
		updateLiveData ()
		tblList.scroll (toRow: project.recordList.count - 1)
	}
}


extension BBAETemplatePanelVC :	NSTextDelegate,
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
	
	//	override func controlTextDidChange (notification: NSNotification) {
	//		performSearch ()
	//	}
	
	func searchFieldDidEndSearching (_ sender: NSSearchField) {
		performSearch ()
	}
}
