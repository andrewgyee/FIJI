//AY edit 01-19-26

print("\\Clear");
baseline_start = 1;
baseline_end = 10;
nStdevs = 3;

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


dFF_windows = newArray();
Dialog.create("BAP Analysis");
Dialog.addNumber("Peak dFoverF frame:", 12);
Dialog.addChoice("Dendrite mask:", mask_windows, mask_windows[0]);
for (i=0; i<dFF_windows_all.length - 1; i+=1) {
	Dialog.addChoice("Analyze dFoverF:", dFF_windows_all, dFF_windows_all[i]);
}
Dialog.addCheckbox("Save data", true);
Dialog.show();

peak_frame = Dialog.getNumber();
mask_window = Dialog.getChoice();
for (i=0; i<dFF_windows_all.length - 1; i+=1) {
	dFF_windows = Array.concat(dFF_windows, Dialog.getChoice());
}
//Array.print(dFF_windows);
save_opt = Dialog.getCheckbox();

if (dFF_windows.length > 1) {
	for (i=0; i<dFF_windows.length; i+=1) {
		if (indexOf(dFF_windows[i], "Baseline") != -1 || indexOf(dFF_windows[i], "baseline") != -1 || indexOf(dFF_windows[i], "00uA") != -1) {
			baseline_index = i;
		} else {
			baseline_index = 0;
		}
	}
	Dialog.create("Calculate Differences");
	Dialog.addChoice("Baseline", dFF_windows, dFF_windows[baseline_index]);
	Dialog.addCheckbox("Calculate Differences", true);
	Dialog.show();
	
	baseline_dFF_window = Dialog.getChoice();
	dif_opt = Dialog.getCheckbox();
}

selectWindow(mask_window); //converts mask window to binary
run("Select None");
if (getValue("Max") != 1) {
	run("Divide...", "value=" + getValue("Max"));
}
setMinAndMax(0, 1);
setThreshold(1, 1);
run("Create Selection");
dend_area = getValue("Area");
print("Dendrite area (um2):\t" + dend_area);

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
	baseline_vars = newArray(); //calculate pooled standard deviation of baseline frames
	for (j=baseline_start; j<=baseline_end; j+=1) {
		setSlice(j);
		run("Select None");
		frame_stdev = getValue("StdDev");
		frame_var = pow(frame_stdev, 2);
		baseline_vars = Array.concat(baseline_vars, frame_var);
	}
	setSlice(peak_frame);
	
	sum_vars = 0; //creates an empty variable for sum of variances from baseline frames
	for (j=0; j<baseline_vars.length; j+=1) {
		sum_vars = sum_vars + baseline_vars[j];
	}
	mean_vars = sum_vars / lengthOf(baseline_vars);
	pooled_stdev = sqrt(mean_vars);
	print("Baseline StdDev:\t" + pooled_stdev);
	
	imageCalculator("Multiply create 32-bit", dFF_windows[i], mask_window);
	setThreshold(nStdevs * pooled_stdev, 99);
	run("Create Selection");
	dFF_mean = getValue("Mean");
	dFF_max = getValue("Max");
	dFF_area = getValue("Area");
	print("Thresh area (um2):\t" + dFF_area);
	print("Mean dF/F0:\t" + dFF_mean);
	print("Max dF/F0:\t" + dFF_max);
	
	close("Result of " + dFF_windows[i]);
}

if (dif_opt == true) {
	
	for (k=0; k<dFF_windows.length; k+=1) {
		
		if (dFF_windows[k] != baseline_dFF_window) {
			selectWindow(dFF_windows[k]);
			imageCalculator("Subtract create 32-bit stack", dFF_windows[k], baseline_dFF_window);
			rename(replace(dFF_windows[k], ".tif", "") + "_BASELINE_SUBTRACTED");
			run("AY_White-Red");
			
			run("Multiply...", "value=-1 stack");
			setMinAndMax(0, 2);
			setSlice(peak_frame);
			subtracted_dFF = getTitle();
			
			selectWindow(mask_window);
			roiManager("reset");
			setThreshold(1,1);
			run("Analyze Particles...", "include add");
			roi_count = roiManager("count");
			roi_list = newArray();
			for (i=0; i<roi_count; i+=1) {
				roi_list = Array.concat(roi_list, i);
			}
			
			selectWindow(subtracted_dFF);
			setSlice(peak_frame);
			roiManager("select", roi_list);
			run("Make Inverse");
			frame_stdev = getValue("StdDev");
			run("Select None");
			
			selectWindow(subtracted_dFF);
			setSlice(peak_frame);
			imageCalculator("Multiply create 32-bit", subtracted_dFF, mask_window);
			rename(replace(dFF_windows[k], ".tif", "") + "_BASELINE_SUBTRACTED_MASKED");
			masked_subtracted_dFF = getTitle();
			setMinAndMax(0, 2);
			setThreshold(nStdevs * frame_stdev, 99);
			run("Set Measurements...", "area mean min redirect=None decimal=4");
			roiManager("reset");
			run("Analyze Particles...", "size=0.03-Infinity clear include add slice");
			//roi_count = roiManager("count");
			//roi_list = newArray();
			//for (i=0; i<roi_count; i+=1) {
			//	roi_list = Array.concat(roi_list, i);
			//}
			//roiManager("select", roi_list);
			//roiManager("combine");
			//run("Create Mask");
			//run("Invert LUT");
			
			diff_areas = newArray(); diff_means = newArray(); diff_mins = newArray(); diff_maxs = newArray();
			for (i=0; i<nResults; i+=1) {
				diff_areas = Array.concat(diff_areas, getResult("Area", i));
				diff_means = Array.concat(diff_means, -1 * getResult("Mean", i));
				diff_mins = Array.concat(diff_mins, -1 * getResult("Min", i));
				diff_maxs = Array.concat(diff_maxs, -1 * getResult("Max", i));
			}
			
			
			
			total_area = 0;
			for (i=0; i<diff_areas.length; i+=1) {
				total_area = total_area + diff_areas[i];
			}
			
			baseline_means = newArray();
			selectWindow(baseline_dFF_window);
			setSlice(peak_frame);
			for (i=0; i<roiManager("count"); i+=1) {
				roiManager("select", i);
				baseline_means = Array.concat(baseline_means, getValue("Mean"));
			}
			
			normalized_means = newArray();
			for (i=0; i<diff_means.length; i+=1) {
				normalized_means = Array.concat(normalized_means, diff_means[i] / baseline_means[i] * 100);
			}
			mean_normalized_means = 0; //mean weighted by area
			for (i=0; i<normalized_means.length; i+=1) {
				mean_normalized_means = mean_normalized_means + normalized_means[i] * (diff_areas[i] / total_area);
			}
			
			print(masked_subtracted_dFF);
			print("Threshold:\t" + nStdevs * frame_stdev);
			print("Number of hotspots (n):\t" + diff_areas.length);
			print("Hotspot density (/um2):\t" + diff_areas.length / dend_area);
			print("Total hotspot area (um2):\t" + total_area);
			print("Mean hotspot difference (% baseline, weighted by area):\t" + mean_normalized_means);
			print("Individual hotspots");
			print("Hotspot#\tArea(um2):\tMean(%):");
			for (i=0; i<diff_areas.length; i+=1) {
				print(i+1 + "\t" + diff_areas[i] + "\t" + normalized_means[i]);
			}			
		}
	}	
}
selectWindow(subtracted_dFF);
selectWindow("Log");