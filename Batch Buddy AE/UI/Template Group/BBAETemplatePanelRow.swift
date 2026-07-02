//
//  BBAETemplatePanelRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 29/07/2021.
//

import Cocoa
import UMOmniaFramework

//protocol NAME Delegate {
//	func update NAME ()
//	func remove NAME (_ id : String)
//}

class BBAETemplatePanelRow :	UMTableCell {
	
	static let cellId = "BBAETemplatePanelRow"
	
	// MARK: - UI
	
	
	// MARK: - var
	var record :	BBAERecord!
	var project :	BBAEProject!
	var delegate :	BBAERecordCellDelegate!
	
	var expanded =	false
	
	var currentX :	CGFloat =	4
	
	static let textFieldWidth :	CGFloat =		200
	static let longTextFieldWidth :	CGFloat =	133
	static let numericFieldWidth :	CGFloat =	84
	static let urlFieldWidth :	CGFloat =		180
	static let buttonWidth :	CGFloat =		48
	static let fieldSeparation :	CGFloat =	10
	static let fieldY0 :	CGFloat =			2
	
	// MARK: - Display
	func displayTextField (_ i :	Int) {
		let textField = UMTextField (frame: CGRect (origin: CGPoint (x: currentX,
																	 y: BBAETemplatePanelRow.fieldY0),
													size: CGSize (width: BBAETemplatePanelRow.textFieldWidth,
																  height: 24)))
		textField.setup (defaultValue: record.recordFieldValueList [i].textContent ?? "") { [weak self] newText in
			self?.record.recordFieldValueList [i].textContent = newText
			self?.project.notifyUpdate ()
		}
		addSubview (textField)
		currentX += BBAETemplatePanelRow.textFieldWidth + BBAETemplatePanelRow.fieldSeparation
	}
	
	func displayLongField (_ i :	Int) {
		let textField = UMTextField (frame: CGRect (origin: CGPoint (x: currentX,
																	 y: BBAETemplatePanelRow.fieldY0),
													size: CGSize (width: BBAETemplatePanelRow.longTextFieldWidth,
																  height: 24)))
		textField.setup (defaultValue: record.recordFieldValueList [i].textContent ?? "") { _ in
		}
		textField.isEditable = false
		textField.font = NSFont.systemFont (ofSize: 10)
		addSubview (textField)
		currentX += BBAETemplatePanelRow.longTextFieldWidth + BBAETemplatePanelRow.fieldSeparation
	}
	
	func displayNumericField (_ i :	Int) {
		let numericTextField = UMTextField (frame: CGRect (origin: CGPoint (x: currentX,
																			y: BBAETemplatePanelRow.fieldY0),
														   size: CGSize (width: BBAETemplatePanelRow.numericFieldWidth,
																  height: 24)))
		numericTextField.setup (defaultValue: record.recordFieldValueList [i].valueContentString ?? "") { [weak self] newText in
			self?.record.recordFieldValueList [i].valueContent = Double (newText)
			self?.project.notifyUpdate ()
		}
		addSubview (numericTextField)
		currentX += BBAETemplatePanelRow.numericFieldWidth + BBAETemplatePanelRow.fieldSeparation
	}
	
	func displayURLField (_ i :	Int) {
		let f = CGRect (origin: CGPoint (x: currentX,
										 y: BBAETemplatePanelRow.fieldY0),
						size: CGSize (width: BBAETemplatePanelRow.urlFieldWidth,
									  height: 24))
		let dragArea = UMDragArea (frame: f)
		switch record.recordFieldValueList [i].type () {
			case .image:
				dragArea.fileTypes = ["png", "jpg", "jpeg", "tif", "tiff", "psd"]
			case .video:
				dragArea.fileTypes = ["mov", "mp4", "m4v"]
			case .audio:
				dragArea.fileTypes = ["wav", "wave"]
			case .vectorAI:
				dragArea.fileTypes = ["ai"]
			default: break
		}
		dragArea.atUrlDrag { [weak self] urlList in
			self?.record.recordFieldValueList [i].url = urlList [0]
			self?.project.notifyUpdate ()
			self?.displayURLField (i)
		}
		let urlField = UMTextField (frame: f)
		urlField.setup (defaultValue: record.recordFieldValueList [i].url?.lastPathComponent ?? "") { _ in
		}
		urlField.font = NSFont.systemFont (ofSize: 10)
		urlField.isEditable = false
		addSubview (urlField)
		addSubview (dragArea)
		currentX += BBAETemplatePanelRow.urlFieldWidth + BBAETemplatePanelRow.fieldSeparation
	}
	
	@objc func initialButtonPressed () {
		BBAERecordVC.showWindow (instance: record,
								   project: project)
	}
	
	func displayInitalButton () {
		let f = CGRect (origin: CGPoint (x: currentX,
										 y: BBAETemplatePanelRow.fieldY0),
						size: CGSize (width: BBAETemplatePanelRow.buttonWidth,
									  height: 24))
		let button = UMRoundedRectButton (frame: f)
		button.setTitle ("Panel")
		button.fill = false
		button.border = 0
		button.setFontSize (10)
//		button.border = foreColor
//		button.setCallback { [weak self] in
//			guard let self = self else { return }
//			BBAEInstanceVC.showWindow (instance: self.instance,
//									   project: self.project)
//		}
		button.target = self
		button.action = #selector (initialButtonPressed)
		addSubview (button)
		currentX += BBAETemplatePanelRow.buttonWidth + BBAETemplatePanelRow.fieldSeparation
	}
	
	func displayRow () {
		subviews.forEach { $0.removeFromSuperview () }
		currentX = 8
		displayInitalButton ()
		for i in 0 ..< record.recordFieldValueList.count {
			let item = record.recordFieldValueList [i]
			switch item.type () {
				case .text :			displayTextField (i)
				case .longText :		displayLongField (i)
				case .numericValue :	displayNumericField (i)
				case .audio,
					 .image,
					 .vectorAI,
					 .video :			displayURLField (i)
				default :				break
			}
		}
	}
	
	func setupObserver () {
		project.observeUpdate { [weak self] in
			self?.displayRow ()
		}
	}
	
	func displayData () {
		displayRow ()
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  NSTableView,
						 instance :		BBAERecord,
						 project :		BBAEProject,
						 delegate : 	BBAERecordCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.record = instance
		cell.project = project
		cell.delegate = delegate
		cell.displayData ()
		
		//cancella se non la vuoi
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Actions
//	@IBAction func btnRemovePressed(_ sender: Any) {
//		delegate.remove (id)
//	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
}
