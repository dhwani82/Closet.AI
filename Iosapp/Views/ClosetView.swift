//
//  ClosetView.swift
//  Iosapp
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var items: [ClothingItem]

    @State private var selectedCategory: ClothingCategory?
    @State private var isShowingAddSheet = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var filteredItems: [ClothingItem] {
        guard let selectedCategory else { return items }
        return items.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Your closet is empty",
                        systemImage: "tshirt",
                        description: Text("Tap + to add your first clothing item.")
                    )
                } else {
                    VStack(spacing: 0) {
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag(nil as ClothingCategory?)
                            ForEach(ClothingCategory.allCases) { category in
                                Text(category.displayName).tag(category as ClothingCategory?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        if filteredItems.isEmpty {
                            ContentUnavailableView(
                                "No items",
                                systemImage: selectedCategory?.iconName ?? "tshirt",
                                description: Text("No clothing in this category yet.")
                            )
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(filteredItems) { item in
                                        clothingThumbnail(for: item)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My closet")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddClothingItemSheet()
            }
        }
    }

    @ViewBuilder
    private func clothingThumbnail(for item: ClothingItem) -> some View {
        Group {
            if let image = item.uiImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
                    .overlay {
                        Image(systemName: item.category.iconName)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AddClothingItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var selectedCategory: ClothingCategory = .top
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            previewImage == nil ? "Choose Photo" : "Change Photo",
                            systemImage: "photo"
                        )
                    }

                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(previewImage == nil || isLoading)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadPhoto(from: newValue)
                }
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else {
            previewImage = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            previewImage = image
        }
    }

    private func saveItem() {
        guard let previewImage,
              let imageData = previewImage.jpegData(compressionQuality: 0.7) else {
            return
        }

        let item = ClothingItem(
            imageData: imageData,
            category: selectedCategory
        )
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    ClosetView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self], inMemory: true)
}
