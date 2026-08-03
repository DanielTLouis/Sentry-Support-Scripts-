#Server Health Report Python Script
#By Daniel
#Created 06/15/2026

from shutil import which
from importlib.util import find_spec
from pathlib import Path
import sys
import subprocess
from datetime import datetime
import socket
import os
import json

"""
function: is_installed 
prereq: String with the service name to check if it is installed 
returns: a boolean (true for installed, false for missing)
Use: Will check if a serice is installed on the host machine and return a boolean indicated if it is 
"""
def is_installed(name):
    if(name == "storcli"):
        if(Path("/opt/MegaRAID/storcli/storcli64").exists()):
            return True
        else:
            return False
    else:
        #"Check if the path exists for the name"
        return which(name) is not None

"""
function: cleanup
prereq: No arguments. Requires sufficient privileges to remove installed
        packages and delete files from the local system.
returns: None.
Use: Prompts the user for confirmation before removing files and packages
     installed by this script, including StorCLI, IPMItool, downloaded
     installation files, and the Server_Health_Report.py script itself.
     Generated health reports located in the backup directory are preserved.
"""
def cleanup():
    print("This will remove installed and downloaded material as well as this script.../nDo you want to continue: y/N")
    looping=True
    while(looping):
        result=input()
        if(result == "y"):
            print("Removing Files and Packages")
            subprocess.run(["rm", "-r", "storcli_rel"])
            subprocess.run(["rm", "-r", "Unified_storcli_all_os"])
            subprocess.run(["rm", "-r", "007.2705.0000.0000_storcli_rel.zip"])
            subprocess.run(["rm", "-r", "Server_Health_Report.py"])
            subprocess.run(["zypper", "remove", "storcli"])
            subprocess.run(["rm", "-f", "/usr/local/bin/storcli"])
            subprocess.run(["rm", "-rf", "/opt/MegaRAID/storcli"])
            subprocess.run(["zypper", "remove", "ipmitool"])
            print("Insalled Items have been removed. Generated reports remain...")
            looping = False
        elif(result == "N"):
            print("Returning to Selection...")
            return
        else:
            print("Please enter a valid choice, y for yes or N for No")


"""
function: generate_report
prereq: Requires storcli, ipmitool, and access to hardware/IPMI data.
returns: None. Generates a server health report file.
Use: Collects RAID, IPMI sensor, SEL, chassis, BMC, and FRU data, stores it in
     a report dictionary, and passes it to jason_to_Sentry_Care_report() to
     create the final Sentry Care text report.
"""
def generate_report():
    print("Generating Report...")
    result_raid = subprocess.run(
        ["storcli", "/call", "show", "all", "J"],
        capture_output=True, 
        text=True
    )
    if result_raid.returncode == 0 and result_raid.stdout.strip():
        storcli_data = json.loads(result_raid.stdout)
    else:
        storcli_data = {
            "error": "StorCLI check failed",
            "stderr": result_raid.stderr
        }
    report = {
        "ipmi_sensors": ipmi_sensor_to_json(),
        "ipmi_sel_list" : ipmi_sel_list_to_json(),
        "ipmi_chassis_status" : ipmi_chassis_status_to_json(),
        "ipmi_mc_info" : ipmi_mc_info_to_json(),
        "ipmi_fru" : ipmi_fru_to_json(),
        "storcli": storcli_data,
        "physical_drive_serials": get_physical_drive_serials(),
    }

    ##TODO df -h output !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    #print(json.dumps(report, indent=2))
    #with open("server_health_report.json", "w") as f:
    #    json.dump(report, f, indent=2)

    jason_to_Sentry_Care_report(report)
    
"""
function: find_value_by_key
prereq: Requires a JSON-compatible Python object (dictionary or list) and
        a collection of target key names to search for.
returns: The value associated with the first matching key encountered during
         the recursive search. Returns None if no matching key is found.
Use: Recursively traverses nested dictionaries and lists to locate a value
     whose key matches one of the specified target names. Used to extract
     information such as drive serial numbers from StorCLI JSON output when
     the desired field may appear at different nesting levels depending on
     controller model or firmware version.
"""
def find_value_by_key(obj, wanted_keys):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key.strip().lower() in wanted_keys:
                return value

            found = find_value_by_key(value, wanted_keys)
            if found:
                return found

    elif isinstance(obj, list):
        for item in obj:
            found = find_value_by_key(item, wanted_keys)
            if found:
                return found

    return None

"""
function: get_physical_drive_serials
prereq: Requires StorCLI to be installed and accessible. The system must
        contain a supported RAID controller and physical drives that can be
        queried through the StorCLI utility.
returns: A dictionary indexed by physical drive enclosure and slot (EID:Slt).
         Each entry contains the enclosure ID, slot number, drive model,
         and serial number. Returns an error dictionary if the drive list
         cannot be retrieved or parsed.
Use: Queries StorCLI for all detected physical drives, retrieves detailed
     information for each drive, extracts the serial number and model, and
     returns the data in a JSON-compatible dictionary for use in report
     generation and physical drive inventory.
"""
def get_physical_drive_serials():
    drives = {}

    result = subprocess.run(
        ["storcli", "/c0", "/eall", "/sall", "show", "J"],
        capture_output=True,
        text=True
    )

    if result.returncode != 0 or not result.stdout.strip():
        return {
            "error": "Failed to get physical drive list",
            "stderr": result.stderr
        }

    try:
        data = json.loads(result.stdout)
        controllers = data.get("Controllers", [])
        drive_rows = controllers[0]["Response Data"].get("Drive Information", [])
    except Exception as e:
        return {
            "error": f"Failed to parse physical drive list: {e}"
        }

    for drive in drive_rows:
        eid_slt = drive.get("EID:Slt")
        model = drive.get("Model")

        if not eid_slt or ":" not in eid_slt:
            continue

        eid, slot = eid_slt.split(":", 1)

        detail_result = subprocess.run(
            ["storcli", f"/c0/e{eid}/s{slot}", "show", "all", "J"],
            capture_output=True,
            text=True
        )

        serial_number = None

        if detail_result.returncode == 0 and detail_result.stdout.strip():
            try:
                detail_data = json.loads(detail_result.stdout)
                response_data = detail_data["Controllers"][0].get("Response Data", {})

                serial_number = find_value_by_key(
                    response_data,
                    {"sn", "serial number", "serial no", "serialnumber"}
                )

                if not serial_number:
                    inquiry_data = find_value_by_key(response_data, {"inquiry data"})

                    if inquiry_data:
                        parts = str(inquiry_data).split()
                        if parts:
                            serial_number = parts[-1]

            except Exception as e:
                serial_number = f"Failed to parse detail output: {e}"

        drives[eid_slt] = {
            "eid": eid,
            "slot": slot,
            "model": model,
            "serial_number": serial_number or "Not found"
        }

    return drives

"""
function: jason_to_Sentry_Care_report
prereq: Requires a populated report dictionary generated by generate_report().
        Requires write access to /home/vcs/backups and access to system serial
        number information through IPMI FRU data or dmidecode.
returns: None. Creates a formatted text report on disk.
Use: Generates a Sentry Care compatible health report by extracting server
     identification information, creating a dated backup directory, analyzing
     hardware alerts and events, and writing chassis, storage controller,
     disk, and ESM health information to a text file named after the system
     serial number.
"""
def jason_to_Sentry_Care_report(report):
    date_dir = datetime.now().strftime("%B-%Y")
    subprocess.run(["mkdir", "-p", "/home/vcs/backups/"+date_dir])

    # Try to get serial from FRU data
    serial_number = "Unknown"
    for fru in report.get("ipmi_fru", []):
        if "product_serial" in fru:
            serial_number = fru["product_serial"]
            break
    if(serial_number == "Unknown"):
        try:
            serial_number = subprocess.run(
                ["dmidecode", "-s", "system-serial-number"], 
                capture_output=True, 
                text=True
            ).stdout.strip()
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            print("Unable to ubtain serial number")
            serial_number = "Unkown"

    bu_dir = f"/home/vcs/backups/{date_dir}"
    os.makedirs(bu_dir.replace(" ", ""), exist_ok=True)

    filename = f"{bu_dir}/omreport_{serial_number}.txt"

    with open(filename, "w") as f:
        f.write("####################\n")
        f.write(f"       {serial_number}\n")
        f.write("####################\n\n")

        f.write("####################\n")
        f.write("     Alert Log\n")
        f.write("####################\n\n")

        for event in report.get("ipmi_sel_list", []): 
            severity = "Ok" 
            text = ( 
                f"{event.get('sensor','')} " 
                f"{event.get('event','')} " 
                f"{event.get('state','')}" 
            ) 
            if any(word in text.lower() for word in ["critical", "failure", "fault", "error", "failed"]): 
                severity = "Critical" 
            elif any(word in text.lower() for word in ["warning", "predictive"]): 
                severity = "Non-Critical" 
            if(severity != "Ok"):
                f.write(f"Severity : {severity}\n") 
                f.write(f"Description : {text}\n\n")
        esm_log_printout(report, f)
        chassis_report_printout(report, f)  
        storage_controller_report_printout(report, f)
        disk_report_printout(report, f)
        
    print(f"Text report saved to {filename}")
    subprocess.run(["less", filename])


"""
function: esm_log_printout
prereq: Requires a report dictionary containing an "ipmi_sel_list" key and
        an open writable file object.
returns: None. Writes formatted ESM log entries to the report file.
Use: Formats and writes IPMI System Event Log (SEL) entries to the report.
     Events are analyzed for severity based on keywords and displayed with
     their timestamp, severity level, and event description in a readable
     ESM log section.
"""
def esm_log_printout(report, f):
    f.write("\n####################\n")
    f.write("      ESM Log\n")
    f.write("####################\n\n")

    events = report.get("ipmi_sel_list", [])

    if not events:
        f.write("No ESM events found.\n")
        return

    for event in events:
        severity = "Ok"

        text = (
            f"{event.get('sensor', '')} "
            f"{event.get('event', '')} "
            f"{event.get('state', '')}"
        )

        text_lower = text.lower()

        if any(word in text_lower for word in [
            "critical",
            "failure",
            "fault",
            "failed",
            "error"
        ]):
            severity = "Critical"

        elif any(word in text_lower for word in [
            "warning",
            "predictive"
        ]):
            severity = "Non-Critical"

        f.write(
            f"{event.get('date','')} "
            f"{event.get('time','')} | "
            f"{severity:<12} | "
            f"{text}\n"
        )

"""
function: chassis_report_printout
prereq: Requires a populated report dictionary containing IPMI sensor data,
        chassis status information, SEL events, and StorCLI controller data.
        Requires an open writable file object.
returns: None. Writes chassis health information to the report file.
Use: Generates the Chassis Report section of the Sentry Care report by
     evaluating the health of major hardware subsystems including fans,
     intrusion detection, memory, power supplies, power management,
     processors, temperatures, voltages, hardware logs, and RAID battery
     systems. Each component is assigned an OK, NON-CRITICAL, CRITICAL,
     or UNKNOWN status and written to the report in a summary format.
"""
def chassis_report_printout(report, f):
    f.write("\n####################\n")
    f.write("   Chassis Report\n")
    f.write("####################\n\n")
    f.write("\nHealth \nMain System Chassis\n\n")
    f.write("Severity    " + " : Component\n")

    chassis = report["ipmi_sensors"]
    
    #--- FANS --------------------------
    fan_status = "OK"
    for sensor in report["ipmi_sensors"]:
        if "fan" in sensor["name"].lower() and "redundancy" not in sensor["name"].lower():
            if sensor["status"].lower() != "ok":
                fan_status = sensor["status"]
                if fan_status.lower() == "critical":
                    break 
    f.write(f"{fan_status.upper():<12} : Fans\n")

    #--- Intrusion --------------------------
    intrusion_status = "UNKNOWN"

    for item in report.get("ipmi_chassis_status", []):
        key = item.get("record_id", "").lower()
        value = item.get("status", "").lower()

        if "intrusion" in key:
            if value in ["inactive", "false", "no", "none", "ok", "normal"]:
                intrusion_status = "OK"
            elif value in ["active", "true", "yes", "detected", "asserted"]:
                intrusion_status = "CRITICAL"
            break

    f.write(f"{intrusion_status.upper():<12} : Intrusion\n")

    #--- Memory --------------------------
    memory_status = "OK"
    for sensor in report["ipmi_sensors"]:
        if "DIMM" in sensor["name"].upper():
            if sensor["status"].lower() != "ok" and "0x0180" not in sensor["status"].lower():
                memory_status = sensor["status"]        
    f.write(f"{memory_status.upper():<12} : Memory\n")

    #--- Power Supplies --------------------------
    power_status = "UNKNOWN"
    psu_sensors = []
    for sensor in report.get("ipmi_sensors", []):
        name = sensor.get("name", "").lower()
        
        if any(term in name for term in [
            "psu", "power supply", "pwr supply", "pwr", "ps "
        ]):
            psu_sensors.append(sensor)

    if psu_sensors:
        power_status = "OK"

        for sensor in psu_sensors:
            status = str(sensor.get("status", "")).lower()
            state = str(sensor.get("state", "")).lower()
            value = f"{status} {state}"

            if any(bad in value for bad in [
                "critical",
                "failed",
                "failure",
                "not present",
                "absent",
                "lost",
                "asserted"
            ]):
                power_status = "CRITICAL"
                break

            elif any(warn in value for warn in [
                "warning",
                "non-critical",
                "degraded"
            ]):
                power_status = "NON-CRITICAL"
    f.write(f"{power_status:<12} : Power Supplies\n")

    #--- Power Management --------------------------

    power_sensors = []

    keywords = [
        "power management",
        "power unit",
        "power redundancy",
        "power control",
        "power consumption",
        "power cap",
        "power state",
    ]

    for sensor in report.get("ipmi_sensors", []):
        name = sensor.get("name", "").lower()

        if any(keyword in name for keyword in keywords):
            power_sensors.append(sensor)

    if not power_sensors:
        power_status = "UNKNOWN"

    else:
        power_status = "OK"

        for sensor in power_sensors:
            combined = " ".join(
                str(sensor.get(key, "")).lower()
                for key in ["status", "state", "reading", "value", "health"]
            )

            if any(term in combined for term in [
                "critical",
                "failed",
                "failure",
                "lost",
                "exceeded",
                "asserted",
                "fault",
            ]):
                power_status = "CRITICAL"
                break

            if any(term in combined for term in [
                "warning",
                "non-critical",
                "degraded",
                "redundancy lost",
                "limit",
            ]):
                power_status = "NON-CRITICAL"
    f.write(f"{power_status:<12} : Power Management\n")

    #--- Processors --------------------------
    processor_status = "UNKNOWN"

    processor_sensors = [
        sensor for sensor in report.get("ipmi_sensors", [])
        if any(term in sensor.get("name", "").lower()
               for term in ["processor", "cpu"])
    ]

    if processor_sensors:
        processor_status = "OK"

        for sensor in processor_sensors:
            status = str(sensor.get("status", "")).lower()
            state = str(sensor.get("state", "")).lower()

            combined = f"{status} {state}"

            if any(x in combined for x in [
                "failed", "failure", "fault",
                "missing", "disabled",
                "critical", "overtemp"
            ]):
                processor_status = "CRITICAL"
                break

            if any(x in combined for x in [
                "warning", "non-critical",
                "throttled", "degraded"
            ]):
                processor_status = "NON-CRITICAL"
    f.write(f"{processor_status:<12} : Processor\n")


    #--- Temperatures --------------------------
    temp_sensors = [
        s for s in report.get("ipmi_sensors", [])
        if "temp" in s.get("name", "").lower()
    ]

    if not temp_sensors:
        temp_status = "UNKNOWN"
    else:

        temp_status = "OK"

        for sensor in temp_sensors:
            status = str(sensor.get("status", "")).lower()

            if any(x in status for x in [
                "critical", "cr", "nr", "failed"
            ]):
                temp_status = "CRITICAL"
                break

            if any(x in status for x in [
                "warning", "non-critical", "nc"
            ]):
                temp_status = "NON-CRITICAL"
    f.write(f"{temp_status:<12} : Temperatures\n")

    #--- Voltages --------------------------
    volt_status = "OK"
    found_voltage = False

    voltage_keywords = [
        "volt",
        "vcore",
        "vbat",
        "3.3v",
        "5v",
        "12v",
        "dimm v",
    ]

    for sensor in report.get("ipmi_sensors", []):
        name = sensor.get("name", "").lower()
        unit = sensor.get("unit", "").lower()

        if not (
            "volts" in unit
            or "volt" in unit
            or any(keyword in name for keyword in voltage_keywords)
        ):
            continue

        found_voltage = True

        combined = " ".join(
            str(sensor.get(key, "")).lower()
            for key in ["status", "state", "reading", "value", "health"]
        )

        if any(x in combined for x in [
            "critical",
            "cr",
            "nr",
            "failed",
            "failure",
            "fault",
            "non-recoverable",
        ]):
            volt_status = "CRITICAL"
            break

        if any(x in combined for x in [
            "warning",
            "non-critical",
            "nc",
            "degraded",
        ]):
            volt_status = "NON-CRITICAL"
    f.write(f"{volt_status:<12} : Voltages\n")

    #--- Hardware Log --------------------------
    events = report.get("ipmi_sel_list", [])
    hardwareLog_status = "OK"

    for event in events:
        combined = " ".join(
            str(event.get(key, "")).lower()
            for key in ["sensor", "event", "state","severity", "status", "event", "description", "sensor_type", "message"]
        )

        if any(term in combined for term in [
            "critical",
            "non-recoverable",
            "fatal",
            "uncorrectable",
            "failed",
            "failure",
            "fault",
        ]):
            hardwareLog_status = "CRITICAL"
            break

        if any(term in combined for term in [
            "warning",
            "non-critical",
            "correctable",
            "degraded",
            "threshold",
        ]):
            hardwareLog_status = "NON-CRITICAL"
    f.write(f"{hardwareLog_status:<12} : Hardware Log\n")

    #--- Batteries --------------------------
    batteries = []

    # Walk the JSON looking for battery-related entries
    def find_batteries(obj):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if any(term in key.lower() for term in [
                    "battery",
                    "bbu",
                    "cvpm",
                    "cachevault"
                ]):
                    batteries.append(value)
                find_batteries(value)

        elif isinstance(obj, list):
            for item in obj:
                find_batteries(item)

    find_batteries(report["storcli"])

    if not batteries:
        batteries_status =  "UNKNOWN"
    else: 
        batteries_status = "OK"

        for battery in batteries:
            text = str(battery).lower()

            if any(term in text for term in [
                "failed",
                "fault",
                "replace",
                "missing",
                "bad"
            ]):
                batteries_status = "CRITICAL"
                break

            if any(term in text for term in [
                "charging",
                "learn",
                "degraded",
                "warning"
            ]):
                batteries_status = "NON-CRITICAL"
    for event in report.get("ipmi_sel_list", []):
        text = " ".join([
            event.get("sensor", ""),
            event.get("event", ""),
            event.get("state", "")
        ]).lower()

        if "battery" in text and "failed" in text and "asserted" in text:
            batteries_status = "CRITICAL"
            break
    f.write(f"{batteries_status:<12} : Batteries\n")

"""
function: storage_controller_report_printout
prereq: Requires a populated report dictionary containing StorCLI controller
        data and an open writable file object.
returns: None. Writes storage controller information to the report file.
Use: Generates the Storage Controller Report section of the Sentry Care
     report. Extracts controller details such as model, serial number,
     firmware version, and controller status from StorCLI data, then
     evaluates overall controller health as OK, NON-CRITICAL, CRITICAL,
     or UNKNOWN and records the results in the report.
"""
def storage_controller_report_printout(report, f):
    f.write("\n####################\n")
    f.write(" Storage Controller Report\n")
    f.write("####################\n\n")

    storcli = report.get("storcli", {})
    controllers = storcli.get("Controllers", [])

    if not controllers:
        f.write("No storage controllers found.\n")
        return

    for controller in controllers:
        response = controller.get("Response Data", {})
        basics = response.get("Basics", {})
        status = response.get("Status", {})
        version = response.get("Version", {})

        controller_id = controller.get("Command Status", {}).get("Controller", "Unknown")
        model = basics.get("Model", "Unknown")
        serial = basics.get("Serial Number", "Unknown")
        fw = version.get("Firmware Version", "Unknown")
        state = status.get("Controller Status", "Unknown")

        f.write(f"Controller ID        : {controller_id}\n")
        f.write(f"Model                : {model}\n")
        f.write(f"Serial Number        : {serial}\n")
        f.write(f"Firmware Version     : {fw}\n")
        f.write(f"Controller Status    : {state}\n")

        if str(state).lower() in ["optimal", "ok", "success"]:
            health = "OK"
        elif any(x in str(state).lower() for x in ["degraded", "warning"]):
            health = "NON-CRITICAL"
        elif any(x in str(state).lower() for x in ["failed", "failure", "critical", "fault"]):
            health = "CRITICAL"
        else:
            health = "UNKNOWN"

        f.write(f"Severity             : {health}\n\n")

"""
function: disk_report_printout
prereq: Requires a populated report dictionary containing StorCLI physical
        disk information and an open writable file object.
returns: None. Writes physical disk information to the report file.
Use: Generates the Disk Report section of the Sentry Care report. Enumerates
     all detected physical drives, extracts disk attributes such as slot,
     state, size, model, serial number, media type, and predictive error
     count, then assigns a health status of OK, NON-CRITICAL, or CRITICAL
     based on the drive's operational state. If no drives are found, an
     appropriate message is written to the report.
"""
def disk_report_printout(report, f):
    f.write("\n####################\n")
    f.write("    Disk Report\n")
    f.write("####################\n\n")

    controllers = report.get("storcli", {}).get("Controllers", [])
    serials = report.get("physical_drive_serials", {})

    found_disks = False

    for controller in controllers:
        response = controller.get("Response Data", {})

        for key, value in response.items():

            if not isinstance(value, list):
                continue

            for disk in value:

                if not isinstance(disk, dict):
                    continue

                if "EID:Slt" not in disk:
                    continue
                eid_slt = disk.get("EID:Slt")

                if eid_slt in serials:
                    disk["SN"] = serials[eid_slt].get("serial_number", "Unknown")

                found_disks = True

                state = str(disk.get("State", "Unknown"))

                severity = "OK"

                if state.lower() in [
                    "offln",
                    "failed",
                    "flt",
                    "missing"
                ]:
                    severity = "CRITICAL"

                elif state.lower() in [
                    "ugood",
                    "rbld",
                    "rebuild",
                    "jbod"
                ]:
                    severity = "NON-CRITICAL"

                f.write(f"Name : 0:{disk.get('EID:Slt','Unknown')}\n")
                f.write(f"State   : {state}\n")
                f.write(f"Size    : {disk.get('Size','Unknown')}\n")
                f.write(f"Model   : {disk.get('Model','Unknown')}\n")

                if "SN" in disk:
                    f.write(f"Serial  : {disk['SN']}\n")

                if "Med" in disk:
                    f.write(f"Media Type       : {disk['Med']}\n")

                if "PI" in disk:
                    f.write(f"Predictive Errors  : {disk['PI']}\n")

                f.write(f"Status: {severity}\n\n")

    if not found_disks:
        f.write("No physical disks found.\n")

"""
function: ipmi_sensor_to_json
prereq: No input 
returns: will return a json formated object 
Use: Will take the output of the command [ipmitool sensor] and put it into a workable json format into memory 
"""
def ipmi_sensor_to_json():
    SENSOR_COLUMNS = [
        "name",
        "value",
        "unit",
        "status",
        "lower_non_recoverable",
        "lower_critical",
        "lower_non_critical",
        "upper_non_critical",
        "upper_critical",
        "upper_non_recoverable",
    ]   
    sensor_result = subprocess.run(["ipmitool", "sensor"], capture_output=True, text=True)
    if sensor_result.returncode != 0:
        print("IPMI Sensor check failed") 
        print(sensor_result.stderr)
        return  []

    records = []
    for line in sensor_result.stdout.splitlines():
        parts = [p.strip() for p in line.split("|")]
        if(len(parts) == len(SENSOR_COLUMNS)):
            records.append(dict(zip(SENSOR_COLUMNS, parts)))

    if records:
        print("IPMI Sensor rows parsed")
        #print(json.dumps(records, indent=2))
    else:
        print("No IPMI sensor rows were parsed")
    return records

"""
function: ipmi_sel_list_to_json
prereq: Requires ipmitool to be installed and accessible. The system must
        support IPMI and allow execution of the command
        'ipmitool sel list'.
returns: A list of dictionaries containing parsed SEL (System Event Log)
         records. Returns an empty list if the command fails or no records
         can be parsed.
Use: Retrieves the IPMI System Event Log (SEL), parses each event entry into
     a structured JSON-compatible format, and returns the data for use in
     report generation, event analysis, and hardware health monitoring.
"""
def ipmi_sel_list_to_json():
    SEL_COLUMNS = [
        "record_id",
        "date",
        "time",
        "sensor",
        "event",
        "state"
    ]   
    result_sel = subprocess.run(["ipmitool", "sel","list"], capture_output=True, text=True)
    if result_sel.returncode != 0:
        print("IPMI Sel List check failed")
        print(result_sel.stderr)
        return []
    records = []
    for line in result_sel.stdout.splitlines():
        parts = [p.strip() for p in line.split("|")]
        if(len(parts) == len(SEL_COLUMNS)):
            records.append(dict(zip(SEL_COLUMNS, parts)))

    if records:
        print("IPMI Sel List rows parsed")
        #print(json.dumps(records, indent=2))
    else:
        print("No IPMI sel list rows were parsed")
    return records

"""
function: ipmi_chassis_status_to_json
prereq: Requires ipmitool to be installed and accessible. The system must
        support IPMI and allow execution of the command
        'ipmitool chassis status'.
returns: A list of dictionaries containing parsed chassis status records.
         Returns an empty list if the command fails or no records can be
         parsed.
Use: Retrieves chassis status information from the BMC through IPMI,
     converts the output into a structured JSON-compatible format, and
     returns the data for use in server health reporting and hardware
     status evaluation, including intrusion detection and chassis state
     monitoring.
"""
def ipmi_chassis_status_to_json():
    CHASSIS_COLUMNS = [
        "record_id",
        "status"
    ]
    result_chassis = subprocess.run(["ipmitool", "chassis", "status"], capture_output=True, text=True)
    if result_chassis.returncode != 0:
        print("IPMI Chassis Status check failed")
        print(result_chassis.stderr)
        return []
    records = []
    for line in result_chassis.stdout.splitlines():
        parts = [p.strip() for p in line.split(":")]
        if(len(parts) == len(CHASSIS_COLUMNS)):
            records.append(dict(zip(CHASSIS_COLUMNS, parts)))

    if records:
        print("IPMI Chassis rows parsed")
        #print(json.dumps(records, indent=2))
    else:
        print("No IPMI chassis status rows were parsed")
    return records

"""
function: ipmi_mc_info_to_json
prereq: Requires ipmitool to be installed and accessible. The system must
        support IPMI and allow execution of the command
        'ipmitool mc info'.
returns: A list of dictionaries containing parsed Management Controller
         (BMC) information. Returns an empty list if the command fails or
         no records can be parsed.
Use: Retrieves Baseboard Management Controller (BMC) information through
     IPMI, parses the output into a structured JSON-compatible format, and
     returns the data for use in server inventory, diagnostics, and health
     reporting. Information may include firmware version, manufacturer,
     device ID, and other controller attributes.
"""
def ipmi_mc_info_to_json():
    BMC_COLUMNS = [
        "record_id",
        "status"
    ]
    result_bmc = subprocess.run(["ipmitool", "mc", "info"], capture_output=True, text=True)
    if result_bmc.returncode != 0:
        print("IPMI mc info check failed")
        print(result_bmc.stderr)
        return []
    records = []
    for line in result_bmc.stdout.splitlines():
        parts = [p.strip() for p in line.split(":")]
        if(len(parts) == len(BMC_COLUMNS)):
            records.append(dict(zip(BMC_COLUMNS, parts)))

    if records:
        print("IPMI BMC rows parsed")
        #print(json.dumps(records, indent=2))
    else:
        print("No IPMI MC Info rows were parsed")
    return records

"""
function: ipmi_fru_to_json
prereq: Requires ipmitool to be installed and accessible. The system must
        support IPMI and allow execution of the command
        'ipmitool fru'.
returns: A list of dictionaries containing parsed FRU (Field Replaceable
         Unit) device information. Returns an empty list if the command
         fails or no FRU records can be parsed.
Use: Retrieves FRU inventory information from the system through IPMI,
     parses each FRU device entry into a structured JSON-compatible format,
     and returns the data for use in server inventory, asset tracking,
     serial number identification, and health reporting. Information may
     include manufacturer, product name, part number, serial number, and
     device presence status.
"""
def ipmi_fru_to_json():
    result_fru = subprocess.run(
        ["ipmitool", "fru"],
        capture_output=True,
        text=True
    )

    if  result_fru.returncode != 0 and not result_fru.stdout.strip():
        print("IPMI FRU check failed")
        print("Return code:", result_fru.returncode)
        print("STDOUT:", repr(result_fru.stdout))
        return []

    frus = []
    current_fru = None

    for line in result_fru.stdout.splitlines():
        line = line.strip()

        if not line:
            continue

        if line.startswith("FRU Device Description"):
            if current_fru:
                frus.append(current_fru)

            key, value = line.split(":", 1)
            current_fru = {
                "device_description": value.strip()
            }

        elif ":" in line and current_fru:
            key, value = line.split(":", 1)

            current_fru[
                key.strip().lower().replace(" ", "_")
            ] = value.strip()

        elif "Device not present" in line and current_fru:
            current_fru["status"] = "not_present"

    if current_fru:
        frus.append(current_fru)

    
    if frus:
        print("IPMI Fru rows parsed")
        #print(json.dumps(frus, indent=2))
    else:
        print("No IPMI Fru rows were parsed")
    return frus

#---- Check if IPMI is installed ----------------------------------------------------------
if(is_installed("ipmitool")):
    print("IPMI is installed")
elif(not is_installed("ipmitool")):
    
    subprocess.run(["echo", "IPMI is not installed, installing IPMI "])
    result=subprocess.run(["zypper", "in", "-y", "ipmitool"],capture_output=True, text=True)
    if result.returncode == 0:
        print("IPMI has been installed...")
    else:
        print("Failed to install IPMI...")
        print(result.stderr)

#---- Check if StorCLI is installed --------------------------------------------------------
if(is_installed("storcli")):
    print("StorCLI is installed") 
else:
    subprocess.run(["echo", "Downloading StorCLI RPM file"])
    result = subprocess.run(["curl", "-LO", "https://docs.broadcom.com/docs-and-downloads/007.2705.0000.0000_storcli_rel.zip"])
    if result.returncode == 0:
        print("StorCLI has been downloaded...")
        subprocess.run(["unzip", "007.2705.0000.0000_storcli_rel.zip"])
        subprocess.run(["unzip", "storcli_rel/Unified_storcli_all_os.zip"])

    else:
        print("Failed to download StorCLI...")
        print(result.stderr)
        print("Please insure the RPM file is placed in the working directory...")
        looping = True
        while(looping):
            print("Please indicate if the rpm is uploaded or if you want to exit: y/E, /nPlace the rpm so it is in the currecnt directory and is named Unified_storcli_all_os/Linux/storcli-007.2705.0000.0000-1.noarch.rpm")
            user_input=input()
            if(user_input == "y"):
                looping = False
                break;
            elif(user_input == "E"):
                exit()
            else:
                print("Please select either y for yes or E for exit")
    subprocess.run(["echo", "Installing StorCLI..."])
    result = subprocess.run(["zypper", "--no-gpg-checks", "install", "-y", "Unified_storcli_all_os/Linux/storcli-007.2705.0000.0000-1.noarch.rpm"], capture_output=True, text=True)
    subprocess.run(["ln", "-s","/opt/MegaRAID/storcli/storcli64", "/usr/local/bin/storcli"])
   
    if result.returncode == 0:
        print("StorCLI has been installed...")
    else:
        print("Failed to install StorCLI...")
        print(result.stderr) 

#----------- MAIN Loop -----------------------------
looping = True
while(looping):
    print("Choose what to do: \n 1. Exit \n 2. Generate Report \n 3. Clean Up")
    inp = input().strip()
    if(inp == "1"):
        looping = False
    elif(inp == "2"): 
        generate_report()
        looping = False
    elif(inp == "3"): 
        cleanup()
        looping = False
    else:
        print("Please enter a valid number choice")
