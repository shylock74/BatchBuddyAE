//
//  BBAETemplate.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework

final class BBAEComp :    Codable,
						  UMSubscribable {
	
	var subscribableType :	String { "media.ulti.BBAETemplateComp" }
	
	static let shared =	BBAEComp (name: "****shared")
	
	struct OverrideRenderFolder :	Codable {
		var override :		Bool =	false
		var mediaFieldId :	String =	""
	}
	
	var id =						UMId.newId (useCounter: false)
	var name :						String
	var shortName_ :				String?
	var defaultColorId :			String?
	var fieldList :					[BBAECompField] =	[]
	var defaultRenderSettingId :	String? =	BBAESettings.shared.defaultRenderSettings
	var defaultOutputModuleId :		String? =	BBAESettings.shared.defaultOutputSettingsId
	var renderSingleFrame :			Bool? =		false
	var frameToRender :				Int? =		0

	var isGroup :					Bool? =		false
	var compGroupList :				[BBAECompGroup]? =	[]
		
	var supposedFramesCount :		Int? =		nil
	var overrideRenderFolder :		OverrideRenderFolder =	OverrideRenderFolder ()
	var customAEProjectUrl :		URL?

	var objectOrder :				Int? = 		0
	
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case shortName_
		case defaultColorId
		case fieldList = "itemList"
		case defaultRenderSettingId
		case defaultOutputModuleId
		case renderSingleFrame
		case frameToRender
		case isGroup
		case compGroupList = "templateGroupList"
		case supposedFramesCount
		case overrideRenderFolder
		case objectOrder
		case customAEProjectUrl
	}
		
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
//		self.id = (try? container.decodeIfPresent (String.self,
//												   forKey: .id)) ?? ""
		self.id = container.decodeString (forKey: .id, default: "")
		self.name = container.decodeString (forKey: .name, default: "")
		self.shortName_ = (try? container.decodeIfPresent (String.self,
														   forKey: .shortName_)) ?? ""
		self.defaultColorId = (try? container.decodeIfPresent (String.self,
															   forKey: .defaultColorId)) ?? ""
		self.fieldList = (try? container.decodeIfPresent ([BBAECompField].self,
														 forKey: .fieldList)) ?? []
		self.defaultRenderSettingId = (try? container.decodeIfPresent (String.self,
																	   forKey: .defaultRenderSettingId)) ?? ""
		self.defaultOutputModuleId = (try? container.decodeIfPresent (String.self,
																	  forKey: .defaultOutputModuleId)) ?? ""
		self.renderSingleFrame = (try? container.decodeIfPresent (Bool.self,
																  forKey: .renderSingleFrame)) ?? false
		self.frameToRender = (try? container.decodeIfPresent (Int.self,
															  forKey: .frameToRender)) ?? 0
		self.isGroup = (try? container.decodeIfPresent (Bool.self,
														forKey: .isGroup)) ?? false
		self.compGroupList = (try? container.decodeIfPresent ([BBAECompGroup].self,
																  forKey: .compGroupList)) ?? []
		self.objectOrder = (try? container.decodeIfPresent (Int.self,
															forKey: .objectOrder)) ?? nil
		self.supposedFramesCount = (try? container.decodeIfPresent (Int.self,
															forKey: .supposedFramesCount))
		self.overrideRenderFolder = (try? container.decodeIfPresent (OverrideRenderFolder.self, forKey: .overrideRenderFolder)) ?? OverrideRenderFolder ()
		self.customAEProjectUrl = (try? container.decodeIfPresent (URL.self, forKey: .customAEProjectUrl)) ?? nil
}

	var shortName :	String {
		shortName_ ?? name
	}
	
	init (name :		String,
		  shortName :	String? =	nil) {
		self.name = name
		self.shortName_ = shortName
	}
	
	func duplicate () -> BBAEComp {
		let copy = BBAEComp (name: name + " copy",
									 shortName: shortName + "_copy")
		copy.defaultColorId = defaultColorId
		copy.fieldList = fieldList.map { $0.duplicate (order: $0.objectOrder!) }
		copy.defaultRenderSettingId = defaultRenderSettingId
		copy.defaultOutputModuleId = defaultOutputModuleId
		copy.renderSingleFrame = renderSingleFrame
		copy.frameToRender = frameToRender
		copy.isGroup = isGroup
		copy.compGroupList = compGroupList
		return copy
	}
	
	func loaded () {
		if objectOrder == nil {
			objectOrder = 0
			fieldList.forEach {
				objectOrder! += 1
				$0.itemLoaded (order: objectOrder)
			}
		} else {
			fieldList.forEach {
				$0.itemLoaded (order: $0.objectOrder!)
			}
		}
		
		isGroup = isGroup ?? false
		compGroupList = compGroupList ?? []
		compGroupList?.forEach {
			$0.fixAtLoad ()
		}
	}
	
	func setShortName (_ t :	String) {
		shortName_ = t
	}
	
	func instanceHeight () -> CGFloat {
		var height :	CGFloat =	32
		height = fieldList.reduce (height, { $0 + $1.instanceHeight + 2 })
		return height
	}
	
	func renderSettings () -> String? {
		let r = BBAESettings.shared.renderSettingsName (defaultRenderSettingId) ?? defaultRenderSettingId
		return r
	}
	
	func outputModule () -> String? {
		BBAESettings.shared.outputModuleName (defaultOutputModuleId)
	}
	
	func outputModuleExtension () -> String? {
		let ext = BBAESettings.shared.outputModuleExtension (defaultOutputModuleId)
		return ext
	}
	
	func getCompItem (withId id :	String) -> BBAECompField? {
		fieldList.first { $0.id == id }
	}
	
	var json :	String {
		JU.encodeToString (self)
	}
	
	func export (toUrl url :	URL) {
		fu_writeTextToFile (url: url,
							text: json)
	}
	
	func load (fromUrl url :	URL) -> BBAEComp? {
		return JU.decodeFromURL (url,
								 type: self)
	}
	
	func addField (_ field : BBAECompField) {
		if field.type == .recordId {
			fieldList.insert (field, at: 0)
		} else {
			fieldList.append (field)
		}
	}
	
	var mediaFieldList : [BBAECompField] {
		let l = fieldList.filter { $0.iSmedia }
		return l
	}
	
	var mediaInFieldList :	Bool {
		!mediaFieldList.isEmpty
	}
	
	var mustIterate : Bool {
		for field in fieldList {
			if field.type == .numericValue,
			   field.numericFieldSettings.iterator {
				return true
			}
		}
		return false
	}

	var iterationRange :	ClosedRange <Int> {
		for field in fieldList {
			if field.isIterator {
				return field.numericFieldSettings.minValue.int ... field.numericFieldSettings.maxValue.int
			}
		}
		return 1 ... 1
	}
}
