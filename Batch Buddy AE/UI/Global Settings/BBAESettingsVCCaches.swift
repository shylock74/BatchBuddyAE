//
//  BBAESettingsVC-Caches.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 01/12/21.
//


import Cocoa
import UMOmniaFramework

class BBAESettingsVCCaches :	UMViewController,
						UMBasicTableVCDelegate {
	
	static let storyboardId = 	"BBAESettingsVCCaches"
	static let storyboardName =	"BBAESettings"
	
	// MARK: - UI Elements

	@IBOutlet weak var drgCache1: UMAnimDragArea!
	@IBOutlet weak var lblCache1: NSTextField!
	@IBOutlet weak var drgCache2: UMAnimDragArea!
	@IBOutlet weak var lblCache2: NSTextField!
	@IBOutlet weak var drgCache3: UMAnimDragArea!
	@IBOutlet weak var lblCache3: NSTextField!
	
	@IBOutlet weak var imgCacheWarning1: NSImageView!
	@IBOutlet weak var imgCacheWarning2: NSImageView!
	@IBOutlet weak var imgCacheWarning3: NSImageView!
	
	@IBOutlet weak var chkCleanCaches: UMCheckButton!
	
	// MARK: - Vars
	var settings =	BBAESettings.shared
	
	private let kNotSet =	"Not Set (will use AE Default)"
	
	// MARK: - Display
	func displayData () {
		
		let aeCacheUrlList = settings.aeCacheUrlList
		if aeCacheUrlList.count > 0 {
			lblCache1.setValue (aeCacheUrlList [0]?.lastPathComponent ?? "")
			drgCache1.atUrlDrag { urlList in
				self.settings.setCacheUrl (forIndex: 0, url: urlList [0])
				self.displayData ()
			}
			if aeCacheUrlList.count > 1 {
				lblCache2.setValue (aeCacheUrlList [1]?.lastPathComponent ?? "")
				drgCache2.atUrlDrag { urlList in
					self.settings.setCacheUrl (forIndex: 1, url: urlList [1])
					self.displayData ()
				}
				if aeCacheUrlList.count > 2 {
					lblCache3.setValue (aeCacheUrlList [2]?.lastPathComponent ?? "")
					drgCache3.atUrlDrag { urlList in
						self.settings.setCacheUrl (forIndex: 2, url: urlList [2])
						self.displayData ()
					}
				}
			}
			
		}
		chkCleanCaches.setup (initialValue: settings.cleanCachesBeforeRendering) { newValue in
			self.settings.cleanCachesBeforeRendering = newValue
			self.settings.save ()
		}
				
		imgCacheWarning1.isHidden = BBAESettings.shared.cacheExists (0)
		imgCacheWarning2.isHidden = BBAESettings.shared.cacheExists (1)
		imgCacheWarning3.isHidden = BBAESettings.shared.cacheExists (2)
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
//	@IBAction func btnOkPressed (_ sender: Any) {
//		close ()
//	}

	
}
