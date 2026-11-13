# Extraction validation —12 November2026

Executed MATLAB R2024b `checkTailExtraction` successfully (exit0).

- All10 package entry points resolve and repository-root detection matches the checkout.
- Fixed-seed synthetic nonzero-motion input gives identical outputs from the original pre-extraction `getTailMotionTrace`, `bbtail.getTailMotionTrace`, and its compatibility wrapper.
- Zero-motion input also agrees, including the existing nonfinite/degenerate behavior; no silent repair was made.
- Independently reversed the documented namespace/root/name substitutions for all10 extracted implementations and matched their original SHA256 hashes. Thus this extraction changes dispatch/location, not calculation bodies.
- Wrapper and implementation hashes are recorded in migration_manifest.json. The figure-package integrity audit recognizes this explicit code relocation rather than treating it as a changed numerical result.

No full-dataset rerun, source-video read, reweighting, peak redetection, or scientific-output write was performed. Synthetic parity does not establish biological validity, and batch stages have not been rerun at their new entry points. Existing frozen outputs and validation remain the scientific reference.

The pre-extraction comparison function was a temporary `/tmp` test fixture, not a new persistent scientific source. All original code hashes and the pre-cleanup working-state archive remain available for independent reconstruction.
