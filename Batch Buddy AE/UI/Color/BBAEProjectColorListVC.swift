//
//  BBAEProjectColorListVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 21/04/2021.
//

import Cocoa
import UMOmniaFramework
import SwiftUI
import UMUIControls

class BBAEProjectColorListVC :	UMViewController, ObservableObject {
	
	static let storyboardId = 	"BBAEProjectColorListVC"
	
	// MARK: - UI Elements
	// Outlets made optional to support SwiftUI hosting safely
	@IBOutlet weak var lblColorN: NSTextField?
	@IBOutlet weak var tblList: NSTableView?
	
	// MARK: - Vars
	var bbaeProject :	BBAEProject!
	
	@Published var colors: [BBAEProjectColor] = []
	
	// MARK: - Display
	func updateColorCountlabel () {
		// Count is displayed reactively in SwiftUI
	}
	
	func displayData () {
		colors = bbaeProject.colorList
	}
	
	func registerTableCells () {
		// Table cells registered natively in SwiftUI
	}
	
	// MARK: - View Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let colorListView = BBAEProjectColorListView(vc: self)
		let hostingView = NSHostingView(rootView: colorListView)
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
		displayData ()
	}
	
	override func loaded () { 
		registerTableCells ()
	}
	
	// MARK: - Show
	static func showSheet (currentController :	NSViewController,
						   bbaeProject :		BBAEProject) {
		_ = UMWindows.sheet (Self.storyboardId,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	static func showWindow (bbaeProject :		BBAEProject) {
		UMWindowsGroup.shared.show (id: "media.ulti.bbae.\(bbaeProject.id).colorList",
									viewControllerId: Self.storyboardId,
									windowTitle: "\(bbaeProject.name) Color List",
									minWidth: 600,
									maxWidth: 600,
									minHeight: 320,
									maxHeight: nil) { vc in
			guard let vc = vc as? Self else { return }
			vc.bbaeProject = bbaeProject
		}
	}
	
	override func disappeared () {
		UMWindowsGroup.shared.didClose (id: "media.ulti.bbae.\(bbaeProject.id).colorList")
	}
	
	// MARK: - Actions
	func addColor() {
		let newColor = BBAEProjectColor (name: "New Color",
										 color: UMColor (0, 0, 0))
		bbaeProject.colorList.append (newColor)
		bbaeProject.notifyUpdate ()
		displayData()
	}
	
	@IBAction func btnAddPressed (_ sender: Any) {
		addColor()
	}
	
	@IBAction func btnOkPressed (_ sender: Any) {
		close ()
	}
	
	@IBAction func btnCancelPressed(_ sender: Any) {
		close ()
	}
}

extension BBAEProjectColorListVC :	BBAEProjectColorListCellDelegate {
	
	func removeColor (bbaeColor :	BBAEProjectColor) {
		bbaeProject.colorList = bbaeProject.colorList.filter { $0.id != bbaeColor.id }
		bbaeProject.notifyUpdate ()
		displayData()
	}
}

// MARK: - SwiftUI Views

struct BBAEProjectColorListView: View {
	@ObservedObject var vc: BBAEProjectColorListVC
	
	var body: some View {
		VStack(spacing: 0) {
			// Header bar with title and Add button
			HStack {
				Text("Project Colors (\(vc.colors.count))")
					.font(.headline)
					.foregroundColor(.primary)
				
				Spacer()
				
				UMUICapsuleButton("", systemImage: "plus", style: .accent, size: .small) {
					vc.addColor()
				}
				.frame(width: 28)
				.lineLimit(1)
				.fixedSize()
			}
			.padding(.horizontal, 16)
			.padding(.top, 16)
			.padding(.bottom, 12)
			
			// Color cards list
			ScrollView {
				LazyVStack(spacing: 8) {
					ForEach(vc.colors, id: \.id) { colorItem in
						ColorListRow(colorItem: colorItem, bbaeProject: vc.bbaeProject, vc: vc)
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}
			.background(Color.darkGray.opacity(0.05))
			
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
		.frame(minWidth: 500, minHeight: 320)
	}
}

struct ColorListRow: View {
	let colorItem: BBAEProjectColor
	let bbaeProject: BBAEProject
	let vc: BBAEProjectColorListVC
	
	@State private var colorName: String
	@State private var colorVal: Color
	
	init(colorItem: BBAEProjectColor, bbaeProject: BBAEProject, vc: BBAEProjectColorListVC) {
		self.colorItem = colorItem
		self.bbaeProject = bbaeProject
		self.vc = vc
		_colorName = State(initialValue: colorItem.name)
		_colorVal = State(initialValue: Color(colorItem.color.getColor()))
	}
	
	var body: some View {
		HStack(spacing: 8) {
			// Color Name Field
			UMUITextField(
				placeholder: "Color Name",
				value: Binding(
					get: { colorName },
					set: { val in
						colorName = val
						colorItem.name = val
						bbaeProject.saveColorFile(customAEProjectUrl: nil)
						bbaeProject.save()
					}
				),
				size: .small,
				labelWidth: 0
			)
			.frame(width: 140)
			
			// Color Picker well
			ColorPicker("", selection: Binding(
				get: { colorVal },
				set: { val in
					colorVal = val
					colorItem.color = UMColor(val.nsColor)
					bbaeProject.saveColorFile(customAEProjectUrl: nil)
					bbaeProject.save()
				}
			))
			.labelsHidden()
			.frame(width: 40)
			
			Spacer()
			
			// Copy HEX
			UMUICapsuleButton("HEX", style: .gray, size: .small) {
				UMPasteboard.setString(colorItem.hex)
			}
			.lineLimit(1)
			.fixedSize()
			
			// Copy AE Expression Code
			UMUICapsuleButton("AE Code", style: .gray, size: .small) {
				bbaeProject.saveColorFile(customAEProjectUrl: nil)
				let code = BBAESettings.shared.getColorAECodeString(color: colorItem)
				UMPasteboard.setString(code)
				UMShowNotification(title: "Copied", informativeText: "Color \(colorItem.name) Successfully Copied.")
			}
			.lineLimit(1)
			.fixedSize()
			
			// Copy AE Color Fill
			UMUICapsuleButton("Fill", style: .gray, size: .small) {
				bbaeProject.saveColorFile(customAEProjectUrl: nil)
				let code = BBAESettings.shared.getColorFillString(color: colorItem)
				UMPasteboard.setString(code)
				UMShowNotification(title: "Copied", informativeText: "Color \(colorItem.name) Successfully Copied.")
			}
			.lineLimit(1)
			.fixedSize()
			
			// Remove Button
			UMUICapsuleButton("", systemImage: "trash", style: .gray, size: .small) {
				vc.removeColor(bbaeColor: colorItem)
			}
			.lineLimit(1)
			.fixedSize()
		}
		.padding(6)
		.background(UMUIBoxView(cornerRadius: 6, borderWidth: 1, backColor: Color.boxGray.opacity(0.15), foreColor: Color.gray.opacity(0.2)))
	}
}

// MARK: - Color Conversion Helpers

extension Color {
	var nsColor: NSColor {
		if #available(macOS 12.0, *) {
			return NSColor(self)
		} else {
			if let cgColor = self.cgColor {
				return NSColor(cgColor: cgColor) ?? .white
			}
			return .white
		}
	}
}
