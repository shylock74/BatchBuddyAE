//
//  BBAETemplateListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 23/04/2021.
//

import Cocoa
import SwiftUI
import UMOmniaFramework
import UMUIControls

class BBAETemplateListVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAETemplateListVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblCompList: UMTableView?
	@IBOutlet weak var fldTemplateName: UMTextField?
	@IBOutlet weak var stckShortNameGroup: NSStackView?
	@IBOutlet weak var fldShortName: UMTextField?
	@IBOutlet weak var tblCompFieldList: UMTableView?
	@IBOutlet var ctxMenuAddItem: NSMenu?
	@IBOutlet weak var imgWarningDuplicate: NSImageView?
	@IBOutlet weak var chkGroupOfTemplates: UMCheckButton?
	@IBOutlet weak var lblNumberOfTemplates: NSTextField?
	
	@IBOutlet weak var chkOverrideRenderFolder: UMCheckButton?
	@IBOutlet weak var lblSameFolderAs: NSTextField?
	@IBOutlet weak var popSameFolderAs: UMPopUpButton?
	
	@IBOutlet weak var cnsTableTrailing: NSLayoutConstraint?

	@IBOutlet weak var btnCustomAERender: UMRoundedRectButton?
	
	// MARK: - Vars
	var project :				BBAEProject!
	@Published var currentSelectedComp :	BBAEComp? =	nil {
		didSet {
			XMain.execute { [weak self] in
				self?.displayData ()
				self?.tblCompFieldList?.reloadDataInMainThread ()
			}
		}
	}
	static var selectedTemplateId :	String? =	nil
	
	private let vcObserverId = UMId.newId (useCounter: false)
	
	@Published var isShortNameDuplicate: Bool = false
	
	var strongScrollViewCompList: NSScrollView?
	var strongScrollViewFieldList: NSScrollView?
	
	// MARK: - Display
	func setupOverrideRenderFolder () {
		let isEnabled = currentSelectedComp?.overrideRenderFolder.override == true
		&& currentSelectedComp?.mediaInFieldList == true
		lblSameFolderAs?.isEnabled = isEnabled
		popSameFolderAs?.isEnabled = isEnabled
		chkOverrideRenderFolder?.setup (initialValue: currentSelectedComp?.overrideRenderFolder.override == true) { [weak self] newValue in
			self?.currentSelectedComp?.overrideRenderFolder.override = newValue
			self?.setupOverrideRenderFolder ()
			self?.project.notifyUpdate ()
		}
		guard isEnabled,
		let currentSelectedComp = currentSelectedComp else { return }
		popSameFolderAs?.clear ()
		for field in currentSelectedComp.mediaFieldList {
			popSameFolderAs?.addItem (title: field.fieldName,
									 value: field.id)
		}
		popSameFolderAs?.addItem (title: "Not Set",
								 value: "")
		popSameFolderAs?.setValueAsString (value: currentSelectedComp.overrideRenderFolder.mediaFieldId)
		if currentSelectedComp.mediaFieldList.count == 1 {
			popSameFolderAs?.setValueAsString (value: currentSelectedComp.mediaFieldList.first!.fieldName)
		}
		popSameFolderAs?.userSelectedCallback = { [weak self] value in
			self?.currentSelectedComp?.overrideRenderFolder.mediaFieldId = value as! String
			self?.project.notifyUpdate ()
		}
	}
	
	func setupTemplateListTable () {
		tblCompList?.rowCount = { self.project.compList.count }
		tblCompList?.cellHeight = { _ in
			24
		}
		tblCompList?.registerCell (cellId: "BBAEProjectTemplateListCellV2")
		
		tblCompList?.cellHandler = { [self] row in
			let template = project.compList [row]
			if let table = tblCompList {
				let cell = BBAEProjectTemplateListCellV2.getCell (table,
																  template: template,
																  delegate: self,
																  selected: template.id == currentSelectedComp?.id)
				return cell
			}
			return nil
		}
		
		tblCompList?.rowSelected = { [self] row in
			currentSelectedComp = row != nil
				? project.compList [row!]
				: nil
		}
		
		tblCompList?.sortCallback = { [self] fromIndex, toIndex in
			project.compList.move (fromOffsets: IndexSet (integer: fromIndex),
								   toOffset: toIndex)
			tblCompList?.reloadDataInMainThread ()
			project.notifyUpdate (andSave: true)
			project.updateValuesAfterStructureChange ()
		}
		
		tblCompList?.reloadData ()
	}
	
	// MARK: - setupTemplateCompFieldListTable
	func setupTemplateCompFieldListTable () {
		tblCompFieldList?.rowCount = { self.currentSelectedComp?.fieldList.count ?? 0 }
		
		tblCompFieldList?.cellHeight = { row in
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
		
		tblCompFieldList?.cellHandler =  { [self] row in
			guard let currentSelectedTemplate = currentSelectedComp else {
				return nil
			}
			if let table = tblCompFieldList {
				let cell = BBAETemplateStructureCell.getCell (table,
															  compField: currentSelectedTemplate.fieldList [row],
															  comp: currentSelectedTemplate,
															  project: project,
															  delegate: self)
				return cell
			}
			return nil
		}
		
		tblCompFieldList?.sortCallback = { [self] fromIndex, toIndex in
			guard let currentSelectedComp = currentSelectedComp else {return}
			currentSelectedComp.fieldList.move (fromOffsets: IndexSet (arrayLiteral: fromIndex),
												toOffset: toIndex)
			tblCompFieldList?.reloadDataInMainThread ()
			project.updateValuesAfterStructureChange ()
			project.notifyUpdate (andSave: true)
		}
	}
	
	func setupCheckGroup () {
		chkGroupOfTemplates?.setup (initialValue: currentSelectedComp?.isGroup ?? false) { [weak self] newValue in
			self?.currentSelectedComp?.isGroup = newValue
			self?.setupNumberOfTemplatesLabel ()
			self?.project.notifyUpdate ()
		}
	}
	
	func setupNumberOfTemplatesLabel () {
		if currentSelectedComp?.isGroup == true {
			lblNumberOfTemplates?.stringValue = "\(currentSelectedComp!.compGroupList!.count) Templates"
			stckShortNameGroup?.isHidden = true
		} else {
			lblNumberOfTemplates?.stringValue = ""
			stckShortNameGroup?.isHidden = false
		}
	}
	
	func setupBtnCustomAERender () {
		XMain.execute { [self] in
			btnCustomAERender?.title = "Custom AE Project" + (currentSelectedComp?.customAEProjectUrl != nil ? " YES" : "")
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
			fldTemplateName?.setValue (currentSelectedTemplate.name)
			fldShortName?.setValue (currentSelectedTemplate.shortName)
			fldTemplateName?.isHidden = false
			fldShortName?.isHidden = false
		} else {
			fldTemplateName?.setValue ("")
			fldShortName?.setValue ("")
			fldTemplateName?.isHidden = true
			fldShortName?.isHidden = true
		}
		
		idleTimer.loop (interval: 0.5) { [self] in
			if BBAETemplateListVC.selectedTemplateId != nil {
				guard let selectedTemplate = (project.compList.first { $0.id == BBAETemplateListVC.selectedTemplateId! }) else { return }
				BBAETemplateListVC.selectedTemplateId = nil
				currentSelectedComp = selectedTemplate
				tblCompList?.reloadDataInMainThread ()
				project.lastTemplateId = currentSelectedComp?.id
			}
			checkDuplicateShortName ()
		}
		
		setupBtnCustomAERender ()
	}
	
	func update () {
		tblCompList?.reloadDataInMainThread ()
		tblCompFieldList?.reloadDataInMainThread ()
		setupBtnCustomAERender ()
	}
	
	func setupObservers () {
		project.observeUpdate (observerId: vcObserverId) { [weak self] in
			self?.update ()
		}
	}
	
	// MARK: - View Cycle
	override func viewDidLoad () {
		super.viewDidLoad ()
		
		// Capture and retain the scroll views of the table views
		self.strongScrollViewCompList = tblCompList?.enclosingScrollView
		self.strongScrollViewFieldList = tblCompFieldList?.enclosingScrollView
		
		// Remove all existing subviews loaded from the storyboard to prevent overlapping!
		self.view.subviews.forEach { subview in
			if subview != strongScrollViewCompList && subview != strongScrollViewFieldList {
				subview.removeFromSuperview ()
			}
		}
		
		// Seamlessly embed the modern SwiftUI View inside NSHostingView
		let hostingView = NSHostingView (rootView: BBAETemplateListView (vc: self))
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		
		self.view.addSubview (hostingView)
		
		NSLayoutConstraint.activate ([
			hostingView.leadingAnchor.constraint (equalTo: self.view.leadingAnchor),
			hostingView.trailingAnchor.constraint (equalTo: self.view.trailingAnchor),
			hostingView.topAnchor.constraint (equalTo: self.view.topAnchor),
			hostingView.bottomAnchor.constraint (equalTo: self.view.bottomAnchor)
		])
	}

	override func willAppear () {
		displayData ()
		setupObservers ()
		setupTemplateListTable ()
		tblCompList?.reloadData ()
		
		tblCompList?.addRoundedBackground (color: NSColor (deviceWhite: 0.15, alpha: 1))
		tblCompFieldList?.addRoundedBackground (color: NSColor (deviceWhite: 0.15, alpha: 1))
	}
	
	override func loaded () {
		if let table = tblCompFieldList {
			BBAETemplateStructureCell.registerCells (table)
		}
	}
	
	// MARK: - Idle
	func checkDuplicateShortName () {
		XMain.execute { [self] in
			imgWarningDuplicate?.isHidden = true
			if let currentSelectedComp = currentSelectedComp {
				for template in project.compList {
					if template.id != currentSelectedComp.id,
					   template.shortName.lowercased () == fldShortName?.stringValue.lowercased () {
						imgWarningDuplicate?.isHidden = false
					}
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
		currentSelectedComp?.name = fldTemplateName?.stringValue ?? ""
		tblCompList?.reloadDataInMainThread ()
		project.save ()
		project.notifyUpdate ()
	}
	
	@IBAction func fldShortNameChanged (_ sender: Any) {
		currentSelectedComp?.shortName_ = fldShortName?.stringValue ?? ""
		project.save ()
		project.notifyUpdate ()
	}
	
	@IBAction func btAddTemplate (_ sender: Any) {
		let newTemplate = BBAEComp (name: "Untitled")
		project.compList.append (newTemplate)
		project.save ()
		project.notifyUpdate ()
		tblCompList?.reloadDataInMainThread ()
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
			tblCompFieldList?.reloadDataInMainThread ()
			Queue.execute (after: 0.75) { [self] in
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
		if let event = NSApplication.shared.currentEvent, let menu = ctxMenuAddItem {
			NSMenu.popUpContextMenu (menu,
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
		tblCompFieldList?.reloadDataInMainThread ()
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
		tblCompFieldList?.reloadDataInMainThread ()
	}
}

// MARK: - SwiftUI Views
struct BBAETemplateListView : View {
	@ObservedObject var vc: BBAETemplateListVC
	
	var body: some View {
		VStack(spacing: 0) {
			HSplitView {
				// Master Pane (Left Column)
				BBAETemplateListMasterPane(vc: vc)
					.frame(minWidth: 220, maxWidth: 300)
				
				// Detail Pane (Right Column)
				BBAETemplateListDetailPane(vc: vc)
					.frame(minWidth: 440)
			}
			.padding(.bottom, 8)
			
			Divider()
			
			// Bottom Bar (Cancel / OK)
			HStack {
				Spacer()
				UMUICapsuleButton("Cancel", style: .gray, size: .small) {
					vc.btnCancelPressed(vc)
				}
				UMUICapsuleButton("OK", style: .accent, size: .small) {
					vc.btnOkPressed(vc)
				}
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(Color.mildDarkGray)
		}
		.background(Color.darkGray)
	}
}

struct BBAETemplateListMasterPane: View {
	@ObservedObject var vc: BBAETemplateListVC
	
	var body: some View {
		VStack(spacing: 8) {
			// Title/Header
			Text("Compositions")
				.font(.system(size: 12, weight: .bold))
				.foregroundColor(.secondary)
				.left(nil)
				.padding(.horizontal, 12)
				.padding(.top, 8)
			
			// Template List Table View
			if let scrollView = vc.strongScrollViewCompList {
				TableViewContainer(scrollView: scrollView)
			} else {
				Color.clear
			}
			
			// Master Toolbar
			HStack(spacing: 8) {
				UMUICapsuleButton("Add", systemImage: "plus", style: .gray, size: .small) {
					vc.btAddTemplate(vc)
				}
				.fixedSize(horizontal: true, vertical: false)
				
				UMUICapsuleButton("Import", systemImage: "square.and.arrow.down", style: .gray, size: .small) {
					vc.btnImportCompTemplatePressed(vc)
				}
				.fixedSize(horizontal: true, vertical: false)
				
				Spacer()
			}
			.padding(.horizontal, 12)
			.padding(.bottom, 8)
		}
	}
}

struct BBAETemplateListDetailPane: View {
	@ObservedObject var vc: BBAETemplateListVC
	
	var body: some View {
		VStack(spacing: 0) {
			if let comp = vc.currentSelectedComp {
				ScrollView {
					VStack(spacing: 12) {
						// Header Card (Grouped Settings)
						VStack(spacing: 10) {
							HStack(spacing: 10) {
								UMUITextField(
									label: "Name",
									placeholder: "Template Name",
									value: Binding(
										get: { comp.name },
										set: { newValue in
											comp.name = newValue
											vc.tblCompList?.reloadDataInMainThread()
											vc.project.save()
											vc.project.notifyUpdate()
										}
									)
								)
								
								HStack(spacing: 4) {
									UMUITextField(
										label: "Short Name",
										placeholder: "Short Name",
										value: Binding(
											get: { comp.shortName },
											set: { newValue in
												comp.shortName_ = newValue
												vc.project.save()
												vc.project.notifyUpdate()
												vc.checkDuplicateShortName()
											}
										)
									)
									
									if vc.isShortNameDuplicate {
										Image(systemName: "exclamationmark.triangle.fill")
											.foregroundColor(.yellow)
											.help("Duplicate short name warning")
									}
								}
							}
							
							HStack {
								UMUIMiniSwitch(
									"Group of Templates",
									isOn: Binding(
										get: { comp.isGroup },
										set: { newValue in
											comp.isGroup = newValue
											vc.setupNumberOfTemplatesLabel()
											vc.project.notifyUpdate()
										}
									)
								)
								
								if comp.isGroup {
									Spacer()
									Text("\(comp.compGroupList?.count ?? 0) templates in group")
										.font(.system(size: 11, weight: .semibold))
										.foregroundColor(.secondary)
									
									UMUICapsuleButton("Group List", systemImage: "list.bullet.indent", style: .gray, size: .small) {
										vc.btnTemplateGroupListPressed(vc)
									}
									.fixedSize(horizontal: true, vertical: false)
								}
							}
							
							// Override Render Folder
							if comp.mediaInFieldList {
								Divider()
								HStack {
									UMUIMiniSwitch(
										"Override Render Folder",
										isOn: Binding(
											get: { comp.overrideRenderFolder.override },
											set: { newValue in
												comp.overrideRenderFolder.override = newValue
												vc.project.notifyUpdate()
											}
										)
									)
									
									if comp.overrideRenderFolder.override {
										Spacer()
										Text("Same folder as:")
											.font(.system(size: 11))
											.foregroundColor(.secondary)
										Picker("", selection: Binding(
											get: { comp.overrideRenderFolder.mediaFieldId },
											set: { newValue in
												comp.overrideRenderFolder.mediaFieldId = newValue
												vc.project.notifyUpdate()
											}
										)) {
											ForEach(comp.mediaFieldList, id: \.id) { field in
												Text(field.fieldName).tag(field.id)
											}
											Text("Not Set").tag("")
										}
										.pickerStyle(MenuPickerStyle())
										.frame(width: 140)
									}
								}
							}
							
							Divider()
							
							HStack {
								UMUICapsuleButton(
									"Custom AE Project" + (comp.customAEProjectUrl != nil ? " (YES)" : ""),
									style: comp.customAEProjectUrl != nil ? .accent : .gray,
									size: .small
								) {
									vc.btncustomAERenderPressed(vc)
								}
								.fixedSize(horizontal: true, vertical: false)
								Spacer()
							}
						}
						.padding(12)
						.background(UMUIBoxView(cornerRadius: 8, borderWidth: 1, foreColor: .mildDarkGray))
						.padding(.horizontal, 16)
						.padding(.top, 12)
						
						// Fields List Title
						HStack {
							Text("Template Fields & Variables")
								.font(.system(size: 12, weight: .bold))
								.foregroundColor(.secondary)
							Spacer()
						}
						.padding(.horizontal, 16)
						
						// Fields List Scroll View
						if let scrollView = vc.strongScrollViewFieldList {
							TableViewContainer(scrollView: scrollView)
								.frame(height: 260)
								.padding(.horizontal, 16)
						}
						
						// Fields Action Toolbar
						HStack(spacing: 8) {
							// Native SwiftUI Menu for Adding Fields
							Menu {
								Button("Text") { vc.addItem(tag: 0) }
								Button("Long Text") { vc.addItem(tag: 7) }
								Button("Checkbox") { vc.addItem(tag: 8) }
								Button("Color Fill") { vc.addItem(tag: 3) }
								Button("Numeric Value") { vc.addItem(tag: 5) }
								Button("Image") { vc.addItem(tag: 1) }
								Button("Video") { vc.addItem(tag: 2) }
								Button("Audio") { vc.addItem(tag: 4) }
								Button("Vector (AI)") { vc.addItem(tag: 6) }
								Button("Record ID") { vc.addItem(tag: 9) }
							} label: {
								HStack(spacing: 4) {
									Image(systemName: "plus")
									Text("Add Field")
								}
							}
							.fixedSize(horizontal: true, vertical: false)
							
							UMUICapsuleButton("Settings", systemImage: "gearshape", style: .gray, size: .small) {
								vc.btnTemplateSettingsPressed(vc)
							}
							.fixedSize(horizontal: true, vertical: false)
							
							UMUICapsuleButton("Export", systemImage: "square.and.arrow.up", style: .gray, size: .small) {
								vc.btnExportCompTemplatePressed(vc)
							}
							.fixedSize(horizontal: true, vertical: false)
							
							Spacer()
						}
						.padding(.horizontal, 16)
						.padding(.bottom, 12)
					}
				}
			} else {
				VStack {
					Spacer()
					Image(systemName: "doc.text.magnifyingglass")
						.font(.system(size: 40))
						.foregroundColor(.secondary)
					UMUIVSpacer(8)
					Text("Select a Template to Edit")
						.font(.system(size: 13, weight: .semibold))
						.foregroundColor(.secondary)
					Spacer()
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
	}
}
