//
//  PhotosService.swift
//  VlogNudge
//
//  Manages the "Daily Vlogs" album in Photos.
//

import Foundation
import Photos
import AVFoundation

enum PhotosService {

    /// Request write-add authorization.
    static func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Find or create the Daily Vlogs album.
    static func findOrCreateAlbum(named name: String = AppConstants.photosAlbumName) async throws -> PHAssetCollection {
        // Try to find existing
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOptions
        )
        if let existing = collections.firstObject {
            return existing
        }

        // Create new
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let placeholder = placeholder else {
            throw NSError(domain: "PhotosService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create album"])
        }

        let result = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [placeholder.localIdentifier],
            options: nil
        )
        if let created = result.firstObject {
            return created
        }
        throw NSError(domain: "PhotosService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Album created but not found"])
    }

    /// Save a video file to the album, return the asset's localIdentifier.
    @discardableResult
    static func saveVideo(at fileURL: URL, toAlbumNamed name: String = AppConstants.photosAlbumName) async throws -> String {
        let album = try await findOrCreateAlbum(named: name)

        var localID: String?

        try await PHPhotoLibrary.shared().performChanges {
            guard let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL),
                  let placeholder = assetRequest.placeholderForCreatedAsset else {
                return
            }
            localID = placeholder.localIdentifier

            if let albumRequest = PHAssetCollectionChangeRequest(for: album) {
                albumRequest.addAssets([placeholder] as NSArray)
            }
        }

        guard let id = localID else {
            throw NSError(domain: "PhotosService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get asset ID"])
        }
        return id
    }

    /// Fetch an AVAsset for playback given a local identifier.
    static func fetchAVAsset(localIdentifier: String) async -> AVAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let phAsset = result.firstObject else { return nil }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { asset, _, _ in
                continuation.resume(returning: asset)
            }
        }
    }
}
