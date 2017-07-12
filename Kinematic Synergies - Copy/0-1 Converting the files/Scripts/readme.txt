
This readme document indicates how to process Phase 3 data.
Author: 2014 Tina Hung
Edits: 2016 navid Lambert-Shirzad

=========================================================================================
For data obtained from FEATHERS Motion, you will only need to call FEATHERS_Motion_RawBinData_Process.m 
to process the .bin file to an .xlsx file. This process filters out:
- data before first left click or centering gesture click
- [PS3] data when either controller is not visible to the camera
- [PS3] data for specified seconds after either controller went from no visual->visual. 
	This was done due to the observation of data jump right after controller went from no visual->visual.
- [Kinect] data when either left or right wrist joint  is not visible or inferred to the camera

Put the raw .bin files in ToBeProcessed Folder. After Running the script, move the raw files to Processed.

OUTPUTS: 
- Filtered data as well as calculated time played (s) and left and right wrist movement. 
- Overall % of mirror or wheel mode used, time played, wrists movements are also outputted in MATLAB main window when processing multiple files. T

Other Comments:
- this scripts look at a certain folder and process all the binary files in it, then it outputs everything to corresponding .xlsx files that are later used for other calculations.
  ** do not put .xlsx files in the result folder initially otherwise it will be automatically processed  by the scripts along with the newly generated .xlsx files from the .bin
- the ratios for x, y, and z are applied in the scripts
- left & right click of each controller are combined in one byte (one column after converted and filtered):
0: no button pressed
1: right button pressed
2: left button pressed
3: both buttons pressed (unlikely)
=========================================================================================