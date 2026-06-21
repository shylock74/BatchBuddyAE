//
//  BBAESettingsVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAESettingsVC :	UMViewController,
						  UMBasicTableVCDelegate {
	
	enum Tab :	String {
		case general =		"General"
		case rendering =	"AE Engine & Rendering"
		case caches	=		"AE Caches"
	}
	
	static let storyboardId = 	"BBAESettingsVC"
	static let storyboardName =	"BBAESettings"
	
	// MARK: - UI Elements
	@IBOutlet weak var tabSettings: UMTabView!
	
	// MARK: - Vars
	var goToTab :	Tab?
	
	private let kNotSet =	"Not Set (will use AE Default)"
	
	// MARK: - Display
	func displayData () {
		tabSettings.addTab (title: Tab.general.rawValue,
							controllerId: BBAESettingsVCGeneral.storyboardId,
							storyboardName: BBAESettingsVC.storyboardName)
		tabSettings.addTab (title: Tab.rendering.rawValue,
							controllerId: BBAESettingsVCRendering.storyboardId,
							storyboardName: BBAESettingsVC.storyboardName)
		tabSettings.addTab (title: Tab.caches.rawValue,
							controllerId: BBAESettingsVCCaches.storyboardId,
							storyboardName: BBAESettingsVC.storyboardName)
		if let goToTab = goToTab {
			tabSettings.goToView (withTitle: goToTab.rawValue)
		}
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
		
	}
	
	override func loaded () {
	}
	
	// MARK: - Show
	static func showWindow (goToTab :	Tab? = nil) {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.BBAESettingsVC",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									windowTitle: "BBAE Settings",
									disableResize: false) { vc in
			guard let vc = vc as? Self else { return }
			vc.goToTab = goToTab
		}
	}
	
	// MARK: - Actions
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
}
