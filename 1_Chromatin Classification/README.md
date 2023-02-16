The aim of this macro is to classify the chromatin into n classes of equal variance. An input sample image is provided.

#### FAQ
#### How do I know what parameters to use when running the macro for the first time?
Run the macro with the default settings and make sure to select the options to pause the macro at the end of each file and show all the intermediary results.  
Once you have that, inspect the images and check whether the parameters seem correct. If not, then, for example, try different thresholds then re-run the macro with the newly selected thresholds.  

For visualisation purposes, image synchronisation might be of interest (Analyze › Tools › Synchronize Windows).

#### Why is this macro so slow?
The most time consuming step is the multi Otsu implementations from the simpleITK library. This is computed on CPU. The more chromatin classes you create the slower it will be.

## Dependencies
:heavy_exclamation_mark: The macros need certain update sites to run.  
The update sites are:
* CLIJ     
* CLIJ2
* clijx-assistant
* clijx-assistant-extensions
* SIMcheck

### How does the macro work?
[Coming soon]
