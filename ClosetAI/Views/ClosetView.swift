//
//  ClosetView.swift
//  ClosetAI
//

import SwiftUI
import SwiftData
import PhotosUI

struct ClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var items: [ClothingItem]

    @State private var selectedFilter: ClothingCategory? = nil
    @State private var showingAddSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var filteredItems: [ClothingItem] {
        guard let selectedFilter else { return items }
        return items.filter { $0.category == selectedFilter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No clothes yet",
                        systemImage: "tshirt",
                        description: Text("Tap + to add your first piece.")
                    )
                } else {
                    VStack(spacing: 0) {
                        Picker("Category", selection: $selectedFilter) {
                            Text("All").tag(ClothingCategory?.none)
                            ForEach(ClothingCategory.allCases) { category in
                                Text(category.displayName).tag(Optional(category))
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(filteredItems) { item in
                                    item.uiImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .navigationTitle("My closet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClothingSheet()
            }
        }
    }
}

private struct AddClothingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var category: ClothingCategory = .top
    @State private var isLoading = false

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
                                .frame(height: 220)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Choose photo", systemImage: "photo.on.rectangle")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            guard let newItem else {
                                imageData = nil
                                return
                            }
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               let jpeg = uiImage.jpegData(compressionQuality: 0.7) {
                                imageData = jpeg
                            }
                        }
                    }

                    if isLoading {
                        ProgressView("Loading photo…")
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let imageData else { return }
                        let item = ClothingItem(imageData: imageData, category: category)
                        modelContext.insert(item)
                        dismiss()
                    }
                    .disabled(imageData == nil)
                }
            }
        }
    }
}

#Preview {
    ClosetView()
        .modelContainer(
            for: [ClothingItem.self, Outfit.self, WishlistItem.self],
            inMemory: true
        )
}
