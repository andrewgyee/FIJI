//AY 08-23-21

//INPUT SLICE NUMBERS HERE
peak_slices = newArray(12, 52, 92, 132, 172);
sweep_length = peak_slices[1] - peak_slices[0];
sweep_pad = sweep_length - 12;

av_opt = false;

print("\\Clear");
active_window = getTitle();
parent_name = replace(active_window, ".tif", "");
info = getImageInfo(); //finds scale factor from original stack
res_index = indexOf(info, "Resolution");
info = substring(info, res_index, res_index + 17);
scale_factor = replace(info, "Resolution: ", "");
scale_factor = parseFloat(scale_factor);

save_dir = getDirectory("Choose Save Directory");

run("Select None");
titles = newArray();
for (i=0; i<peak_slices.length; i+=1) {
	selectWindow(active_window);
	run("Make Substack...", "slices=" + peak_slices[i] - 11 + "-" + peak_slices[i] + sweep_pad);
	substack_id = i+1;
	substack_id = IJ.pad(substack_id, 2);
	rename(parent_name + "_" + substack_id);
	title = getTitle();
	titles = Array.concat(titles, title);
	saveAs("Tiff", save_dir + parent_name + "_" + substack_id);
	setSlice(12);
}

if (av_opt == true) {

	Dialog.create("Average Movies"); //automatically selects movies from list of open windows
	for (i=1; i<=titles.length; i+=1) {
		Dialog.addChoice("Movie #" + i + ":", titles, titles[i-1]);
	}
	Dialog.show();
			
	movie_list = newArray(); //creates list of variable names to assign choices from previous dialog
	for (i=0; i<titles.length; i+=1) {
		movie_name = "Movie_" + i+1;
		movie_list = Array.concat(movie_list, movie_name);
	}
	//Array.print(movie_list);
			
	for (i=0; i<titles.length; i+=1) { //assigns dialog choices to list of variable names
		movie_list[i] = Dialog.getChoice();
	}
			
	alphs = newArray(); //creates array of letters for parser expression
	alphabet = newArray("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");
	for (i=0; i<titles.length; i+=1) {
		alph = alphabet[i];
		alphs = Array.concat(alphs, alph);
	}
			
	expression = ""; //compiles parser expression
	for (i=0; i<titles.length; i+=1) {
		expression = expression + alphs[i] + "+";
	}
	expression = substring(expression, 0, lengthOf(expression)-1);
	expression = "(" + expression + ")/" + titles.length;
	//print(expression);
		
	alphs_lower = newArray(); //cos stupid ImageJ uses lowercase for the second part of this java macro...
	alphabet_lower = newArray("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z");
	for (i=0; i<titles.length; i+=1) {
		alph_lower = alphabet_lower[i];
		alphs_lower = Array.concat(alphs_lower, alph_lower);
	}
			
	average_list = ""; //compiles parser list of movies to average i.e. A=movie_name
	for (i=0; i<titles.length; i+=1) {
		average_list = average_list + alphs_lower[i] + "=" + movie_list[i] + ".tif ";
	}
	average_list = substring(average_list, 0, lengthOf(average_list)-1);
	//print(average_list);
	
	//waitForUser;
	
	run("Image Expression Parser (Macro)", "expression=" + expression + " " + average_list);
			
	selectWindow("Parsed with " + expression);
	rename(parent_name + "_Average");
	run("Hyperstack to Stack");
	selectWindow(parent_name + "_Average");
	run("Set Scale...", "distance=" + scale_factor + " known=1 unit=µm");
	//run("16-bit");
	saveAs("Tiff", save_dir + parent_name + "_Average")
	setSlice(12);
}

run("Close All");