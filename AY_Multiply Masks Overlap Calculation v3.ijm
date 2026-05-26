//AY edit 09-14-22
//Requres RED mask and dFoverF windows
//UPDATE 09-14-22 will now loop through all open dFoverF windows

print("\\Clear");
run("Clear Results");
run("Set Measurements...", "area mean redirect=None decimal=4");

open_windows = getList("image.titles");
multi_opt = false;

red_index = 0; red_check = -1; //searches for index of open_windows with "RED" for auto-population of RED dialog choice
for (i=0; i<open_windows.length; i+=1) {
	red_check = indexOf(open_windows[i], "RED");
	if (red_check != -1) {
		red_index = i;
	}
}

green_index = newArray(); green_check = -1; //searches for index of open_windows with "dFoverF" for auto-population of GREEN dialog choice
for (i=0; i<open_windows.length; i+=1) {
	green_check = indexOf(open_windows[i], "dFoverF");
	if (green_check != -1) {
		green_index = Array.concat(green_index, i);
	}
}

Dialog.create("Mask Multiplier");
Dialog.addChoice("Red Mask", open_windows, open_windows[red_index]);
if (green_index.length > 1) {
	Dialog.addCheckbox("Calculate Overlap for Multiple ∆F/F Sweeps", true);
}
for (i=0; i<green_index.length; i+=1) {
	Dialog.addChoice("Green dF/F", open_windows, open_windows[(green_index[i])]);
}
Dialog.addMessage("\n");
Dialog.addCheckbox("Calculate Noise", false);
Dialog.show();

red_mask = Dialog.getChoice();
if (green_index.length > 1) {
	multi_opt = Dialog.getCheckbox();
}
green_deltas = newArray();
for (i=0; i<green_index.length; i+=1) {
	green_delta = open_windows[(green_index[i])];
	green_delta = Dialog.getChoice();
	green_deltas = Array.concat(green_deltas, green_delta);
}
noise_opt = Dialog.getCheckbox();

selectWindow(red_mask); //changes red mask from 0-255 to binary (0-1) unless it's already binary
run("Duplicate...", "title=red_mask_copy");
max = getValue("Max");
if (max == 255) {
	run("Divide...", "value=255");
} else if (max == 1) {
}
setMinAndMax(0, 1);

if (multi_opt == true) {
	green_windows = green_index.length;
	areas = newArray(); means = newArray(); maxs = newArray();
} else {
	green_windows = 1;
}

Dialog.create("Baseline/Peak Slices");
Dialog.addNumber("Baseline Start:", 1);
Dialog.addNumber("Baseline End:", 10);
Dialog.addNumber("Peak Slice", 12);
Dialog.show();
	
baseline_start = Dialog.getNumber();
baseline_end = Dialog.getNumber();
peak_slice = Dialog.getNumber();

for (m=0; m<green_windows; m+=1) {
	
	selectWindow(green_deltas[m]); //
	print(green_deltas[m]);

	run("Duplicate...", "title=" + green_deltas[m] + "_mean duplicate");
	run("Gaussian Blur...", "sigma=1 stack");
			
	//calculates pooled standard deviation of baseline frames (1 to peak slice-2)
	baseline_vars = newArray(); //creates blank array for variances from baseline frames
	for (i=1; i<=baseline_end; i+=1) {
		setSlice(i);
		frame_stdev = getValue("StdDev");
		frame_var = pow(frame_stdev, 2);
		baseline_vars = Array.concat(baseline_vars, frame_var);
	}
	setSlice(peak_slice);
	
	sum_vars = 0; //creates an empty variable for sum of variances from baseline frames
	for (i=0; i<lengthOf(baseline_vars); i+=1) {
		sum_vars = sum_vars + baseline_vars[i];
	}
	
	mean_vars = sum_vars / lengthOf(baseline_vars);
	pooled_stdev = sqrt(mean_vars);	
	
	imageCalculator("Multiply create 32-bit", "red_mask_copy", green_deltas[m] + "_mean"); //creates new mask including overlap between red and green masks
	rename(green_deltas[m] + "_masked");

	thresh = 2 * pooled_stdev;
	setThreshold(thresh, 99);
	run("Set Measurements...", "area mean redirect=None decimal=4");
	run("Analyze Particles...", "size=0-Infinity show=[Bare Outlines] display clear include add slice");
	
	roi_count = roiManager("count");
	if (roi_count == 0) {
		print("NO MASKED GREEN AREA DETECTED ABOVE 2 SD");
	}
	roi_array = newArray();
	for (i=0; i<roi_count; i+=1) {
		roi_array = Array.concat(roi_array, i);
	}
	roiManager("Select", roi_array);
	roiManager("combine");
	run("Create Mask");
	rename(green_deltas[m] + "_masked_thresh_mask");
	run("Divide...", "value=255");
	setMinAndMax(0, 1);
	close("Drawing of " + green_deltas[m] + "_masked");
	
	imageCalculator("Multiply create 32-bit", green_deltas[m] + "_mean", green_deltas[m] + "_masked_thresh_mask"); //outputs masked data for presentation
	rename(green_deltas[m] + "_masked_data");
	setMinAndMax(0, 5);
	
	//print("\\Clear");
	selectWindow(green_deltas[m] + "_masked_thresh_mask");
	setThreshold(1, 1);
	run("Set Measurements...", "area mean redirect=None decimal=4");
	run("Analyze Particles...", "size=0-Infinity show=[Bare Outlines] display clear include add slice");
	
	if (nResults == 0) {
		overlap_check = 0;
	} else {
		overlap_check = getResult("Area", 0);
	}
	
	roi_count = roiManager("count");
	roi_array = newArray();
	for (i=0; i<roi_count; i+=1) {
		roi_array = Array.concat(roi_array, i);
	}
	roiManager("Select", roi_array);
	roiManager("combine");
	run("Clear Results");
	run("Set Measurements...", "area mean standard min redirect=[" + green_deltas[m] + "_mean] decimal=4");
	run("Measure");
	close("Drawing of " + green_deltas[m] + "_masked_thresh_mask");
	close(green_deltas[m] + "_masked_thresh_mask");
	close(green_deltas[m] + "_masked");
	
	if (noise_opt == false) {
		close(green_deltas[m] + "_mask_overlap");
	}
		
	total_area = getResult("Area", 0);
	mean_value = getResult("Mean", 0);
	max_value = getResult("Max", 0);
	
	selectWindow("red_mask_copy");
	setThreshold(1, 1);
	run("Analyze Particles...", "size=0-Infinity show=[Bare Outlines] display clear include add slice");
	
	roi_count = roiManager("count");
	roi_array = newArray();
	for (i=0; i<roi_count; i+=1) {
		roi_array = Array.concat(roi_array, i);
	}
	roiManager("Select", roi_array);
	roiManager("combine");
	run("Clear Results");
	run("Set Measurements...", "area mean standard min redirect=[" + green_deltas[m] + "_mean] decimal=4");
	run("Measure");
	close("Drawing of " + "red_mask_copy");
	if (noise_opt == false) {
		close (green_deltas[m] + "_mean");
	}
	
	pixel_stdev = getResult("StdDev", 0);
	pixel_mean = getResult("Mean", 0);
	pixel_cv = pixel_stdev / pixel_mean * 100;
	
	//print("Pooled stdev:\t" + pooled_stdev);
	
	if (overlap_check == 0) {
		print("NO OVERLAP");
	}
	print("Overlap Area (µm2):\t" + total_area);
	areas = Array.concat(areas, total_area);
	print("Mean Pixel Value (dF/F):\t" + mean_value);
	means = Array.concat(means, mean_value);
	print("Max Pixel Value (dF/F):\t" + max_value);
	maxs = Array.concat(maxs, max_value);
	print("Pixel Coefficient of Variation (%):\t" + pixel_cv);
	print("Mean Pixel Value Across Dendrite (dF/F):\t" + pixel_mean);
	print("\n");
	
	if (noise_opt == true) {
		selectWindow(green_deltas[m] + "_mean");
		setSlice(peak_slices[0]+2);
		roiManager("Select", roi_array);
		roiManager("combine");
		run("Clear Results");
		run("Set Measurements...", "area mean min redirect=[" + green_deltas[m] + "_mean] decimal=4");
		run("Measure");
		total_area = getResult("Area", 0);
		mean_value = getResult("Mean", 0);
		max_value = getResult("Max", 0);
		print("\nNoise Values (Pre-stimulation):");
		print("Overlap Area (µm):\t" + total_area);
		print("Mean Pixel Value (dF/F):\t" + mean_value);
		print("Max Pixel Value (dF/F):\t" + max_value);
		imageCalculator("Multiply create 32-bit", green_deltas[m] + "_mean", green_deltas[m] + "_mask_overlap"); //outputs masked data for presentation
		rename(green_deltas[m] + "_masked_noise");
		setMinAndMax(0, 5);
		close (green_deltas[m] + "_mean");
		close(green_deltas[m] + "_mask_overlap");
	}
	
	//selectWindow("masked_data");
	//setThreshold(3*pooled_stdev, 99);
	run("Set Measurements...", "area mean centroid redirect=None decimal=4");
}

if (multi_opt == true) {
	av_area = 0; av_mean = 0; av_max = 0;
	for (i=0; i<green_windows; i+=1) {
		av_area = av_area + areas[i];
		av_mean = av_mean + means[i];
		av_max = av_max + maxs[i];
	}
	av_area = av_area / areas.length;
	av_mean = av_mean / means.length;
	av_max = av_max / maxs.length;
	print("Average of x" + areas.length + " sweeps");
	print("Overlap Area (µm2):\t" + av_area);
	print("Mean Pixel Value (dF/F):\t" + av_mean);
	print("Max Pixel Value (dF/F):\t" + av_max);
}

close("red_mask_copy");
print("\nALL DONE! :)");