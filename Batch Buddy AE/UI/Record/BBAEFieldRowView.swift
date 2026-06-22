//
//  BBAEFieldRowView.swift
//  Batch Buddy AE
//
//  Created by Antigravity on 22/06/2026.
//
//  Contains the shared SwiftUI field-row components originally from BBAERecordVC.
//  These are used by both BBAERecordRowView (inline list) and any other future views.
//

import SwiftUI
import UMOmniaFramework
import UMUIControls
import UniformTypeIdentifiers
import UMMovie

// MARK: - Field Row Editor

struct FieldRowView: View {
	let field: BBAECompField
	let fieldValue: BBAERecordFieldValue
	let record: BBAERecord
	let project: BBAEProject
	let onModified: () -> Void
	
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			switch field.type {
			case .recordId:
				HStack(spacing: 8) {
					Text("Record Id:")
						.font(.system(size: 11))
						.frame(width: 100, alignment: .leading)
					
					UMUITextField(
						placeholder: "Record ID",
						value: Binding(
							get: { fieldValue.textContent ?? "" },
							set: { val in
								if val != fieldValue.textContent {
									fieldValue.textContent = val
									onModified()
								}
							}
						),
						size: .small,
						labelWidth: 0
					)
					
					UMUICapsuleButton("Suggest", style: .gray, size: .small) {
						fieldValue.textContent = record.suggestedRecordID()
						onModified()
					}
					.lineLimit(1)
					.fixedSize()
				}
				
			case .text, .longText:
				if fieldValue.showAsLargeText {
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Text((field.fieldName) + ":")
								.font(.system(size: 11))
							Spacer()
							UMUIMiniSwitch("Large Text", isOn: Binding(
								get: { fieldValue.showAsLargeText },
								set: { val in
									fieldValue.showAsLargeText = val
									if val {
										fieldValue.textContent = fieldValue.textContent?.replace(BBAESettings.shared.carriageReturnString, with: "\n")
									} else {
										fieldValue.textContent = fieldValue.textContent?.replace("\n", with: BBAESettings.shared.carriageReturnString)
									}
									onModified()
								}
							))
						}
						
						TextEditor(text: Binding(
							get: { fieldValue.textContent ?? "" },
							set: { val in
								if val != fieldValue.textContent {
									fieldValue.textContent = val
									onModified()
								}
							}
						))
						.frame(height: 70)
						.padding(4)
						.background(
							RoundedRectangle(cornerRadius: 4)
								.stroke(Color.gray.opacity(0.2), lineWidth: 1)
						)
					}
				} else {
					HStack(spacing: 8) {
						Text((field.fieldName) + ":")
							.font(.system(size: 11))
							.frame(width: 100, alignment: .leading)
						
						UMUITextField(
							placeholder: "",
							value: Binding(
								get: { fieldValue.textContent ?? "" },
								set: { val in
									if val != fieldValue.textContent {
										fieldValue.textContent = val
										onModified()
									}
								}
							),
							size: .small,
							labelWidth: 0
						)
						.onChange(of: fieldValue.textContent) { newValue in
							if let nv = newValue, nv.contains("\n") && !fieldValue.showAsLargeText {
								fieldValue.showAsLargeText = true
								onModified()
							}
						}
						
						UMUIMiniSwitch("Large Text", isOn: Binding(
							get: { fieldValue.showAsLargeText },
							set: { val in
								fieldValue.showAsLargeText = val
								if val {
									fieldValue.textContent = fieldValue.textContent?.replace(BBAESettings.shared.carriageReturnString, with: "\n")
								} else {
									fieldValue.textContent = fieldValue.textContent?.replace("\n", with: BBAESettings.shared.carriageReturnString)
								}
								onModified()
							}
						))
					}
				}
				
			case .numericValue:
				switch field.numericFieldSettings.appearance {
				case .field:
					HStack(spacing: 8) {
						Text((field.fieldName) + ":")
							.font(.system(size: 11))
							.frame(width: 100, alignment: .leading)
						
						UMUITextField(
							placeholder: "0.0",
							value: Binding(
								get: {
									if fieldValue.type() == .text {
										return fieldValue.textContent ?? ""
									} else {
										return fieldValue.valueContentString ?? ""
									}
								},
								set: { val in
									if fieldValue.type() == .text {
										fieldValue.textContent = val
									} else {
										fieldValue.valueContent = Double(val)
									}
									onModified()
								}
							),
							size: .small,
							labelWidth: 0
						)
					}
					
				case .slider:
					HStack(spacing: 8) {
						Text((field.fieldName) + ":")
							.font(.system(size: 11))
							.frame(width: 100, alignment: .leading)
						
						UMUISlider(
							value: Binding(
								get: { fieldValue.valueContent ?? 0.0 },
								set: { val in
									fieldValue.valueContent = val
									onModified()
								}
							),
							range: (field.numericFieldSettings.minValue)...(field.numericFieldSettings.maxValue),
							size: .small,
							labelWidth: 0
						)
						
						Text(String(format: "%.1f", fieldValue.valueContent ?? 0.0))
							.font(.system(size: 10))
							.frame(width: 40, alignment: .trailing)
					}
					
				case .stepper:
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Text((field.fieldName) + ":")
								.font(.system(size: 11))
							Spacer()
							if field.isIterator {
								UMUIMiniSwitch("Iterator", isOn: Binding(
									get: { fieldValue.iterator },
									set: { val in
										fieldValue.iterator = val
										onModified()
									}
								))
							}
						}
						
						HStack {
							if fieldValue.iterator {
								Text("\(Int(field.numericFieldSettings.minValue)) -> \(Int(field.numericFieldSettings.maxValue))")
									.font(.system(size: 11))
									.foregroundColor(.secondary)
							} else {
								Text(String(format: "%.1f", fieldValue.valueContent ?? 0.0))
									.font(.system(size: 11))
								
								Spacer()
								
								UMUICapsuleButton("- \(field.numericFieldSettings.step.string)", style: .gray, size: .small) {
									fieldValue.valueContent = max((fieldValue.valueContent ?? 0) - field.numericFieldSettings.step, field.numericFieldSettings.minValue)
									onModified()
								}
								.lineLimit(1)
								.fixedSize()
								
								UMUICapsuleButton("+ \(field.numericFieldSettings.step.string)", style: .gray, size: .small) {
									fieldValue.valueContent = min((fieldValue.valueContent ?? 0) + field.numericFieldSettings.step, field.numericFieldSettings.maxValue)
									onModified()
								}
								.lineLimit(1)
								.fixedSize()
							}
						}
					}
				}
				
			case .checkBox:
				HStack(spacing: 8) {
					Text((field.fieldName) + ":")
						.font(.system(size: 11))
					Spacer()
					UMUIMiniSwitch("", isOn: Binding(
						get: { fieldValue.valueContent == 1 },
						set: { val in
							fieldValue.valueContent = val ? 1 : 0
							onModified()
						}
					))
				}
				
			case .colorFill:
				HStack(spacing: 8) {
					Text((field.fieldName) + ":")
						.font(.system(size: 11))
						.frame(width: 100, alignment: .leading)
					
					Picker("", selection: Binding(
						get: { fieldValue.colorId ?? "*" },
						set: { val in
							fieldValue.colorId = val == "*" ? nil : val
							onModified()
						}
					)) {
						Text("Custom").tag("*")
						ForEach(project.colorList, id: \.id) { colorItem in
							Text(colorItem.name).tag(colorItem.id)
						}
					}
					.labelsHidden()
					.frame(width: 150)
					
					Spacer()
					
					if let colorId = fieldValue.colorId,
					   let projectColor = project.getColor(colorId) {
						Circle()
							.fill(Color(projectColor.color.getColor()))
							.frame(width: 18, height: 18)
					} else {
						Circle()
							.fill(Color.black)
							.frame(width: 18, height: 18)
					}
				}
				
			case .image, .video, .audio, .vectorAI:
				VStack(alignment: .leading, spacing: 6) {
					HStack {
						Image(nsImage: field.type.image)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 14, height: 14)
						Text((field.fieldName) + ":")
							.font(.system(size: 11))
						Spacer()
					}
					HStack(spacing: 8) {
						FileDropPreview(
							url: fieldValue.url,
							type: field.type,
							allowedExtensions: allowedExtensionsForType(field.type)
						) { newUrl in
							fieldValue.url = newUrl
							onModified()
							Queue.execute {
								record.prepareVideos(project: project)
							}
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text(fieldValue.url?.lastPathComponent ?? "Drag File Here")
								.font(.system(size: 11))
								.foregroundColor(fieldValue.url == nil ? .secondary : .primary)
								.lineLimit(1)
								.truncationMode(.middle)
							
							if fieldValue.url != nil {
								HStack(spacing: 8) {
									UMUICapsuleButton("Reveal in Finder", style: .gray, size: .small) {
										if let url = fieldValue.url {
											fu_showInFinder(url)
										}
									}
									.lineLimit(1)
									.fixedSize()
									
									UMUICapsuleButton("Remove", style: .gray, size: .small) {
										fieldValue.url = nil
										onModified()
									}
									.lineLimit(1)
									.fixedSize()
								}
							}
						}
					}
				}
			}
		}
		.padding(.vertical, 4)
	}
	
	private func allowedExtensionsForType(_ type: BBAECompField.FieldType) -> [String] {
		switch type {
		case .image: return ["png", "jpg", "jpeg", "tif", "tiff", "psd"]
		case .video: return ["mov", "mp4", "m4v"]
		case .audio: return ["wav", "wave"]
		case .vectorAI: return ["ai"]
		default: return []
		}
	}
}

// MARK: - File Drop Area Preview

struct FileDropPreview: View {
	let url: URL?
	let type: BBAECompField.FieldType
	let allowedExtensions: [String]
	let onFileSelected: (URL) -> Void
	
	@State private var isTargeted = false
	@State private var thumbnail: NSImage? = nil
	@State private var loadId = UUID()
	
	var body: some View {
		ZStack {
			if let img = thumbnail {
				Image(nsImage: img)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 80, height: 80)
					.cornerRadius(4)
			} else {
				RoundedRectangle(cornerRadius: 4)
					.fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.1))
					.frame(width: 80, height: 80)
				
				Image(systemName: placeholderIconName(type))
					.font(.system(size: 24))
					.foregroundColor(.secondary)
			}
		}
		.frame(width: 80, height: 80)
		.overlay(
			RoundedRectangle(cornerRadius: 4)
				.stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isTargeted ? 2 : 1)
		)
		.onTapGesture {
			browseFile()
		}
		.onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
			guard let provider = providers.first else { return false }
			_ = provider.loadObject(ofClass: URL.self) { loadedUrl, error in
				if let loadedUrl = loadedUrl {
					let ext = loadedUrl.pathExtension.lowercased()
					if allowedExtensions.isEmpty || allowedExtensions.contains(ext) {
						XMain.execute {
							onFileSelected(loadedUrl)
						}
					}
				}
			}
			return true
		}
		.onAppear {
			loadThumbnail()
		}
		.onChange(of: url) { _ in
			loadThumbnail()
		}
	}
	
	private func placeholderIconName(_ type: BBAECompField.FieldType) -> String {
		switch type {
		case .image: return "photo"
		case .video: return "video"
		case .audio: return "music.note"
		case .vectorAI: return "doc.richtext"
		default: return "doc"
		}
	}
	
	private func loadThumbnail() {
		guard let url = url else {
			thumbnail = nil
			return
		}
		let currentLoadId = UUID()
		loadId = currentLoadId
		
		if type == .audio {
			thumbnail = Draw.getImage("Icn_AudioFile")
			return
		}
		
		Queue.execute {
			let img: NSImage?
			if type == .image || type == .vectorAI {
				let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
				if let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
				   let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
					kCGImageSourceCreateThumbnailFromImageAlways: true,
					kCGImageSourceShouldCacheImmediately: true,
					kCGImageSourceCreateThumbnailWithTransform: true,
					kCGImageSourceThumbnailMaxPixelSize: 160
				   ] as CFDictionary) {
					img = NSImage(cgImage: downsampledImage, size: CGSize(width: 80, height: 80))
				} else {
					img = NSImage(contentsOf: url)
				}
			} else if type == .video {
				let generator = UMMovieUtilsImageGenerator(url: url)
				img = generator.getUMImage(at: 0, speculativeExecution: false)?.image
			} else {
				img = nil
			}
			
			XMain.execute {
				if loadId == currentLoadId {
					thumbnail = img
				}
			}
		}
	}
	
	private func browseFile() {
		UMFileDialogs.open(
			title: "Select File",
			message: "Choose file of type: \(type)",
			availableExtensions: allowedExtensions
		) { selectedUrl in
			onFileSelected(selectedUrl)
		}
	}
}
