//
//  BBAECompCustomAERenderVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 20/12/22.
//

import Cocoa
import UMOmniaFramework


class BBAECompCustomAERenderVC :	UMViewController {
	
	static let storyboardId = 	"BBAECompCustomAERenderVC"
	static let storyboardName =	"BBAETemplate"
	
	// MARK: - UI Elements
	@IBOutlet weak var drgArea: UMAnimDragArea!
	@IBOutlet weak var lblCustomAErender: NSTextField!
	
	// MARK: - Vars
	var project :	BBAEProject!
	var comp :		BBAEComp!
	

	// MARK: - Display
	func displaylabel () {
		let s = comp.customAEProjectUrl?.lastPathComponent ?? "Drag Here AE Project"
		lblCustomAErender.setValue (s)
	}
	
	func setupArea () {
		drgArea.setup ()
		drgArea.atUrlDrag { [weak self] urlList in
			guard let url = urlList.first else { return }
			guard url.pathExtension.lowercased () == "aep" else { return }
			self?.comp.customAEProjectUrl = url
			self?.project.save ()
			self?.displaylabel ()
		}
	}
	
	func displayData () {
		displaylabel ()
		setupArea ()
	}
	
	// MARK: - View Cycle
	override func willAppear () {
		displayData ()
	}
	
	override func viewWillDisappear () {
		project.notifyUpdate ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   project :			BBAEProject,
						   comp :				BBAEComp) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.comp = comp
			vc.project = project
		}
	}
	

	// MARK: - Actions
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
	
	@IBAction func btnClearPressed (_ sender: Any) {
		comp.customAEProjectUrl = nil
		displayData ()
		project.save ()
	}
}
