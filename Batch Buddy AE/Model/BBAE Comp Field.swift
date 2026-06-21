//
//  BBAETEmplateItem.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 28/04/2021.
//

import Cocoa
import UMOmniaFramework
import UMImaging
import UMMovie

final class BBAECompField :	Codable,
								UMSubscribable {
	
	var subscribableType :	String { "media.ulti.BBAETemplateCompItem" }
	
	static var compFieldList =	[BBAECompField] ()
	
	enum FieldType :	String, Codable {
		case text
		case longText
		case colorFill
		case image
		case video
		case audio
		case numericValue
		case vectorAI
		case checkBox
		case recordId

		func fieldValueHeight () -> CGFloat {
			switch self {
				case .text, .numericValue, .checkBox, .recordId:
					return 24
				case .image, .video, .vectorAI:
					return 80
				case .audio:
					return 80
				case .longText:
					return 96
				case .colorFill:
					return 24
			}
		}
		
		var image :	NSImage {
			switch self {
				case .text:
					return Draw.getImage ("Btn__Type-Text_00000")!
				case .longText:
					return Draw.getImage ("Btn__Type-Long-Text_00000")!
				case .colorFill:
					return Draw.getImage ("Btn__Type-Color_00000")!
				case .image:
					return Draw.getImage ("Btn__Type-Picture_00000")!
				case .video:
					return Draw.getImage ("Btn__Type-Video_00000")!
				case .audio:
					return Draw.getImage ("Btn__Type-Audio_00000")!
				case .numericValue:
					return Draw.getImage ("Btn__Type-Number_00000")!
				case .vectorAI:
					return Draw.getImage ("Btn__Type-Vector_00000")!
				case .checkBox:
					return Draw.getImage ("Btn__Type-Checkbox_00000")!
				case .recordId:
					return Draw.getImage ("Btn__Type-Id_00000")!
			}
		}
		
		var isMedia :	Bool {
			return self == .image || self == .audio || self == .video || self == .vectorAI
		}
	}
	
	enum ResizePolicy :	String, Codable {
		case fill
		case fit
	}
	
	struct NumericFieldSettings :	Codable {
		
		enum NumberType : String,Codable {
			case integer =	"Integer"
			case float =	"Float"
		}
		
		enum Appearance :	String, Codable, CaseIterable {
			case field
			case slider
			case stepper
			
			var displayString :	String {
				self.rawValue.capitalized
			}
		}
		
		var appearance :	Appearance =	.field
		var numberType :	NumberType =	.float
		var minValue :		Double =		0
		var maxValue :		Double =		100
		var step :			Double =		10
		var iterator :		Bool =			false
		
		init (appearance :	Appearance = .field,
			  numberType :	NumberType = .float,
			  minValue :	Double = 0,
			  maxValue :	Double = 100,
			  step :		Double = 10) {
			self.appearance = appearance
			self.numberType = numberType
			self.minValue = minValue
			self.maxValue = maxValue
			self.step = step
		}

		var enableStep :	Bool {
			appearance == .stepper
		}
		
		var enableMinMax :	Bool {
			appearance == .slider || appearance == .stepper
		}
		
		init (from decoder: Decoder) throws {
			let container = try decoder.container (keyedBy: CodingKeys.self)
			self.appearance = (try? container.decodeIfPresent (Appearance.self, forKey: .appearance)) ?? .field
			self.numberType = (try? container.decodeIfPresent (NumberType.self, forKey: .numberType)) ?? .float
			self.minValue = (try? container.decodeIfPresent (Double.self, forKey: .minValue)) ?? 0
			self.maxValue = (try? container.decodeIfPresent (Double.self, forKey: .maxValue)) ?? 100
			self.step = (try? container.decodeIfPresent (Double.self, forKey: .step)) ?? 10
			self.iterator = (try? container.decodeIfPresent (Bool.self, forKey: .iterator)) ?? false
		}
	}
	
	var id =					UMId.newId (useCounter: false)
	var type :					FieldType =		.text
	var fieldName :				String =		""
	var placeholderUrl :		URL? =			nil
	var placeholderPosterUrl :	URL? =			nil
	var resize :				Bool =			false
	var resizeWidth :			Int =			0
	var resizeHeight :			Int = 			0
	var resizePolicy :			ResizePolicy =	.fill
	var colorize :				Bool =			false
	var colorizeColorId :		String? =		nil
	var defaultNumericValue :	Double? =		nil
	var defaultTextValue :		String? =		nil
	var objectOrder :			Int? =			0
	var numericFieldSettings :	NumericFieldSettings =	NumericFieldSettings ()
	var customVariableName :	String?	=		nil
	
	private enum CodingKeys: String, CodingKey {
		case id
		case type
		case fieldName
		case placeholderUrl
		case placeholderPosterUrl
		case resize
		case resizeWidth
		case resizeHeight
		case resizePolicy
		case colorize
		case colorizeColorId
		case defaultNumericValue
		case defaultTextValue
		case objectOrder
		case numericFieldSettings
		case customVariableName
	}

	init (type :	BBAECompField.FieldType,
		  order :	Int) {
		self.type = type
		self.objectOrder = order
		itemLoaded (order: order)
	}
	
	required init (from decoder: Decoder) throws {
		let container = try decoder.container (keyedBy: CodingKeys.self)
		self.id = container.decodeString (forKey: .id, default: "")
		self.type = (try? container.decodeIfPresent (FieldType.self,
													 forKey: .type)) ?? .text
		self.fieldName = (try? container.decodeIfPresent (String.self,
													 forKey: .fieldName)) ?? ""
		self.placeholderUrl = try? container.decodeIfPresent (URL.self,
															  forKey: .placeholderUrl)
		self.placeholderPosterUrl = try? container.decodeIfPresent (URL.self,
																	forKey: .placeholderPosterUrl)
		self.resize = (try? container.decodeIfPresent (Bool.self,
													   forKey: .resize)) ?? false
		self.resizeWidth = (try? container.decodeIfPresent (Int.self,
															forKey: .resizeWidth)) ?? 0
		self.resizeHeight = (try? container.decodeIfPresent (Int.self,
															 forKey: .resizeHeight)) ?? 0
		self.resizePolicy = (try? container.decodeIfPresent (ResizePolicy.self,
															 forKey: .resizePolicy)) ?? .fill
		self.colorize = (try? container.decodeIfPresent (Bool.self,
														 forKey: .colorize)) ?? false
		self.colorizeColorId = (try? container.decodeIfPresent (String.self,
																forKey: .colorizeColorId)) ?? ""
		self.defaultNumericValue = (try? container.decodeIfPresent (Double.self,
																	forKey: .defaultNumericValue))
		self.numericFieldSettings = (try? container.decodeIfPresent (NumericFieldSettings.self,
																	 forKey: .numericFieldSettings)) ?? NumericFieldSettings ()
		self.customVariableName = (try? container.decodeIfPresent (String.self, forKey: .customVariableName)) ?? nil
	}

	func duplicate (order :	Int) -> BBAECompField {
		let copy = BBAECompField (type: type,
										 order: order)
		copy.fieldName = fieldName
		copy.placeholderUrl = placeholderUrl
		copy.placeholderPosterUrl = placeholderPosterUrl
		copy.resize = resize
		copy.resizeWidth = resizeWidth
		copy.resizeHeight = resizeHeight
		copy.resizePolicy = resizePolicy
		copy.colorize = colorize
		copy.colorizeColorId = colorizeColorId
		return copy
	}
	
	func itemLoaded (order :	Int?) {
		objectOrder = order ?? 0
		UMItems.addItem (id: id,
						 item: self)
	}
	
	var instanceHeight :	CGFloat {
		type.fieldValueHeight ()
	}
	
	func getAECode () -> String {
		switch type {
			case .text, .longText:
				return BBAESettings.shared.getTextAECodeString (item: self)
			case .numericValue, .colorFill, .checkBox:
				return BBAESettings.shared.getNumberAECodeString (item: self)

			default: return ""
		}
		
	}
	
	static func addFieldToGlobalList (_ field :	BBAECompField) {
		removeFieldFromGlobalList (field)
		compFieldList.append (field)
	}
	
	static func removeFieldFromGlobalList (_ field : 	BBAECompField) {
		compFieldList = compFieldList.filter { $0.id != field.id }
	}
	
	static func removeFieldFromGlobalList (withId id : 	String) {
		compFieldList = compFieldList.filter { $0.id != id }
	}
	
	static func getField (withId id :	String?) -> BBAECompField? {
		guard let id = id else { return nil }
		let r = compFieldList.first { $0.id == id }
		return r
	}
	
	func variableName () -> String {
		let vn = customVariableName ?? strUt_acceptChars (srcString: id, acceptedChars: "abcdef")
		return vn
	}
	
	func placeholderURLInBBAEFolderName (shortName :	String) -> String {
		
		var fieldName_ = strUt_acceptChars (srcString: fieldName,
										   acceptedChars: "qwertuiyopasdfghjklzxcvbnmQWERTUYIOPASDFGHJKLZXCVBNM1234567890_- ")
		fieldName_ = fieldName_.searchAndReplace (search: " ", replaceWith: "_")
		var name :	String
		switch type {
			case .text, .numericValue, .longText, .checkBox, .recordId:
				name = ""
			case .colorFill:
				name = ""
			case .image:
				name = "Placeholder_\(shortName)_\(fieldName_).png"
			case .video:
				name = "Placeholder_\(shortName)_\(fieldName_).mov"
			case .audio:
				name = "Placeholder_\(shortName)_\(fieldName_).wav"
			case .vectorAI:
				name = "Placeholder_\(shortName)_\(fieldName_).ai"
		}
		return name
	}
	
	func poster () -> UMImage? {
		if type == .text {
			return nil
		}
		guard let placeholderUrl = placeholderUrl else { return nil }
		if type == .image {
			return UMImage (placeholderUrl)
		}
		if type == .video {
			let generator =	UMMovieUtilsImageGenerator (url: placeholderUrl)
			let duration = MU.getVideoDuration (placeholderUrl)
			let image = generator.getUMImage (at: duration * BBAESettings.shared.posterFrameAt / 100,
											  speculativeExecution: false)
			return image
		}
		if type == .vectorAI {
			return UMImage (placeholderUrl)
		}
		return nil
	}
	
	var iSmedia : Bool {
		type.isMedia
	}
	
	var isIterator : Bool {
		type == .numericValue && numericFieldSettings.iterator
	}
}
