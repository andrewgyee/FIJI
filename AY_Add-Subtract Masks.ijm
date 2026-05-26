open_windows = getList("image.titles");

mask_check = -1; mask_index = 0;
for (i=0; i<open_windows.length; i+=1) {
	//mask_check = indexOf(open_windows[i], "_Mask");
	if (indexOf(open_windows[i], "_Mask") != -1 || indexOf(open_windows[i], "mask") != -1) {
		mask_index = i;
	}
}

active_mask = open_windows[mask_index];

Dialog.create("Add/Subtract Mask");
Dialog.addCheckbox("Add", false);
Dialog.addCheckbox("Subtract", false);
Dialog.show();

add_check = Dialog.getCheckbox();
sub_check = Dialog.getCheckbox();

if (add_check == true) {
	operation = "Add";
} else if (sub_check == true) {
	operation = "Subtract";
}

run("Create Mask");
imageCalculator(operation, active_mask, "Mask");
close("Mask");