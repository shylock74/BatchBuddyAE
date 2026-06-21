//
//  BBAERecordVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 29/07/2021.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls
import UniformTypeIdentifiers
import UMImaging
import UMMovie

class BBAERecordVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAERecordVC"
	static let storyboardName =	"BBAETemplatePanel"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblList: UMTableView?
	
	// MARK: - Vars
	var project :			BBAEProject!
	var record :			BBAERecord!
	var hostController :	NSViewController!
	
	private let vcObserverId = UMId.newId(useCounter: false)
	
	var template :	BBAEComp? {
		project.getComp (withId: record.compId)
	}
	
	// MARK: - Display
	func displayData () {
		windowTitle = (template?.name ?? "Template") + " Instance"
		NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
	}
	
	// MARK: - View Cycle
	override func loaded () {
		let rootView = BBAERecordView(vc: self)
		let hostingView = NSHostingView(rootView: rootView)
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		
		self.view.subviews.forEach { $0.removeFromSuperview() }
		self.view.addSubview(hostingView)
		
		NSLayoutConstraint.activate([
			hostingView.topAnchor.constraint(equalTo: self.view.topAnchor),
			hostingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			hostingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			hostingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
		])
		
		setupObservers()
	}
	
	override func willAppear () {
		displayData ()
	}
	
	func setupObservers() {
		let projectKey = "media.ulti.bbae.projectUpdate.\(project.id)"
		UMDispatch.observe(key: projectKey, myId: vcObserverId) { [weak self] in
			XMain.execute {
				NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
			}
		}
		
		if let comp = template {
			let compKey = "\(comp.subscribableType).\(comp.id)"
			UMDispatch.observe(key: compKey, myId: vcObserverId) { [weak self] in
				XMain.execute {
					NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
				}
			}
		}
	}
	
	func changeCompId (to newId :	String?) {
		let previousItemInstance = record.duplicate ()
		record.compId = newId
		
		for fieldValue in record.recordFieldValueList {
			if let fieldName = fieldValue.templateItem ()?.fieldName {
				if let originalInstance = previousItemInstance.recordFieldValueList.first (where: { $0.templateItem ()?.fieldName == fieldName }) {
					fieldValue.textContent = originalInstance.textContent
					fieldValue.url = originalInstance.url
					fieldValue.valueContent = originalInstance.valueContent
				}
			}
		}
		project.lastTemplateId = newId
	}
	
	func rowModified () {
		record.prepareConfigurationFile (url: project.aeProjectFileUrl,
										 iteration: nil,
										 project: project)
		record.status = .toBeRendered
		project.save ()
		project.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
	}
	
	func saveToDisk() {
		UMProgressVC_Type0.show (currentController: self,
								 imgProgressPrefix: "BBAE_Progress_",
								 status: "Saving Data...")
		Queue.execute { [weak self] in
			guard let s = self,
			let comp = s.template else { return }
			s.record.prepareFiles (inProject: s.project,
								   comp: comp)
			UMProgressVC_Type0.hide ()
		}
	}
	
	func revealInFinder() {
		let renderFileUrl = project.renderFileUrl (record,
												   templateGroup: nil,
												   fileExtension: "")
		fu_showInFinder (renderFileUrl.parent)
	}
	
	func goToTemplate() {
		BBAETemplateListVC.showWindow (bbaeProject: project,
									   selectedTemplateId: record.compId)
	}
	
	func duplicateCurrentRecord() {
		duplicateRecord(record.id)
	}
	
	func removeCurrentRecord() {
		removeRecord(record.id)
	}
	
	func renderImmediately() {
		guard project.aepFilePresent () else {
			UMAlert.ok (message: "Alert",
						informativeText: "After Effects file (AEP) missing.")
			return
		}
		guard let comp = project.getComp (withId: record.compId) else {
			UMAlert.ok (message: "Alert",
						informativeText: "No Comp with this Id")
			return
		}
		guard BBAESettings.shared.aeRenderExists () else {
			UMAlert.ok (message: "Alert",
						informativeText: "AERender not present.")
			return
		}
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			project.renderedCount = 0
			if comp.isGroup == true {
				project.toBeRenderedCount = comp.compGroupList?.filter { $0.active }.count ?? 0
			} else {
				project.toBeRenderedCount = 1
			}
			renderRecord (item: record)
		}
	}
	
	// MARK: - BBAEInstanceCellDelegate
	func updateRecord () {
		project.save ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
	}
	
	func removeRecord (_ id: String) {
		project.recordList.removeAll { $0.id == id }
		project.save ()
		project.notifyUpdate ()
		close()
	}
	
	func displayInstanceCtxMenu (item :				BBAERecord,
								 button sender :	NSButton) {
	}
	
	func renderRecord (item: BBAERecord) {
		Queue.execute { [self] in
			guard License.licenseValidated else {
				XMain.execute (after: 0.5 ){
					UMAlert.ok (message: "Warning",
								informativeText: "Unlicensed.")
				}
				return
			}
			item.status = .rendering
			project.notifyUpdate ()
			project.renderRecord (item) { success, error in
				item.status = success
					? .rendered
					: .toBeRendered
				self.rowModified()
			}
		}
	}
	
	func renderPlaceholderInstance (item: BBAERecord) {
		Queue.execute { [self] in
			item.status = .rendering
			project.notifyUpdate ()
			project.renderPlaceholderItem (item) { value in
				item.status = value
					? .rendered
					: .toBeRendered
				self.rowModified()
			}
		}
	}
	
	func duplicateRecord (_ id: String) {
		project.duplicateItem (id)
		project.save ()
		project.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAERecordChanged"), object: nil)
	}
	
	static func showWindow (instance :	BBAERecord,
							project :	BBAEProject) {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.bbaeinstancevc.\(instance.id)",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									bundle: nil,
									disableResize: false,
									minWidth: 620,
									maxWidth: 620,
									minHeight: 288) { vc in
			guard let vc = vc as? Self else { return }
			vc.record = instance
			vc.project = project
		}
	}
}

// MARK: - SwiftUI Views

struct BBAERecordView: View {
	@ObservedObject var vc: BBAERecordVC
	
	@State private var compId: String
	@State private var recordStatus: BBAERecord.Status
	@State private var isActiveForRendering: Bool
	@State private var outputModuleText: String
	
	@State private var refreshId = UUID()
	
	init(vc: BBAERecordVC) {
		self.vc = vc
		_compId = State(initialValue: vc.record.compId ?? "*")
		_recordStatus = State(initialValue: vc.record.status)
		_isActiveForRendering = State(initialValue: vc.record.status != .dontRender)
		
		let template = vc.project.getComp(withId: vc.record.compId)
		let outText: String
		if let template = template {
			if template.isGroup == true {
				let t = template.compGroupList?.count ?? 0
				let nActive = template.compGroupList?.filter { $0.active }.count ?? 0
				outText = "Group (\(t) templates, \(nActive) active)"
			} else {
				outText = template.outputModule() ?? ""
			}
		} else {
			outText = ""
		}
		_outputModuleText = State(initialValue: outText)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Header configuration
			UMUISection("Instance Configuration") {
				VStack(spacing: 8) {
					HStack(spacing: 12) {
						Text("Template:")
							.font(.system(size: 11))
							.frame(width: 80, alignment: .leading)
						
						Picker("", selection: Binding(
							get: { compId },
							set: { val in
								compId = val
								let newId = val == "*" ? nil : val
								if newId != vc.record.compId {
									vc.changeCompId(to: newId)
								}
								vc.rowModified()
							}
						)) {
							Text("Not Set").tag("*")
							Divider()
							ForEach(vc.project.compList, id: \.id) { comp in
								Text(comp.name).tag(comp.id)
							}
						}
						.labelsHidden()
						.frame(maxWidth: .infinity)
						
						Spacer()
						
						UMUIMiniSwitch("Active for Rendering", isOn: Binding(
							get: { isActiveForRendering },
							set: { val in
								isActiveForRendering = val
								vc.record.status = val ? .toBeRendered : .dontRender
								vc.rowModified()
							}
						))
					}
					
					HStack {
						if !outputModuleText.isEmpty {
							Text("Output Module: \(outputModuleText)")
								.font(.system(size: 10))
								.foregroundColor(.secondary)
						}
						
						Spacer()
						
						HStack(spacing: 4) {
							Text("Status:")
								.font(.system(size: 11, weight: .bold))
							Text(recordStatus.displayString())
								.font(.system(size: 11))
								.foregroundColor(statusColor(recordStatus))
							
							Image(nsImage: statusImage(recordStatus))
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 14, height: 14)
						}
					}
				}
				.padding(10)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			.padding(.horizontal, 16)
			.padding(.top, 16)
			
			// Dynamic fields section
			ScrollView {
				VStack(spacing: 12) {
					if let template = vc.project.getComp(withId: vc.record.compId) {
						UMUISection("Template Fields") {
							VStack(spacing: 10) {
								ForEach(Array(template.fieldList.enumerated()), id: \.element.id) { index, field in
									if index < vc.record.recordFieldValueList.count {
										let fieldValue = vc.record.recordFieldValueList[index]
										FieldRowView(
											field: field,
											fieldValue: fieldValue,
											record: vc.record,
											project: vc.project,
											onModified: {
												vc.rowModified()
											}
										)
									}
								}
							}
							.padding(10)
							.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
						}
						.id(refreshId)
					} else {
						VStack {
							Spacer()
							Text("No Template Selected")
								.font(.system(size: 12))
								.foregroundColor(.secondary)
							Spacer()
						}
						.frame(minHeight: 120)
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
			}
			.background(Color.darkGray.opacity(0.05))
			
			// Footer Control Buttons
			HStack(spacing: 8) {
				UMUICapsuleButton("Save to Disk", style: .gray, size: .small) {
					vc.saveToDisk()
				}
				.lineLimit(1)
				.fixedSize()
				
				UMUICapsuleButton("Show in Finder", style: .gray, size: .small) {
					vc.revealInFinder()
				}
				.lineLimit(1)
				.fixedSize()
				
				UMUICapsuleButton("Go to Template", style: .gray, size: .small) {
					vc.goToTemplate()
				}
				.lineLimit(1)
				.fixedSize()
				
				Spacer()
				
				UMUICapsuleButton("Duplicate", style: .gray, size: .small) {
					vc.duplicateCurrentRecord()
				}
				.lineLimit(1)
				.fixedSize()
				
				UMUICapsuleButton("Delete", style: .gray, size: .small) {
					vc.removeCurrentRecord()
				}
				.lineLimit(1)
				.fixedSize()
				
				UMUICapsuleButton("Render", style: .accent, size: .small) {
					vc.renderImmediately()
				}
				.lineLimit(1)
				.fixedSize()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
		}
		.frame(minWidth: 620, minHeight: 350)
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAERecordChanged"))) { _ in
			self.refreshData()
		}
	}
	
	func refreshData() {
		let r = vc.record!
		compId = r.compId ?? "*"
		recordStatus = r.status
		isActiveForRendering = r.status != .dontRender
		
		let template = vc.project.getComp(withId: r.compId)
		let outText: String
		if let template = template {
			if template.isGroup == true {
				let t = template.compGroupList?.count ?? 0
				let nActive = template.compGroupList?.filter { $0.active }.count ?? 0
				outText = "Group (\(t) templates, \(nActive) active)"
			} else {
				outText = template.outputModule() ?? ""
			}
		} else {
			outText = ""
		}
		outputModuleText = outText
		
		refreshId = UUID()
	}
	
	func statusColor(_ status: BBAERecord.Status) -> Color {
		switch status {
		case .toBeRendered: return .orange
		case .dontRender: return .secondary
		case .rendering: return .blue
		case .rendered: return .green
		}
	}
	
	func statusImage(_ status: BBAERecord.Status) -> NSImage {
		switch status {
		case .toBeRendered: return Draw.getImage("Icon_Render_00001") ?? NSImage()
		case .dontRender: return Draw.getImage("Icon_Render_00000") ?? NSImage()
		case .rendering: return Draw.getImage("Icon_Render_00002") ?? NSImage()
		case .rendered: return Draw.getImage("Icon_Render (0-00-00-00)") ?? NSImage()
		}
	}
}

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
