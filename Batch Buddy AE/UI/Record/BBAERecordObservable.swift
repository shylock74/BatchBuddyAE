//
//  BBAERecordObservable.swift
//  Batch Buddy AE
//
//  Created by Antigravity on 22/06/2026.
//

import Foundation
import UMOmniaFramework

/// A thin `ObservableObject` wrapper around `BBAERecord`.
/// The underlying `BBAERecord` model stays unchanged (Codable, non-Observable).
/// This class bridges UMDispatch notifications → SwiftUI @Published refreshes.
final class BBAERecordObservable: ObservableObject, Identifiable {

    // MARK: - Public
    let record: BBAERecord
    let project: BBAEProject

    /// Bumped whenever any data in this record changes.
    @Published var refreshToken = UUID()

    var id: String { record.id }

    // MARK: - Private
    private let observerId = UMId.newId(useCounter: false)
    private var observedKeys: [String] = []

    // MARK: - Init
    init(record: BBAERecord, project: BBAEProject) {
        self.record = record
        self.project = project
        setupObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Observers
    private func setupObservers() {
        removeObservers()

        // Project-level updates (covers all records)
        let projectKey = "media.ulti.bbae.projectUpdate.\(project.id)"
        UMDispatch.observe(key: projectKey, myId: observerId) { [weak self] in
            XMain.execute { self?.refreshToken = UUID() }
        }
        observedKeys.append(projectKey)

        // Record-level updates
        let recordKey = record.id
        UMDispatch.observe(key: recordKey, myId: observerId) { [weak self] in
            XMain.execute { self?.refreshToken = UUID() }
        }
        observedKeys.append(recordKey)

        // Template-level updates (comp changes affect field layout)
        if let comp = record.comp {
            let compKey = "\(comp.subscribableType).\(comp.id)"
            UMDispatch.observe(key: compKey, myId: observerId) { [weak self] in
                XMain.execute { self?.refreshToken = UUID() }
            }
            observedKeys.append(compKey)
        }
    }

    private func removeObservers() {
        for key in observedKeys {
            UMDispatch.remove(key: key, myId: observerId)
        }
        observedKeys.removeAll()
    }

    // MARK: - Commit
    /// Call after any mutation to `record` to persist and notify the rest of the app.
    func commit() {
        record.prepareConfigurationFile(
            url: project.aeProjectFileUrl,
            iteration: nil,
            project: project
        )
        record.status = .toBeRendered
        project.save()
        project.notifyUpdate()
        XMain.execute { [weak self] in
            self?.refreshToken = UUID()
        }
    }

    /// Commit without changing render status (e.g., when only toggling display mode).
    func commitSilent() {
        project.save()
        project.notifyUpdate()
        XMain.execute { [weak self] in
            self?.refreshToken = UUID()
        }
    }

    // MARK: - changeCompId
    func changeCompId(to newId: String?) {
        let previousRecord = record.duplicate()
        record.compId = newId
        for fieldValue in record.recordFieldValueList {
            if let fieldName = fieldValue.templateItem()?.fieldName {
                if let original = previousRecord.recordFieldValueList.first(where: {
                    $0.templateItem()?.fieldName == fieldName
                }) {
                    fieldValue.textContent = original.textContent
                    fieldValue.url = original.url
                    fieldValue.valueContent = original.valueContent
                }
            }
        }
        project.lastTemplateId = newId
        // Re-setup observers to pick up the new comp key
        setupObservers()
    }
}
