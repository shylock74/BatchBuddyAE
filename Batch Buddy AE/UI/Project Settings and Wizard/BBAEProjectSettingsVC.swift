//
//  BBAEProjectSettingsVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 11/09/21.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls
import UniformTypeIdentifiers

class BBAEProjectSettingsVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAEProjectSettingsVC"
	static let storyboardName =	"BBAEProjectSettings"
	
	// MARK: - UI Elements
	// Legacy Outlets made optional to support SwiftUI hosting safely
	@IBOutlet weak var fldProjectName: UMTextField?
	@IBOutlet weak var drgDragArea: UMAnimDragArea?
	@IBOutlet weak var lblAEPFileName: NSTextField?
	@IBOutlet weak var imgAEPFileMissingWarning: NSImageView?
	@IBOutlet weak var btnRenderFolder: UMRoundedRectButton?
	@IBOutlet weak var chkRenderInSubfolder: UMCheckButton?
	@IBOutlet weak var chkUseCompFullName: UMCheckButton?
	@IBOutlet weak var fldGlobalPrefix: UMTextField?
	@IBOutlet weak var fldGlobalMidfix: UMTextField?
	@IBOutlet weak var fldGlobalSuffix: UMTextField?

	@IBOutlet weak var lblDragHereAERender: NSTextField?
	@IBOutlet weak var drgAERenderDragArea: UMAnimDragArea?
	@IBOutlet weak var chkUseRosetta: UMCheckButton?
	
	// MARK: - Vars
	var project :	BBAEProject!
	
	// MARK: - View Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let settingsView = BBAEProjectSettingsView(vc: self)
		let hostingView = NSHostingView(rootView: settingsView)
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		
		self.view.subviews.forEach { $0.removeFromSuperview() }
		self.view.addSubview(hostingView)
		
		NSLayoutConstraint.activate([
			hostingView.topAnchor.constraint(equalTo: self.view.topAnchor),
			hostingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			hostingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			hostingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
		])
	}
	
	override func willAppear () {
		// Handled via NSHostingView lifecycle
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   project :			BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.project = project
		}
	}
	
	// MARK: - Actions
	func selectRenderFolder() {
		UMFileDialogs.chooseFolder(
			title: "Render Folder",
			message: "Choose Render Folder For Project",
			defaultPath: project.renderFolder_
		) { [weak self] url in
			if let url = url {
				self?.project.renderFolder_ = url
				self?.project.save()
				self?.project.notifyUpdate()
				NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsChanged"), object: nil)
			}
		}
	}
	
	func removeAllRecords() {
		UMAlert.twoButtons (message: "Warning",
							informativeText: "Do you really want to remove ALL records?",
							button0Txt: "No, Cancel",
							button1Txt: "Yes, Continue and Delete ALL Records",
							button1Completion: { [weak self] in
			self?.project.deleteAllRecords ()
			self?.project.save()
			self?.project.notifyUpdate()
			NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsChanged"), object: nil)
		})
	}
	
	func clearCustomAERender() {
		project.customAERenderUrl = nil
		project.save ()
		project.notifyUpdate()
		NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsChanged"), object: nil)
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
	
	@IBAction func btnSelectFolderPressed(_ sender: Any) {
		selectRenderFolder()
	}
	
	@IBAction func btnOpenProjectInAEPressed (_ sender: Any) {
		guard let url = project.aeProjectFileUrl else { return }
		fu_openFileWithItsApp (url)
	}
	
	@IBAction func btnRevealInFinderpressed(_ sender: Any) {
		guard let url = project.aeProjectFileUrl else { return }
		fu_showInFinder (url)
	}
	
	@IBAction func btnRemoveAllRecordsPressed(_ sender: Any) {
		removeAllRecords()
	}
	
	@IBAction func btnClearAERenderPressed(_ sender: Any) {
		clearCustomAERender()
	}
}

// MARK: - SwiftUI Views

struct BBAEProjectSettingsView: View {
	@ObservedObject var vc: BBAEProjectSettingsVC
	
	@State private var projectName: String
	@State private var aepPath: String
	@State private var aepExists: Bool
	
	@State private var renderFolderTitle: String
	@State private var renderInSubfolder: Bool
	@State private var useFullCompName: Bool
	
	@State private var globalPrefix: String
	@State private var globalMidfix: String
	@State private var globalSuffix: String
	
	@State private var customAERenderPath: String
	@State private var useRosetta: Bool
	
	init(vc: BBAEProjectSettingsVC) {
		self.vc = vc
		let p = vc.project!
		_projectName = State(initialValue: p.name)
		_aepPath = State(initialValue: p.aeProjectFileUrl?.path ?? "")
		_aepExists = State(initialValue: p.aepFilePresent())
		
		let docsFolder = fu_getDocumentsFolderURL().append("_BBAE Render")
		let folderTitle = p.renderFolder_ == docsFolder ? "Documents Folder" : p.renderFolder_.lastPathComponent
		_renderFolderTitle = State(initialValue: folderTitle)
		
		_renderInSubfolder = State(initialValue: p.renderInSubfolders)
		_useFullCompName = State(initialValue: p.useFullCompNameForSubfolder)
		
		_globalPrefix = State(initialValue: p.naming.globalPrefix)
		_globalMidfix = State(initialValue: p.naming.globalMidfix)
		_globalSuffix = State(initialValue: p.naming.globalSuffix)
		
		_customAERenderPath = State(initialValue: p.customAERenderUrl?.path ?? "")
		_useRosetta = State(initialValue: p.customAEUseRosetta)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(spacing: 12) {
					// Project Metadata
					UMUISection("Project Details") {
						VStack(alignment: .leading, spacing: 8) {
							UMUITextField(
								label: "Project Name:",
								placeholder: "My Project",
								value: Binding(
									get: { projectName },
									set: { val in
										projectName = val
										vc.project.name = val
										vc.project.save()
										vc.project.notifyUpdate()
									}
								),
								size: .small,
								labelWidth: 100
							)
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
					
					// After Effects Project
					UMUISection("After Effects Project") {
						VStack(alignment: .leading, spacing: 10) {
							ProjectAepDropZone(path: aepPath, hasWarning: !aepExists) { url in
								vc.project.aeProjectFileUrl = url
								vc.project.save()
								vc.project.notifyUpdate()
								refreshData()
							}
							
							HStack(spacing: 8) {
								Spacer()
								UMUICapsuleButton("Open in After Effects", style: .gray, size: .small) {
									if let url = vc.project.aeProjectFileUrl {
										fu_openFileWithItsApp(url)
									}
								}
								.lineLimit(1)
								.fixedSize()
								
								UMUICapsuleButton("Reveal in Finder", style: .gray, size: .small) {
									if let url = vc.project.aeProjectFileUrl {
										fu_showInFinder(url)
									}
								}
								.lineLimit(1)
								.fixedSize()
							}
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
					
					// Render Output
					UMUISection("Output Directory") {
						VStack(alignment: .leading, spacing: 10) {
							HStack(spacing: 8) {
								Text("Render Folder:")
									.font(.system(size: 11))
									.frame(width: 120, alignment: .leading)
								
								UMUICapsuleButton(renderFolderTitle, style: .gray, size: .small) {
									vc.selectRenderFolder()
								}
								.lineLimit(1)
								.fixedSize()
							}
							
							UMUIMiniSwitch("Render in Subfolder Based on Comp", isOn: Binding(
								get: { renderInSubfolder },
								set: { val in
									renderInSubfolder = val
									vc.project.renderInSubfolders = val
									vc.project.save()
								}
							))
							
							UMUIMiniSwitch("Use Full Comp Name", isOn: Binding(
								get: { useFullCompName },
								set: { val in
									useFullCompName = val
									vc.project.useFullCompNameForSubfolder = val
									vc.project.save()
								}
							))
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
					
					// Comp Naming Prefixes
					UMUISection("Comp Render Naming") {
						VStack(alignment: .leading, spacing: 8) {
							UMUITextField(
								label: "Global Prefix:",
								placeholder: "",
								value: Binding(
									get: { globalPrefix },
									set: { val in
										globalPrefix = val
										vc.project.naming.globalPrefix = val
										vc.project.save()
									}
								),
								size: .small,
								labelWidth: 100
							)
							
							UMUITextField(
								label: "Global Midfix:",
								placeholder: "",
								value: Binding(
									get: { globalMidfix },
									set: { val in
										globalMidfix = val
										vc.project.naming.globalMidfix = val
										vc.project.save()
									}
								),
								size: .small,
								labelWidth: 100
							)
							
							UMUITextField(
								label: "Global Suffix:",
								placeholder: "",
								value: Binding(
									get: { globalSuffix },
									set: { val in
										globalSuffix = val
										vc.project.naming.globalSuffix = val
										vc.project.save()
									}
								),
								size: .small,
								labelWidth: 100
							)
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
					
					// Custom AERender
					UMUISection("Custom AE Engine") {
						VStack(alignment: .leading, spacing: 10) {
							ProjectAERenderDropZone(path: customAERenderPath) { url in
								vc.project.customAERenderUrl = url
								vc.project.save()
								vc.project.notifyUpdate()
								refreshData()
							}
							
							HStack {
								UMUIMiniSwitch("Use Rosetta", isOn: Binding(
									get: { useRosetta },
									set: { val in
										useRosetta = val
										vc.project.customAEUseRosetta = val
										vc.project.save()
									}
								))
								
								Spacer()
								
								if !customAERenderPath.isEmpty {
									UMUICapsuleButton("Clear Custom Engine", style: .gray, size: .small) {
										vc.clearCustomAERender()
										refreshData()
									}
									.lineLimit(1)
									.fixedSize()
								}
							}
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
					
					// Maintenance / Actions
					UMUISection("Project Maintenance") {
						HStack {
							Spacer()
							UMUICapsuleButton("Remove All Records", style: .gray, size: .small) {
								vc.removeAllRecords()
							}
							.lineLimit(1)
							.fixedSize()
							Spacer()
						}
						.padding(10)
						.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
			}
			.background(Color.darkGray.opacity(0.05))
			
			// Footer OK button
			HStack {
				Spacer()
				UMUICapsuleButton("OK", style: .accent, size: .small) {
					vc.close()
				}
				.frame(width: 80)
				.lineLimit(1)
				.fixedSize()
				Spacer()
			}
			.padding(.vertical, 12)
		}
		.frame(minWidth: 500, minHeight: 460)
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAESettingsChanged"))) { _ in
			self.refreshData()
		}
	}
	
	func refreshData() {
		let p = vc.project!
		projectName = p.name
		aepPath = p.aeProjectFileUrl?.path ?? ""
		aepExists = p.aepFilePresent()
		
		let docsFolder = fu_getDocumentsFolderURL().append("_BBAE Render")
		renderFolderTitle = p.renderFolder_ == docsFolder ? "Documents Folder" : p.renderFolder_.lastPathComponent
		
		renderInSubfolder = p.renderInSubfolders
		useFullCompName = p.useFullCompNameForSubfolder
		
		globalPrefix = p.naming.globalPrefix
		globalMidfix = p.naming.globalMidfix
		globalSuffix = p.naming.globalSuffix
		
		customAERenderPath = p.customAERenderUrl?.path ?? ""
		useRosetta = p.customAEUseRosetta
	}
}

// MARK: - Drop Target Subviews

struct ProjectAepDropZone: View {
	let path: String
	let hasWarning: Bool
	let onFileSelected: (URL) -> Void
	
	@State private var isTargeted = false
	
	var body: some View {
		HStack(spacing: 8) {
			Text("After Effects Project:")
				.font(.system(size: 11))
				.frame(width: 120, alignment: .leading)
			
			HStack {
				Text(path.isEmpty ? "Drag Here Adobe After Effects (.aep) File" : URL(fileURLWithPath: path).lastPathComponent)
					.font(.system(size: 11))
					.foregroundColor(path.isEmpty ? .secondary : .primary)
					.lineLimit(1)
					.truncationMode(.middle)
				
				Spacer()
				
				if hasWarning && !path.isEmpty {
					Image(nsImage: NSImage(named: "Icn_Warning_00000") ?? NSImage())
						.resizable()
						.frame(width: 14, height: 14)
				}
			}
			.padding(.horizontal, 8)
			.frame(height: 36)
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 4)
					.fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.1))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 4)
					.stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isTargeted ? 2 : 1)
			)
			.onTapGesture {
				browseAep()
			}
			.onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
				guard let provider = providers.first else { return false }
				_ = provider.loadObject(ofClass: URL.self) { url, error in
					if let url = url, url.pathExtension == "aep" {
						XMain.execute {
							onFileSelected(url)
						}
					}
				}
				return true
			}
		}
	}
	
	private func browseAep() {
		UMFileDialogs.open(
			title: "Select After Effects Project",
			message: "Choose Adobe After Effects project file (.aep)",
			availableExtensions: ["aep"]
		) { url in
			onFileSelected(url)
		}
	}
}

struct ProjectAERenderDropZone: View {
	let path: String
	let onFileSelected: (URL) -> Void
	
	@State private var isTargeted = false
	
	var body: some View {
		HStack(spacing: 8) {
			Text("Custom AERender:")
				.font(.system(size: 11))
				.frame(width: 120, alignment: .leading)
			
			HStack {
				Text(path.isEmpty ? "Drag Here AERender App" : URL(fileURLWithPath: path).parentName)
					.font(.system(size: 11))
					.foregroundColor(path.isEmpty ? .secondary : .primary)
					.lineLimit(1)
					.truncationMode(.middle)
				
				Spacer()
			}
			.padding(.horizontal, 8)
			.frame(height: 36)
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 4)
					.fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.1))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 4)
					.stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isTargeted ? 2 : 1)
			)
			.onTapGesture {
				browseAERender()
			}
			.onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
				guard let provider = providers.first else { return false }
				_ = provider.loadObject(ofClass: URL.self) { url, error in
					if let url = url, url.lastPathComponent == "aerender" {
						XMain.execute {
							onFileSelected(url)
						}
					}
				}
				return true
			}
		}
	}
	
	private func browseAERender() {
		UMFileDialogs.open(
			title: "Select aerender Executable",
			message: "Choose custom aerender executable binary",
			availableExtensions: []
		) { url in
			if url.lastPathComponent == "aerender" {
				onFileSelected(url)
			}
		}
	}
}
