//
//  ClothingDetailView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: ClothingItem

    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Spacing.xl - 4) {
                item.uiImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large, style: .continuous))
                    .frame(maxWidth: .infinity)

                LabeledContent("Category", value: item.category.displayName)

                LabeledContent("Color") {
                    Text(item.colorName.isEmpty ? "Not set" : item.colorName.capitalized)
                        .foregroundStyle(item.colorName.isEmpty ? .secondary : .primary)
                }

                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("Tags")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if item.tags.isEmpty {
                        Text("No tags")
                            .foregroundStyle(.secondary)
                    } else {
                        FlowTagChips(tags: item.tags)
                    }
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete item", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, Constants.Spacing.sm)
            }
            .padding(Constants.Spacing.lg)
        }
        .navigationTitle(item.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this item?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the piece from your closet. This can’t be undone.")
        }
    }
}

/// Simple wrapping chip row for tags.
private struct FlowTagChips: View {
    let tags: [String]

    var body: some View {
        FlexibleChipLayout(spacing: Constants.Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.subheadline)
                    .padding(.horizontal, Constants.Spacing.md)
                    .padding(.vertical, Constants.Spacing.xs + 2)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }
}

/// Lightweight wrap layout so tag chips flow onto multiple lines.
private struct FlexibleChipLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

#Preview {
    NavigationStack {
        ClothingDetailView(
            item: ClothingItem(
                imageData: Data(),
                category: .top,
                colorName: "navy",
                tags: ["casual", "cotton"]
            )
        )
    }
    .modelContainer(
        for: [ClothingItem.self, Outfit.self, WishlistItem.self],
        inMemory: true
    )
}
