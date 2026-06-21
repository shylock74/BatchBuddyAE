//
//  BBAE_Model.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework
import UMImaging
import UMMovie

class BBAEText :	Codable {
	var text :		String =	""
	var colorId :	String?
	
	init (text :	String,
		  colorId :	String? = nil) {
		self.text = text
		self.colorId = colorId
	}
}



class BBAEProject :    Codable {
	
	static let shared =				BBAEProject ()
	static let renderQueue =		DispatchQueue (label: "media.ulti.bbae.renderqueue")
	
	static var projectList =		[BBAEProject] ()
	
	struct Naming :	Codable {
		var globalPrefix :	String =	""
		var globalMidfix :	String =	""
		var globalSuffix :	String =	""
	}
	
	var id =							UMId.newId (useCounter: false)
	var url :							URL =		URL (fileURLWithPath: "")
	var name :							String =	""
	var aeProjectFileUrl :				URL? = 		nil
	var compList =						[BBAEComp] ()
	var compGroupList :					[BBAECompGroup]? = 	[]
	var recordList =					[BBAERecord] ()
	var colorList =						[BBAEProjectColor] ()
	var renderFolder_ :					URL = 		fu_getDocumentsFolderURL ().append ("_BBAE Render")
	var lastTemplateId :				String? =	nil
	var sarFolderUrl :					URL? = 		nil
	var renderInSubfolders :			Bool =		false
	var useFullCompNameForSubfolder :	Bool =	false
	var naming :						Naming	=	Naming ()
	
	var customAERenderUrl :				URL?
	var customAEUseRosetta :			Bool =	false
	
	var toBeRenderedCount =		0
	var renderedCount =			0

	let updateTaskQueue =	UMPressureTask ()

	private enum CodingKeys: String, CodingKey {
		case id
		case url
		case name
		case aeProjectFileUrl
		case compList = "templateList"
		case compGroupList = "templateGroupList"
		case recordList = "itemInstanceList"
		case colorList
		case renderFolder_
		case lastTemplateId
		case sarFolderUrl
		case renderInSubfolders
		case useFullCompNameForSubfolder
		case naming
		case customAERenderUrl
		case customAEUseRosetta
	}
	
	var renderFolder :		URL {
		renderFolder_.append (name + " Render Files")
	}
	
	var statusUpdateKey :	String {
		"media.ulti.project.\(id).statusUpdate"
	}
	
	init () {
		print ()
	}
	
	init (url :		URL,
		  name :	String) {
		self.url = url
		self.name = name
		save ()
		BBAEProject.addProjectToList (self)
		
		UMNotify.addRarify (keyword: statusUpdateKey)
	}
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
		self.id = container.decodeString (forKey: .id, default: "")
		self.url = (try? container.decodeIfPresent (URL.self,
													forKey: .url)) ?? URL (fileURLWithPath: "")
		self.name = (try? container.decodeIfPresent (String.self,
													 forKey: .name)) ?? ""
		self.aeProjectFileUrl = (try? container.decodeIfPresent (URL.self,
																 forKey: .aeProjectFileUrl))
		self.compList = (try? container.decodeIfPresent ([BBAEComp].self,
														 forKey: .compList)) ?? []
		self.compGroupList = (try? container.decodeIfPresent ([BBAECompGroup].self,
															  forKey: .compGroupList)) ?? []
		self.recordList = (try? container.decodeIfPresent ([BBAERecord].self,
														   forKey: .recordList)) ?? []
		self.colorList = (try? container.decodeIfPresent ([BBAEProjectColor].self,
														  forKey: .colorList)) ?? []
		self.renderFolder_ = (try? container.decodeIfPresent (URL.self,
															  forKey: .renderFolder_)) ?? fu_getDocumentsFolderURL ().append ("_BBAE Render")
		self.lastTemplateId = (try? container.decodeIfPresent (String.self,
															   forKey: .lastTemplateId))
		self.sarFolderUrl = (try? container.decodeIfPresent (URL.self,
															 forKey: .sarFolderUrl))
		self.renderInSubfolders = (try? container.decodeIfPresent (Bool.self,
																   forKey: .renderInSubfolders)) ?? false
		self.useFullCompNameForSubfolder = (try? container.decodeIfPresent (Bool.self,
																   forKey: .useFullCompNameForSubfolder)) ?? false
		self.naming = (try? container.decodeIfPresent (BBAEProject.Naming.self,
													   forKey: .naming)) ?? BBAEProject.Naming ()
		self.customAERenderUrl = (try? container.decodeIfPresent (URL.self, forKey: .customAERenderUrl)) ?? nil
		self.customAEUseRosetta = (try? container.decodeIfPresent (Bool.self, forKey: .customAEUseRosetta)) ?? false

		toBeRenderedCount = 0
		renderedCount = 0
		
		UMNotify.addRarify (keyword: statusUpdateKey)
	}
	
	func updateBBAEFieldsGlobalList () {
		BBAECompField.compFieldList = []
		compList.forEach {
			$0.fieldList.forEach {
				BBAECompField.addFieldToGlobalList ($0)
			}
			$0.loaded ()
		}
	}
	
	func updateValuesAfterStructureChange () {
		updateBBAEFieldsGlobalList ()
		recordList.forEach {
			$0.setupValues ()
		}
	}
	
	init? (url :	URL) {
		guard let decoded = Self.shared.load (url: url) else { return nil }
		id = decoded.id
		self.url = url
		name = decoded.name
		aeProjectFileUrl = decoded.aeProjectFileUrl
		recordList = decoded.recordList
		compList = decoded.compList
		colorList = decoded.colorList
		renderFolder_ = decoded.renderFolder_
		renderInSubfolders = decoded.renderInSubfolders //?? false
		useFullCompNameForSubfolder = decoded.useFullCompNameForSubfolder
		customAERenderUrl = decoded.customAERenderUrl
		BBAEProject.addProjectToList (self)
		updateBBAEFieldsGlobalList ()
		updateValuesAfterStructureChange ()
		compGroupList = compGroupList ?? []
		
		UMNotify.addRarify (keyword: statusUpdateKey)
	}
	
	static func addProjectToList (_ project :	BBAEProject) {
		projectList = projectList.filter { $0.id != project.id }
		projectList.append (project)
	}
	
	static func getProject (withId id :	String?) -> BBAEProject? {
		guard let id = id else { return nil }
		return projectList.first { $0.id == id }
	}
	
	static func getComp (withId id :	String?) -> BBAEComp? {
		guard let id = id else { return nil }
		for project in projectList {
			if let comp = (project.compList.first { $0.id == id }) {
				return comp
			}
		}
		return nil
	}
	
	func save () {
		_ = JU.encodeToFile (self,
							 url: url)
	}
	
	func load (url :	URL) -> BBAEProject? {
		return JU.decodeFromURL (url, type: self)
	}
	
	func getComp (withId id :	String?) -> BBAEComp? {
		guard id != nil else { return nil }
		return compList.first { $0.id == id }
	}
	
	// MARK: - Render
	func renderFileUrl (_ item :		BBAERecord,
						templateGroup :	BBAECompGroup?,
						fileExtension :	String?) -> URL {
		
		let template = getComp (withId: item.compId!)!
		let shortname = templateGroup != nil
		? useFullCompNameForSubfolder ? templateGroup!.name : templateGroup!.shortName
		: useFullCompNameForSubfolder ? template.name : template.shortName
		let fileItemName = item.recordFileName ()
		var ext = ""
		if fileExtension == nil {
			ext = ".mov"
		} else {
			if !["jpg", "jpeg", "png"].contains (fileExtension!.lowercased ()) {
				ext = "." + fileExtension!
			} else {
				ext = ".mov"
			}
		}
		
		var url = renderFolder
		if template.overrideRenderFolder.override,
		   let overrideRenderUrl = item.overrideRenderUrl {
			url = overrideRenderUrl
		}
		
		if renderInSubfolders {
			url = url.append (shortname)
		}
		
		let finalFileName = (naming.globalPrefix != "" ? (naming.globalPrefix + "_") : "")
		+ shortname
		+ (naming.globalMidfix != "" ? ("_" + naming.globalMidfix + "_") : "")
		+ "_" + fileItemName
		+ (naming.globalSuffix != "" ? ("_" + naming.globalSuffix) : "")
		+ ext
		
		url = url.append (finalFileName)
		return url
	}
	
	func render (record :			BBAERecord,
				 withComp comp :	BBAEComp,
				 callback :			@escaping (Bool, String) -> ()) {
		
		if BBAESettings.shared.renderingStuff.autoSaveurrentDocument {
			UMApplescript.launch (scriptName: "AESave")
			sleep (UInt32 (BBAESettings.shared.renderingStuff.autoSaveDelay))
		}
		
		let templateName = comp.name
		var renderDoneSuccesfully = true
		var log = ""
		
		var canContinue = true
		if comp.isGroup == true {
			BBAERenderingVC.setTotalCount (toBeRenderedCount)
			for i in 0 ..< comp.compGroupList!.count {
				
				let templateGroup = comp.compGroupList! [i]
				if !templateGroup.active {
				} else {
					let s = UMSemaphore ()
					BBAERenderingVC.setCurrentItemN (renderedCount)
					while !canContinue {
						sleep (1)
					}
					
					let renderFileUrl = self.renderFileUrl (record,
															templateGroup: templateGroup,
															fileExtension: comp.outputModuleExtension ())
					BBAERenderingVC.setTitle ("Rendering comp: \(templateGroup.name)")
					BBAERenderingVC.setRecord ("Record: \(fu_getFileNameWithoutExtension (renderFileUrl.lastPathComponent))")
					BBAERenderingVC.setStatus ("Setting up...")
					
					UMNotify.notify (keyword: statusUpdateKey,
									 sender: self,
									 string: "AE Rendering (\(i + 1)/\(comp.compGroupList!.count)) \(record.recordFileName ().bound (toMaxLength: 30))...")
					
					let recordComp = templateGroup.tempComp
					
					let frameToRenderIndex : Int? = (recordComp.renderSingleFrame == true)
					? recordComp.frameToRender ?? 0
					: nil
					canContinue = false
					
					BBAERenderingVC.setFileSize (0)
					
					let customProjectUrl = comp.customAEProjectUrl ?? self.aeProjectFileUrl!
					UMAERender.render (projectUrl: self.aeProjectFileUrl!,
									   compName: templateGroup.name,
									   renderedFileURL: renderFileUrl,
									   startFrame: frameToRenderIndex,
									   endFrame: frameToRenderIndex,
									   renderSettings: recordComp.renderSettings (),
									   outputSettings: recordComp.outputModule (),
									   reuseAE: BBAESettings.shared.renderingStuff.reuseAE,
									   customAERenderUrl: customAERenderUrl,
									   progressCallback: { f, rt in
						BBAERenderingVC.setStatus ("Rendering: frame \(f)")
						if rt != 0 {
							BBAERenderingVC.setStats ("(avg: \(rt.round (digits: 2))s per frame, \((1 / rt).round (digits: 1)) fps)")
						}
						if let framesCount = templateGroup.supposedFrameCount {
							BBAERenderingVC.setItemPercentage (min (Double (f) / Double (framesCount), 0.99))
							if let renderedFileSize = fu_getFileSize (url: renderFileUrl) {
								BBAERenderingVC.setFileSize (renderedFileSize)
							}
						}
					}) { done, errorLog, frameCount in
						self.notifyUpdate ()
						self.renderedCount += 1
						canContinue = true
						renderDoneSuccesfully = renderDoneSuccesfully && done
						if errorLog != "" {
							log += errorLog + "\n"
						} else {
							templateGroup.supposedFrameCount = frameCount
						}
						s.release ()
					}
					s.wait ()
				}
			}
			UMNotify.notify (keyword: statusUpdateKey,
							 sender: self,
							 string: "")
			callback (renderDoneSuccesfully, log)
		} else {
			
			//NON GRUPPO
			
			let renderFileUrl = self.renderFileUrl (record,
													templateGroup: nil,
													fileExtension: comp.outputModuleExtension ())
			BBAERenderingVC.setTitle ("Rendering comp: \(comp.name)")
			BBAERenderingVC.setStatus ("Setting up...")
			BBAERenderingVC.setRecord ("Record: \(fu_getFileNameWithoutExtension (renderFileUrl.lastPathComponent))")
			UMNotify.notify (keyword: statusUpdateKey,
							 sender: self,
							 string: "AE Rendering \(record.recordFileName ().bound (toMaxLength: 34))...")
			
			let frameToRenderIndex : Int? = (comp.renderSingleFrame == true)
			? comp.frameToRender ?? 0
			: nil
			
//			let s = UMSemaphore ()
			BBAERenderingVC.setFileSize (0)
			let customProjectUrl = comp.customAEProjectUrl ?? self.aeProjectFileUrl!
			UMAERender.render (projectUrl: customProjectUrl,
							   compName: templateName,
							   renderedFileURL: renderFileUrl,
							   startFrame: frameToRenderIndex,
							   endFrame: frameToRenderIndex,
							   renderSettings: comp.renderSettings (),
							   outputSettings: comp.outputModule (),
							   reuseAE: BBAESettings.shared.renderingStuff.reuseAE,
							   customAERenderUrl: customAERenderUrl,
							   progressCallback: { progressCallback (f: $0, rt: $1, renderFileUrl: renderFileUrl) },
							   callback: doneCallback)
		}
		
		func progressCallback (f :				Int,
							   rt :				Double,
							   renderFileUrl :	URL) {
			BBAERenderingVC.setStatus ("Rendering: frame \(f)")
			if rt != 0 {
				BBAERenderingVC.setStats ("(avg: \(rt.round (digits: 2))s per frame, \((1 / rt).round (digits: 1)) fps)")
			}
			if let framesCount = comp.supposedFramesCount {
				BBAERenderingVC.setItemPercentage (min (Double (f) / Double (framesCount), 0.99))
				if let renderedFileSize = fu_getFileSize (url: renderFileUrl) {
					BBAERenderingVC.setFileSize (renderedFileSize)
				}
			}
		}
		
		func doneCallback (done :		Bool,
						   errorLog :	String,
						   frameCount :	Int) {
			renderDoneSuccesfully = renderDoneSuccesfully && done
			if errorLog != "" {
				log += errorLog + "\n"
			} else {
				comp.supposedFramesCount = frameCount
			}
			record.status = done ? .rendered : .toBeRendered
			self.notifyUpdate ()
			self.renderedCount += 1
			
			UMNotify.notify (keyword: statusUpdateKey,
							 sender: self,
							 string: "")
			callback (renderDoneSuccesfully, log)
		}
	}
	
	func renderRecord (_ record :	BBAERecord,
					   callback :	@escaping (Bool, String) -> ()) {
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Setting Up \(record.recordFileName ())")
		
		let template = getComp (withId: record.compId!)!
		
		record.status = .rendering
		record.prepareImages (project: self)
		record.prepareVideos (project: self)
		record.prepareAudios (project: self)
		saveColorFile (customAEProjectUrl: template.customAEProjectUrl)
		
		if !template.mustIterate ||
			!record.mustIterate () {
			
			record.prepareConfigurationFile (url: self.aeProjectFileUrl,
											 iteration: nil,
											 project: self)
			BBAESettings.shared.deleteCaches ()
			notifyUpdate ()
			render (record: record,
					withComp: template) { done, errorLog in
				callback (done, errorLog)
				self.save ()
				UMNotify.notify (keyword: self.statusUpdateKey,
								 sender: self,
								 string: "")
			}
			
		} else {
			let range = template.iterationRange
			let count = range.count
			var doneCount = 0
			var allDone = true
			for i in range {
				record.prepareConfigurationFile (url: self.aeProjectFileUrl,
												 iteration: i,
												 project: self)
				BBAESettings.shared.deleteCaches ()
				notifyUpdate ()
				render (record: record,
						withComp: template) { done, errorLog in
					allDone = allDone && done
					doneCount += 1
					if doneCount == count {
						callback (allDone, errorLog)
						self.save ()
						UMNotify.notify (keyword: self.statusUpdateKey,
										 sender: self,
										 string: "")
					}
				}
			}
		}
	}
	
	func renderPlaceholderItem (_ item :	BBAERecord,
								callback :	@escaping (Bool) -> ()) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Setting Strings")
		
		let template = getComp (withId: item.compId!)!
//		let templateName = template.name
		item.status = .rendering
		item.prepareTemplateTextFile (url: self.aeProjectFileUrl,
									  project: self)
		saveColorFile (customAEProjectUrl: template.customAEProjectUrl)
		notifyUpdate ()
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "")
	}
	
	func renderItemsNeedingRender (callback :	@escaping (Bool, String) -> ()) {
		
		var allSucceded = true
		var log = ""
		var idx = -1

		func loopCallback (success :	Bool,
						   errorLog :	String) {
			idx += 1
			allSucceded = allSucceded && success
			if errorLog != "" {
				log += errorLog + "\n"
			}
			
			if idx == itemToRenderList.count - 1 {
				callback (allSucceded, log)
				BBAERenderingVC.hide ()
			}
		}
		
		let itemToRenderList = recordList.filter { $0.status == .toBeRendered }
		toBeRenderedCount = 0
		renderedCount = 0
		for itemToRender in itemToRenderList {
			if itemToRender.comp?.isGroup == true {
				toBeRenderedCount += itemToRender.comp?.compGroupList?.filter { $0.active }.count ?? 0
			} else {
				toBeRenderedCount += 1
			}
		}
		
		Queue.execute { [self] in
			BBAERenderingVC.setTotalCount (toBeRenderedCount)
			for item in itemToRenderList {
				BBAERenderingVC.setCurrentItemN (renderedCount)
				renderRecord (item,
							  callback: loopCallback)
			}
		}
	}
	
	// MARK: - Duplicate
	func duplicateItem (_ id :	String) {
		guard let item = (recordList.first { $0.id == id }) else { return }
		let duplicateItem = item.duplicate ()
		recordList.append (duplicateItem)
	}
	
	// MARK: - New, Open, Startup
	static func new (callback :	@escaping (BBAEProject) -> ()) {
		UMFileDialogs.save (title: "New Project",
							message: "Please select where to save the new project and the name of the file.",
							suggestedFileName: "Untitled.bbae",
							availableExtensions: ["bbae"],
							extensionHidden: false) { url in
			guard let url = url else { return }
			let bbaeProject = BBAEProject (url: url,
										   name: fu_getFileNameWithoutExtension (url.lastPathComponent))
			lastProjectUrl = url.path
			callback (bbaeProject)
		}
	}
	
	static func open (callback :	@escaping (BBAEProject) -> ()) {
		UMFileDialogs.open (title: "open Project",
							message: "***",
							availableExtensions: ["bbae"]) { url in
			guard let bbaeProject = BBAEProject (url: url) else { return }
			lastProjectUrl = url.path
			callback (bbaeProject)
		}
	}
	
	@UMDef (key: "lastProjectUrl", def: "") static var lastProjectUrl :	String
	
	static func startup (callback :	@escaping (BBAEProject) -> ()) {
		guard lastProjectUrl != "" else { return }
		let url = URL (fileURLWithPath: lastProjectUrl)
		guard let bbaeProject = BBAEProject (url: url) else { return }
		callback (bbaeProject)
	}
	
	func getColor (_ colorId :	String) -> BBAEProjectColor? {
		return colorList.first { $0.id == colorId }
	}
	
	func notifyUpdate (andSave :	Bool = true) {
		updateTaskQueue.perform (after: 0.25) { [self] in
			if andSave {
				save ()
			}
			UMDispatch.notify (key: "media.ulti.bbae.projectUpdate.\(id)")
		}
	}
	
	func observeUpdate (observerId :String =	UMId.newId (),
						callback :	@escaping () -> ()) {
		UMDispatch.observe (key: "media.ulti.bbae.projectUpdate.\(id)",
							myId: observerId,
							callback: callback)
	}
	
	func saveColorFile (customAEProjectUrl :	URL?) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Setting Colors")
		
		guard let aeProjectFileUrl = aeProjectFileUrl else { return }
		let text = BBAESettings.shared.getColorFileString (colorList: colorList)
		let url = customAEProjectUrl ?? aeProjectFileUrl
			.deletingLastPathComponent ()
			.append (BBAESettings.shared.bbaeSubFolderName,
					 BBAESettings.shared.bbaeColorsFileName)
		fu_deleteFile (url)
		fu_createFolderIfNeeded (url: url)
		fu_writeTextToFile (url: url,
							text: text)
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "")
	}
	
	func dynamicImageUrl (compShortName :		String,
						  name :				String,
						  customAEProjectUrl :	URL?) -> URL? {
		guard let aeProjectFileUrl = (customAEProjectUrl ?? aeProjectFileUrl) else { return nil }
		let url = aeProjectFileUrl
			.deletingLastPathComponent ()
			.append (BBAESettings.shared.bbaeSubFolderName,
					 compShortName,
					 fu_getFileNameWithoutExtension (name) + ".png")
		return url
	}
	
	func dynamicAIUrl (compShortName :		String,
					   name :				String,
					   customAEProjectUrl :	URL?) -> URL? {
		guard let aeProjectFileUrl = (customAEProjectUrl ?? aeProjectFileUrl) else { return nil }
		let url = aeProjectFileUrl
			.deletingLastPathComponent ()
			.append (BBAESettings.shared.bbaeSubFolderName,
					 compShortName,
					 fu_getFileNameWithoutExtension (name) + ".ai")
		return url
	}
	
	func saveImage (srcUrl :				URL,
					compShortName :			String,
					dstName :				String,
					customAEProjectUrl :	URL?) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Preparing Image \(srcUrl.lastPathComponent)")
		
		guard let image = UMImage (srcUrl) else { return }
		guard let dstUrl = dynamicImageUrl (compShortName: compShortName,
											name: dstName,
											customAEProjectUrl: customAEProjectUrl) else { return }
		fu_createFolderIfNeeded (url: dstUrl)
		_ = image.saveToPNG (url: dstUrl)
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Image done.")
	}
	
	func saveAI (srcUrl :				URL,
				 compShortName :		String,
				 dstName :				String,
				 customAEProjectUrl :	URL?) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Preparing AI \(srcUrl.lastPathComponent)")
		
		guard let dstUrl = dynamicAIUrl (compShortName: compShortName,
										 name: dstName,
										 customAEProjectUrl: customAEProjectUrl) else { return }
		fu_createFolderIfNeeded (url: dstUrl)
		fu_copyFile (srcURL: srcUrl, dstURL: dstUrl)
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "AI done.")
	}
	
	func dynamicImageVideo (compShortName :			String,
							name :					String,
							customAEProjectUrl :	URL?) -> URL? {
		guard let aeProjectFileUrl = (customAEProjectUrl ?? aeProjectFileUrl) else { return nil }
		let url = aeProjectFileUrl
			.deletingLastPathComponent ()
			.append (BBAESettings.shared.bbaeSubFolderName,
					 compShortName,
					 fu_getFileNameWithoutExtension (name) + ".mov")
		return url
	}
	
	func dynamicImageAudio (compShortName :			String,
							name :					String,
							customAEProjectUrl :	URL?) -> URL? {
		guard let aeProjectFileUrl = (customAEProjectUrl ?? aeProjectFileUrl) else { return nil }
		let url = aeProjectFileUrl
			.deletingLastPathComponent ()
			.append (BBAESettings.shared.bbaeSubFolderName,
					 compShortName,
					 fu_getFileNameWithoutExtension (name) + ".wav")
		return url
	}
	
	func saveVideo (srcUrl :				URL,
					compShortName :			String,
					dstName :				String,
					customAEProjectUrl :	URL?) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Preparing Video \(srcUrl.lastPathComponent)")
		
		guard let dstUrl = dynamicImageVideo (compShortName: compShortName,
											  name: dstName,
											  customAEProjectUrl: customAEProjectUrl) else { return }
		fu_createFolderIfNeeded (url: dstUrl)
		fu_deleteFile (dstUrl)
		fu_copyFile (srcURL: srcUrl, dstURL: dstUrl)
		
		let s = UMSemaphore ()
		Queue.execute (after: 2) {
			s.release ()
		}
		s.wait ()
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Video done.")
	}
	
	func saveAudio (srcUrl :				URL,
					compShortName :			String,
					dstName :				String,
					customAEProjectUrl :	URL?) {
		
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Preparing Audio \(srcUrl.lastPathComponent)")
		
		guard let dstUrl = dynamicImageAudio (compShortName: compShortName,
											  name: dstName,
											  customAEProjectUrl: customAEProjectUrl) else { return }
		fu_createFolderIfNeeded (url: dstUrl)
		fu_deleteFile (dstUrl)
		fu_copyFile (srcURL: srcUrl, dstURL: dstUrl)
		let s = UMSemaphore ()
		Queue.execute (after: 2) {
			s.release ()
		}
		s.wait ()
		UMNotify.notify (keyword: statusUpdateKey,
						 sender: self,
						 string: "Audio done.")
	}
	
	func duplicateTemplate (_ template :	BBAEComp) {
		let copy = template.duplicate ()
		compList.append (copy)
		save ()
	}
	
	func importCompTemplate (_ url :	URL) {
		guard let compTemplate = BBAEComp.shared.load (fromUrl: url) else { return }
		compList.append (compTemplate)
	}
}


extension BBAEProject {
	
	func aepFilePresent () -> Bool {
		guard let aeProjectFileUrl = aeProjectFileUrl else { return false }
		return fu_fileExists (url: aeProjectFileUrl)
	}
}


extension BBAEProject {
	
	func deleteAllRecords () {
		recordList = []
		notifyUpdate ()
	}
	
	func openAEproject () {
		guard let aePath = aeProjectFileUrl?.path else { return }
		_ = shell (launchPath: "/usr/bin/open",
				   arguments: [aePath])
	}
}


extension BBAEProject {
	
	func setDisplayModeForAllRecord (_ displayMode :	BBAERecord.DisplayMode) {
		for record in recordList {
			record.displayMode = displayMode
		}
	}
}
