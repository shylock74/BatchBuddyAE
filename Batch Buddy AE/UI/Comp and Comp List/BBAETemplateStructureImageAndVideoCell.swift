//
//  BBAETemplateStructureImageAndVideoCell.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 11/01/22.
//

import Cocoa
import UMOmniaFramework


class BBAETemplateStructureImageAndVideoCell :	UMTableCell {
	
	static let cellId =	"BBAETemplateStructureImageAndVideoCell"
	
	// MARK: - UI
	@IBOutlet weak var imgFieldType: NSImageView!
	@IBOutlet weak var fldFieldName: UMTextField!
	@IBOutlet weak var drgPlaceholder: UMDragArea!
	
	// MARK: - var
	var compField :	BBAECompField!
	var comp :	BBAEComp!
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
	
	// MARK: - Display
	//	func populateResizePolicyPop () {
	//		popResizePolicy.addItem (title: "Fill",
	//								 value: "0")
	//		popResizePolicy.addItem (title: "Fit",
	//								 value: "1")
	//		popResizePolicy.setValueAsString (value: compField.resizePolicy == .fill
	//											? "0"
	//											: "1")
	//		popResizePolicy.userSelectedCallback = { [self] value in
	//			compField.resizePolicy = (value as? String) == "0"
	//				? .fill
	//				: .fit
	//			project.save ()
	//			notifyUpdates ()
	//		}
	//	}
	
	//	func populateColorPop () {
	//		popColor.addItem (title: "Not Set",
	//						  value: "*")
	//		for color in project.colorList {
	//			popColor.addItem (title: color.name,
	//							  value: color.id)
	//		}
	//		if compField.colorizeColorId == nil || !compField.colorize {
	//			popColor.setValueAsString (value: "*")
	//		} else {
	//			popColor.setValueAsString (value: compField.colorizeColorId!)
	//		}
	//		popColor.userSelectedCallback = { [self] value in
	//			let valueS = value as? String
	//			compField.colorizeColorId = valueS != "*"
	//				? valueS
	//				: nil
	//			project.save ()
	//			notifyUpdates ()
	//		}
	//	}
	
	func setupDrag () {
		drgPlaceholder.image = compField.poster ()?.image
		switch compField.type {
			case .image:
				drgPlaceholder.fileTypes = ["png", "jpg", "jpeg", "tif", "tiff", "psd"]
			case .video:
				drgPlaceholder.fileTypes = ["mov", "mp4", "m4v"]
			case .audio:
				drgPlaceholder.fileTypes = ["wav", "wave"]
			case .vectorAI:
				drgPlaceholder.fileTypes = ["ai"]
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
				}
				UMProgressVC_Type0S.hide ()
				notifyUpdates ()
			}
		}
	}
	
	func displayData () {
		imgFieldType.image = compField.type.image
		
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

