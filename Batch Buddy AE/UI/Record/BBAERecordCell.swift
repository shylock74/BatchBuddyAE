//
//  BBAEInstanceCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAERecordCellDelegate {
	func updateRecord ()
	func removeRecord (_ id : String)
	func displayInstanceCtxMenu (item :		BBAERecord,
								 button :	NSButton)
	func renderRecord (item :	BBAERecord)
	func renderPlaceholderInstance (item :	BBAERecord)
	func duplicateRecord (_ id : String)
}


class BBAERecordCell :	UMTableCell {
	
	static let cellId = "BBAERecordCell"
	
	// MARK: - UI
	@IBOutlet weak var popTemplate: UMPopUpButton!
	@IBOutlet weak var tblTemplateItems: UMTableView!
	@IBOutlet weak var lblOutputModule: NSTextField!
	@IBOutlet weak var chkRender: UMCheckButton!
	@IBOutlet weak var btnRender: NSButton!
	@IBOutlet weak var scrScrollView: NSScrollView!
	
	@IBOutlet weak var cnsTableLeading: NSLayoutConstraint!
	
	// MARK: - var
	var record :			BBAERecord!
	var project :			BBAEProject!
	var delegate : 			BBAERecordCellDelegate!
	var fatherController :	NSViewController!
	
	private let cellObserverId = UMId.newId (useCounter: false)
	private var observedKeys = [String] ()
	
	func cleanPreviousObservers () {
		for key in observedKeys {
			UMDispatch.remove (key: key, myId: cellObserverId)
		}
		observedKeys.removeAll ()
	}
	
	override func prepareForReuse () {
		super.prepareForReuse ()
		cleanPreviousObservers ()
	}
	
	var comp :	BBAEComp? {
		project.getComp (withId: record.compId)
	}

	// MARK: - Display
	func displayRenderButton () {
		XMain.execute { [weak self] in
			guard let bbaeItem = self?.record else { return }
			switch bbaeItem.status {
				case .toBeRendered:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00001")
				case .dontRender:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00000")
				case .rendering:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00002")
				case .rendered:
					self?.btnRender.image = Draw.getImage ("Icon_Render (0-00-00-00)")
			}
		}
	}
	
	// MARK: - changeCompId
	func changeCompId (to newId :	String?) {
		let previousItemInstance = record.duplicate ()
		record.compId = newId
		
		for fieldValue in record.recordFieldValueList {
			if let fieldName = fieldValue.templateItem ()?.fieldName {
				if let originalInstance = previousItemInstance.recordFieldValueList.first (where: { $0.templateItem ()?.fieldName == fieldName }) {
					fieldValue.textContent = originalInstance.textContent
					fieldValue.url = originalInstance.url
					fieldValue.valueContent = originalInstance.valueContent
				}
			}
		}
	}
	
	// MARK: - populateTemplate
	func populateTemplate () {
		popTemplate.clear ()
		popTemplate.addItem (title: "Not Set",
							 value: "*")
		popTemplate.addSeparator ()
		for template in project.compList {
			popTemplate.addItem (title: template.name,
								 value: template.id)
		}
		popTemplate.setValueAsString (value: record.compId ?? "*")
		popTemplate.userSelectedCallback = { [weak self] value in
			guard let s = self else { return }
			guard let valueS = value as? String else { return }
			let newId = valueS == "*"
				? nil
				: valueS
			if newId != s.record.compId {
				s.changeCompId (to: newId)
				self?.project.lastTemplateId = newId
			}
			self?.delegate.updateRecord ()
			self?.displayOuputModule ()
			self?.setupObserver ()
		}
	}
	
	// MARK: - rowModified
	func rowModified () {
		record.prepareConfigurationFile (url: project.aeProjectFileUrl,
										 iteration: nil,
										 project: project)
		record.status = .toBeRendered
		project.save ()
		project.notifyUpdate ()
	}
	
	// MARK: - templateItemCell
	func templateItemCell (_ row :	Int) -> UMTableCell? {

		guard let template = comp else {
			print ("!")
			return nil
		}
		guard row < template.fieldList.count,
			  row < record.recordFieldValueList.count else {
			print ("!")
			return nil
		}
		let field = template.fieldList [row]
		switch field.type {
			
			case .recordId:
				return BBAEInstanceRecordIdRow.getCell (tblTemplateItems,
														recordFieldValue:  record.recordFieldValueList [row],
														record: record,
														rowModifiedCallback: rowModified)
			case .text:
				if record.recordFieldValueList [row].showAsLargeText {
					return BBAEInstanceLongTextRow.getCell (tblTemplateItems,
															recordFieldValue: record.recordFieldValueList [row],
															rowModifiedCallback: rowModified)
				} else {
					return BBAEInstanceTextRow.getCell (tblTemplateItems,
														recordFieldValue: record.recordFieldValueList [row],
														rowModifiedCallback: rowModified)
				}
				
			case .numericValue:
				switch field.numericFieldSettings.appearance {
					case .field:
						return BBAEInstanceNumberRow.getCell (tblTemplateItems,
															  recordFieldValue: record.recordFieldValueList [row],
															  rowModifiedCallback: rowModified)
					case .slider:
						return BBAEInstanceNumberSliderRow.getCell (tblTemplateItems,
																	recordFieldValue: record.recordFieldValueList [row],
																	rowModifiedCallback: rowModified)
						
					case .stepper:
						return BBAEInstanceNumberStepperRow.getCell (tblTemplateItems,
																	 recordFieldValue: record.recordFieldValueList [row],
																	 rowModifiedCallback: rowModified)
				}
				
			case .image:
				return BBAEInstanceImageVideoRow.getCell (tblTemplateItems,
														  recordFieldValue: record.recordFieldValueList [row],
														  record: record,
														  project: project,
														  rowModifiedCallback: rowModified)
				
			case .video:
				return BBAEInstanceImageVideoRow.getCell (tblTemplateItems,
														  recordFieldValue: record.recordFieldValueList [row],
														  record: record,
														  project: project,
														  rowModifiedCallback: rowModified)
				
			case .audio:
				return BBAEInstanceImageVideoRow.getCell (tblTemplateItems,
														  recordFieldValue: record.recordFieldValueList [row],
														  record: record,
														  project: project,
														  rowModifiedCallback: rowModified)
				
			case .vectorAI:
				return BBAEInstanceImageVideoRow.getCell (tblTemplateItems,
														  recordFieldValue: record.recordFieldValueList [row],
														  record: record,
														  project: project,
														  rowModifiedCallback: rowModified)
				
			case .longText:
				if record.recordFieldValueList [row].showAsLargeText {
					return BBAEInstanceLongTextRow.getCell (tblTemplateItems,
															recordFieldValue: record.recordFieldValueList [row],
															rowModifiedCallback: rowModified)
				} else {
					return BBAEInstanceTextRow.getCell (tblTemplateItems,
														recordFieldValue: record.recordFieldValueList [row],
														rowModifiedCallback: rowModified)
				}
				
			case .colorFill:
				return BBAEInstanceColorRow.getCell (tblTemplateItems,
													 project: project,
													 recordFieldValue: record.recordFieldValueList [row],
													 rowModifiedCallback: rowModified)
			case .checkBox:
				return BBAEInstanceCheckboxRow.getCell (tblTemplateItems,
														recordFieldValue: record.recordFieldValueList [row],
														rowModifiedCallback: rowModified)
		}
	}
	
	func cellHeight (_ row :	Int) -> CGFloat {
		guard let templateItem = comp?.fieldList [row] else { return 0 }
		switch templateItem.type {
			case .numericValue, .checkBox, .recordId:
				return 24
			case .text:
				return record.recordFieldValueList [row].showAsLargeText ? 96 : 24
			case .colorFill:
				return 24
			case .image, .vectorAI:
				return 80
			case .video:
				return 80
			case .audio:
				return 80
			case .longText:
				return record.recordFieldValueList [row].showAsLargeText ? 96 : 24
		}
	}
	
	func setupTable () {

		tblTemplateItems.registerCell (cellId: "BBAEInstanceTextRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceRecordIdRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceLongTextRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceImageVideoRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceNumberRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceNumberSliderRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceNumberStepperRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceColorRow")
		tblTemplateItems.registerCell (cellId: "BBAEInstanceCheckboxRow")
		tblTemplateItems.rowCount = {
			self.comp?.fieldList.count ?? 0
		}
		tblTemplateItems.cellHandler = templateItemCell
		tblTemplateItems.cellHeight = cellHeight
	}
	
	// MARK: - displayOuputModule
	func displayOuputModule () {
		guard let template = record.comp else {
			lblOutputModule.setValue ("")
			return
		}
		if template.isGroup == true {
			let t = template.compGroupList?.count ?? 0
			let nActive = template.compGroupList?.filter { $0.active }.count ?? 0
			lblOutputModule.setValue ("Group (\(t) templates, \(nActive) active)")
		} else {
			lblOutputModule.setValue (template.outputModule () ?? "")
		}
	}
	
	func fillData () {
	
	}
	
	func updateData () {
		XMain.execute { [self] in
			populateTemplate ()
			displayRenderButton ()
			displayOuputModule ()
		}
	}
	
	// MARK: - setupObserver
	func setupObserver () {
		cleanPreviousObservers ()
		
		guard let project = project else { return }
		
		let projectKey = "media.ulti.bbae.projectUpdate.\(project.id)"
		UMDispatch.observe (key: projectKey, myId: cellObserverId) { [weak self] in
			self?.updateData ()
			self?.tblTemplateItems.reloadDataInMainThread ()
		}
		observedKeys.append (projectKey)
		
		if let comp = comp {
			let compKey = "\(comp.subscribableType).\(comp.id)"
			UMDispatch.observe (key: compKey, myId: cellObserverId) { [weak self] in
				self?.updateData ()
				self?.tblTemplateItems.reloadDataInMainThread ()
			}
			observedKeys.append (compKey)
		}
	}
	
	func setupCheck () {
		chkRender.setup (initialValue: record.status == .toBeRendered ? true : false) { newValue in
			self.record.status = newValue ? .toBeRendered : .dontRender
			self.displayRenderButton ()
		}
	}
	
	func displayData () {
		setupTable ()
		updateData ()
		setupCheck ()
		tblTemplateItems.reloadDataInMainThread ()
		setupObserver ()
		
		if #available (OSX 11.0, *) {
			cnsTableLeading.constant = -16
//			cnsTableTrailing.constant = 0
		}
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  	NSTableView,
						 record :			BBAERecord,
						 project :			BBAEProject,
						 fatherController :	NSViewController,
						 delegate :			BBAERecordCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.record = record
		cell.delegate = delegate
		cell.project = project
		cell.fatherController = fatherController
		cell.displayData ()
		cell.setBackground ()
		return cell
	}
	
	// MARK: - Actions
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeRecord (record.id)
	}
	
	@IBAction func btnDuplicatePressed (_ sender: Any) {
		delegate.duplicateRecord (record.id)
	}

	@IBAction func btnRenderStatusPressed (_ sender: Any) {
		delegate.displayInstanceCtxMenu (item: record,
										 button: sender as! NSButton)
	}
	
	@IBAction func btnGoToTemplatePressed(_ sender: Any) {
		BBAETemplateListVC.showWindow (bbaeProject: project,
									   selectedTemplateId: record.compId)
	}
	
	@IBAction func btnRenderImmediatelyPressed (_ sender: Any) {
		guard project.aepFilePresent () else {
			UMAlert.ok (message: "Alert",
						informativeText: "After Effects file (AEP) missing.")
			return
		}
		guard let comp = project.getComp (withId: record.compId) else {
			UMAlert.ok (message: "Alert",
						informativeText: "No Comp with this Id")
			return
		}
		guard BBAESettings.shared.aeRenderExists () else {
			UMAlert.ok (message: "Alert",
						informativeText: "AERender not present.")
			return
			
		}
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			project.renderedCount = 0
			if comp.isGroup == true {
				project.toBeRenderedCount = comp.compGroupList?.filter { $0.active }.count ?? 0
			} else {
				project.toBeRenderedCount = 1
			}
			delegate.renderRecord (item: record)
		}
	}
	
	@IBAction func btnToggleCompact (_ sender: Any) {
		record.displayMode = .compact
		project.notifyUpdate ()
	}
	
	@IBAction func btnSaveToDiskPressed (_ sender: Any) {
		UMProgressVC_Type0.show (currentController: fatherController,
								 imgProgressPrefix: "BBAE_Progress_",
								 status: "Saving Data...")
		Queue.execute { [weak self] in
			guard let s = self,
			let comp = s.comp else { return }
			s.record.prepareFiles (inProject: s.project,
								   comp: comp)
			UMProgressVC_Type0.hide ()
		}
	}
	
	@IBAction func btnGoTorenderFolderPressed (_ sender: Any) {
		let renderFileUrl = project.renderFileUrl (record,
												   templateGroup: nil,
												   fileExtension: "")
		fu_showInFinder (renderFileUrl.parent)
	}
	
}
