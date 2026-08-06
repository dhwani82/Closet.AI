//
//  ClosetView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ClosetView: View {
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var items: [ClothingItem]

    @State private var selectedFilter: ClothingCategory? = nil
    @State private var showingAddSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: Constants.Spacing.md),
        GridItem(.flexible(), spacing: Constants.Spacing.md),
        GridItem(.flexible(), spacing: Constants.Spacing.md)
    ]

    private var filteredItems: [ClothingItem] {
        guard let selectedFilter else { return items }
        return items.filter { $0.category == selectedFilter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No clothes yet", systemImage: "tshirt")
                    } description: {
                        Text("Tap + to photograph and catalog your first piece.")
                    } actions: {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add item", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 0) {
                        Picker("Category", selection: $selectedFilter) {
                            Text("All").tag(ClothingCategory?.none)
                            ForEach(ClothingCategory.allCases) { category in
                                Text(category.displayName).tag(Optional(category))
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Constants.Spacing.lg)
                        .padding(.vertical, Constants.Spacing.md)

                        ScrollView {
                            LazyVGrid(columns: columns, spacing: Constants.Spacing.md) {
                                ForEach(filteredItems) { item in
                                    NavigationLink {
                                        ClothingDetailView(item: item)
                                    } label: {
                                        item.uiImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }
                            }
                            .padding(.horizontal, Constants.Spacing.lg)
                            .padding(.bottom, Constants.Spacing.lg)
                            .animation(.easeInOut(duration: 0.25), value: filteredItems.map(\.id))
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
                    .accessibilityLabel("Add clothing item")
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
    @State private var colorName: String = ""
    @State private var isLoadingPhoto = false
    @State private var isAnalyzing = false

    private var canSave: Bool {
        imageData != nil && !isLoadingPhoto && !isAnalyzing
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
                        Task { await loadAndAnalyze(newItem) }
                    }

                    if isLoadingPhoto {
                        ProgressView("Loading photo…")
                    } else if isAnalyzing {
                        ProgressView("Analyzing with Vision…")
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    TextField("Color (e.g. navy)", text: $colorName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                        let item = ClothingItem(
                            imageData: imageData,
                            category: category,
                            colorName: colorName.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(item)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func loadAndAnalyze(_ newItem: PhotosPickerItem?) async {
        isLoadingPhoto = true
        isAnalyzing = false
        defer { isLoadingPhoto = false }

        guard let newItem else {
            imageData = nil
            colorName = ""
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
        isAnalyzing = true
        defer { isAnalyzing = false }

        let result = await ImageAnalyzer.analyze(imageData: jpeg)
        if let suggested = result.suggestedCategory {
            category = suggested
        }
        if !result.dominantColorName.isEmpty {
            colorName = result.dominantColorName
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
