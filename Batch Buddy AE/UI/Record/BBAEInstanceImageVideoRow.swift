//
//  BBAEInstanceImageVideoRow.swift
//  Batch Buddy AE
//
//  Created by Alex Raccuglia on 10/05/2021.
//

import Cocoa
import UMOmniaFramework
import UMImaging
import UMMovie
import ImageIO

class BBAEInstanceImageVideoRow :	UMTableCell {
	
	static let cellId = "BBAEInstanceImageVideoRow"
	
	// MARK: - UI
	@IBOutlet weak var imgFieldType: NSImageView!
	@IBOutlet weak var lblFieldName: UMTextField!
	@IBOutlet weak var drgArea: UMDragArea! //UMDragImageAreaView!
	@IBOutlet weak var lblPath: NSTextField!
	@IBOutlet weak var btnShowInFinder: NSButton!
	
	// MARK: - var
	var record :				BBAERecord!
	var project :				BBAEProject!
	var recordFieldValue :		BBAERecordFieldValue!
	var rowModifiedCallback :	(() -> ())!
	
	private var notificationObserver: NSObjectProtocol?
	
	func cleanObserver () {
		if let observer = notificationObserver {
			UMNotify.removeObserver (observer)
			notificationObserver = nil
		}
	}
	
	override func prepareForReuse () {
		super.prepareForReuse ()
		cleanObserver ()
	}
	
	var templateItem :			BBAECompField? {
		BBAECompField.getField (withId: recordFieldValue.compFieldId)
	}
	
	static let imageCache = UMImageCache (maxImagesInCache: 200)
	static let cacheQueue = DispatchQueue (label: "media.ulti.bbae.imageCacheQueue")
	
	// MARK: - Display

	func downsampleImage (at url: URL, toSize pointSize: CGSize) -> NSImage? {
		let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		guard let imageSource = CGImageSourceCreateWithURL (url as CFURL, imageSourceOptions) else { return nil }
		
		let maxDimensionInPixels = max (pointSize.width, pointSize.height) * 2.0 // Support retina display
		let downsampleOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
		] as CFDictionary
		
		guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex (imageSource, 0, downsampleOptions) else { return nil }
		return NSImage (cgImage: downsampledImage, size: pointSize)
	}

	func videoPoster (url :	URL) -> UMImage? {
		BBAEInstanceImageVideoRow.cacheQueue.sync {
			BBAEInstanceImageVideoRow.imageCache.getImageOrCalc (withId: url.path,
																 maxSize: 120) {
				let generator =	UMMovieUtilsImageGenerator (url: url)
				let image = generator.getUMImage (at: 0, speculativeExecution: false)
				return image
			}
		}
	}
	
	func displayPoster () {
		drgArea.image = nil
		guard let templateItem = templateItem else {
			drgArea.image = nil
			return
		}
		if let url = recordFieldValue.url {
			let tempId = recordFieldValue.id
			
			if templateItem.type == .audio {
				drgArea.image = Draw.getImage ("Icn_AudioFile")
				return
			}
			
			if templateItem.type == .image || templateItem.type == .vectorAI {
				drgArea.image = nil
				Queue.execute { [self] in
					let image = BBAEInstanceImageVideoRow.cacheQueue.sync {
						BBAEInstanceImageVideoRow.imageCache.getImageOrCalc (withId: url.path,
																						 maxSize: 200) {
							if let downsampled = downsampleImage (at: url, toSize: CGSize (width: 200, height: 200)) {
								return UMImage (downsampled)
							}
							return UMImage (url)
						}
					}?.image
					XMain.execute { [weak self] in
						if tempId == self?.recordFieldValue.id {
							self?.drgArea.image = image
						}
					}
				}
			} else {
				drgArea.image = nil
				Queue.execute { [self] in
					let image = videoPoster (url: url)?.image
					XMain.execute { [weak self] in
						if tempId == self?.recordFieldValue.id {
							self?.drgArea.image = image
						}
					}
				}
			}
		}
	}
	
	func setupDragArea () {
		guard let templateItem = templateItem else { return }
		switch templateItem.type {
			case .image:
				drgArea.fileTypes = ["png", "jpg", "jpeg", "tif", "tiff", "psd"]
			case .video:
				drgArea.fileTypes = ["mov", "mp4", "m4v"]
			case .audio:
				drgArea.fileTypes = ["wav", "wave"]
			case .vectorAI:
				drgArea.fileTypes = ["ai"]
			default: break
		}
		displayPoster ()
		drgArea.atUrlDrag { [weak self] urlList in
			guard let self = self else { return }
			let url = urlList [0]
			self.recordFieldValue.url = url
			self.rowModifiedCallback ()
			self.displayPoster ()
			Queue.execute { [weak self] in
				if let project = self?.project {
					self?.record.prepareVideos (project: project)
				}
			}
			self.displayBtnShowInFinder ()
		}
	}
	
	func displayBtnShowInFinder () {
		btnShowInFinder.isHidden = recordFieldValue.url == nil
	}
	
	func displayData () {
		imgFieldType.image = templateItem?.type.image
		lblFieldName.setValue ((templateItem?.fieldName ?? "UNDEFINED") + ":")
		setupDragArea ()
		lblPath.setValue (recordFieldValue.url?.lastPathComponent ?? "")
		displayBtnShowInFinder ()
	}
	
	// MARK: - Actions
	@IBAction func btnRemoveImageLinkPressed(_ sender: Any) {
		recordFieldValue.url = nil
		rowModifiedCallback ()
		displayPoster ()
		displayBtnShowInFinder ()
	}
	
	@IBAction func btnShowInFinderPressed(_ sender: Any) {
		guard let url = recordFieldValue.url else { return }
		fu_showInFinder (url)
	}
	
	// MARK: - Observer
	func setupObserver () {
		cleanObserver ()
		let keyword = "media.ulti.bbae.\(recordFieldValue.compFieldId)"
		notificationObserver = UMNotify.observe (keyword: keyword) { [weak self] _ in
			XMain.execute {
				self?.displayData ()
			}
		}
	}
	
	// MARK: - Show
	static func getCell (_ tableView :  		NSTableView,
						 recordFieldValue :		BBAERecordFieldValue,
						 record :				BBAERecord,
						 project :				BBAEProject,
						 rowModifiedCallback :	@escaping () -> ()) -> Self? {
		guard let cell = tableView.getCell (id: cellId) as? Self else { return nil }
		cell.recordFieldValue = recordFieldValue
		cell.rowModifiedCallback = rowModifiedCallback
		cell.record = record
		cell.project = project
		cell.displayData ()
		cell.setBackground ()
		cell.setupObserver ()
		return cell
	}
	
	// MARK: - Actions

	// MARK: - Register
	// Da chiamare al load
	static func register (_ tableView :	NSTableView) {
		let nib = NSNib.init (nibNamed: cellId,
							  bundle: nil)
		tableView.register (nib,
							forIdentifier: NSUserInterfaceItemIdentifier (rawValue: cellId))
	}
}
