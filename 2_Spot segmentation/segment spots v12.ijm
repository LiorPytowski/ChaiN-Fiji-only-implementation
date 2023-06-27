// To make this script run in Fiji, please activate the clij and clij2 plus the SIMcheck  update sites in your Fiji
//Input outputs directory selection
filelist_raw_inputs = getFileList(raw_inputs_directory);
filelist_processed_inputs = getFileList(processed_inputs_directory);
filelist_classified_nuclei_inputs = getFileList(classified_nuclei_inputs_directory);
Array.sort(filelist_raw_inputs);
Array.sort(filelist_processed_inputs);
Array.sort(filelist_classified_nuclei_inputs);

// Decide if showing intermediary steps or not. Usefull for parameter optimisation and debugging
if (preview == true || pause == true) {
	run("3D Manager");
	Ext.Manager3D_Reset();
	} else {
	setBatchMode(true);
	}

// Clear workspace, initialise CLIJ and clear GPU
run("Fresh Start");
run("Input/Output...", "jpeg=100 gif=-1 file=.csv copy_column save_column"); // this is for saving the results without row number
run("CLIJ2 Macro Extensions", "cl_device=");
Ext.CLIJ2_clear();

// Load image from disc 
for (i = 0; i < lengthOf(filelist_processed_inputs); i++) {
    if (endsWith(filelist_processed_inputs[i], ".dv")) { /////////////////////////////////////////////////////////////////////////////////////////////////////HARD CODED EXTENSION
      open(processed_inputs_directory + File.separator + filelist_processed_inputs[i]);

	name_without_extension = File.nameWithoutExtension;
	input_image = getTitle();
	getVoxelSize(Voxel_width, Voxel_height, Voxel_depth, unit);
	
	run("Duplicate...", "duplicate channels=&Spots_Channel");
	getDimensions(SIR_width, SIR_height, SIR_channels, SIR_slices, SIR_frames);
	input_image_c1 = getTitle();
	Ext.CLIJx_pushMetaData();
	Ext.CLIJ2_pushCurrentZStack(input_image_c1);
	
	// Make Isotropic // This assumes that X and Y are equal
	original_voxel_size_x = Voxel_width;
	original_voxel_size_y = Voxel_height;
	original_voxel_size_z = Voxel_depth;
	new_voxel_size = Voxel_width;
	Ext.CLIJ2_makeIsotropic(input_image_c1, isotropic_input, original_voxel_size_x, original_voxel_size_y, original_voxel_size_z, new_voxel_size);
	//Ext.CLIJ2_release(input_image_c1);
		if (preview == true) {		Ext.CLIJ2_pull(isotropic_input);}
	
	// Laplacian Of Gaussian3D // 0 means no Gaussian
	sigma_x = Laplacian_Of_Gaussian;
	sigma_y = Laplacian_Of_Gaussian;
	sigma_z = Laplacian_Of_Gaussian;
	Ext.CLIJx_laplacianOfGaussian3D(isotropic_input, laplacian_of_Gaussian3D, sigma_x, sigma_y, sigma_z);
		if (preview == true) {		Ext.CLIJ2_pull(laplacian_of_Gaussian3D);}
	
	// Invert
	Ext.CLIJ2_invert(laplacian_of_Gaussian3D, inverted_laplacian_of_Gaussian3D);
	Ext.CLIJ2_release(laplacian_of_Gaussian3D);
		if (preview == true) {		Ext.CLIJ2_pull(inverted_laplacian_of_Gaussian3D);}
	
	// Maximum3D Sphere filter
	radius_x = Maximum3D_Sphere_radiues;
	radius_y = Maximum3D_Sphere_radiues;
	radius_z = Maximum3D_Sphere_radiues;
	Ext.CLIJ2_maximum3DSphere(inverted_laplacian_of_Gaussian3D, maximum_3D_filter, radius_x, radius_y, radius_z);
		if (preview == true) {		Ext.CLIJ2_pull(maximum_3D_filter);}
	
	// Automatic Threshold of inverted laplace
	method = Threshold_Method_Inverted_laplace;
	Ext.CLIJ2_automaticThreshold(inverted_laplacian_of_Gaussian3D, mask_of_Laplacian, method);
	Ext.CLIJ2_release(inverted_laplacian_of_Gaussian3D);
		if (preview == true) {		Ext.CLIJ2_pull(mask_of_Laplacian);}
	
	// Automatic Threshold of Maximum 3D Sphere filter
	method = Threshold_Method_Maximum3D_filter;
	Ext.CLIJ2_automaticThreshold(maximum_3D_filter, maximum_3D_filter_mask, method);
	Ext.CLIJ2_release(maximum_3D_filter);
		if (preview == true) {		Ext.CLIJ2_pull(maximum_3D_filter_mask);}
	
	// Binary And
	Ext.CLIJ2_binaryAnd(mask_of_Laplacian, maximum_3D_filter_mask, binary_mask);
	Ext.CLIJ2_release(mask_of_Laplacian);
	Ext.CLIJ2_release(maximum_3D_filter_mask);
		if (preview == true) {		Ext.CLIJ2_pull(binary_mask);}
	
	// Detect Maxima3D Box
	radiusX = Detect_maxima_radius;
	radiusY = Detect_maxima_radius;
	radiusZ = Detect_maxima_radius;
	Ext.CLIJ2_detectMaxima3DBox(isotropic_input, image_maxima_spots, radiusX, radiusY, radiusZ);
	Ext.CLIJ2_release(isotropic_input);
		if (preview == true) {		Ext.CLIJ2_pull(image_maxima_spots);}
	
	// Label Spots
	Ext.CLIJ2_labelSpots(image_maxima_spots, labelled_spots);
	Ext.CLIJ2_release(image_maxima_spots);			
		if (preview == true) {		Ext.CLIJ2_pull(labelled_spots);}
	
	// Marker Controlled Watershed
	Ext.CLIJx_morphoLibJMarkerControlledWatershed(binary_mask, labelled_spots, binary_mask, Watersheded_labels);
	Ext.CLIJ2_release(labelled_spots);
	Ext.CLIJ2_release(binary_mask);
		if (preview == true) {		Ext.CLIJ2_pull(Watersheded_labels);}
	
	// Erode Labels
	radius = erosion_radius;
	relabel_islands = 0.0;
	Ext.CLIJ2_erodeLabels(Watersheded_labels, eroded_labels, radius, relabel_islands);
	Ext.CLIJ2_release(Watersheded_labels);
	Ext.CLIJ2_pull(eroded_labels);
		
	// Reslice to original z sice
	run("Properties...", "pixel_width=0.041 pixel_height=0.041 voxel_depth=0.041");    ////////////////////////////////////////////////////////////////////////////////////////////SORT THIS OUT
	run("Scale...", "width=" + SIR_width + " height=" + SIR_height + " depth=" + SIR_slices +" interpolation=None process create");
	resliced_label_map = getTitle();
	run("glasbey_on_dark");
	Ext.CLIJ2_pushCurrentZStack(resliced_label_map);
	
	// Exclude Labels Outside Size Range // This is the final label image
	minimum_size = Min_volume;
	maximum_size = Max_volume;
	Ext.CLIJ2_excludeLabelsOutsideSizeRange(resliced_label_map, resliced_label_map_size_filtered, minimum_size, maximum_size);
	Ext.CLIJ2_release(resliced_label_map);
		if (preview == true) {		Ext.CLIJ2_pull(resliced_label_map_size_filtered);}
		
	
	// This section will extract the statistics of lables so that we can create a centers of mass stack
	//setBatchMode(false);
	//setBatchMode("exit and display");
				intensity_input = input_image_c1;
				labelmap = resliced_label_map_size_filtered;
				Ext.CLIJ2_statisticsOfLabelledPixels(intensity_input, labelmap);
				Ext.CLIJ2_release(resliced_label_map_size_filtered);
				
					// generate center of mass map channel B
					centers_of_mass_map = "Centers_of_Mass";
					newImage(centers_of_mass_map, "32-bit", SIR_width, SIR_height, SIR_slices);
						
					Stack.setXUnit("micron");
					run("Properties...", "pixel_width=&Voxel_width pixel_height=&Voxel_height voxel_depth=&Voxel_depth");
					
					for (r = 0; r < nResults; r++) {
					CMx = getResult("MASS_CENTER_X", r);
					CMy = getResult("MASS_CENTER_Y", r);
					CMz = getResult("MASS_CENTER_Z", r);
					id_pix = getResult("IDENTIFIER", r);
					
					setSlice(CMz + 1); //we add 1 because CLIJ counts starting from 0 but Imagej from 1
					setPixel(CMx, CMy, id_pix);
					}
				rename("CentersOfMass");
				centers_of_mass_stack = getTitle();
				Ext.CLIJ2_push(centers_of_mass_stack);
				close("Results");
	
	
	//////////////////////////////// Modulation Contrast Masking
	// Open raw DV iamge
	open(raw_inputs_directory + File.separator + filelist_raw_inputs[i]);
	run("Duplicate...", "duplicate channels=1");
	rename("RawInput");
		
	// Modulation contrast calculation
	run("Modulation Contrast", "angles=3 phases=5 z_window_half-width=1");
	MCNR_not_scaled = getTitle();
	getDimensions(MCNR_width, MCNR_height, MCNR_channels, MCNR_slices, MCNR_frames);
	Ext.CLIJ2_pushCurrentZStack(MCNR_not_scaled);
	
	// Modulation contrast masking of resliced label map
	// Greater Constant
	constant = Modulation_contrast_threshold;
	Ext.CLIJ2_greaterConstant(MCNR_not_scaled, MCNR_Mask, constant);
	Ext.CLIJ2_release(MCNR_not_scaled);
	if (preview == true) {		Ext.CLIJ2_pull(MCNR_Mask);}
	
	// Rescale MCNR Mask to match label image dimensions
	factor_X = SIR_width / MCNR_width;
	factor_Y = SIR_height / MCNR_height;
	factor_Z = SIR_slices / MCNR_slices;
	Ext.CLIJ2_downsample3D(MCNR_Mask, MCNR_Mask_Scaled, factor_X, factor_Y, factor_Z);
	//Ext.CLIJ2_downsample3D(MCNR_Mask, MCNR_Mask_Scaled, 2, 2, 1);  //////////////////////////////////////////////////////////////This assumes that the raw image is always 2x smaller than processed
	Ext.CLIJ2_release(MCNR_Mask);
	if (preview == true) {		Ext.CLIJ2_pull(MCNR_Mask_Scaled);}
	
	// Multiply Images
	Ext.CLIJ2_multiplyImages(MCNR_Mask_Scaled, centers_of_mass_stack, centers_of_mass_stack_Masked);
	Ext.CLIJ2_release(MCNR_Mask_Scaled);
	if (preview == true) {		Ext.CLIJ2_pull(centers_of_mass_stack_Masked);}
	
	//convert to 16 bit
	Ext.CLIJ2_convertUInt16(centers_of_mass_stack_Masked, centers_of_mass_stack_Masked_sixteen);
	if (preview == true) {		Ext.CLIJ2_pull(centers_of_mass_stack_Masked_sixteen);}
	
	//////////////////////////// CLASSIFIED NUCLEI SECTION
	open(classified_nuclei_inputs_directory + File.separator + filelist_classified_nuclei_inputs[i]);
	name_classified_nuclei_without_extension = File.nameWithoutExtension;
	name_classified_nuclei = getTitle();
	
	///////////////////// Check on which class each foci sits on
	// Statistics of labelled pixels
	Ext.CLIJ2_push(name_classified_nuclei);
	Ext.CLIJ2_statisticsOfLabelledPixels(name_classified_nuclei, centers_of_mass_stack_Masked);
	
	// Delete unnnecessary columns
	Table.deleteColumn("BOUNDING_BOX_X");Table.deleteColumn("BOUNDING_BOX_Y");Table.deleteColumn("BOUNDING_BOX_Z");
	Table.deleteColumn("BOUNDING_BOX_END_X");Table.deleteColumn("BOUNDING_BOX_END_Y");Table.deleteColumn("BOUNDING_BOX_END_Z");
	Table.deleteColumn("BOUNDING_BOX_WIDTH");Table.deleteColumn("BOUNDING_BOX_HEIGHT");Table.deleteColumn("BOUNDING_BOX_DEPTH");
	Table.deleteColumn("MINIMUM_INTENSITY");Table.deleteColumn("MAXIMUM_INTENSITY");Table.deleteColumn("SUM_INTENSITY");
	Table.deleteColumn("STANDARD_DEVIATION_INTENSITY");Table.deleteColumn("PIXEL_COUNT");
	Table.deleteColumn("SUM_INTENSITY_TIMES_X");Table.deleteColumn("SUM_INTENSITY_TIMES_Y");Table.deleteColumn("SUM_INTENSITY_TIMES_Z");
	Table.deleteColumn("MASS_CENTER_X");Table.deleteColumn("MASS_CENTER_Y");Table.deleteColumn("MASS_CENTER_Z");
	Table.deleteColumn("SUM_X");Table.deleteColumn("SUM_Y");Table.deleteColumn("SUM_Z");
	Table.deleteColumn("CENTROID_X");Table.deleteColumn("CENTROID_Y");Table.deleteColumn("CENTROID_Z");
	Table.deleteColumn("SUM_DISTANCE_TO_MASS_CENTER");Table.deleteColumn("MEAN_DISTANCE_TO_MASS_CENTER");Table.deleteColumn("MAX_DISTANCE_TO_MASS_CENTER");
	Table.deleteColumn("MAX_MEAN_DISTANCE_TO_MASS_CENTER_RATIO");Table.deleteColumn("SUM_DISTANCE_TO_CENTROID");
	Table.deleteColumn("MEAN_DISTANCE_TO_CENTROID");Table.deleteColumn("MAX_DISTANCE_TO_CENTROID");Table.deleteColumn("MAX_MEAN_DISTANCE_TO_CENTROID_RATIO");
	
	// Add column to results table with name of input image. Usefull for post processing
	for (h = 0; h < nResults(); h++) {
			setResult("Input_image_name", h, name_without_extension);
		}
		
	Table.renameColumn("IDENTIFIER", "Label_number");
	Table.renameColumn("MEAN_INTENSITY", "Chromatin_class");
	Table.rename("Results", name_without_extension); // This is not really necessary since later, when saving we set the name as well.
	
	saveAs("Results", output_directory +  File.separator + name_without_extension + ".csv");
	tablename= name_without_extension + ".csv";
	close(tablename);
	
	
	///////////////////// Measure distance foci to interchromatin
	
	// Within Intensity Range, this wil combine classes into one
	above_intensity = 1.0;
	below_intensity = 8.0;
	Ext.CLIJ2_withinIntensityRange(name_classified_nuclei, chromatin, above_intensity, below_intensity);
	Ext.CLIJ2_release(name_classified_nuclei);
	
	Ext.CLIJ2_convertFloat(chromatin, chromatin_float);
	Ext.CLIJ2_release(chromatin);
	if (preview == true) {		Ext.CLIJ2_pull(chromatin_float);}
	
	// make isotropic with no interpoilation
	factor_X = 1;
	factor_Y = 1;
	factor_Z = Voxel_depth / Voxel_width;
	Ext.CLIJ2_downsample3D(chromatin_float, chromatin_float_isotropic, factor_X, factor_Y, factor_Z);
	if (preview == true) {		Ext.CLIJ2_pull(chromatin_float_isotropic);}
	
	// Distance To Label Border Map
	Ext.CLIJx_morphoLibJDistanceToLabelBorderMap(chromatin_float_isotropic, chromatin_float_isotropic_distance_to_border);
	Ext.CLIJ2_release(chromatin_float_isotropic);
	
	Ext.CLIJ2_pull(chromatin_float_isotropic_distance_to_border);
	run("Green Fire Blue");
	Ext.CLIJ2_release(chromatin_float_isotropic_distance_to_border);
	
	
	
	
	
	//////////////////////////////////////////////////

			if (overlay == true) {
			// Dilate Labels
			radius = 2.0;
			Ext.CLIJ2_dilateLabels(centers_of_mass_stack_Masked, centers_of_mass_stack_Masked_dilated, radius);
			Ext.CLIJ2_release(centers_of_mass_stack_Masked);
					
			// Reduce Labels To Label Edges
			Ext.CLIJ2_reduceLabelsToLabelEdges(centers_of_mass_stack_Masked_dilated, label_edges);
			Ext.CLIJ2_release(centers_of_mass_stack_Masked_dilated);
			
			Ext.CLIJ2_pull(label_edges);
			run("glasbey_on_dark");
			Ext.CLIJ2_release(label_edges);
			
			run("Merge Channels...", "c1=&input_image_c1 c2=&label_edges create keep");
			}

	// If in debug mode
	if (preview == true || pause == true) {
		run("Tile");	
		waitForUser("", "Process next image in folder?");	
		} 

// End file loop and close all images
run("Fresh Start");
run("Close All");
Ext.CLIJ2_clear();

    } 
}


///////////////////////
//Log printing
if (print_log == true ) {
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("\\Clear");
	print("1 Choose folder with Raw DV inputs: " + raw_inputs_directory);
	print("2 Choose folder with SIR inputs: " + processed_inputs_directory);
	print("3 Choose folder with classified nuclei inputs: " + classified_nuclei_inputs_directory);
	print("4 Choose where to save result tables: " + output_directory);
	print("Spots Channel: " + Spots_Channel);
	print("Gaussian radius for Laplacian Of Gaussian3D: " + Laplacian_Of_Gaussian);
	print("Maximum3D Sphere filter radius: " + Maximum3D_Sphere_radiues);
	print("Threshold method for the inverted Laplace: " + Threshold_Method_Inverted_laplace);
	print("Threshold method for the Maximum3D filter: " + Threshold_Method_Maximum3D_filter);
	print("Radius for 3D maxima detection: " + Detect_maxima_radius);
	print("Label erosion, in voxels: " + erosion_radius);
	print("Modulation contrast threshold: " + Modulation_contrast_threshold);
	print("Minimum label volume in voxels: " + Min_volume);
	print("Maximum label volume in voxels: " + Max_volume);

	selectWindow("Log"); 
	save(output_directory + File.separator + "Log.txt");
	}
print("Macro finished");





//////////
// Below the dialog is defined
#@ File(label="1 Choose folder with Raw DV inputs" , style="directory") raw_inputs_directory
#@ File(label="2 Choose folder with SIR inputs", style="directory") processed_inputs_directory
#@ File(label="3 Choose folder with classified nuclei inputs", style="directory") classified_nuclei_inputs_directory
#@ File(label="4 Choose where to save result tables", style="directory") output_directory
					
					
#@ Integer(label="Spots Channel", value = 1) Spots_Channel
#@ Float (label="Gaussian radius for Laplacian Of Gaussian3D. Default is 1.", value = 1) Laplacian_Of_Gaussian
#@ Float (label="Maximum3D Sphere filter radius. Default is 2.", value = 2.0) Maximum3D_Sphere_radiues
#@ String(label="Threshold method for the inverted Laplace (default is Moments)", choices={"Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"}, style="list") Threshold_Method_Inverted_laplace
#@ String(label="Threshold method for the Maximum3D filter (default is Otsu)", choices={"Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"}, style="list") Threshold_Method_Maximum3D_filter
#@ Float (label="Radius for 3D maxima detection. Default is 2.", value = 2) Detect_maxima_radius
#@ Integer(label="Label erosion, in voxels. Default is 1", value = 1) erosion_radius

#@ Float (label="Modulation contrast threshold. Default is 7.", value = 7) Modulation_contrast_threshold

#@ Integer(label="Minimum label volume in voxels. Default is 6", value = 6) Min_volume
#@ Integer(label="Maximum label volume in voxels", value = 1000) Max_volume

#@ String(value=" ", visibility="MESSAGE") TextP7
#@ String(value="Displaying intermediary images is useful for optimisation or debugging.", visibility="MESSAGE") TextP8
#@ Boolean(label="Pause macro at the end of each file?") pause
#@ Boolean(label="Show all intermediary images?") preview
#@ Boolean(label="Save a log with the settings used to run this macro?") print_log
#@ Boolean(label="Display segmented particles over input image?") overlay

#@ String(value="This macro requires the update sites CLIJ, CLIJ2, clijx-assistant, clijx-assistant-extensions and SIMcheck.", visibility="MESSAGE") TextP9
#@ String(value="Running this macro takes approx. 4 to 10 minutes per image.Please be patient when running it.", visibility="MESSAGE") TextP11
#@ String(value="Macro created by Lior Pytowski. Feb-June 2023, work in progress!", visibility="MESSAGE") TextP13
