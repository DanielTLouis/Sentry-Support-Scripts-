function main(){
  Logger.log("Running printCameraNames");
  printCameraNames();
  Logger.log("Running piechart_axis_up_down");
  piechart_axis_up_down();
  Logger.log("Running buildGroupUniqueIpBarChartGeneric");
  buildGroupUniqueIpBarChartGeneric();
  Logger.log("Running buildGroupUniqueIpBarChartGeneric");
  buildGroupUniqueIpBarChartGeneric();
}

function piechart_axis_up_down() {
  const ss = SpreadsheetApp.getActive();
  const sheet = ss.getSheetByName("AxisCameras");
  if (!sheet) throw new Error(`Sheet not found: AxisCameras`);

  const startRow = 13;
  const headerRow = startRow - 1; // yellow header row is 12
  //const lastCol = sheet.getLastColumn();
  const lastCol = 1700;

  // Header names (match your sheet)
  const MODEL_HEADER = "Model";
  const STATUS_HEADER = "Status";
  const DISCONTINUED_HEADER = "Discontinued date";

  // --- ADDON: Warranty header name (change if your sheet uses a different label) ---
  const WARRANTY_HEADER = "Warranty";

  // Read headers
  const headers = sheet
    .getRange(headerRow, 1, 1, lastCol)
    .getValues()[0]
    .map(h => String(h).trim());

  // Only search left side headers (real table)
  const SEARCH_LIMIT = 10;
  const findHeaderCol = (name) => {
    for (let i = 0; i < Math.min(SEARCH_LIMIT, headers.length); i++) {
      if (headers[i].toLowerCase() === name.toLowerCase()) return i + 1;
    }
    return 0;
  };

  // --- ADDON: Search ALL headers (not just first 10) for Warranty column ---
  const findHeaderColAny = (name) => {
    const target = String(name).trim().toLowerCase();
    for (let i = 0; i < headers.length; i++) {
      if (String(headers[i]).trim().toLowerCase() === target) return i + 1;
    }
    return 0;
  };

  const colModel = findHeaderCol(MODEL_HEADER);
  const colStatus = findHeaderCol(STATUS_HEADER);
  const colDiscontinued = findHeaderCol(DISCONTINUED_HEADER);

  // --- ADDON: Warranty column index ---
  const colWarranty = findHeaderColAny(WARRANTY_HEADER);

  if (!colModel || !colStatus || !colDiscontinued) {
    throw new Error(
      `Could not find required headers.\n` +
      `Model col=${colModel}, Status col=${colStatus}, Discontinued col=${colDiscontinued}\n` +
      `Headers row (${headerRow}) values:\n${headers.join(" | ")}`
    );
  }

  if (!colWarranty) {
    throw new Error(
      `Could not find Warranty header "${WARRANTY_HEADER}".\n` +
      `Tip: if the header is different, update WARRANTY_HEADER.\n` +
      `Headers row (${headerRow}) first 40 values:\n${headers.slice(0, 40).join(" | ")}`
    );
  }

  const lastDataRow = sheet.getLastRow();
  if (lastDataRow < startRow) throw new Error("No camera rows found under the header.");

  const data = sheet.getRange(startRow, 1, lastDataRow - startRow + 1, lastCol).getValues();

  // ---- Chart 1 counts (ONLY Reachable/Unreachable from first Status column) ----
  const statusCounts = { "Reachable on Network": 0, "Unreachable": 0 };

  // ---- Chart 2 counts (ALWAYS Supported/Unsupported/Unknown) ----
  const eomCounts = { "Supported": 0, "Unsupported": 0, "Unknown": 0 };

  // ---- ADDON: Chart 3 counts (Warranty) ----
  const warrantyCounts = {
    "In Warranty": 0,
    "Out of Warranty": 0,
    "Out of Warranty in 6 Months": 0
  };

  const norm = (v) => String(v ?? "").trim().toLowerCase();

  // --- ADDON: Date helpers for warranty calc ---
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const sixMonthsFromNow = new Date(today);
  sixMonthsFromNow.setMonth(sixMonthsFromNow.getMonth() + 6);

  const asDate = (v) => {
    // If the cell is a real Date value
    if (v instanceof Date && !isNaN(v.getTime())) return v;

    // Try parse string
    const s = String(v ?? "").trim();
    if (!s) return null;

    const d = new Date(s);
    if (!isNaN(d.getTime())) return d;

    return null;
  };

  data.forEach(row => {
    const model = String(row[colModel - 1] ?? "").trim();
    const status = String(row[colStatus - 1] ?? "").trim();
    const discRaw = row[colDiscontinued - 1];
    const warrantyRaw = row[colWarranty - 1];

    if (!status) return;

    // Chart 1 (Axis status)
    if (status === "Reachable on Network" || status === "Reachable") statusCounts["Reachable on Network"]++;
    else statusCounts["Unreachable"]++;

    // Chart 2 (EOM Support Status) based on values in "Discontinued date" column
    // Column currently has: Supported / Unknown Status (and may have Unsupported in the future)
    const d = norm(discRaw);
    // Check if value is a date
    const s = asDate((String(discRaw ?? "").trim()).toLowerCase());
    if (d === "supported" || d === "orderable") {
      eomCounts["Supported"]++;
    } else if (d === "unsupported") {
      eomCounts["Unsupported"]++;
    } else if (d === "" || d === "unknown" || d === "unknown status" || d === "no date set") {
      eomCounts["Unknown"]++;
    } else if (s) {
      s.setHours(0, 0, 0, 0);

      if (s < today) {
        eomCounts["Unsupported"]++;
      } else {
        eomCounts["Supported"]++;
      }
    } else {
      // Any unexpected value -> Unknown
      eomCounts["Unknown"]++;
    }
    

    // --- ADDON: Chart 3 (Warranty Status) ---
    // Assumes Warranty column contains a warranty END/EXPIRATION date
    const w = asDate(warrantyRaw);
    if (w) {
      w.setHours(0, 0, 0, 0);

      if (w < today) {
        warrantyCounts["Out of Warranty"]++;
      } else {
        warrantyCounts["In Warranty"]++;

        // Still in warranty, but expiring within the next 6 months
        if (w <= sixMonthsFromNow) {
          warrantyCounts["Out of Warranty in 6 Months"]++;
        }
      }
    }
  });

  // ---- Helper tables MUST stay above the yellow line (rows 2-11) ----
  // Axis table: J2:K11
  // EOM table:  M2:N11
  // Warranty:   P2:Q11
  const AXIS_TABLE_COL = 10; // J
  const EOM_TABLE_COL  = 13; // M
  const WAR_TABLE_COL  = 16; // P
  const TABLE_TOP_ROW  = 2;

  // Clear exactly the spaces we use (10 rows: 2..11)
  sheet.getRange(TABLE_TOP_ROW, AXIS_TABLE_COL, 10, 2).clearContent().clearFormat(); // J2:K11
  sheet.getRange(TABLE_TOP_ROW, EOM_TABLE_COL, 10, 2).clearContent().clearFormat();  // M2:N11
  sheet.getRange(TABLE_TOP_ROW, WAR_TABLE_COL, 10, 2).clearContent().clearFormat();  // P2:Q11

  // Write Axis helper table (fixed 2 rows)
  sheet.getRange(TABLE_TOP_ROW, AXIS_TABLE_COL).setValue("Axis Camera Status");
  sheet.getRange(TABLE_TOP_ROW + 1, AXIS_TABLE_COL, 1, 2).setValues([["Category", "Count"]]);
  sheet.getRange(TABLE_TOP_ROW + 2, AXIS_TABLE_COL, 2, 2).setValues([
    ["Reachable on Network", statusCounts["Reachable on Network"]],
    ["Unreachable", statusCounts["Unreachable"]],
  ]);
  // Pad remaining rows so old values don't linger
  sheet.getRange(TABLE_TOP_ROW + 4, AXIS_TABLE_COL, 6, 2)
    .setValues(Array.from({ length: 6 }, () => ["", ""]));

  // Range for chart: header + up to 8 rows (keeps stable)
  const table1Range = sheet.getRange(TABLE_TOP_ROW + 1, AXIS_TABLE_COL, 9, 2);

  // Write EOM helper table (fixed 3 rows: Supported/Unsupported/Unknown)
  sheet.getRange(TABLE_TOP_ROW, EOM_TABLE_COL).setValue("EOM Support Status");
  sheet.getRange(TABLE_TOP_ROW + 1, EOM_TABLE_COL, 1, 2).setValues([["Category", "Count"]]);
  sheet.getRange(TABLE_TOP_ROW + 2, EOM_TABLE_COL, 3, 2).setValues([
    ["Supported", eomCounts["Supported"]],
    ["Unsupported", eomCounts["Unsupported"]],
    ["Unknown", eomCounts["Unknown"]],
  ]);
  // Pad remaining rows
  sheet.getRange(TABLE_TOP_ROW + 5, EOM_TABLE_COL, 5, 2)
    .setValues(Array.from({ length: 5 }, () => ["", ""]));

  const table2Range = sheet.getRange(TABLE_TOP_ROW + 1, EOM_TABLE_COL, 9, 2);

  // --- ADDON: Write Warranty helper table ---
  sheet.getRange(TABLE_TOP_ROW, WAR_TABLE_COL).setValue("Warranty Status");
  sheet.getRange(TABLE_TOP_ROW + 1, WAR_TABLE_COL, 1, 2).setValues([["Category", "Count"]]);
  sheet.getRange(TABLE_TOP_ROW + 2, WAR_TABLE_COL, 3, 2).setValues([
    ["In Warranty", warrantyCounts["In Warranty"]],
    ["Out of Warranty", warrantyCounts["Out of Warranty"]],
    ["Out of Warranty in 6 Months", warrantyCounts["Out of Warranty in 6 Months"]],
  ]);
  sheet.getRange(TABLE_TOP_ROW + 5, WAR_TABLE_COL, 5, 2)
    .setValues(Array.from({ length: 5 }, () => ["", ""]));

  const table3Range = sheet.getRange(TABLE_TOP_ROW + 1, WAR_TABLE_COL, 9, 2);

  // ---- Remove existing charts ----
  sheet.getCharts().forEach(c => sheet.removeChart(c));

  // ---- Build charts ABOVE yellow line ----
  const CHART_WIDTH = 320;
  const CHART_HEIGHT = 200;

  const chart1 = sheet.newChart()
    .setChartType(Charts.ChartType.PIE)
    .addRange(table1Range)
    .setOption("title", "Axis Camera Status")
    .setOption("titleTextStyle", {fontSize: 30, bold: true, color: "#000000"})
    .setOption("pieSliceText", "value")
    .setOption("pieSliceTextStyle", { fontSize: 20 })
    .setOption("legend", { position: "right" , textStyle: { fontSize: 20, color: "#000000" } })
    .setOption("useFirstRowAsHeaders", true)
    .setOption("useFirstColumnAsDomain", true)
    .setOption("slices", {
      0: { color: "#1a73e8" }, // Blue = Up
      1: { color: "#d93025" }  // Red = Down
    })
    .setOption('colors', ['red', 'blue', '#d93025'])
    .setOption("backgroundColor", "#e9eedf")
    .setOption("chartArea", {
      backgroundColor: "#e9eedf"
    })
    .setOption("width", CHART_WIDTH)
    .setOption("height", CHART_HEIGHT)
    .setPosition(2, 1, 0, 0)   // A2
    .build();

  const chart2 = sheet.newChart()
    .setChartType(Charts.ChartType.PIE)
    .addRange(table2Range)
    .setOption("title", "EOM Support Status")
    .setOption("titleTextStyle", {fontSize: 30, bold: true, color: "#000000"})
    .setOption("pieSliceText", "value")
    .setOption("pieSliceTextStyle", { fontSize: 20 })
    .setOption("legend", { position: "right" , textStyle: { fontSize: 20, color: "#000000" } })
    .setOption("useFirstRowAsHeaders", true)
    .setOption("useFirstColumnAsDomain", true)
    .setOption("slices", {
      0: { color: "#1a73e8" }, // Blue = Supported 
      1: { color: "#d93025" },  // Red = Unsupported
      2: { color: "#f0e037" } //Yellow = Unknown
    })
    .setOption('colors', ['red', 'blue', '#d93025', '#f0e037'])
    .setOption("backgroundColor", "#e9eedf")
    .setOption("chartArea", {
      backgroundColor: "#e9eedf"
    })
    .setOption("width", CHART_WIDTH)
    .setOption("height", CHART_HEIGHT)
    .setPosition(2, 5, 0, 0)   // D2 (right of chart 1)
    .build();

  // --- ADDON: Chart 3 (Warranty) ---
  const chart3 = sheet.newChart()
    .setChartType(Charts.ChartType.PIE)
    .addRange(table3Range)
    .setOption("title", "Warranty Status")
    .setOption("titleTextStyle", {fontSize: 30, bold: true, color: "#000000"})
    .setOption("pieSliceText", "value")
    .setOption("pieSliceTextStyle", { fontSize: 20 })
    .setOption("legend", { position: "right" , textStyle: { fontSize: 20, color: "#000000" } })
    .setOption("useFirstRowAsHeaders", true)
    .setOption("useFirstColumnAsDomain", true)
    .setOption("slices", {
      0: { color: "#1a73e8" }, // In Warranty
      1: { color: "#d93025" }, // Out of Warranty
      2: { color: "#f0e037" }  // Out in 6 months
    })
    .setOption('colors', ['red', 'blue', '#d93025', '#f0e037'])
    .setOption("backgroundColor", "#e9eedf")
    .setOption("chartArea", {
      backgroundColor: "#e9eedf"
    })
    .setOption("width", CHART_WIDTH)
    .setOption("height", CHART_HEIGHT)
    .setPosition(2, 9, 0, 0)   // G2 (right of chart 2)
    .build();

  sheet.insertChart(chart1);
  sheet.insertChart(chart2);
  sheet.insertChart(chart3);
}

function buildGroupUniqueIpBarChartGeneric() {
  const ss = SpreadsheetApp.getActive();
  const sheet =  ss.getSheetByName("Inventory Charts");
  if (!sheet) throw new Error(`Sheet not found: Inventory Charts`);

  const namesSheet =  ss.getSheetByName("Summary & Licensing");
  if (!namesSheet) throw new Error(`Names sheet not found: Summary & Licensing`);

  // ---- CONFIG (structure anchors) ----
  const GROUP_NAMES_START_ROW = 36;    // A36 down
  const GROUP_NAME_COL = 3;             // Column C
  const CAMERA_START_ROW = 401;         // rows of cameras
  const CAMERA_HEADER_ROW = 400;        // header row

  // Header names (must match)
  const IP_HEADER = "IP Address";
  const CONNECTED_HEADER = "Connected";

  // Output locations (safe defaults: right side)
  const HELPER_TOP_LEFT_A1 = "S401";
  const CHART_ANCHOR_A1 = "G4";

  const MAX_RECOM = 65;

  // ---- Read group names ----
  const maxRows = namesSheet.getMaxRows();
  const groupRaw = namesSheet
    .getRange(GROUP_NAMES_START_ROW, GROUP_NAME_COL, maxRows - GROUP_NAMES_START_ROW + 1, 1)
    .getValues()
    .map(r => String(r[0]).trim());

  const groupNames = [];
  for (const name of groupRaw) {
    if (!name) break;
    groupNames.push(name);
  }
  if (groupNames.length === 0) {
    throw new Error(`No group names found in "Summary & Licensing" column C starting at row ${GROUP_NAMES_START_ROW}.`);
  }

  // ---- Find IP + Connected columns by header row ----
  const headerRowRange = sheet.getRange(CAMERA_HEADER_ROW, 1, 1, sheet.getLastColumn()).getDisplayValues()[0];
  const headers = headerRowRange.map(h => h.trim());

  const colIp = headers.findIndex(h => h.toLowerCase() === IP_HEADER.toLowerCase()) + 1;
  const colConnected = headers.findIndex(h => h.toLowerCase() === CONNECTED_HEADER.toLowerCase()) + 1;

  if (!colIp || !colConnected) {
    throw new Error(
      `Missing required headers on row ${CAMERA_HEADER_ROW}.\n` +
      `IP col=${colIp}, Connected col=${colConnected}\n` +
      `Headers: ${headers.join(" | ")}`
    );
  }

  // ---- Read camera data ----
  const lastRow = sheet.getLastRow();
  if (lastRow < CAMERA_START_ROW) throw new Error(`No camera data at/after row ${CAMERA_START_ROW}.`);

  const lastCol = sheet.getLastColumn();
  const data = sheet.getRange(CAMERA_START_ROW, 1, lastRow - CAMERA_START_ROW + 1, lastCol).getValues();
  const isBlankRow = (row) => row.every(c => String(c).trim() === "");

  // ---- Aggregate per blank-line group: unique IPs + unique down IPs ----
  const stats = []; // [{totalUnique, downUnique}, ...] in order
  let seen = new Set();
  let down = new Set();
  let inGroup = false;

  const flush = () => {
    if (!inGroup) return;
    stats.push({ totalUnique: seen.size, downUnique: down.size });
    seen = new Set();
    down = new Set();
    inGroup = false;
  };

  for (const row of data) {
    if (isBlankRow(row)) {
      flush();
      continue;
    }

    inGroup = true;

    const ip = String(row[colIp - 1]).trim();
    if (!ip) continue;

    const connected = String(row[colConnected - 1]).toLowerCase() === "true";
    const key = ip.toLowerCase();

    seen.add(key);
    if (!connected) down.add(key);
  }
  flush();

  const n = Math.min(groupNames.length, stats.length);
  if (n === 0) throw new Error("No blank-line groups detected in the camera section.");

  // ---- Write helper table ----
  const helperCell = sheet.getRange(HELPER_TOP_LEFT_A1);
  const out = [
    ["Server", "Unique IP Cameras", "Unique IP Down", "Max Cams Recom"], 
    ["", null, null, MAX_RECOM], // LEFT padding
  ];
  for (let i = 0; i < n; i++) {
    out.push([groupNames[i], stats[i].totalUnique, stats[i].downUnique, MAX_RECOM]);
  }

  out.push(["", null, null, MAX_RECOM]); // RIGHT padding

  sheet.getRange(helperCell.getRow(), helperCell.getColumn(), out.length, 4).clearContent();
  const helperRange = sheet.getRange(helperCell.getRow(), helperCell.getColumn(), out.length, 4);
  helperRange.setValues(out);

  // ---- Build chart ----
  let maxVal = 0;
  for (let i = 1; i < out.length; i++) {
    maxVal = Math.max(maxVal, Number(out[i][1]) || 0, Number(out[i][2]) || 0);
  }
  const vMax = maxVal > 100 ? Math.ceil(maxVal * 1.10 + 5) : Math.ceil(maxVal + 5);
  const helperDataRange = helperRange.offset(1, 0, helperRange.getNumRows() - 1, helperRange.getNumColumns());

  const anchor = sheet.getRange(CHART_ANCHOR_A1);

  const CHART_TITLE = "Server Configuration";

  // ---- Remove existing chart with same title ----
  sheet.getCharts().forEach(c => {
    const opts = c.getOptions();
    if (opts && opts.get("title") === CHART_TITLE) {
      sheet.removeChart(c);
    }
  });

  // vAxis max so it doesn't cut off
  for (let i = 1; i < out.length; i++) {
    maxVal = Math.max(maxVal, Number(out[i][1]) || 0, Number(out[i][2]) || 0, Number(out[i][3]) || 0);
  }

  const chart = sheet.newChart()
    .setChartType(Charts.ChartType.COMBO)
    .addRange(helperDataRange)
    .setOption("useFirstRowAsHeaders", true)
    .setPosition(anchor.getRow(), anchor.getColumn(), 0, 0)
    .setOption("title", CHART_TITLE)
    .setOption("titleTextStyle",{fontSize: 24, bold: true, color: "#000000"})
    .setOption("subtitle", "Number of Cameras per Server") // may be ignored by Sheets, but ok to try
    .setOption("legend", { position: "bottom" })
    .setOption("hAxis", { title: ""})
    .setOption("vAxis", { minValue: 0, maxValue: 100 })

    // Series mapping (based on helperRange2 columns B,C,D):
    // 0 = # of Cameras (bar)
    // 1 = Down Cams (bar)
    // 2 = Max Cams Recom (line)
    .setOption("seriesType", "bars")
    .setOption("series", {
      0: { type: "bars", dataLabel: "value", labelInLegend: "Connected Cameras" },
      1: { type: "bars", dataLabel: "value", labelInLegend: "Down Cams" },
      2: { type: "line", lineWidth: 3, pointSize: 0, labelInLegend: "Max Cams Recom", color: "#f9ab00",  }
    })
    .setOption("vAxis", {
      title: "Count",
      viewWindow: { min: 0, max: 100 }
    })
    .setOption("backgroundColor", "#e9eedf")
    .setOption("annotations", {
      alwaysOutside: true,
      textStyle: { color: "#f9ab00", fontSize: 12 }
    })
    .build();

  sheet.insertChart(chart);
}

function piechart_nonAxis_up_down() {
  const ss = SpreadsheetApp.getActive();
  const sheet =  ss.getSheetByName("Inventory Charts");
  if (!sheet) throw new Error(`Sheet not found: Inventory Charts`);;

  const startRow = 401;           // camera rows start here
  const headerRow = startRow - 1; // headers are on row 400
  const lastRow = 1700;
  const lastCol = sheet.getLastColumn();
  if (lastRow < startRow) throw new Error("No camera rows found at/after row 401.");

  // Header names (match your sheet)
  const MODEL_HEADER = "Model";
  const CONNECTED_HEADER = "Connected";

  // Find columns by header name
  const headers = sheet.getRange(headerRow, 1, 1, lastCol).getValues()[0].map(h => String(h).trim());
  const colModel = headers.findIndex(h => h.toLowerCase() === MODEL_HEADER.toLowerCase()) + 1;
  const colConnected = headers.findIndex(h => h.toLowerCase() === CONNECTED_HEADER.toLowerCase()) + 1;

  if (!colModel || !colConnected) {
    throw new Error(
      `Could not find required headers.\n` +
      `Model col=${colModel}, Connected col=${colConnected}\n` +
      `Headers row (${headerRow}) values:\n${headers.join(" | ")}`
    );
  }

  // Read rows 401 -> end
  const data = sheet.getRange(startRow, 1, lastRow - startRow + 1, lastCol).getValues();

  let up = 0;
  let down = 0;

  data.forEach(r => {
    const model = String(r[colModel - 1] || "").trim();
    if (!model) return;

    // Exclude Axis rows
    if (model.toLowerCase().startsWith("axis")) return;

    const connectedVal = r[colConnected - 1];
    const connected = String(connectedVal).toLowerCase() === "true";

    if (connected) up += 1;
    else down += 1;
  });

  let hasData = (up + down) > 0;

  // Write a tiny helper table for the pie chart
  const helperCell = sheet.getRange("S415"); // change location if you want
  sheet.getRange(helperCell.getRow(), helperCell.getColumn(), 10, 2).clearContent();

  const helperRange = sheet.getRange(helperCell.getRow(), helperCell.getColumn(), 3, 2);
  helperRange.setValues([
  ["Status", "Non-Axis Cameras"],
  ["Connected to Server", hasData ? up : 0],
  ["Down", hasData ? down : 0]
]);

  const CHART_TITLE = hasData
  ? "Non-Axis Cameras Status"
  : "Non-Axis Cameras Status (No Data)";

  // Remove existing chart that was just generated
  sheet.getCharts().forEach(c => {
    const opts = c.getOptions();
    if (opts && opts.get("title") === CHART_TITLE) {
      sheet.removeChart(c);
    }
  })

  // Insert pie chart
  const anchor = sheet.getRange("A4"); // chart top-left
  const chart = sheet.newChart()
  .setChartType(Charts.ChartType.PIE)
  .addRange(helperRange)
  .setPosition(anchor.getRow(), anchor.getColumn(), 0, 0)
  .setOption("title", CHART_TITLE)
  .setOption("titleTextStyle", {fontSize: 30, bold: true, color: "#000000"})
  // Labels like left (value + percent on slices)
  .setOption("pieSliceText", "value")
  .setOption("pieSliceTextStyle", { fontSize: 20 })

  .setOption("legend", { position: "right", textStyle: { fontSize: 20, color: "#000000" } })
  .setOption("slices", {
    0: { color: "#1a73e8" }, // Blue = Up
    1: { color: "#d93025" }  // Red = Down
  })
  .setOption('colors', ['red', 'blue', '#d93025'])
  .setOption("pieHole", 0.25)
  .setOption("backgroundColor", "#e9eedf")
  .setOption("chartArea", {
    backgroundColor: "#e9eedf"
  })
  .build();

  sheet.insertChart(chart);
  if (!hasData) {
    console.warn("No Non-Axis cameras found between rows 401–1700.");
  }
}

function printCameraNames() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const targetSheet = spreadsheet.getSheetByName("Inventory Charts");

  // Clear target range (rows 401, 1300 rows, 5 columns)
  targetSheet.getRange(401, 1, 1300, 5).clearContent();
  let startRow = 401, serverCounts = [];

  for (let i = 1; i <= 12; i++) {
    const prefix = `Svr${i}`;
    const sourceSheet = spreadsheet.getSheets().find(sheet => sheet.getName().startsWith(prefix));
    if (!sourceSheet) continue;

    const data = sourceSheet.getRange(1, 1, sourceSheet.getLastRow(), 36).getValues(); // up to column AJ
    const cameraData = data
      .filter(row => {
        const colAB = row[27];  // Column AB (0-indexed 27)
        const colAI = row[34];  // Column AI (0-indexed 34)
        return colAB && colAB !== "IP True+False Cams" && colAI !== "MultiSensor";
      })
      .map(row => [row[2], row[3], row[4], row[5], row[34]]); // Use columns: 3, 4, 5, 6, and 35

    if (cameraData.length > 0) {
      targetSheet.getRange(startRow, 1, cameraData.length, 5).setValues(cameraData);
      serverCounts.push(cameraData.length);
      startRow += cameraData.length;
    }
    startRow++; // leave an empty row between server groups
  }

  // Write camera counts per server to column C starting at row 375
  if (serverCounts.length > 0) {
    const countsArray = serverCounts.map(count => [count]);
    targetSheet.getRange(375, 3, countsArray.length, 1).setValues(countsArray);
  }
  
  // Delete cell C374 content and add header "# of cameras"
  targetSheet.getRange(374, 3).clearContent();
  targetSheet.getRange(374, 3).setValue("# of cameras");
}
