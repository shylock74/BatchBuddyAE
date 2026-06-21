//
//  BBAETEmplateInstanceItem.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Foundation
import UMOmniaFramework


final class BBAERecordFieldValue :	Codable {
	
	var id =				UMId.newId (useCounter: false)
	var compFieldId :		String =	""
	var textContent :		String? =	nil
	var valueContent :		Double? =	nil
	var colorId :			String? =	nil
	var customColor :		UMColor? =	nil
	var url :				URL?
	var iterator :			Bool =		false
	var showAsLargeText :	Bool =		false
	
	private enum CodingKeys: String, CodingKey {
		case id
		case compFieldId = "templateItemId"
		case textContent
		case valueContent
		case colorId
		case customColor
		case url
		case iterator
		case showAsLargeText
	}

	var formattedTextContent :	String {
		guard let textContent = textContent else {
			return ""
		}
		let t = textContent
			.searchAndReplace (search: "\\", replaceWith: "\\\\")
			.searchAndReplace (search: "\n", replaceWith: "\\n")
			.searchAndReplace (search: "\r", replaceWith: "\\n")
			.searchAndReplace (search: "\"", replaceWith: "\\\"")
			.searchAndReplace (search: BBAESettings.shared.carriageReturnString, replaceWith: "\\n")
		return t
	}
	
	var valueContentString :	String? {
		valueContent != nil
			? String (valueContent!)
			: nil
	}
	
	init (templateItemId :	String,
		  textContent :		String? =	nil,
		  valueContent :	Double? =	nil,
		  url :				URL? =		nil,
		  colorId :			String? =	nil) {
		self.compFieldId = templateItemId
		self.textContent = textContent
		self.valueContent = valueContent
		self.url = url
		self.colorId = colorId
		
		if let compField = BBAECompField.getField (withId: templateItemId) {
			if type () == .numericValue {
				if let defaultNumericValue = compField.defaultNumericValue {
					self.valueContent = defaultNumericValue
				}
			} else if type () == .text || type () == .longText {
				if let defaultTextValue = compField.defaultTextValue {
					self.textContent = defaultTextValue
				}
				if type () == .text {
					self.showAsLargeText = false
				} else {
					self.showAsLargeText = true
				}
			}
		}
	}
	
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
//		self.id = (try? container.decodeIfPresent (String.self,
//												   forKey: .id)) ?? ""
		self.id = container.decodeString (forKey: .id, default: "")
		self.compFieldId = (try? container.decodeIfPresent (String.self,
															forKey: .compFieldId)) ?? ""
		self.textContent = (try? container.decodeIfPresent (String.self,
															forKey: .textContent))
		self.valueContent = (try? container.decodeIfPresent (Double.self,
															 forKey: .valueContent))
		self.colorId = (try? container.decodeIfPresent (String.self,
														forKey: .colorId))
		self.customColor = (try? container.decodeIfPresent (UMColor.self,
															forKey: .customColor))
		self.url = try? container.decodeIfPresent (URL.self,
												   forKey: .url)
		self.iterator = (try? container.decodeIfPresent (Bool.self, forKey: .iterator)) ?? false
		self.showAsLargeText = (try? container.decodeIfPresent (Bool.self, forKey: .showAsLargeText)) ?? (type () == .longText)
	}
	
	func duplicate () -> BBAERecordFieldValue {
		let duplicateItem = BBAERecordFieldValue (templateItemId: compFieldId,
												  textContent: textContent,
												  valueContent: valueContent,
												  url: url,
												  colorId: colorId)
		return duplicateItem
	}
	
	var fileSaveNameParticle :	String {
		if textContent == nil && url == nil && valueContent == nil {
			return id
		}
		return (textContent ?? valueContentString ?? fu_getFileNameWithoutExtension (url!.lastPathComponent))
			.searchAndReplace (search: ":", replaceWith: "-")
			.searchAndReplace (search: "/", replaceWith: "-")
			.searchAndReplace (search: " ", replaceWith: "-")
			.searchAndReplace (search: "\"", replaceWith: "")
			.searchAndReplace (search: "\\n", replaceWith: "-")
			.searchAndReplace (search: "\n", replaceWith: "-")
			.searchAndReplace (search: "&", replaceWith: "And")
			.searchAndReplace (search: "?", replaceWith: "")
			.searchAndReplace (search: "!", replaceWith: "")
			.searchAndReplace (search: "%", replaceWith: "Perc")
			.searchAndReplace (search: BBAESettings.shared.carriageReturnString, replaceWith: "-")
	}
	
	func variableName () -> String {
		guard let templateItem = BBAECompField.getField (withId: compFieldId) else {
			return "notDefined"
		}
		let vn = strUt_acceptChars (srcString: templateItem.variableName (), acceptedChars: "abcdef")
		return vn
	}
	
	func aeVariableAssignation (comp :		BBAEComp,
								project :	BBAEProject,
								type :		BBAECompField.FieldType?) -> String {
		guard let type = type,
			  let templateItem = (comp.fieldList.first { $0.id == compFieldId }) else { return "" }
		let varName = variableName ()
		if type == .text || type == .longText {
			return "\(varName) = \"\(formattedTextContent)\";\n"
		}
		if (type == .numericValue || type == .checkBox),
		   valueContentString != nil {
			return "\(varName) = \(valueContentString!);\n"
		}
		if type == .colorFill,
		   colorId != nil,
		   let bbaeColor = (project.colorList.first { $0.id == colorId }) {
			let color = BBAEProjectColor.aeColorArray (bbaeColor.color)
			let directColor = "\(varName) = \(color);\n"
			return directColor
		}
		return ""
	}
	
	func aeCompVariableAssignation (comp :	BBAEComp) -> String {
		guard let templateItem = (comp.fieldList.first { $0.id == compFieldId }) else { return "" }
		let fieldName = variableName ()
		if textContent != nil {
			return "\(fieldName) = \"\("Placeholder Text")\";\n"
		}
		if valueContentString != nil {
			return "\(fieldName) = \(100);\n"
		}
		return ""
	}
	
	func templateItem () ->	BBAECompField? {
		UMItems.getItem (withId: compFieldId) as? BBAECompField
	}
	
	func type () -> BBAECompField.FieldType? {
		templateItem ()?.type
	}
	
	var isTextType :	Bool {
		let t = type ()
		return t == .text || t == .longText
	}
	
	var cellHeight : CGFloat {
		guard let templateItem = templateItem () else { return 0 }
		switch templateItem.type {
			case .numericValue, .checkBox, .recordId:
				return 24
			case .text:
				return showAsLargeText ? 96 : 24
			case .colorFill:
				return 24
			case .image, .vectorAI:
				return 80
			case .video:
				return 80
			case .audio:
				return 80
			case .longText:
				return showAsLargeText ? 96 : 24
		}
	}
}



extension [BBAERecordFieldValue] {
	
	func cellHeight () -> CGFloat {
		reduce (0) { $0 + $1.cellHeight + 2 }
	}
}
