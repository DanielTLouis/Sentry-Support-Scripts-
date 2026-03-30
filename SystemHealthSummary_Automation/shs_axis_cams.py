from __future__ import print_function
from datetime import date
from lxml import html
from bs4 import BeautifulSoup
import os.path
import csv
import os
import subprocess
import socket
import requests
import json
import re

from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from pathlib import Path

#------- Global Variables -----------------------------------------------------------------------------------------
CSV_PATH_WORKBOOK = "/opt/API_Integration/site_summary_workbook_test.csv"

# TO UPDATE A SPECIFIC CELL enter the cell after the sheet1! Note: if using a different sheet it needs to exsist prior to this
RANGE_NAME = "AxisCameras!A12"
BUCKET_RANGE = "AxisCameras!M12"

#Site Class to encasolate the API and Reference that is needed for the Google Sheet Export 
class Site: 
    def __init__(self, name="test", reference_path="/opt/API_Integration/Multi-Server_2025-11-18.csv", spreadsheet_id="1m06CDhoiWHjZ1PbkAm8FG9KZCFBu0wbkvc2mu6xKt_U"):
        self.name = name
        self.scope = ["https://www.googleapis.com/auth/spreadsheets"]
        self.reference_path = reference_path
        self.spreadsheet_id = spreadsheet_id
    def print_site(self):
        print(f"name: {self.name}{{")
        print(f"    scope: {str(self.scope)},")
        print(f"    csv path: {self.reference_path},")
        print(f"    spreadsheet id: {self.spreadsheet_id}")
        print("}")
#Global Site set to defualts before selection
SITE = Site()

# Function create bucket for graph output 
# Input List of List for the columns 
# Returns a dictionary of integers representing the statuses 
def graph_bucket(columns):
    bucket = {"Reachable on Network": 0, "Unreachable": 0, "Warranty is Good": 0, "Warrranty is Out of Date": 0, "Warranty is Near Date": 0, "Duplicate IPs": 0, "Unsupported": 0, "Supported": 0}
    current_date = str(date.today())
    current_year = int(current_date[0:4])
    current_month = int(current_date[5:7])
    current_day = int(current_date[8:])
    
    # Loop through the columns and check the status, warranty, and discontinued 
    for i in range(len(columns["Status"])):
        if (columns["Status"][i] == "Reachable" or columns["Status"][i] == "Reachable on Network"):
            bucket["Reachable on Network"] += 1
        else:
            bucket["Unreachable"] += 1
        if(columns["Warranty"][i] == "No date set"):
            bucket["Warranty is Good"] += 1
        else:
            war_year = int(columns["Warranty"][i][0:4])
            war_month = int(columns["Warranty"][i][5:7])
            war_day = int(columns["Warranty"][i][8:])
            if(war_year < current_year):
                bucket["Warrranty is Out of Date"] += 1
            elif(war_year == current_year and war_month <= current_month):
                bucket["Warrranty is Out of Date"] += 1
            # Near outdate is 6 months out
            elif((12*(war_year - current_year) + war_month) - (current_month) <= 6):
                bucket["Warranty is Near Date"] += 1
            else:
                bucket["Warranty is Good"] += 1
        val = (columns["Discontinued date"][i] or "").strip().lower()

        if val in ("orderable", "supported"):
            bucket["Supported"] += 1
        else:
            bucket["Unsupported"] += 1


    # Check for Duplicate IPs from the cameras 
    for i in range(len(columns["IP"])):
        for j in range(len(columns["IP"])// 2):
            if (i != j and columns["IP"][i] == columns["IP"][j]):
                bucket["Duplicate IPs"] += 1
    print("Bucket: ")
    print(bucket)
    return bucket 

#Get Custom Input from Users
def custom_site():
    name = ""
    csv_path = ""
    spreadsheet_id = ""

    #
    answering = True 
    while(answering):
        name = input("Please enter a site name: ").strip()
        # Regex: letters, numbers, spaces, hyphens, underscores
        if re.fullmatch(r"[A-Za-z0-9 _-]+", name):
            print("Valid site name:", name)
            answering = False
        else:
            print("Please Enter a valid string.")

    answering = True 
    while(answering):
        reference_path = input("Please enter a reference_path: ").strip()
        # Regex: letters, numbers, periods, slashs
        reference_regex = r"^[A-Za-z0-9/_\-\. ]+\.?$"
        if re.fullmatch(reference_regex, reference_path):
            print("Valid path:", reference_path)
            answering = False
        else:
            print("Please Enter a valid string.")
   
    spreadsheet_id = input("Please enter the spreadsheet ID: ").strip()


    cus_site = Site(name, reference_path, spreadsheet_id)
    cus_site.print_site()
    return cus_site

#Allow user to select a site or enter a custom one 
def user_input():
    print("\n=== Site Selection ===\n")
    print("Before running this application, please confirm the following:")
    print("")
    print("1) ONE of the following data sources is prepared:")
    print("   - A complete CSV export from the target site using ADMX")
    print("   - OR the script 'vapix_scrapper.sh' has been executed for the site, on each server")
    print("")
    print("2) The output from step (1) has been copied to the Support Utility server:")
    print("   Server: 192.168.2.70")
    print("   Path:   /opt/API_Integration/sites/<site_name>/")
    print("")
    print("3) The <site_name> directory name MUST match the site selection below")
    print("")
    print("If these steps are complete, select a site from the list below.\n")
    global SITE
    sites=[
        Site(
            "test", 
            "/opt/API_Integration/sites/primary/", 
            "1m06CDhoiWHjZ1PbkAm8FG9KZCFBu0wbkvc2mu6xKt_U",
        ),
        Site(
            "St Bern",  
            "/opt/API_Integration/sites/St/", 
            "1crpDyL02zgnUGU69SB_mRcb5_pLKkzRzJnJwdt4M0QA",
        ),
        Site(
            "Clinton Massie",
            "/opt/API_Integration/sites/clinton-massie/",
            "1iFVvgtpcRUcmIRsylpAX9Kf2FmUQZzaxKfu7aba3xzg"
        ),
        Site(
            "Trumbull County",
            "/opt/API_Integration/sites/trumble/",
            "1iu-LnZwkzZuTOPav3sQfbVBRRx54w9034Ugy7TbylJE"
        ),
        Site(
            "Shadyside",
            "/opt/API_Integration/sites/shadyside/",
            "1mbym0BjyVV-Q8AM8hdVoUkaBlLoePkynjtXYhtvAG0o"
        ),
        Site(
            "Buffalo ",
            "/opt/API_Integration/sites/buffalo-akg/",
            "1o1v0Zk9BCfyFgifb8yP-qBVve2DkVt8PVKTxOWeuJjo"
        ),
        Site(
            "Delaware",
            "/opt/API_Integration/sites/delaware/",
            "1Uo8qs7RwXBuOv7TO6VnhHgefAI_TKS5hyZoOLB-ndCY"
        ),
        Site(
            "Norton Museum of Art",
            "/opt/API_Integration/sites/nortonMOA/",
            "1sP8vhmA8RI1tl5-pjTAwB_-eA4KdLFhvlzTSQPdwgjQ"
        ),
        Site(
            "Beloved",
            "/opt/API_Integration/sites/beloved",
            "1l7b0xfLec8jjrpAw6kdz3QrjV5bpzdIRhCuJtNg5_4c"
        ),
        Site(
            "",
            "/opt/API_Integration/sites/",
            ""
        ),
        Site(
            "Custom",  
            "Enter a Custom path to reference files", 
            "Enter a Custom sheet id",
        )
        
    ]
    answering = True 
    while(answering):
        for i in sites: i.print_site()
        choice = input("Please select a customer site: ").strip()
        for i in sites:
            if(i.name == choice):
                answering = False 
                if(i.name == "Custom"):
                    SITE = custom_site()
                else:
                    SITE = i
                break
        if(answering == True):
            print("Please select a valid input form the list.")


# Fucntion Loads all columns from the spread sheet into a workable list of lists in memory 
# Input is the path to the csv file
# Returns a dic of lists with each list being the values of the colums and named by the column header as the key
def load_columns_as_lists(csv_path_admx):
    print("Load Columns As List Executed")
    if not os.path.exists(csv_path_admx):
        raise FileNotFoundError(f"CSV file not found: {csv_path_admx}")

    with open(csv_path_admx, newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)

        # First row: column names
        try:
            headers = next(reader)
        except StopIteration:
            raise ValueError("CSV file is empty")

        # Initialize a list for each column
        columns = {header: [] for header in headers}

        # Fill the lists
        for row in reader:
            # Handle rows that might be shorter than headers
            for i, header in enumerate(headers):
                value = row[i] if i < len(row) else ""
                columns[header].append(value)

    del_column_names = {"Name", "Hostname", "Folder", "UPnP name", "Apps"}
    for i in del_column_names:
      del columns[i]
    return columns

# Function to find SHEET_ID
# Will retrun the numeric value for the SHEET_ID 
def get_sheet_id_by_name(service, spreadsheet_id, tab_name):
    meta = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    for s in meta["sheets"]:
        props = s["properties"]
        if props["title"] == tab_name:
            return props["sheetId"]
    raise ValueError(f"Tab '{tab_name}' not found")


def _parse_vapix_text(text: str, dedupe_by_ip: bool = True):
    columns = {
        "Model": [], "Status": [], "IP": [], "Mac/Sn": [],
        "Software": [], "Warranty": [], "Discontinued date": [],
    }

    blocks = re.split(r"(?m)^\s*-{3,}\s*$", text.strip())
    seen_ips = set()

    for blk in blocks:
        blk = blk.strip()
        if not blk:
            continue

        m = re.search(r"(?m)^\s*IP:\s*([0-9]{1,3}(?:\.[0-9]{1,3}){3})\s*$", blk)
        ip = m.group(1) if m else ""

        if dedupe_by_ip and ip and ip in seen_ips:
            continue

        # ✅ robust JSON decode (handles nested braces)
        payload = None
        start = blk.find("{")
        if start != -1:
            try:
                payload, _ = json.JSONDecoder().raw_decode(blk[start:])
            except json.JSONDecodeError:
                payload = None

        status = "Unreachable"
        model = ""
        serial = ""
        version = ""

        if payload:
            props = (payload.get("data") or {}).get("propertyList") or {}
            model = props.get("ProdShortName") or props.get("ProdNbr") or props.get("ProdFullName") or ""
            serial = props.get("SerialNumber", "") or ""
            version = props.get("Version", "") or ""
            status = "Unreachable" if serial == "UNREACHABLE" else "Reachable on Network"

        columns["Model"].append(model)
        columns["Status"].append(status)
        columns["IP"].append(ip)
        columns["Mac/Sn"].append(serial)
        columns["Software"].append(version)
        columns["Warranty"].append("No date set")
        columns["Discontinued date"].append("Not Supported" if version.startswith("5.") else "Supported")

        if ip:
            seen_ips.add(ip)

    return columns


#Funciton that will go through the site summary workbook and ping out each camera with vapix commands 
def vapix_output_to_column_list(dedupe_by_ip=True):
    print("Vapix to Column List Executed")
    
    """
    If site.reference_path is a file: parse it.
    If it's a directory: parse all .txt/.log/.json/.out files inside (non-recursive).
    Returns columns dict for downstream logic.
    """

    path = SITE.reference_path

    if os.path.isdir(path):
        combined = []
        for fn in sorted(os.listdir(path)):
            full = os.path.join(path, fn)
            if not os.path.isfile(full):
                continue
            if not fn.lower().endswith((".txt", ".log", ".out", ".json")):
                continue
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                combined.append(f.read())
        text = "\n----------\n".join(combined)
        return _parse_vapix_text(text, dedupe_by_ip=dedupe_by_ip)

    if not os.path.exists(path):
        raise FileNotFoundError(f"VAPIX output file/folder not found: {path}")

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return _parse_vapix_text(f.read(), dedupe_by_ip=dedupe_by_ip)

#Function that will take a CSV path to a sites workbook and get that information into memory 
# Only for Axis cameras, will skip all others 
# Will return a dictionary or matrix of string or strings 
def load_axis_cams(CSV_PATH_WORKBOOK):
    if not os.path.exists(CSV_PATH_WORKBOOK):
        raise FileNotFoundError(f"CSV file not found: {CSV_PATH_WORKBOOK}")
    KEEP = {"MFG", "Model", "Model", "Model ", "MAC Address", "Mac Address", "IP Address", "Username", "Password", "Server"}

    with open(CSV_PATH_WORKBOOK, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        # normalize headers (strip)
        reader.fieldnames = [h.strip() for h in reader.fieldnames]

        rows = []
        for r in reader:
            # normalize keys too
            r = {k.strip(): (v or "").strip() for k, v in r.items()}

            if r.get("MFG", "").lower() != "axis":
                continue

            ip = r.get("IP Address", "")
            if not ip:
                continue

            rows.append({
                "ip": ip,
                "user": r.get("Username", "root") or "root",
                "pass": r.get("Password", ""),
                "model": r.get("Model", "") or r.get("Model", ""),
                "server": r.get("Server", ""),
                "mac": r.get("MAC Address", "") or r.get("Mac Address", ""),
            })
        return rows

def main():

    #------- Get User Input For Correct Sheet ----------------------------------------------
    user_input()
    SITE.print_site()

    #if REFERENCE_PATH ends with csv 
    if Path(SITE.reference_path).suffix.lower() == ".csv":
        #------- CSV → columns in memory -------------------------------------------------------
        columns = load_columns_as_lists(SITE.reference_path)
        print("Using the csv file")
    #if REFERENCE_PATH ends into a reference folder  
    else:
        #------- txt → columns in memory -------------------------------------------------------
        columns = vapix_output_to_column_list(dedupe_by_ip=True)
        print("Using the vapix output")
    # Create variables in the global scope with the header names
    for name, values in columns.items():
        safe_name = name.strip().replace(" ", "_")
        globals()[safe_name] = values
        # print(f"Created list variable: {safe_name} (length: {len(values)})")

    # Rebuild rows (including header row) for Google Sheets
    headers = list(columns.keys())
    num_rows = len(next(iter(columns.values())))  # number of data rows

    values = [headers]  # first row = headers
    for i in range(num_rows):
        row = [columns[h][i] for h in headers]
        values.append(row)

    #------- OAuth / Sheets API ------------------------------------------------------------
    creds = None

    # If token.json already exists, load it
    if os.path.exists("token.json"):
        creds = Credentials.from_authorized_user_file("token.json", SITE.scope)

    # If no valid creds, run the browser-based flow
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                "credentials.json", SITE.scope
            )
            creds = flow.run_local_server(port=0)

        # Save the credentials for next time
        with open("token.json", "w") as token:
            token.write(creds.to_json())

    print("token.json created/updated successfully.")

    service = build("sheets", "v4", credentials=creds)

    body = {"values": values}

    #------- Print to Sheet -----------------------------------------------------------------
    result = service.spreadsheets().values().update(
        spreadsheetId=SITE.spreadsheet_id,
        range=RANGE_NAME,
        valueInputOption="RAW",
        body=body
    ).execute()

  
    print("body = ")
    print(body)


    #------- Call function to create buckets ------------------------------------------------
    bucket = graph_bucket(columns)

    #------- Create Graphs and Charts -------------------------------------------------------
    
    rows = [["Status", "Count"]] + [[k, v] for k, v in bucket.items()]

    # Write bucket table to M7 (columns M and N)
    service.spreadsheets().values().update(
        spreadsheetId=SITE.spreadsheet_id,
        range=BUCKET_RANGE,
        valueInputOption="USER_ENTERED",
        body={"values": rows}
    ).execute()

    # range geometry for the chart
    num_rows = len(rows)              # header + items
    start_row = 11                    # A1 row index 0
    end_row = num_rows + start_row    # exclusive
    domain_col = 12                   # column M
    series_col = 13                   # column N
    # Online: rows 13-14 => indices 12..14
    ONLINE_START = 12
    ONLINE_END   = 14

    # Warranty: rows 15-17 => indices 14..17
    WARRANTY_START = 14
    WARRANTY_END   = 17
    # Support: rows 19-20 => indices 18..20
    SUPPORT_START = 18
    SUPPORT_END   = 20
    SHEET_ID = get_sheet_id_by_name(service, SITE.spreadsheet_id, "AxisCameras")

    chart_request = {
        "requests": [
            {
                "addChart": {
                    "chart": {
                        "spec": {
                            "title": "Axis Camera Status",
                            "pieChart": {
                                "legendPosition": "RIGHT_LEGEND",
                                "domain": {
                                    "sourceRange": {
                                        "sources": [{
                                            "sheetId": SHEET_ID,
                                            "startRowIndex": ONLINE_START,
                                            "endRowIndex": ONLINE_END,
                                            "startColumnIndex": domain_col,
                                            "endColumnIndex": domain_col + 1
                                        }]
                                    }
                                },
                                "series": {
                                    "sourceRange": {
                                        "sources": [{
                                            "sheetId": SHEET_ID,
                                            "startRowIndex": ONLINE_START,
                                            "endRowIndex": ONLINE_END,
                                            "startColumnIndex": series_col,
                                            "endColumnIndex": series_col + 1
                                        }]
                                    }
                                }
                            }
                        },
                        "position": {
                            "overlayPosition": {
                                "anchorCell": {"sheetId": SHEET_ID, "rowIndex": 0, "columnIndex": 0},
                                "widthPixels": 300,
                                "heightPixels": 200
                            }
                        }
                    }
                }
            },
            {
              "addChart": {
                "chart": {
                  "spec": {
                    "title": "EOM Support Status",
                    "pieChart": {
                      "legendPosition": "RIGHT_LEGEND",
                      "domain": {
                        "sourceRange": {
                          "sources": [{
                            "sheetId": SHEET_ID,
                            "startRowIndex": SUPPORT_START,
                            "endRowIndex": SUPPORT_END,
                            "startColumnIndex": domain_col,
                            "endColumnIndex": domain_col + 1
                          }]
                        }
                      },
                      "series": {
                        "sourceRange": {
                          "sources": [{
                            "sheetId": SHEET_ID,
                            "startRowIndex": SUPPORT_START,
                            "endRowIndex": SUPPORT_END,
                            "startColumnIndex": series_col,
                            "endColumnIndex": series_col + 1
                          }]
                        }
                      },
                    }
                  },
                  "position": {
                    "overlayPosition": {
                      "anchorCell": {"sheetId": SHEET_ID, "rowIndex": 0, "columnIndex": 3},
                      "widthPixels": 300,
                      "heightPixels": 200
                    }
                  }
                }
              }
            }
            
        ]
    }


    body_chart = chart_request
    resp = service.spreadsheets().batchUpdate(
        spreadsheetId=SITE.spreadsheet_id,
        body=chart_request
    ).execute()

    print("Chart added. Response:", resp)


    #------- Print out if there are any duplicate IPs to a warning on the sheet 
    if(bucket["Duplicate IPs"] != 0):
        body={
            "values" :
            [
                ["Duplicate IPs found"]
            ]
        }
        result = service.spreadsheets().values().update(
            spreadsheetId=SITE.spreadsheet_id,
            range="AxisCameras!A11",
            valueInputOption="RAW",
            body=body
        ).execute()

    """
    This is how the bodu will be read to convert into the sheet
    {
      "values": [
        ["row1-col1", "row1-col2", ...],
        ["row2-col1", "row2-col2", ...]
      ]
    }
    
    body = {
      "values" : 
        [
            ["Model", "Status", "IP", "Mac/Sn", "Software", "WAranty", "Dsicontinued date"]
        ]
    }

    result = service.spreadsheets().values().update(
        spreadsheetId=SITE.spreadsheet_id,
        range=RANGE_NAME,
        valueInputOption="RAW",
        body=body
    ).execute()
    """
    #------- highlight that same row yellow -------------------------------------------------
    sheet_name = RANGE_NAME.split("!")[0]   # "AxisCameras"
    start_cell = RANGE_NAME.split("!")[1]   # "A7"
    
    # Get numeric sheetId automatically
    meta = service.spreadsheets().get(
        spreadsheetId=SITE.spreadsheet_id,
        fields="sheets(properties(sheetId,title))"
    ).execute()
    
    sheet_id = None
    for s in meta["sheets"]:
        if s["properties"]["title"] == sheet_name:
            sheet_id = s["properties"]["sheetId"]
            break
    if sheet_id is None:
        raise ValueError(f"Sheet '{sheet_name}' not found")
    # Convert "A7" -> row index 6 (0-based)
    row_number = int(''.join(ch for ch in start_cell if ch.isdigit()))
    start_row_index = row_number - 1
    end_row_index = row_number
    
    format_body = {
        "requests": [
            {
                "repeatCell": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": start_row_index,
                        "endRowIndex": end_row_index
                        # no columns => whole row gets color
                    },
                    "cell": {
                        "userEnteredFormat": {
                            "backgroundColor": {
                                "red": 1.0,
                                "green": 1.0,
                                "blue": 0.0
                            }
                        }
                    },
                    "fields": "userEnteredFormat.backgroundColor"
                }
            }
        ]
    }
    
    service.spreadsheets().batchUpdate(
        spreadsheetId=SITE.spreadsheet_id,
        body=format_body
    ).execute()

    print(f"{result.get('updatedCells')} cells updated.")

if __name__ == "__main__":
    main()
