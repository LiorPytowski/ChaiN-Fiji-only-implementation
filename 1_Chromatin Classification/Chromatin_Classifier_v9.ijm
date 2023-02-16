run("Fresh Start");
run("CLIJ2 Macro Extensions", "cl_device=");
Ext.CLIJ2_clear();

setBatchMode(true);

// Load image from disc 
filelist = getFileList(Input_Directory) 
for (i = 0; i < lengthOf(filelist); i++) {
  		Ext.CLIJ2_clear();
        open(Input_Directory + File.separator + filelist[i]);
		run("Duplicate...", "duplicate channels=&Chromatin_Channel");
		getDimensions(Input_width, Input_height, Input_channels, Input_slices, Input_frames);
		
		if (Threshold_and_conversion == true) {
			run("Threshold and 16-bit Conversion", "auto-scale");
		}
		
		
		input_image = getTitle();
		Ext.CLIJ2_push(input_image);
		
///Below we segment the nucleus
// Gaussian Blur3D
sigma_x = sigma_XY;
sigma_y = sigma_XY;
sigma_z = sigma_Z;
Ext.CLIJ2_gaussianBlur3D(input_image, Blurred_input, sigma_x, sigma_y, sigma_z);
if (preview == true) {		Ext.CLIJ2_pull(Blurred_input);}

// Automatic Threshold
method = Threshold_Method_Gaussian;
Ext.CLIJ2_automaticThreshold(Blurred_input, Blurred_input_thresholded, method);
Ext.CLIJ2_release(Blurred_input);
if (preview == true) {		Ext.CLIJ2_pull(Blurred_input_thresholded);}

// Maximum3D Box
radius_x = max_XY;
radius_y = max_XY;
radius_z = max_Z;
Ext.CLIJ2_maximum3DBox(input_image, maxima_filtered, radius_x, radius_y, radius_z);
if (preview == true) {		Ext.CLIJ2_pull(maxima_filtered);}

// Automatic Threshold
method = Threshold_Method_Max;
Ext.CLIJ2_automaticThreshold(maxima_filtered, maxima_filtered_thresholded, method);
Ext.CLIJ2_release(maxima_filtered);
if (preview == true) {		Ext.CLIJ2_pull(maxima_filtered_thresholded);}
	
	// Binary And
	Ext.CLIJ2_binaryAnd(maxima_filtered_thresholded, Blurred_input_thresholded, AND_Image);
	Ext.CLIJ2_release(Blurred_input_thresholded);
	Ext.CLIJ2_release(maxima_filtered_thresholded);
	if (preview == true) {		Ext.CLIJ2_pull(AND_Image);}
	
	// Binary Fill Holes Slice By Slice
	Ext.CLIJx_binaryFillHolesSliceBySlice(AND_Image, fill_holes);
	Ext.CLIJ2_release(AND_Image);
	//Ext.CLIJ2_pull(fill_holes); we will use this later
	
	// Minimum3D Box
	radius_x = erosion_radius_XY;
	radius_y = erosion_radius_XY;
	radius_z = erosion_radius_Z;
	Ext.CLIJ2_minimum3DBox(fill_holes, fill_holes_eroded, radius_x, radius_y, radius_z);
	Ext.CLIJ2_release(fill_holes);
	if (preview == true) {		Ext.CLIJ2_pull(fill_holes);}
	

	
	// We replace the background with -1
	Ext.CLIJ2_convertFloat(fill_holes_eroded, fill_holes_eroded_Float);
	Ext.CLIJ2_replaceIntensity(fill_holes_eroded_Float, flip, 0, 65535);
	Ext.CLIJ2_replaceIntensity(flip, flop, 1, 0);
	Ext.CLIJ2_release(flip);
	//Ext.CLIJ2_release(fill_holes_eroded);  // we'll use this image later so we dont release it now
	if (preview == true) {		Ext.CLIJ2_pull(flop);}
	
	// We make the background in the input image negative
	Ext.CLIJ2_convertFloat(input_image, input_image_Float);
	Ext.CLIJ2_subtractImages(input_image_Float, flop, masked_input); 
	Ext.CLIJ2_pull(masked_input);
	
	// Maximum Z Projection
	Ext.CLIJ2_minimumZProjection(flop, max_proj_label);
	if (preview == true) {		Ext.CLIJ2_pull(max_proj_label);}
	
	// Pull To ROIManager
	run("ROI Manager...");
	Ext.CLIJ2_pullToROIManager(max_proj_label);
	Ext.CLIJ2_release(max_proj_label);
	
	selectWindow(masked_input);
	roiManager("Select", 0);
	run("Crop");
	run("Select None");


		//if croping for speed, enable lines below
		//makeRectangle(32, 100, 87, 75);
		//run("Crop");
		getDimensions(width, height, channels, slices, frames); //once macro finished this line could be deleted and subsequent width * height * slices variable be replaced with Input_height * Input_channels * Input_slices, etc.
		
		////////////////////////////
		// This section is a convoluted way of copying all pixel values that are >= 0 to a new image/array.
		// This excludes the NaNs so that the multi Ostsu calculates the classes from the nuclear signal only excluding the background.
		/////////////////////////////
		setBatchMode(true);// it is essential to run this section in batch mode. Otherwaise it is very slow to process due to the very repetitive change of window
		newImage("Image_no_NaN", "16-bit black", 1, width * height * slices, 1);
		pix_number = 0;
		for (s = 1; s <= slices; s++) {
			selectWindow(masked_input);
		    run("Duplicate...", "title=&s duplicate range=" + s + "-" + s);
		    current_slice = getTitle();
		    print("slice " + s + " out of " + slices);
			
			for (x = 0; x < width; x++) {
				for (y = 0; y < height; y++) {
						selectWindow(current_slice);
						pixel_value =	getPixel(x, y);
							
							if (pixel_value >= 0) {
									selectWindow("Image_no_NaN");
									setPixel(0, pix_number, pixel_value);
									pix_number = pix_number + 1;
								}
					}
				}
				close(current_slice);
		}
		
		// The array-image we created had the size of Input_height * Input_channels * Input_slices
		// But since we had NaNs we now crop it so that we have an image with only all the values >= 0 
		selectWindow("Image_no_NaN");
		makeRectangle(0, 0, 1, pix_number);
		run("Crop");
		run("Select None");
		
		////End of section where we created the image/array excluding NaNs.
		
		// simple itk otsu multiple thresholds on the image/array excluding NaNs
		print("itk otsu multiple thresholds running on " + input_image);
		print("please be patient... This could take approx. 3 to 10 minutes per image.");
		selectWindow("Image_no_NaN");
		image_6 = getTitle();
		Ext.CLIJ2_push(image_6);
		number_of_thresholds = nb_classes-1;
		Ext.CLIJx_simpleITKOtsuMultipleThresholds(image_6, image_7, number_of_thresholds);
		
		// statisticsOfBackgroundAndLabelledPixels. Here we make a Results table with the minimas for each newly segmented class from the multi Otsu
		Ext.CLIJ2_statisticsOfBackgroundAndLabelledPixels(image_6, image_7);
		Ext.CLIJ2_release(image_6);
		Ext.CLIJ2_release(image_7);
		
		// Below we get intensities of classes and apply to input image to create masks for each class.
		class = newArray(nb_classes);
		for (r = 1; r < nResults(); r++) {
			selectWindow("Results");
		    min_intensity = getResult("MINIMUM_INTENSITY", r);
		    max_intensity = getResult("MAXIMUM_INTENSITY", r);
		    
		    // Greater Constant. Here we use the min value for each class then threshold the input Dapi image.
		    Ext.CLIJ2_greaterConstant(input_image, class[r], min_intensity);
		    if (preview == true) {Ext.CLIJ2_pull(class[r]);
		    rename("Class" + r);}
			}
		
		// Since each class contains the previous we can simply summ all the masks to create the final label map.
		Ext.CLIJ2_create3D(flip, Input_width, Input_height, Input_slices, 32); // We create an empty image where we will add the masks
		Ext.CLIJ2_set(flip, 1);
		for (c = 1; c < lengthOf(class); c++) {
			Ext.CLIJ2_addImages(flip, class[c], flop);
			Ext.CLIJ2_copy(flop, flip);
			}
		 if (preview == true) {Ext.CLIJ2_pull(flip);} 
				
								
		// We set the background to 0
		Ext.CLIJ2_multiplyImages(flip, fill_holes_eroded, final_classes);
		Ext.CLIJ2_release(flip);
		Ext.CLIJ2_release(fill_holes_eroded);
		 if (preview == true) {Ext.CLIJ2_pull(final_classes); run("Fire");}
		
		// Convert U Int16
		Ext.CLIJ2_convertUInt16(final_classes, final_classes_float);
		Ext.CLIJ2_release(final_classes);
		Ext.CLIJ2_pull(final_classes_float);// This is the final label map
		run("Fire");
		Ext.CLIJ2_release(final_classes_float);

			
		//Below we save the classified image, display iamges if necessary, close all and close file loop.
		saveAs("Tif", Output_Directory + File.separator +  filelist[i]);
		print("file " + input_image + "has been processed.");
				
		if (preview == true || pause == true) {
			setBatchMode("exit and display");
			run("Tile");
			waitForUser("", "Process next image in folder?");	
		}
		
		close("Results");
		run("Fresh Start");
		Ext.CLIJ2_clear();
		print("File " + i+1 + " out of " + lengthOf(filelist) +" done." );

}



///////////////////////
//Log printing
if (print_log == true ) {
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("\\Clear");
	print("Input_Directory: " + Input_Directory);
	print("Output_Directory: " + Output_Directory);
	print("Run SIMcheck's Threshold and 16-bit Conversion? " + Threshold_and_conversion);
	print("Chromatin Channel: " + Chromatin_Channel);
	print("number of segmented chromatin classes: " + nb_classes);
	print("sigma_XY for gaussin blur: " + sigma_XY);
	print("sigma_Z for gaussian blur: " + sigma_Z);
	print("Threshold Method Gaussian filtered stack: " + Threshold_Method_Gaussian);
	print("XY radius for maximum filter:  " +max_XY);
	print("Z radius for maximum filter: " + max_Z);
	print("Threshold Method Maximum filtered stack: " + Threshold_Method_Max);
	print("Erosion radius XY: " + erosion_radius_XY);
	print("Erosion radius Z: " + erosion_radius_Z);

	selectWindow("Log"); 
	save(Output_Directory + File.separator + "Log.txt");
	}
print("Macro finished");

//////////
// Below the dialog is defined
#@ File(style="directory") Input_Directory
#@ File(style="directory") Output_Directory

#@ Integer(label="Chromatin Channel", value = 2) Chromatin_Channel
#@ Integer(label="Number of DNA classes", value = 3, min=2, max=7, style="slider") nb_classes
#@ Boolean(label="Run SIMcheck's Threshold and 16-bit Conversion?") Threshold_and_conversion


#@ String(value=" ", visibility="MESSAGE") TextP1
#@ String(value="Gaussian and threshold algorithm to segment the nucleus. Defaults are XY = 6, Z = 2; Threshold = `Otsu`. ", visibility="MESSAGE") TextP2
#@ Integer(label="Gaussian XY sigma", value = 6) sigma_XY
#@ Integer(label="Gaussian Z sigma", value = 2) sigma_Z
#@ String(label="Threshold method for the Gaussian filtered stack", choices={"Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"}, style="list") Threshold_Method_Gaussian

#@ String(value=" ", visibility="MESSAGE") TextP3
#@ String(value="Maximum filter and threshold algorithm to segment the nucleus. Defaults are XY = 6, Z = 2; Threshold = `Osu`. ", visibility="MESSAGE") TextP4
#@ Integer(label="Max XY radius", value = 6) max_XY
#@ Integer(label="Max Z radius", value = 2) max_Z
#@ String(label="Threshold method for the Maximum filtered stack", choices={"Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"}, style="list") Threshold_Method_Max


#@ String(value=" ", visibility="MESSAGE") TextP5
#@ String(value="Optional erosion of nuclear mask. The more you blur the more you need to erode. ", visibility="MESSAGE") TextP6
#@ Integer(label="Erosion radius XY", value = 0) erosion_radius_XY
#@ Integer(label="Erosion radius Z", value = 0) erosion_radius_Z


#@ String(value=" ", visibility="MESSAGE") TextP7
#@ String(value="Displaying intermediary images is useful for optimisation or debugging.", visibility="MESSAGE") TextP8
#@ Boolean(label="Pause macro at the end of each file?") pause
#@ Boolean(label="Show all intermediary images?") preview
#@ Boolean(label="Save a log with the settings used to run this macro?") print_log

#@ String(value="This macro requires the update sites CLIJ, CLIJ2, clijx-assistant, clijx-assistant-extensions and SIMcheck.", visibility="MESSAGE") TextP9
#@ String(value="Running this macro takes approx. 4 to 10 minutes per image.Please be patient when running it.", visibility="MESSAGE") TextP11
#@ String(value="Macro created by Lior Pytowski. Feb 2023, work in progress!", visibility="MESSAGE") TextP13