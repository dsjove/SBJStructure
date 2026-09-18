# SBJ Image Document

`SBJImageDocument` is a self-contained, non-destructive image package. It stores the immutable encoded source image plus the current edit state. It is deliberately **not** an edit history.

## Package type

`SBJImageDocument` is deliberately generic at the framework level. Internally its content type is `public.package`; a host application that wants to own the document format should export its own concrete UTI conforming to `public.package` and associate that UTI with the package filename extension.

- Recommended filename extension: `.sbjimage`
- Framework content type: `public.package`

## Layout

```text
Example.sbjimage/
    manifest.json
    source/
        original.<source-extension>
    edits/
        geometry.json
        color.json
        markup.data            # optional
    thumbnail/
        image.<image-ext>      # optional generated thumbnail cache
```

The source and current edit state are authoritative image content. The manifest records thumbnail behavior:

- `generated`: persist a bounded rendered derivative; it is disposable and regenerated when edits change.
- `none`: persist no thumbnail and let the host thumbnail provider decide whether to supply a fallback.

A generated thumbnail is bounded to 512 pixels on its longest edge.

## Rendering roles

The package deliberately separates three jobs:

1. **Thumbnail providers** ask `SBJImageDocument.thumbnailURL(in:)` for the persisted thumbnail. If the document has none, the host provider chooses its own fallback behavior. Generated thumbnails have a maximum edge of 512 pixels and are encoded for compact storage (JPEG for opaque images, PNG when alpha is required).
2. **Quick Look / full preview consumers** render the current edit recipe at full output resolution on demand. A full flattened render is not stored in the package.
3. **Source fallback** is reserved for full rendering when the requested derivative cannot be produced; thumbnail lookup itself does not fall back to the source.

This avoids storing a second full-resolution copy of every edited image while still making thumbnail lookup cheap.

## `manifest.json`

The manifest identifies every component by path and content type. Readers should ignore JSON fields they do not recognize and should not assume that markup is PencilKit unless its declared content type says so.

The container currently publishes separate components for:

- source image
- geometry recipe
- color recipe
- optional markup
- thumbnail behavior (`thumbnailBehavior`), declaring whether the document generates a thumbnail
- optional generated thumbnail component (`thumbnail`)

## Geometry

`geometry.json` is encoded from `PhotoEditGeometry` and currently describes:

- crop
- normalized placement
- magnification
- quarter-turn and fine rotation
- horizontal/vertical mirror
- perspective
- skew

Perspective and skew are reserved fields. The current framework preserves them but does not yet render non-identity perspective or skew.

Perspective uses four points in normalized source/composition space. Identity is the unit square:

```text
topLeft     = (0, 0)
topRight    = (1, 0)
bottomLeft  = (0, 1)
bottomRight = (1, 1)
```

Skew values are degrees. Identity is zero horizontal and vertical skew.

## Color

`color.json` is currently an empty `PhotoColorAdjustments` object. It remains a separate component so future color controls can be added without changing the package container shape.

## Markup

Markup is format-neutral at the package level. The manifest records:

- path
- content type identifier
- canvas width and height
- coordinate space

The current editor uses serialized PencilKit `PKDrawing` data and composition coordinates. Other markup encodings can be introduced later without changing the image-document container.

## Framework API roles

- `PhotoEditGeometry`: portable geometry state.
- `PhotoColorAdjustments`: portable color state; currently empty.
- `PhotoMarkup`: serialized markup plus coordinate metadata.
- `PhotoEditResult`: current geometry + color + markup, usable entirely in memory.
- `PhotoEditor`: edits an image document and returns one atomically updated document.
- `SBJImageDocument.ThumbnailBehavior`: `.generated` (default) or `.none`. Use `SBJImageDocument(source:thumbnail:)` to opt out of storing a thumbnail.
- `SBJImageDocument.thumbnailURL(in:)`: cheap thumbnail-provider path that returns only the thumbnail component already stored in the package, or `nil` when none is present. It does not render or fall back to the source image.
- `SBJImageDocument.thumbnailImage`: image convenience over the same stored-thumbnail semantics.
- `SBJImageDocument.renderedImage(options:)`: on-demand full-render path for Quick Look/export-style presentation; source fallback.
- `SBJImageDocument`: owns source/edit/thumbnail consistency internally rather than exposing those components for callers to coordinate.

`PhotoMenu` infers edit semantics from the bound resource. An ordinary image is edited destructively/in memory; an `SBJImageDocument` is reopened with its saved geometry, color state, and markup. Applications choose persistence semantics by what their resource binding stores. A binding that requires non-destructive images can normalize assigned images with `SBJResourceContent.preservingImageEdits`.

## System registration and presentation

`SBJImageDocument` is a framework-provided persistence/interchange format, not a document type that every host application must advertise. Host applications that merely embed image documents inside their own documents do **not** need to register `.sbjimage` as a standalone document type.

Embedded thumbnail presentation uses `SBJResourceContent.uiImage`, `SBJImageDocument.thumbnailImage`, or `ImageReference.document`. Quick Look thumbnail providers should prefer `SBJImageDocument.thumbnailURL(in:)` and choose their own fallback when it returns `nil`. Full-size preview code should explicitly use `SBJImageDocument.renderedImage(options:)` so it performs the full render instead of displaying the thumbnail cache.
