// To make this script run in Fiji, please activate the clij and clij2 plus the SIMcheck  update sites in your Fiji
//Input outputs directory selection
classified_nuclei_inputs_directory = getDirectory("3 Choose folder with classified nuclei inputs");
output_directory = getDirectory("4 Choose where to save result tables");

filelist_classified_nuclei_inputs = getFileList(classified_nuclei_inputs_directory);
Array.sort(filelist_classified_nuclei_inputs);

// Open 3D manager
run("3D Manager");
Ext.Manager3D_Reset();
run("3D Manager Options", "volume surface compactness distance_to_surface");

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

// Load image from disc 
for (i = 0; i < lengthOf(filelist_classified_nuclei_inputs); i++) {
	open(classified_nuclei_inputs_directory + File.separator + filelist_classified_nuclei_inputs[i]);
	name_classified_nuclei_without_extension = File.nameWithoutExtension;
	name_classified_nuclei = getTitle();
	
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	
	// 3D Manager
	Ext.Manager3D_AddImage();
	Ext.Manager3D_Measure();
	Ext.Manager3D_SaveResult("M",output_directory + name_classified_nuclei_without_extension + "_Classes_stats.csv");
	Ext.Manager3D_CloseResult("M");
	
	
	run("CLIJ2 Macro Extensions", "cl_device=");
	Ext.CLIJ2_clear();
	///////////////////////////////
	Ext.CLIJ2_pushCurrentZStack(name_classified_nuclei);
	for (j = 1; j <= max; j++) {

	// Equal Constant
	constant = j;
	class = "Class_" + j;
	Ext.CLIJ2_equalConstant(name_classified_nuclei, class, constant);
	//Ext.CLIJ2_pull(class);
		
	// Class fragmentation
	class_fragmented = "Class_" + j +"_fragmented";
	Ext.CLIJ2_connectedComponentsLabelingDiamond(class, class_fragmented);
	Ext.CLIJ2_pull(class_fragmented);
	run("glasbey_inverted");
	
	}
	
	run("3D Manager");
	Ext.Manager3D_Reset();
	for (j = 1; j <= max; j++) {
	selectWindow("Class_1_fragmented");
	Ext.Manager3D_AddImage();
	Ext.Manager3D_Measure();
	Ext.Manager3D_SaveResult("M",output_directory + name_classified_nuclei_without_extension + "_class_" + j + "_stats.csv");
	Ext.Manager3D_CloseResult("M");
	
	}
	

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



