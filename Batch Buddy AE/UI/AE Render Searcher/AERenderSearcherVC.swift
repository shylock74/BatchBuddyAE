//
//  AERenderSearcherVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 03/12/21.
//

import Cocoa
import UMOmniaFramework

class AERenderSearcherVC :	UMViewController, UMTableCellDelegate {
	
	static let storyboardId = 	"AERenderSearcherVC"
	static let storyboardName =	"AERenderSearcherVC"
	
	static let kNotification =	"media.ulti.bbae.AERenderSearcherVC.done"
	
	// MARK: - UI Elements
	@IBOutlet weak var tabAERenderList: UMTableView!
	@IBOutlet weak var drgAERender: UMDragArea!
	@IBOutlet weak var lblAERender: NSTextField!
	
	// MARK: - Vars
	var eligibleUrls =	[URL] ()
	var selectedRow :	Int?
	
	// MARK: - Display
	func displayAEREnderPath () {
		let s = BBAESettings.shared.aeRenderEngineUrl?.path ?? "Not Set"
		lblAERender.setValue (s)
	}
	
	func displayData () {
		displayAEREnderPath ()
		drgAERender.atUrlDrag { urlList in
			let url = urlList [0]
			if url.name.lowercased () == "aerender" {
				BBAESettings.shared.aeRenderEngineUrl = url
				self.displayAEREnderPath ()
			}
		}
	}
	
	// MARK: - Table
	func setupTable () {
		tabAERenderList.registerCell (nibName: UMTableCell_IconText.storyboardId,
									  bundle: UMOmniaFrameworkBundle,
									  cellId: UMTableCell_IconText.storyboardId)
		tabAERenderList.setup (rowCount: { self.eligibleUrls.count },
							   cellHandler: { index in
			UMTableCell_IconText.getCell (self.tabAERenderList,
									  id: self.eligibleUrls [index].path,
									  text: self.eligibleUrls [index].parentName + " > AERender",
									  icon: index == self.selectedRow ? Draw.getImage ("Btn__Ok_00000") : nil,
									  isSelected: false, //index == self.selectedRow,
									  delegate: self)!
		},
							   cellHeight: { _ in 28 },
							   rowSelected: {
			self.selectedRow = $0
			if let selectedRow = self.selectedRow {
				BBAESettings.shared.aeRenderEngineUrl = self.eligibleUrls [selectedRow]
				self.displayAEREnderPath ()
			}
		})
		tabAERenderList.wantsLayer = true
		tabAERenderList.layer?.backgroundColor = NSColor.red.cgColor
	}
	
	func umTableCellRemove (id: String) {
		//		<#code#>
	}
	

	
	// MARK: - View Cycle
	override func appeared () {
		
	}
	
	override func willAppear () {
		displayData ()
	}
	
	override func loaded () {
		setupTable ()
	}
	
	// MARK: - Show
	static func showWindow () {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.AERenderSearcherVC",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									bundle: nil,
									windowTitle: "AERender Wizard",
									disableResize: false,
									minHeight: 320) { vc in
		}
	}

	
	// MARK: - Actions
	@IBAction func btnSearchPressed(_ sender: Any) {
		UMProgressVC_Type0S.show (currentController: self,
								  imgProgressPrefix: nil,
								  status: "Searching for AERender Executables")
		Queue.execute { [self] in
			eligibleUrls = UMAERender.getEligibleAERenderUrlList () { count in
				UMProgressVC_Type0S.setSubStatus ("\(count) Files Scanned so far...")
			}
			UMProgressVC_Type0S.hide ()
			XMain.execute { [weak self] in
				guard let self else { return }
				if let url = BBAESettings.shared.aeRenderEngineUrl {
					let index = eligibleUrls.firstIndex (of: url)
					tabAERenderList.selectRow (index,
											   doCallback: false)
					selectedRow = index
				}
				tabAERenderList.reloadDataInMainThread ()
			}
		}
	}
	
	
	@IBAction func btnOkPressed (_ sender: Any) {
		guard let selectedRow = selectedRow else {
			UMAlert.ok (message: "Warning",
						informativeText: "No AERender Selected")
			return
		}
		BBAESettings.shared.aeRenderEngineUrl = eligibleUrls [selectedRow]
		UMNotify.notify (keyword: AERenderSearcherVC.kNotification)
		close ()
	}
	
	@IBAction func btnCancelPressed (_ sender: Any) {
		close ()
	}
}
