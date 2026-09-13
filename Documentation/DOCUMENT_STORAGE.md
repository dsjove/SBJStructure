# Document Storage

SBJFoundation's document layer is type-driven. Applications describe their live document and immutable snapshot by conforming to `PackageDocument` and `PackageDocumentSnapshot`; there is no separate model/strategy adapter.

## Shared cross-platform layer

- `PackageDocumentSnapshot` identifies immutable persisted state with a stable, comparable, sendable ID.
- `PackageDocument` defines the live-object contract: stable ID, snapshot/restore, semantic name, role, modified date, creation/duplication, storage location, import preparation/copy policy, URL routing, and package `FileWrapper` serialization.
- `PackageDocumentLibrary<Document>` owns canonical live identity, package discovery, active sessions, create/duplicate/delete/import/adopt operations, import and external conflicts, save-error routing, iCloud directory monitoring, and catalog rescans.
- `PackageLibraryStore` is the lower-level coordinated package discovery/delete/external-read helper used internally by the library.
- `PackageStorageLocation` maps stable IDs to app-controlled package URLs. `PackageDocumentLibrary` resolves the active root once at initialization (or accepts an injected root for tests) and uses that root for its entire lifetime, avoiding catalog/session split-brain if iCloud availability changes mid-session.
- `UbiquitousDirectoryMonitor` watches the app-controlled package directory for catalog-level changes.

## Active package boundary

Clients use `PackageDocumentLibrary` and do not branch on platform.

- `DocumentStorage/UIKit/PackageSession+UIKit.swift` is compiled for UIKit document platforms other than tvOS/watchOS and delegates active-file lifecycle to `UIDocument`.
- `DocumentStorage/tvOS/PackageSession+tvOS.swift` is entirely `#if os(tvOS)`. It exists only because tvOS has no `UIDocument`; it supplies the equivalent active-file presentation/coordinated-I/O behavior with `NSFilePresenter` and `NSFileCoordinator`.
- `PackageSessionSupport.swift` contains only the small event/version-resolution surface shared by both active-session backends.

The tvOS presenter implementation is therefore isolated both physically and at compile time. No client type needs to know whether its active package is backed by `UIDocument` or `NSFilePresenter`.

## Conflict policy

Active content conflicts use Foundation `NSFileVersion` under coordinated access. Keeping local changes saves the active document and resolves/removes competing versions. Choosing the external version promotes the newest unresolved conflicting version with `NSFileVersion.replaceItem(at:)`, resolves/removes the obsolete versions, and reloads the active session. External move/delete conflicts discard the session's pending save before closing so “Keep My Changes” recreates only the canonical package and never writes stale local changes into the externally moved/deleted URL.
