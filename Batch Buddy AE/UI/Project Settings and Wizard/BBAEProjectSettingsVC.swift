//
//  BBAEProjectSettingsVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 11/09/21.
//

import Cocoa
import UMOmniaFramework

class BBAEProjectSettingsVC :	UMViewController {
	
	static let storyboardId = 	"BBAEProjectSettingsVC"
	static let storyboardName =	"BBAEProjectSettings"
	
	// MARK: - UI Elements
	@IBOutlet weak var fldProjectName: UMTextField!
	@IBOutlet weak var drgDragArea: UMAnimDragArea!
	@IBOutlet weak var lblAEPFileName: NSTextField!
	@IBOutlet weak var imgAEPFileMissingWarning: NSImageView!
	@IBOutlet weak var btnRenderFolder: UMRoundedRectButton!
	@IBOutlet weak var chkRenderInSubfolder: UMCheckButton!
	@IBOutlet weak var chkUseCompFullName: UMCheckButton!
	@IBOutlet weak var fldGlobalPrefix: UMTextField!
	@IBOutlet weak var fldGlobalMidfix: UMTextField!
	@IBOutlet weak var fldGlobalSuffix: UMTextField!

	@IBOutlet weak var lblDragHereAERender: NSTextField!
	@IBOutlet weak var drgAERenderDragArea: UMAnimDragArea!
	@IBOutlet weak var chkUseRosetta: UMCheckButton!
	
	// MARK: - Vars
	var project :	BBAEProject!
	
	// MARK: - Display
	func setupProjectMissingWarning () {
		imgAEPFileMissingWarning.isHidden = project.aepFilePresent ()
	}
	
	func setupAEPName () {
		lblAEPFileName.stringValue = project.aeProjectFileUrl?.lastPathComponent ?? "Drag Here AEP Project File"
	}
	
	func setupDragArea () {
		drgDragArea.setup ()
		drgDragArea.atUrlDrag { [weak self] urlList in
			self?.project.aeProjectFileUrl = urlList [0]
			self?.project.save ()
			self?.project.notifyUpdate ()
			self?.displayData ()
		}
	}
	
	func setupAERenderDragArea () {
		drgAERenderDragArea.setup ()
		drgAERenderDragArea.atUrlDrag { [weak self] urlList in
			guard let url = urlList.first,
			url.name == "aerender" else { return }
			self?.project.customAERenderUrl = url
			self?.project.save ()
			self?.project.notifyUpdate ()
			self?.displayData ()
		}
		setupAERenderLabel ()
		chkUseRosetta.setup (initialValue: project.customAEUseRosetta) { [weak self] newValue in
			self?.project.customAEUseRosetta = newValue
			self?.project.save ()
		}
	}
	
	func setupAERenderLabel () {
		lblDragHereAERender.setValue (project.customAERenderUrl?.parentName ?? "Drag Here AERender App")
	}
	
	func setupProjectFoldername () {
		btnRenderFolder.title =
			project.renderFolder_ == fu_getDocumentsFolderURL ().append ("_BBAE Render")
			? "Documents Folder"
			: project.renderFolder_.lastPathComponent
	}
	
	func setupCheck () {
		chkRenderInSubfolder.setup (initialValue: project.renderInSubfolders) { [weak self] newValue in
			self?.project.renderInSubfolders = newValue
			self?.project.save ()
		}
		chkUseCompFullName.setup (initialValue: project.useFullCompNameForSubfolder) { [weak self] newValue in
			self?.project.useFullCompNameForSubfolder = newValue
			self?.project.save ()
		}
	}
	
	func setupNamingFields () {
		fldGlobalPrefix.setup (defaultValue: project.naming.globalPrefix,
							   notifyOnlyAtEditingEnd: true) { [weak self] newValue in
			self?.project.naming.globalPrefix = newValue
			self?.project.save ()
		}
		fldGlobalMidfix.setup (defaultValue: project.naming.globalMidfix,
							   notifyOnlyAtEditingEnd: true) { [weak self] newValue in
			self?.project.naming.globalMidfix = newValue
			self?.project.save ()
		}
		fldGlobalSuffix.setup (defaultValue: project.naming.globalSuffix,
							   notifyOnlyAtEditingEnd: true) { [weak self] newValue in
			self?.project.naming.globalSuffix = newValue
			self?.project.save ()
		}
	}
	
	func displayData () {
		fldProjectName.setup (defaultValue: project.name) { newName in
			self.project.name = newName
			self.project.save ()
		}
		setupProjectMissingWarning ()
		setupDragArea ()
		setupAERenderDragArea ()
		setupAEPName ()
		setupProjectFoldername ()
		setupCheck ()
		setupNamingFields ()
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   project :			BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.project = project
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
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
	
	@IBAction func btnSelectFolderPressed(_ sender: Any) {
		UMFileDialogs.chooseFolder (title: "Render Folder",
									message: "Choose Render Folder For Project",
									defaultPath: project.renderFolder_) { [weak self] url in
			self?.project.renderFolder_ = url
			self?.setupProjectFoldername ()
		}
	}
	
	@IBAction func btnOpenProjectInAEPressed (_ sender: Any) {
		guard let url = project.aeProjectFileUrl else { return }
		fu_openFileWithItsApp (url)
	}
	
	@IBAction func btnRevealInFinderpressed(_ sender: Any) {
		guard let url = project.aeProjectFileUrl else { return }
		fu_showInFinder (url)
	}
	
	@IBAction func btnRemoveAllRecordsPressed(_ sender: Any) {
		UMAlert.twoButtons (message: "Warning",
							informativeText: "Do you really want to remove ALL records?",
							button0Txt: "No, Cancel",
							button1Txt: "Yes, Continue and Delete ALL Records",
							button1Completion: { [weak self] in
			self?.project.deleteAllRecords ()
		})
	}
	
	@IBAction func btnClearAERenderPressed(_ sender: Any) {
		project.customAERenderUrl = nil
		project.save ()
		setupAERenderLabel ()
	}
	 
}
