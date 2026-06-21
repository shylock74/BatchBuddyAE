//
//  BBAE Template Group.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 09/09/2021.
//

import Foundation
import UMOmniaFramework

final class BBAECompGroup :	Codable {
	
	var id =						UMId.newId (useCounter: false)
	var name :						String
	var shortName :					String
	var defaultRenderSettingId :	String? =	nil
	var defaultOutputModuleId :		String? =	nil
	var renderSingleFrame :			Bool? = false
	var frameToRender :				Int? = 0
	var supposedFrameCount :		Int? = nil
	var active :					Bool =	true
	
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case shortName
		case defaultRenderSettingId
		case defaultOutputModuleId
		case renderSingleFrame
		case frameToRender
		case supposedFrameCount
		case active
	}
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
		self.id = container.decodeString (forKey: .id, default: "")
		self.name = container.decodeString (forKey: .name, default: "")
		self.shortName = container.decodeString (forKey: .shortName, default: "")
		self.defaultRenderSettingId = container.decodeString (forKey: .defaultRenderSettingId, default: "")
		self.defaultOutputModuleId = container.decodeString (forKey: .defaultOutputModuleId, default: "")
		self.renderSingleFrame = (try? container.decodeIfPresent (Bool.self,
																  forKey: .renderSingleFrame)) ?? false
		self.frameToRender = (try? container.decodeIfPresent (Int.self,
															  forKey: .frameToRender)) ?? 0
		self.supposedFrameCount = (try? container.decodeIfPresent (Int.self,
																   forKey: .supposedFrameCount)) ?? 0
		self.active = (try? container.decodeIfPresent (Bool.self,
													   forKey: .active)) ?? true
	}
	
	init (name :					String,
		  shortName :				String,
		  defaultRenderSettingId :	String? =	nil,
		  defaultOutputModuleId :	String? =	nil,
		  renderSingleFrame :		Bool? = false,
		  frameToRender :			Int? = nil) {
		self.name = name
		self.shortName = shortName
		self.defaultRenderSettingId = defaultRenderSettingId
		self.defaultOutputModuleId = defaultOutputModuleId
		self.renderSingleFrame = renderSingleFrame
		self.frameToRender = frameToRender
	}
	
	func fixAtLoad () {
		renderSingleFrame = renderSingleFrame ?? false
		frameToRender = frameToRender ?? 0
		defaultRenderSettingId = defaultRenderSettingId ?? nil
		defaultOutputModuleId = defaultOutputModuleId ?? nil
	}
	
	func duplicate () -> BBAECompGroup {
		BBAECompGroup (name: name,
					   shortName: shortName)
	}
	
	var tempComp: BBAEComp {
		let tempTemplate = BBAEComp (name: name)
		tempTemplate.defaultOutputModuleId = defaultOutputModuleId ?? BBAESettings.shared.defaultOutputSettingsId
		tempTemplate.defaultRenderSettingId = defaultRenderSettingId ?? BBAESettings.shared.defaultRenderSettings
		tempTemplate.renderSingleFrame = renderSingleFrame ?? false
		tempTemplate.frameToRender = frameToRender ?? 0
		return tempTemplate
	}
	
	func update (withTempComp comp : 	BBAEComp) {
		self.defaultRenderSettingId = comp.defaultRenderSettingId
		self.defaultOutputModuleId = comp.defaultOutputModuleId
		self.renderSingleFrame = comp.renderSingleFrame
		self.frameToRender = comp.frameToRender
	}
}
