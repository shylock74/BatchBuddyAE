//
//  BBAESettingsVCRendering.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 01/12/21.
//


import Cocoa
import UMOmniaFramework

class BBAESettingsVCRendering :	UMViewController,
								UMBasicTableVCDelegate {
	
	static let storyboardId = 	"BBAESettingsVCRendering"
	static let storyboardName =	"BBAESettings"
	
	// MARK: - UI Elements
//	@IBOutlet weak var drgRenderEngine: UMAnimDragArea!
//	@IBOutlet weak var lblRenderEngine: NSTextField!
	@IBOutlet weak var btnAERenderEngine: UMRoundedRectButton!
	@IBOutlet weak var popRenderSettings: UMPopUpButton!
	@IBOutlet weak var popOutputModule: UMPopUpButton!
	
	@IBOutlet weak var imgWarningAERender: NSImageView!
	@IBOutlet weak var chkReuseAE: UMCheckButton!
		
	@IBOutlet weak var chkSaveAEProject: UMCheckButton!
	@IBOutlet weak var sldAutoSaveDelay: UMSlider!
	@IBOutlet weak var lblAutoSaveDelay: NSTextField!
	
	// MARK: - Vars
	var settings =	BBAESettings.shared
	
	private let kNotSet =	"Not Set (will use AE Default)"
	
	// MARK: - Display
	func setupRenderSettings () {
		popRenderSettings.clear ()
		settings.aeRenderSettingList!.forEach {
			popRenderSettings.addItem (title: $0.title, value: $0.title)
		}
		popRenderSettings.addSeparator ()
		popRenderSettings.addItem (title: kNotSet, value: kNotSet)
		popRenderSettings.setValueAsString (value: settings.defaultRenderSettings ?? kNotSet)
		popRenderSettings.userSelectedCallback = { [self] value in
			guard let valueS = value as? String else { return }
			settings.defaultRenderSettings = settings.aeRenderSettingList!.first { $0.title == valueS }?.title
			settings.save ()
		}
	}
	
	func setupOutputModule () {
		popOutputModule.clear ()
		settings.aeOutputModuleList!.forEach {
			popOutputModule.addItem (title: $0.title, value: $0.id)
		}
		popOutputModule.addSeparator ()
		popOutputModule.addItem (title: kNotSet, value: "*")
		popOutputModule.setValueAsString (value: settings.defaultOutputSettingsId ?? "*")
		popOutputModule.userSelectedCallback = { [self] value in
			guard let valueS = value as? String else { return }
			settings.defaultOutputSettingsId = settings.aeOutputModuleList!.first { $0.id == valueS }?.id ?? BBAESettings.shared.defaultOutputSettingsId
			settings.save ()
		}
	}
	
	func displayAERenderEngineButton () {
		XMain.execute { [weak self] in
			guard let url = self?.settings.aeRenderEngineUrl else {
				self?.btnAERenderEngine.title = "Select AERender"
				return
			}
			self?.btnAERenderEngine.title = url.parentName + " > AERender"
		}
	}
	
	func displayData () {
		if settings.aeRenderSettingList == nil {
			settings.aeRenderSettingList = []
		}
		if settings.aeOutputModuleList == nil {
			settings.aeOutputModuleList = []
		}
		
//		lblRenderEngine.setValue (settings.aeRenderEngineUrl?.lastPathComponent)
//		drgRenderEngine.atUrlDrag { urlList in
//			self.settings.aeRenderEngineUrl = urlList [0]
//			self.displayData ()
//		}
		displayAERenderEngineButton ()
		setupRenderSettings ()
		setupOutputModule ()
		
		chkReuseAE.setup (initialValue: settings.renderingStuff.reuseAE) { newValue in
			self.settings.renderingStuff.reuseAE = newValue
			self.settings.save ()
		}
		
		chkSaveAEProject.setup (initialValue: settings.renderingStuff.autoSaveurrentDocument) { newValue in
			self.settings.renderingStuff.autoSaveurrentDocument = newValue
			self.settings.save ()
		}
		sldAutoSaveDelay.setup (label: lblAutoSaveDelay,
								defaultValue: settings.renderingStuff.autoSaveDelay) { newValue in
			self.settings.renderingStuff.autoSaveDelay = newValue
			self.settings.save ()
		}
		imgWarningAERender.isHidden = settings.aeRenderExists ()
		
		UMNotify.observe (keyword: AERenderSearcherVC.kNotification) { [weak self] in
			self?.displayAERenderEngineButton ()
		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
		
	}
	
	override func loaded () {
	}
	
	// MARK: - Show
	static func showWindow () {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.BBAESettingsVC",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									windowTitle: "BBAE Settings",
									disableResize: false) { vc in
			guard let vc = vc as? Self else { return }
			
		}
	}
	
	// MARK: - Actions
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
	
	enum EditingList {
		case none
		case render
		case ouput
	}
	var editingList = EditingList.none
	var tableVC :	UMBasicTableVC?
	@IBAction func btnSetupRenderSettingsPressed(_ sender: Any) {
		let textList :	[(String, String)] = settings.aeRenderSettingList?.map {
			($0.id, $0.title)
		} ?? []
		editingList = .render
		BBAERenderOutputListVC.showSheet (currentController: self,
										  show: .render)
	}
	
	@IBAction func btnSetupOutputModulePressed(_ sender: Any) {
		let twoTextsList :	[(String, String, String)] = settings.aeOutputModuleList?.map {
			($0.id, $0.title, $0.fileExtension ?? "")
		} ?? []
		editingList = .ouput
		BBAERenderOutputListVC.showSheet (currentController: self,
										  show: .ouput)
	}
	
	func addRow () {
		guard editingList != .none else { return }
		
		if editingList == .render {
			BBAERenderOutputListVC.showSheet (currentController: self,
											  show: .render)
		} else {
			//			Interface_BasicVCs_TwoTextFieldsVC.showSheet (currentController: tableVC ?? self,
			//														  label0: "Module Name",
			//														  label1: "Extension") { [self] moduleName, fileExtension in
			//				let newItem = BBAESettings.AETemplate (title: moduleName,
			//													   fileExtension: fileExtension)
			//				settings.aeOutputModuleList?.append (newItem)
			//				settings.save ()
			//				displayData ()
			//				tableVC?.displayData ()
			//			}
			BBAERenderOutputListVC.showSheet (currentController: self,
											  show: .ouput)
		}
	}
	
	func removeRow (id: String) {
		guard editingList != .none else { return }
		if self.editingList == .render {
			settings.aeRenderSettingList!  = settings.aeRenderSettingList!.filter { $0.id != id }
		} else {
			settings.aeOutputModuleList!  = settings.aeOutputModuleList!.filter { $0.id != id }
		}
		self.settings.save ()
		self.displayData ()
		tableVC?.displayData ()
	}
	
	@IBAction func btnAERenderEnginePressed (_ sender: Any) {
		AERenderSearcherVC.showWindow ()
	}
	
}
