print("\\Clear");

paramZooms = newArray("Z2.5=4.6", "Z4=12.9", "Z5=26.1", "Z6=52.2");
delay = false;

prevDir = getDir("current");
File.setDefaultDir(prevDir);

curDir = getDirectory("Open Folder");
curDirList = getFileList(curDir);
curDirTifs = newArray();
for (i=0; i<curDirList.length; i+=1) {
	if (indexOf(curDirList[i], ".tif") != -1) {
		curDirTifs = Array.concat(curDirTifs, curDirList[i]);
	}
}
if (curDirTifs.length < 1) {
	exit("Select Folder with .tifs");
} else {
	//print(curDirTifs[0]);
	sep_index = findSep(curDirTifs[0], "_", "fwd");
	name = substring(curDirTifs[0], 0, sep_index);
	strip_name = replace(name, "\\d", ""); strip_name = String.trim(strip_name);
}

if (indexOf(curDir, "/Analysis/") != -1) { //makes Analysis folder if it doesn't already exist
	saveDir = substring(curDir, 0, indexOf(curDir, "/Analysis"));
} else {
	sep_index = findSep(substring(curDir, indexOf(curDir, strip_name), curDir.length), "/", "fwd");
	saveDir = substring(curDir, 0, indexOf(curDir, strip_name) + sep_index);
	saveDir = saveDir + "/Analysis/";
	File.makeDirectory(saveDir);
}

print(saveDir);
//Array.print(curDirTifs);
saveDirList = getFileList(saveDir); //check if files already exist in /Analysis/
for (i=0; i<saveDirList.length; i+=1) { //check for subdirectories inside /Analysis/ and add any tifs
	if (endsWith(saveDirList[i], "/")) {
		subDirList = getFileList(saveDirList[i]);
		saveDirList = Array.concat(saveDirList, subDirList);
	}
}
curDirTifsNew = newArray();
if (saveDirList.length > 0) {
	for (i=0; i<curDirTifs.length; i+=1) {
		idc = newArray();
		idc = findValueinArray(saveDirList, curDirTifs[i]);
		//Array.print(idc);
		if (idc.length < 1) {
			curDirTifsNew = Array.concat(curDirTifsNew, curDirTifs[i]);
		}
	}
} else {
	curDirTifsNew = curDirTifs;
}
//Array.print(curDirTifsNew);
if (curDirTifsNew.length == 0) {
	exit("All .tifs in this folder have been processed");
} else {
	print("Processing " + curDirTifsNew.length + " Files");
}
for (i=0; i<curDirTifsNew.length; i+=1) {
	open(curDir + "/" + curDirTifsNew[i]);
	selectWindow(curDirTifsNew[i]);
	active_window = getTitle();
	zero_negs(active_window);
	activeParams = findParams(active_window);
	//Array.print(activeParams);
	for (j=0; j<activeParams.length; j+=1) { //extract paramZoom from activeParams array
		if (indexOf(activeParams[j], "paramZoom") != -1) {
			paramZoom = activeParams[j]; paramZoom = substring(paramZoom, indexOf(paramZoom, "=") + 1, paramZoom.length);
		}
	}
	for (j=0; j<paramZooms.length; j+=1) {
		if (indexOf(paramZooms[j], paramZoom) != -1) {
			paramZoom = paramZooms[j]; paramZoom = substring(paramZoom, indexOf(paramZoom, "=") + 1, paramZoom.length);
		}
	}
	run("Set Scale...", "distance="+paramZoom+" known=1 pixel=1 unit=µm");
	run("Rotate 90 Degrees Left");
	saveAs("Tiff", saveDir + "/" + active_window);
	if (delay == true) {
		run("Plot Z-axis Profile");
		wait(1000);
		close(active_window + "-0-0");
	}
	close(active_window);
}
print("DONE :)");
beep();

function findParams(name) {
	activeParams = newArray();
	//wavelength
	
	//zoom
	sep_index = findSep(substring(name, indexOf(name, "Z"), name.length), "_", "fwd");
	paramZoom = substring(name, indexOf(name, "Z"), indexOf(name, "Z") + sep_index);
	activeParams = Array.concat(activeParams, "paramZoom=" + paramZoom);
	//chan
	
	return activeParams;
}

function zero_negs(active_window) {
	selectWindow(active_window);
	for (i=1; i<=nSlices; i+=1) {
		setSlice(i);
		run("Select None"); //sets negative values to zero
		setThreshold(-999, 0);
		run("Create Selection");
		run("Set...", "value=0");
		resetThreshold;
		run("Select None");
	}
}

function findSep(ref, sep, direction) {
	sep_find = false; sep_index = 0;
	while (sep_find == false) {
		if (direction == "fwd") {
			if (substring(ref, sep_index, sep_index + 1) != sep) {
				sep_index = sep_index + 1;
			} else {
				sep_find = true;
			}
		}
		if (direction == "rev") {
			if (substring(ref, ref.length + (sep_index - 1), ref.length + sep_index) != sep) {
				sep_index = sep_index - 1;
			} else {
				sep_find = true;
			}
		}
	}
	return sep_index;
}

function findValueinArray(array, value) {
	idc = newArray();
	for (i=0; i<array.length; i+=1) {
		if (indexOf(array[i], value) != -1) {
			idc = Array.concat(idc, i);
		}
	}
	//Array.print(idc);
	return idc;
}