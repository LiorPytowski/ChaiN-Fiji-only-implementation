This repository contains imageJ/Fiji macros to reproduce the ChaiN workflow in Fiji only (or with as little additional software as possible).

Cha*i*N stands for `Cha*i*N high-throughput analysis of the in situ Nucleome`  
It was originally published by:
1. Miron, E. et al. Chromatin arranges in chains of mesoscale domains with nanoscale functional topography independent of cohesin. Science Advances 6, eaba8811 (2020).

It builds on:
1. Smeets, D. et al. Three-dimensional super-resolution microscopy of the inactive X chromosome territory reveals a collapse of its active nuclear compartment harboring distinct Xist RNA foci. Epigenetics Chromatin 7, 8 (2014).

With code from:
1. Schmid, V. J., Cremer, M. & Cremer, T. Quantitative analyses of the 3D nuclear landscape recorded with super-resolved fluorescence microscopy. Methods 123, 33–46 (2017).

## What is this?
The macros and scripts in this repository enable the analysis of spatial distribution of nuclear spots relative to the chromatin distribution, specifically in 3D structured illuminations microscopy (3D SIM) data. 

## List of scripts
1) A [macro](https://github.com/LiorPytowski/ChaiN-Fiji-only-implementation/tree/main/1_Chromatin%20Classification) to classify the chromatin into n classes (work in progress)
2) A macro to segment spots and report on which chromatin class it is located (work in progress)
3) An R script for some data wrangling and visualisation (this is not done yet)

More details about each script is provided by following the links above.

## How to use the macros
Download the .ijm files then drag-and drop it in the FIJI bar. Then press "Run" on the bottom of the script editor.  
(There are other ways of doing this. This is just one of them.)

## Dependencies
:heavy_exclamation_mark: The macros need certain update sites to run.

The update sites are:
* 3D ImageJ Suite
* Java8
* CLIJ     
* CLIJ2
* clijx-assistant
* clijx-assistant-extensions
* SIMcheck
* IJPB-plugins
* ImageScience


## To do
* Improve the input dialogs.
* Provide sample images to run the scripts.
* Create an update site so that user can install and update automatically the macros (?)


## FAQ
#### How do I download files from here?
You can download the files from the last release (soon).  
Alternatively, have a look at [this](https://blog.hubspot.com/website/download-from-github?hubs_content=blog.hubspot.com%2Fwebsite%2Fdownload-from-github&hubs_content-cta=downloading%20a%20file) 

#### Why are the macros written in ImageJ macro language?
This language was chosen because it is the easiest to edit by non-coding experts.

#### Why would I want to edit the macro?
No macro is perfect. And no macro is suited for all images. You may need to change commands in the macros. Hopefully this is not necessary, but it may happen.

## Acknowledgement
These macros rely heavily on the CLIJ library. Therefore this work would have been not possible in it's current form without the work of Robert Haase and colleagues:
1. Haase, R. et al. CLIJ: GPU-accelerated image processing for everyone. Nat Methods 17, 5–6 (2020).
2. Vorkel, D. & Haase, R. GPU-accelerating ImageJ Macro image processing workflows using CLIJ. arXiv:2008.11799 [cs, q-bio] (2020).
3. Haase, R. et al. Interactive design of GPU-accelerated Image Data Flow Graphs and cross-platform deployment using multi-lingual code generation. 2020.11.19.386565 https://www.biorxiv.org/content/10.1101/2020.11.19.386565v1 (2020) doi:10.1101/2020.11.19.386565.

And MorphoLibJ:
1. Legland, D., Arganda-Carreras, I. & Andrey, P. MorphoLibJ: integrated library and plugins for mathematical morphology with ImageJ. Bioinformatics 32, 3532–3534 (2016).

And finally, last but not least:

1. Schindelin, J. et al. Fiji: an open-source platform for biological-image analysis. Nature Methods 9, 676 (2012).
2. Schindelin, J., Rueden, C. T., Hiner, M. C. & Eliceiri, K. W. The ImageJ ecosystem: An open platform for biomedical image analysis. Mol. Reprod. Dev. 82, 518–529 (2015).
3. Schneider, C. A., Rasband, W. S. & Eliceiri, K. W. NIH Image to ImageJ: 25 years of image analysis. Nat Methods 9, 671–675 (2012).
