System Health Summary (Axis Cameras)

This document outlines the process for collecting and processing System Health Summary (SHS) data for Axis cameras across customer sites.

The workflow consists of three parts:

Part 1 – Data collection from the customer’s network
Part 2 – Data processing and formatting into a Google Sheet
Part 3 – Chart generation using Google Apps Script
Part 1 – Data Collection

Data from the customer’s site can be gathered using one of the following methods:

Option 1 (Preferred): Axis Device Manager Extend (ADMX)
Use Axis Device Manager Extend on the customer’s network
Export a CSV file containing camera information
Follow the official instructions (link referenced as “here”)
Option 2 (Fallback): Bash Script (VAPIX)

Use this option only if ADMX is not available

Run a Bash script to collect camera data directly using VAPIX commands.

Notes on Execution
Run the selected option on servers that cover the entire network
Some environments may require:
Multiple servers
Or just a single server
When using ADMX:
Ensure all required nodes are connected
Export combined camera data into one CSV
Running the Bash Script (Option 2)
1. Prepare the Environment

Log in as root and navigate to /tmp:

cd /tmp
2. Create the Script
touch vapix_scrapper.sh
chmod +x vapix_scrapper.sh
3. Edit the Script
less vapix_scrapper.sh
Paste the provided script code (referenced as “Script is here”)
Save and exit
4. Execute the Script
./vapix_scrapper.sh
5. Output Location

The script generates a .txt file at:

/tmp/${host_name}/${server_id}_axis_basicdeviceinfo.txt
Copy this file to your local machine for processing
Part 2 – Data Processing
1. Prepare the Google Sheet
Add a new tab after "Inventory Charts"
Name it exactly:
AxisCameras

⚠️ No space between “Axis” and “Cameras”

2. Upload Data

Upload collected data to:

/opt/API_Integration/sites/<site_name>/
Supports:
.txt (from script)
.csv (from ADMX)

If using ADMX manual process, skip to Part 3

3. Run the Python Script
cd /opt/API_Integration/
python3 shs_axis_cams.py
4. Select Site
Choose the site from the displayed list
Enter the name exactly as shown
5. If Site Is Missing (Custom Entry)

Provide the following:

Name
Any descriptive name (not strict)
Source File Location
/opt/API_Integration/sites/<site_name>/
Google Sheet ID

From the URL:

https://docs.google.com/spreadsheets/d/<GOOGLE_SHEET_ID>/edit
6. Validate Results
Review processed camera data
Fix any incorrect statuses:
Example: Cameras marked “unreachable” but actually online
Part 3 – Google Apps Script (Chart Generation)

Run the Apps Script in the System Health Summary Google Sheet.

1. Open Apps Script
Open the customer’s SHS Google Sheet
Navigate to:
Extensions → Apps Script
2. Verify Script File

Check for:

shs_complete.gs
If it exists → skip to Step 4
If not → continue to Step 3
3. Create Missing Script
Click + (Add file) → Script
Name:
shs_complete.gs
Paste the provided script code
Save the file
4. Run the Script
Open code.gs (or relevant script file)
Click Run
Authorization (if prompted)
Select your Google account
Grant permissions
Running Specific Functions
Select the desired function from the dropdown
Run individually if needed
5. Verify Output
Return to the Google Sheet
Confirm:
Charts are generated
Data appears correctly
Additional Reference
Return to SHS Instructions: Back
