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
            LazyVStack(spacing: 0) {
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
        }
        .background(Color(nsColor: NSColor(deviceWhite: 0.13, alpha: 1)))
        .id(vc.listRefreshId)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Records")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Text("Press \"Add Item\" to create the first record.")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
