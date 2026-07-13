//
//  BBAERecordListView.swift
//  Batch Buddy AE
//
//  Created by Antigravity on 22/06/2026.
//

import SwiftUI
import UMOmniaFramework
import UMUIControls

// MARK: - BBAERecordListView

/// Pure SwiftUI list of records using a LazyVStack inside a ScrollView.
/// Each record is displayed as a `BBAERecordRowView`.
struct BBAERecordListView: View {

    @ObservedObject var vc: BBAEProjectVC

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                let records = vc.itemFoundList()
                if records.isEmpty {
                    emptyState
                } else {
                    ForEach(records, id: \.id) { record in
                        BBAERecordRowView(
                            store: vc.storeFor(record: record),
                            vc: vc
                        )
                        .id(record.id)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(NSColor(deviceWhite: 0.13, alpha: 1)))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            VStack(spacing: 4) {
                Text("No Records")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Press the button below to create the first record.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            UMUICapsuleButton("Add First Record", systemImage: "plus", style: .accent, size: .normal) {
                vc.btnaddItemPressed(vc)
            }
            .padding(.top, 8)
            
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
