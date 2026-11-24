# BIBA StyleIQ — Power BI Online Edition (Mac + college account)

Use this guide **together with** `BIBA_StyleIQ_Step_by_Step_Guide.md` (the "main guide").
- This guide replaces the steps that are different online: **setup, loading data, the data model, What-if parameters, and publishing**.
- For DAX formulas, charts, page layouts, 📘 Study boxes and ✅ checkpoint numbers, it sends you to the right section of the main guide. Those work the same online.

> **Why a separate edition?** Power BI Desktop (the app the main guide uses) only runs on Windows. Power BI Online (app.powerbi.com, the same thing you see in Teams) runs in any browser on your Mac. It can do almost everything this project needs, with three differences:
> 1. **No Power Query for files on your computer.** So the cleaning and transformation columns from main-guide Days 2–3 have been **pre-built into the Excel file** for you. You'll study what they do instead of clicking them.
> 2. **No "New parameter" button.** We build the What-if parameters with a short DAX formula instead (Day 10), which is actually a good thing to understand.
> 3. **The data model is edited in the browser** ("Open data model"), and it saves automatically.

> Power BI Online's menus move around a little with updates. If a button isn't exactly where this guide says, look for the same word in the top ribbon, the **…** (more options) menu, or the right-hand **Properties** pane.

---

## Day 0: Setup (30 minutes)

### 0.1 Use the browser, not Teams, for building

Power BI inside Teams is the same service, but squeezed into a smaller window. Build in a browser (Chrome or Edge work best; Safari is fine) and use Teams at the end to **share** the report.

1. Go to **app.powerbi.com** and sign in with your **college email**.
2. Click your profile picture (top-right) to see your licence. **Free** is enough to build in *My workspace*. **Pro** (many colleges include it) also lets you share. Note which one you have.
3. In the left bar, click **My workspace**. This is where your project will live.

### 0.2 The file you'll upload

In Finder: `Documents → BIBA_StyleIQ_Project → BIBA_StyleIQ → Dataset → BIBA_StyleIQ_Data.xlsx` (14.5 MB).

It contains all 7 tables, one per sheet, each formatted as an Excel Table with the same name as the sheet. **Open it in Excel on your Mac first** and click through the sheets so you know what's inside. (Read `Dataset/README_Data.md` alongside it.)

Columns that were added to save you Power Query work (they're explained on Day 3):

| Table | Extra columns |
|---|---|
| Dim_Date | `season_order` |
| Dim_Product | `margin_pct`, `price_band`, `price_band_order`, `lead_time_days` |
| Fact_Purchase_Orders | `shipment_type`, `delay_days`, `actual_lead_time_days` (and `delivery_status` is already split) |
| Fact_Inventory_Monthly | `cover_days`, `stock_status` |

---

## Day 1: Recap

✅ **Done.** Your completed Day 1 work is in `Documentation/Day1_Notes.md`: the project brief, BIBA business notes, the problem statement, why the data is simulated, the dataset inventory, business questions, and the KPI-to-column map. Read it fully, practise the "say it out loud" answer in Step 3, and answer the self-check questions at the end. Background: main guide **Section 1** and `Documentation/BIBA_StyleIQ_Day1_Findings.md`.

---

## Day 2: Data quality checks in Excel, then upload (2 hours)

Desktop users check data quality in Power Query. You'll do the same checks in **Excel**, which is a useful skill on its own.

### 2.1 Data quality checks in Excel

✅ **Done for you:** `Documentation/Data_Quality_Checks.xlsx`. It's the full dataset plus a **Checks** sheet (the first tab) with **22 live Excel formulas** across 6 areas. Each row shows the Result, the Expected value, Pass/Fail, what the check tests, and the formula used. **All 22 pass.**

**Your part (30 min):**
1. Open `Data_Quality_Checks.xlsx` in Excel. It recalculates when it opens (about 10–20 seconds for 270K rows). If Excel asks to **Enable Editing** or **update/recalculate**, click yes.
2. Confirm the top says **Checks passed: 22 of 22**.
3. Click a few **Result** cells and read the formula in the formula bar. Because the data is in named Excel Tables, formulas refer to columns by name (`Fact_Sales[units_sold]`).
4. Try to break one check to see it work: go to the `Dim_Store` sheet, change `S02` to `S01` (creating a duplicate ID), and watch check 6 turn to **Fail**. Then press **Cmd + Z** to undo, and close **without saving**.
5. Be able to explain each of the 6 areas in one line:

| Area | Checks | What it means |
|---|---|---|
| Completeness | 1–4 | All rows arrived; the date table has no gaps |
| Uniqueness | 5–8 | Each dimension key (product, store, supplier, date) appears once |
| Validity | 9–13 | Values are possible: dates in range, no negative stock, discounts within rules |
| Expected blanks | 14 | 1,714 blank delivery dates are **correct**: orders still in transit |
| Consistency | 15–17 | Numbers agree with each other: stock balances add up, net ≤ gross, sold ≤ demanded |
| Referential integrity | 18–20 | Every ID in a fact table exists in its dimension table |
| Reconciliation | 21–22 | Totals match the figures used across the project (₹127.25 Cr, 433,264 units) |

📘 **Study:** referential integrity matters because if a fact row's ID is missing from its dimension, Power BI shows a "(Blank)" item in slicers and totals don't add up. **Interview line:** *"Before building anything, I ran 22 data quality checks across completeness, uniqueness, validity, consistency, referential integrity and reconciliation."*

**Don't upload this checks file** to Power BI. Upload the original `Dataset/BIBA_StyleIQ_Data.xlsx` (next step).

### 2.2 Upload the original file to Power BI

> **Route that works:** on this account, *Import → From this computer* greys out Excel files, so use **Create**.

1. In the left bar, click **Create** → under "Add data to start building a report", click **Excel** (or **More data sources** → Excel).
2. **Upload file → Browse** → select `Dataset/BIBA_StyleIQ_Data.xlsx` → **Next**.
3. In the list of what's in the file, each name appears twice (as a sheet and as an Excel Table). **Tick only one of each**: the 7 tables `Dim_Date`, `Dim_Product`, `Dim_Store`, `Dim_Supplier`, `Fact_Sales`, `Fact_Inventory_Monthly`, `Fact_Purchase_Orders`.
4. **Power Query** opens with **Queries [7]** on the left. Check each column's type icon (calendar = date, 1²3 = whole number, 1.2 = decimal, ABC = text). Fix one auto-guess: in `Dim_Date`, click the **calendar icon in the `year_month` header** → **Text** → **Replace current**, so it shows `2022-01` (not `1/1/2022`). Make sure `date` stays a **Date**.
   - 📘 This is Power Query's automatic **Changed type** step (see *Applied steps* on the right). You're correcting one of its guesses.
   - Each column's type icon sits at the left edge of **its own** header. Click the icon of the exact column you want to change.
   - **Check `Dim_Store`:** every column in it is text, so Power Query may *not* promote the first row to headers. You'd see `Column1…Column6` with `store_id, store_name…` in row 1 (25 rows instead of 24). Fix: select `Dim_Store` → **Transform → Use first row as headers**. If you only notice after creating relationships, delete the relationships to `Dim_Store (Column1)` first, fix the headers (**Queries ▾ → Transform data**), then recreate them.
5. Click the **▾** next to *Create a report* → **Create semantic model only** → name it **BIBA StyleIQ** → workspace **My workspace** → **Create**.
6. ✅ **Checkpoint:** My workspace shows **BIBA StyleIQ** with type **Semantic model**. No duplicate tables to clean up, because you ticked only 7.

📘 **Study: what's a semantic model?** It's Power BI's name for the dataset plus everything you add to it: relationships, measures, formats. Reports are built *on top of* a semantic model. One model can feed many reports.

> **If the upload fails:** check the file is the original (14.5 MB) and that you're in *My workspace*. If your college blocks uploads, upload the file to your college **OneDrive** first, then in Power BI choose **Upload → OneDrive** and pick it there.

---

## Day 3: Understand the pre-built columns (1.5 hours)

📄 **Study notes for Days 2–3:** `Documentation/BIBA_StyleIQ_Day2_Day3_Notes.docx` has the 22 checks explained, the Power Query concepts, each prepared column with worked examples from the data, Power Query vs DAX, and a 10-question self-check.

There's nothing to click today. Instead, learn **what each added column does and how it would be built**, because you'll be asked about it. For each one, read the explanation and copy the formula into your notes.

| Column | What it means | How it was made (Power Query M, as in the main guide) |
|---|---|---|
| `Fact_Purchase_Orders[delay_days]` | Days late vs the promised date (negative = early) | `Duration.Days([actual_delivery_date] - [expected_delivery_date])` |
| `Fact_Purchase_Orders[actual_lead_time_days]` | Days from ordering to receiving | `Duration.Days([actual_delivery_date] - [order_date])` |
| `Fact_Purchase_Orders[delivery_status]` / `[shipment_type]` | The original "Late - Short Shipped" split into two clean columns: **On Time / Late / Open** and **Full / Short Shipped** | Split Column by delimiter `" - "` |
| `Dim_Product[margin_pct]` | Gross margin per product (0.56–0.64) | `1 - [unit_cost_inr] / [mrp_inr]` |
| `Dim_Product[price_band]` + `[price_band_order]` | Price grouping and its sort order | Conditional column (< 1500, < 3000, < 6000, else) |
| `Dim_Product[lead_time_days]` | The supplier's promised lead time, copied onto each product | DAX: `LOOKUPVALUE ( Dim_Supplier[contracted_lead_time_days], Dim_Supplier[supplier_id], Dim_Product[supplier_id] )` |
| `Dim_Date[season_order]` | 1 Winter, 2 Summer, 3 Monsoon, 4 Festive: sort order for seasons | Conditional column |
| `Fact_Inventory_Monthly[cover_days]` | How many days that month-end stock would last at that month's sales rate | DAX in main guide **5.5** |
| `Fact_Inventory_Monthly[stock_status]` | Stocked Out / Low (< 14 days) / Healthy / Excess (> 90 days) / No Sales | DAX `SWITCH(TRUE(), …)` in main guide **5.5** |

Then read the 📘 Study boxes in main guide **Section 3** ("Applied Steps are a recipe", "one fact per column") and **5.5** (`SWITCH(TRUE())`, business-rule thresholds).

**Interview line:** *"I used Power BI Online, so I prepared the transformation columns upstream in the data file; in Power BI Desktop I'd do the same in Power Query, as split columns, custom columns and conditional columns."*

---

## Day 4: Build the data model in the browser (2–3 hours)

Read the 📘 Study boxes in main guide **Section 4** first (star schema, single direction).

### 4.1 Open the data model

1. In **My workspace**, click the **semantic model** `BIBA_StyleIQ_Data` (the icon looks like a small database/cube; not the report).
2. On the model's page, click **Open data model** (top bar). (If you only see *Explore* / *Create a report*, look under the **…** menu or **File → Open data model**.)
3. You're now in the web **Model view**, with 7 tables as boxes. Changes save **automatically**.

> **If "Open data model" is greyed out or missing**, your college's Power BI admin has the setting *"Users can edit data models in the Power BI service"* turned off. Email your college IT or Power BI admin and ask them to enable it for you (quote that exact setting name). This is the only step you can't work around online.

### 4.2 Check the data types

Click a column in a table box. The **Properties** pane on the right shows its **Data type** and **Format**. Check:
- All date columns → **Date** (if one shows *Date/Time*, change Data type to **Date**, or set Format to a date-only format like `yyyy-mm-dd`).
- All `_id` columns → **Text**.
- Money columns (`_inr`) → **Decimal number** or **Fixed decimal number**. Format → **Currency**, symbol **₹**.
- `margin_pct` → Format **Percentage**.
- `Dim_Date[year]` → Whole number, and under **Advanced → Summarize by → None**.
- `mrp_inr`, `unit_cost_inr`, `margin_pct`, `lead_time_days`, `contracted_lead_time_days` → Summarize by **None**.

### 4.3 Remove automatic relationships, then create the right ones

Power BI may have guessed some relationships during upload (lines between boxes). Click each line → **Delete**, or open **Manage relationships** (top ribbon) and delete them all. Then create the **10 relationships** in the table in main guide **4.2**, either by dragging a dimension column onto the matching fact column, or **Manage relationships → New relationship**. For each one, check:
- **Cardinality: Many to one** (fact → dimension) / One to many (dimension → fact)
- **Cross-filter direction: Single**
- **Active: yes**

Again: **don't** link Dim_Supplier to Dim_Product (main guide 4.2 explains why; `lead_time_days` is already in Dim_Product).

### 4.4 Mark the date table, sort-by columns, hide IDs

- Select `Dim_Date` → **Mark as date table** (ribbon, or right-click the table, or Properties) → column `date`.
- Sort-by-column: select the column → **Properties → Advanced → Sort by column**:
  - `Dim_Date[month_name]` → `month_no`
  - `Dim_Date[weekday]` → `weekday_no`
  - `Dim_Date[season]` → `season_order`
  - `Dim_Product[price_band]` → `price_band_order`
- Data category: `Dim_Store[city]` → **City**, `Dim_Store[state]` → **State or Province** (Properties → Advanced → Data category).
- Hide the ID and date columns **in the fact tables** (right-click → **Hide**, or Properties → **Is hidden**): `product_id`, `store_id`, `supplier_id`, `date`, `month_end_date`, `order_date`.

### 4.5 Create a measures table

Online there may be no *Enter data* button, so create it with DAX:
1. **New table** (top ribbon) → type `_Measures = ROW ( "x", 1 )` → Enter.
2. Right-click column `x` → **Hide**. (Keep it; a table needs at least one column.)

✅ **Checkpoint:** 8 tables (7 + `_Measures`), 10 solid relationship lines, each with **1** on the dimension side and **\*** on the fact side. Take a screenshot (**Cmd + Shift + 4**, then drag) and save it to `Screenshots/00_Data_Model.png`; it goes in your GitHub README.

---

## Day 5: DAX measures (3 hours)

Follow main guide **Section 5** almost exactly. Differences online:

- **Where:** in the web data model, select `_Measures` → **New measure** (top ribbon, or right-click the table). Type the formula in the formula bar → Enter (or click ✓).
- **Format & folder:** with the measure selected, use the **Properties** pane: **Format** (Currency ₹ / Percentage / Whole number / Custom) and **Display folder**.
- **Skip creating** `cover_days`, `stock_status` (5.5) and `lead_time_days` (5.6): they already exist in the data. Still read those sections to understand them.
- Because those columns already exist, you can create the measures **in the order they're listed** (ignore the "do 5.5 first" note).
- Custom format for `Net Revenue (Cr)`: Properties → Format → **Custom** → `"₹"#,0.00" Cr"`. If custom formats aren't offered, use Decimal with 2 places; the card title will say "(Cr)" anyway.

### ✅ Checkpoint

Do the checkpoint at the end of main guide **Section 5** (build a quick test page with cards; you'll create the report on Day 6, so you can do this check on the first page there). Every number should match: ₹127.25 Cr, 433,264 units, 58.1% margin, 7.6% lost sales, 83.5% on-time, and so on.

---

## Day 6–9: Build the report pages

### Create the report (once)

1. Go back to **My workspace** → click the semantic model `BIBA_StyleIQ_Data` → **Create a report → Start from scratch** (or *Blank report*).
2. You're in **Edit** mode, with the same panes as Desktop on the right: **Filters**, **Visualizations** (build + format), **Data**.
3. **Save immediately:** **File → Save** → name it `BIBA StyleIQ`. Save often. (Unlike the model, **reports don't auto-save**.)
4. Canvas: click empty canvas → **Format page → Canvas settings → 16:9**; **Canvas background** colour `#FAF6F0`.

### Then follow the main guide

| Day | Main guide section | Online notes |
|---|---|---|
| 6 | **6. Executive Overview** | Same. Gridlines/snap: **View** menu, if available. |
| 7 | **7. Product & Sales** + drill-through page | Same. When you paste slicers onto a new page and Power BI asks to **sync**, click **Sync**. |
| 8 | **8. Inventory & Supplier Intelligence** | Same. |
| 9 | **9. Seasonal Demand** | Same. |

Tips for the browser:
- **Copy/paste visuals:** Cmd + C / Cmd + V.
- If you need to add or fix a **measure** while building the report, you can create it from the report too (**Data** pane → `_Measures` → **…** → *New measure*), but it's better to keep all measures in the data model, so prefer going back to **Open data model**.
- **Reading view** (top bar) shows how users will see it; **Edit** switches back.

---

## Day 10: Planning Simulator: What-if parameters without the button (3 hours)

Read main guide **10 (intro)** and the 📘 Study box in **10.1**.

> **Your college's version has a New parameter button** in the data-model ribbon. If **New parameter ▾ → Numeric range** works, you can follow main guide **10.1** exactly and skip 10.1–10.2 below. The DAX method below builds the same thing by hand: a small disconnected table of numbers, plus a measure that reads the selected value. It's worth knowing for interviews either way.

### 10.1 Create the parameter tables (in Open data model)

**New table**, three times:

```
Demand Uplift % = GENERATESERIES ( 0, 50, 5 )
```
```
Safety Stock Days = GENERATESERIES ( 0, 30, 1 )
```
```
Extra Lead Time Days = GENERATESERIES ( 0, 20, 1 )
```

Each table has one column called `Value`. **Don't** create relationships for them; they must stay disconnected.

### 10.2 Create the "selected value" measures (in `_Measures`, folder `6 Scenario`)

```
Demand Uplift % Value = SELECTEDVALUE ( 'Demand Uplift %'[Value], 0 )
```
```
Safety Stock Days Value = SELECTEDVALUE ( 'Safety Stock Days'[Value], 12 )
```
```
Extra Lead Time Days Value = SELECTEDVALUE ( 'Extra Lead Time Days'[Value], 0 )
```

📘 **Study:** `SELECTEDVALUE(column, default)` returns the value picked in a slicer, or the **default** if nothing (or more than one value) is picked. So with no selection, the simulator uses 0% uplift, 12 safety days and 0 extra lead days.

### 10.3 Scenario measures

Create all six measures from main guide **10.2** exactly as written (`Avg Daily Demand`, `Scenario Daily Demand`, `Reorder Point Units`, `Recommended Order Units`, `Recommended Order Value`, `Store-SKUs to Reorder`). They already use the `… Value` measure names above, and `Dim_Product[lead_time_days]` already exists.

### 10.4 Build the page

Follow main guide **10.3**, with one change: the three parameter slicers use the tables you made:
- Slicer field `'Demand Uplift %'[Value]` → title "Demand uplift %". Style **Dropdown** (or Tile), **Single select: On**.
- Same for `'Safety Stock Days'[Value]` and `'Extra Lead Time Days'[Value]`.
- Pick **0**, **12** and **0** before saving, so the report opens on the base scenario.

Then run and record the scenario table in main guide **10.4**.

---

## Day 11: Polish

Follow main guide **Section 11**, with these online notes:

| Main guide step | Online |
|---|---|
| 11.1 Theme | **View → Themes**. Pick a built-in theme, or **Customize current theme** if offered. Otherwise set colours per visual (Format → Colors). |
| 11.2 Page navigator | **Insert → Buttons → Navigator → Page navigator**. Same. Hide pages: right-click the page tab → **Hide page**. |
| 11.3 Tooltip page | **Format page → Page information → Allow use as tooltip**, and **Canvas settings → Type: Tooltip**. Same. |
| 11.4 Bookmarks | **View → Bookmarks** and **View → Selection**. Same. |
| 11.5 Edit interactions | Select a visual → **Format → Edit interactions** (top ribbon). Same. |
| 11.6 Dynamic titles | Same (Format → General → Title → **fx**). |
| 11.7 Alt text, tab order | Same. |
| 11.8 Performance analyzer | Usually not available online. Skip. |

---

## Day 12: Validate, export, share, GitHub, resume

### 12.1 Validation

Do the checklist in main guide **12.1** in **Reading view**.

### 12.2 Screenshots, PDF, video (on a Mac)

- **Screenshot** a page: switch to Reading view, then press **Cmd + Shift + 4** and drag over the report (or **Cmd + Shift + 4, then Space**, then click the browser window). Files go to your Desktop; move them into `Screenshots/` as `01_Executive.png`, `02_Product_Sales.png`, …
- **PDF:** **File → Export → PDF** (or *Export to PDF*) → save into `PowerBI/`.
- **Walkthrough video (recommended):** press **Cmd + Shift + 5** → *Record Selected Portion* → record 2–3 minutes explaining problem → insights → simulator.
- **Download a copy (if allowed):** **File → Download this file → A copy of your report and data (.pbix)**. If it's offered, save it into `PowerBI/`. If not, the PDF and screenshots are enough.

### 12.3 Share it in Teams (needs a Pro licence for you and your viewers)

- In Power BI, open the report → **Share** → enter a classmate's or professor's college email.
- Or in **Teams**: open a channel → **+** (Add a tab) → **Power BI** → pick your report. Everyone in the channel with access can open it.
- *Publish to web* (a public link) is normally disabled for college accounts. For your resume and GitHub, use screenshots, the PDF and the video.

### 12.4 GitHub and resume

Same as main guide **12.4** and **12.5**. Two additions:
- Upload `BIBA_StyleIQ_Data.xlsx` as well (14.5 MB fits GitHub's 25 MB web limit) and the `Generator/build_excel.rb` script.
- In the README's "Approach", say you built it in **Power BI Service (web)**: semantic model editing, DAX, report authoring. Mention you prepared transformations upstream because Power Query isn't available in the web editor for uploaded files. That shows you understand the tool's limits.

Resume skill line suggestion: *Microsoft Power BI (Service), DAX, Data Modelling, Excel*.

---

## Quick reference: Desktop vs Online for this project

| Task | Desktop (main guide) | Online (this guide) |
|---|---|---|
| Load data | 7 CSVs via Get data | 1 Excel file via Upload |
| Data quality checks | Power Query profiling | Excel formulas (Day 2) |
| Cleaning / new columns | Power Query (Day 3) | Pre-built in the file (study them) |
| Relationships, measures | Model view, Modeling tab | Open data model (auto-saves) |
| What-if parameters | Modeling → New parameter | `GENERATESERIES` tables + `SELECTEDVALUE` measures |
| Report building | Report view | Create a report (save manually) |
| Share | Publish → Service | Already in the Service; Share or Teams tab |
