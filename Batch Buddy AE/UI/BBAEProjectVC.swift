//
//  BBAEProjectVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import SwiftUI
import UMOmniaFramework
import UMUIControls

class BBAEProjectVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAEProjectVC"
	
	// MARK: - Legacy IBOutlets (retained for storyboard compatibility)
	@IBOutlet weak var srcSearch: UMSearchField?
	@IBOutlet weak var popTemplateList: UMPopUpButton?
	@IBOutlet weak var btnShowToRender: NSButton?
	@IBOutlet weak var chkRenderAll: UMCheckButton?
	@IBOutlet weak var lblItemsCount: NSTextField?
	@IBOutlet weak var lblStatus: NSTextField?
	@IBOutlet var mnuCtxRender: NSMenu!
	
	// MARK: - Vars
	var project :		BBAEProject!
	@Published var searchText :	String =	""
	@Published var searchComp =	"*"
	var searchQueue =	UMPressureTask ()
	var isNew :			Bool!
	
	private let vcObserverId = UMId.newId (useCounter: false)
	
	@Published var displayMode :	BBAERecord.DisplayMode =	.normal
	
	static var currentProject :	BBAEProject?
	
	@UMDef (key: "firstLaunch", def: true) var firstlaunch

	@Published var showToBeRenderedOnly =	false
	@Published var itemsCountText: String = ""
	@Published var statusText: String = ""
	@Published var renderAll: Bool = false
	
	/// Bumped to force `BBAERecordListView` to re-render (e.g. after add/remove).
	@Published var listRefreshId = UUID()
	
	// MARK: - Record Store Cache
	/// Caches `BBAERecordObservable` per record ID so observers survive list refreshes.
	private var storeCache: [String: BBAERecordObservable] = [:]
	
	func storeFor(record: BBAERecord) -> BBAERecordObservable {
		if let existing = storeCache[record.id] {
			return existing
		}
		let store = BBAERecordObservable(record: record, project: project)
		storeCache[record.id] = store
		return store
	}
	
	private func pruneStoreCache() {
		let activeIds = Set(project.recordList.map { $0.id })
		storeCache = storeCache.filter { activeIds.contains($0.key) }
	}
	
	// MARK: - Filter
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
	func populateTemplate () {
		popTemplateList?.clear ()
		popTemplateList?.addItem (title: "All Comp Templates",
								 value: "*")
		popTemplateList?.addSeparator ()
		if let compList = project?.compList {
			for template in compList {
				popTemplateList?.addItem (title: template.name,
										value: template.id)
			}
		}
		popTemplateList?.setValueAsString (value: "*")
		popTemplateList?.userSelectedCallback = { [weak self] value in
			guard let valueS = value as? String else { return }
			self?.searchComp = valueS
			self?.performSearch ()
		}
	}
	
	func displatItemsCount () {
		let countText = "Items: \(self.itemFoundList ().count)/\(project.recordList.count) (\((project.recordList.filter { $0.status == .toBeRendered }).count ) to be rendered)"
		XMain.execute { [weak self] in
			self?.itemsCountText = countText
		}
		lblItemsCount?.setValue (countText)
	}
	
	func setupSearch () {
		srcSearch?.searchTextChanged = { text in
			self.searchText = text
			self.performSearch ()
		}
	}
	
	func displayData () {
		XMain.execute { [self] in
			setupSearch ()
			
			chkRenderAll?.setup (initialValue: false) { value in
				self.itemFoundList ().forEach {
					$0.status = value ? .toBeRendered : .rendered
				}
				self.updateLiveData ()
			}
			displatItemsCount ()
			
			populateTemplate ()
			srcSearch?.delegate = self
			
			self.statusText = ""
			lblStatus?.setValue ("")
		}
	}
	
	func updateLiveData () {
		pruneStoreCache()
		XMain.execute { [weak self] in
			self?.listRefreshId = UUID()
			self?.displatItemsCount()
		}
	}
	
	// MARK: - Observer
	func setupObservers () {
		project.observeUpdate (observerId: vcObserverId) { [weak self] in
			self?.updateLiveData ()
			self?.displayData ()
		}
		UMNotify.observeString (keyword: project.statusUpdateKey) { [weak self] status in
			XMain.execute {
				self?.statusText = status ?? ""
			}
			self?.lblStatus?.setValue (status)
		}
	}
	
	// MARK: - View Cycle
	override func viewDidLoad () {
		super.viewDidLoad ()
		
		// Remove all storyboard subviews and install the SwiftUI hosting view
		self.view.subviews.forEach { $0.removeFromSuperview() }
		
		let hostingView = NSHostingView (rootView: BBAEProjectView (vc: self))
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
		if isNew {
			isNew = false
			BBAEProjectSettingsVC.showSheet (currentController: self,
											project: project)
		}
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
//			BBAESettingsVC.showWindow (goToTab: .rendering)
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
		updateLiveData ()
	}
	
	// MARK: - Record CRUD (called from SwiftUI cells)
	
	func removeRecordFromList(_ id: String) {
		project.recordList.removeAll { $0.id == id }
		storeCache.removeValue(forKey: id)
		project.save()
		updateLiveData()
	}
	
	func duplicateRecordInList(_ id: String) {
		project.duplicateItem(id)
		project.save()
		updateLiveData()
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
		currentRecord.status = .toBeRendered
		self.currentRecord = nil
		updateLiveData ()
	}

}


extension BBAEProjectVC :	NSTextDelegate,
							NSSearchFieldDelegate {
	
	func performSearch () {
		if let src = srcSearch {
			searchText = src.stringValue
		}
		Queue.execute { [self] in
			searchQueue.perform {
				self.updateLiveData ()
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

// MARK: - SwiftUI Root View
struct BBAEProjectView : View {
	@ObservedObject var vc: BBAEProjectVC
	
	var body: some View {
		VStack(spacing: 0) {
			BBAEProjectHeaderView(vc: vc)
			
			BBAERecordListView(vc: vc)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			
			BBAEProjectFooterView(vc: vc)
		}
		.background(Color(nsColor: NSColor(deviceWhite: 0.13, alpha: 1)))
	}
}

// MARK: - Header View
struct BBAEProjectHeaderView: View {
	@ObservedObject var vc: BBAEProjectVC
	
	var body: some View {
		HStack(spacing: 10) {
			// Search Input
			UMUITextField(
				placeholder: "Search...",
				value: Binding(
					get: { vc.searchText },
					set: { newValue in
						vc.searchText = newValue
						vc.performSearch()
					}
				),
				size: .small
			)
			.frame(width: 140)
			
			// Templates Filter Picker
			Picker("", selection: Binding(
				get: { vc.searchComp },
				set: { newValue in
					vc.searchComp = newValue
					vc.performSearch()
				}
			)) {
				Text("All Comp Templates").tag("*")
				ForEach(vc.project.compList, id: \.id) { comp in
					Text(comp.name).tag(comp.id)
				}
			}
			.pickerStyle(MenuPickerStyle())
			.frame(width: 140)
			
			// Pending Only Toggle Button
			UMUICapsuleButton(
				style: vc.showToBeRenderedOnly ? .accent : .gray,
				size: .small,
				action: {
					vc.showToBeRenderedOnly.toggle()
					vc.updateLiveData()
				}
			) {
				HStack(spacing: 4) {
					if let nsImg = Draw.getImage(vc.showToBeRenderedOnly ? "Icon_Render_00001" : "Icon_Render_00000") {
						Image(nsImage: nsImg)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 12, height: 12)
					}
					Text("Pending Only")
						.font(.system(size: 11))
						.lineLimit(1)
				}
			}
			.fixedSize(horizontal: true, vertical: false)
			
			// Compact Mode Toggle Button
			UMUICapsuleButton(
				vc.displayMode == .normal ? "Compact View" : "Normal View",
				systemImage: vc.displayMode == .normal ? "square.dashed.inset.filled" : "list.bullet.rectangle",
				style: .gray,
				size: .small,
				action: {
					vc.btnCompactPressed(vc)
				}
			)
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Templates", systemImage: "doc.text", style: .gray, size: .small) {
				vc.btnTemplates(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Template Panel", systemImage: "rectangle.3.group", style: .gray, size: .small) {
				vc.btnTemplatePanelPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			Spacer()
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(Color.mildDarkGray)
	}
}

// MARK: - Footer View
struct BBAEProjectFooterView: View {
	@ObservedObject var vc: BBAEProjectVC
	
	var body: some View {
		HStack(spacing: 8) {
			// Switch for Render All
			UMUIMiniSwitch(
				"Render All",
				isOn: Binding(
					get: { vc.renderAll },
					set: { newValue in
						vc.renderAll = newValue
						vc.itemFoundList().forEach {
							$0.status = newValue ? .toBeRendered : .rendered
						}
						vc.updateLiveData()
					}
				)
			)
			.fixedSize(horizontal: true, vertical: false)
			
			UMUIHSpacer(8)
			
			// Items count text
			Text(vc.itemsCountText)
				.font(.system(size: 11, weight: .medium, design: .rounded))
				.foregroundColor(.secondary)
				.lineLimit(1)
				.fixedSize(horizontal: true, vertical: false)
			
			// Status messages
			if !vc.statusText.isEmpty {
				Text(vc.statusText)
					.font(.system(size: 11, design: .monospaced))
					.foregroundColor(.accentColor)
					.padding(.horizontal, 8)
					.padding(.vertical, 2)
					.background(Color.accentColor.opacity(0.15))
					.cornerRadius(4)
					.lineLimit(1)
					.fixedSize(horizontal: true, vertical: false)
			}
			
			Spacer()
			
			UMUICapsuleButton("Add Item", systemImage: "plus", style: .gray, size: .small) {
				vc.btnaddItemPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Colors", systemImage: "paintpalette", style: .gray, size: .small) {
				vc.btnColorsPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Render Folder", systemImage: "folder", style: .gray, size: .small) {
				vc.btnRenderFolderPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Project Settings", systemImage: "gearshape", style: .gray, size: .small) {
				vc.btnProjectSettingsPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
			
			UMUICapsuleButton("Render Comps", systemImage: "play.fill", style: .accent, size: .small) {
				vc.btnRenderPressed(vc)
			}
			.fixedSize(horizontal: true, vertical: false)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 6)
		.background(Color.mildDarkGray)
	}
}
