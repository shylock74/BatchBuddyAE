//
//  AppDelegate.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 14/04/2021.
//

import Cocoa
import UMOmniaFramework

@main
class AppDelegate : NSObject,
					NSApplicationDelegate {
	
	func applicationShouldTerminateAfterLastWindowClosed (_ sender: NSApplication) -> Bool {
		false
	}
	
    func applicationDidFinishLaunching (_ aNotification: Notification) {
		BBAEProject.startup { bbaeProject in
			if BBAESettings.shared.atLaunch == .openLast {
				BBAEProjectVC.showWindow (bbaeProject: bbaeProject, isNew: false)
			}
		}
		setupMenuOpenRecent ()
		
		Boot.boot (kAppIdLong: "Batch Buddy AE",
				   kAppName: "Batch Buddy AE",
				   kAppIdShort: "BB10",
				   purchaseUrl: "https://ulti.media/product/batch-buddy-ae-early-access/",
				   logoImageUrl: "https://ulti.media/wp-content/uploads/2021/12/BBAE-Logo-Boxed-0-00-00-00.png",
				   logoImageAlt: "Batch Buddy AE Converter Logo",
				   downloadAppUrl: "https://ultimediacloud.net/repository/apps/Batch-Buddy-AE.app.zip",
				   brandColor: UMColor (1, 0, 0.75))
    }

    func applicationWillTerminate (_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
	
	func application (_ sender :			NSApplication,
					  openFiles filenames :	[String]) {
		for fileName in filenames {
			let url = URL (fileURLWithPath: fileName)
			open (url: url)
		}
	}
	
	func application (_ application :	NSApplication,
					  open  :			[URL]) {
		for url in open {
			self.open (url: url)
		}
	}
	
	func application (_ sender :			NSApplication,
					  openFile filename :	String) -> Bool {
		let url = URL (fileURLWithPath: filename)
		open (url: url)
		return true
	}
	
	private func application (_ application :	NSApplication,
							  openFile :		String) {
		let url = URL (fileURLWithPath: openFile)
		open (url: url)
	}
	
	// MARK: - Menu
	@IBOutlet weak var mnuOpenRecent: NSMenuItem!
	
	func open (url :	URL) {
		guard let project = BBAEProject (url: url) else { return }
		BBAEProject.lastProjectUrl = url.path
		BBAEProjectVC.showWindow (bbaeProject: project,
								  isNew: false)
		UMRecentFiles.addFile (name: project.name,
							   url: project.url)
	}
	
	// MARK: - setupMenuOpenRecent
	func setupMenuOpenRecent () {
		UMRecentFiles.fillRecentFilesMenu (menu: mnuOpenRecent) { url in
			self.open (url: url)
		}
		
		if BBAESettings.shared.atLaunch == .showRecents {
			UMOpenRecentVC.showWindow (image: Draw.getImage ("BBAE_Icon (0-00-00-00)"),
									   fileIcon: Draw.getImage ("BBAE_DocumentIcon"),
									   createNewCallback: {
				self.mnuNewSelected ("")
			}) { urlToOpen in
				self.open (url: urlToOpen)
			} deleteFileCallback: { urlToDelete in
				UMRecentFiles.removeRecentFile (withUrl: urlToDelete)
				UMOpenRecentVC.refresh ()
				UMRecentFiles.fillRecentFilesMenu (menu: self.mnuOpenRecent) { url in
					self.open (url: url)
				}
			}
		}
	}
	
	@IBAction func mnuPreferencesSelected(_ sender: Any) {
		BBAESettingsVC.showWindow ()
	}
	
	@IBAction func mnuNewSelected (_ sender: Any) {
		BBAEProject.new { bbaeProject in
			BBAEProjectVC.showWindow (bbaeProject: bbaeProject, isNew: true)
			UMRecentFiles.addFile (name: bbaeProject.name,
								   url: bbaeProject.url)
			self.setupMenuOpenRecent ()
		}
	}
	
	@IBAction func mnuOpenSelected (_ sender: Any) {
		BBAEProject.open { bbaeProject in
			BBAEProjectVC.showWindow (bbaeProject: bbaeProject, isNew: false)
			UMRecentFiles.addFile (name: bbaeProject.name,
								   url: bbaeProject.url)
		}
	}
	
	@IBAction func mnuProjectSettingsSelected (_ sender: Any) {
		guard let controller = NSApplication.shared.mainWindow?.contentViewController as? BBAEProjectVC else { return }
		controller.btnProjectSettingsPressed ("")
	}
		
	@IBAction func mnyNewFieldSelected (_ sender: NSMenuItem) {
		let allControllers = UMWindowsGroup.shared.getAllContollers ()
		allControllers.forEach {
			($0 as? BBAETemplateListVC)?.newItem (tag: sender.tag)
		}
	}
		
	@IBAction func mnuOpenAfterEffectsProjectSelected (_ sender: Any) {
		if let projectController = UMWindows.keyWindowController as? BBAEProjectVC {
			projectController.project.openAEproject ()
		}
		if let compController = UMWindows.keyWindowController as? BBAETemplateListVC {
			compController.project.openAEproject ()
		}
	}
	
	@IBAction func mnuOpenCompTemplatesWindowSelected (_ sender: Any) {
		if let projectController = UMWindows.keyWindowController as? BBAEProjectVC {
			BBAETemplateListVC.showWindow (bbaeProject: projectController.project,
										   selectedTemplateId: nil)
		}
	}
	
	@IBAction func mnuOpenColorsWindowSelected (_ sender: Any) {
		if let projectController = UMWindows.keyWindowController as? BBAEProjectVC {
			BBAEProjectColorListVC.showWindow (bbaeProject: projectController.project)
		}
	}
	
	@IBAction func mnuNewWindowForProjectSelected(_ sender: Any) {
		if let projectController = UMWindows.keyWindowController as? BBAEProjectVC {
			BBAEProjectVC.showWindow (bbaeProject: projectController.project,
									  isNew: false)
		}
	}
	
}

