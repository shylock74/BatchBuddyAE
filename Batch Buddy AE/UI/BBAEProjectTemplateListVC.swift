//
//  BBAEProjectTemplateListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls

class BBAEProjectTemplateListVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAEProjectTemplateListVC"
	
	// MARK: - UI Elements
	@IBOutlet weak var tblList: NSTableView?
	
	// MARK: - Vars
	var bbaeProject :	BBAEProject?
	
	private let vcObserverId = UMId.newId(useCounter: false)
	
	// MARK: - View Cycle
	override func loaded () {
		let rootView = BBAEProjectTemplateListView(vc: self)
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
		NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
	}
	
	func setupObservers() {
		guard let project = bbaeProject else { return }
		let projectKey = "media.ulti.bbae.projectUpdate.\(project.id)"
		UMDispatch.observe(key: projectKey, myId: vcObserverId) { [weak self] in
			XMain.execute {
				NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
			}
		}
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   bbaeProject :	BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	// MARK: - Actions
	func addTemplate () {
		bbaeProject?.compList.append (BBAEComp (name: ""))
		bbaeProject?.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
	}
	
	func removeTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject!.compList = bbaeProject!.compList.filter { $0.id != bbaeTemplate.id }
		bbaeProject!.save ()
		bbaeProject!.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
	}
	
	func updateTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject!.save ()
		bbaeProject!.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
	}
	
	func duplicateTemplate (bbaeTemplate: BBAEComp) {
		bbaeProject?.duplicateTemplate (bbaeTemplate)
		bbaeProject?.save ()
		bbaeProject?.notifyUpdate ()
		NotificationCenter.default.post(name: NSNotification.Name("BBAEProjectTemplatesChanged"), object: nil)
	}
}

// MARK: - SwiftUI Views

struct BBAEProjectTemplateListView: View {
	@ObservedObject var vc: BBAEProjectTemplateListVC
	
	@State private var templates: [BBAEComp] = []
	
	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Project Templates")
					.font(.headline)
					.foregroundColor(.primary)
				
				Spacer()
				
				UMUICapsuleButton("", systemImage: "plus", style: .accent, size: .small) {
					vc.addTemplate()
				}
				.frame(width: 28)
				.lineLimit(1)
				.fixedSize()
			}
			.padding(.horizontal, 16)
			.padding(.top, 16)
			.padding(.bottom, 12)
			
			// Scroll View
			ScrollView {
				LazyVStack(spacing: 8) {
					ForEach(templates, id: \.id) { comp in
						TemplateRowView(comp: comp, vc: vc)
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}
			.background(Color.darkGray.opacity(0.05))
			
			UMUIVSpacer(8)
			
			// Footer
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
		.frame(minWidth: 500, minHeight: 350)
		.onAppear {
			refreshTemplates()
		}
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BBAEProjectTemplatesChanged"))) { _ in
			refreshTemplates()
		}
	}
	
	private func refreshTemplates() {
		templates = vc.bbaeProject?.compList ?? []
	}
}

struct TemplateRowView: View {
	let comp: BBAEComp
	let vc: BBAEProjectTemplateListVC
	
	@State private var name: String
	@State private var shortName: String
	@State private var defaultColorId: String
	
	init(comp: BBAEComp, vc: BBAEProjectTemplateListVC) {
		self.comp = comp
		self.vc = vc
		_name = State(initialValue: comp.name)
		_shortName = State(initialValue: comp.shortName)
		_defaultColorId = State(initialValue: comp.defaultColorId ?? "*")
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 8) {
				// Name
				UMUITextField(
					label: "Name:",
					placeholder: "Composition Name",
					value: Binding(
						get: { name },
						set: { val in
							name = val
							comp.name = val
							vc.updateTemplate(bbaeTemplate: comp)
						}
					),
					size: .small,
					labelWidth: 80
				)
				
				Spacer()
				
				// Actions
				UMUICapsuleButton("", systemImage: "plus.on.plus", style: .gray, size: .small) {
					vc.duplicateTemplate(bbaeTemplate: comp)
				}
				.lineLimit(1)
				.fixedSize()
				
				UMUICapsuleButton("", systemImage: "trash", style: .gray, size: .small) {
					vc.removeTemplate(bbaeTemplate: comp)
				}
				.lineLimit(1)
				.fixedSize()
			}
			
			HStack(spacing: 8) {
				// Short name
				UMUITextField(
					label: "Short Name:",
					placeholder: "Short Name",
					value: Binding(
						get: { shortName },
						set: { val in
							shortName = val
							comp.setShortName(val)
							vc.updateTemplate(bbaeTemplate: comp)
						}
					),
					size: .small,
					labelWidth: 80
				)
				
				Spacer()
				
				// Default Color Selector
				HStack(spacing: 4) {
					Text("Default Color:")
						.font(.system(size: 11))
						.frame(width: 80, alignment: .trailing)
					
					Picker("", selection: Binding(
						get: { defaultColorId },
						set: { val in
							defaultColorId = val
							comp.defaultColorId = val == "*" ? nil : val
							vc.updateTemplate(bbaeTemplate: comp)
						}
					)) {
						Text("Not Set").tag("*")
						if let project = vc.bbaeProject {
							ForEach(project.colorList, id: \.id) { colorItem in
								Text(colorItem.name).tag(colorItem.id)
							}
						}
					}
					.labelsHidden()
					.frame(width: 120)
				}
			}
		}
		.padding(10)
		.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
	}
}
