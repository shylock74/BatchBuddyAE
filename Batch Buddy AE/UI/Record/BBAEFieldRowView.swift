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
					
					UMUIMiniButton("Suggest", style: .gray) {
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
							.controlSize(.mini)
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
						.controlSize(.mini)
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
								.controlSize(.mini)
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
								
								UMUIMiniButton("- \(field.numericFieldSettings.step.string)", style: .gray) {
									fieldValue.valueContent = max((fieldValue.valueContent ?? 0) - field.numericFieldSettings.step, field.numericFieldSettings.minValue)
									onModified()
								}
								.lineLimit(1)
								.fixedSize()
								
								UMUIMiniButton("+ \(field.numericFieldSettings.step.string)", style: .gray) {
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
						.frame(width: 100, alignment: .leading)
					
					UMUIMiniSwitch("", isOn: Binding(
						get: { fieldValue.valueContent == 1 },
						set: { val in
							fieldValue.valueContent = val ? 1 : 0
							onModified()
						}
					))
					.controlSize(.mini)
					
					Spacer()
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
					
					Spacer()
				}
				
			case .image, .video, .audio, .vectorAI:
				HStack(alignment: .center, spacing: 8) {
					HStack(spacing: 4) {
						Image(nsImage: field.type.image)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 14, height: 14)
						Text((field.fieldName) + ":")
							.font(.system(size: 11))
					}
					.frame(width: 100, alignment: .leading)
					
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
						if fieldValue.url != nil {
							HStack(alignment: .center, spacing: 6) {
								Text(fieldValue.url!.lastPathComponent)
									.font(.system(size: 11))
									.foregroundColor(.primary)
									.lineLimit(1)
									.truncationMode(.middle)
								
								Button(action: {
									if let url = fieldValue.url {
										fu_showInFinder(url)
									}
								}) {
									Image(systemName: "magnifyingglass")
										.font(.system(size: 13, weight: .medium))
										.foregroundColor(.secondary)
								}
								.buttonStyle(PlainButtonStyle())
								.help("Reveal in Finder")
							}
						} else {
							Text("Drag File Here")
								.font(.system(size: 11))
								.foregroundColor(.secondary)
								.lineLimit(1)
						}
					}
					Spacer()
					
					if fieldValue.url != nil {
						Button(action: {
							fieldValue.url = nil
							onModified()
						}) {
							Image(systemName: "trash")
								.font(.system(size: 14, weight: .medium))
								.foregroundColor(.red.opacity(0.8))
						}
						.buttonStyle(PlainButtonStyle())
						.help("Remove")
						.padding(.trailing, 4)
					}
				}
			}
		}
		.padding(.vertical, 1)
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
			RoundedRectangle(cornerRadius: 4)
				.fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.3)) // "pozzo" background
            
            CheckerboardPattern()
                .opacity(0.1)
                .clipShape(RoundedRectangle(cornerRadius: 4))
			
			if let img = thumbnail {
				Image(nsImage: img)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.padding(2)
			} else {
				Image(systemName: placeholderIconName(type))
					.font(.system(size: 24))
					.foregroundColor(.secondary)
			}
		}
		.frame(width: 144, height: 81) // 16:9 aspect ratio
		.clipShape(RoundedRectangle(cornerRadius: 4))
		.overlay(
			RoundedRectangle(cornerRadius: 4)
				.stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isTargeted ? 2 : 1)
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
					img = NSImage(cgImage: downsampledImage, size: .zero)
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

// MARK: - Checkerboard Pattern

struct CheckerboardPattern: View {
    var squareSize: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                
                Path { path in
                    let columns = Int(geometry.size.width / squareSize) + 1
                    let rows = Int(geometry.size.height / squareSize) + 1
                    for row in 0..<rows {
                        for col in 0..<columns {
                            if (row + col).isMultiple(of: 2) {
                                path.addRect(CGRect(x: CGFloat(col) * squareSize, 
                                                    y: CGFloat(row) * squareSize, 
                                                    width: squareSize, 
                                                    height: squareSize))
                            }
                        }
                    }
                }
                .fill(Color.white.opacity(0.4))
            }
        }
    }
}

