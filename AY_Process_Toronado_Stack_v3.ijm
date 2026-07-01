//AY edit 04/28/26

print("\\Clear");
current_dir = getDir("current");
File.setDefaultDir(current_dir);

waves = newArray(); chans = newArray(); zooms = newArray();
zero_vals = true;
selin_naming_system = false;

if (isOpen("Stack")) {
	print("oh hai there's a stack ready to be processed");
	wave = ""; zoom = ""; chan = "";
	dir = getInfo("image.directory");
	info = getInfo("slice.label");
	//print(info);
	if (indexOf(info, "nm") != -1) {
		sep_index = 1; sep_find = false;
		while(sep_find == false) {
			if (substring(info, indexOf(info, "nm") - sep_index - 1, indexOf(info, "nm") - sep_index) == "_") {
				sep_find = true;
			} else {
				sep_find = false;
				sep_index = sep_index + 1;
			}
		}
		//print(sep_index);
		wave = substring(info, indexOf(info, "nm") - sep_index, indexOf(info, "nm"));
		//print(wave);
	} else {
		wave = "";
	}
	if (indexOf(info, "_Z") != -1) {
		sep_index = 1; sep_find = false;
		while(sep_find == false) {
			if (substring(info, indexOf(info, "_Z") + sep_index, indexOf(info, "_Z") + sep_index + 1) == "_") {
				sep_find = true;
			} else {
				sep_find = false;
				sep_index = sep_index + 1;
			}
		}
		//print(sep_index);
		zoom = substring(info, indexOf(info, "_Z") + 2, indexOf(info, "_Z") + sep_index);
		//print(zoom);
	} else {
		zoom = "";
	}
	if (indexOf(info, "Red") != -1) {
		chan = "RED";
	}
	if (indexOf(info, "Green") != -1) {
		chan = "GREEN";
	} else {
		chan = "";
	}
} else {
	run("Close All");
	print("okay let's find a stack to process");
	dir = getDirectory("Choose Folder of Images"); //select a directory with tif files
	dir_files = getFileList(dir);
	dir_files_tif = newArray(); tif_check = -1;
	for (i=0; i<dir_files.length; i+=1) {
		if (indexOf(dir_files[i], ".tif") != -1) {
			dir_files_tif = Array.concat(dir_files_tif, dir_files[i]);
		}
	}
	if (dir_files_tif.length == 0) {
		exit("Whoops there's no TIF files in here!");
	}
	waves = newArray(); zooms = newArray(); chans = newArray();
	if (dir_files_tif.length > 0) {
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "810") != -1) {
				waves = Array.concat(waves, "810nm");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "920") != -1) {
				waves = Array.concat(waves, "920nm");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "1020") != -1) {
				waves = Array.concat(waves, "1020nm");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "1040") != -1) {
				waves = Array.concat(waves, "1040nm");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Z2.5") != -1 || indexOf(dir_files_tif[i], "Morph") != -1 || indexOf(dir_files_tif[i], "Zoom2.5") != -1 || indexOf(dir_files_tif[i], "Focus") != -1 || indexOf(dir_files_tif[i], "focus") != -1 ) {
				zooms = Array.concat(zooms, "Z2.5");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Z4") != -1  || indexOf(dir_files_tif[i], "Zoom4") != -1 || indexOf(dir_files_tif[i], "zoom") != -1 ) {
				zooms = Array.concat(zooms, "Z4");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Z5") != -1) {
				zooms = Array.concat(zooms, "Z5");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Z6") != -1) {
				zooms = Array.concat(zooms, "Z6");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Green") != -1) {
				chans = Array.concat(chans, "Green");
				i = dir_files_tif.length;
			}
		}
		for (i=0; i<dir_files_tif.length; i+=1) {
			if (indexOf(dir_files_tif[i], "Red") != -1) {
				chans = Array.concat(chans, "Red");
				i = dir_files_tif.length;
			}
		}		
	}
	
	if (waves.length > 1) {
		waves_def = waves[0];
	} else {
		waves_def = waves[0];
	}
	if (chans.length > 1) {
		chans_def = "Green";
	} else {
		chans_def = "Green";
	}
	if (zooms.length > 1) {
		zooms_def = "Z4";
	} else {
		zooms_def = "Z4";
	}
	
	Dialog.create("Find the Stack");
	Dialog.addChoice("Wavelength", waves, waves_def);
	Dialog.addChoice("Channel", chans, chans_def);
	Dialog.addChoice("Zoom", zooms, zooms_def);
	Dialog.show();
	
	wave = Dialog.getChoice();
	chan = Dialog.getChoice();
	zoom = Dialog.getChoice();

	filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + wave + ").*\\.tif$))");
	while (filt_dir.length == 0) {
		Dialog.create("Custom Wavelength Setting");
		Dialog.addMessage("Wavelength not found in filename, please enter custom wavelength");
		Dialog.addString("Wavelength (nm):", "810");
		Dialog.show();
		wave = Dialog.getString();
		wave = wave + "nm";
		filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + wave + ").*\\.tif$))");
		if (filt_dir.length == 0) {
			waitForUser("None found.\nTry again...");
		}
	}
	filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + zoom + ").*\\.tif$))");
	while (filt_dir.length == 0) {
		Dialog.create("Custom Zoom Input");
		Dialog.addMessage("Zoom setting not found in filename, please enter custom value");
		Dialog.addString("Enter Custom Value:", "");
		Dialog.show();
		zoom = Dialog.getString;
		filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + zoom + ").*\\.tif$))");
		if (filt_dir.length == 0) {
			waitForUser("None found.\nTry again...");
		}
	}	
	filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + chan + ").*\\.tif$))");
	while (filt_dir.length == 0) {
		chans = newArray("Green", "Red");
		Dialog.create("Custom Channel Input");
		Dialog.addMessage("Channel not found in filename, please enter custom value");
		Dialog.addChoice("Channel:", chans, "Green");
		Dialog.show();
		chan = Dialog.getChoice();
		filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + chan + ").*\\.tif$))");
		if (filt_dir.length == 0) {
			waitForUser("None found.\nTry again...");
		}
	}
	filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + wave + ")(?=.*" + zoom + ")(?=.*" + chan + ").*\\.tif$))");
	while (filt_dir.length == 0) {
		Dialog.create("Custom Inputs");
		Dialog.addMessage("Filter Fail... Try entering custom values");
		Dialog.addString("Wavelength:", "810nm");
		Dialog.addString("Zoom:", "Z4");
		Dialog.addString("Channel:", "Green");
		Dialog.show();
		wave = Dialog.getString();
		zoom = Dialog.getString();
		chan = Dialog.getString();
		filt_dir = Array.filter(dir_files_tif, "((?i)((?=.*" + wave + ")(?=.*" + zoom + ")(?=.*" + chan + ").*\\.tif$))");
		if (filt_dir.length == 0) {
			waitForUser("None found.\nTry again...");
		}
	}
	myFilter = "((?i)((?=.*" + wave + ")(?=.*" + zoom + ")(?=.*" + chan + ").*\\.tif$))";
	run("Image Sequence...", "open=[" + dir + "] filter=&myFilter sort");
	rename("Stack");

	if (nSlices == 1) {
		rename("Stack");
		
		run("Select None"); //sets negative values to zero
		setThreshold(-999, 0);
		run("Create Selection");
		run("Set...", "value=0");
		resetThreshold;
		run("Select None");		
	
	} else if (nSlices > 1) {
		selectWindow("Stack");
		seq = newArray();
		for (i=1; i<=nSlices; i+=1) {
			setSlice(i);
			label = getInfo("slice.label");
			//print(label);
			label_seq_end = indexOf(label, "_ADCA");
			if (label_seq_end == -1) {
				label_seq_end = indexOf(label, "_ADCB");
			}
			//print(label_seq_end);
			
			label_seq_start = -1; chars = 0;
			while (label_seq_start == -1) {
				if (substring(label, label_seq_end - (chars + 1), label_seq_end - chars) != "_") {
					chars = chars + 1;
				} else if (substring(label, label_seq_end - (chars + 1), label_seq_end - chars) == "_") {
					label_seq_start = label_seq_end - (chars);
				}
			}
			
			//print(label_seq_start);
			label_seq = substring(label, label_seq_start, label_seq_end);
			//print(label_seq);
					
			label_seq = IJ.pad(label_seq, 3);
			//print(label_seq);
			seq = Array.concat(seq, label_seq);
			
			label = substring(label, 0, label_seq_start) + label_seq + substring(label, label_seq_end, label.length);
			//print(label);
			
			run("Set Label...", "label=" + label); //relabels slice with sequence padded with zeros
			
			if (zero_vals == true) {
				run("Select None"); //sets negative values to zero
				setThreshold(-999, 0);
				run("Create Selection");
				run("Set...", "value=0");
				resetThreshold;
				run("Select None");
			}
		}
		seq = Array.rankPositions(seq);
		seq_order = newArray();
		for (j=0; j<seq.length; j+=1) {
			label_seq = seq[j] + 1;
			seq_order = Array.concat(seq_order, label_seq);
		}
		//Array.print(slices);
		slices = "";
		for (k=0; k<seq_order.length; k+=1) {
			slices = slices + seq_order[k] + ",";
		}
		
		slices = substring(slices, 0, slices.length - 1);
		//print(slices);
		
		run("Make Substack...", "slices=" + slices); //creates new substack with slices in order
		close("Stack");
		rename("Stack");
		setSlice(1);
	}
}
if (indexOf(dir, "Match") != -1) {
	date = "";
	name = "";
}

if (dir.length == 0) { //naming
	Dialog.create("Manual input");
	Dialog.addString("Date:", "");
	Dialog.addString("Name:", "");
	Dialog.show();
	date = Dialog.getString();
	name = Dialog.getString();
} else {
	
	date_info = File.dateLastModified(dir);
	mod_month = substring(date_info, 4, 7);
	if (mod_month == "Jan") {
		mod_month = "01";
	}
	if (mod_month == "Feb") {
		mod_month = "02";
	}
	if (mod_month == "Mar") {
		mod_month = "03";
	}
	if (mod_month == "Apr") {
		mod_month = "04";
	}
	if (mod_month == "May") {
		mod_month = "05";
	}
	if (mod_month == "Jun") {
		mod_month = "06";
	}
	if (mod_month == "Jul") {
		mod_month = "07";
	}
	if (mod_month == "Aug") {
		mod_month = "08";
	}
	if (mod_month == "Sep") {
		mod_month = "09";
	}
	if (mod_month == "Oct") {
		mod_month = "10";
	}
	if (mod_month == "Nov") {
		mod_month = "11";
	}
	if (mod_month == "Dec") {
		mod_month = "12";
	}
	mod_day = substring(date_info, 8, 10);
	mod_year = substring(date_info, 24, date_info.length);
	//mod_date = mod_month + "-" + mod_day + "-" + mod_year;
	
	if (indexOf(dir, "2026") != -1) {
		year = "26";
	}
	if (indexOf(dir, "2025") != -1) {
		year = "25";
	}
	if (indexOf(dir, "2024") != -1) {
		year = "24";
	}
	if (indexOf(dir, "2023") != -1) {
		year = "23";
	}
	if (indexOf(dir, "2022") != -1) {
		year = "22";
	}
	if (indexOf(dir, "2021") != -1) {
		year = "21";
	}
	if (indexOf(dir, "2020") != -1) {
		year = "20";
	}
	if (indexOf(dir, "2019") != -1) {
		year = "19";
	} else {
		year = mod_year;
	}
	if (indexOf(dir, "Jan") != -1 || indexOf(dir, "January") != -1) {
		month = "01";
	}
	if (indexOf(dir, "Feb") != -1 || indexOf(dir, "February") != -1) {
		month = "02";
	}
	if (indexOf(dir, "Mar") != -1 || indexOf(dir, "March") != -1) {
		month = "03";
	}
	if (indexOf(dir, "Apr") != -1 || indexOf(dir, "April") != -1) {
		month = "04";
	}
	if (indexOf(dir, "May") != -1) {
		month = "05";
	}
	if (indexOf(dir, "Jun") != -1 || indexOf(dir, "June") != -1) {
		month = "06";
	}
	if (indexOf(dir, "Jul") != -1 || indexOf(dir, "July") != -1) {
		month = "07";
	}
	if (indexOf(dir, "Aug") != -1 || indexOf(dir, "August") != -1) {
		month = "08";
	}
	if (indexOf(dir, "Sep") != -1 || indexOf(dir, "Sept") != -1 || indexOf(dir, "September") != -1) {
		month = "09";
	}
	if (indexOf(dir, "Oct") != -1 || indexOf(dir, "October") != -1) {
		month = "10";
	}
	if (indexOf(dir, "Nov") != -1 || indexOf(dir, "November") != -1) {
		month = "11";
	}
	if (indexOf(dir, "Dec") != -1 || indexOf(dir, "December") != -1) {
		month = "12";
	} else {
		month = mod_month;
	}
	
	if (indexOf(dir, ",") != -1) {
		day_index_end = indexOf(dir, ",");
		//print(day_index_end);
		day_index_start = -1; chars = 0;
		while (day_index_start == -1) {
			if (substring(dir, day_index_end - (chars + 1), day_index_end - chars) != " ") {
				chars = chars + 1;
			} else if (substring(dir, day_index_end - (chars + 1), day_index_end - chars) == " ") {
				day_index_start = day_index_end - chars;
			}
		}
		day = substring(dir, day_index_start, day_index_end);
	} else {
		day = mod_day;
	}
	
	if (indexOf(dir, "Selin") != -1 || selin_naming_system == true) {
		year = substring(dir, indexOf(dir, "2026"), indexOf(dir, "2026") + 4);
		month = substring(dir, indexOf(dir, "2026") - 4, indexOf(dir, "2026") -2);
		day = substring(dir, indexOf(dir, "2026") - 2, indexOf(dir, "2026"));
	}
	
	//print(day);
	date = month + "-" + day + "-" + year;
	//print(date);
	
	info = getInfo("slice.label");
	name_end = indexOf(info, "_");
	name = substring(info, 0, name_end);
}

print(name);

Dialog.create("Process Stack from Toronado");
Dialog.addMessage("Stack Name:");
Dialog.addString("Date:", date);
Dialog.addString("Name:", name);
Dialog.addCheckbox("Stim/Ionto", true);
Dialog.addCheckbox("Save Stack", true);
Dialog.addMessage("\n");
Dialog.addCheckbox("Display Z-axis profile", true);
Dialog.show();

date = Dialog.getString();
name = Dialog.getString();
stim_opt = Dialog.getCheckbox();
save_opt = Dialog.getCheckbox();
z_opt = Dialog.getCheckbox();

stim = "";
sweeps = "3";

theta_check = -1; ionto_check = -1; bap_check = -1; stim_check = -1;
if (indexOf(name, "Theta") != -1) {
	if (indexOf(info, "uA") != -1) {
		stim_int = substring(info, indexOf(info, "uA") - 2, indexOf(info, "uA"));
	} else {
		stim_int = "";
	}
	sweeps = "3";
}
if (indexOf(name, "Ionto") != -1) {
	if (indexOf(info, "_r") != -1 && indexOf(info, "nA_e") != -1) {
		ionto_ret = substring(info, indexOf(info, "_r") + 2, indexOf(info, "nA_e"));
	} else {
		ionto_ret = "";
	}
	if (indexOf(info, "_e") != -1 && indexOf(info, "nA_d") != -1) {
		ionto_ej = substring(info, indexOf(info, "_e") + 2, indexOf(info, "nA_d"));
	} else {
		ionto_ej = "";
	}
	if (indexOf(info, "_d") != -1 && indexOf(info, "ms_") != -1) {
		ionto_dur = substring(info, indexOf(info, "_d") + 2, indexOf(info, "ms_"));
	} else {
		ionto_dur = "";
	}
	sweeps = "5";
}
bap_check = indexOf(name, "BAP");
stim_check = indexOf(name, "Stim");

if (stim_opt == true) {
	Dialog.create("Stim/Ionto Params");
	if (indexOf(name, "Theta") != -1) {
		Dialog.addString("Stim Intensity (uA):", stim_int);
	}
	if (indexOf(name, "Ionto") != -1) {
		Dialog.addString("Retention Current (nA):", ionto_ret);
		Dialog.addString("Ejection Current (nA):", ionto_ej);
		Dialog.addString("Duration (ms):", ionto_dur);
	}
	if (indexOf(name, "BAP") != -1) {
		Dialog.addString("Stim Intensity (uA):", "1x10");
	}
	if (indexOf(name, "Stim") != -1) {
		Dialog.addString("Stim Intensity (uA)", "1x40");
	}
	Dialog.addString("Sweeps", sweeps);
	Dialog.show();
	
	if (indexOf(name, "Theta") != -1) {
		stim_int = Dialog.getString();
	}
	if (indexOf(name, "Ionto") != -1) {
		ionto_ret = Dialog.getString();
		ionto_ej = Dialog.getString();
		ionto_dur = Dialog.getString();
	}
	if (indexOf(name, "BAP") != -1) {
		bap_int = Dialog.getString();
	}
	if (indexOf(name, "Stim") != -1) {
		stim_int = Dialog.getString();
	}
	sweeps = Dialog.getString();
	
	if (indexOf(name, "Theta") != -1) {
		stim = "_" + stim_int + "uA";
	}
	if (indexOf(name, "Ionto") != -1) {
		stim = "_r" + ionto_ret + "nA_e" + ionto_ej + "nA_" + ionto_dur + "ms";
	}
	if (indexOf(name, "BAP") != -1) {
		stim = "_" + bap_int + "uA";
	}
	if (indexOf(name, "Stim") != -1) {
		stim = "_" + stim_int + "uA";
	}
	if (sweeps != 1) {
		sweeps = "_x" + sweeps;
	} else if (sweeps == 1) {
	//	sweeps = substring(dir, dir.length - 3, dir.length - 1);
	}
}

stack_name = date + "_" + name + "_" + wave + "_" + zoom + "_" + chan + stim + sweeps;

rename(stack_name);
run("Rotate 90 Degrees Left");

if (zoom == "Z4") {
	zoom_factor = 12.9;
} else if (zoom == "Z2.5") {
	zoom_factor = 4.6;
} else if (zoom == "Z5") {
	zoom_factor = 26.1;
} else if (zoom == "Z6") {
	zoom_factor = 52.2;
} else {
	zoom_names = newArray("Z4", "Z2.5", "Z5", "Z6");
	
	Dialog.create("Zoom Setting");
	Dialog.addChoice("Select Zoom setting:", zoom_names, "Z4");
	Dialog.show();
	
	zoom = Dialog.getChoice();
}
if (zoom == "Z4") {
	zoom_factor = 12.9;
} else if (zoom == "Z2.5") {
	zoom_factor = 4.6;
} else if (zoom == "Z5") {
	zoom_factor = 26.1;
} else if (zoom == "Z6") {
	zoom_factor = 52.2;
}

run("Set Scale...", "distance=" + zoom_factor + " known=1 pixel=1 unit=" + "µm");

if (save_opt == true) {
	//save_dir = getDirectory("Choose Save Directory");
	if (indexOf(dir, ",") != -1) {	
		root_start = indexOf(dir, ","); chars = 0; end_loop = 0;
		while (end_loop < 2) {
			if (substring(dir, root_start + chars, root_start + chars + 1) != "/") {
				chars = chars + 1;
			} else if (substring(dir, root_start + chars, root_start + chars + 1) == "/") {
				end_loop = end_loop + 1;
				chars = chars + 1;
			}
		}
		name_end = root_start + chars;
		root = substring(dir, 0, name_end);
		if (File.exists(root + "/Analysis/") != 1) {
			File.makeDirectory(root + "/Analysis/");
			dir = root + "/Analysis/";
		} else {
			dir = root + "/Analysis/";
		}
	} else {
		if (File.exists(dir + "/Analysis/") != 1) {
			File.makeDirectory(dir + "/Analysis/");
			dir = dir + "/Analysis/";
		} else {
			dir = dir + "/Analysis/";
		}
	}
	saveAs("Tiff", dir + "/" + stack_name + ".tif");
}

if (z_opt == true) {
	run("Plot Z-axis Profile");
	z_prof = getTitle();
	waitForUser("Close Z-axis Profile");
	close(z_prof);
}
