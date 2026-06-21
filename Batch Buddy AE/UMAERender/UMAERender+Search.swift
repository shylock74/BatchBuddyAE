//
//  UMAERender+Search.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 03/12/21.
//

import Foundation
import UMOmniaFramework

extension UMAERender {
	
	static func getEligibleAERenderUrlList (fileScannedCallback :	((Int) -> ())? = nil) -> [URL] {
		let applicationUrls = fu_getApplicationsFolder ()
		var eligibleUrls = [URL] ()
		var scannedFilesCount = 0
		for applicationUrl in applicationUrls {
			let foundUrls = FUList.getFiles (url: applicationUrl,
											 recursive: true,
											 filterStrings: [],
											 searchInHiddenFolders: false,
											 filesScannedCountSoFar: &scannedFilesCount,
											 fileScannedCallback: fileScannedCallback)
			eligibleUrls += foundUrls.filter { $0.name == "aerender" }
		}
		return eligibleUrls
	}
}
