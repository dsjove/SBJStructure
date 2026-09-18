# SBJ Image Document

`SBJImageDocument` is a self-contained, non-destructive image package. It stores the immutable encoded source image plus the current edit state. It is deliberately **not** an edit history.

## Package type

- Uniform Type Identifier: `com.softwarebyjove.image-document`
- Recommended filename extension: `.sbjimage`
- Conforms to: `public.package`

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
        thumbnail.<image-ext>  # optional, disposable derived data
```

Only the source and current edit state are authoritative. `thumbnail/` is a disposable cache and may be regenerated or omitted. It stores a **bounded thumbnail**, never a full-size flattened image.

## Rendering roles

The package deliberately separates three jobs:

1. **Thumbnail providers** use the persisted thumbnail. New thumbnails are rendered with a maximum edge of 512 pixels and encoded for compact storage (JPEG for opaque images, PNG when alpha is required).
2. **Quick Look / full preview consumers** render the current edit recipe at full output resolution on demand. A full flattened render is not stored in the package.
3. **Source fallback** is used only if the requested thumbnail or full render cannot be produced.

This avoids storing a second full-resolution copy of every edited image while still making thumbnail lookup cheap.

## `manifest.json`

The manifest identifies every component by path and content type. Readers should ignore JSON fields they do not recognize and should not assume that markup is PencilKit unless its declared content type says so.

The container currently publishes separate components for:

- source image
- geometry recipe
- color recipe
- optional markup
- optional cached thumbnail (`thumbnail` manifest component)

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
- `SBJImageDocument.thumbnailImage`: cheap thumbnail-provider path; persisted thumbnail first, source fallback.
- `SBJImageDocument.renderedImage(options:)`: on-demand full-render path for Quick Look/export-style presentation; source fallback.
- `SBJImageDocument`: owns source/edit/thumbnail consistency internally rather than exposing those components for callers to coordinate.

`PhotoMenu` infers edit semantics from the bound resource. An ordinary image is edited destructively/in memory; an `SBJImageDocument` is reopened with its saved geometry, color state, and markup. Applications choose persistence semantics by what their resource binding stores. A binding that requires non-destructive images can normalize assigned images with `SBJResourceContent.preservingImageEdits`.

## System registration and presentation

`SBJImageDocument` is a framework-owned persistence/interchange format, not a document type that every host application must advertise. Host applications that merely embed image documents inside their own documents do **not** need to register `.sbjimage` as a standalone document type.

Embedded thumbnail presentation uses `SBJResourceContent.uiImage`, `SBJImageDocument.thumbnailImage`, or `ImageReference.document`. Full-size preview code should explicitly use `SBJImageDocument.renderedImage(options:)` so it performs the full render instead of displaying the thumbnail cache.
