# Phase Interpreter
# A tool to interpret mineral phases with modern microcopy image analysis tools.

**Version**: 1 (beta)  
**Author**: Dr Marco Acevedo Z. (maaz.geologia@gmail.com)  
**Affiliation**: School of Earth and Atmospheric Sciences, Queensland University of Technology  
**Date**: November 2025  
**Citation**: [Acevedo Zamora & Kamber 2023](https://www.mdpi.com/2075-163X/13/2/156)  
**Previous versions**: [Original repository](https://github.com/marcoaaz/Acevedo-Kamber/tree/main/QuPath_generatingMaps)  
---

## 📖 Overview

Phase interpreter assists researchers in saving mineral phase maps and performing basic image analysis that are essential to study geological processes. It generates a structured output folder with files corresponding to the selected analyses for each 'Trial tag' (see interface) to support findings and encourage future (or retrospective) reuse of research data (thin sections, polished blocks, resin mounts).

The tool is useful for users wanting to combine the capabilities/power of light microscopy and X-ray/electron microscope imaging systems using a much larger image analysis pipeline (see citations at the bottom of page). Previous image analysis (segmentation) is done in [QuPath](https://qupath.github.io/) ([Bankhead et al., 2017](https://www.nature.com/articles/s41598-017-17204-5)) using the [pixel classifier](https://qupath.readthedocs.io/en/stable/docs/tutorials/pixel_classification.html) tool.

<img width=60% height=60% alt="Image" src="https://github.com/user-attachments/assets/f877cfdc-0c85-43ca-9a77-73cf2462cce1" />

---

## 🚀 Features

### Core Functionality
- **Graphical User Interface (GUI) following three steps** for reprocessing the input maps from QuPath
- **Seamless selection of trained classifier outputs** for each run
- **Removal of the background class** using the original names that are excluded from the analysis (e.g. hole, epoxy, cracks, mixed phases)  
- **Basic image processing** to allow creating sample the foreground mask (e.g. dilation, rotation, mirroring) and checking the Preview
- **Menu for editing mineral names** of the ranked phases following a desired nomenclature (and resorting the targets)
- **Focus the analysis on a region of interest (ROI)** to avoid analysing uninteresting areas and reducing computational cost
- **Varied pool of textural analysis**: phase map, modal mineralogy, association, granulometry

### Image Metadata Extraction
- **Automatic metadata extraction** from input QuPath project containing:
  - **Saved pixel classifier** - Process metadata and machine learning model saved in the QuPath > Classify > Pixel classification > Train pixel classifier
  - **Saved predicted map** - File with the same basename as the classifier and often saved after classifying the entire sample (*.ome.tif) .
- **Steps metadata** - CSV files are saved tracking the semantic and numerical outputs from each processing step within the GUI and allow reproducibility.

### Adaptive Interface
- **Grid design** - adapts to the window size

---

## 🖥️ Requirements*

- **MatLab** R2024b
- **MatLab App Designer**
- **Additional libraries** for metadata extraction:
  - `bfmatlab` - for reading OME TIFF [link](https://www.openmicroscopy.org/bio-formats/downloads/)
  - `external_package/rgb` - for getting triplets by colour text [link](https://au.mathworks.com/matlabcentral/fileexchange/24497-rgb-triple-of-color-name-version-2)  

*The standanlone App can be produced from:

Operating System: Microsoft Windows 11 Enterprise Version 10.0 (Build 22631)
Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode
- MATLAB                                                Version 24.2        (R2024b)
- Computer Vision Toolbox                               Version 24.2        (R2024b)
- Curve Fitting Toolbox                                 Version 24.2        (R2024b)
- Deep Learning Toolbox                                 Version 24.2        (R2024b)
- Fixed-Point Designer                                  Version 24.2        (R2024b)
- Global Optimization Toolbox                           Version 24.2        (R2024b)
- Image Processing Toolbox                              Version 24.2        (R2024b)
- MATLAB Compiler                                       Version 24.2        (R2024b)
- Mapping Toolbox                                       Version 24.2        (R2024b)
- Optimization Toolbox                                  Version 24.2        (R2024b)
- Parallel Computing Toolbox                            Version 24.2        (R2024b)
- Signal Processing Toolbox                             Version 24.2        (R2024b)
- Statistics and Machine Learning Toolbox               Version 24.2        (R2024b)
- Symbolic Math Toolbox                                 Version 24.2        (R2024b)
- Wavelet Toolbox                                       Version 24.2        (R2024b)

---

## 📁 Versions Available

### Phase interpreter v1 (Phaseinterpreterv1.prj)
- Graphical user interface (GUI)

### v1 script (qupathPhaseMap_v13.m)
- Development script that allows trialling new implementation ideas before editing the GUI
  
---

## ⌨️ Creating the Executable

1. Open **MatLab > App Designer**   
2. Open "Phaseinterpreterv1.prj".  
4. Go to App Designer > Share > Standalone Desktop App
5. Within Apps required for your application to run, add the folders of the additional libraries (living within your PC)
6. Click "Package" button while having selected "Runtime included in package" (for future users not having MatLab runtime)

## 📦 Packaged Executable (proved to work in Windows 11)
- A folder "Phaseinterpreterv1" will appear containing:
  - for_redistribution: installer that can be shared with others (users not having MatLab runtime)
  - for_redistribution_files_only: executable (when having the runtime)
  - for_testing: executable (when having the runtime)
- If requiring an example dataset to operate the software, please, contact me

## Issues and future work
-This is a beta version that will soon be improved with user feedback
-If having issues to compile or wanting to make a new branch/pull request, contact me as well

## Citing Phase interpreter
- This software depends on open-source software components (QuPath is in ongoing development) and scientific citations/feedback
- The following research papers have already contributed to its evolution:
  - Acevedo Zamora, M. A., & Kamber, B. S. (2023). Petrographic Microscopy with Ray Tracing and Segmentation from Multi-Angle Polarisation Whole-Slide Images. Minerals, 13(2), 156. https://doi.org/10.3390/min13020156 
  - Acevedo Zamora, M. A., Kamber, B. S., Jones, M. W. M., Schrank, C. E., Ryan, C. G., Howard, D. L., Paterson, D. J., Ubide, T., & Murphy, D. T. (2024). Tracking element-mineral associations with unsupervised learning and dimensionality reduction in chemical and optical image stacks of thin sections. Chemical Geology, 650, 121997. https://doi.org/10.1016/j.chemgeo.2024.121997
  - Acevedo Zamora, M. (2024). Petrographic microscopy of geologic textural patterns and element-mineral associations with novel image analysis methods [Thesis by publication, Queensland University of Technology]. Brisbane. https://eprints.qut.edu.au/248815/
  - Ubide, T., Murphy, D. T., Emo, R. B., Jones, M. W. M., Acevedo Zamora, M. A., & Kamber, B. S. (2025). Early pyroxene crystallisation deep below mid-ocean ridges. Earth and Planetary Science Letters, 663, 119423. https://doi.org/10.1016/j.epsl.2025.119423 
  - Kamber, B. S., Acevedo Zamora, M. A., Rodrigues, R. F., Li, M., Yaxley, G. M., & Ng, M. (2025). Exploring High PT Experimental Charges Through the Lens of Phase Maps. Minerals, 15(4), 355. https://doi.org/10.3390/min15040355
  - Rodrigues, R. F., Yaxley, G. M., & Kamber, B. S. (2025). Phase relations and solidus temperature of garnet lherzolite at 5 GPa revisited. Contributions to Mineralogy and Petrology, 180(9), 57. https://doi.org/10.1007/s00410-025-02250-4 

Thank you.
Marco
