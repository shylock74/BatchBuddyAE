//
//  BBAERecordRowView.swift
//  Batch Buddy AE
//
//  Created by Antigravity on 22/06/2026.
//

import SwiftUI
import UMOmniaFramework
import UMUIControls
import UniformTypeIdentifiers
import UMMovie

// MARK: - BBAERecordRowView

/// Main SwiftUI view for a single record in the project list.
/// Supports both `.normal` (inline fields) and `.compact` (summary row) display modes.
struct BBAERecordRowView: View {

    @ObservedObject var store: BBAERecordObservable
    @ObservedObject var vc: BBAEProjectVC

    // Local state mirrors
    @State private var compId: String
    @State private var isActiveForRendering: Bool
    @State private var outputModuleText: String
    @State private var displayMode: BBAERecord.DisplayMode

    init(store: BBAERecordObservable, vc: BBAEProjectVC) {
        self.store = store
        self.vc = vc
        let r = store.record
        _compId = State(initialValue: r.compId ?? "*")
        _isActiveForRendering = State(initialValue: r.status != .dontRender)
        _displayMode = State(initialValue: r.displayMode)
        _outputModuleText = State(initialValue: Self.computeOutputModule(record: r, project: store.project))
    }

    var body: some View {
        VStack(spacing: 0) {
            if displayMode == .compact {
                compactRow
            } else {
                normalRow
            }

            Divider()
                .background(Color.gray.opacity(0.15))
        }
        .onChange(of: store.refreshToken) { _ in
            syncState()
        }
    }

    // MARK: - Compact Row

    private var compactRow: some View {
        HStack(spacing: 10) {

            // Status icon
            statusDot(store.record.status)
                .frame(width: 10, height: 10)

            // Record ID
            Text(store.record.displayId())
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)

            // Template name
            Text(store.project.getComp(withId: store.record.compId)?.name ?? "Not Set")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            // Status label
            Text(store.record.status.displayString())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(statusColor(store.record.status))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor(store.record.status).opacity(0.12))
                .cornerRadius(4)

            // Render toggle
            UMUIMiniSwitch("", isOn: Binding(
                get: { isActiveForRendering },
                set: { val in
                    isActiveForRendering = val
                    store.record.status = val ? .toBeRendered : .dontRender
                    store.commitSilent()
                }
            ))
            .controlSize(.mini)

            // Quick render button
            UMUICapsuleButton("", systemImage: "play.fill", style: .accent, size: .small) {
                renderRecord()
            }
            .fixedSize()

            // Expand to normal
            UMUICapsuleButton("", systemImage: "chevron.down", style: .gray, size: .small) {
                store.record.displayMode = .normal
                displayMode = .normal
                store.commitSilent()
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(backgroundForStatus(store.record.status))
    }

    // MARK: - Normal Row

    private var normalRow: some View {
        VStack(spacing: 0) {
            // — Row Header —
            HStack(spacing: 10) {

                statusDot(store.record.status)
                    .frame(width: 10, height: 10)

                // Template picker
                Picker("", selection: Binding(
                    get: { compId },
                    set: { val in
                        compId = val
                        let newId = val == "*" ? nil : val
                        if newId != store.record.compId {
                            store.changeCompId(to: newId)
                        }
                        outputModuleText = Self.computeOutputModule(
                            record: store.record,
                            project: store.project
                        )
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
                .frame(maxWidth: .infinity, alignment: .leading)

                if !outputModuleText.isEmpty {
                    Text(outputModuleText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Status label
                Text(store.record.status.displayString())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(statusColor(store.record.status))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(store.record.status).opacity(0.12))
                    .cornerRadius(4)

                // Active for rendering toggle
                UMUIMiniSwitch("Render", isOn: Binding(
                    get: { isActiveForRendering },
                    set: { val in
                        isActiveForRendering = val
                        store.record.status = val ? .toBeRendered : .dontRender
                        store.commitSilent()
                    }
                ))
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // — Fields —
            if let template = store.project.getComp(withId: store.record.compId) {
                VStack(spacing: 2) {
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
                            .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 8)
            } else {
                HStack {
                    Spacer()
                    Text("No Template Selected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            // — Row Footer —
            HStack(spacing: 6) {
                UMUICapsuleButton("Save to Disk", style: .gray, size: .small) {
                    saveToDisk()
                }
                .lineLimit(1).fixedSize()

                UMUICapsuleButton("Reveal", systemImage: "folder", style: .gray, size: .small) {
                    revealInFinder()
                }
                .lineLimit(1).fixedSize()

                UMUICapsuleButton("Go to Template", systemImage: "doc.text", style: .gray, size: .small) {
                    goToTemplate()
                }
                .lineLimit(1).fixedSize()

                Spacer()

                UMUICapsuleButton("Compact", systemImage: "minus.circle", style: .gray, size: .small) {
                    store.record.displayMode = .compact
                    displayMode = .compact
                    store.commitSilent()
                }
                .lineLimit(1).fixedSize()

                UMUICapsuleButton("Duplicate", systemImage: "plus.square.on.square", style: .gray, size: .small) {
                    vc.duplicateRecordInList(store.record.id)
                }
                .lineLimit(1).fixedSize()

                UMUICapsuleButton("Delete", systemImage: "trash", style: .gray, size: .small) {
                    vc.removeRecordFromList(store.record.id)
                }
                .lineLimit(1).fixedSize()

                UMUICapsuleButton("Render", systemImage: "play.fill", style: .accent, size: .small) {
                    renderRecord()
                }
                .lineLimit(1).fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .background(backgroundForStatus(store.record.status))
        .cornerRadius(0)
    }

    // MARK: - Actions

    private func renderRecord() {
        guard store.project.aepFilePresent() else {
            UMAlert.ok(message: "Alert", informativeText: "After Effects file (AEP) missing.")
            return
        }
        guard let comp = store.project.getComp(withId: store.record.compId) else {
            UMAlert.ok(message: "Alert", informativeText: "No Comp with this Id")
            return
        }
        guard BBAESettings.shared.aeRenderExists() else {
            UMAlert.ok(message: "Alert", informativeText: "AERender not present.")
            return
        }
        BBAERenderingVC.showSheet(currentController: vc)
        Queue.execute { [self] in
            guard License.licenseValidated else {
                XMain.execute { BBAERenderingVC.hide() }
                XMain.execute(after: 0.5) {
                    UMAlert.ok(message: "Warning", informativeText: "Unlicensed.")
                }
                return
            }
            store.project.renderedCount = 0
            if comp.isGroup == true {
                store.project.toBeRenderedCount = comp.compGroupList?.filter { $0.active }.count ?? 0
            } else {
                store.project.toBeRenderedCount = 1
            }
            BBAERenderingVC.setTotalCount(store.project.toBeRenderedCount)
            
            let record = store.record
            let project = store.project
            record.status = .rendering
            project.notifyUpdate()
            project.renderRecord(record) { success, error in
                XMain.execute { BBAERenderingVC.hide() }
                record.status = success ? .rendered : .toBeRendered
                XMain.execute { vc.updateLiveData() }
                if !success {
                    XMain.execute(after: 0.5) {
                        UMAlert.ok(message: "After Effects Render Error", informativeText: error)
                    }
                }
            }
        }
    }

    private func saveToDisk() {
        guard let comp = store.project.getComp(withId: store.record.compId) else { return }
        UMProgressVC_Type0.show(
            currentController: vc,
            imgProgressPrefix: "BBAE_Progress_",
            status: "Saving Data..."
        )
        Queue.execute { [self] in
            store.record.prepareFiles(inProject: store.project, comp: comp)
            UMProgressVC_Type0.hide()
        }
    }

    private func revealInFinder() {
        let renderFileUrl = store.project.renderFileUrl(store.record, templateGroup: nil, fileExtension: "")
        fu_showInFinder(renderFileUrl.parent)
    }

    private func goToTemplate() {
        BBAETemplateListVC.showWindow(bbaeProject: store.project,
                                      selectedTemplateId: store.record.compId)
    }

    // MARK: - Sync

    private func syncState() {
        let r = store.record
        compId = r.compId ?? "*"
        isActiveForRendering = r.status != .dontRender
        displayMode = r.displayMode
        outputModuleText = Self.computeOutputModule(record: r, project: store.project)
    }

    // MARK: - Helpers

    static func computeOutputModule(record: BBAERecord, project: BBAEProject) -> String {
        guard let template = project.getComp(withId: record.compId) else { return "" }
        if template.isGroup == true {
            let t = template.compGroupList?.count ?? 0
            let nActive = template.compGroupList?.filter { $0.active }.count ?? 0
            return "Group (\(t) templates, \(nActive) active)"
        }
        return template.outputModule() ?? ""
    }

    private func statusColor(_ status: BBAERecord.Status) -> Color {
        switch status {
        case .toBeRendered: return .orange
        case .dontRender:   return .secondary
        case .rendering:    return .blue
        case .rendered:     return .green
        }
    }

    @ViewBuilder
    private func statusDot(_ status: BBAERecord.Status) -> some View {
        Circle()
            .fill(statusColor(status))
            .shadow(color: statusColor(status).opacity(0.5), radius: 3)
    }

    private func backgroundForStatus(_ status: BBAERecord.Status) -> Color {
        switch status {
        case .rendering: return Color.blue.opacity(0.04)
        case .rendered:  return Color.green.opacity(0.03)
        default:         return Color.clear
        }
    }
}
