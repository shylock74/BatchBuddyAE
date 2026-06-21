//
//  BBAETemplateListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 23/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAETemplateListVC :	UMViewController {
	
	static let storyboardId = 	"BBAETemplateListVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblCompList: UMTableView!
	@IBOutlet weak var fldTemplateName: UMTextField!
	@IBOutlet weak var stckShortNameGroup: NSStackView!
	@IBOutlet weak var fldShortName: UMTextField!
	@IBOutlet weak var tblCompFieldList: UMTableView!
	@IBOutlet var ctxMenuAddItem: NSMenu!
	@IBOutlet weak var imgWarningDuplicate: NSImageView!
	@IBOutlet weak var chkGroupOfTemplates: UMCheckButton!
	@IBOutlet weak var lblNumberOfTemplates: NSTextField!
	
	@IBOutlet weak var chkOverrideRenderFolder: UMCheckButton!
	@IBOutlet weak var lblSameFolderAs: NSTextField!
	@IBOutlet weak var popSameFolderAs: UMPopUpButton!
	
	@IBOutlet weak var cnsTableTrailing: NSLayoutConstraint!

	@IBOutlet weak var btnCustomAERender: UMRoundedRectButton!
	
	// MARK: - Vars
	var project :				BBAEProject!
	var currentSelectedComp :	BBAEComp? {
		didSet {
			XMain.execute { [weak self] in
				self?.displayData ()
				self?.tblCompFieldList.reloadDataInMainThread ()
			}
		}
	}
	static var selectedTemplateId :	String? =	nil
	
	private let vcObserverId = UMId.newId (useCounter: false)
	
	// MARK: - Display
	func setupOverrideRenderFolder () {
		let isEnabled = currentSelectedComp?.overrideRenderFolder.override == true
		&& currentSelectedComp?.mediaInFieldList == true
		lblSameFolderAs.isEnabled = isEnabled
		popSameFolderAs.isEnabled = isEnabled
		chkOverrideRenderFolder.setup (initialValue: currentSelectedComp?.overrideRenderFolder.override == true) { [weak self] newValue in
			self?.currentSelectedComp?.overrideRenderFolder.override = newValue
			self?.setupOverrideRenderFolder ()
			self?.project.notifyUpdate ()
		}
		guard isEnabled,
		let currentSelectedComp = currentSelectedComp else { return }
		popSameFolderAs.clear ()
		for field in currentSelectedComp.mediaFieldList {
			popSameFolderAs.addItem (title: field.fieldName,
									 value: field.id)
		}
		popSameFolderAs.addItem (title: "Not Set",
								 value: "")
		popSameFolderAs.setValueAsString (value: currentSelectedComp.overrideRenderFolder.mediaFieldId)
		if currentSelectedComp.mediaFieldList.count == 1 {
			popSameFolderAs.setValueAsString (value: currentSelectedComp.mediaFieldList.first!.fieldName)
		}
		popSameFolderAs.userSelectedCallback = { [weak self] value in
			self?.currentSelectedComp?.overrideRenderFolder.mediaFieldId = value as! String
			self?.project.notifyUpdate ()
		}
	}
	
	func setupTemplateListTable () {
		tblCompList.rowCount = { self.project.compList.count }
		tblCompList.cellHeight = { _ in
			24
		}
		tblCompList.registerCell (cellId: "BBAEProjectTemplateListCellV2")
		
		tblCompList.cellHandler = { [self] row in
			let template = project.compList [row]
//			let selectedRow = tblTemplateList.selectedRow
			let cell = BBAEProjectTemplateListCellV2.getCell (tblCompList,
															  template: template,
															  delegate: self,
															  selected: template.id == currentSelectedComp?.id)
			return cell
		}
		
		tblCompList.rowSelected = { [self] row in
			currentSelectedComp = row != nil
				? project.compList [row!]
				: nil
		}
		
//		tblCompList.dragKey = "media.ulti.bbae.\(BBAETemplateListVC.storyboardId).compList"
		tblCompList.sortCallback = { [self] fromIndex, toIndex in
			project.compList.move (fromOffsets: IndexSet (integer: fromIndex),
								   toOffset: toIndex)
			tblCompList.reloadDataInMainThread ()
			project.notifyUpdate (andSave: true)
			project.updateValuesAfterStructureChange ()
		}
		
		tblCompList.reloadData ()
	}
	
	// MARK: - setupTemplateCompFieldListTable
	func setupTemplateCompFieldListTable () {
		tblCompFieldList.rowCount = { self.currentSelectedComp?.fieldList.count ?? 0 }
		
		tblCompFieldList.cellHeight = { row in
			guard let currentSelectedTemplate = self.currentSelectedComp else { return 0 }
			switch currentSelectedTemplate.fieldList [row].type {
				case .text, .checkBox:
					return 50
				case .colorFill:
					return 50
				case .image:
					return 104
				case .video:
					return 104
				case .audio:
					return 104
				case .vectorAI:
					return 104
				case .longText:
					return 50
				case .recordId:
					return 28
				case .numericValue:
					return 108
			}
		}
		
		tblCompFieldList.cellHandler =  { [self] row in
			guard let currentSelectedTemplate = currentSelectedComp else {
				return nil
			}
			let cell = BBAETemplateStructureCell.getCell (tblCompFieldList,
														  compField: currentSelectedTemplate.fieldList [row],
														  comp: currentSelectedTemplate,
														  project: project,
														  delegate: self)
			return cell
		}
		
		tblCompFieldList.sortCallback = { [self] fromIndex, toIndex in
			guard let currentSelectedComp = currentSelectedComp else {return}
			currentSelectedComp.fieldList.move (fromOffsets: IndexSet (arrayLiteral: fromIndex),
												toOffset: toIndex)
			tblCompFieldList.reloadDataInMainThread ()
			project.updateValuesAfterStructureChange ()
			project.notifyUpdate (andSave: true)
		}
	}
	
	func setupCheckGroup () {
		chkGroupOfTemplates.setup (initialValue: currentSelectedComp?.isGroup ?? false) { [weak self] newValue in
			self?.currentSelectedComp?.isGroup = newValue
			self?.setupNumberOfTemplatesLabel ()
			self?.project.notifyUpdate ()
		}
	}
	
	func setupNumberOfTemplatesLabel () {
		if currentSelectedComp?.isGroup == true {
			lblNumberOfTemplates.stringValue = "\(currentSelectedComp!.compGroupList!.count) Templates"
			stckShortNameGroup.isHidden = true
		} else {
			lblNumberOfTemplates.stringValue = ""
			stckShortNameGroup.isHidden = false
		}
	}
	
	func setupBtnCustomAERender () {
		XMain.execute { [self] in
			btnCustomAERender.title = "Custom AE Project" + (currentSelectedComp?.customAEProjectUrl != nil ? " YES" : "")
		}
	}
	
	// MARK: - displayData
	func displayData () {
		setupCheckGroup ()
		setupNumberOfTemplatesLabel ()
		setupTemplateCompFieldListTable ()
		setupOverrideRenderFolder ()
		
		checkDuplicateShortName ()
		if currentSelectedComp == nil && project.compList.first != nil {
			currentSelectedComp = project.compList.first
			setupCheckGroup ()
		}
		if let currentSelectedTemplate = currentSelectedComp {
			fldTemplateName.setValue (currentSelectedTemplate.name)
			fldShortName.setValue (currentSelectedTemplate.shortName)
			fldTemplateName.isHidden = false
			fldShortName.isHidden = false
		} else {
			fldTemplateName.setValue ("")
			fldShortName.setValue ("")
			fldTemplateName.isHidden = true
			fldShortName.isHidden = true
		}
		
		idleTimer.loop (interval: 0.5) { [self] in
			if BBAETemplateListVC.selectedTemplateId != nil {
				guard let selectedTemplate = (project.compList.first { $0.id == BBAETemplateListVC.selectedTemplateId! }) else { return }
				BBAETemplateListVC.selectedTemplateId = nil
				currentSelectedComp = selectedTemplate
				tblCompList.reloadDataInMainThread ()
				project.lastTemplateId = currentSelectedComp?.id
			}
			checkDuplicateShortName ()
		}
		
		setupBtnCustomAERender ()
	}
	
	func update () {
		tblCompList.reloadDataInMainThread ()
		tblCompFieldList.reloadDataInMainThread ()
		setupBtnCustomAERender ()
	}
	
	func setupObservers () {
		project.observeUpdate (observerId: vcObserverId) { [weak self] in
			self?.update ()
		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
		setupObservers ()
		setupTemplateListTable ()
		tblCompList.reloadData ()
		
		if #available(OSX 11.0, *) {
//			cnsTableLeading.constant = -20
//			cnsTableTrailing.constant = 0
		}
		tblCompList.addRoundedBackground (color: NSColor (deviceWhite: 0.15, alpha: 1))
		tblCompFieldList.addRoundedBackground (color: NSColor (deviceWhite: 0.15, alpha: 1))
	}
	
	override func loaded () {
		BBAETemplateStructureCell.registerCells (tblCompFieldList)
	}
	
	// MARK: - Idle
	func checkDuplicateShortName () {
		XMain.execute { [self] in
			imgWarningDuplicate.isHidden = true
			for template in project.compList {
				if template.id != currentSelectedComp?.id,
				   template.shortName.lowercased () == fldShortName.stringValue.lowercased () {
					imgWarningDuplicate.isHidden = false
				}
			}
		}
	}
			
	// MARK: - Show
	static func showWindow (bbaeProject :			BBAEProject,
							selectedTemplateId :	String? =	nil) {
		BBAETemplateListVC.selectedTemplateId = selectedTemplateId
		UMWindowsGroup.shared.show (id: "media.ulti.bbaetemplatelistvc.\(bbaeProject.id)",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									bundle: nil,
									windowTitle: "\(bbaeProject.name) Template List",
									minWidth: 780,
									maxWidth: 780,
									minHeight: 540,
									maxHeight: nil) { vc in
			guard let vc = vc as? Self else { return }
			vc.project = bbaeProject
		}
	}
	
	override func disappeared () {
		UMWindowsGroup.shared.didClose (id: "media.ulti.bbaetemplatelistvc.\(project.id)")
		UMDispatch.remove (key: "media.ulti.bbae.projectUpdate.\(project.id)", myId: vcObserverId)
	}
	
	// MARK: - Actions
	@IBAction func btnTemplateGroupListPressed(_ sender: Any) {
		guard let currentSelectedTemplate = currentSelectedComp else { return }
		BBAETemplateGroupListVC.showSheet (currentController: self,
										   project: project,
										   template: currentSelectedTemplate)
	}
	
	@IBAction func fldTemplateNameChanged (_ sender: Any) {
		currentSelectedComp?.name = fldTemplateName.stringValue
		tblCompList.reloadDataInMainThread ()
		project.save ()
		project.notifyUpdate ()
	}
	
	@IBAction func fldShortNameChanged (_ sender: Any) {
		currentSelectedComp?.shortName_ = fldShortName.stringValue
		project.save ()
		project.notifyUpdate ()
	}
	
	@IBAction func btAddTemplate (_ sender: Any) {
		let newTemplate = BBAEComp (name: "Untitled")
		project.compList.append (newTemplate)
		project.save ()
		project.notifyUpdate ()
		tblCompList.reloadDataInMainThread ()
		currentSelectedComp = newTemplate
		setupCheckGroup ()
	}
	
	func addItem (tag :	Int) {
		let type :	BBAECompField.FieldType
		switch tag {
			case 0: 	type = .text
			case 1: 	type = .image
			case 2: 	type = .video
			case 3: 	type = .colorFill
			case 4: 	type = .audio
			case 5: 	type = .numericValue
			case 6: 	type = .vectorAI
			case 7:		type = .longText
			case 8:		type = .checkBox
			case 9:		type = .recordId
		default:	return
		}
		guard let currentSelectedTemplate = currentSelectedComp else { return }
		currentSelectedTemplate.objectOrder = currentSelectedTemplate.objectOrder != nil ? currentSelectedTemplate.objectOrder! + 1 : 1
		let newField = BBAECompField (type: type,
									 order: currentSelectedTemplate.objectOrder!)
		BBAECompField.addFieldToGlobalList (newField)
		currentSelectedTemplate.addField (newField)
		XMain.execute (after: 0.25) { [self] in
			tblCompFieldList.reloadDataInMainThread ()
			Queue.execute (after: 0.75) {
				project.updateValuesAfterStructureChange ()
				project.notifyUpdate ()
			}
		}
	}
	
	func newItem (tag :	Int) {
		if view.window?.isKeyWindow == true {
			addItem (tag: tag)
		}
	}
	
	@IBAction func btAddITem (_ sender: NSButton) {
		if let event = NSApplication.shared.currentEvent {
			NSMenu.popUpContextMenu (ctxMenuAddItem,
									 with: event,
									 for: sender)
		}
	}

	@IBAction func ctxMenuAddItemSelected (_ sender: NSMenuItem) {
		PerfAn.start (#function)
		defer {
			PerfAn.end ()
		}

		addItem (tag: sender.tag)
	}
	
	
	@IBAction func btnTemplateSettingsPressed (_ sender: Any) {
		guard let template = currentSelectedComp else { return }
		BBAECompSettingsVC.showSheet (currentController: self,
										  template: template,
										  project: project)
	}
	
	@IBAction func btnExportCompTemplatePressed (_ sender: Any) {
		guard let currentSelectedComp = currentSelectedComp else { return }
		UMFileDialogs.save (title: "Save Template Comp",
							availableExtensions: ["bbtemplate"]) { url in
			guard let url = url else { return }
			currentSelectedComp.export (toUrl: url)
		}
	}
	
	@IBAction func btnImportCompTemplatePressed (_ sender: Any) {
		UMFileDialogs.open (title: "Import Template Comp",
							message: "Select",
							availableExtensions: ["bbtemplate"]) { [weak self] url in
			self?.project.importCompTemplate (url)
		}
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
//		ACTION
		close ()
	}
	
	@IBAction func btnCancelPressed(_ sender: Any) {
		close ()
	}
	
	@IBAction func btncustomAERenderPressed(_ sender: Any) {
		guard let currentSelectedComp else { return }
		BBAECompCustomAERenderVC.showSheet (currentController: self,
											  project: project,
											  comp: currentSelectedComp)
	}
	
}


// MARK: - BBAEProjectTemplateListCellDelegate
extension BBAETemplateListVC :	BBAEProjectTemplateListCellDelegate {
	
	func removeTemplate (bbaeTemplate: BBAEComp) {
		project.compList = project.compList.filter { $0.id != bbaeTemplate.id }
		project.updateValuesAfterStructureChange ()
		project.notifyUpdate ()
		tblCompFieldList.reloadDataInMainThread ()
		currentSelectedComp = nil
		setupCheckGroup ()
		update ()
	}
	
	func updateTemplate (bbaeTemplate: BBAEComp) {
		project.updateValuesAfterStructureChange ()
		project.notifyUpdate ()
		update ()
	}
	
	func duplicateTemplate (bbaeTemplate: BBAEComp) {
		project.duplicateTemplate (bbaeTemplate)
		project.updateValuesAfterStructureChange ()
		project.notifyUpdate ()
		update ()
	}
	
	
}


// MARK: - BBAETemplateStructureCellDelegate
extension BBAETemplateListVC :	BBAETemplateStructureCellDelegate {
	
	func updateTemplate () {
		project.notifyUpdate ()
	}
	
	func removeTemplateItem (_ id: String) {
		BBAECompField.removeFieldFromGlobalList (withId: id)
		currentSelectedComp?.fieldList = currentSelectedComp!.fieldList.filter { $0.id != id }
		project.updateValuesAfterStructureChange ()
		project.notifyUpdate ()
		tblCompFieldList.reloadDataInMainThread ()
	}
}
