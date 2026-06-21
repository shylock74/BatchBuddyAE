//
//  BBAETemplateStructureCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 27/04/2021.
//

import Cocoa
import UMOmniaFramework

protocol BBAETemplateStructureCellDelegate {
	func updateTemplate ()
	func removeTemplateItem (_ id :	String)
}

// MARK: - BBAETemplateStructureTextCell
class BBAETemplateStructureTextCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureTextCell"
	
	// MARK: - UI
	@IBOutlet weak var imgFieldType: NSImageView!
	@IBOutlet weak var fldFieldName: UMTextField!
	@IBOutlet weak var fldDefault: UMTextField!
	@IBOutlet weak var btnCopyColorFill: NSButton!
	
	// MARK: - var
	var compField :	BBAECompField!
	var comp :		BBAEComp!
	var project :	BBAEProject!
	var delegate :	BBAETemplateStructureCellDelegate!
	var selected =	false {
		didSet {
			hilite = selected
		}
	}
	
	// MARK: - Notifications
	func notifyUpdates () {
		delegate.updateTemplate ()
		comp.notifyUpdate ()
		project.notifyUpdate ()
		UMNotify.notify (keyword: "media.ulti.bbae.\(compField.id)")
	}
	
	func displayData () {

		imgFieldType.image = compField.type.image
		
		fldFieldName.setup (defaultValue: compField.fieldName) { [self] newValue in
			compField.fieldName = newValue
			BBAECompField.addFieldToGlobalList (compField)
			delegate.updateTemplate ()
			notifyUpdates ()
		}
		let dS = compField.type == .numericValue
		? (compField.defaultNumericValue != nil
		   ? String (compField.defaultNumericValue ?? 0)
		   : "")
		: ""
		fldDefault.setup (defaultValue: dS) { [self] newValue in
			if compField.type == .numericValue {
				compField.defaultNumericValue = Double (newValue)
			}
		}
		btnCopyColorFill.isHidden = compField.type != .colorFill
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 compField :	BBAECompField,
						 comp :			BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.compField = compField
		cell.project = project
		cell.delegate = delegate
		cell.comp = comp
		cell.displayData ()
		cell.setBackground ()

		return cell
	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
	
	// MARK: - Actions
	@IBAction func fldFieldNameChanged (_ sender: Any) {
		compField.fieldName = fldFieldName.stringValue
		project.notifyUpdate ()
		notifyUpdates ()
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplateItem (compField.id)
		project.notifyUpdate ()
	}
	
	@IBAction func btnCopyCodePressed (_ sender: Any) {
		let code = compField.getAECode ()
		UMPasteboard.setString (code)
		
		var t :	String = ""
		switch compField.type {
			case .text, .longText:
				t = "Text"
			case .colorFill:
				t = "Color"
			case .numericValue:
				t = "Number"
			default: break
		}
		UMShowNotification (title: "Copied",
							informativeText: "After Effects \(t) Code Copied Successfully.")
	}
	
	@IBAction func btnCopyFillColorPressed (_ sender: Any) {
		let code = BBAESettings.shared.getDynamicColorFillString (variableName: compField.variableName ())
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "After Effects Color Fill Copied Successfully.")
	}
}


// MARK: - BBAETemplateStructureAudioCell
class BBAETemplateStructureAudioCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureAudioCell"
	
	// MARK: - UI
	@IBOutlet weak var imgFieldType: NSImageView!
	@IBOutlet weak var fldFieldName: UMTextField!
	@IBOutlet weak var drgPlaceholder: UMDragArea!
	
	// MARK: - var
	var compField :		BBAECompField!
	var comp :		BBAEComp!
	var project :		BBAEProject!
	var delegate :		BBAETemplateStructureCellDelegate!
	var selected =	false {
		didSet {
			hilite = selected
		}
	}
	
	// MARK: - Notifications
	func notifyUpdates () {
		delegate.updateTemplate ()
		comp.notifyUpdate ()
		project.notifyUpdate ()
		UMNotify.notify (keyword: "media.ulti.bbae.\(compField.id)")
	}
	
	// MARK: - Display
	
	
	func setupDrag () {
		drgPlaceholder.image = compField.poster ()?.image
		switch compField.type {
			case .audio:
				drgPlaceholder.fileTypes = ["wav", "wave"]
			default: break
		}
		
		drgPlaceholder.atUrlDrag { [self] urlList in
			UMProgressVC_Type0S.show ()
			UMProgressVC_Type0S.setStatus ("Loading...")
			Queue.execute {
				let url = urlList [0]
				compField.placeholderUrl = url
				if compField.type == .image {
					project.saveImage (srcUrl: url,
									   compShortName: comp.shortName,
									   dstName: compField.placeholderURLInBBAEFolderName (shortName: comp.shortName),
									   customAEProjectUrl: comp.customAEProjectUrl)
				} else if compField.type == .vectorAI {
					project.saveAI (srcUrl: url,
									compShortName: comp.shortName,
									dstName: compField.placeholderURLInBBAEFolderName (shortName: comp.shortName),
									customAEProjectUrl: comp.customAEProjectUrl)
				} else if compField.type == .video {
					project.saveVideo (srcUrl: url,
									   compShortName: comp.shortName,
									   dstName: compField.placeholderURLInBBAEFolderName (shortName: comp.shortName),
									   customAEProjectUrl: comp.customAEProjectUrl)
				} else if compField.type == .audio {
					project.saveAudio (srcUrl: url,
									   compShortName: comp.shortName,
									   dstName: compField.placeholderURLInBBAEFolderName (shortName: comp.shortName),
									   customAEProjectUrl: comp.customAEProjectUrl)
					XMain.execute {
						drgPlaceholder.image = Draw.getImage ("Icn_AudioFile")
					}
				}
				UMProgressVC_Type0S.hide ()
				notifyUpdates ()
			}
		}
	}
	
	func displayData () {
		fldFieldName.setup (defaultValue: compField.fieldName) { [self] newValue in
			compField.fieldName = newValue
			BBAECompField.addFieldToGlobalList (compField)
			project.notifyUpdate ()
			notifyUpdates ()
		}
		setupDrag ()
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 compField :	BBAECompField,
						 comp :		BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.compField = compField
		cell.project = project
		cell.delegate = delegate
		cell.comp = comp
		cell.displayData ()
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
	
	// MARK: - Actions
	@IBAction func fldFieldNameChanged (_ sender: Any) {
		compField.fieldName = fldFieldName.stringValue
		delegate.updateTemplate ()
		project.notifyUpdate ()
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplateItem (compField.id)
		project.notifyUpdate ()
	}
	
	@IBAction func btnCopyPlaceholderUrlPressed (_ sender: Any) {
		
	}
	
	@IBAction func btnshowPlaceholderInFinderPressed (_ sender: Any) {
//		let url = item.placeholderURLInBBAEFolderName (shortName: comp.shortName,
//											 order: item.objectOrder!)
		guard let url = project.dynamicImageUrl (compShortName: comp.shortName,
												 name: compField.placeholderURLInBBAEFolderName (shortName: comp.shortName),
												 customAEProjectUrl: comp.customAEProjectUrl) else { return }
		fu_showInFinder (url)
	}
	
}



// MARK: - BBAETemplateStructureSwitchCell
class BBAETemplateStructureSwitchCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureSwitchCell"
	
	// MARK: - UI
//	@IBOutlet weak var lblFieldType: NSTextField!
	@IBOutlet weak var fldFieldName: UMTextField!
	@IBOutlet weak var chkDefaultValue: UMCheckButton!
	
	// MARK: - var
	var compField :	BBAECompField!
	var comp :		BBAEComp!
	var project :	BBAEProject!
	var delegate :	BBAETemplateStructureCellDelegate!
	var selected =	false {
		didSet {
			hilite = selected
		}
	}
	
	// MARK: - Notifications
	func notifyUpdates () {
		delegate.updateTemplate ()
		comp.notifyUpdate ()
		project.notifyUpdate ()
		UMNotify.notify (keyword: "media.ulti.bbae.\(compField.id)")
	}
	
	func displayData () {
		fldFieldName.setup (defaultValue: compField.fieldName) { [self] newValue in
			compField.fieldName = newValue
			BBAECompField.addFieldToGlobalList (compField)
			delegate.updateTemplate ()
			notifyUpdates ()
			project.notifyUpdate ()
		}

		chkDefaultValue.setup (initialValue: compField.defaultNumericValue == 1) { [self] _ in
			compField.defaultNumericValue = chkDefaultValue.value ? 1 : 0
		}
	}
	
	// MARK: - Display
	static func getCell (_ tableView :  NSTableView,
						 compField :	BBAECompField,
						 comp :			BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.compField = compField
		cell.project = project
		cell.delegate = delegate
		cell.comp = comp
		cell.displayData ()
		cell.setBackground ()
		
		return cell
	}
	
	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
	
	// MARK: - Actions
	@IBAction func fldFieldNameChanged (_ sender: Any) {
		compField.fieldName = fldFieldName.stringValue
		project.notifyUpdate ()
		notifyUpdates ()
	}
	
	@IBAction func btnRemovePressed (_ sender: Any) {
		delegate.removeTemplateItem (compField.id)
		project.notifyUpdate ()
	}
	
	@IBAction func btnCopyCodePressed(_ sender: Any) {
		let code = compField.getAECode ()
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "After Effects Numeric Code Copied Successfully.")
	}
	
	@IBAction func btnCopyVisibilityCodePressed (_ sender: Any) {
		let code = BBAESettings.shared.getDynamicCheckboxVisibilityCodeString (variableName: compField.variableName ())
		UMPasteboard.setString (code)
		UMShowNotification (title: "Copied",
							informativeText: "After Effects Dynamic Opacity Copied Successfully.")
	}
}



// MARK: - BBAETemplateStructureCell
class BBAETemplateStructureCell {
	
	static func getCell (_ tableView :	NSTableView,
						 compField :	BBAECompField,
						 comp :			BBAEComp,
						 project :		BBAEProject,
						 delegate :		BBAETemplateStructureCellDelegate) -> UMTableCell? {
		
		switch compField.type {
				
			case .text, .longText, .colorFill:
				return BBAETemplateStructureTextCell.getCell (tableView,
															  compField: 	compField,
															  comp: comp,
															  project :	project,
															  delegate: delegate)
				
			case .numericValue:
				return BBAETemplateStructureNumericCell.getCell (tableView,
																 compField: compField,
																 comp: comp,
																 project: project,
																 delegate: delegate)
				
			case .image, .video, .vectorAI:
				return BBAETemplateStructureImageAndVideoCell.getCell (tableView,
																	   compField: 	compField,
																	   comp: comp,
																	   project :	project,
																	   delegate: delegate)
				
			case .audio:
				return BBAETemplateStructureAudioCell.getCell (tableView,
															   compField: 	compField,
															   comp: comp,
															   project :	project,
															   delegate: delegate)
				
			case .checkBox:
				return BBAETemplateStructureSwitchCell.getCell (tableView,
																compField: compField,
																comp: comp,
																project: project,
																delegate: delegate)
				
			case .recordId:
				return BBAETemplateStructureRecordIdCell.getCell (tableView,
																  compField: compField,
																  comp: comp,
																  project: project,
																  delegate: delegate)
				

			default: return nil
		}
	}
	
	static func registerCells (_ tableView :	NSTableView) {
		BBAETemplateStructureImageAndVideoCell.register (tableView)
		BBAETemplateStructureTextCell.register (tableView)
		BBAETemplateStructureNumericCell.register (tableView)
		BBAETemplateStructureAudioCell.register (tableView)
		BBAETemplateStructureSwitchCell.register (tableView)
		BBAETemplateStructureRecordIdCell.register (tableView)
	}
}
