//31st Jan 2023
//Sid
//Specified analyse particles filter for size
//make sure the data is paired in R

roiManager("Reset");
inDir = getDirectory("Input Direction, source of all .nd2 files");
outDir = getDirectory("Direct images from steps and ROIs of whole image");

gfpData = getDirectory("GFP_data");
rfpData = getDirectory("RFP_data");


filelist = getFileList(inDir);

//running the loop on every .nd2 file in the the selected input directory
//all output saved to the specified output directory

for (k = 0; k < lengthOf(filelist); k++) {
    if (endsWith(filelist[k], ".nd2")) { 
    	filename = inDir + File.separator + filelist[k];
    	run("Bio-Formats Importer", "open=filename autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack");
    image = getTitle();  

roiManager("Reset");
  
//Open raw .nd2 image and first we Z project it                                
run("Z Project...", "projection=[Sum Slices]");    

//save Z projected file 
filenamesave = filelist[k];
saveAs("Tiff",  outDir + filenamesave + "_Zstack_Sum");

selectWindow(filenamesave + "_Zstack_Sum.tif");
run("Channels Tool...");
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");

//Now we want to select specific channels to work with.
//We start with the DAPI channel (channel 3)
selectWindow(filenamesave + "_Zstack_Sum.tif");
run("Select All");
run("Duplicate...", "duplicate channels=3");
selectWindow(filenamesave + "_Zstack_Sum-1.tif"); //the new file has a -1 appended to the name
resetMinAndMax();
run("Enhance Contrast", "saturated=0.35"); //brightness and contrast adjustment

//Applying a median filtering of specified radius
//titlex = "Select Radius"; 
//msg = "Select Radius for median filtering and click ok";
//waitForUser(titlex, msg); //dont know how to do away with this dialogue box :(
run("Median...");

//After median filtering we next make the image binary in order to select nuceli ROIs
//We use the thresholding pluggin to make this binary
selectWindow(filenamesave + "_Zstack_Sum-1.tif");
run("Threshold...");
resetThreshold();
title = "Thresholds";
msg = "Use the \"Threshold\" tool to\nadjust the threshold, click apply and convert to mask. (ALWAYS) then click \"OK\". ";
waitForUser(title, msg); //we set the threshold for every image
run("Watershed");
//Next we select all the binary white regions and make them ROIs
run("Create Selection");
roiManager("Add");
roiManager("Split");
saveAs("Tiff",  outDir + filenamesave + "_DAPImasks"); //save DAPI masks
roiManager("Save", outDir + filenamesave + "_ROIs_all_DAPImask_wholeImage" + ".zip");

//Next we duplicate out the GFP channel (Channel 2)
//Note because we renames and saved the previous image the duplicated file is still appended with -1
selectWindow(filenamesave + "_Zstack_Sum.tif");
run("Select All");
run("Duplicate...", "duplicate channels=2");

//Run threshold of specified by us for the GFP FISH stained centromeres
run("Threshold...");
resetThreshold();
run("ROI Manager...");
roiManager("Show None");

title = "Thresholds";
msg = "Use the \"Threshold\" tool to\nadjust the threshold, click apply and convert to mask. (ALWAYS) then click \"OK\". ";
waitForUser(title, msg);
roiManager("Select", 0);
saveAs("Tiff",  outDir + filenamesave + "_GFPmasks"); //save GFP masks
roiManager("Show None");
roiManager("Show All");

//Now we run the main chunk of code

//We can now finally measure the integrated density of the 2 foci of the good ROIs
run("Analyze Particles...", "size=0.1-Infinity circularity=0.00-1.00 show=Nothing display clear add composite");
run("Set Measurements...", "area mean standard min integrated median display redirect=None decimal=3");
run("ROI Manager...");
roiManager("Save", outDir + filenamesave + "_fociROIsgfp" + ".zip");  
selectWindow("Results");
newname=substring(image,0,lengthOf(image)-3);
saveresult = gfpData  + newname+ "Result_GFParea" + ".csv";
saveAs("text",saveresult); 
Table.rename("Results", "Result_GFParea");
selectWindow("Result_GFParea");				
close("Result_GFParea");

open(outDir + filenamesave + "_Zstack_Sum.tif");
run("Duplicate...", "duplicate channels=2");
roiManager("Reset");
open(outDir + filenamesave + "_fociROIsgfp" + ".zip");
run("ROI Manager...");

l = roiManager("count");
x=Array.getSequence(l);

roiManager("Select", x);
roiManager("AND");
roiManager("Measure");

selectWindow("Results");
newname=substring(image,0,lengthOf(image)-3);
saveresult = gfpData  + newname+ "Result__GFPintensity" + ".csv";
saveAs("text",saveresult);
Table.rename("Results", "Result__GFPintensity");
selectWindow("Result__GFPintensity");				
close("Result__GFPintensity");
 //You can chaneg what you want to measure in the set measurement line

run("close all tables jru v1"); //Close all the tabs
//Next we repeat the same thing for RFP

//Next we duplicate out the RFP channel (Channel 1)
//Note because we renames and saved the previous image the duplicated file is still appended with -1
roiManager("Reset");
selectWindow(filenamesave + "_Zstack_Sum.tif");
run("Select All");
run("Duplicate...", "duplicate channels=1");

//Run threshold of specified by us for the RFP FISH stained centromeres
run("Threshold...");
resetThreshold();
open(outDir + filenamesave + "_ROIs_all_DAPImask_wholeImage" + ".zip");
run("ROI Manager...");
roiManager("Show None");
roiManager("Show All");

title = "Thresholds";
msg = "Use the \"Threshold\" tool to\nadjust the threshold, click apply and convert to mask. (ALWAYS) then click \"OK\". ";
waitForUser(title, msg);

roiManager("Select", 0);
saveAs("Tiff",  outDir + filenamesave + "_RFPmasks"); //save RFPFP masks
roiManager("Show None");
roiManager("Show All");

//Now we run the main chunk of code
run("Analyze Particles...", "size=0.1-Infinity circularity=0.00-1.00 show=Nothing display clear add composite");
run("Set Measurements...", "area mean standard min integrated median display redirect=None decimal=3");
run("ROI Manager...");
roiManager("Save", outDir + filenamesave + "_fociROIsrfp" + ".zip");  
selectWindow("Results");
newname=substring(image,0,lengthOf(image)-3);
saveresult = rfpData  + newname+ "Result_RFParea" + ".csv";
saveAs("text",saveresult); 
Table.rename("Results", "Result_RFParea");
selectWindow("Result_RFParea");				
close("Result_RFParea");

open(outDir + filenamesave + "_Zstack_Sum.tif");
run("Duplicate...", "duplicate channels=1");
roiManager("Reset");
open(outDir + filenamesave + "_fociROIsrfp" + ".zip");
run("ROI Manager...");


l = roiManager("count");
x=Array.getSequence(l);

roiManager("Select", x);
roiManager("AND");
roiManager("Measure");

selectWindow("Results");
newname=substring(image,0,lengthOf(image)-3);
saveresult = rfpData  + newname+ "Result__RFPintensity" + ".csv";
saveAs("text",saveresult); 
Table.rename("Results", "Result__RFPintensity");
selectWindow("Result__RFPintensity");				
close("Result__RFPintensity");
} //You can chaneg what you want to measure in the set measurement line


run("close all tables jru v1"); //Close all the tabs
close("*");
}}
//Close everything so that its all clean for the next .nd2 file 
//Done
//Congrats
//:))
 
