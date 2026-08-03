function main() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("All products");

  hide_columns(sheet);
  update_sheet_name();
  insert_xy_cells(sheet);
  insertColumn_ourCost(sheet);
  insertShippingColumns(sheet);
}

function hide_columns(sheet) {
  const headerRow = 2
  const high_value_order = findColumnByHeader(sheet, "High volume order", headerRow)
  const ean_code_us = findColumnByHeader(sheet, "EAN Code US", headerRow)
  sheet.hideColumns(high_value_order);
  sheet.hideColumns(ean_code_us);
}

function insert_xy_cells(sheet) {
  sheet.getRange("AA1").setValue("Museum Mult");
  sheet.getRange("AB1").setValue(0.7081);

  sheet.getRange("AA2").setValue("Discount Mult");
  sheet.getRange("AB2").setValue(0.73);
}

function insertColumn_ourCost(sheet) {
  sheet.insertColumnAfter(8);
  sheet.getRange("I2").setValue("Our Cost");

  const lastRow = sheet.getLastRow();
  sheet.getRange(`I3:I${lastRow}`).setFormula("=$J3*$AC$2");
  sheet.getRange(`I3:I${lastRow}`).setNumberFormat("0.00");
}

function insertShippingColumns(sheet) {
  const headerRow = 2;
  const firstDataRow = 3;
  const lastRow = sheet.getLastRow();

  const widthCol = findColumnByHeader(sheet, "Width inches", headerRow);
  const depthCol = findColumnByHeader(sheet, "Depth inches", headerRow);
  const heightCol = findColumnByHeader(sheet, "Height inches", headerRow);
  const weightCol = findColumnByHeader(sheet, "Weight lbs", headerRow);

  sheet.insertColumnAfter(heightCol);
  const cuInCol = heightCol + 1;
  sheet.getRange(headerRow, cuInCol).setValue("Cu In");

  sheet.getRange(firstDataRow, cuInCol, lastRow - firstDataRow + 1)
    .setFormulaR1C1(`=RC[${widthCol - cuInCol}]*RC[${depthCol - cuInCol}]*RC[${heightCol - cuInCol}]`)
    .setNumberFormat("0.00");

  sheet.insertColumnAfter(cuInCol);
  const cuFtCol = cuInCol + 1;
  sheet.getRange(headerRow, cuFtCol).setValue("Cu Ft");

  sheet.getRange(firstDataRow, cuFtCol, lastRow - firstDataRow + 1)
    .setFormulaR1C1("=RC[-1]/1728")
    .setNumberFormat("0.00");

  sheet.insertColumnAfter(weightCol);
  const dimWeightCol = weightCol + 1;
  sheet.getRange(headerRow, dimWeightCol).setValue("Dim Weight (lb)");

  sheet.getRange(firstDataRow, dimWeightCol, lastRow - firstDataRow + 1)
    .setFormulaR1C1(`=RC[${cuInCol - dimWeightCol}]/139`)
    .setNumberFormat("0.00");
}

function findColumnByHeader(sheet, headerName, headerRow) {
  const normalize = value =>
    String(value)
      .toLowerCase()
      .replace(/[^a-z0-9]/g, "");

  const target = normalize(headerName);
  const headers = sheet.getRange(headerRow, 1, 1, sheet.getLastColumn()).getValues()[0];

  const index = headers.findIndex(header => normalize(header) === target);

  if (index === -1) {
    throw new Error(`Header not found: ${headerName}`);
  }

  return index + 1;
}

function update_sheet_name() {
  const today = new Date();
  const month = today.getMonth();
  const year = String(today.getFullYear()).slice(-2);

  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  SpreadsheetApp.getActiveSpreadsheet()
    .setName("Anixter Axis US Price_List-" + monthNames[month] + "-" + year);
}