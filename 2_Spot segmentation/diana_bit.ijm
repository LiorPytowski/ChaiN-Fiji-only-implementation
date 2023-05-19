	
	selectWindow("CLIJ2_reduceLabelsToCentroids_result66");
	Image_final_label_centroids = getTitle();
	
	selectWindow("EM16-12-A_C127_S1_1514_H3K27me3-594_Sytox_G1_01_SIR_EAL.tif");
	name_classified_nuclei = getTitle();
	
	
	///Distance foci to chromatin edges section
	nb_neighbours = 2;
	run("DiAna_Analyse", "img1=" + name_classified_nuclei + " img2=" + Image_final_label_centroids + " lab1=" + name_classified_nuclei + " lab2=" + Image_final_label_centroids + " adja kclosest=" + nb_neighbours);
	selectWindow("AdjacencyResults");
	
	
	sdfsdf
	Table.deleteColumn("Dist min EdgeA-EdgeB");	Table.deleteColumn("Dist min CenterA-EdgeB");	Table.deleteColumn("Dist min EdgeA-CenterB");
	saveAs("AdjacencyResults", Output_Directory + File.separator + name_classified_nuclei_without_extension + "_SpotDistancesToClasses.csv");
	close(name_classified_nuclei_without_extension + "_SpotDistancesToClasses.csv");

	