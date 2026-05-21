# Project Progress Checklist: Stream Utilities & Optimizations

## 🔴 Not Started (Pending Tasks)

### Critical Refactors
- [ ] **Custom Tag Search Optimization**: Implement a specialized version of `indexOfUint8Array` for `ENCODED_TAGS.CLOSED.HEAD` and `ENCODED_TAGS.CLOSED.BODY` to improve scanning speed during transformation (Ref: `@Ethan-Arrowood` TODO).
- [ ] **Stream Parser Robustness**: Redesign `createStripDocumentClosingTagsTransform` to correctly handle scenarios where closing tags (`</body></html>`) are split across multiple stream chunks, removing the "safe assumption" currently in place.

### Deprecations
- [ ] **Native React Head Management**: Deprecate and eventually remove `createHeadInsertionTransformStream` and its associated logic in `continueFizzStream` once the upstream React Fizz renderer natively supports appending HTML to the end of the `<head>`.

### Localization (I18n)
- [ ] **Diagnostic Message Audit**: Verify consistency of new TypeScript error codes (9000-series like `isolatedDeclarations`) across the generated JSON files for Portuguese, Spanish, and Italian locales.

## 🟡 Not Finished (In-Progress / Ongoing Monitoring)

### Reliability
- [ ] **Hydration Error Prevention**: Monitor the effectiveness of `createHeadInsertionTransformStream` in preventing hydration errors during app layout rendering.
- [ ] **Stream Chaining Stability**: Verify that `voidCatch` correctly prevents unhandled promise rejections without suppressing critical errors in the consuming stream.

### Performance & Monitoring
- [ ] **Root Layout Validation**: Ensure `createRootLayoutValidatorStream` correctly identifies missing `<html>` or `<body>` tags across all edge-case streaming scenarios.
- [ ] **Buffer Pressure Monitoring**: Monitor the performance impact of `createBufferedTransformStream` to ensure it effectively balances the trade-off between network flushing frequency and Time to First Byte (TTFB).
- [ ] **Scheduler Latency**: Audit the use of `scheduleImmediate` and `atLeastOneTask` within `createBufferedTransformStream` and `createMergedTransformStream` to ensure they don't introduce unnecessary task-queue lag.

### Typing & Compliance
- [ ] **Isolated Declarations Compliance**: Ensure all public stream utilities provide explicit return type annotations to satisfy the `--isolatedDeclarations` requirement noted in recent diagnostic message updates.

## 🟢 Finished (Core Infrastructure)

### Core Web Stream Logic

### Utilities
- [x] Basic `chainStreams` implementation with `preventClose` logic.
- [x] `streamFromString` and `streamToString` helper functions.
- [x] Suffix management via `createMoveSuffixStream` and `createDeferredSuffixStream`.
- [x] Merging logic for inlined data (Flight data/form state) via `createMergedTransformStream`.

### Render Pipelines
- [x] Implementation of `continueFizzStream` for standard SSR.
- [x] Implementation of `continueDynamicPrerender` and `continueStaticPrerender`.
- [x] Implementation of Dynamic Resume streams (HTML and Data).

### Observability & Environment
- [x] Integration of `AppRenderSpan` tracing for `renderToInitialFizzStream`.
- [x] UTF-8 Text Encoding/Decoding safety in `streamToString`.
- [x] Supabase Phoenix asset compilation configuration (`tsconfig.json`).

## 📦 Support & Maintenance
- [x] Portuguese (pt-br) Diagnostic Mapping
- [x] Spanish (es) Diagnostic Mapping
- [x] Italian (it) Diagnostic Mapping