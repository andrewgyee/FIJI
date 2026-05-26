//AY 11-07-25
//Updated calibration factors 01-27-21

print("\\Clear");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
date = "" + year + "-" + month+1 + "-" + dayOfMonth;
print("AY_ImageJ_ContourPlot.ijm " + date);

run("Clear Results");
mask_opt = false;
multi_opt = false;

open_windows = getList("image.titles");
dFF_windows = newArray(); mask_windows = newArray();
if (open_windows.length > 1) {
	for (i=0; i<open_windows.length; i+=1) {
		if (indexOf(open_windows[i], "dFoverF") != -1) {
			dFF_windows = Array.concat(dFF_windows, open_windows[i]);
		}
		if (indexOf(open_windows[i], "Mask") != -1) {
			mask_windows = Array.concat(mask_windows, open_windows[i]);
		}
	}
}
if (dFF_windows.length == 0) {
	exit("Open a dFoverF window, dummy!");
}

Dialog.create("Contour Map");
Dialog.addNumber("Peak Frame:", 12);
Dialog.addMessage("[DA] = dF/F:");
Dialog.addNumber("10 nM:", 0.0854);
Dialog.addNumber("100 nM:", 0.288);
Dialog.addNumber("1 µM:", 0.8899);
Dialog.addNumber("10 µM:", 2.2014);
Dialog.addNumber("30 µM:", 2.9943);
Dialog.addNumber("100 µM:", 3.7969);
Dialog.addMessage("\n");
Dialog.addNumber("Gaussian Filter, sigma:", 2);
Dialog.addNumber("Median Filter, radius:", 2);
Dialog.addNumber("Minimum Area for Contour Level (µm^2)", 0);
Dialog.addMessage("\n");
Dialog.addCheckbox("Generate Calibration Bar", false);
if (mask_windows.length != 0) {
	Dialog.addCheckbox("Mask by Dendrite", true);
}
Dialog.addCheckbox("Three Levels", false);
if (dFF_windows.length > 1) {
	Dialog.addCheckbox("Multiple dF/F windows", true);
}
Dialog.show();

peak_frame = Dialog.getNumber();
dFF_10nM = Dialog.getNumber();
dFF_100nM = Dialog.getNumber();
dFF_1uM = Dialog.getNumber();
dFF_10uM = Dialog.getNumber();
dFF_30uM = Dialog.getNumber();
dFF_100uM = Dialog.getNumber();
gauss_filter = Dialog.getNumber();
med_filter = Dialog.getNumber();
min_area = Dialog.getNumber();
cal_bar_opt = Dialog.getCheckbox();
if (mask_windows.length != 0) {
	mask_opt = Dialog.getCheckbox();
}
three_opt = Dialog.getCheckbox();
if (dFF_windows.length > 1) {
	multi_opt = Dialog.getCheckbox();
}

contour_levels = newArray(dFF_10nM, dFF_100nM, dFF_1uM, dFF_10uM, dFF_30uM, dFF_100uM);
contour_da = newArray(1, 2, 3, 4, 5, 6);
//contour_da = newArray(0.01, 0.1, 1, 10, 30, 100);
contour_da_labels = newArray("10nM", "100nM", "1uM", "10uM", "30uM", "100uM");
areas_10nM = newArray(); areas_100nM = newArray(); areas_1uM = newArray(); areas_10uM = newArray(); areas_30uM = newArray(); areas_100uM = newArray();

//Array.print(contour_levels);

if (mask_opt == true) {
	Dialog.create("Mask Window");
	Dialog.addChoice("Mask", mask_windows, mask_windows[0]);
	Dialog.show();	
	mask_window = Dialog.getChoice();
	
	selectWindow(mask_window);
	run("Select None");
	mask_max = getValue("Max");
	run("Divide...", "value=" + mask_max);
	setMinAndMax(0, 1);
	setThreshold(1, 1);
	run("Create Selection");
	dendrite_area = getValue("Area"); //total dendritic area
	run("Select None");
}

if (multi_opt == true) {
	dFF_ids = newArray();
	for (i=0; i<dFF_windows.length; i+=1) {
		dFF_ids = Array.concat(dFF_ids, substring(dFF_windows[i], indexOf(dFF_windows[i], "_dFoverF") - 2, indexOf(dFF_windows[i], "_dFoverF")));
	}
}
//Array.print(dFF_ids);

save_dir = getDir("Select Save Directory");
if (indexOf(save_dir, "/Contour/") == -1) {
	File.makeDirectory(save_dir + "/Contour/");
	save_dir = save_dir + "Contour/";
	if (indexOf(save_dir, date) == -1) {
		File.makeDirectory(save_dir + date);
		save_dir = save_dir + date;
	}
} else {
	if (indexOf(save_dir, "/Contour/") != -1) {
		File.makeDirectory(save_dir + date);
		save_dir = save_dir + date + "/";
	}
}
print(save_dir);

if (multi_opt == true) {
	for (m=0; m<dFF_windows.length; m+=1) {
		sub_dir = "" + "SW" + dFF_ids[m];
		if (indexOf(save_dir, sub_dir) == -1) {
			File.makeDirectory(save_dir + "/" + sub_dir);
			output_dir = save_dir + "/" + sub_dir + "/";
			//print(output_dir);
		}
		selectWindow(dFF_windows[m]);
		contourplot();
		areas_10nM = Array.concat(areas_10nM, getResult("10nM", 0));
		areas_100nM = Array.concat(areas_100nM, getResult("100nM", 0));
		areas_1uM = Array.concat(areas_1uM, getResult("1uM", 0));
		areas_10uM = Array.concat(areas_10uM, getResult("10uM", 0));
		areas_30uM = Array.concat(areas_30uM, getResult("30uM", 0));
		areas_100uM = Array.concat(areas_100uM, getResult("100uM", 0));
		print("\n");
	}
	
	av_area_10nM = 0; av_area_100nM = 0; av_area_1uM = 0; av_area_10uM = 0; av_area_30uM = 0; av_area_100uM = 0;
	for (i=0; i<areas_10nM.length; i+=1) {
		av_area_10nM = av_area_10nM + areas_10nM[i];
		av_area_100nM = av_area_100nM + areas_100nM[i];
		av_area_1uM = av_area_1uM + areas_1uM[i];
		av_area_10uM = av_area_10uM + areas_10uM[i];
		av_area_30uM = av_area_30uM + areas_30uM[i];
		av_area_100uM = av_area_100uM + areas_100uM[i];
	}
	av_area_10nM = av_area_10nM / areas_10nM.length;
	av_area_100nM = av_area_100nM / areas_100nM.length;
	av_area_1uM = av_area_1uM / areas_1uM.length;
	av_area_10uM = av_area_10uM / areas_10uM.length;
	av_area_30uM = av_area_30uM / areas_30uM.length;
	av_area_100uM = av_area_100uM / areas_100uM.length;
	
	print("Average of x" + dFF_windows.length + " sweeps");
	if (three_opt == true) {
		
	} else {
		print("Area (um2) at 10nM (%):\t" + av_area_10nM + "\t" + av_area_10nM / dendrite_area * 100);
		print("Area (um2) at 100nM (%):\t" + av_area_100nM + "\t" + av_area_100nM / dendrite_area * 100);
		print("Area (um2) at 1uM (%):\t" + av_area_1uM + "\t" + av_area_1uM / dendrite_area * 100);
		print("Area (um2) at 10uM (%):\t" + av_area_10uM + "\t" + av_area_10uM / dendrite_area * 100);
		print("Area (um2) at 30uM (%):\t" + av_area_30uM + "\t" + av_area_30uM / dendrite_area * 100);
		print("Area (um2) at 100uM (%):\t" + av_area_100uM + "\t" + av_area_100uM / dendrite_area * 100);
	}
	
	selectWindow("Log");
	saveAs("Text", save_dir + "/" + "Contour Analysis Output_" + date);
} else {
	File.makeDirectory(save_dir + "/Output");
	output_dir = save_dir + "/Output/";
	selectWindow(dFF_windows[0]);
	contourplot();
	selectWindow("Log");
	saveAs("Text", save_dir + "/" + "Contour Analysis Output_" + date);
}

function contourplot() {
	run("Duplicate...", "duplicate");
	active_window = getTitle();
	name = replace(active_window, ".tif", ""); name = replace(name, "dFoverF-1", "dFoverF");
	print(name);
	run("Gaussian Blur...", "sigma=" + gauss_filter + " stack");
	run("Median...", "radius="+ med_filter + " stack");
	
	for (i=0; i<contour_levels.length; i+=1) {
		selectWindow(active_window);
		run("Select None");
		setSlice(peak_frame);
		roiManager("reset");
		run("Set Measurements...", "area redirect=None decimal=4");
		setThreshold(contour_levels[i], 99);
		run("Create Mask");
		run("Divide...", "value=255");
		run("16-bit");
		run("Multiply...", "value=" + contour_da[i]);
		//rename(active_window + "_" + contour_da_labels[i]);
		//print(output_dir + replace(active_window, ".tif", "") + "_" + IJ.pad(i + 1, 2) + "_" + contour_da_labels[i]);
		saveAs("tif", output_dir + "/" + name + "_" + IJ.pad(i + 1, 2) + "_" + contour_da_labels[i]);
		temp_mask = getTitle();
		close(temp_mask);
	}
	close(active_window);
	
	run("Image Sequence...", "dir=[" + output_dir + "] sort");
	contour_stack = getTitle();
	if (three_opt == true) {
		run("Make Substack...", "slices=2,3,4");
		close(contour_stack);
	}
	contour_stack = getTitle();
	
	run("Z Project...", "projection=[Max Intensity]");
	active_contour = getTitle();
	close(contour_stack);
	
	selectWindow(active_contour);
	if (three_opt == true) {
		run("AY_CPF_Test");
		setMinAndMax(1, 3);
	} else {
		run("AY_CPF_Test");
		setMinAndMax(0, 5);
	}
	rename(name + "_ContourPlot");
	saveAs("tiff", save_dir + "/" + name + "_ContourPlot");
	active_contour = getTitle();

	if (mask_opt == true) {
		selectWindow(mask_window);
		run("Select None");		
		imageCalculator("Multiply create", active_contour, mask_window);
		
		if (three_opt == true) {
			setMinAndMax(1, 3);
		} else {
			setMinAndMax(0, 5);
		}
		rename(name + "_ContourPlot_Masked");
		for (i=0; i<contour_da.length; i+=1) {
			setThreshold(contour_da[i], contour_da[i]);
			run("Create Selection");
			if (getValue("selection.size") != 0) {
				masked_area = getValue("Area");
			} else {
				masked_area = 0;
			}
			setResult(contour_da_labels[i], 0, masked_area);
			print("Area (um2) at " + contour_da_labels[i] + ":\t" + masked_area);
		}
		selectWindow(name + "_ContourPlot_Masked");
		run("Select None");
		//run("AY_CPF_Test");
		saveAs("tif", save_dir + "/" + name + "_ContourPlot_Masked");
		//close(open_windows[(green_index)] + "_ContourPlot");
	}
	close(active_contour);
}

if (cal_bar_opt == true) {
	cal_bar_width = 50;
	newImage("Calibration Bar", "16-bit", cal_bar_width, cal_bar_width * (lengthOf(contour_da) + 1), 1);
	for (i=0; i<=lengthOf(contour_da); i+=1) {
		makeRectangle(0, cal_bar_width * (lengthOf(contour_da) - i), cal_bar_width, cal_bar_width);
		run("Set...", "value=" + i);
		}
	run("AY_CPF_Test");
	setMinAndMax(0, 5);
	run("Select None");
}