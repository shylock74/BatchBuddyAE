//
//  BBAETemplateNewItemChooserVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 27/04/2021.
//

import Cocoa
import UMOmniaFramework

class BBAETemplateNewItemChooserVC :	UMViewController {
	
	static let storyboardId = 	"BBAETemplateNewItemChooserVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
//	@IBOutlet weak var tblList: NSTableView!
	
	// MARK: - Vars
	var callback :	((BBAECompField.FieldType) -> ())!
	
	// MARK: - Display
	func displayData () {
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
		
	override func loaded () {
	}
	
	// MARK: - Show
	static func showPopover (currentController :	NSViewController,
							 originView :			NSView,
							 callback :				@escaping (BBAECompField.FieldType) -> ()) {
		UMWindows.popover (Self.storyboardId,
							   Self.storyboardName,
							   currentViewController: currentController,
							   originView: originView,
							   disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.callback = callback
		}
	}
	
	// MARK: - Actions
	@IBAction func btnSelectorPressed (_ sender: UMRoundedRectButton) {
		close ()
		switch sender.tag {
			case 0: 	callback (.text)
			case 1: 	callback (.image)
			case 2: 	callback (.video)
			case 3: 	callback (.colorFill)
			default:	break
		}
	}
	
	
}
