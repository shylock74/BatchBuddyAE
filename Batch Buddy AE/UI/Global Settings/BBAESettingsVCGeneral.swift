//
//  BBAESettingsVCGeneral.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 01/12/21.
//

import Cocoa
import UMOmniaFramework

class BBAESettingsVCGeneral :	UMViewController,
								UMBasicTableVCDelegate {
	
	static let storyboardId = 	"BBAESettingsVCGeneral"
	static let storyboardName =	"BBAESettings"
	
	// MARK: - UI Elements
	@IBOutlet weak var chkShowLastAtLaunch: UMCheckButton!
	@IBOutlet weak var fldNewLineString: UMTextField!
	@IBOutlet weak var sldPosterFrameAt: UMSlider!
	@IBOutlet weak var lblPosterFrameAt: NSTextField!
	
	// MARK: - Vars
	var settings =	BBAESettings.shared
	
	private let kNotSet =	"Not Set (will use AE Default)"
	
	// MARK: - Display
	func displayData () {
		chkShowLastAtLaunch.setup (initialValue: settings.atLaunch == .openLast) { newValue in
			self.settings.atLaunch = newValue ? .openLast : .showRecents
			self.settings.save ()
		}
		
		fldNewLineString.setup (defaultValue: settings.carriageReturnString) { newValue in
			self.settings.carriageReturnString = newValue
			self.settings.save ()
		}
		
		sldPosterFrameAt.setup (label: lblPosterFrameAt,
								defaultValue: Int (settings.posterFrameAt)) { newValue in
			self.settings.posterFrameAt = Double (newValue)
			self.settings.save ()
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
}
