//AY 08-23-24
//requires dF/F stack input

print("\\Clear");
active_window = getTitle();

info = getImageInfo(); //finds scale factor from original stack
res_index = indexOf(info, "Resolution");
info = substring(info, res_index, res_index + 17);
scale_factor = replace(info, "Resolution: ", "");
scale_factor = parseFloat(scale_factor);
//print(scale_factor);
if (scale_factor == 4.6) {
	scale_factor_zoom = "Z2.5";
} else if (scale_factor == 12.9) {
	scale_factor_zoom = "Z4";
} else if (scale_factor == 26.1) {
	scale_factor_zoom = "Z5";
} else if (scale_factor == 52.2) {
	scale_factor_zoom = "Z6";
} else {
	scale_factor_zoom = "ZX";
}

//automatically finds slice with maximum average pixel intensity by indexing stack (to find baseline_end)
//n.b. returns indexes (slice number-1) 
average_ints = newArray();
for (i=1; i<=nSlices; i+=1) {
	setSlice(i);
	average_int = getValue("Mean");
	average_ints = Array.concat(average_ints, average_int);
}
peak_slices = Array.reverse(Array.rankPositions(average_ints));
setSlice(peak_slices[0] + 1);
//Array.print(peak_slices);

baseline_sum = 0;
for (i=0; i<peak_slices[0]; i+=1) {
	baseline_sum = baseline_sum + average_ints[i];
}

av_baseline = abs(baseline_sum) / peak_slices[0];
diff = (average_ints[(peak_slices[0])] - av_baseline) / av_baseline;

if (diff > 0.05) {
	auto_baseline_end = peak_slices[0] - 1;
} else {
	auto_baseline_end = "";
}

zoom_settings = newArray("Z4", "Z2.5", "Z5", "Z6", "ZX");

Dialog.create("Radial Line Profiles");
Dialog.addMessage("Input Delta F/F Stack");
Dialog.addChoice("Zoom Setting", zoom_settings, scale_factor_zoom);
Dialog.addMessage("Event Detection Parameters:");
Dialog.addNumber("Baseline Start Frame", 1);
Dialog.addNumber("Baseline End Frame", 10);
Dialog.addNumber("Peak Slice", 12);
Dialog.addCheckbox("Gaussian filter (rad=3) before Thresh?", true);
Dialog.addNumber("Stdevs for Thresholding", 2);
Dialog.addMessage("Radial Profile Parameters:");
Dialog.addNumber("Angle Increment (°):", 20);
Dialog.addCheckbox("Save Data", true);
Dialog.show()

zoom_setting = Dialog.getChoice();
baseline_start = Dialog.getNumber();
baseline_end = Dialog.getNumber();
peak_slice = Dialog.getNumber();
filt_opt = Dialog.getCheckbox();
save_opt = Dialog.getCheckbox();
thresh_stdevs = Dialog.getNumber();
angle = Dialog.getNumber();

if (zoom_setting == "Z4") {
	zoom_factor = 12.9;
}

if (zoom_setting == "Z2.5") {
	zoom_factor = 4.6;
}

if (zoom_setting == "Z5") {
	zoom_factor = 26.1;
}

if (zoom_setting == "Z6") {
	zoom_factor = 52.2;
}

if (zoom_setting == "ZX") {
	Dialog.create("Custom Zoom");
	Dialog.addNumber("1 um in pixels: ", "");
	Dialog.show();
	
	custom_zoom = Dialog.getNumber();
	zoom_factor = custom_zoom;
}

if (filt_opt == true) {
	active_window = getTitle();
	run("Duplicate...", "duplicate");
	run("Gaussian Blur...", "sigma=3 stack");
	rename(replace(active_window, ".tif", "") + "_Filtered");
	active_filtered = getTitle();
} else {
	active_filtered = active_window;
}

selectWindow(active_filtered);
baseline_vars = newArray(); //creates blank array for variances from baseline frames
for (i=baseline_start; i<=baseline_end; i+=1) {
	setSlice(i);
	frame_stdev = getValue("StdDev");
	frame_var = pow(frame_stdev, 2);
	baseline_vars = Array.concat(baseline_vars, frame_var);
}

sum_vars = 0; //creates an empty variable for sum of variances from baseline frames
for (i=0; i<lengthOf(baseline_vars); i+=1) {
	sum_vars = sum_vars + baseline_vars[i];
}
	
mean_vars = sum_vars / lengthOf(baseline_vars);
pooled_stdev = sqrt(mean_vars);
print("Baseline Slices:\t" + baseline_start + "-" + baseline_end + "\nPooled Standard Deviation:\t" + pooled_stdev);
setSlice(peak_slice);

if (save_opt == true) {
	dir = getDirectory("Choose Save Directory");
}

selectWindow(active_filtered); //runs segementation (event detection) by analyze particles function using pooled_stdev to threshold
setSlice(peak_slice);
setThreshold(pooled_stdev * thresh_stdevs, 99);
run("Set Measurements...", "area mean centroid perimeter circularity stack redirect=None decimal=4");
run("Analyze Particles...", "size=1-Infinity show=Outlines display clear slice");
rename(replace(active_filtered, ".tif", "") + " Threshold_" + pooled_stdev * thresh_stdevs + "-99");
if (save_opt == true) {
	saveAs("Results", dir + replace(active_filtered, ".tif", "") + "_Threshold_" + d2s(pooled_stdev * thresh_stdevs, 4) + "-99_Results.csv");
}


//import results from Analyze Particles to arrays

areas = newArray(); //create blank array for areas
for (i=0; i<nResults; i+=1) {
	area = getResult("Area", i);
	areas = Array.concat(areas, area);
}

x_values = newArray(); //create blank array for x_value co-ordinates
for (i=0; i<nResults; i+=1) {
	x_value = getResult("X", i);
	x_values = Array.concat(x_values, x_value);
}

y_values = newArray(); //create blank array for y_value co-ordinates
for (i=0; i<nResults; i+=1) {
	y_value = getResult("Y", i);
	y_values = Array.concat(y_values, y_value);
}

slices_in_stack = newArray(); //create blank array for slice in stack
for (i=0; i<nResults; i+=1) {
	slice_in_stack = getResult("Slice", i);
	slices_in_stack = Array.concat(slices_in_stack, slice_in_stack);
}


//create array containing index of maximum area
max_areas = Array.reverse(Array.rankPositions(areas));
//calls index as a single integer from array
//N.B. can add loop to generate radial profiles from 2nd, 3rd...
max_area_index = max_areas[0];

//returns values from respective arrays at specified index of maximum area
max_area_x_value = x_values[max_area_index];
max_area_y_value = y_values[max_area_index];
max_area_value = areas[max_area_index];

print("The Maximum Area is the n-th Event, n = " + max_area_index + 1);
print("The Largest Area is: " + max_area_value + " µm^2");
print("The Centre of the Largest Event (x, y) is at: (" + max_area_x_value + ", " + max_area_y_value + ").");

if (filt_opt == true) {
	close(active_filtered);
}

//generate radial line profiles from event with maximum area

//define center-point of particle
center_x = max_area_x_value;
center_y = max_area_y_value;

//define area of particle - assumed circular to find radius and 2.5 * line_length for line profiles
area = max_area_value;
radius = sqrt(area / PI);
line_length = zoom_factor * 5 * radius;

//define angle increment in degrees to determine number and radial spread of line profiles

angle_rad = (PI / 180) * angle;

print("Drawing Radial Line Profiles at " + angle + "° Increments");
print("Line Length is: " + line_length / zoom_factor + " µm");

//build array of angles
angles = newArray();
for (i=0; i<360; i+=angle) {
	angles = Array.concat(angles, i);
}

//build array of angles in radians (sin/cos functions in rad)
angle_rads = newArray();
for (i=0; i<lengthOf(angles); i+=1) {
	angle_rads = Array.concat(angle_rads, (PI / 180) * angles[i]);
}

run("Clear Results");

//X values
for (i=0; i<(line_length + 1); i+=1) {
	setResult("X", i, ((i + 1) * (1/zoom_factor)));
}

selectWindow(active_window);
setSlice(slices_in_stack[max_area_index]);

//draw lines from center point of length (line_length) at radiating angles (angle)
for (i=0; i<lengthOf(angle_rads); i+=1) {
	makeLine((zoom_factor * center_x), (zoom_factor * center_y), ((zoom_factor * center_x) + (line_length * cos(angle_rads[i]))), ((zoom_factor * center_y) + (line_length * sin(angle_rads[i]))));

//returns line profile as array
	profile = getProfile();	

//export line profile measurements (stored as arrays) to Results sheet
		for (k=0; k<lengthOf(profile); k+=1) {
			setResult("Angle " + angles[i], k, profile[k]);
		}
}

if (save_opt == true) {
	saveAs("Results", dir + replace(active_window, ".tif", "") + "_Angle_" + angle + "_Results.csv");
}

print("");
print("Done!");