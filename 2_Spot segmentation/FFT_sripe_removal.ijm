run("Fresh Start");
run("Bridge (174K)");


thickness  = 3;

getDimensions(width, height, channels, slices, frames);

run("FFT");

center_y = height / 2 - (thickness - 1) / 2
makeRectangle(0, center_y, width, thickness);
run("Rotate...", "  angle=15");
run("Clear");

getDimensions(width, height, channels, slices, frames);
makeRectangle(width/2, height/2, 1, 1);
run("Add...", "value=1");

run("Inverse FFT");