//
//  BBAEItem.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework

class BBAEItemInstance :   Codable {
	
	enum Status :	String, Codable {
		case toBeRendered
		case dontRender
		case rendering
		case rendered
		
		func displayString () -> String {
			switch self {
				case .toBeRendered:
					return "Needs R."
				case .dontRender:
					return "Don't R."
				case .rendering:
					return "Rendering"
				case .rendered:
					return "Rendered"
			}
		}
	}
		
	var id =        	UMId.newId ()
	var name :			String = ""
	var templateId :	String? =	nil{
		didSet {
			self.setupItems ()
			UMDispatch.notify (key: id)
		}
	}
	var status =		Status.toBeRendered {
		didSet {
			UMDispatch.notify (key: id)
		}
	}
	var instanceItemList =	[BBAETemplateInstanceItem] ()
	
	func fileItemName () -> String {
		if name != "" {
			return name
		}
		return instanceItemList.reduce ("", { $0 + $1.fileSaveNameParticle })
	}
	
	init (template :	BBAETemplate?) {
		self.templateId = template?.id
		setupItems ()
	}
	
	var template :	BBAETemplate? {
		BBAEProject.getTemplate (withId: templateId)
	}
	
	func getInstance (forTemplateItemId id :	String) -> BBAETemplateInstanceItem? {
		return instanceItemList.first { $0.templateItemId == id }
	}
	
 	func setupItems () {
		guard let template = template else {
			instanceItemList = []
			return
		}
		for templateItem in template.itemList {
			if getInstance (forTemplateItemId: templateItem.id) == nil {
				instanceItemList.append (BBAETemplateInstanceItem (templateItemId: templateItem.id))
			}
		}
		let instanceItemListTemp = instanceItemList
		instanceItemList = []
		for templateItem in template.itemList {
			instanceItemList.append (instanceItemListTemp.first { $0.templateItemId == templateItem.id }!)
		}
	}
	
	func setText (index :	Int,
				  text :	String,
				  colorId :	String? = nil) -> Bool {
		//		var changed = false
		//		if index >= textList.count {
		//			for _ in textList.count ... index {
		//				textList.append (BBAEText (text: ""))
		//				changed = true
		//			}
		//		}
		//		if textList [index].text != text || textList [index].colorId != colorId {
		//			changed = true
		//		}
		//		textList [index] = BBAEText (text: text, colorId: colorId)
		//		return changed
		return false
	}
	
	func prepareConfigurationFile (url u:		URL,
								   project :	BBAEProject) {
		let url = u.deletingLastPathComponent ().append (BBAESettings.shared.bbaeSubFolderName,
														 BBAESettings.shared.bbaeTextsFileName)
		fu_deleteFile (url)
		guard let template = project.getTemplate (withId: templateId) else { return }
		let fileText = instanceItemList.reduce ("",
												{ $0 + $1.aeVariableAssignation (template: template) })
		fu_writeTextToFile (url: url,
							text: fileText)
	}
	
	func cellHeight () -> CGFloat {
		template?.instanceHeight () ?? 64
	}
}
