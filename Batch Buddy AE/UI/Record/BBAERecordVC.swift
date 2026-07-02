//
//  BBAERecordVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 29/07/2021.
//  Modernized with SwiftUI components.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls

class BBAERecordVC: UMViewController, ObservableObject {
	static let storyboardId = "BBAERecordVC"
	static let storyboardName = "BBAETemplatePanel"
	
	// Retained for storyboard compatibility
	@IBOutlet weak var tblList: UMTableView?
	
	var project: BBAEProject!
	var record: BBAERecord!
	
	@Published var listRefreshId = UUID()
	private var store: BBAERecordObservable!
	
	static func showWindow(instance: BBAERecord, project: BBAEProject) {
		UMWindowsGroup.shared.show(id: "media.ulti.bbae.bbaeinstancevc.\(instance.id)",
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
	
	override func loaded() {
		self.store = BBAERecordObservable(record: record, project: project)
		
		let rootView = BBAERecordWindowView(store: store, vc: self)
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
	
	override func willAppear() {
		updateTitle()
	}
	
	private func setupObservers() {
		let projectKey = "media.ulti.bbae.projectUpdate.\(project.id)"
		UMDispatch.observe(key: projectKey, myId: UMId.newId(useCounter: false)) { [weak self] in
			XMain.execute {
				self?.listRefreshId = UUID()
				self?.updateTitle()
			}
		}
	}
	
	func updateTitle() {
		let template = project.getComp(withId: record.compId)
		windowTitle = (template?.name ?? "Template") + " Instance"
	}
}

// MARK: - SwiftUI View Container

struct BBAERecordWindowView: View {
	@ObservedObject var store: BBAERecordObservable
	@ObservedObject var vc: BBAERecordVC
	
	@State private var compId: String
	@State private var isActiveForRendering: Bool
	
	init(store: BBAERecordObservable, vc: BBAERecordVC) {
		self.store = store
		self.vc = vc
		_compId = State(initialValue: store.record.compId ?? "*")
		_isActiveForRendering = State(initialValue: store.record.status != .dontRender)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Configuration Section
			VStack(spacing: 10) {
				HStack(spacing: 12) {
					Text("Template:")
						.font(.system(size: 11))
						.frame(width: 80, alignment: .leading)
					
					Picker("", selection: Binding(
						get: { compId },
						set: { val in
							compId = val
							let newId = val == "*" ? nil : val
							if newId != store.record.compId {
								store.changeCompId(to: newId)
							}
							store.commit()
						}
					)) {
						Text("Not Set").tag("*")
						Divider()
						ForEach(store.project.compList, id: \.id) { comp in
							Text(comp.name).tag(comp.id)
						}
					}
					.labelsHidden()
					.frame(maxWidth: 180)
					
					Spacer()
					
					UMUIMiniSwitch("Render", isOn: Binding(
						get: { isActiveForRendering },
						set: { val in
							isActiveForRendering = val
							store.record.status = val ? .toBeRendered : .dontRender
							store.commitSilent()
						}
					))
				}
				
				let outputText = BBAERecordRowView.computeOutputModule(record: store.record, project: store.project)
				if !outputText.isEmpty {
					HStack {
						Text(outputText)
							.font(.system(size: 10))
							.foregroundColor(.secondary)
						Spacer()
					}
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 14)
			.padding(.bottom, 12)
			.background(Color.mildDarkGray.opacity(0.15))
			
			Divider()
			
			// Fields ScrollView
			ScrollView(.vertical) {
				VStack(spacing: 2) {
					if let template = store.project.getComp(withId: store.record.compId) {
						let fields = template.fieldList
						let values = store.record.recordFieldValueList
						ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
							if index < values.count {
								let fieldValue = values[index]
								FieldRowView(
									field: field,
									fieldValue: fieldValue,
									record: store.record,
									project: store.project,
									onModified: {
										store.commit()
									}
								)
							}
						}
					} else {
						Spacer()
						Text("No Template Selected")
							.foregroundColor(.secondary)
							.font(.system(size: 11))
						Spacer()
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}
			
			Divider()
			
			// Footer Actions
			HStack(spacing: 8) {
				UMUICapsuleButton("Reveal", systemImage: "folder", style: .gray, size: .small) {
					let renderFileUrl = store.project.renderFileUrl(store.record, templateGroup: nil, fileExtension: "")
					fu_showInFinder(renderFileUrl.parent)
				}
				
				Spacer()
				
				UMUICapsuleButton("OK", style: .accent, size: .small) {
					vc.close()
				}
				.frame(width: 80)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(Color.mildDarkGray.opacity(0.15))
		}
		.frame(minWidth: 500, minHeight: 350)
	}
}
