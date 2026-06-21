//
//  BBAEInstanceCompactRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 07/02/22.
//

import Cocoa
import UMOmniaFramework


class BBAERecordCompactRow :	UMTableCell {
	
	static let cellId = "BBAERecordCompactRow"
	
	// MARK: - UI
	@IBOutlet weak var imgId: NSImageView!
	@IBOutlet weak var lblId: NSTextField!
	@IBOutlet weak var lblTemplateName: NSTextField!
	@IBOutlet weak var chkRender: UMCheckButton!
	@IBOutlet weak var btnRender: NSButton!
	
	// MARK: - var
	var record :			BBAERecord!
	var project :			BBAEProject!
	var delegate : 			BBAERecordCellDelegate!
	var fatherController :	NSViewController!

	var comp :	BBAEComp? {
		project.getComp (withId: record.compId)
	}
	
	// MARK: - Display
	func setupCheck () {
		chkRender.setup (initialValue: record.status == .toBeRendered ? true : false) { newValue in
			self.record.status = newValue ? .toBeRendered : .dontRender
			self.displayRenderButton ()
		}
	}
	
	func displayRenderButton () {
		XMain.execute { [weak self] in
			guard let bbaeItem = self?.record else { return }
			switch bbaeItem.status {
				case .toBeRendered:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00001")
				case .dontRender:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00000")
				case .rendering:
					self?.btnRender.image = Draw.getImage ("Icon_Render_00002")
				case .rendered:
					self?.btnRender.image = Draw.getImage ("Icon_Render (0-00-00-00)")
			}
		}
	}
	
	func displayData () {
		lblId.setValue (record.displayId ())
		lblTemplateName.setValue (comp?.name ?? "Not Set")
		setupCheck ()
		displayRenderButton ()
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  NSTableView,
						 record :			BBAERecord,
						 project :			BBAEProject,
						 fatherController :	NSViewController,
						 delegate :			BBAERecordCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.record = record
		cell.delegate = delegate
		cell.project = project
		cell.fatherController = fatherController
		cell.displayData ()
		cell.setBackground ()
		return cell
	}
	
	// MARK: - Actions
//	@IBAction func btnRemovePressed(_ sender: Any) {
//		delegate.remove (id)
//	}
	
	@IBAction func btnToggleCompact(_ sender: Any) {
		record.displayMode = .normal
		project.notifyUpdate ()
	}
	
	@IBAction func btnRenderImmediatelyPressed (_ sender: Any) {
		guard project.aepFilePresent () else {
			UMAlert.ok (message: "Alert",
						informativeText: "After Effects file (AEP) missing.")
			return
		}
		guard let comp = project.getComp (withId: record.compId) else {
			UMAlert.ok (message: "Alert",
						informativeText: "No Comp with this Id")
			return
		}
		guard BBAESettings.shared.aeRenderExists () else {
			UMAlert.ok (message: "Alert",
						informativeText: "AERender not present.")
			return
			
		}
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			project.renderedCount = 0
			if comp.isGroup == true {
				project.toBeRenderedCount = comp.compGroupList?.filter { $0.active }.count ?? 0
			} else {
				project.toBeRenderedCount = 1
			}
			delegate.renderRecord (item: record)
		}
	}
	
	@IBAction func btnSaveToDiskPressed (_ sender: Any) {
		UMProgressVC_Type0.show (currentController: fatherController,
								 imgProgressPrefix: "BBAE_Progress_",
								 status: "Saving Data...")
		Queue.execute { [weak self] in
			guard let s = self,
			let comp = s.comp else { return }
			s.record.prepareFiles (inProject: s.project,
								   comp: comp)
			UMProgressVC_Type0.hide ()
		}
		
	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
}
