//
//  BBAE Model.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Foundation
import UMOmniaFramework

class BBAESettings :	Codable {
    
	class AETemplate :	Codable {
		var id :			String =	UMId.newId (useCounter: false)
		var title :			String
		var fileExtension :	String?	=	""
		init (title :			String,
			  fileExtension :	String) {
			self.title = title
			self.fileExtension = fileExtension
		}
	}
	
    static let kDefaultKey =	"settings"
	static let shared =			BBAESettings ()
	
	var aeRenderEngineUrl :	URL? =		nil {
		didSet {
			if aeRenderEngineUrl != nil {
				UMAERender.setRenderEnginePath (aeRenderEngineUrl!.path)
			}
			save ()
		}
	}
	var aeCacheUrlList :	[URL?] =		[nil, nil, nil] {
		didSet {
			save ()
		}
	}
	var bbaeSubFolderName :	String =	"_BBAE" {
		didSet {
			save ()
		}
	}
	var bbaeTextsFileName :	String =	"bbae_texts.txt" {
		didSet {
			save ()
		}
	}
	var bbaeColorsFileName :	String =	"bbae_colors.txt" {
		didSet {
			save ()
		}
	}
	var defaultRenderSettings :	String? =	"Best Settings" {
		didSet {
			if let defaultRenderSettings = defaultRenderSettings {
				UMAERender.defaultRenderSettings = defaultRenderSettings
				save ()
			}
		}
	}
	var defaultOutputSettingsId :	String? =	nil {
		didSet {
			UMAERender.defaultOutputSettings = defaultOutputSettingsId!
			save ()
		}
	}
	
	var aeRenderSettingList :	[AETemplate]? = nil
	var aeOutputModuleList :	[AETemplate]? = nil
	
	var carriageReturnString =	"%RET%"

	enum AtLaunch :	String, Codable {
		case openLast
		case showRecents
	}
	
	var atLaunch :	AtLaunch = .showRecents
	
	struct RenderingStuff :	Codable {
		var reuseAE :					Bool =	true
		var autoSaveurrentDocument :	Bool =	true
		var autoSaveDelay :				Int =	10
	}
	
	var cleanCachesBeforeRendering :	Bool =		true
	var renderingStuff =				RenderingStuff ()
	
	var posterFrameAt :					Double = 10
	
	private enum CodingKeys: String, CodingKey {
		case aeRenderEngineUrl
		case aeCacheUrlList
		case bbaeSubFolderName
		case bbaeTextsFileName
		case bbaeColorsFileName
		case defaultRenderSettings
		case defaultOutputSettingsId = "defaultOutputSettings"
		case aeRenderSettingList
		case aeOutputModuleList
		case atLaunch
		case renderingStuff
		case carriageReturnString
		case cleanCachesBeforeRendering
		case posterFrameAt
	}
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
		self.aeRenderEngineUrl = (try? container.decodeIfPresent (URL.self,
																  forKey: .aeRenderEngineUrl))
		self.aeCacheUrlList = (try? container.decodeIfPresent ([URL].self,
																  forKey: .aeCacheUrlList)) ?? []
		self.bbaeSubFolderName = (try? container.decodeIfPresent (String.self,
															   forKey: .bbaeSubFolderName)) ?? "_BBAE"
		self.bbaeTextsFileName = (try? container.decodeIfPresent (String.self,
																  forKey: .bbaeTextsFileName)) ?? "bbae_texts.txt"
		self.bbaeColorsFileName = (try? container.decodeIfPresent (String.self,
																  forKey: .bbaeColorsFileName)) ?? "bbae_colors.txt"
		self.defaultRenderSettings = (try? container.decodeIfPresent (String.self,
																   forKey: .defaultRenderSettings)) ?? "Best Settings"
		self.defaultOutputSettingsId = (try? container.decodeIfPresent (String.self,
																	  forKey: .defaultOutputSettingsId))
		self.aeRenderSettingList = (try? container.decodeIfPresent ([AETemplate].self,
															   forKey: .aeRenderSettingList)) ?? []
		self.aeOutputModuleList = (try? container.decodeIfPresent ([AETemplate].self,
																	forKey: .aeOutputModuleList)) ?? []
		self.atLaunch = (try? container.decodeIfPresent (AtLaunch.self,
														 forKey: .atLaunch)) ?? .showRecents
		self.renderingStuff = (try? container.decodeIfPresent (RenderingStuff.self,
															   forKey: .renderingStuff)) ?? RenderingStuff ()
		self.cleanCachesBeforeRendering = (try? container.decodeIfPresent (Bool.self,
														forKey: .cleanCachesBeforeRendering)) ?? false
		self.carriageReturnString = (try? container.decodeIfPresent (String.self,
																   forKey: .carriageReturnString)) ?? "%RET%"
		self.posterFrameAt = (try? container.decodeIfPresent (Double.self,
															  forKey: .posterFrameAt)) ?? 10
	}
	
	init () {
		
		UMAERender.defaultRenderSettings = defaultRenderSettings!
		if let os = (aeOutputModuleList?.first { $0.id == defaultOutputSettingsId }?.title) {
			UMAERender.defaultOutputSettings = os
		}
		
		let s = UMPrefsStorage.getValueString (key: Self.kDefaultKey,
									  defaultValue: "")
		guard let d = s.data (using: .utf8) else { return }
		guard let decoded = try? JSONDecoder ().decode (Self.self,
														from: d) else { return }
		aeRenderEngineUrl = decoded.aeRenderEngineUrl
		aeCacheUrlList = decoded.aeCacheUrlList
		bbaeSubFolderName = decoded.bbaeSubFolderName
		bbaeTextsFileName = decoded.bbaeTextsFileName
		defaultRenderSettings = decoded.defaultRenderSettings
		defaultOutputSettingsId = decoded.defaultOutputSettingsId
		aeRenderSettingList = decoded.aeRenderSettingList ?? []
		aeOutputModuleList = decoded.aeOutputModuleList ??  []
		aeCacheUrlList = decoded.aeCacheUrlList ?? [URL (fileURLWithPath: ""), URL (fileURLWithPath: ""), URL (fileURLWithPath: "")]
		
		UMAERender.defaultRenderSettings = defaultRenderSettings ?? UMAERender.defaultRenderSettings
		UMAERender.defaultOutputSettings = aeOutputModuleList?.first { $0.id == defaultOutputSettingsId }?.title ?? UMAERender.defaultOutputSettings

		atLaunch = decoded.atLaunch
		renderingStuff = decoded.renderingStuff
		posterFrameAt = decoded.posterFrameAt
	}
	
	func save () {
		let s = JU.encodeToString (self)
		UMPrefsStorage.setValueString (key: Self.kDefaultKey,
							  value: s)
		NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsChanged"), object: nil)
	}
	
	func getLayerColorToBePasted (index idx :	Int) -> String {
		let url = Bundle.main.url (forResource: "AETextLayerColor",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%INDEX%%",
										 replace: String (idx))
		return aeCode
	}
	
	func getLayerTextToBePasted (index idx :	Int) -> String {
		let url = Bundle.main.url (forResource: "AETextLayerTemplate",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%INDEX%%",
										 replace: String (idx))
		
//		if let color = color  {
			aeCode = strUt_searchAndReplace (originalText: aeCode,
											 search: "%%COLOR%%",
											 replace: getLayerColorToBePasted (index: idx))
//
//		}
		return aeCode
	}
	
	func getColorFileString (colorList :	[BBAEProjectColor]) -> String {
		var t = ""
		for color in colorList {
			t += color.aeVariableAssignation + "\n"
		}
		return t
	}

	func getColorAECodeString (color :	BBAEProjectColor) -> String {
		let url = Bundle.main.url (forResource: "AETextColorCodeToPaste",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAECOLORFILENAME%%",
										 replace: bbaeColorsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: color.aeVariableName)
		return aeCode
	}
	
	func getTextAECodeString (item :	BBAECompField) -> String {
		let url = Bundle.main.url (forResource: "AETextLayerTemplate",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: item.variableName ())
		return aeCode
	}
	
	func getNumberAECodeString (item :	BBAECompField) -> String {
		let url = Bundle.main.url (forResource: "AENumberLayerTemplate",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: item.variableName ())
		return aeCode
	}
	
	func getColorFillString (color :	BBAEProjectColor) -> String {
		let url = Bundle.main.url (forResource: "AEColorFill",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAECOLORFILENAME%%",
										 replace: bbaeColorsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: color.aeVariableName)
		return aeCode
	}
	
	func getDynamicColorFillString (variableName :	String) -> String {
		let url = Bundle.main.url (forResource: "AEDynamicColorFill",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: "\(variableName)")
		return aeCode
	}
	
	func getDynamicCheckboxVisibilityCodeString (variableName :	String) -> String {
		let url = Bundle.main.url (forResource: "AECheckboxOpacity",
								   withExtension: "txt")!
		let aeCodeTemplate = fu_readTextFile (url: url)
		var aeCode = aeCodeTemplate
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBASESUBFOLDER%%",
										 replace: bbaeSubFolderName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%BBAEFILENAME%%",
										 replace: bbaeTextsFileName)
		aeCode = strUt_searchAndReplace (originalText: aeCode,
										 search: "%%VARIABLENAME%%",
										 replace: "\(variableName)")
		return aeCode
	}
	
	
	func renderSettingsName (_ id :	String?) -> String? {
		guard let id = id else { return nil }
		return aeRenderSettingList?.first { $0.id == id }?.title
	}
	
	func outputModuleName (_ id :	String?) -> String? {
		guard let id = id else { return nil }
		return aeOutputModuleList?.first { $0.id == id }?.title
	}
	
	func outputModuleExtension (_ id :	String?) -> String? {
		guard let id = id else { return nil }
		let ext = aeOutputModuleList?.first { $0.id == id }?.fileExtension
		return ext
	}
	
	func deleteCaches () {
		if cleanCachesBeforeRendering {
			for i in 0 ..< aeCacheUrlList.count {
				if let url = aeCacheUrlList [i] {
					fu_deleteFile (url)
					fu_createFolder (url)
				}
			}
		}
	}
	
	func cacheExists (_ index :	Int) -> Bool {
		guard index < aeCacheUrlList.count,
			  let url = aeCacheUrlList [index] else { return false }
		return fu_fileExists (url: url)
	}
	
	func setCacheUrl (forIndex index :	Int,
					  url :				URL) {
		if index >= aeCacheUrlList.count {
			for i in aeCacheUrlList.count - 1 ..< 3 {
				aeCacheUrlList.append (nil)
			}
		}
		aeCacheUrlList [index] = url
	}
	
	func aeRenderExists () -> Bool {
		guard let aeRenderEngineUrl = aeRenderEngineUrl else { return false }
		return fu_fileExists (url: aeRenderEngineUrl)
	}
}
