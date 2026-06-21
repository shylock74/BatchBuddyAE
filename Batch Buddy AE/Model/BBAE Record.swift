//
//  BBAEItem.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework

final class BBAERecord :   Codable,
					 UMSearchable {
	
	enum DisplayMode :	String, Codable {
		case normal
		case compact
	}
	
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
	

		
	var id =       	UMId.newId (useCounter: false)
	var name :		String = ""
	var compId :	String? =	nil{
		didSet {
			self.setupValues ()
			UMDispatch.notify (key: id)
		}
	}
	var status =	Status.toBeRendered {
		didSet {
			UMDispatch.notify (key: id)
		}
	}
	var recordFieldValueList =	[BBAERecordFieldValue] ()
	var displayMode :			DisplayMode = 	.normal
	var hidden :				Bool =			false
	
	
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case compId = "templateId"
		case status
		case recordFieldValueList = "instanceItemList"
		case displayMode
		case hidden
	}
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
		self.id = container.decodeString (forKey: .id, default: "")
		self.name = (try? container.decodeIfPresent (String.self,
													 forKey: .name)) ?? ""
		self.compId = (try? container.decodeIfPresent (String.self,
													   forKey: .compId)) ?? ""
		self.status = (try? container.decodeIfPresent (Status.self,
													   forKey: .status)) ?? .toBeRendered
		self.recordFieldValueList = (try? container.decodeIfPresent ([BBAERecordFieldValue].self,
															   forKey: .recordFieldValueList)) ?? []
		self.displayMode = (try? container.decodeIfPresent (DisplayMode.self,
													   forKey: .displayMode)) ?? .normal
		self.hidden = (try? container.decodeIfPresent (Bool.self, forKey: .hidden)) ?? false
	}
	
	func displayId () -> String {
		let textList = recordFieldValueList.filter { $0.isTextType || $0.type () == .recordId }.first
		if let textList = textList {
			return textList.fileSaveNameParticle
		}
		return id
	}
	
	func recordFileName () -> String {
		if name != "" {
			return name
		}
		
		let textList = recordFieldValueList.filter { $0.isTextType || $0.type () == .recordId }.first
		if let textList = textList {
			return textList.fileSaveNameParticle
		}
		return recordFieldValueList.reduce ("_", { $0 + $1.fileSaveNameParticle })
	}
	
	func suggestedRecordID () -> String {
		let vl = recordFieldValueList
		guard let suggestedText = vl.filter { $0.isTextType }.first?.textContent else { return "" }
		let suggestedTextWithNoCR = suggestedText.searchAndReplace (search: "\n", replaceWith: " ")
		return suggestedTextWithNoCR
	}
	
	init (comp :	BBAEComp?) {
		self.compId = comp?.id
		setupValues ()
	}
	
	func duplicate () -> BBAERecord {
		let duplicateItem = BBAERecord (comp: comp)
		duplicateItem.compId = compId
		duplicateItem.recordFieldValueList = recordFieldValueList.map { $0.duplicate () }
		return duplicateItem
	}

	var comp :	BBAEComp? {
		BBAEProject.getComp (withId: compId)
	}
	
	func getInstance (forTemplateItemId id :	String) -> BBAERecordFieldValue? {
		return recordFieldValueList.first { $0.compFieldId == id }
	}
	
 	func setupValues () {
		
		PerfAn.start (#function)
		defer {
			PerfAn.end ()
		}

		guard let comp = comp else {
			recordFieldValueList = []
			return
		}
		for field in comp.fieldList {
			if getInstance (forTemplateItemId: field.id) == nil {
				recordFieldValueList.append (BBAERecordFieldValue (templateItemId: field.id))
			}
		}
		let instanceItemListTemp = recordFieldValueList
		recordFieldValueList = []
		for field in comp.fieldList {
			recordFieldValueList.append (instanceItemListTemp.first { $0.compFieldId == field.id }!)
		}
	}

	
	func prepareConfigurationFile (url u:		URL?,
								   iteration :	Int?,
								   project :	BBAEProject) {
		guard let template = comp else { return }
		guard let u2 = template.customAEProjectUrl ?? u else { return }
		let url = u2.deletingLastPathComponent ().append (BBAESettings.shared.bbaeSubFolderName,
														  BBAESettings.shared.bbaeTextsFileName)
		fu_deleteFile (url)
		guard let comp = project.getComp (withId: compId) else { return }
		let fileText :	String
		if let iteration {
			fillRecordValueList (withIteration: iteration)
		}
		fileText = recordFieldValueList.reduce ("",
												{ $0 + $1.aeVariableAssignation (comp: comp,
																				 project: project,
																				 type: $1.type ()) })
		fu_writeTextToFile (url: url,
							text: fileText)
	}
	
	func prepareTemplateTextFile (url u:	URL?,
								  project :	BBAEProject) {
		guard let template = comp else { return }
		guard let u2 = template.customAEProjectUrl ?? u else { return }
		let url = u2.deletingLastPathComponent ().append (BBAESettings.shared.bbaeSubFolderName,
														  BBAESettings.shared.bbaeTextsFileName)
		fu_deleteFile (url)
		guard let template = project.getComp (withId: compId) else { return }
		let fileText = recordFieldValueList.reduce ("",
												{ $0 + $1.aeCompVariableAssignation (comp: template) })
		fu_writeTextToFile (url: url,
							text: fileText)
	}
	
	func prepareImages (project :	BBAEProject) {
		guard let template = comp else { return }
		let imageItemList = recordFieldValueList.filter { $0.type () == .image || $0.type () == .vectorAI }
		for imageItem in imageItemList {
			if let url = imageItem.url,
			   let templateItem = imageItem.templateItem (),
			   let templateCompItem = template.getCompItem (withId: imageItem.compFieldId) {
				if imageItem.type () == .image {
					project.saveImage (srcUrl: url,
									   compShortName: template.shortName,
									   dstName: templateItem.placeholderURLInBBAEFolderName (shortName: template.shortName),
									   customAEProjectUrl: comp?.customAEProjectUrl)
				} else {
					project.saveAI (srcUrl: url,
									compShortName: template.shortName,
									dstName: templateItem.placeholderURLInBBAEFolderName (shortName: template.shortName),
									customAEProjectUrl: comp?.customAEProjectUrl)
				}
			}
		}
	}
	
	func prepareVideos (project :	BBAEProject) {
		guard let template = comp else { return }
		let videoItemList = recordFieldValueList.filter { $0.type () == .video }
		for videoItem in videoItemList {
			if let url = videoItem.url,
			   let templateItem = videoItem.templateItem (),
			   let templateCompItem = template.getCompItem (withId: videoItem.compFieldId) {
				project.saveVideo (srcUrl: url,
								   compShortName: template.shortName,
								   dstName: templateItem.placeholderURLInBBAEFolderName (shortName: template.shortName),
								   customAEProjectUrl: comp?.customAEProjectUrl)
			}
		}
	}
	
	func prepareAudios (project :	BBAEProject) {
		guard let template = comp else { return }
		let videoItemList = recordFieldValueList.filter { $0.type () == .audio }
		for videoItem in videoItemList {
			if let url = videoItem.url,
			   let templateItem = videoItem.templateItem (),
			   let templateCompItem = template.getCompItem (withId: videoItem.compFieldId) {
				project.saveAudio (srcUrl: url,
								   compShortName: template.shortName,
								   dstName: templateItem.placeholderURLInBBAEFolderName (shortName: template.shortName),
								   customAEProjectUrl: comp?.customAEProjectUrl)
			}
		}
	}
	
	func prepareFiles (inProject project :	BBAEProject,
					   comp :				BBAEComp) {
		prepareConfigurationFile (url: comp.customAEProjectUrl ?? project.aeProjectFileUrl,
								  iteration: nil,
								  project: project)
		prepareImages (project: project)
		prepareVideos (project: project)
		prepareAudios (project: project)
	}
	
	func cellHeight () -> CGFloat {
		
		var adder :	CGFloat = 0
		if #available (OSX 11, *) {
			adder = 10
		}
//		if #available (OSX 26, *) {
//			adder = 20
//		}

//		return (comp?.instanceHeight () ?? 64) + 8 + adder
		return (recordFieldValueList.cellHeight ()) + 32 + 8 + adder

	}
	

	func umSearchContains (_ s: String) -> Bool {
		for instance in recordFieldValueList {
			if let t = instance.textContent?.lowercased (),
			   t.contains (s) {
				return true
			}
			if let t = instance.valueContentString?.lowercased (),
			   t.contains (s) {
				return true
			}
			if let path = instance.url?.path.lowercased (),
			   path.contains (s) {
				return true
			}
		}
		return false
	}
	
	var overrideRenderUrl :	URL? {
		guard let comp = comp,
			  comp.mediaInFieldList == true,
			  let compMediaField = (comp.fieldList.first { $0.id == comp.overrideRenderFolder.mediaFieldId }),
			  let recordField = (recordFieldValueList.first { $0.compFieldId == compMediaField.id }) else { return nil }
		let mediaUrl = recordField.url
		return mediaUrl?.parent
	}
	
//	func updateWithMissingFields (forComp comp :	BBAEComp) {
//		for compField in comp.fieldList {
//			let recordField = recordFieldValueList.first { $0.compFieldId == compField.id }
//			if recordField == nil {
//				recordFieldValueList.append (
//			}
//		}
//	}
	
	func iterationRange () -> ClosedRange <Int> {
		guard let comp = comp else { return 1 ... 1 }
		return comp.iterationRange
	}
	
	func fillRecordValueList (withIteration i :	Int) {
		guard let comp else { return }
		for compField in comp.fieldList {
			if compField.isIterator,
			   let recordField = (recordFieldValueList.first { $0.compFieldId == compField.id }),
			   recordField.iterator {
				recordField.valueContent = i.double
			}
		}
	}
	
	func mustIterate () -> Bool {
		guard let comp else { return false }
		var returnValue = false
		for compField in comp.fieldList {
			if compField.isIterator,
			   let recordField = (recordFieldValueList.first { $0.compFieldId == compField.id }),
			   recordField.iterator {
				returnValue = true
			}
		}
		return returnValue
	}
}
