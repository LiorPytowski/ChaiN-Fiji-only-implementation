// To make this script run in Fiji, please activate the clij and clij2 plus the SIMcheck  update sites in your Fiji
//Input outputs directory selection
processed_inputs_directory = getDirectory("2 Choose folder with SIR inputs");
classified_nuclei_inputs_directory = getDirectory("3 Choose folder with classified nuclei inputs");
output_directory = getDirectory("4 Choose where to save result tables");

filelist_processed_inputs = getFileList(processed_inputs_directory);
filelist_classified_nuclei_inputs = getFileList(classified_nuclei_inputs_directory);

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



