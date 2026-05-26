//AY 05-05-26
//05-05-26: AY groups and averages dFF windows 

print("\\Clear");
run("Clear Results");
run("Set Measurements...", "area mean min redirect=None decimal=4");
run("Select None");

single_check = true; multi_check = false;
open_windows = getList("image.titles");
if (open_windows.length == 0) {
	exit("Open some windows, yo");
}
open_stacks = newArray();
if (open_windows.length >= 1) {
	for (i=0; i<open_windows.length; i+=1) {
		selectWindow(open_windows[i]);
		//print(open_windows[i]);
		//print(nSlices);
		if (nSlices > 1) {
			open_stacks = Array.concat(open_stacks, open_windows[i]);
		}
	}
	selectWindow(open_windows[0]);
}
if (open_stacks.length == 0) {
	exit("Open some stacks, yo");
}

if (open_stacks.length > 1) {
	Dialog.create("Delta F/F");
	Dialog.addCheckbox("Run Single", false);
	Dialog.addCheckbox("Run ALL", true);
	Dialog.show();
	
	single_check = Dialog.getCheckbox();
	multi_check = Dialog.getCheckbox();
}

if (multi_check == true) {
	stack_groups = newArray();
	for (i=0; i<open_stacks.length; i+=1) {
		if (indexOf(open_stacks[i], "_01.tif") != -1) {
			stack_groups = Array.concat(stack_groups, open_stacks[i]);
		}
	}
}

//if (single_check == true) {
//	average_ints = newArray(); //automatically finds slice with maximum average pixel intensity by indexing stack (to find baseline_end)
//	for (i=1; i<=nSlices; i+=1) {
//		setSlice(i);
//		average_int = getValue("Mean");
//		average_ints = Array.concat(average_ints, average_int);
//	}
//	peak_slices = Array.reverse(Array.rankPositions(average_ints));
//	setSlice(peak_slices[0] + 1);
	//note that peak_slices[0] refers to baseline_end slice because slices: 1...n whereas index: 0...n [therefore this index refers to (max slice -1)]
	//print("\\Clear");
	//print(pre_peak_slice);
	
	//checks if the maximum pixel intensity is more than 5% larger than baseline
//	baseline_sum = 0;
//	for (i=0; i<peak_slices[0]; i+=1) {
//		baseline_sum = baseline_sum + average_ints[i];
//	}
	//print(baseline_sum);
//	av_baseline = baseline_sum / peak_slices[0];
//	diff = (average_ints[(peak_slices[0])] - av_baseline) / av_baseline;
	//print(diff);
	
//	if (diff > 0.05) {
//		auto_baseline_end = peak_slices[0] - 1;
//	} else {
//		auto_baseline_end = "";
//	}
//}

//opens GUI for user inputs
Dialog.create("Delta F/F");
Dialog.addNumber("Baseline Start Frame", 1);
//Dialog.addNumber("Baseline End Frame", auto_baseline_end);
Dialog.addNumber("Baseline End Frame", 10);
Dialog.addCheckbox("Filter?", true);
Dialog.addCheckbox("Apply LUT?", true);
if (multi_check == true) {
	Dialog.addCheckbox("Average dF/F Stacks", true);
}
Dialog.addCheckbox("Save Output Stack", false); 
Dialog.show();

baseline_start = Dialog.getNumber();
baseline_end = Dialog.getNumber();
filter_opt = Dialog.getCheckbox();
lut_opt = Dialog.getCheckbox();
if (multi_check == true) {
	average_opt = Dialog.getCheckbox();
}
save_opt = Dialog.getCheckbox();

if (save_opt == true) {
	dir = getDirectory("Choose Save Directory");
}

if (multi_check == true) {
	for(i=0; i<open_stacks.length; i+=1) {
		selectWindow(open_stacks[i]);
		run("32-bit");
		deltaFoverF();
		run("Measure");
		close(open_stacks[i]);
	}
	if (average_opt == true) {
		open_windows = getList("image.titles");
		dFF_windows = newArray();
		for (m=0; m<open_windows.length; m+=1) {
			if (indexOf(open_windows[m], "_dFoverF") != -1) {
				dFF_windows = Array.concat(dFF_windows, open_windows[m]);
			}
		}
		//Array.print(dFF_windows);
		if (stack_groups.length > 1) {
			for (j=0; j<stack_groups.length; j+=1) {
				grouped_dFF_windows = newArray();
				for (k=0; k<dFF_windows.length; k+=1) {
					if (indexOf(dFF_windows[k], substring(stack_groups[j], 0, stack_groups[j].length - 7)) != -1) {
						grouped_dFF_windows = Array.concat(grouped_dFF_windows, dFF_windows[k]);
					}
				}
				average_dFF(grouped_dFF_windows);
			}
		} else {
			average_dFF(dFF_windows);
		}
	}
}

if (single_check == true) {
	selectWindow(open_stacks[0]);
	run("32-bit");
	deltaFoverF();
}

function deltaFoverF() {
	run("Select None");
	if (filter_opt == true) {
		run("Median...", "radius=3 stack");
	}
	if (lut_opt == true) {
		run("AY_CPF_Test");
	}

//returns original name of image
	original_name = getTitle();
	print(original_name);
	rename("raw");

//generates baseline (F0) image
	run("Select None");
	run("Z Project...", "start=baseline_start stop=baseline_end projection=[Average Intensity]");
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

	if (save_opt == true) {
		saveAs("tiff", dir + title);
	}
}

function average_dFF(list) {
	alphabet = newArray("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");
	alphabet_lower = newArray("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z");	
	//open_windows = getList("image.titles");
	//dFF_windows = newArray();
	//for (i=0; i<open_windows.length; i+=1) {
	//	if (indexOf(open_windows[i], "dFoverF") != -1) {
	//		dFF_windows = Array.concat(dFF_windows, open_windows[i]);
	//	}
	//}
	if (list.length == 0) {
		exit("Requires dF/F0 window");
	}
	selectWindow(list[0]);
	parent_name = substring(list[0], 0, indexOf(list[0], "_dFoverF") - 3);
	info = getImageInfo(); //finds scale factor from original stack
	res_index = indexOf(info, "Resolution");
	info = substring(info, res_index, res_index + 17);
	scale_factor = replace(info, "Resolution: ", "");
	scale_factor = parseFloat(scale_factor);
		
	Dialog.create("Average Movies"); //automatically selects movies from list of open windows
	for (i=1; i<=list.length; i+=1) {
		Dialog.addChoice("Movie #" + i + ":", list, list[i-1]);
	}
	Dialog.show();
				
	movie_list = newArray(); //creates list of variable names to assign choices from previous dialog
	for (i=0; i<list.length; i+=1) {
		movie_name = "Movie_" + i+1;
		movie_list = Array.concat(movie_list, movie_name);
	}
	//Array.print(movie_list);
				
	for (i=0; i<list.length; i+=1) { //assigns dialog choices to list of variable names
		movie_list[i] = Dialog.getChoice();
	}
				
	alphs = newArray(); //creates array of letters for parser expression
	
	for (i=0; i<list.length; i+=1) {
		alph = alphabet[i];
		alphs = Array.concat(alphs, alph);
	}
				
	expression = ""; //compiles parser expression
	for (i=0; i<list.length; i+=1) {
		expression = expression + alphs[i] + "+";
	}
	expression = substring(expression, 0, lengthOf(expression)-1);
	expression = "(" + expression + ")/" + list.length;
	//print(expression);
			
	alphs_lower = newArray(); //cos stupid ImageJ uses lowercase for the second part of this java macro...
	
	for (i=0; i<list.length; i+=1) {
		alph_lower = alphabet_lower[i];
		alphs_lower = Array.concat(alphs_lower, alph_lower);
	}
				
	average_list = ""; //compiles parser list of movies to average i.e. A=movie_name
	for (i=0; i<list.length; i+=1) {
		average_list = average_list + alphs_lower[i] + "=" + replace(movie_list[i], ".tif", "") + " ";
	}
	average_list = substring(average_list, 0, lengthOf(average_list)-1);
	//print(average_list);
	//waitForUser;
	
	run("Image Expression Parser (Macro)", "expression=" + expression + " " + average_list);
				
	selectWindow("Parsed with " + expression);
	setSlice(12);
	rename(parent_name + "_dFoverF_Average");
	run("Hyperstack to Stack");
	run("Set Scale...", "distance=" + scale_factor + " known=1 unit=µm");
	//run("16-bit");
	//saveAs("Tiff", save_dir + parent_name + "_Average")
	setMinAndMax(0, 2);
	run("AY_CPF_Test");
	title = getTitle();
	if (save_opt == true) {
		saveAs("tiff", dir + title);
	}
}