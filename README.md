# PBNSU: Physics-Guided Blind Nonlinear Spectral Unmixing of Broadband RGB Histopathology Images

This repository contains the MATLAB code needed to run the H&E joint spectral and concentration estimation method used in the paper.

The package is intentionally minimal. It includes the solver, its helper functions, and the fitted spectral initialization files required at runtime. Synthetic images, ground truth, evaluation scripts, and previously generated experiment outputs are not included.

## Contents

- `he_spectral_decomposition.m`: main solver synchronized from `simulation/Slip_solve_HERGB_MM_PC_260518ADMM_Cnorm.m` (source modified 2026-08-10).
- `run_example.m`: small wrapper for running the solver with the paper experiment settings.
- `solve_concentration_fast_GN_patch*.m`: concentration fitting helpers.
- `Gaussian_reconstruction5.m`, `rgb2od.m`, `od2rgb.m`: spectral reconstruction and RGB/OD conversion helpers.
- `p_fit5_result_*.mat`: fitted spectra used to initialize H, E, and RGB response curves.

## Requirements

- MATLAB R2023b or a nearby release
- Optimization Toolbox
- Parallel Computing Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

## Quick Start

In MATLAB, add this directory to the path and call:

```matlab
run_example(referenceImage, inputImageDirectory, outputDirectory)
```

Example:

```matlab
cd('path/to/this/repository')
run_example( ...
    'path/to/reference.png', ...
    'path/to/input_images', ...
    'path/to/output')
```

Use 8-bit, three-channel RGB input and reference images. Relative paths are resolved against the MATLAB working directory at the time of the call.

The input directory may contain `.png`, `.jpg`, `.jpeg`, `.tif`, or `.tiff` images. The wrapper uses the same settings as the paper experiments:

```matlab
C_list = 100;
P_list = 2;
NumSample = 600;
ThrWhite = 240;
LowCut = 15;
lambda_orthoC = 0;
lambda_s = 0;
PatchVis = false;
```

## Outputs

Results are written to:

```text
<outputDirectory>/path0/<image-name>/
```

Image stems must be unique across input formats. Existing results for the same stem are overwritten. Use a separate output directory for each run or iteration setting.

Each image directory contains:

- `results_data.mat`: fitted spectral parameters (`p_opt`), raw and normalized concentration maps.
- `converge_hist.mat`: optimization history.
- `01_RGB_orig.png`: original image.
- `02_RGB_recon_self.png`: self-reconstructed RGB image.
- `03_RGB_diff.png`: reconstruction difference visualization.
- `04_RGB_corrected_ref.png`: reference-normalized RGB image.
- `Hematoxylin.png` and `Eosin.png`: separated H/E component images.
- `A_Convergence_Curves.png` and `OD_Error_Heatmaps.png`: diagnostic plots.

The solver also creates a local `ref/` directory on the first run. This cache stores spectra and concentration ranges estimated from the reference image. Delete `ref/` if you intentionally want to recompute the reference state from a different reference image.

## Reproducibility Notes

- Use `run_example.m` when possible. It changes into the code directory before running, so the initialization `.mat` files are resolved consistently.
- The solver uses a fixed random seed for pixel sampling.
- For a fair comparison across runs, keep the same reference image, input image directory, and `ref/` cache state.
- This release follows the selected simulation implementation, including shared RGB peak normalization, spectral-change stopping, channel-specific RGB edge priors, H/E band constraints, and legacy Jacobian scaling. It differs numerically from the previous manuscript-aligned release.
- Clear the previous `ref/` cache when upgrading the solver so reference spectra are recomputed with this version.
- The three `p_fit5_result_*_Singlegauss.mat` camera initializations are retained from the previous release because the simulation root does not contain those files; the other initialization files match the simulation source.

## Validation

From the repository directory in MATLAB:

```matlab
addpath('tests')
test_release
```

This checks relative-path handling, working-directory restoration, initialization files, and fast GN recovery on synthetic data. It does not replace a full batch experiment on the paper dataset.
