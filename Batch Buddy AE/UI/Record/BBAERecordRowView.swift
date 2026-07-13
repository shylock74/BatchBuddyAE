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

    // Aesthetic additions
    @State private var isHovered: Bool = false
    @State private var isPulsing: Bool = false

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
        }
        .background(backgroundForStatus(store.record.status, isHovered: isHovered))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                self.isHovered = hovering
            }
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
            Text(store.record.status.displayString().uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(statusColor(store.record.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(store.record.status).opacity(0.15))
                .cornerRadius(6)

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
            UMUIMiniButton(style: .accent, action: {
                renderRecord()
            }) {
                Image(systemName: "play.fill")
            }
            .fixedSize()

            // Expand to normal
            UMUIMiniButton(style: .gray, action: {
                store.record.displayMode = .normal
                displayMode = .normal
                store.commitSilent()
            }) {
                Image(systemName: "chevron.down")
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
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
                Text(store.record.status.displayString().uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(statusColor(store.record.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(store.record.status).opacity(0.15))
                    .cornerRadius(6)

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
                UMUIMiniButton("Save", style: .gray) {
                    saveToDisk()
                }
                .lineLimit(1).fixedSize()

                UMUIMiniButton("Reveal", systemImage: "folder", style: .gray) {
                    revealInFinder()
                }
                .lineLimit(1).fixedSize()

                UMUIMiniButton("Template", systemImage: "doc.text", style: .gray) {
                    goToTemplate()
                }
                .lineLimit(1).fixedSize()

                Spacer()

                UMUIMiniButton(style: .gray, action: {
                    store.record.displayMode = .compact
                    displayMode = .compact
                    store.commitSilent()
                }) {
                    Image(systemName: "minus.circle")
                }
                .lineLimit(1).fixedSize()

                UMUIMiniButton(style: .gray, action: {
                    vc.duplicateRecordInList(store.record.id)
                }) {
                    Image(systemName: "plus.square.on.square")
                }
                .lineLimit(1).fixedSize()

                UMUIMiniButton(style: .gray, action: {
                    vc.removeRecordFromList(store.record.id)
                }) {
                    Image(systemName: "trash")
                }
                .lineLimit(1).fixedSize()

                UMUIHSpacer(4)

                UMUIMiniButton("Render", systemImage: "play.fill", style: .accent) {
                    renderRecord()
                }
                .lineLimit(1).fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
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
        let color = statusColor(status)
        Circle()
            .fill(color)
            .shadow(color: color.opacity(0.6), radius: 4)
            .scaleEffect((status == .rendering && isPulsing) ? 1.4 : 1.0)
            .opacity((status == .rendering && isPulsing) ? 0.6 : 1.0)
            .onAppear {
                if status == .rendering {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: status) { newStatus in
                if newStatus == .rendering {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    withAnimation {
                        isPulsing = false
                    }
                }
            }
    }

    private func backgroundForStatus(_ status: BBAERecord.Status, isHovered: Bool = false) -> Color {
        let baseColor: Color
        switch status {
        case .rendering: baseColor = Color.blue.opacity(0.08)
        case .rendered:  baseColor = Color.green.opacity(0.06)
        default:         baseColor = Color(NSColor(deviceWhite: 0.16, alpha: 1))
        }
        return isHovered ? baseColor.opacity(0.8) : baseColor
    }
}
