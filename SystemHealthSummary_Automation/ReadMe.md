This process explains how to collect System Health Summary data for Axis cameras from each site. It consists of Three parts.
---
### Part 1 is performed on the customer’s site and is used to gather the required data directly from their network.
###Part 2 takes the collected data and formats it into a clean, organized layout within a Google Sheet.
###Part 3 will create the charts for the non-axis cameras using App Scripts.
---
#Fist Part
The information from the customer’s site can be gathered in two ways.

##Option 1 (Preferred): Use Axis Device Manager Extend on the customer’s network and export a CSV file containing the camera information. Follow the Instructions: here

##Option 2 (Only use when ADMX is not an option): Run the Bash script below to collect the required data directly from the cameras using VAPIX commands.

Depending on the site’s network architecture, run Option 1 or Option 2 on servers that provide coverage for the entire network. Some sites may require the process to be run on multiple servers, while others may only require a single server.

If using Axis Device Manager Extend (ADMX), connect all required nodes within ADMX and export the combined camera data into a single CSV file.

Running the Bash Script (Option 2)
Create and run the Bash script on a server that is connected to the customer’s network. Ensure you are logged in as the root user.

Navigate to the temporary directory:

cd /tmp
Create the script file and make it executable:

touch vapix_scrapper.sh
chmod +x vapix_scrapper.sh
Open the file for editing:

less vapix_scrapper.sh
Paste the provided script code into the newly created file and save it. Script is here.

Once executed, the script will automatically generate a .txt file containing the camera information.

./vapix_scrapper.sh
The output file will be located at:

/tmp/${host_name}/${server_id}_axis_basicdeviceinfo.txt
After the script completes, copy the output file back to your local machine for further processing.
---
##Second Part
Add a Tab in the Google Sheet right after [“Inventory Charts”] and name it exactly [“AxisCameras“] (no space between Axis and Cameras)

Once the data has been gathered from the customer’s site, it must be processed and then entered into the site-specific Google Sheet. (If ADMX was used then follow the ADMX instructions to add them manually and skip to part 3)

Take the gathered data (either the exported .txt file or the ADMX .csv file) and upload it to the Support Utility in the appropriate site folder:

/opt/API_Integration/sites/<site_name>/
Next, run the Python script located in the /opt/API_Integration/ directory:

cd /opt/API_Integration/
python3 shs_axis_cams.py
When the script runs, it will display a list of available sites. Select the site you are working on by typing the corresponding name exactly as shown in the list.

If the site is not listed, choose the final option to create a custom entry. Creating a custom entry requires the following three values:

Name
Any descriptive name for the site. The specific string is not critical.

Location for source file
The directory containing the data collected in Part 1. This should be:

/opt/API_Integration/sites/<site_name>/
Google Sheet ID
This can be found in the URL of the Google Sheet. For example:

https://docs.google.com/spreadsheets/d/<THIS_IS_THE_GOOGLE_ID_KEY>/edit?gid=0#gid=0
After the script completes, carefully review the camera output results. Identify any cameras that are marked as “unreachable” but are in fact online and functioning properly, and update their status to reflect their correct state.
---
##Third Part
For the customer you’re working on, you must run The Google Apps Script in the corresponding System Health Summary Google Sheet:

shs_complete.gs

1) Open Apps Script from the Google Sheet
Open the customer’s Site Health Summary Google Sheet.

In the top menu, click Extensions.

Select Apps Script.

This opens Apps Script in a new tab.

2) Confirm the script file exist
In the Apps Script tab, look at the left sidebar under Files.

Check whether this file is listed:

shs_complete.gs

If the file exist, skip to Step 4: Run the scripts.

If one or both files do not exist, continue to Step 3: Create the missing files.

3) Create missing script
Click the + (Add file) button next to Files.

Choose Script.

Name the file exactly:

shs_complete.gs

Open the new file, then copy the provided code and paste it into the editor body.

shs_complete.gs

Click the Save icon.

4) Run the scripts
Run each script function “main”:

Click code.gs in the left sidebar to open it.

Click the Run button at the top of the editor.

If prompted, complete the authorization steps (choose your Google account → allow permissions).

If only one function needs to run and not all four

selected the desired function form the list

5) Verify
Return to the Site Health Summary Google Sheet and confirm the expected updates (charts) appear after both scripts run.

Go back to the SHS instructions: Back
