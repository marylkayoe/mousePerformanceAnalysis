# Paper deposition packages

Each subfolder contains a self-contained package prepared for a specific paper.
Packages are intended to accompany journal submissions or archival deposits.

- `Yang-Mia-2026/`: draft open-field analysis package with a video example.

When preparing a package, copy the required source files and record their provenance,
dependencies, parameters, and any changes. Do not rely on code outside the paper folder.
Clearly distinguish draft packages from verified submission releases.

## MATLAB path

Add only the selected package's code folders to the MATLAB path. Avoid adding the
entire working repository recursively: deposited copies may share function names
with the development code or other paper packages. Check function resolution with
`which functionName -all` when verifying a package.
