//
//  BBAERenderingVC.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 30/09/2021.
//

import Cocoa
import SwiftUI
import UMOmniaFramework

// MARK: - SwiftUI Reactive Model
class BBAERenderingModel : ObservableObject {
	@Published var title: String = "Rendering..."
	@Published var record: String = ""
	@Published var status: String = ""
	@Published var stats: String = ""
	@Published var fileSize: String = ""
	@Published var etaString: String = ""
	
	@Published var currentItemPercentage: Double = 0.0
	@Published var currentItemN: Double = 0.0
	@Published var totalCount: Double = 1.0 {
		didSet {
			updateCount ()
			if totalCount == 0 {
				eta = LocalETA ()
			}
		}
	}
	
	var eta = LocalETA ()
	
	var globalProgress: Double {
		guard totalCount > 0 else { return 0 }
		return (currentItemN + currentItemPercentage) / totalCount
	}
	
	var counterString: String {
		return "\(Int (currentItemN + 1)) of \(Int (totalCount))"
	}
	
	var itemPercentageString: String {
		return "\(Int (currentItemPercentage * 100))%"
	}
	
	var globalPercentageString: String {
		return "\(Int (globalProgress * 100))%"
	}
	
	func updateCount () {
		etaString = eta.getDiscorsiveEta (percentage: globalProgress)
	}
	
	func reset () {
		title = "Rendering..."
		record = ""
		status = ""
		stats = ""
		fileSize = ""
		etaString = ""
		currentItemPercentage = 0.0
		currentItemN = 0.0
		totalCount = 1.0
		eta = LocalETA ()
	}
}

// MARK: - Custom Premium Progress Bar
struct PremiumProgressBar : View {
	var value: Double
	var color: Color = .accentColor
	
	var body: some View {
		GeometryReader { geo in
			ZStack (alignment: .leading) {
				Capsule ()
					.fill (Color.primary.opacity (0.1))
					.frame (height: 6)
				
				Capsule ()
					.fill (
						LinearGradient (
							gradient: Gradient (colors: [color, color.opacity (0.75)]),
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.frame (width: geo.size.width * CGFloat (min (max (value, 0.0), 1.0)), height: 6)
					.animation (.spring (response: 0.35, dampingFraction: 0.75), value: value)
			}
		}
		.frame (height: 6)
	}
}

// MARK: - SwiftUI Premium View
struct BBAERenderingView : View {
	@ObservedObject var model: BBAERenderingModel
	
	var body: some View {
		VStack (alignment: .leading, spacing: 14) {
			// Header Area
			HStack (spacing: 12) {
				// Animated Rotating Circle Spinner
				Circle ()
					.trim (from: 0, to: 0.7)
					.stroke (
						LinearGradient (
							gradient: Gradient (colors: [.accentColor, .accentColor.opacity (0.4)]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						style: StrokeStyle (lineWidth: 2.5, lineCap: .round)
					)
					.frame (width: 22, height: 22)
					.rotationEffect (Angle (degrees: model.currentItemPercentage * 360 * 3))
					.animation (.linear (duration: 1.5).repeatForever (autoreverses: false), value: model.currentItemPercentage)
				
				Text (model.title)
					.font (.system (size: 14, weight: .bold, design: .rounded))
					.foregroundColor (.primary)
					.lineLimit (1)
				
				Spacer ()
				
				// Batch Index Badge
				Text (model.counterString)
					.font (.system (size: 10, weight: .semibold, design: .monospaced))
					.padding (.horizontal, 8)
					.padding (.vertical, 3)
					.background (Color.accentColor.opacity (0.15))
					.cornerRadius (6)
					.foregroundColor (.accentColor)
			}
			
			// Active Record Card
			VStack (alignment: .leading, spacing: 6) {
				Text (model.record.isEmpty ? "Preparing Composition..." : model.record)
					.font (.system (size: 13, weight: .semibold, design: .rounded))
					.foregroundColor (.primary)
					.lineLimit (1)
				
				HStack (spacing: 6) {
					Text (model.status.isEmpty ? "Setting up..." : model.status)
						.font (.system (size: 11))
						.foregroundColor (.secondary)
					
					if !model.stats.isEmpty {
						Spacer ()
						Text (model.stats)
							.font (.system (size: 10, weight: .medium, design: .monospaced))
							.foregroundColor (.accentColor)
					}
				}
			}
			.padding (12)
			.background (Color.primary.opacity (0.05))
			.cornerRadius (8)
			
			// Progress Bars
			VStack (spacing: 12) {
				// Item Progress
				VStack (alignment: .leading, spacing: 4) {
					HStack {
						Text ("Active Slide / Frame")
							.font (.system (size: 10, weight: .semibold))
							.foregroundColor (.secondary)
						Spacer ()
						Text (model.itemPercentageString)
							.font (.system (size: 11, weight: .bold, design: .monospaced))
							.foregroundColor (.primary)
					}
					PremiumProgressBar (value: model.currentItemPercentage, color: .accentColor)
				}
				
				// Global Progress
				VStack (alignment: .leading, spacing: 4) {
					HStack {
						Text ("Total Batch Progress")
							.font (.system (size: 10, weight: .semibold))
							.foregroundColor (.secondary)
						Spacer ()
						Text (model.globalPercentageString)
							.font (.system (size: 11, weight: .bold, design: .monospaced))
							.foregroundColor (.accentColor)
					}
					PremiumProgressBar (value: model.globalProgress, color: .accentColor)
				}
			}
			
			// Footer Statistics
			HStack {
				// ETA Widget
				if !model.etaString.isEmpty {
					HStack (spacing: 5) {
						Image (systemName: "clock")
							.font (.system (size: 10))
						Text (model.etaString)
							.font (.system (size: 11, design: .rounded))
					}
					.foregroundColor (.secondary)
				}
				
				Spacer ()
				
				// File Size Widget
				if !model.fileSize.isEmpty {
					HStack (spacing: 5) {
						Image (systemName: "doc.zipper")
							.font (.system (size: 10))
						Text (model.fileSize)
							.font (.system (size: 11, weight: .semibold, design: .monospaced))
					}
					.foregroundColor (.accentColor)
				}
			}
			.padding (.top, 2)
		}
		.padding (20)
		.frame (width: 440, height: 260)
	}
}

// MARK: - AppKit / SwiftUI Hybrid ViewController
class BBAERenderingVC : UMViewController {
	
	static let storyboardId = 	"BBAERenderingVC"
	static let storyboardName =	"BBAERenderingVC"
	
	// Keep outlets as optionals for Storyboard compatibility (prevents AppKit runtime load crashes)
	@IBOutlet weak var lblRenderingStatus: NSTextField?
	@IBOutlet weak var lblRecord: NSTextField?
	@IBOutlet weak var lblStatus: NSTextField?
	@IBOutlet weak var lblStats: NSTextField?
	@IBOutlet weak var barItemProgress: NSProgressIndicator?
	@IBOutlet weak var barGlobalProgress: NSProgressIndicator?
	@IBOutlet weak var lblCounter: NSTextField?
	@IBOutlet weak var lblPercentage: NSTextField?
	@IBOutlet weak var lblGlobalPercentage: NSTextField?
	@IBOutlet weak var lblEta: NSTextField?
	@IBOutlet weak var lblFileSize: NSTextField?
	
	// Static Observable Model instance
	static let model = BBAERenderingModel ()
	static var vc : BBAERenderingVC? = nil
	
	// MARK: - View Cycle
	override func viewDidLoad () {
		super.viewDidLoad ()
		
		// Remove all existing subviews loaded from the storyboard to prevent overlapping!
		self.view.subviews.forEach { $0.removeFromSuperview () }
		
		// Set the preferredContentSize of the ViewController to match our SwiftUI frame exactly
		self.preferredContentSize = CGSize (width: 440, height: 260)
		
		// Seamlessly embed the modern SwiftUI View inside NSHostingView
		let hostingView = NSHostingView (rootView: BBAERenderingView (model: Self.model))
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		
		self.view.addSubview (hostingView)
		
		NSLayoutConstraint.activate ([
			hostingView.leadingAnchor.constraint (equalTo: self.view.leadingAnchor),
			hostingView.trailingAnchor.constraint (equalTo: self.view.trailingAnchor),
			hostingView.topAnchor.constraint (equalTo: self.view.topAnchor),
			hostingView.bottomAnchor.constraint (equalTo: self.view.bottomAnchor)
		])
	}
	
	override func willAppear () {
		super.willAppear ()
	}
	
	override func loaded () {
		XMain.execute {
			Self.model.reset ()
		}
	}
	
	override func willDisppear () {
		BBAERenderingVC.vc = nil
	}
	
	// MARK: - Fully Transparent Static Setters
	static func setTitle (_ s : String) {
		XMain.execute {
			model.title = s
		}
	}

	static func setStatus (_ s : String) {
		XMain.execute {
			model.status = s
		}
	}
	
	static func setStats (_ s : String) {
		XMain.execute {
			model.stats = s
		}
	}

	static func setRecord (_ s : String) {
		XMain.execute {
			model.record = s
		}
	}
	
	static func setItemPercentage (_ p : Double) {
		XMain.execute {
			model.currentItemPercentage = p
			model.updateCount ()
		}
	}
	
	static func setTotalCount (_ n : Int) {
		XMain.execute {
			model.totalCount = Double (n)
			model.updateCount ()
		}
	}
	
	static func setCurrentItemN (_ i : Int) {
		XMain.execute {
			model.currentItemN = Double (i)
			model.currentItemPercentage = 0
			model.updateCount ()
		}
	}
	
	static func setFileSize (_ size : Int) {
		XMain.execute {
			model.fileSize = fu_getReadableFileSizeBySizeShort (size)
			model.updateCount ()
		}
	}
	
	// MARK: - Sheet Control Methods
	static func showSheet (currentController : NSViewController) {
		_ = UMWindows.sheet (Self.storyboardId,
							 Self.storyboardName,
							 currentViewController: currentController,
							 disableResize: true) { vc in
			guard let vc = vc as? Self else { return }
			BBAERenderingVC.vc = vc
		}
	}
	
	static func hide () {
		vc?.close ()
	}
}
