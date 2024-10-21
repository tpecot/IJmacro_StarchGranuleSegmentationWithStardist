/* This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation:
 http://www.gnu.org/licenses/agpl-3.0.txt
*/

// input parameters
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Input Stardist model", style = "open") stardist_model
#@ Float (label = "Probability threshold for Stardist", value = 0.25, style = "format:#.##") prob_threshold
#@ Float (label = "Overlapping parameter for Stardist", value = 0.1, style = "format:#.##") overlapping_parameter
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// call to the main function "processFolder"
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	///////////// initial cleaning /////////////////
	// close all images
	run("Close All");
	// reset ROI manager
	roiManager("Reset");
	// remove results in result table if there are any
	run("Clear Results");

	// set Feret's diameter as measurements
	run("Set Measurements...", "feret's redirect=None decimal=3");
	///////////// apply pipeline to input images /////////////////
	// get the files in the input folder
	list = getFileList(input);
	list = Array.sort(list);
	// loop over the files
	for (i = 0; i < list.length; i++) {
		// if there are any subdirectories, process them
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		// if current file ends with the suffix given as input parameter, call function "processFile" to process it
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
	
	// save results
	saveAs("Results", output + File.separator + "results.csv");	
	close("Results"); 
	// save parameters
	// create results table
	Table.create("Results");
	setResult("Input Stardist model", 0, stardist_model);
	setResult("Probability threshold for Stardist", 0, prob_threshold);
	setResult("Overlapping parameter for Stardist", 0, overlapping_parameter);
	updateResults();
	// save results
	saveAs("Results", output + File.separator + "parameters.csv");	
	// close results table
	close("Results"); 
}

function processFile(input, output, file) {

	// open image
	open(input+"/"+file);
	// rename
	rename("input");

	// run stardist
	stardist_model = replace(stardist_model,  "\\", "\\\\");
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'input', 'modelChoice':'Model (.zip) from File', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'" + prob_threshold + "', 'nmsThresh':'" + overlapping_parameter + "', 'outputType':'Both', 'modelFile':'" + stardist_model + "', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	// remove nuclei on the border
    for (i=roiManager("count")-1; i>=0; i--) {
		roiManager("select", i);
		getSelectionBounds(x, y, w, h); 
		if (x<=0||y<=0||x+w>=getWidth||y+h>=getHeight) 
        	roiManager("delete"); 
	} 

	// extract measurements
	selectImage("input");
	roiManager("Show All with labels");
	run("Select All");
	roiManager("Measure");
	// add file title in the Results
	current_row_init = nResults-roiManager("count");
	for (row=0; row<roiManager("count"); row++) {
		setResult("Input name", row+current_row_init, file);
		setResult("Id", row+current_row_init, row+1);
	}
	updateResults();
	// output visualization
	// flatten overlays
	run("Flatten");
	// save the image and the rois for visual inspection
	saveAs("png", output+"/"+file);

	///////////// clear everything /////////////////
	// close all images
	run("Close All");
	// reset ROI manager
	roiManager("Reset");

}
