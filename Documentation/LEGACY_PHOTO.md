# Legacy Photo Workflow

`Sources/SBJFoundation/LegacyPhoto/` contains the pre-resource photo workflow . It is retained so existing application code has a stable source location
while the workflow is redesigned.

## Status

This directory is **compatibility code, not the target photo architecture**.

- Do not add new features to LegacyPhoto unless they are required to keep an existing application
  working.
- Do not move new image/resource APIs into this directory.
- New code should use the resource-content photo APIs under `Sources/SBJFoundation/Image/`, centered
  on `SBJResourceContent`, `PhotoMenu`, `PhotoThumbnailView`, and `PhotoDisplayView`.
- Historical API spelling is preserved for source compatibility, including `PhotoThumbailView`.
  Correcting public names belongs in the rewrite/migration rather than in a cleanup pass.
- The photo workflow depends on UIKit/SwiftUI/SwiftData. UIKit/SwiftData photo views are excluded
  from watchOS; small shared SwiftUI helpers may still compile there.

## Rewrite boundary

A future rewrite should separate:

1. encoded image content and stable resource identity;
2. import/camera/photos/paste acquisition;
3. crop/markup editing state;
4. thumbnail generation/caching;
5. application persistence and save policy.

The current `Image/` APIs already establish the first and second boundaries around
`SBJResourceContent`. The rewrite should converge LegacyPhoto callers on those contracts instead of
building a second image-storage model.

## Test policy

`LegacyPhotoAPITests` provides compile/API coverage for the moved compatibility surface and a small
amount of model-independent `PhotoSource` behavior. It deliberately does not snapshot the old UI or
lock in crop/markup implementation details. Those internals are expected to change during the
rewrite.
