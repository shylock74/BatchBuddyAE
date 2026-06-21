//
//  BBAETEmplateItem.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework

class BBAETemplateItem :	Codable {
	
	static var templateItemList =	[BBAETemplateItem] ()
	
	enum ItemType :	String, Codable {
		case text
		case colorFill
		case image
		case video
		
		func instanceHeight () -> CGFloat {
			switch self {
				case .text:
					return 28
				case .colorFill:
					return 0
				case .image:
					return 120
				case .video:
					return 120
			}
		}
	}
	
	enum ResizePolicy :	String, Codable {
		case fill
		case fit
	}
	
	var id =					UMId.newId ()
	var type :					ItemType =		.text
	var fieldName :				String =		""
	var placeholderUrl :		URL? =			nil
	var placeholderPosterUrl :	URL? =			nil
	var resize :				Bool =			false
	var resizeWidth :			Int =			0
	var resizeHeight :			Int = 			0
	var resizePolicy :			ResizePolicy =	.fill
	var colorize :				Bool =			false
	var colorizeColorId :		String? =		nil
	
	init (type :	BBAETemplateItem.ItemType) {
		self.type = type
	}
	
	var instanceHeight :	CGFloat {
		type.instanceHeight ()
	}
	
	func getAECode () -> String {
		BBAESettings.shared.getTextAECodeString (item: self)
	}
	
	static func addItemToList (_ item :	BBAETemplateItem) {
		templateItemList = templateItemList.filter { $0.id != item.id }
		templateItemList.append (item)
	}
	
	static func getItem (withId id :	String?) -> BBAETemplateItem? {
		guard let id = id else { return nil }
		return templateItemList.first { $0.id == id }
	}
	
	func variableName () -> String {
		return id
	}
}
