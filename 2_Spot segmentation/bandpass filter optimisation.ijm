close("\\Others");
input = getTitle();

small_structures_filter_range_sart = 0;
small_structures_filter_range_end = 6;
small_structures_filter_range_step = 0.2;

for (i = small_structures_filter_range_sart; i < small_structures_filter_range_end; i =  i + small_structures_filter_range_step) {
selectWindow(input);
run("Duplicate...", " ");
rename(i + "_filtered");
run("Bandpass Filter...", "filter_large=100000 filter_small=&i suppress=None tolerance=5");
//run("Fourier Plots", "(2)_window_function*");
run("Fourier Plots", " ");
}

run("Images to Stack", "  title=FTL use");
run("Images to Stack", "  title=_filtered use");
run("Images to Stack", "  title=FTR use");