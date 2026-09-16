//Test for pedestal to eliminate 'math noise'
//Increase pedestal values to see effect on F0, noise and maximum dF/F0...

print("\\Clear");

Dialog.create("Baseline Params");
Dialog.addNumber("baseline start:", 1);
Dialog.addNumber("baseline end:", 10);
Dialog.show()

baseline_start = Dialog.getNumber();
baseline_end = Dialog.getNumber();

filt_opt = true;
lut_opt = true;

active_window = getTitle();

cont_check = true;
while(cont_check == true) {
	Dialog.create("Pedestal Params");
	Dialog.addNumber("Pedestal", 0);
	Dialog.show();
	ped = Dialog.getNumber();
	
	print(replace(active_window, ".tif", "") + "+_Pedestal" + ped);
	selectWindow(active_window);
	run("Duplicate...", "title=" + replace(active_window, ".tif", "") + "_Copy duplicate");
	run("32-bit");
	active_copy = getTitle();
	run("Add...", "value=" + ped + " stack");
	selectWindow(active_copy);
	
	deltaFoverF(baseline_start, baseline_end, filt_opt, lut_opt);
	active_dFF = getTitle();
	selectWindow(active_dFF);
	diags = diagnostic(active_dFF, baseline_start, baseline_end);
	print("Baseline Mean (dF/F0): " + diags[0]);
	print("Baseline StdDev (dF/F0): " + diags[1]);
	print("Unconstrained Frame (e.g. 11th, dF/F0): " + diags[2] + " (" + (diags[2] / diags[1]) + " Z-scores)");
	print("Difference (Unconstrained-F0, dF/F0): " + (diags[2] - diags[0]) + " (" + (diags[2] - diags[0]) / abs(diags[0]) * 100 + "%)");
	print("Max (dF/F0): " + diags[3] + " (" + (diags[3] / diags[1]) + " Z-scores)");
	setSlice(baseline_end + 1);
	run("Plot Z-axis Profile");
	waitForUser("Have a peek");
	Dialog.create("Continue");
	Dialog.addChoice("Continue", newArray("Yes", "No"));
	Dialog.show();
	cont_opt = Dialog.getChoice();
	if (cont_opt == "Yes") {
		cont_check = true;
		close(active_copy);
		close(active_copy + "_dFoverF");
		close(active_copy + "_dFoverF-0-0");
	} else {
		cont_check = false;
	}
}

function deltaFoverF(baseline_start, baseline_end, filt_opt, lut_opt) {
	run("Select None");
	if (filt_opt == true) {
		run("Median...", "radius=3 stack");
	}
	if (lut_opt == true) {
		run("AY_CPF_Test");
	}

//returns original name of image
	original_name = getTitle();
	//print(original_name);
	rename("raw");

//generates baseline (F0) image
	run("Select None");
	run("Z Project...", "start=" + baseline_start + " stop=" + baseline_end + " projection=[Average Intensity]");
	run("Select None");
	f0 = getValue("Mean");
	print("Baseline (F0):\t" + f0);
	rename("baseline");

//subtracts baseline (F-F0)
	imageCalculator("Subtract create 32-bit stack", "raw", "baseline");
	rename("delta_F");
	selectWindow("raw");
	rename(original_name);

//divides baseline-subtracted image (F-F0) by baseline (F0)
	imageCalculator("Divide create 32-bit stack", "delta_F","baseline");
	original_name = replace(original_name, ".tif", "");
	rename(original_name + "_dFoverF");
	title = getTitle();
	setMinAndMax(0, 5);
	setSlice(baseline_end + 2);
	
	close("baseline");
	close("delta_F");
}

function diagnostic(active_dFF, baseline_start, baseline_end) {
	selectWindow(active_dFF);
	frameMeans = newArray();
	for (i=1; i<=nSlices; i+=1) {
		setSlice(i);
		run("Select None");
		frameMeans = Array.concat(frameMeans, getValue("Mean"));
	}
	//baseline_frameMeans = Array.slice(frameMeans, baseline_start - 1, baseline_end - 1);
	//Array.getStatistics(baseline_frameMeans, min, max, mean, stdDev);
	baseline_mean = 0;
	for (i=baseline_start - 1; i<baseline_end; i+=1) {
		baseline_mean = baseline_mean + frameMeans[i];
	}
	baseline_mean = baseline_mean / (baseline_end - baseline_start + 1);
	baseline_stdDev = 0;
	for (i=baseline_start - 1; i<baseline_end; i+=1) {
		baseline_stdDev = baseline_stdDev + pow((frameMeans[i] - baseline_mean), 2);
	}
	baseline_stdDev = pow(baseline_stdDev / (baseline_end - baseline_start + 1 - 1), 0.5);
	//baseline_mean = mean;
	//baseline_stdDev = stdDev;
	frameMaxIdx = Array.reverse(Array.rankPositions(frameMeans));
	frameMax = frameMeans[frameMaxIdx[0]];
	diags = newArray(baseline_mean, baseline_stdDev, frameMeans[baseline_end], frameMax);
	return diags;
}