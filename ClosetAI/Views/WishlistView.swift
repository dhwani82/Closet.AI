//
//  WishlistView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI
import SwiftData
import PhotosUI

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WishlistItem.dateAdded, order: .reverse) private var items: [WishlistItem]

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No wishlist items", systemImage: "heart")
                    } description: {
                        Text("Snap a photo of something you want and track it here.")
                    } actions: {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add item", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            WishlistRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add wishlist item")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWishlistItemSheet()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

private struct WishlistRow: View {
    let item: WishlistItem

    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            thumbnail
                .frame(width: Constants.Thumbnail.size, height: Constants.Thumbnail.size)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                Text(item.itemDescription.isEmpty ? "Untitled item" : item.itemDescription)
                    .font(.body)
                    .lineLimit(2)

                Text(item.estimatedPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Constants.Spacing.xs)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uiImage = UIImage(data: item.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.fill.tertiary)
        }
    }
}

private struct AddWishlistItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var itemDescription = ""
    @State private var priceText = ""
    @State private var isLoadingPhoto = false
    @State private var isDescribing = false
    @State private var descriptionError: String?

    private let descriptionService = ItemDescriptionService()

    private var estimatedPrice: Double {
        Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var canSave: Bool {
        imageData != nil && !isLoadingPhoto && !isDescribing
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: Constants.Thumbnail.addPhotoHeight)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium, style: .continuous))
                        } else {
                            Label("Choose photo", systemImage: "photo.on.rectangle")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task { await loadPhotoAndDescribe(newItem) }
                    }

                    if isLoadingPhoto {
                        ProgressView("Loading photo…")
                    } else if isDescribing {
                        ProgressView("Describing with AI…")
                    }

                    if let descriptionError {
                        Text(descriptionError)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Details") {
                    TextField("Description", text: $itemDescription, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Estimated price", text: $priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add to wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let imageData else { return }
                        let item = WishlistItem(
                            imageData: imageData,
                            itemDescription: itemDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                            estimatedPrice: estimatedPrice
                        )
                        modelContext.insert(item)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func loadPhotoAndDescribe(_ newItem: PhotosPickerItem?) async {
        isLoadingPhoto = true
        isDescribing = false
        descriptionError = nil
        defer { isLoadingPhoto = false }

        guard let newItem else {
            imageData = nil
            itemDescription = ""
            return
        }

        guard let data = try? await newItem.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let jpeg = uiImage.jpegData(compressionQuality: 0.7) else {
            imageData = nil
            return
        }

        imageData = jpeg
        isLoadingPhoto = false
        isDescribing = true
        defer { isDescribing = false }

        do {
            itemDescription = try await descriptionService.describeItem(imageData: jpeg)
        } catch {
            descriptionError = error.localizedDescription
        }
    }
}

#Preview {
    WishlistView()
        .modelContainer(
            for: [ClothingItem.self, Outfit.self, WishlistItem.self],
            inMemory: true
        )
}
