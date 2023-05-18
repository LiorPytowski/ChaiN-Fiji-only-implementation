// To make this script run in Fiji, please activate the clij and clij2 plus the SIMcheck  update sites in your Fiji
//Input outputs directory selection
raw_inputs_directory = getDirectory("1 Choose folder with Raw DV inputs");
processed_inputs_directory = getDirectory("2 Choose folder with SIR inputs");
classified_nuclei_inputs_directory = getDirectory("3 Choose folder with classified nuclei inputs");
output_directory = getDirectory("4 Choose where to save result tables");

filelist_raw_inputs = getFileList(raw_inputs_directory);
filelist_processed_inputs = getFileList(processed_inputs_directory);
filelist_classified_nuclei_inputs = getFileList(classified_nuclei_inputs_directory);

Array.sort(filelist_raw_inputs);
Array.sort(filelist_processed_inputs);
Array.sort(filelist_classified_nuclei_inputs);



// Decide if showing intermediary steps or not. Usefull for parameter optimisation and debugging
preview = true;
pause = true;

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
    if (endsWith(filelist_processed_inputs[i], ".dv")) { 
      open(processed_inputs_directory + File.separator + filelist_processed_inputs[i]);

	name_without_extension = File.nameWithoutExtension;
	input_image = getTitle();
	getVoxelSize(Voxel_width, Voxel_height, Voxel_depth, unit);
	
	run("Duplicate...", "duplicate channels=1");
	getDimensions(width, height, channels, slices, frames);
	input_image_c1 = getTitle();
	Ext.CLIJx_pushMetaData();
	Ext.CLIJ2_pushCurrentZStack(input_image_c1);
	
	// Make Isotropic // This assumes that X and Y are equal
	original_voxel_size_x = Voxel_width;
	original_voxel_size_y = Voxel_height;
	original_voxel_size_z = Voxel_depth;
	new_voxel_size = Voxel_width;
	Ext.CLIJ2_makeIsotropic(input_image_c1, isotropic_input, original_voxel_size_x, original_voxel_size_y, original_voxel_size_z, new_voxel_size);
	Ext.CLIJ2_release(input_image_c1);
		if (preview == true) {		Ext.CLIJ2_pull(isotropic_input);}
	
	// Laplacian Of Gaussian3D // 0 means no Gaussian
	sigma_x = 1;
	sigma_y = 1;
	sigma_z = 1;
	Ext.CLIJx_laplacianOfGaussian3D(isotropic_input, laplacian_of_Gaussian3D, sigma_x, sigma_y, sigma_z);
		if (preview == true) {		Ext.CLIJ2_pull(laplacian_of_Gaussian3D);}
	
	// Invert
	Ext.CLIJ2_invert(laplacian_of_Gaussian3D, inverted_laplacian_of_Gaussian3D);
	Ext.CLIJ2_release(laplacian_of_Gaussian3D);
		if (preview == true) {		Ext.CLIJ2_pull(inverted_laplacian_of_Gaussian3D);}
	
	// Maximum3D Sphere filter
	radius_x = 2.0;
	radius_y = 2.0;
	radius_z = 2.0;
	Ext.CLIJ2_maximum3DSphere(inverted_laplacian_of_Gaussian3D, maximum_3D_filter, radius_x, radius_y, radius_z);
		if (preview == true) {		Ext.CLIJ2_pull(maximum_3D_filter);}
	
	// Automatic Threshold of inverted laplace
	method = "Moments";
	Ext.CLIJ2_automaticThreshold(inverted_laplacian_of_Gaussian3D, mask_of_Laplacian, method);
	Ext.CLIJ2_release(inverted_laplacian_of_Gaussian3D);
		if (preview == true) {		Ext.CLIJ2_pull(mask_of_Laplacian);}
	
	// Automatic Threshold of Maximum 3D Sphere filter
	method = "Otsu";
	Ext.CLIJ2_automaticThreshold(maximum_3D_filter, maximum_3D_filter_mask, method);
	Ext.CLIJ2_release(maximum_3D_filter);
		if (preview == true) {		Ext.CLIJ2_pull(maximum_3D_filter_mask);}
	
	// Binary And
	Ext.CLIJ2_binaryAnd(mask_of_Laplacian, maximum_3D_filter_mask, binary_mask);
	Ext.CLIJ2_release(mask_of_Laplacian);
	Ext.CLIJ2_release(maximum_3D_filter_mask);
		if (preview == true) {		Ext.CLIJ2_pull(binary_mask);}
	
	// Detect Maxima3D Box
	radiusX = 2.0;
	radiusY = 2.0;
	radiusZ = 2.0;
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
	radius = 1;
	relabel_islands = 0.0;
	Ext.CLIJ2_erodeLabels(Watersheded_labels, eroded_labels, radius, relabel_islands);
	Ext.CLIJ2_release(Watersheded_labels);
	Ext.CLIJ2_pull(eroded_labels);
	
	// Clear GPU memory
	Ext.CLIJ2_clear();
	
	// Reslice to original z sice
	run("Properties...", "pixel_width=0.041 pixel_height=0.041 voxel_depth=0.041");
	run("Scale...", "width=" + width + " height=" + height + " depth=" + slices +" interpolation=None process create");
	resliced_label_map = getTitle();
	run("glasbey_on_dark");
	Ext.CLIJ2_pushCurrentZStack(resliced_label_map);
		
	//////////////////////////////// Modulation Contrast Masking
	// Open raw DV iamge
	open(raw_inputs_directory + File.separator + filelist_raw_inputs[i]);
	run("Duplicate...", "duplicate channels=1");
	rename("RawInput");
	
	// Modulation contrast calculation
	run("Modulation Contrast", "angles=3 phases=5 z_window_half-width=1");
	MCNR_not_scaled = getTitle();
	Ext.CLIJ2_pushCurrentZStack(MCNR_not_scaled);
	
	// Modulation contrast masking of resliced label map
	// Greater Constant
	constant = 5.0;
	Ext.CLIJ2_greaterConstant(MCNR_not_scaled, MCNR_Mask, constant);
	Ext.CLIJ2_release(MCNR_not_scaled);
	if (preview == true) {		Ext.CLIJ2_pull(MCNR_Mask);}
	
	// Rescale MCNR Mask to match label image dimensions
	//Ext.CLIJ2_getDimensions(resliced_label_map, width, height, depth);
	//Ext.CLIJ2_create3D(MCNR_Mask_Scaled, width, height, depth, 32);/////////////////////////////##################################################################
	Ext.CLIJ2_downsample3D(MCNR_Mask, MCNR_Mask_Scaled, 2, 2, 1);
	Ext.CLIJ2_release(MCNR_Mask);
	if (preview == true) {		Ext.CLIJ2_pull(MCNR_Mask_Scaled);}
	
	// Multiply Images
	Ext.CLIJ2_multiplyImages(MCNR_Mask_Scaled, resliced_label_map, resliced_label_map_Masked);
	Ext.CLIJ2_release(MCNR_Mask_Scaled);
	if (preview == true) {		Ext.CLIJ2_pull(resliced_label_map);}
	
	// Exclude Labels Outside Size Range // This is the final label image
	minimum_size = 6;
	maximum_size = 1000;
	Ext.CLIJ2_excludeLabelsOutsideSizeRange(resliced_label_map_Masked, Labels_MCNR_and_size_filtered, minimum_size, maximum_size);
	Ext.CLIJ2_release(resliced_label_map_Masked);
		if (preview == true) {		Ext.CLIJ2_pull(Labels_MCNR_and_size_filtered);}
		
	
	// Reduce Labels To Centroids
	Ext.CLIJ2_reduceLabelsToCentroids(Labels_MCNR_and_size_filtered, final_centroids);
	Ext.CLIJ2_release(Labels_MCNR_and_size_filtered);
	Ext.CLIJ2_pull(final_centroids);
	Image_final_label_centroids = getTitle();
	
	

	//////////////////////////// CLASSIFIED NUCLEI SECTION
	open(classified_nuclei_inputs_directory + File.separator + filelist_classified_nuclei_inputs[i]);
	name_classified_nuclei_without_extension = File.nameWithoutExtension;
	name_classified_nuclei = getTitle();
	
	///////////////////// Make measurements
	// Statistics of labelled pixels
	Ext.CLIJ2_push(name_classified_nuclei);
	Ext.CLIJ2_push(Image_final_label_centroids);
	Ext.CLIJ2_statisticsOfLabelledPixels(name_classified_nuclei, Image_final_label_centroids);
	
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
	
	// Add Row to results table with name of input image. Usefull for post processing
	for (h = 0; h < nResults(); h++) {
			setResult("Input_image_name", h, name_without_extension);
		}
		
	Table.renameColumn("IDENTIFIER", "Label_number");
	Table.renameColumn("MEAN_INTENSITY", "Chromatin_class");
	Table.rename("Results", name_without_extension); // This is not really necessary since later, when saving whe set the name as well.
	
	saveAs("Results", output_directory + name_without_extension + ".csv");
	tablename= name_without_extension + ".csv";
	close(tablename);
	
	//////////////////////////////////////////////////
	///Distance foci to chromatin edges section
	CONTINUE HERE
	run("DiAna_Analyse", "img1=InputC" + ChannelA + " img2=InputC" + ChannelB + " lab1=" + centers_of_mass_map_A + " lab2=" + centers_of_mass_map_B + " adja kclosest=" + nb_neighbours);
	selectWindow("AdjacencyResults");
	Table.deleteColumn("Dist min EdgeA-EdgeB");	Table.deleteColumn("Dist min CenterA-EdgeB");	Table.deleteColumn("Dist min EdgeA-CenterB");
	saveAs("AdjacencyResults", Output_Directory + File.separator + stack_name_without_extension + "@AdjacencyResultsCentersOfMass_C" + ChannelA + "vsC" + ChannelB + ".csv");
	
	
	
	

	// If in debug mode
	if (preview == true || pause == true) {
		run("Tile");	
		waitForUser("", "Process next image in folder?");	
		} 
	

// End file loop and close all images
//exit;
run("Fresh Start");
run("Close All");
    } 
}



