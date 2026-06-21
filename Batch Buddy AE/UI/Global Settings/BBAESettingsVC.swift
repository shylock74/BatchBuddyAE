//
//  BBAESettingsVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls
import UniformTypeIdentifiers

class BBAESettingsVC :	UMViewController,
						  UMBasicTableVCDelegate {
	
	enum Tab :	String, CaseIterable {
		case general =		"General"
		case rendering =	"AE Engine & Rendering"
		case caches	=		"AE Caches"
	}
	
	static let storyboardId = 	"BBAESettingsVC"
	static let storyboardName =	"BBAESettings"
	
	// MARK: - Vars
	var goToTab :	Tab?
	
	private let kNotSet =	"Not Set (will use AE Default)"
	
	// MARK: - View Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let settingsView = BBAESettingsView(vc: self, initialTab: goToTab ?? .general)
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
		
		// Setup notification observer for search done
		UMNotify.observe (keyword: AERenderSearcherVC.kNotification) {
			NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsChanged"), object: nil)
		}
	}
	
	override func willAppear () {
		// Handled via NSHostingView lifecycle
	}
	
	override func loaded () {
	}
	
	// MARK: - Show
	static func showWindow (goToTab :	Tab? = nil) {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.BBAESettingsVC",
									viewControllerId: Self.storyboardId,
									storyboardName: Self.storyboardName,
									windowTitle: "BBAE Settings",
									disableResize: false) { vc in
			guard let vc = vc as? Self else { return }
			vc.goToTab = goToTab
			if let goToTab = goToTab {
				NotificationCenter.default.post(name: NSNotification.Name("BBAESettingsSelectTab"), object: goToTab.rawValue)
			}
		}
	}
	
	// MARK: - Actions
	func openRenderSettingsSheet() {
		BBAERenderOutputListVC.showSheet (currentController: self,
										  show: .render)
	}
	
	func openOutputModuleSheet() {
		BBAERenderOutputListVC.showSheet (currentController: self,
										  show: .ouput)
	}
	
	@objc func btnOkPressed (_ sender: Any) {
		close ()
	}
}

// MARK: - SwiftUI Views

struct BBAESettingsView: View {
	@State private var selectedTab: String
	@State private var refreshID = UUID()
	
	let vc: BBAESettingsVC
	
	init(vc: BBAESettingsVC, initialTab: BBAESettingsVC.Tab) {
		self.vc = vc
		_selectedTab = State(initialValue: initialTab.rawValue)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Segmented Bar at the top for Tab selection
			UMUISegmentedBar(
				options: BBAESettingsVC.Tab.allCases.map { $0.rawValue },
				selection: $selectedTab
			)
			.padding(.horizontal, 16)
			.padding(.top, 14)
			
			UMUIVSpacer(12)
			
			// Main Tab View
			Group {
				switch selectedTab {
				case BBAESettingsVC.Tab.general.rawValue:
					BBAESettingsGeneralView()
				case BBAESettingsVC.Tab.rendering.rawValue:
					BBAESettingsRenderingView(vc: vc)
				case BBAESettingsVC.Tab.caches.rawValue:
					BBAESettingsCachesView()
				default:
					EmptyView()
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.id(refreshID)
			
			UMUIVSpacer(8)
			
			// Footer close button
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
			.padding(.bottom, 14)
		}
		.frame(minWidth: 480, minHeight: 420)
		.background(Color.darkGray.opacity(0.05))
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAESettingsChanged"))) { _ in
			self.refreshID = UUID()
		}
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAESettingsSelectTab"))) { notification in
			if let tabName = notification.object as? String {
				self.selectedTab = tabName
			}
		}
	}
}

// MARK: - General Settings Tab

struct BBAESettingsGeneralView: View {
	@State private var carriageReturnStr: String = BBAESettings.shared.carriageReturnString
	@State private var posterFrame: Double = BBAESettings.shared.posterFrameAt
	@State private var showLastAtLaunch: Bool = BBAESettings.shared.atLaunch == .openLast
	
	var body: some View {
		VStack(spacing: 12) {
			UMUISection("Startup & Input") {
				VStack(alignment: .leading, spacing: 10) {
					UMUIMiniSwitch("Show Last Opened Project at Launch", isOn: Binding(
						get: { showLastAtLaunch },
						set: { val in
							showLastAtLaunch = val
							BBAESettings.shared.atLaunch = val ? .openLast : .showRecents
							BBAESettings.shared.save()
						}
					))
					
					UMUIVSpacer(4)
					
					UMUITextField(
						label: "Newline code:",
						placeholder: "%RET%",
						value: Binding(
							get: { carriageReturnStr },
							set: { val in
								carriageReturnStr = val
								BBAESettings.shared.carriageReturnString = val
								BBAESettings.shared.save()
							}
						),
						size: .small,
						labelWidth: 100
					)
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			UMUISection("Video Settings") {
				VStack(alignment: .leading, spacing: 10) {
					HStack(spacing: 8) {
						UMUISlider(
							label: "Poster Frame At:",
							value: Binding(
								get: { posterFrame },
								set: { val in
									posterFrame = val
									BBAESettings.shared.posterFrameAt = val
									BBAESettings.shared.save()
								}
							),
							range: 0...100,
							size: .small,
							labelWidth: 100
						)
						
						Text("\(Int(posterFrame))% of Video")
							.font(.system(size: 11))
							.foregroundColor(.secondary)
							.frame(width: 80, alignment: .leading)
					}
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
	}
}

// MARK: - Rendering Settings Tab

struct BBAESettingsRenderingView: View {
	let vc: BBAESettingsVC
	
	@State private var aeRenderEnginePath: String = BBAESettings.shared.aeRenderEngineUrl?.path ?? ""
	@State private var defaultRenderSettings: String = BBAESettings.shared.defaultRenderSettings ?? "Not Set (will use AE Default)"
	@State private var defaultOutputSettingsId: String = BBAESettings.shared.defaultOutputSettingsId ?? "*"
	
	@State private var reuseAE: Bool = BBAESettings.shared.renderingStuff.reuseAE
	@State private var autoSave: Bool = BBAESettings.shared.renderingStuff.autoSaveurrentDocument
	@State private var autoSaveDelay: Double = Double(BBAESettings.shared.renderingStuff.autoSaveDelay)
	
	@State private var engineExists: Bool = BBAESettings.shared.aeRenderExists()
	
	var body: some View {
		VStack(spacing: 12) {
			UMUISection("After Effects Engine") {
				VStack(alignment: .leading, spacing: 8) {
					HStack(spacing: 8) {
						Text("Render Engine:")
							.font(.system(size: 11))
							.frame(width: 120, alignment: .leading)
						
						UMUICapsuleButton(
							engineButtonTitle,
							style: engineExists ? .gray : .accent,
							size: .small
						) {
							AERenderSearcherVC.showWindow()
						}
						.lineLimit(1)
						.fixedSize()
						
						if !engineExists {
							Image(nsImage: NSImage(named: "Icn_Warning_00000") ?? NSImage())
								.resizable()
								.frame(width: 14, height: 14)
						}
					}
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			UMUISection("Templates") {
				VStack(alignment: .leading, spacing: 8) {
					HStack(spacing: 8) {
						Text("Render Settings:")
							.font(.system(size: 11))
							.frame(width: 120, alignment: .leading)
						
						Picker("", selection: Binding(
							get: { defaultRenderSettings },
							set: { val in
								defaultRenderSettings = val
								BBAESettings.shared.defaultRenderSettings = val == "Not Set (will use AE Default)" ? nil : val
								BBAESettings.shared.save()
							}
						)) {
							ForEach(renderSettingsOptions, id: \.self) { opt in
								Text(opt).tag(opt)
							}
						}
						.pickerStyle(.menu)
						.labelsHidden()
						.controlSize(.small)
						
						Spacer()
						
						UMUICapsuleButton("", systemImage: "gearshape", style: .gray, size: .small) {
							vc.openRenderSettingsSheet()
						}
						.frame(width: 24)
						.lineLimit(1)
						.fixedSize()
					}
					
					HStack(spacing: 8) {
						Text("Output Module:")
							.font(.system(size: 11))
							.frame(width: 120, alignment: .leading)
						
						Picker("", selection: Binding(
							get: { defaultOutputSettingsId },
							set: { val in
								defaultOutputSettingsId = val
								if val != "*" {
									BBAESettings.shared.defaultOutputSettingsId = val
									BBAESettings.shared.save()
								}
							}
						)) {
							ForEach(outputModuleOptions, id: \.id) { opt in
								Text(opt.title).tag(opt.id)
							}
						}
						.pickerStyle(.menu)
						.labelsHidden()
						.controlSize(.small)
						
						Spacer()
						
						UMUICapsuleButton("", systemImage: "gearshape", style: .gray, size: .small) {
							vc.openOutputModuleSheet()
						}
						.frame(width: 24)
						.lineLimit(1)
						.fixedSize()
					}
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			UMUISection("Rendering Options") {
				VStack(alignment: .leading, spacing: 10) {
					UMUIMiniSwitch("Reuse After Effects if Already Open (no second instance)", isOn: Binding(
						get: { reuseAE },
						set: { val in
							reuseAE = val
							BBAESettings.shared.renderingStuff.reuseAE = val
							BBAESettings.shared.save()
						}
					))
					
					UMUIMiniSwitch("Save Current After Effects Project Before Rendering", isOn: Binding(
						get: { autoSave },
						set: { val in
							autoSave = val
							BBAESettings.shared.renderingStuff.autoSaveurrentDocument = val
							BBAESettings.shared.save()
						}
					))
					
					HStack(spacing: 8) {
						UMUISlider(
							label: "Delay Before Rendering:",
							value: Binding(
								get: { autoSaveDelay },
								set: { val in
									autoSaveDelay = val
									BBAESettings.shared.renderingStuff.autoSaveDelay = Int(val)
									BBAESettings.shared.save()
								}
							),
							range: 3...30,
							size: .small,
							labelWidth: 140
						)
						
						Text("\(Int(autoSaveDelay))s")
							.font(.system(size: 11))
							.foregroundColor(.secondary)
							.frame(width: 40, alignment: .leading)
					}
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAESettingsChanged"))) { _ in
			self.refreshData()
		}
	}
	
	private var engineButtonTitle: String {
		guard let url = BBAESettings.shared.aeRenderEngineUrl else {
			return "Select AERender"
		}
		return url.parentName + " > AERender"
	}
	
	private var renderSettingsOptions: [String] {
		var list = (BBAESettings.shared.aeRenderSettingList ?? []).map { $0.title }
		list.append("Not Set (will use AE Default)")
		return list
	}
	
	struct OutputModuleOption {
		let id: String
		let title: String
	}
	
	private var outputModuleOptions: [OutputModuleOption] {
		var list = (BBAESettings.shared.aeOutputModuleList ?? []).map { OutputModuleOption(id: $0.id, title: $0.title) }
		list.append(OutputModuleOption(id: "*", title: "Not Set (will use AE Default)"))
		return list
	}
	
	private func refreshData() {
		aeRenderEnginePath = BBAESettings.shared.aeRenderEngineUrl?.path ?? ""
		defaultRenderSettings = BBAESettings.shared.defaultRenderSettings ?? "Not Set (will use AE Default)"
		defaultOutputSettingsId = BBAESettings.shared.defaultOutputSettingsId ?? "*"
		reuseAE = BBAESettings.shared.renderingStuff.reuseAE
		autoSave = BBAESettings.shared.renderingStuff.autoSaveurrentDocument
		autoSaveDelay = Double(BBAESettings.shared.renderingStuff.autoSaveDelay)
		engineExists = BBAESettings.shared.aeRenderExists()
	}
}

// MARK: - Caches Settings Tab

struct BBAESettingsCachesView: View {
	@State private var cachePaths: [String] = [
		BBAESettings.shared.aeCacheUrlList.indices.contains(0) ? (BBAESettings.shared.aeCacheUrlList[0]?.path ?? "") : "",
		BBAESettings.shared.aeCacheUrlList.indices.contains(1) ? (BBAESettings.shared.aeCacheUrlList[1]?.path ?? "") : "",
		BBAESettings.shared.aeCacheUrlList.indices.contains(2) ? (BBAESettings.shared.aeCacheUrlList[2]?.path ?? "") : ""
	]
	
	@State private var cacheWarnings: [Bool] = [
		!BBAESettings.shared.cacheExists(0),
		!BBAESettings.shared.cacheExists(1),
		!BBAESettings.shared.cacheExists(2)
	]
	
	@State private var cleanCaches: Bool = BBAESettings.shared.cleanCachesBeforeRendering
	
	var body: some View {
		VStack(spacing: 12) {
			UMUISection("After Effects Caches") {
				VStack(spacing: 10) {
					CacheDropZone(
						label: "Disk Cache:",
						path: cachePaths[0],
						hasWarning: cacheWarnings[0]
					) { url in
						BBAESettings.shared.setCacheUrl(forIndex: 0, url: url)
						BBAESettings.shared.save()
						refreshData()
					}
					
					CacheDropZone(
						label: "Media Cache DB:",
						path: cachePaths[1],
						hasWarning: cacheWarnings[1]
					) { url in
						BBAESettings.shared.setCacheUrl(forIndex: 1, url: url)
						BBAESettings.shared.save()
						refreshData()
					}
					
					CacheDropZone(
						label: "Media Cache:",
						path: cachePaths[2],
						hasWarning: cacheWarnings[2]
					) { url in
						BBAESettings.shared.setCacheUrl(forIndex: 2, url: url)
						BBAESettings.shared.save()
						refreshData()
					}
				}
				.padding(10)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			UMUISection("Cache Options") {
				VStack(alignment: .leading, spacing: 8) {
					UMUIMiniSwitch("Clean Caches Before Rendering", isOn: Binding(
						get: { cleanCaches },
						set: { val in
							cleanCaches = val
							BBAESettings.shared.cleanCachesBeforeRendering = val
							BBAESettings.shared.save()
						}
					))
				}
				.padding(10)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
			}
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAESettingsChanged"))) { _ in
			self.refreshData()
		}
	}
	
	private func refreshData() {
		let list = BBAESettings.shared.aeCacheUrlList
		cachePaths = [
			list.indices.contains(0) ? (list[0]?.path ?? "") : "",
			list.indices.contains(1) ? (list[1]?.path ?? "") : "",
			list.indices.contains(2) ? (list[2]?.path ?? "") : ""
		]
		cacheWarnings = [
			!BBAESettings.shared.cacheExists(0),
			!BBAESettings.shared.cacheExists(1),
			!BBAESettings.shared.cacheExists(2)
		]
		cleanCaches = BBAESettings.shared.cleanCachesBeforeRendering
	}
}

// MARK: - Cache Drag and Drop Target Zone

struct CacheDropZone: View {
	let label: String
	let path: String
	let hasWarning: Bool
	let onFolderSelected: (URL) -> Void
	
	@State private var isTargeted = false
	
	var body: some View {
		HStack(spacing: 8) {
			Text(label)
				.font(.system(size: 11))
				.frame(width: 120, alignment: .leading)
			
			// Drop Target Area
			HStack {
				Text(path.isEmpty ? "Drag a folder here or click to browse..." : URL(fileURLWithPath: path).lastPathComponent)
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
			.frame(height: 28)
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
				browseFolder()
			}
			.onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
				guard let provider = providers.first else { return false }
				_ = provider.loadObject(ofClass: URL.self) { url, error in
					if let url = url {
						XMain.execute {
							onFolderSelected(url)
						}
					}
				}
				return true
			}
		}
	}
	
	private func browseFolder() {
		UMFileDialogs.chooseFolder(
			title: "Select Cache Folder",
			message: "Choose Cache Folder For After Effects",
			defaultPath: path.isEmpty ? nil : URL(fileURLWithPath: path)
		) { url in
			if let url = url {
				onFolderSelected(url)
			}
		}
	}
}
