//
//  BBAETemplateSettingsVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 10/05/2021.
//

import Cocoa
import UMOmniaFramework

class BBAECompSettingsVC :	UMViewController {
	
	static let storyboardId = 	"BBAECompSettingsVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
	@IBOutlet weak var lblTemplateSettings: NSTextField!
	@IBOutlet weak var popRenderSettings: UMPopUpButton!
	@IBOutlet weak var popOutputModule: UMPopUpButton!
	@IBOutlet weak var chkRenderSingleFrame: UMCheckButton!
	@IBOutlet weak var fldFrameToRender: UMTextField!
	
	// MARK: - Vars
	var comp :				BBAEComp!
	var project :			BBAEProject!
	var settings =			BBAESettings.shared
	var atCloseCallback :	((BBAEComp) -> ())?
	
	// MARK: - Display
//	func setupRenderSettings () {
//		popRenderSettings.clear ()
//		popRenderSettings.addItem (title: "Not Set", value: "*")
//		popRenderSettings.addSeparator ()
//		settings.aeRenderSettingList?.forEach {
//			popRenderSettings.addItem (title: $0.title, value: $0.id)
//		}
//		popRenderSettings.setValueAsString (value: template.defaultRenderSettingId ?? "*")
//		popRenderSettings.userSelectedCallback = { [self] value in
//			guard let valueS = value as? String else { return }
//			template.defaultRenderSettingId = valueS
//		}
	//	}
	private let kNotSet =	"Not Set (will use AE Default)"

	func setupRenderSettings () {
	popRenderSettings.clear ()
	settings.aeRenderSettingList!.forEach {
	popRenderSettings.addItem (title: $0.title, value: $0.title)
	}
	popRenderSettings.addSeparator ()
	popRenderSettings.addItem (title: kNotSet, value: kNotSet)
	popRenderSettings.setValueAsString (value: comp.defaultRenderSettingId ?? kNotSet)
	popRenderSettings.userSelectedCallback = { [self] value in
	guard let valueS = value as? String else { return }
		comp.defaultRenderSettingId = valueS
		project.save ()
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
		popOutputModule.setValueAsString (value: comp.defaultOutputModuleId ?? "*")
		popOutputModule.userSelectedCallback = { [self] value in
			guard let valueS = value as? String else { return }
			comp.defaultOutputModuleId = valueS
			project.save ()
			settings.save ()
		}
	}
	
	func setupRenderSingleFrame () {
		chkRenderSingleFrame.setup (initialValue: comp.renderSingleFrame ?? false) {
			self.comp.renderSingleFrame = $0
		}
		fldFrameToRender.setup (defaultValue: String (comp.frameToRender ?? 0)) {
			self.comp.frameToRender = Int ($0)
		}
	}
	
	func displayData () {
		lblTemplateSettings.stringValue = "Template \(comp.name) Settings:"
		setupRenderSettings ()
		setupOutputModule ()
		setupRenderSingleFrame ()
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	override func loaded () {
		//		setupTableList ()
	}
	
	override func willDisppear () {
		atCloseCallback? (comp)
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   template :			BBAEComp,
						   project :			BBAEProject,
						   atCloseCallback :	((BBAEComp) -> ())? = nil) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.comp = template
			vc.project = project
			vc.atCloseCallback = atCloseCallback
		}
	}
	
	//	static func showWindow (template :	BBAETemplate) {
	//		//		if let uniqueId = uniqueId {
	//		UMWindowsGroup.shared.show (id: template.id,
	//									viewControllerId: Self.storyboardId,
	//									storyboardName: Self.storyboardName,
	//									bubdle: nil,
	//									windowTitle: "WINDOW TITLE",
	//									disableResize: false) { vc in
	//			guard let vc = vc as? Self else { return }
	//			vc.PARAM = PARAM
	//		}
	//		} else {
	//			_ = UMWindows.instantiateWindowAndController (viewControllerId: Self.storyboardId,
	//														  storyboardName: Self.storyboardName,
	//														  bundle: nil,
	//														  windowTitle: "WINDOW TITLE",
	//														  resizable: true) { vc in
	//				guard let vc = vc as? Self else { return }
	//				vc.PARAM = PARAM
	//			}
	//		}
	//}
	
	// MARK: - Actions
	@IBAction func btnOkPressed (_ sender: Any) {
		project.save ()
		close ()
	}
	
	//	@IBAction func btnCancelPressed(_ sender: Any) {
	//		close ()
	//	}
}
