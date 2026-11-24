# Builds Dataset/BIBA_StyleIQ_Data.xlsx: all 7 tables in one workbook, each as an
# Excel Table, for use with Power BI Online (which has no Power Query for CSVs).
#
# It also adds the columns that the Desktop guide creates in Power Query / DAX
# calculated columns, so the online model has them ready:
#   Fact_Purchase_Orders: delivery_status split into delivery_status + shipment_type,
#                         delay_days, actual_lead_time_days
#   Dim_Product:          margin_pct, price_band, price_band_order, lead_time_days
#   Dim_Date:             season_order
#   Fact_Inventory_Monthly: cover_days, stock_status
#
# Also builds Documentation/Data_Quality_Checks.xlsx: the same data plus a 'Checks'
# sheet of 22 live Excel formulas (completeness, uniqueness, validity, consistency,
# referential integrity, reconciliation), each with Expected value and Pass/Fail.
#
# Run: ruby build_excel.rb     (Ruby 2.6+, standard library + the macOS `zip` command)

require 'csv'
require 'date'
require 'fileutils'
require 'tmpdir'

DATA = File.expand_path('../Dataset', __dir__)
OUT  = File.join(DATA, 'BIBA_StyleIQ_Data.xlsx')
CHECKS_OUT = File.expand_path('../Documentation/Data_Quality_Checks.xlsx', __dir__)
EPOCH = Date.new(1899, 12, 30)
DATE_COLS = %w[date launch_date month_end_date order_date expected_delivery_date actual_delivery_date]
NUM_RE = /\A-?\d+(\.\d+)?\z/

def load(name)
  rows = CSV.read(File.join(DATA, "#{name}.csv"), headers: true)
  [rows.headers, rows.map(&:to_h)]
end

# ---------------------------------------------------------------- derived columns
tables = {}
%w[Dim_Date Dim_Product Dim_Store Dim_Supplier Fact_Sales Fact_Inventory_Monthly Fact_Purchase_Orders].each { |t| tables[t] = load(t) }

lead = tables['Dim_Supplier'][1].map { |r| [r['supplier_id'], r['contracted_lead_time_days']] }.to_h

h, rows = tables['Dim_Date']
order = { 'Winter' => 1, 'Summer' => 2, 'Monsoon' => 3 }
rows.each { |r| r['season_order'] = (order[r['season']] || 4).to_s }
tables['Dim_Date'] = [h + ['season_order'], rows]

h, rows = tables['Dim_Product']
rows.each do |r|
  mrp = r['mrp_inr'].to_f
  r['margin_pct'] = (1 - r['unit_cost_inr'].to_f / mrp).round(4).to_s
  band, ord = if mrp < 1500 then ['Under ₹1,500', 1]
              elsif mrp < 3000 then ['₹1,500–2,999', 2]
              elsif mrp < 6000 then ['₹3,000–5,999', 3]
              else ['₹6,000+', 4]
              end
  r['price_band'] = band
  r['price_band_order'] = ord.to_s
  r['lead_time_days'] = lead[r['supplier_id']]
end
tables['Dim_Product'] = [h + %w[margin_pct price_band price_band_order lead_time_days], rows]

h, rows = tables['Fact_Purchase_Orders']
rows.each do |r|
  status, ship = r['delivery_status'].split(' - ', 2)
  r['delivery_status'] = status
  r['shipment_type'] = ship || (status == 'Open' ? '' : 'Full')
  if r['actual_delivery_date'].to_s != ''
    a = Date.parse(r['actual_delivery_date'])
    r['delay_days'] = (a - Date.parse(r['expected_delivery_date'])).to_i.to_s
    r['actual_lead_time_days'] = (a - Date.parse(r['order_date'])).to_i.to_s
  end
end
tables['Fact_Purchase_Orders'] = [h + %w[shipment_type delay_days actual_lead_time_days], rows]

h, rows = tables['Fact_Inventory_Monthly']
rows.each do |r|
  cs = r['closing_stock'].to_i
  us = r['units_sold'].to_i
  daily = us / Date.parse(r['month_end_date']).day.to_f
  cover = daily > 0 ? cs / daily : nil
  r['cover_days'] = cover ? cover.round(1).to_s : ''
  r['stock_status'] = if cs == 0 then 'Stocked Out'
                      elsif us == 0 then 'No Sales'
                      elsif cover > 90 then 'Excess'
                      elsif cover < 14 then 'Low'
                      else 'Healthy'
                      end
end
tables['Fact_Inventory_Monthly'] = [h + %w[cover_days stock_status], rows]

# ---------------------------------------------------------------- data quality checks
# Each check: [area, check, Excel formula, value computed here in Ruby, expected, kind, what it tests]
# kind: :num (exact), :round2 (compare rounded to 2 dp), :date
def uniq_dupes(rows, col); rows.size - rows.map { |r| r[col] }.uniq.size; end
def missing(fact, fcol, dim, dcol)
  keys = dim.map { |r| r[dcol] }.to_h { |k| [k, true] } rescue dim.map { |r| [r[dcol], true] }.to_h
  fact.count { |r| !keys[r[fcol]] }
end
d = ->(t) { tables[t][1] }
sales = d['Fact_Sales']; inv = d['Fact_Inventory_Monthly']; po = d['Fact_Purchase_Orders']
sale_dates = sales.map { |r| r['date'] }.sort
excel_date = ->(s) { (Date.parse(s) - EPOCH).to_i }

CHECKS = [
  ['Completeness', 'Rows in Fact_Sales', 'ROWS(Fact_Sales[sale_id])', sales.size, 271871, :num, 'All sales rows were loaded'],
  ['Completeness', 'Rows in Fact_Inventory_Monthly', 'ROWS(Fact_Inventory_Monthly[product_id])', inv.size, 30480, :num, '24 stores x 60 products x months on sale'],
  ['Completeness', 'Rows in Fact_Purchase_Orders', 'ROWS(Fact_Purchase_Orders[po_id])', po.size, 23418, :num, 'All purchase orders were loaded'],
  ['Completeness', 'Rows in Dim_Date', 'ROWS(Dim_Date[date])', d['Dim_Date'].size, 730, :num, 'One row per day for 2 years (no gaps)'],
  ['Uniqueness', 'Duplicate product_id in Dim_Product', 'ROWS(Dim_Product[product_id])-SUMPRODUCT(1/COUNTIF(Dim_Product[product_id],Dim_Product[product_id]))', uniq_dupes(d['Dim_Product'], 'product_id'), 0, :num, 'A dimension key must appear only once'],
  ['Uniqueness', 'Duplicate store_id in Dim_Store', 'ROWS(Dim_Store[store_id])-SUMPRODUCT(1/COUNTIF(Dim_Store[store_id],Dim_Store[store_id]))', uniq_dupes(d['Dim_Store'], 'store_id'), 0, :num, 'A dimension key must appear only once'],
  ['Uniqueness', 'Duplicate supplier_id in Dim_Supplier', 'ROWS(Dim_Supplier[supplier_id])-SUMPRODUCT(1/COUNTIF(Dim_Supplier[supplier_id],Dim_Supplier[supplier_id]))', uniq_dupes(d['Dim_Supplier'], 'supplier_id'), 0, :num, 'A dimension key must appear only once'],
  ['Uniqueness', 'Duplicate dates in Dim_Date', 'ROWS(Dim_Date[date])-SUMPRODUCT(1/COUNTIF(Dim_Date[date],Dim_Date[date]))', uniq_dupes(d['Dim_Date'], 'date'), 0, :num, 'Each date must appear only once in the date table'],
  ['Validity', 'First sale date', 'MIN(Fact_Sales[date])', excel_date[sale_dates.first], excel_date['2022-01-01'], :date, 'Data starts when expected'],
  ['Validity', 'Last sale date', 'MAX(Fact_Sales[date])', excel_date[sale_dates.last], excel_date['2023-12-31'], :date, 'Data ends when expected'],
  ['Validity', 'Rows with zero or negative units sold', 'COUNTIF(Fact_Sales[units_sold],"<=0")', sales.count { |r| r['units_sold'].to_i <= 0 }, 0, :num, 'A sales row should always sell at least 1 unit'],
  ['Validity', 'Negative closing stock', 'COUNTIF(Fact_Inventory_Monthly[closing_stock],"<0")', inv.count { |r| r['closing_stock'].to_i < 0 }, 0, :num, 'Stock can never be below zero'],
  ['Validity', 'Discount outside 0-50%', 'COUNTIFS(Fact_Sales[discount_pct],"<0")+COUNTIFS(Fact_Sales[discount_pct],">50")', sales.count { |r| !(0..50).cover?(r['discount_pct'].to_i) }, 0, :num, 'Discounts should be within business rules'],
  ['Expected blanks', 'Open POs (blank delivery date)', 'COUNTBLANK(Fact_Purchase_Orders[actual_delivery_date])', po.count { |r| r['actual_delivery_date'].to_s == '' }, 1714, :num, 'Not an error: orders still in transit on 31 Dec 2023'],
  ['Consistency', 'Stock balance errors (open + received - sold <> closing)', 'SUMPRODUCT(--(Fact_Inventory_Monthly[opening_stock]+Fact_Inventory_Monthly[units_received]-Fact_Inventory_Monthly[units_sold]<>Fact_Inventory_Monthly[closing_stock]))', inv.count { |r| r['opening_stock'].to_i + r['units_received'].to_i - r['units_sold'].to_i != r['closing_stock'].to_i }, 0, :num, 'Stock movements must add up every month'],
  ['Consistency', 'Net revenue greater than gross revenue', 'SUMPRODUCT(--(Fact_Sales[net_revenue_inr]>Fact_Sales[gross_revenue_inr]))', sales.count { |r| r['net_revenue_inr'].to_f > r['gross_revenue_inr'].to_f + 0.001 }, 0, :num, 'A discount can only reduce revenue'],
  ['Consistency', 'Sold more than demanded', 'SUMPRODUCT(--(Fact_Inventory_Monthly[units_sold]>Fact_Inventory_Monthly[actual_demand_units]))', inv.count { |r| r['units_sold'].to_i > r['actual_demand_units'].to_i }, 0, :num, 'You cannot sell more than customers wanted'],
  ['Referential integrity', 'Sales rows with product_id not in Dim_Product', 'SUMPRODUCT(--ISNA(MATCH(Fact_Sales[product_id],Dim_Product[product_id],0)))', missing(sales, 'product_id', d['Dim_Product'], 'product_id'), 0, :num, 'Every fact ID must exist in its dimension'],
  ['Referential integrity', 'Sales rows with store_id not in Dim_Store', 'SUMPRODUCT(--ISNA(MATCH(Fact_Sales[store_id],Dim_Store[store_id],0)))', missing(sales, 'store_id', d['Dim_Store'], 'store_id'), 0, :num, 'Every fact ID must exist in its dimension'],
  ['Referential integrity', 'PO rows with supplier_id not in Dim_Supplier', 'SUMPRODUCT(--ISNA(MATCH(Fact_Purchase_Orders[supplier_id],Dim_Supplier[supplier_id],0)))', missing(po, 'supplier_id', d['Dim_Supplier'], 'supplier_id'), 0, :num, 'Every fact ID must exist in its dimension'],
  ['Reconciliation', 'Total net revenue (Rs Crore)', 'SUM(Fact_Sales[net_revenue_inr])/10^7', (sales.sum { |r| r['net_revenue_inr'].to_f } / 1e7), 127.25, :round2, 'Matches the figure used throughout the project'],
  ['Reconciliation', 'Total units sold', 'SUM(Fact_Sales[units_sold])', sales.sum { |r| r['units_sold'].to_i }, 433264, :num, 'Matches the figure used throughout the project'],
]

# ---------------------------------------------------------------- xlsx writer
def col_letter(i)
  s = ''
  i += 1
  while i > 0
    i, rem = (i - 1).divmod(26)
    s = (65 + rem).chr + s
  end
  s
end

def esc(s)
  s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
end

NS = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
RNS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
# cell styles: 0 normal, 1 date, 2 header (bold white on maroon), 3 title, 4 pass (green), 5 fail (red), 6 wrap text, 7 date bold, 8 number 2dp
STYLES = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="#{NS}"><numFmts count="2"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/><numFmt numFmtId="165" formatCode="#,##0.00"/></numFmts><fonts count="5"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font><font><b/><sz val="16"/><color rgb="FF7B1E3A"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FF1E7B34"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFC0392B"/><name val="Calibri"/></font></fonts><fills count="5"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF7B1E3A"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFE3F4E6"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFBE3E1"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFBBBBBB"/></left><right style="thin"><color rgb="FFBBBBBB"/></right><top style="thin"><color rgb="FFBBBBBB"/></top><bottom style="thin"><color rgb="FFBBBBBB"/></bottom><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="9"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/><xf numFmtId="0" fontId="3" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf><xf numFmtId="0" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf><xf numFmtId="165" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>)

def write_book(out, tables, checks: nil)
  strings = {}
  sst = []
  si = lambda { |s| strings[s] ||= (sst << s; sst.size - 1) }
  dir = Dir.mktmpdir('biba_xlsx')
  FileUtils.mkdir_p(%W[#{dir}/_rels #{dir}/xl/_rels #{dir}/xl/worksheets/_rels #{dir}/xl/tables])
  sheet_names = []
  table_sheets = []

  if checks
    sheet_names << 'Checks'
    n = sheet_names.size
    pass_all = checks.all? { |c| c[5] == :round2 ? c[3].round(2) == c[4] : c[3] == c[4] }
    File.open("#{dir}/xl/worksheets/sheet#{n}.xml", 'w') do |f|
      f << %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="#{NS}" xmlns:r="#{RNS}">)
      f << %(<sheetViews><sheetView workbookViewId="0" tabSelected="1"><pane ySplit="4" topLeftCell="A5" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>)
      f << %(<cols><col min="1" max="1" width="5" customWidth="1"/><col min="2" max="2" width="20" customWidth="1"/><col min="3" max="3" width="44" customWidth="1"/><col min="4" max="5" width="14" customWidth="1"/><col min="6" max="6" width="9" customWidth="1"/><col min="7" max="7" width="46" customWidth="1"/><col min="8" max="8" width="70" customWidth="1"/></cols><sheetData>)
      f << %(<row r="1"><c r="A1" s="3" t="s"><v>#{si.call('BIBA StyleIQ - Data Quality Checks (Day 2)')}</v></c></row>)
      f << %(<row r="2"><c r="A2" t="s"><v>#{si.call('Each Result is a live Excel formula on the data sheets in this workbook. Status compares Result with Expected. Simulated, BIBA-inspired data.')}</v></c></row>)
      f << %(<row r="3"><c r="A3" t="s"><v>#{si.call('Checks passed:')}</v></c><c r="C3" t="str"><f>COUNTIF(F5:F#{4 + checks.size},"Pass")&amp;" of "&amp;#{checks.size}</f><v>#{esc(pass_all ? "#{checks.size} of #{checks.size}" : '?')}</v></c></row>)
      hdr = ['#', 'Area', 'Check', 'Result', 'Expected', 'Status', 'What it tests', 'Excel formula used']
      f << '<row r="4" ht="20" customHeight="1">' + hdr.each_with_index.map { |h, i| %(<c r="#{col_letter(i)}4" s="2" t="s"><v>#{si.call(h)}</v></c>) }.join + '</row>'
      checks.each_with_index do |(area, name, formula, val, exp, kind, why), i|
        r = i + 5
        ok = kind == :round2 ? val.round(2) == exp : val == exp
        num_style = kind == :date ? 7 : (kind == :round2 ? 8 : 6)
        status_f = kind == :round2 ? %(IF(ROUND(D#{r},2)=E#{r},"Pass","Fail")) : %(IF(D#{r}=E#{r},"Pass","Fail"))
        f << %(<row r="#{r}">)
        f << %(<c r="A#{r}" s="6"><v>#{i + 1}</v></c>)
        f << %(<c r="B#{r}" s="6" t="s"><v>#{si.call(area)}</v></c>)
        f << %(<c r="C#{r}" s="6" t="s"><v>#{si.call(name)}</v></c>)
        f << %(<c r="D#{r}" s="#{num_style}"><f>#{esc(formula)}</f><v>#{kind == :round2 ? val.round(6) : val}</v></c>)
        f << %(<c r="E#{r}" s="#{num_style}"><v>#{exp}</v></c>)
        f << %(<c r="F#{r}" s="#{ok ? 4 : 5}" t="str"><f>#{esc(status_f)}</f><v>#{ok ? 'Pass' : 'Fail'}</v></c>)
        f << %(<c r="G#{r}" s="6" t="s"><v>#{si.call(why)}</v></c>)
        f << %(<c r="H#{r}" s="6" t="s"><v>#{si.call('=' + formula)}</v></c>)
        f << '</row>'
      end
      f << %(</sheetData><conditionalFormatting sqref="F5:F#{4 + checks.size}"><cfRule type="cellIs" dxfId="0" priority="1" operator="equal"><formula>"Fail"</formula></cfRule></conditionalFormatting></worksheet>)
    end
  end

  tables.each do |name, (headers, rows)|
    sheet_names << name
    n = sheet_names.size
    table_sheets << n
    last = "#{col_letter(headers.size - 1)}#{rows.size + 1}"
    File.open("#{dir}/xl/worksheets/sheet#{n}.xml", 'w') do |f|
      f << %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n)
      f << %(<worksheet xmlns="#{NS}" xmlns:r="#{RNS}"><dimension ref="A1:#{last}"/>)
      f << %(<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>)
      f << %(<sheetFormatPr defaultRowHeight="15"/><sheetData>)
      f << %(<row r="1">)
      headers.each_with_index { |hd, ci| f << %(<c r="#{col_letter(ci)}1" t="s"><v>#{si.call(hd)}</v></c>) }
      f << '</row>'
      rows.each_with_index do |r, ri|
        rn = ri + 2
        f << %(<row r="#{rn}">)
        headers.each_with_index do |hd, ci|
          v = r[hd]
          next if v.nil? || v == ''
          ref = "#{col_letter(ci)}#{rn}"
          if DATE_COLS.include?(hd)
            f << %(<c r="#{ref}" s="1"><v>#{(Date.parse(v) - EPOCH).to_i}</v></c>)
          elsif v =~ NUM_RE && !hd.end_with?('_id')
            f << %(<c r="#{ref}"><v>#{v}</v></c>)
          else
            f << %(<c r="#{ref}" t="s"><v>#{si.call(v)}</v></c>)
          end
        end
        f << '</row>'
      end
      f << %(</sheetData><tableParts count="1"><tablePart r:id="rId1"/></tableParts></worksheet>)
    end
    tid = table_sheets.size
    File.write("#{dir}/xl/worksheets/_rels/sheet#{n}.xml.rels",
               %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="#{RNS}/table" Target="../tables/table#{tid}.xml"/></Relationships>))
    cols = headers.each_with_index.map { |hd, ci| %(<tableColumn id="#{ci + 1}" name="#{esc(hd)}"/>) }.join
    File.write("#{dir}/xl/tables/table#{tid}.xml",
               %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<table xmlns="#{NS}" id="#{tid}" name="#{name}" displayName="#{name}" ref="A1:#{last}" totalsRowShown="0"><autoFilter ref="A1:#{last}"/><tableColumns count="#{headers.size}">#{cols}</tableColumns><tableStyleInfo name="TableStyleMedium2" showFirstColumn="0" showLastColumn="0" showRowStripes="1" showColumnStripes="0"/></table>))
  end

  File.open("#{dir}/xl/sharedStrings.xml", 'w') do |f|
    f << %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<sst xmlns="#{NS}" count="#{sst.size}" uniqueCount="#{sst.size}">)
    sst.each { |s| f << %(<si><t xml:space="preserve">#{esc(s)}</t></si>) }
    f << '</sst>'
  end
  styles = checks ? STYLES.sub('</cellStyles>', '</cellStyles><dxfs count="1"><dxf><font><b/><color rgb="FFC0392B"/></font><fill><patternFill><bgColor rgb="FFFBE3E1"/></patternFill></fill></dxf></dxfs>') : STYLES
  File.write("#{dir}/xl/styles.xml", styles)

  sheets = sheet_names.each_with_index.map { |n, i| %(<sheet name="#{n}" sheetId="#{i + 1}" r:id="rId#{i + 1}"/>) }.join
  calc = checks ? '<calcPr calcId="191029" fullCalcOnLoad="1"/>' : ''
  File.write("#{dir}/xl/workbook.xml", %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<workbook xmlns="#{NS}" xmlns:r="#{RNS}"><bookViews><workbookView/></bookViews><sheets>#{sheets}</sheets>#{calc}</workbook>))
  k = sheet_names.size
  wrels = sheet_names.each_with_index.map { |_, i| %(<Relationship Id="rId#{i + 1}" Type="#{RNS}/worksheet" Target="worksheets/sheet#{i + 1}.xml"/>) }.join
  wrels += %(<Relationship Id="rId#{k + 1}" Type="#{RNS}/styles" Target="styles.xml"/><Relationship Id="rId#{k + 2}" Type="#{RNS}/sharedStrings" Target="sharedStrings.xml"/>)
  File.write("#{dir}/xl/_rels/workbook.xml.rels", %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">#{wrels}</Relationships>))
  File.write("#{dir}/_rels/.rels", %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="#{RNS}/officeDocument" Target="xl/workbook.xml"/></Relationships>))
  ov = sheet_names.each_with_index.map { |_, i| %(<Override PartName="/xl/worksheets/sheet#{i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>) }.join
  ov += table_sheets.each_index.map { |t| %(<Override PartName="/xl/tables/table#{t + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml"/>) }.join
  File.write("#{dir}/[Content_Types].xml", %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/><Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>#{ov}</Types>))

  File.delete(out) if File.exist?(out)
  Dir.chdir(dir) { system('zip', '-q', '-X', '-D', '-r', out, '[Content_Types].xml', '_rels', 'xl') or abort('zip failed') }
  FileUtils.rm_rf(dir)
  puts "Wrote #{out} (#{(File.size(out) / 1e6).round(1)} MB)"
end

tables.each { |k, (hd, rs)| puts "#{k}: #{rs.size} rows, #{hd.size} columns" }
write_book(OUT, tables)
write_book(CHECKS_OUT, tables, checks: CHECKS)
puts 'Data quality checks:'
CHECKS.each_with_index do |(area, name, _, val, exp, kind), i|
  ok = kind == :round2 ? val.round(2) == exp : val == exp
  shown = kind == :round2 ? val.round(4) : val
  puts format('  %2d %-4s %-22s %-58s result=%-10s expected=%s', i + 1, ok ? 'PASS' : 'FAIL', area, name, shown, exp)
end
