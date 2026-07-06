//AY edit 01-19-26

print("\\Clear");
roiManager("reset");
baseline_start = 1;
baseline_end = 10;
nStdevs = 3;
size_thresh = 0.05;
abs_thresh = 0.5;

going = "pos";

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
date = "" + year + "-" + month+1 + "-" + dayOfMonth;
open_windows = getList("image.titles");
mask_windows = newArray(); dFF_windows_all = newArray();
for (i=0; i<open_windows.length; i+=1) {
	if (indexOf(open_windows[i], "_Mask") != -1) {
		mask_windows = Array.concat(mask_windows, open_windows[i]);
	}
	if (indexOf(open_windows[i], "dFoverF") != -1) {
		dFF_windows_all = Array.concat(dFF_windows_all, open_windows[i]);
	}
}
if (dFF_windows_all.length == 0) {
	exit("Requires dF/F0 Window");
}
if (mask_windows.length == 0) {
	exit("Requires Mask Window");
}

if (dFF_windows_all.length != 0) {
	dFF_windows_all = Array.concat(dFF_windows_all, "Exclude");
}

thresh_modes = newArray("Absolute", "nStdDevs");
dFF_windows = newArray();
Dialog.create("GFlamp Hotspot Analysis");
Dialog.addChoice("Dendrite mask:", mask_windows, mask_windows[0]);
for (i=0; i<dFF_windows_all.length - 1; i+=1) {
	Dialog.addChoice("Analyze dFoverF:", dFF_windows_all, dFF_windows_all[i]);
}
Dialog.addChoice("Threshold Mode:", thresh_modes, thresh_modes[1]);
Dialog.addCheckbox("Save data", true);
Dialog.show();

mask_window = Dialog.getChoice();
for (i=0; i<dFF_windows_all.length - 1; i+=1) {
	dFF_windows = Array.concat(dFF_windows, Dialog.getChoice());
}
//Array.print(dFF_windows);
thresh_mode = Dialog.getChoice();
save_opt = Dialog.getCheckbox();

if (save_opt == true) {
	save_dir = getDir("Select Save Directory");
}

if (thresh_mode == "Absolute") {
	Dialog.create("Absolute Threshold");
	Dialog.addNumber("Threshold:", abs_thresh);
	Dialog.show();
	thresh = Dialog.getNumber();
}

selectWindow(mask_window); //converts mask window to binary
run("Select None");
if (getValue("Max") != 1) {
	run("Divide...", "value=" + getValue("Max"));
}
setThreshold(1,1);
run("Create Selection");
roiManager("add");
dend_area = getValue("Area");
run("Select None");
setMinAndMax(0, 1);

info = getImageInfo(); //finds scale factor from original stack
res_index = indexOf(info, "Resolution");
info = substring(info, res_index, res_index + 17);
scale_factor = replace(info, "Resolution: ", "");
scale_factor = parseFloat(scale_factor);

if (save_opt == true) {
	
}

for (i=0; i<dFF_windows.length; i+=1) {
	print(dFF_windows[i]);
	selectWindow(dFF_windows[i]);
	run("Select None");
	if (going == "neg") {
		run("Multiply...", "value=-1.0000 stack");
	}
	baseline_vars = newArray(); //calculate pooled standard deviation of baseline frames
	for (j=baseline_start; j<=baseline_end; j+=1) {
		setSlice(j);
		run("Select None");
		frame_stdev = getValue("StdDev");
		frame_var = pow(frame_stdev, 2);
		baseline_vars = Array.concat(baseline_vars, frame_var);
	}
	sum_vars = 0; //creates an empty variable for sum of variances from baseline frames
	for (j=0; j<baseline_vars.length; j+=1) {
		sum_vars = sum_vars + baseline_vars[j];
	}
	mean_vars = sum_vars / lengthOf(baseline_vars);
	pooled_stdev = sqrt(mean_vars);
	print("Baseline StdDev:\t" + pooled_stdev);
	
	if (thresh_mode == "nStdDevs") {
		thresh = nStdevs * pooled_stdev;
	}
	
	imageCalculator("Multiply create 32-bit stack", dFF_windows[i], mask_window);
	setMinAndMax(0, 5);
	rename(replace(dFF_windows[i], ".tif", "") + "_Masked");
	active_window_masked = getTitle();
	frame_vals = newArray();
	for (j=1; j<nSlices; j+=1) {
		setSlice(j);
		//run("Select None");
		roiManager("select", roiManager("count") - 1);
		frame_vals = Array.concat(frame_vals, getValue("Mean"));
	}
	frame_vals_ranked = Array.reverse(Array.rankPositions(frame_vals));
	peak_frame = frame_vals_ranked[0] + 1;
	setSlice(peak_frame);
	run("Plot Z-axis Profile");
	zprof = getTitle();
	waitForUser("Peak frame: " + peak_frame + "??");
	
	Dialog.create("Confirm Peak Frame");
	Dialog.addNumber("Peak frame:", peak_frame);
	Dialog.show();
	
	peak_frame = Dialog.getNumber();
	close(zprof);
	
	selectWindow(active_window_masked);
	setSlice(peak_frame);
	setThreshold(thresh, 99);
	print("Threshold:\t" + thresh);
	print("Peak frame:\t" + peak_frame);
	print("Dendrite area (um2):\t" + dend_area);	
	run("Set Measurements...", "area mean min redirect=None decimal=4");
	roiManager("reset");
	run("Select None");
	run("Analyze Particles...", "size=" + size_thresh + "-Infinity display clear include add slice");
	
	if (nResults == 0) {
		print("No hotspots detected");
	} else {
		thresh_areas = newArray(); thresh_means = newArray(); thresh_mins = newArray(); thresh_maxs = newArray();
		for (j=0; j<nResults; j+=1) {
			thresh_areas = Array.concat(thresh_areas, getResult("Area", j));
			thresh_means = Array.concat(thresh_means, getResult("Mean", j));
			thresh_mins = Array.concat(thresh_mins, getResult("Min", j));
			thresh_maxs = Array.concat(thresh_maxs, getResult("Max", j));
		}
		total_area = 0; area_mean = 0;
		for (j=0; j<thresh_areas.length; j+=1) {
			total_area = total_area + thresh_areas[j];
		}
		area_mean = total_area / thresh_areas.length;
		hotspot_mean = 0;
		for (j=0; j<thresh_means.length; j+=1) {
			hotspot_mean = hotspot_mean + thresh_means[j];
		}
		hotspot_mean = hotspot_mean / thresh_means.length;
		hotspot_maxs = Array.reverse(Array.rankPositions(thresh_maxs));
		hotspot_max = thresh_maxs[(hotspot_maxs[0])];
	
		if (going == "neg") {
			hotspot_mean = hotspot_mean * -1;
			hotspot_max = hotspot_max * -1;
		}
		
		print("Number of hotspots (n):\t" + thresh_areas.length);
		print("Hotspot density (/um2):\t" + thresh_areas.length / dend_area);
		print("Total area >" + nStdevs + "of baseline:\t" + total_area);
		print("Average hotspot area (um2):\t" + area_mean);
		print("Hotspot mean dF/F:\t" + hotspot_mean);
		print("Hotspot max dF/F:\t" + hotspot_max);
		
		if (save_opt == true) {
			selectWindow("Log");
			saveAs("Text", save_dir + "/" + "GFlamp Analysis_" + date);
		}
	}
	
	selectWindow(active_window_masked);
	setMinAndMax(0,5);
}
selectWindow("Log");
