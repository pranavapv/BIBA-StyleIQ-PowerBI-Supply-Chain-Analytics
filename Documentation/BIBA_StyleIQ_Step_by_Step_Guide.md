# BIBA StyleIQ — Complete Step-by-Step Power BI Guide

*A BIBA-inspired retail supply chain case study using a simulated dataset.*

> **Using a Mac / Power BI Online (app.powerbi.com or Teams)?** Start with `BIBA_StyleIQ_PowerBI_Online_Guide.md`. It replaces the setup, data-loading, modelling and What-if steps, and tells you which sections of this guide to follow for everything else.

This guide takes you from an empty Power BI file to a finished, five-page decision-support report. Every step says **what to click**, **what to type**, **why you're doing it**, and **what number you should see** so you can check yourself.

**How to use it**
- Do one Day at a time. Don't skip the "Why" lines; they are what you'll say in an interview.
- ✅ **Checkpoint** boxes give the exact number you should get. If yours is different, stop and fix it before moving on.
- 📘 **Study** boxes explain a concept. Write these into your own notes in your own words.
- Save your file after every Day (**Ctrl + S**), and also keep a copy named `BIBA_StyleIQ_DayX.pbix`, so you can go back if something breaks.

---

## Contents

0. Before you start: setup (important if you use a Mac)
1. Day 1 recap: what was done and what you should understand
2. Day 2: Import the data and explore Power Query
3. Day 3: Clean and transform in Power Query
4. Day 4: Build the data model (star schema)
5. Day 5: DAX measures and calculated columns
6. Day 6: Page 1, Executive Overview
7. Day 7: Page 2, Product & Sales Analytics (+ drill-through page)
8. Day 8: Page 3, Inventory & Supplier Intelligence
9. Day 9: Page 4, Seasonal Demand Analysis
10. Day 10: Page 5, Inventory Planning Simulator (What-if)
11. Day 11: Polish (theme, navigation, tooltips, bookmarks, interactions)
12. Day 12: Validate, document, publish, resume
13. Study notes: glossary, interview questions, common errors

---

## 0. Before you start: setup

### 0.1 Power BI Desktop needs Windows

Power BI Desktop (the free app you build reports in) **only runs on Windows**. There is no Mac version. Your options:

| Option | Notes |
|---|---|
| **A Windows laptop or desktop** (your own, a friend's, or a college computer lab) | Easiest and most reliable. |
| **Windows inside your Mac** using a virtual machine app such as Parallels Desktop | Works for many people, but it's paid software and needs a powerful Mac. Test that Power BI opens before you rely on it. |
| **Power BI in the browser** (app.powerbi.com) | Needs a work or school account (a Gmail address won't work; try your college email). It can build reports, but Power Query and modelling are limited. This guide is written for Desktop. |

**Recommendation:** use a Windows machine for building. Everything below assumes Power BI Desktop on Windows.

### 0.2 Install

1. On the Windows PC, open the **Microsoft Store**, search **Power BI Desktop**, and click **Get / Install**. (The Store version updates itself automatically.)
2. Open it. When it asks you to sign in, you can close that box; you don't need an account to build.

### 0.3 Copy the project folder

Copy the whole `BIBA_StyleIQ` folder to the Windows PC, for example to `C:\Projects\BIBA_StyleIQ\`. It contains:

```
BIBA_StyleIQ/
├── Dataset/          ← the 7 CSV files + README_Data.md (data dictionary)
├── Generator/        ← the script that created the data (for GitHub transparency)
├── Documentation/    ← this guide + Day 1 findings
├── PowerBI/          ← (create this) your .pbix file will live here
└── Screenshots/      ← (create this) dashboard images for GitHub
```

Create the `PowerBI` and `Screenshots` folders now.

### 0.4 Two settings to change first

Open Power BI Desktop → **File → Options and settings → Options**.

1. **CURRENT FILE → Data Load** → *untick* **Auto date/time**. Click OK.
   - *Why:* by default Power BI secretly creates a hidden date table for every date column. We have our own proper date table (`Dim_Date`), and hidden ones bloat the file and confuse time-intelligence DAX.
2. **GLOBAL → Regional settings** → set **Locale for import** to **English (India)**.
   - *Why:* makes ₹ formatting and Indian date conventions the default.

Then **File → Save As** → `PowerBI\BIBA_StyleIQ.pbix`.

---

## 1. Day 1 recap: what was done, and what you should understand

Day 1 was the **data discovery** phase. Read `Documentation/BIBA_StyleIQ_Day1_Findings.md` fully. In short:

1. The public BIBA GitHub dataset (4,544 rows) turned out to be **synthetic**: its "season" labels didn't match the dates, there was no festive peak, and the README's ₹29.68 Cr headline was miscalculated.
2. So we built a **new simulated dataset** designed like a real retailer's data warehouse. Read `Dataset/README_Data.md` fully; it's your data dictionary.

📘 **Study: why a consultant checks provenance first.** "Provenance" means *where data came from and whether you can trust it*. On a real EY engagement, the first week is often spent validating client data, because every insight built on bad data is wrong. Being able to say *"I found the public dataset was synthetic and its headline figure was miscalculated, so I rebuilt the data properly and disclosed it"* is a strong interview story.

**Try it yourself (15 min, optional but good practice):** open the old repo's `BIBA_Supply_chain1.csv` in Excel, insert a PivotTable with `Month` in rows, `season` in columns, and Count of `order_id` as values. You'll see every month has all four seasons, which proves the labels are random.

✅ **Completed Day 1 notes:** `Documentation/Day1_Notes.md` (project brief, business notes, dataset inventory, business questions, KPI-to-column map).

### What our dataset contains

| Table | Rows | One row means… | Type |
|---|---|---|---|
| Dim_Date | 730 | one day, 2022–2023 | Dimension |
| Dim_Product | 60 | one SKU (product) | Dimension |
| Dim_Store | 24 | one store (23 physical + Online) | Dimension |
| Dim_Supplier | 8 | one supplier | Dimension |
| Fact_Sales | 271,871 | units of one SKU sold in one store on one day | Fact |
| Fact_Inventory_Monthly | 30,480 | stock position of one SKU in one store at month end | Fact (snapshot) |
| Fact_Purchase_Orders | 23,418 | one replenishment order | Fact |

📘 **Study: fact vs dimension.**
- A **fact table** records *events or measurements* (a sale, a stock count, an order). It's long, mostly numbers plus ID columns.
- A **dimension table** *describes* things (what is product P001? which city is store S05?). It's short, mostly text.
- You *filter and group by* dimensions and *add up* facts.

---

## 2. Day 2: Import the data and explore Power Query (2–3 hours)

**Goal:** get all 7 CSVs into Power Query with the correct data types, and learn to read data quality.

### 2.1 Import the first file

1. **Home → Get data → Text/CSV**.
2. Browse to `Dataset\Dim_Date.csv` → **Open**.
3. A preview window appears. Check **File Origin: 65001: Unicode (UTF-8)** and **Delimiter: Comma**.
4. Click **Transform Data** (not Load).
   - *Why:* "Load" sends data straight into the model. "Transform Data" opens **Power Query Editor** so you can inspect and fix it first. A professional always inspects first.

### 2.2 Import the other six files inside Power Query

In Power Query Editor: **Home → New Source → Text/CSV**, then pick each remaining file and click **OK**:
`Dim_Product.csv`, `Dim_Store.csv`, `Dim_Supplier.csv`, `Fact_Sales.csv`, `Fact_Inventory_Monthly.csv`, `Fact_Purchase_Orders.csv`.

You now see 7 queries in the **Queries** pane on the left. Their names come from the file names. Leave them as they are.

### 2.3 Turn on data profiling

1. **View** tab → tick **Column quality**, **Column distribution**, **Column profile**.
2. At the very bottom-left of the window it says **"Column profiling based on top 1000 rows"**. Click it → choose **"Column profiling based on entire data set"**.
   - *Why:* by default Power Query only checks the first 1,000 rows. Errors can hide further down.

📘 **Study: reading the profile bars.** Under each column header:
- **Valid** (green) = good values. **Error** (red) = values that failed conversion. **Empty** (grey) = null or blank.
- **Distinct / Unique** = how many different values. An ID column in a dimension table should have *distinct = row count*.

### 2.4 Check and fix data types, table by table

Power Query guesses types automatically (look at the **Applied Steps** pane on the right: there's a step called **Changed Type**). Click each column-header icon (ABC = text, 123 = whole number, 1.2 = decimal, calendar = date) to check or change it.

**Rule:** IDs = Text. Counts of units/days = Whole Number. Money = Fixed Decimal Number (shows as **$** icon; it's just "currency precision", not dollars). Percentages = Decimal Number. Dates = Date.

| Query | Columns → type |
|---|---|
| Dim_Date | `date` → Date · `year`, `month_no`, `week_of_year`, `weekday_no` → Whole Number · everything else → Text |
| Dim_Product | `product_id`, `product_name`, `category`, `collection`, `fabric`, `supplier_id` → Text · `mrp_inr`, `unit_cost_inr` → Fixed Decimal · `launch_date` → Date |
| Dim_Store | all → Text |
| Dim_Supplier | `contracted_lead_time_days` → Whole Number · others → Text |
| Fact_Sales | `sale_id`, `store_id`, `product_id` → Text · `date` → Date · `units_sold`, `discount_pct` → Whole Number · `mrp_inr`, `gross_revenue_inr`, `net_revenue_inr`, `cogs_inr` → Fixed Decimal |
| Fact_Inventory_Monthly | `month_end_date` → Date · `store_id`, `product_id` → Text · all `_units`, `_stock`, `stockout_days`, `units_received`, `units_sold` → Whole Number · `closing_stock_value_cost_inr` → Fixed Decimal |
| Fact_Purchase_Orders | `po_id`, `store_id`, `product_id`, `supplier_id`, `delivery_status` → Text · `order_date`, `expected_delivery_date`, `actual_delivery_date` → Date · `qty_ordered`, `qty_received` → Whole Number · `unit_cost_inr`, `po_value_inr` → Fixed Decimal |

To change a type: click the icon left of the column name → pick the type. If asked **"Replace current"** or **"Add new step"**, choose **Replace current** (keeps a single tidy Changed Type step).

📘 **Study: why Fixed Decimal for money?** "Decimal Number" is floating point, which can produce tiny rounding errors like 0.30000000004 when summed millions of times. Fixed Decimal stores exactly 4 decimal places, the standard for currency.

### 2.5 Data quality checks (record these; they're resume material)

For each table, look at the column-quality bars and write the results in a small table in `Documentation/Data_Quality_Log.md` (create it):

| # | Check | How | Expected result |
|---|---|---|---|
| 1 | Row counts | Bottom-left status bar shows row count (with full-dataset profiling on) | Matches the table in Section 1 |
| 2 | Blank / null values | Column quality "Empty" | 0% everywhere **except** `Fact_Purchase_Orders[actual_delivery_date]` and `[qty_received]`: ~7% empty (1,714 open orders; this is correct, not an error) |
| 3 | Errors after type change | Column quality "Error" | 0% |
| 4 | Duplicate IDs in dimensions | Column profile of `product_id`, `store_id`, `supplier_id`, `date` → Distinct = Unique = row count | 60 / 24 / 8 / 730 |
| 5 | Date range | Column profile of `Fact_Sales[date]` → Min / Max | 2022-01-01 to 2023-12-31 |
| 6 | Negative values | Column profile of `units_sold`, `closing_stock` → Min | Min ≥ 0 |
| 7 | Referential integrity (every ID in facts exists in dimensions) | Checked on Day 4 in Model view | No blank row appears in slicers |
| 8 | Stock balance | Checked on Day 5 with a DAX measure | 0 rows fail |

> If `actual_delivery_date` shows **Error** instead of **Empty**: right-click the column header → **Replace Errors** → type `null` → OK. Do the same for `qty_received`.

### 2.6 Close & Apply

**Home → Close & Apply**. Power BI loads all tables (Fact_Sales takes a few seconds). Save.

✅ **Checkpoint:** switch to **Table view** (the grid icon on the far left). Click `Fact_Sales`: the bottom bar says **271,871 rows**.

---

## 3. Day 3: Clean and transform in Power Query (2–3 hours)

Our data is already clean, so today you learn the transformations that **add business value**. Open Power Query again: **Home → Transform data**.

📘 **Study: Applied Steps are a recipe.** Every click in Power Query is recorded as a step (written in a language called **M**). When data refreshes, Power Query replays the recipe. You never edit the source CSV; you build a repeatable pipeline. Click any step to see the data at that point. Click the ⚙ next to a step to edit it. To see the M code: **View → Advanced Editor**.

### 3.1 Fact_Purchase_Orders: delay and lead time columns

Click the `Fact_Purchase_Orders` query.

**a) Delay in days (actual vs promised)**
1. **Add Column → Custom Column**.
2. New column name: `delay_days`
3. Formula:
   ```
   if [actual_delivery_date] = null then null
   else Duration.Days([actual_delivery_date] - [expected_delivery_date])
   ```
4. OK. Then click the column-type icon → **Whole Number**.

**b) Actual lead time (order to delivery)**
1. **Add Column → Custom Column** → name `actual_lead_time_days`
   ```
   if [actual_delivery_date] = null then null
   else Duration.Days([actual_delivery_date] - [order_date])
   ```
2. Type → **Whole Number**.

*Why:* suppliers are judged on *how late* they are, not just whether they're late. Subtracting two dates gives a **duration**; `Duration.Days` turns it into a number.

**c) Split the delivery status**
`delivery_status` has values like `On Time`, `Late`, `On Time - Short Shipped`, `Late - Short Shipped`, `Open`. Two facts are squashed into one column, so we'll separate them.
1. Select `delivery_status` → **Transform → Split Column → By Delimiter**.
2. Choose **--Custom--**, type ` - ` (space, hyphen, space). Split at **Left-most delimiter** → OK.
3. You get `delivery_status.1` and `delivery_status.2`. Double-click to rename them `delivery_status` and `shipment_type`.
4. Right-click `shipment_type` → **Replace Values** → Value To Find: `null` → Replace With: `Full` → OK. (Rows with no " - " part, like plain `On Time`, got null here; they were shipped in full.)
5. Check the column distribution: `delivery_status` now has only **On Time / Late / Open**, and `shipment_type` has **Full / Short Shipped**.

📘 **Study: "one fact per column"** is a rule of tidy data. Splitting lets you count late orders and short shipments independently.

### 3.2 Dim_Product: margin and price band

Click `Dim_Product`.

**a) Margin % per product**
**Add Column → Custom Column** → name `margin_pct` → formula `1 - [unit_cost_inr] / [mrp_inr]` → type **Decimal Number**. (Expect values around 0.56–0.64.)

**b) Price band** (a grouping for analysis)
**Add Column → Conditional Column**:
- New column name: `price_band`
- If `mrp_inr` **is less than** `1500` → Output `Under ₹1,500`
- Add Clause: Else If `mrp_inr` **is less than** `3000` → `₹1,500–2,999`
- Add Clause: Else If `mrp_inr` **is less than** `6000` → `₹3,000–5,999`
- Else → `₹6,000+`
- OK → type **Text**.

Add a sort helper the same way: Conditional Column `price_band_order` → 1, 2, 3, 4 using the same rules → type **Whole Number**.

### 3.3 Dim_Date: season sort order

Click `Dim_Date` → **Add Column → Conditional Column** → `season_order`:
- If `season` equals `Winter` → `1`; Else If equals `Summer` → `2`; Else If equals `Monsoon` → `3`; Else → `4`. Type **Whole Number**.

*Why:* text sorts alphabetically (Festive, Monsoon, Summer, Winter), which isn't the order of the year. A numeric sort column fixes that (used on Day 4).

> Note on the `festival` column: where two festivals' shopping windows overlap (e.g., Karva Chauth falls inside the Diwali build-up), the day is labelled with the bigger festival. So Karva Chauth won't appear as its own label. That's a deliberate simplification; mention it if asked.

### 3.4 Make the file path portable (parameter)

If you move the folder, every query breaks because the CSV paths are hard-coded. Fix that once:
1. **Home → Manage Parameters → New Parameter**. Name `DataFolder`, Type **Text**, Current Value: your path ending in a backslash, e.g. `C:\Projects\BIBA_StyleIQ\Dataset\` → OK.
2. For each query: click the first step **Source**. The formula bar shows something like `= Csv.Document(File.Contents("C:\...\Dim_Date.csv"), [Delimiter=",", ...])`. Replace only the `File.Contents(...)` part with:
   ```
   File.Contents(DataFolder & "Dim_Date.csv")
   ```
   (use the right file name for each query). Press Enter.
3. Now if the folder moves, you only change the parameter.

### 3.5 Optional practice: dates in a different format (15 min)

Import the old repo's `BIBA_Supply_chain1.csv` as a separate query. Its dates look like `17-10-2023`. Right-click `order_date` → **Change Type → Using Locale…** → Data Type **Date**, Locale **English (India)** → OK. That's how you parse DD-MM-YYYY correctly. Then **right-click the query → Delete**; it isn't part of our model.

### 3.6 Close & Apply, save.

✅ **Checkpoint:** in Table view, `Fact_Purchase_Orders` has new columns `delay_days`, `actual_lead_time_days`, `shipment_type`. `Dim_Product` has `margin_pct`, `price_band`, `price_band_order`.

---

## 4. Day 4: Build the data model, a star schema (2–3 hours)

Click **Model view** (the third icon on the far left; it looks like connected boxes).

📘 **Study: star schema.** Put fact tables in the middle and dimension tables around them, each linked by an ID. Filters flow **from the dimension (the "1" side) to the fact (the "many" side)**. One product has many sales, so `Dim_Product` (1) → `Fact_Sales` (*). This is the layout Power BI is optimised for; it keeps DAX simple and fast.

### 4.1 Delete any automatic relationships

Power BI may have auto-created some lines. Click each line → press **Delete** → Yes. We'll create them deliberately. (Auto-detect sometimes guesses wrong.)

### 4.2 Create the relationships

For each row below: drag the **dimension column** onto the matching **fact column**. A dialog opens: check **Cardinality = Many to one (*:1)** (or One to many from the dimension side), **Cross filter direction = Single**, **Make this relationship active = ticked** → OK.

| From (dimension, "1") | To (fact, "*") |
|---|---|
| `Dim_Date[date]` | `Fact_Sales[date]` |
| `Dim_Date[date]` | `Fact_Inventory_Monthly[month_end_date]` |
| `Dim_Date[date]` | `Fact_Purchase_Orders[order_date]` |
| `Dim_Product[product_id]` | `Fact_Sales[product_id]` |
| `Dim_Product[product_id]` | `Fact_Inventory_Monthly[product_id]` |
| `Dim_Product[product_id]` | `Fact_Purchase_Orders[product_id]` |
| `Dim_Store[store_id]` | `Fact_Sales[store_id]` |
| `Dim_Store[store_id]` | `Fact_Inventory_Monthly[store_id]` |
| `Dim_Store[store_id]` | `Fact_Purchase_Orders[store_id]` |
| `Dim_Supplier[supplier_id]` | `Fact_Purchase_Orders[supplier_id]` |

That's 10 relationships. **Do not** link `Dim_Supplier` to `Dim_Product`: it would create two filter paths from Supplier to Purchase Orders (directly, and via Product), which Power BI calls **ambiguity**. We'll bring the supplier's lead time into Dim_Product with DAX on Day 5 instead.

Tidy the layout: drag the three fact tables into a column in the middle, and dimensions around them.

📘 **Study: why Single direction?** "Both" direction lets filters flow backwards (fact → dimension). It's sometimes useful but often causes ambiguous paths and wrong totals. Default to Single; use Both only with a clear reason.

### 4.3 Mark the date table

Select `Dim_Date` (in Table view or the Data pane) → **Table tools → Mark as date table** → choose column `date` → OK.
*Why:* DAX time-intelligence functions (SAMEPERIODLASTYEAR, TOTALYTD) need a proper, continuous date table.

### 4.4 Sort-by-column (so months and seasons sort correctly)

In **Table view**, select `Dim_Date`:
- Click column `month_name` → **Column tools → Sort by column → month_no**
- Click `weekday` → Sort by column → `weekday_no`
- Click `season` → Sort by column → `season_order`

Select `Dim_Product` → `price_band` → Sort by column → `price_band_order`.

### 4.5 Formatting and data categories

- `Dim_Store[city]` → **Column tools → Data category → City**. `Dim_Store[state]` → **State or Province**. (Lets map visuals place them correctly.)
- `Dim_Product[mrp_inr]`, `[unit_cost_inr]` → **Column tools → Format → Currency**, then the **$ dropdown → ₹ English (India)**. **Summarization → Don't summarize** (adding up prices makes no sense).
- `Dim_Product[margin_pct]` → Format **Percentage**, 1 decimal. Summarization → Don't summarize.
- `Dim_Date[year]` → Summarization → **Don't summarize** (otherwise Power BI tries to add up years!).

### 4.6 Hide the ID columns in the fact tables

In Model view, in each **fact** table, right-click `product_id`, `store_id`, `supplier_id`, `date`, `month_end_date`, `order_date` → **Hide in report view**.
*Why:* users should filter using the dimension's columns (e.g., `Dim_Product[category]`). Using the fact's ID column bypasses the model and causes confusing results. Hiding prevents mistakes.

### 4.7 Create a measures table

1. **Home → Enter data**. Name the table `_Measures` (the underscore keeps it at the top). Leave the one empty column → **Load**.
2. You'll delete `Column1` after creating your first measure on Day 5 (a table must have at least one column until then).

✅ **Checkpoint:** in Model view you see 7 tables and 10 solid lines (solid = active). Each line shows **1** on the dimension side and **\*** on the fact side.

---

## 5. Day 5: DAX measures and calculated columns (3 hours)

📘 **Study: the four DAX ideas you must be able to explain**

1. **Measure vs calculated column.**
   - A *calculated column* is computed **once per row** when data loads, and stored. Use it for categorising rows (e.g., "Excess" vs "Healthy").
   - A *measure* is computed **at query time** for whatever is on screen (a year, a region, a product). Use it for anything you aggregate (totals, %, ratios). **Prefer measures.**
2. **Filter context.** The set of filters active for one number on screen: slicers + the row/column of the visual + page filters. `[Net Revenue]` in the "North" row of a table is computed with filter `region = North`.
3. **Row context.** "The current row" inside a calculated column or an iterator (SUMX, AVERAGEX, FILTER). It does *not* filter anything by itself.
4. **CALCULATE** changes filter context. `CALCULATE([Net Revenue], Dim_Store[store_type] = "Online")` = revenue *as if* the filter were Online. When you call a measure inside a row context, DAX automatically wraps it in CALCULATE and turns the current row into filters. This is called **context transition**.

**How to create a measure:** in the **Data** pane, right-click `_Measures` → **New measure** → type the formula in the formula bar → **Enter**. Then set the format in **Measure tools → Format**.

**How to create a calculated column:** select the table → **Table tools → New column**.

> Tip: type formulas exactly as below. DAX ignores line breaks, so you can paste multi-line formulas (press **Shift + Enter** for a new line while typing).

### 5.1 Sales measures

| # | Measure | Formula | Format |
|---|---|---|---|
| 1 | Net Revenue | `Net Revenue = SUM ( Fact_Sales[net_revenue_inr] )` | Currency ₹, 0 decimals |
| 2 | Gross Revenue | `Gross Revenue = SUM ( Fact_Sales[gross_revenue_inr] )` | Currency ₹ |
| 3 | Units Sold | `Units Sold = SUM ( Fact_Sales[units_sold] )` | Whole number, thousands separator |
| 4 | COGS | `COGS = SUM ( Fact_Sales[cogs_inr] )` | Currency ₹ |
| 5 | Gross Margin | `Gross Margin = [Net Revenue] - [COGS]` | Currency ₹ |
| 6 | Gross Margin % | `Gross Margin % = DIVIDE ( [Gross Margin], [Net Revenue] )` | Percentage, 1 dp |
| 7 | Discount Given | `Discount Given = [Gross Revenue] - [Net Revenue]` | Currency ₹ |
| 8 | Discount % | `Discount % = DIVIDE ( [Discount Given], [Gross Revenue] )` | Percentage, 1 dp |
| 9 | Avg Selling Price | `Avg Selling Price = DIVIDE ( [Net Revenue], [Units Sold] )` | Currency ₹, 0 dp |
| 10 | Sales Lines | `Sales Lines = COUNTROWS ( Fact_Sales )` | Whole number |
| 11 | Net Revenue (Cr) | `Net Revenue (Cr) = DIVIDE ( [Net Revenue], 10000000 )` | **Custom**: `"₹"#,0.00" Cr"` |

Delete `Column1` from `_Measures` now (right-click → Delete). The table icon changes to a calculator.

📘 **Study: why DIVIDE instead of `/`?** `DIVIDE(a, b)` returns blank instead of an error when `b` is 0 or blank (e.g., a product with no sales).

📘 **Study: Crore formatting.** Power BI's built-in display units are Thousands/Millions/Billions, not Lakhs/Crores. Dividing by 1,00,00,000 and using a custom format string gives Indian-style KPI cards.

### 5.2 Time-intelligence measures

| # | Measure | Formula | Format |
|---|---|---|---|
| 12 | Revenue PY | `Revenue PY = CALCULATE ( [Net Revenue], SAMEPERIODLASTYEAR ( Dim_Date[date] ) )` | Currency ₹ |
| 13 | Revenue YoY % | `Revenue YoY % = IF ( HASONEVALUE ( Dim_Date[year] ), DIVIDE ( [Net Revenue] - [Revenue PY], [Revenue PY] ) )` | Percentage, 1 dp |
| 14 | Revenue PM | `Revenue PM = CALCULATE ( [Net Revenue], DATEADD ( Dim_Date[date], -1, MONTH ) )` | Currency ₹ |
| 15 | Revenue MoM % | `Revenue MoM % = DIVIDE ( [Net Revenue] - [Revenue PM], [Revenue PM] )` | Percentage, 1 dp |
| 16 | Revenue FYTD | `Revenue FYTD = TOTALYTD ( [Net Revenue], Dim_Date[date], "3/31" )` | Currency ₹ |
| 17 | Avg Daily Revenue | `Avg Daily Revenue = DIVIDE ( [Net Revenue], COUNTROWS ( Dim_Date ) )` | Currency ₹, 0 dp |

📘 **Study:** `SAMEPERIODLASTYEAR` shifts the dates in the current filter back one year. `"3/31"` tells TOTALYTD that the year ends on 31 March (Indian financial year). Avg Daily Revenue matters because **seasons have different lengths**: comparing totals of a 2-month season with a 4-month season is misleading (you'll see this on Day 9).

### 5.3 Share and ranking measures

> **First, a product label column.** Two different products share the name "Navy Solid Cotton Salwar Suit" (P030 Everyday ₹2,999 and P032 Festive ₹3,999). Any visual or ranking by `product_name` would merge them into one row. Create a calculated column in **Dim_Product** (select Dim_Product → **New column**):
> `product_label = Dim_Product[product_name] & " (" & Dim_Product[product_id] & ")"`
> e.g. "Emerald Embroidered Rayon Kurta (P012)". Use `product_label` in all visuals and rankings from now on. 📘 **Lesson:** names aren't unique keys. Retailers show the SKU code next to the name for exactly this reason. Found by checking `product_name` for duplicates (59 unique of 60).

| # | Measure | Formula | Format |
|---|---|---|---|
| 18 | Online Share % | `Online Share % = DIVIDE ( CALCULATE ( [Net Revenue], Dim_Store[store_type] = "Online" ), [Net Revenue] )` | % |
| 19 | Festive Share % | `Festive Share % = DIVIDE ( CALCULATE ( [Net Revenue], Dim_Date[season] = "Festive (Oct-Nov)" ), CALCULATE ( [Net Revenue], REMOVEFILTERS ( Dim_Date[season] ) ) )` | % |
| 20 | % of Total Revenue | `% of Total Revenue = DIVIDE ( [Net Revenue], CALCULATE ( [Net Revenue], ALLSELECTED ( Dim_Product ) ) )` | % |
| 21 | Product Rank | `Product Rank = IF ( HASONEVALUE ( Dim_Product[product_label] ), RANKX ( ALLSELECTED ( Dim_Product[product_label] ), [Net Revenue] ) )` | Whole number |
| 22 | Cumulative Revenue % | see below | % |

```
Cumulative Revenue % =
VAR CurrentRev = [Net Revenue]
VAR AllProducts =
    ADDCOLUMNS ( ALLSELECTED ( Dim_Product[product_label] ), "@Rev", [Net Revenue] )
RETURN
    DIVIDE (
        SUMX ( FILTER ( AllProducts, [@Rev] >= CurrentRev ), [@Rev] ),
        SUMX ( AllProducts, [@Rev] )
    )
```

📘 **Study: ALL vs ALLSELECTED vs REMOVEFILTERS.**
- `ALL(table)` / `REMOVEFILTERS` ignore filters completely (grand total of everything).
- `ALLSELECTED` ignores the visual's own row filters but **keeps slicer filters**, so "% of total" respects your slicers.
- Cumulative % is the basis of a **Pareto / ABC analysis**: which few products drive most revenue.

### 5.4 Inventory measures

📘 **Study: semi-additive measures (very important).** Stock is a *snapshot*. You can add stock across stores ("total stock today") but **not across months**: Jan stock + Feb stock is meaningless. So a "closing stock" measure must pick the **last snapshot date** in the period, then add up across stores/products. Sales, by contrast, are fully additive.

| # | Measure | Formula | Format |
|---|---|---|---|
| 23 | Closing Stock Units | see below | Whole number |
| 24 | Closing Stock Value | see below | Currency ₹ |
| 25 | Avg Inventory Value | see below | Currency ₹ |
| 26 | Inventory Turnover | `Inventory Turnover = DIVIDE ( [COGS], [Avg Inventory Value] ) * DIVIDE ( 365, COUNTROWS ( Dim_Date ) )` | Decimal, 1 dp |
| 27 | Days of Cover | `Days of Cover = DIVIDE ( [Closing Stock Value], DIVIDE ( [COGS], COUNTROWS ( Dim_Date ) ) )` | Decimal, 0 dp |
| 28 | Actual Demand | `Actual Demand = SUM ( Fact_Inventory_Monthly[actual_demand_units] )` | Whole number |
| 29 | Planned Demand | `Planned Demand = SUM ( Fact_Inventory_Monthly[planned_demand_units] )` | Whole number |
| 30 | Lost Sales Units | `Lost Sales Units = SUM ( Fact_Inventory_Monthly[est_lost_sales_units] )` | Whole number |
| 31 | Lost Sales % | `Lost Sales % = DIVIDE ( [Lost Sales Units], [Actual Demand] )` | %, 1 dp |
| 32 | Fill Rate % | `Fill Rate % = 1 - [Lost Sales %]` | %, 1 dp |
| 33 | Lost Sales Value | `Lost Sales Value = SUMX ( Fact_Inventory_Monthly, Fact_Inventory_Monthly[est_lost_sales_units] * RELATED ( Dim_Product[mrp_inr] ) )` | Currency ₹ |
| 34 | Stockout Days | `Stockout Days = SUM ( Fact_Inventory_Monthly[stockout_days] )` | Whole number |
| 35 | Forecast Bias % | `Forecast Bias % = DIVIDE ( [Planned Demand] - [Actual Demand], [Actual Demand] )` | %, 1 dp |
| 36 | Forecast Accuracy % | see below | %, 1 dp |
| 37 | Stock Balance Errors | see below | Whole number |

```
Closing Stock Units =
VAR LastSnapshot = CALCULATE ( MAX ( Fact_Inventory_Monthly[month_end_date] ), REMOVEFILTERS ( Fact_Inventory_Monthly[stock_status], Fact_Inventory_Monthly[cover_days] ) )
RETURN
    CALCULATE ( SUM ( Fact_Inventory_Monthly[closing_stock] ), Dim_Date[date] = LastSnapshot )
```
```
Closing Stock Value =
VAR LastSnapshot = CALCULATE ( MAX ( Fact_Inventory_Monthly[month_end_date] ), REMOVEFILTERS ( Fact_Inventory_Monthly[stock_status], Fact_Inventory_Monthly[cover_days] ) )
RETURN
    CALCULATE ( SUM ( Fact_Inventory_Monthly[closing_stock_value_cost_inr] ), Dim_Date[date] = LastSnapshot )
```
```
Avg Inventory Value =
AVERAGEX (
    VALUES ( Fact_Inventory_Monthly[month_end_date] ),
    CALCULATE ( SUM ( Fact_Inventory_Monthly[closing_stock_value_cost_inr] ) )
)
```
```
Forecast Accuracy % =
1 - DIVIDE (
    SUMX ( Fact_Inventory_Monthly,
        ABS ( Fact_Inventory_Monthly[planned_demand_units] - Fact_Inventory_Monthly[actual_demand_units] ) ),
    [Actual Demand]
)
```
```
Stock Balance Errors =
COUNTROWS (
    FILTER ( Fact_Inventory_Monthly,
        Fact_Inventory_Monthly[opening_stock] + Fact_Inventory_Monthly[units_received]
            - Fact_Inventory_Monthly[units_sold] <> Fact_Inventory_Monthly[closing_stock] )
)
```

> **Order of creation:** the stock measures refer to `stock_status` and `cover_days`, which you create in 5.5. Do **5.5 first**, then come back and create measures 23–24 (otherwise they show an error). The `REMOVEFILTERS` part makes sure that when a visual is split by stock status, the measure still uses the **latest month**, not the last month in which that status happened.

📘 **Study:**
- **SUMX / AVERAGEX** are *iterators*: they go row by row through a table, compute an expression, then sum/average. `RELATED` fetches a value from the "1" side table (MRP from Dim_Product) for the current row.
- **Forecast Accuracy** here is `1 − WAPE` (Weighted Absolute Percentage Error), the standard retail forecast metric. **Bias** tells you the *direction*: negative = the plan under-forecasts.
- **Inventory Turnover** = how many times stock is sold through per year. Multiplying by 365/days annualises it.
- **Days of Cover** = how many days current stock lasts at the average sales rate.
- **Stock Balance Errors** is a data-quality test written in DAX. It should return blank (no errors).

### 5.5 Calculated columns for stock status

Select **Fact_Inventory_Monthly** → **Table tools → New column**:

```
cover_days =
VAR DailySales = DIVIDE ( Fact_Inventory_Monthly[units_sold], DAY ( Fact_Inventory_Monthly[month_end_date] ) )
RETURN IF ( DailySales > 0, DIVIDE ( Fact_Inventory_Monthly[closing_stock], DailySales ) )
```
(`DAY(month_end_date)` = number of days in that month: 28/30/31.)

New column:
```
stock_status =
SWITCH (
    TRUE (),
    Fact_Inventory_Monthly[closing_stock] = 0, "Stocked Out",
    Fact_Inventory_Monthly[units_sold] = 0, "No Sales",
    Fact_Inventory_Monthly[cover_days] > 90, "Excess",
    Fact_Inventory_Monthly[cover_days] < 14, "Low",
    "Healthy"
)
```

📘 **Study: `SWITCH(TRUE(), …)`** checks conditions top to bottom and returns the first match. It's a cleaner IF-ELSEIF chain. **Order matters**: stocked-out is checked before cover days. The thresholds (14 and 90 days) are *business rules*. In an interview, say you chose them as assumptions that a client would confirm with their merchandising team.

Then two status measures:

| # | Measure | Formula |
|---|---|---|
| 38 | Store-SKU Count (Latest) | `Store-SKU Count (Latest) = VAR LastSnapshot = CALCULATE ( MAX ( Fact_Inventory_Monthly[month_end_date] ), REMOVEFILTERS ( Fact_Inventory_Monthly[stock_status], Fact_Inventory_Monthly[cover_days] ) ) RETURN CALCULATE ( COUNTROWS ( Fact_Inventory_Monthly ), Dim_Date[date] = LastSnapshot )` |
| 39 | Excess Stock Value | `Excess Stock Value = VAR LastSnapshot = CALCULATE ( MAX ( Fact_Inventory_Monthly[month_end_date] ), REMOVEFILTERS ( Fact_Inventory_Monthly[stock_status], Fact_Inventory_Monthly[cover_days] ) ) RETURN CALCULATE ( SUM ( Fact_Inventory_Monthly[closing_stock_value_cost_inr] ), Dim_Date[date] = LastSnapshot, Fact_Inventory_Monthly[stock_status] IN { "Excess", "No Sales" } )` |

### 5.6 Supplier measures

| # | Measure | Formula | Format |
|---|---|---|---|
| 40 | PO Count | `PO Count = COUNTROWS ( Fact_Purchase_Orders )` | Whole |
| 41 | Delivered POs | `Delivered POs = CALCULATE ( [PO Count], Fact_Purchase_Orders[delivery_status] <> "Open" )` | Whole |
| 42 | On-Time % | `On-Time % = DIVIDE ( CALCULATE ( [PO Count], Fact_Purchase_Orders[delivery_status] = "On Time" ), [Delivered POs] )` | %, 1 dp |
| 43 | Short-Ship % | `Short-Ship % = DIVIDE ( CALCULATE ( [PO Count], Fact_Purchase_Orders[shipment_type] = "Short Shipped" ), [Delivered POs] )` | %, 1 dp |
| 44 | Supplier Fill Rate % | `Supplier Fill Rate % = DIVIDE ( SUM ( Fact_Purchase_Orders[qty_received] ), CALCULATE ( SUM ( Fact_Purchase_Orders[qty_ordered] ), Fact_Purchase_Orders[delivery_status] <> "Open" ) )` | %, 1 dp |
| 45 | Avg Delay Days | `Avg Delay Days = AVERAGE ( Fact_Purchase_Orders[delay_days] )` | Decimal, 1 dp |
| 46 | Avg Lead Time Days | `Avg Lead Time Days = AVERAGE ( Fact_Purchase_Orders[actual_lead_time_days] )` | Decimal, 1 dp |
| 47 | Purchase Spend | `Purchase Spend = SUM ( Fact_Purchase_Orders[po_value_inr] )` | Currency ₹ |

Finally, a calculated column in **Dim_Product** (Table tools → New column):
```
lead_time_days =
LOOKUPVALUE ( Dim_Supplier[contracted_lead_time_days], Dim_Supplier[supplier_id], Dim_Product[supplier_id] )
```
📘 **Study:** `LOOKUPVALUE` works like Excel's VLOOKUP, with no relationship needed. We use it because we deliberately didn't relate Supplier to Product.

### 5.7 Organise the measures

Select a measure → **Measure tools → Display folder** → type `1 Sales`, `2 Time`, `3 Share & Rank`, `4 Inventory`, `5 Supplier`, `6 Scenario` (Day 10). Folders keep 45+ measures navigable.

### ✅ Day 5 Checkpoint: build a quick test table

Go to Report view → add a **Card** visual for each of these with no slicers. You should see:

| Measure | Expected |
|---|---|
| Net Revenue (Cr) | **₹127.25 Cr** |
| Gross Revenue | ≈ ₹135.15 Cr |
| Units Sold | **433,264** |
| Sales Lines | **271,871** |
| Gross Margin % | **58.1%** |
| Discount % | 5.8% |
| Avg Selling Price | ≈ ₹2,937 |
| Online Share % | 10.8% |
| Festive Share % | 24.5% |
| Lost Sales % | **7.6%** (Fill Rate 92.4%) |
| Lost Sales Value | ≈ ₹13.03 Cr |
| Forecast Bias % | **−20.0%** |
| Forecast Accuracy % | 58.4% |
| Closing Stock Value | ≈ ₹2.55 Cr (Dec 2023) |
| Avg Inventory Value | ≈ ₹2.37 Cr |
| Inventory Turnover | ≈ 11.2 |
| PO Count / Delivered POs | 23,418 / 21,704 |
| On-Time % | **83.5%** |
| Short-Ship % | 7.4% |
| Supplier Fill Rate % | 98.8% |
| Avg Delay Days / Avg Lead Time Days | ≈ 1.4 / ≈ 26.2 |
| Purchase Spend | ≈ ₹55.12 Cr |
| Stock Balance Errors | (Blank) = 0 errors |

Put a slicer on `Dim_Date[year]` and choose 2023: **Revenue YoY %** should be **16.6%**.

Then delete this test page (right-click the page tab → Delete page).

> Why is turnover so high (11×) compared with typical apparel (3–5×)? Our data tracks **store stock only**; there's no central warehouse stock. Mention this as a known limitation.

---

## 6. Day 6: Page 1, Executive Overview (3 hours)

📘 **Study: dashboard design rules**
- **Top-left = most important.** People read in a Z pattern: KPIs at the top, trend next, details at the bottom.
- **One page = one question.** This page answers: *"How is the business doing overall?"*
- Max ~7 visuals per page. Consistent colours. Every chart has a clear title in plain English.

### 6.1 Page setup

1. Rename the page: double-click the tab → `Executive Overview`.
2. Click an empty area of the canvas → **Format** pane (paint-roller icon) → **Canvas settings**: Type **16:9** (1280 × 720). **Canvas background**: colour `#FAF6F0` (cream), transparency 0%.
3. **View → Gridlines** and **Snap to grid** on. Helps alignment.

### 6.2 Header

- **Insert → Text box**: `BIBA StyleIQ | Executive Overview`, Segoe UI Semibold 20, colour `#7B1E3A` (maroon). Place top-left.
- A smaller text box underneath: `Simulated BIBA-inspired dataset · Jan 2022 – Dec 2023`, size 10, grey.

### 6.3 Slicers (right side of header)

Add three **Slicer** visuals:
1. Field `Dim_Date[year]` → Format → Slicer settings → Style **Tile**.
2. Field `Dim_Store[region]` → Style **Dropdown**, Selection → **Multi-select with Ctrl**, turn **"Select all" option** on.
3. Field `Dim_Product[category]` → Dropdown, same settings.

### 6.4 KPI cards (row under the header)

Add 5 **Card** visuals in a row, each with one measure:
`Net Revenue (Cr)` · `Units Sold` · `Gross Margin %` · `Revenue YoY %` · `Fill Rate %`.

Format each: Callout value size 24; Category label on, size 10; card background white, rounded corners 8 px, a light shadow.

📘 **Study:** Revenue YoY % is blank unless exactly one year is selected; that's what the `HASONEVALUE` check does. Without it, "all years" would be compared with 2022 alone and show a meaningless +116%. 2022 is blank too, because there's no 2021 data. Select 2023 to see 16.6%.

### 6.5 Revenue trend (left, middle)

**Line chart**: X-axis `Dim_Date[month_name]`, Y-axis `Net Revenue`, Legend `Dim_Date[year]`.
- Title: `Monthly Net Revenue: 2022 vs 2023`.
- Format → Lines: 2023 maroon `#7B1E3A`, 2022 gold `#C9A227`.
- Format → Markers on.

*What you should see:* both years peak in **October–November** (Diwali) and dip in **June–July** (monsoon). A smaller peak shows in **April–May** (Eid, wedding season, summer cottons).

### 6.6 Revenue by region (right, middle)

**Clustered bar chart**: Y-axis `Dim_Store[region]`, X-axis `Net Revenue`. Sort by Net Revenue descending (… menu → Sort axis). Data labels on.
*Expect:* North highest (~25%), then South, West, East, Central, Online.

### 6.7 Category mix (bottom-left)

**Donut chart**: Legend `Dim_Product[category]`, Values `Net Revenue`. Detail labels → Category, percent of total.
*Expect:* Palazzo Set, Anarkali and Kurta each ≈ 25%; Salwar Suit 15%; Lehenga 9%.

### 6.8 Top 10 products (bottom-right)

**Table**: `Dim_Product[product_label]`, `Dim_Product[category]`, `Net Revenue`, `Units Sold`, `Gross Margin %`.
- **Filters pane** → expand `product_label` → Filter type **Top N** → Show items **Top 10** → By value: drag `Net Revenue` → **Apply filter**.
- Sort by Net Revenue descending.

✅ **Checkpoint:** with no slicers, #1 is **Emerald Embroidered Rayon Kurta (P012) (≈ ₹6.95 Cr)**.

### 6.9 Write the insight

Add a small text box at the bottom: 2–3 bullet "Key insights" in your own words (e.g., *"Revenue grew 16.6% in 2023; Oct–Nov contributes ~25% of the year's revenue in just 2 months; North is the largest region."*).

📘 **Study:** a consultant's dashboard always has a "so what". Numbers without interpretation are a report, not a recommendation.

---

## 7. Day 7: Page 2, Product & Sales Analytics (3 hours)

Question this page answers: *"What sells, where, at what margin, and which few products drive the business?"*

Add a new page (the **+** at the bottom) → rename `Product & Sales`. Copy the header and slicers from Page 1 (select → Ctrl+C → go to page 2 → Ctrl+V). When asked **"Sync visuals?"** click **Sync** (the slicers will stay in step across pages).

### 7.1 Category → product matrix

**Matrix**: Rows `Dim_Product[category]` then `Dim_Product[product_label]` · Values `Net Revenue`, `Units Sold`, `Avg Selling Price`, `Discount %`, `Gross Margin %`, `% of Total Revenue`.
- Use the **+/−** icons (Format → Row headers → +/- icons on) to expand categories.
- Conditional formatting: in the Visualizations pane, click the dropdown on `Gross Margin %` → **Conditional formatting → Background color** → Format style **Gradient** → lowest = light, highest = maroon.

### 7.2 Pareto chart (80/20)

**Line and clustered column chart**: X-axis `Dim_Product[product_label]`, Column y-axis `Net Revenue`, Line y-axis `Cumulative Revenue %`.
- Sort by Net Revenue descending.
- Format → Y-axis secondary 0–100%.
- Add a constant line: **Analytics** pane (magnifier icon) → **Y-axis constant line** on the secondary axis at **0.8**, label "80%".

✅ **Checkpoint:** the line crosses 80% at about the **31st** product. So **31 of 60 SKUs (~52%) generate 80% of revenue**. That's an ABC-analysis insight: the "C" products are candidates for range rationalisation.

### 7.3 Volume vs margin scatter

**Scatter chart**: X-axis `Units Sold`, Y-axis `Gross Margin %`, Size `Net Revenue`, Values `Dim_Product[product_label]`, Legend `Dim_Product[category]`.
- Analytics pane → Average line on X and Y. This splits products into four quadrants (high volume–high margin = stars).

### 7.4 Channel and collection

- **Clustered column**: X `Dim_Store[store_type]`, Y `Net Revenue`.
- **Stacked column**: X `Dim_Product[collection]`, Y `Net Revenue`, Legend `Dim_Product[category]`.

### 7.5 Decomposition tree

**Decomposition tree** visual: Analyze `Net Revenue`; Explain by `Dim_Store[region]`, `Dim_Store[store_name]`, `Dim_Product[category]`, `Dim_Product[product_label]`.
Click the **+** on the root to choose the next level. Users can explore freely.
📘 **Study:** this shows "root cause" thinking: breaking a total into its drivers.

### 7.6 Drill-through page: Product Detail

1. New page → rename `Product Detail`.
2. In the Visualizations pane, under **Drill through**, drag `Dim_Product[product_label]` into **"Add drill-through fields here"**. Power BI adds a **Back** button automatically (top-left).
3. Add visuals:
   - Card: `Net Revenue`, `Units Sold`, `Gross Margin %`, `Lost Sales %`, `Closing Stock Units`.
   - Line chart: X `Dim_Date[year_month]`, Y `Units Sold` and `Lost Sales Units`.
   - Clustered bar: Y `Dim_Store[store_name]`, X `Net Revenue`.
   - Line chart: X `Dim_Date[year_month]`, Y `Closing Stock Units`.
   - Dynamic title text: create measure `Product Title = "Product: " & SELECTEDVALUE ( Dim_Product[product_label], "Select a product" )`, add a **Card** with it.
4. Test: go to Page 2 → right-click any product in the matrix → **Drill through → Product Detail**.

📘 **Study:** `SELECTEDVALUE(column, alternate)` returns the single value in the current filter, or the alternate if there are zero or several.

---

## 8. Day 8: Page 3, Inventory & Supplier Intelligence (3 hours)

Question: *"Where are we losing money through stockouts and excess stock, and are our suppliers part of the problem?"*

New page → `Inventory Intelligence`. Paste header and synced slicers.

### 8.1 KPI cards

`Closing Stock Value` · `Days of Cover` · `Inventory Turnover` · `Fill Rate %` · `Lost Sales Value` · `Excess Stock Value`

✅ **Checkpoint** (no slicers): Closing Stock Value ≈ **₹2.55 Cr**, Lost Sales Value ≈ **₹13.03 Cr**, Excess Stock Value ≈ **₹0.57 Cr** (₹57 Lakh).

### 8.2 Stock-status breakdown

**Stacked bar chart**: Y-axis `Dim_Product[category]`, X-axis `Store-SKU Count (Latest)`, Legend `Fact_Inventory_Monthly[stock_status]`.
Format → Columns → set colours: Stocked Out `#C0392B` red · Low `#E67E22` amber · Healthy `#27AE60` green · Excess `#2E86C1` blue · No Sales `#95A5A6` grey.

✅ **Checkpoint** at Dec 2023 (no slicers), totals across categories: **Healthy 901 · Low 180 · Excess 159 · Stocked Out 109 · No Sales 91** (= 1,440 store-SKU combinations).

### 8.3 When do stockouts happen?

**Line chart**: X `Dim_Date[year_month]`, Y `Lost Sales %`. Add a second line, `Forecast Bias %`, on the secondary axis.
*What you should see:* lost sales spike in **May** (~16–17%) and **November 2023** (~16%): the wedding and festive peaks. Bias is negative: the plan is too low exactly when demand is highest.

📘 **Study: the core finding of the project.** Stores reorder using a **flat average demand plan**. Average-based planning fails in seasonal businesses: it under-stocks peaks (lost sales) and over-stocks some slow lines (excess). The fix is **seasonal demand planning with a festive pre-build**, which is what Page 5 simulates.

### 8.4 Action list: excess & dead stock

**Table**: `Dim_Store[store_name]`, `Dim_Product[product_label]`, `Fact_Inventory_Monthly[stock_status]`, `Closing Stock Units`, `Closing Stock Value`.
- Filters on this visual → `stock_status` → Basic filtering → tick **Excess** and **No Sales**.
- Sort by Closing Stock Value descending.
- Conditional formatting → `Closing Stock Value` → **Data bars**.
- Title: `Action list: excess & non-moving stock (consider transfer / markdown)`.

### 8.5 Supplier scorecard

**Table**: `Dim_Supplier[supplier_name]`, `Dim_Supplier[specialisation]`, `PO Count`, `On-Time %`, `Avg Delay Days`, `Short-Ship %`, `Avg Lead Time Days`, `Purchase Spend`.
- Conditional formatting → `On-Time %` → **Icons** → rules: ≥ 0.85 green ●, ≥ 0.75 amber ●, else red ●.

✅ **Checkpoint:** best = **Supplier 02 - Tiruppur (93.5%)**, worst = **Supplier 08 - Delhi NCR (65.3%)**, the bridal supplier, who also has the longest lead time (40 days contracted).

📘 **Study: OTIF.** Retailers track **On-Time In-Full**: the % of orders arriving on time *and* complete. You can compute it as a stretch:
`OTIF % = DIVIDE ( CALCULATE ( [PO Count], Fact_Purchase_Orders[delivery_status] = "On Time", Fact_Purchase_Orders[shipment_type] = "Full" ), [Delivered POs] )`

---

## 9. Day 9: Page 4, Seasonal Demand Analysis (2–3 hours)

Question: *"How do seasons, festivals and regions shape demand, and does our plan follow it?"*

New page → `Seasonal Demand`. Paste header and slicers.

### 9.1 Season comparison: totals vs per-day

Two **Clustered column** charts side by side:
1. X `Dim_Date[season]`, Y `Net Revenue`. Title `Total revenue by season`.
2. X `Dim_Date[season]`, Y `Avg Daily Revenue`. Title `Average revenue per day by season`.

*What you'll see:* totals look similar (₹30–33 Cr each), **but per day, Festive (Oct–Nov) is far higher**, because it's only 2 months long while Monsoon is 4. That's a great interview point about **choosing the right metric**.

### 9.2 Category × month heat map

**Matrix**: Rows `Dim_Product[category]`, Columns `Dim_Date[month_name]`, Values `Net Revenue`.
- Values dropdown → **Show value as → Percent of row total** (each category's year split by month).
- Conditional formatting → Background color → Gradient (white → maroon).

*Patterns to find:* Kurta & Palazzo strong in **Apr–Jun** (summer cottons); Lehenga & Anarkali strong in **Nov–Feb and Apr–May** (wedding seasons); Lehenga weak in **Jun–Aug**.

### 9.3 Festival impact

**Clustered bar**: Y `Dim_Date[festival]`, X `Net Revenue`.
- Visual filter: `festival` → **is not blank**.

✅ **Checkpoint:** **Diwali ≈ ₹11.98 Cr** (largest), then Durga Puja ≈ ₹5.44 Cr, Eid ul-Fitr ≈ ₹4.74 Cr.
Then click **Durga Puja** in this chart, and look at the region chart if you add one: it's concentrated in the **East**. (Click a bar = cross-filtering.)

### 9.4 Region × category preference

**Matrix**: Rows `Dim_Store[region]`, Columns `Dim_Product[category]`, Values `Net Revenue` → Show value as **Percent of row total** → gradient formatting.
*Find:* North over-indexes on Lehenga/Salwar Suit; South on Kurta; West on Anarkali/Palazzo.

### 9.5 Plan vs actual demand

**Line chart**: X `Dim_Date[year_month]`, Y `Planned Demand` and `Actual Demand`.
*What you'll see:* the planned line is **almost flat**; the actual line swings with seasons. This picture *is* the business problem in one chart. Title it: `Flat demand plan vs seasonal reality`.

### 9.6 Weekday pattern

**Clustered column**: X `Dim_Date[weekday]`, Y `Avg Daily Revenue`, with a slicer on `Dim_Store[store_type]`.
*Find:* physical stores peak on Saturday/Sunday; online is nearly flat.

---

## 10. Day 10: Page 5, Inventory Planning Simulator (3 hours)

Question: *"If we plan for next season differently, how much should each store order?"*

📘 **Study: the replenishment formula**
- **Reorder Point (ROP)** = daily demand × (lead time days + safety stock days)
- If current stock < ROP → order **(ROP − stock)**.
- **Safety stock** is a buffer for uncertainty (demand spikes, late suppliers).
- **Lead time** = days between ordering and receiving.

### 10.1 Create the What-if parameters

**Modeling → New parameter → Numeric range**:

| Name | Data type | Min | Max | Increment | Default |
|---|---|---|---|---|---|
| Demand Uplift % | Whole number | 0 | 50 | 5 | 0 |
| Safety Stock Days | Whole number | 0 | 30 | 1 | 12 |
| Extra Lead Time Days | Whole number | 0 | 20 | 1 | 0 |

Keep **"Add slicer to this page"** ticked. Each parameter creates a small table plus a measure named `<Name> Value` (e.g., `Demand Uplift % Value`).

📘 **Study:** a What-if parameter is just a disconnected table of numbers (0, 5, 10…50) plus a measure that reads the slicer's selected value with `SELECTEDVALUE`. It isn't related to anything; your measures *use* it.

### 10.2 Scenario measures (put in folder `6 Scenario`)

```
Avg Daily Demand =
DIVIDE ( [Actual Demand], COUNTROWS ( Dim_Date ) )
```
```
Scenario Daily Demand =
[Avg Daily Demand] * ( 1 + [Demand Uplift % Value] / 100 )
```
```
Reorder Point Units =
SUMX (
    CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
    VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
    RETURN [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] )
)
```
```
Recommended Order Units =
SUMX (
    CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
    VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
    VAR ROP = [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] )
    RETURN MAX ( 0, ROP - [Closing Stock Units] )
)
```
```
Recommended Order Value =
SUMX (
    CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
    VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
    VAR ROP = [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] )
    RETURN MAX ( 0, ROP - [Closing Stock Units] ) * CALCULATE ( MAX ( Dim_Product[unit_cost_inr] ) )
)
```
```
Store-SKUs to Reorder =
COUNTROWS (
    FILTER (
        CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
        VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
        RETURN [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] ) > [Closing Stock Units]
    )
)
```

📘 **Study: why the CROSSJOIN + SUMX?** The order must be calculated **for each store-product pair separately**, then added up. If you computed one big ROP for the whole company and subtracted total stock, a store with too much stock would "cancel out" a store with too little, and you'd under-order. `CROSSJOIN` makes every store × product pair, `SUMX` loops over them, and calling measures inside the loop triggers **context transition**, so each pair uses its own demand, stock and lead time. This is the most advanced DAX in the project; make sure you can explain it.

### 10.3 Build the page

New page → `Planning Simulator`. Header + the three parameter slicers (format them as **Single value** sliders).

1. **Planning-window slicer**: `Dim_Date[year_month]`, style **Dropdown**, multi-select. *Instruction text box:* "Select the past months whose demand you want to plan from (e.g., 2023-10 and 2023-11 to plan the next festive season). Stock is taken at the end of the window."
   - **Important:** select **whole months** using year_month, not partial dates.
   - Make sure this page is **not** synced to the Year slicer of other pages (**View → Sync slicers** → untick this page for the year slicer).
2. **Cards**: `Store-SKUs to Reorder`, `Recommended Order Units`, `Recommended Order Value`.
3. **Table** (the order proposal): `Dim_Store[store_name]`, `Dim_Product[product_label]`, `Scenario Daily Demand`, `Closing Stock Units`, `Reorder Point Units`, `Recommended Order Units`, `Recommended Order Value`. Visual filter: `Recommended Order Units` **is greater than 0**.
4. **Clustered bar**: Y `Dim_Product[category]`, X `Recommended Order Value`.
5. **Clustered bar**: Y `Dim_Product[supplier_id]`, X `Recommended Order Value`. (Which suppliers need to be told about the order early, especially the slow ones?)

### 10.4 Run and record scenarios (this becomes resume evidence)

Set the window to **2023-10 + 2023-11**, then fill in this table in `Documentation/Scenario_Results.md`:

| Scenario | Demand Uplift | Safety Days | Extra Lead Days | Store-SKUs to reorder | Order Units | Order Value |
|---|---|---|---|---|---|---|
| Base | 0% | 12 | 0 | | | |
| Demand +10% | 10% | 12 | 0 | | | |
| Demand +20% | 20% | 12 | 0 | | | |
| Higher buffer | 0% | 18 (≈ +50%) | 0 | | | |
| Supplier delay | 0% | 12 | 10 | | | |
| Peak + delay | 20% | 18 | 10 | | | |

Then write two sentences interpreting it (e.g., *"A 20% festive uplift increases the required order value by X%; a 10-day supplier delay alone adds Y, so lead-time reliability matters as much as forecasting."*). Use **your** numbers.

---

## 11. Day 11: Polish (3 hours)

### 11.1 Theme

**View → Themes → Customize current theme**:
- Name: `BIBA StyleIQ`
- Colors: Color 1 `#7B1E3A` (maroon), Color 2 `#C9A227` (gold), Color 3 `#2E86C1`, Color 4 `#27AE60`, Color 5 `#E67E22`, Color 6 `#6C3483`.
- Text: font Segoe UI, title size 12.
- Visuals → Background: white; Border: off; Header icons: on hover.
- **Apply**. Then **View → Themes → Save current theme** so you can reuse it.

### 11.2 Navigation bar

On Page 1: **Insert → Buttons → Navigator → Page navigator**. It creates a button for every page. Format → Style: fill maroon for **Selected** state, white for Default. Copy it onto every page in the same position. (Hide the Product Detail page from the navigator: right-click that page tab → **Hide page**; hidden pages still work for drill-through.)

### 11.3 Report-page tooltip

1. New page → `Tooltip - Category`. **Format → Page information → Allow use as tooltip: On**. **Canvas settings → Type: Tooltip** (320 × 240).
2. Add: a small Card for `Net Revenue`, `Gross Margin %`, `Lost Sales %`, and a mini line chart (`year_month` × `Net Revenue`).
3. Hide this page.
4. On Page 1's donut chart: Format → **Tooltips** → Type **Report page** → Page **Tooltip - Category**.
Now hovering a category shows a mini-dashboard.

### 11.4 Bookmarks: "Chart / Table" toggle (optional, impressive)

On the Inventory page:
1. Place the stacked bar (8.2) and the action table (8.4) in the **same spot**, on top of each other.
2. **View → Bookmarks** and **View → Selection**.
3. In Selection pane hide the table → Bookmarks → **Add** → rename `Show Chart`.
4. Show the table, hide the chart → Add bookmark `Show Table`.
5. Right-click each bookmark → untick **Data** (so it doesn't reset slicers).
6. **Insert → Buttons → Bookmark navigator**, or two buttons with Action → Bookmark.

### 11.5 Edit interactions

By default, clicking one chart filters all others. Sometimes that's wrong (e.g., KPI cards shouldn't be cross-highlighted, or the top-10 table shouldn't filter the trend). Select a visual → **Format → Edit interactions** → on each other visual, click the **filter** icon, the **highlight** icon, or **None** ⊘. Click Edit interactions again to finish.

### 11.6 Dynamic titles

Measure:
```
Trend Title =
"Monthly Net Revenue – " & SELECTEDVALUE ( Dim_Store[region], "All Regions" )
```
Select the line chart on Page 1 → Format → General → **Title** → click **fx** next to Title text → Format style **Field value** → Based on field **Trend Title** → OK.

### 11.7 Accessibility & tidiness

- Every visual: Format → General → **Alt text** (describe what it shows).
- **View → Selection pane** → rename visuals meaningfully, and set tab order.
- Check alignment: select several visuals → **Format → Align → Align top / Distribute horizontally**.

### 11.8 Performance check

**Optimize → Performance analyzer → Start recording → Refresh visuals**. Any visual over ~1,000 ms? The Simulator table is the heaviest; that's expected because of CROSSJOIN. Stop recording.

---

## 12. Day 12: Validate, document, publish, resume (3 hours)

### 12.1 Validation checklist

- [ ] All Day 5 checkpoint numbers match.
- [ ] Every page: test each slicer, including "nothing selected".
- [ ] Region totals on Page 1 add up to the overall Net Revenue.
- [ ] Drill-through works from Page 2.
- [ ] Simulator: Uplift 0 → 20 makes Recommended Order Units go **up**; Safety 12 → 0 makes it go **down**. (Sanity checks of direction.)
- [ ] `Stock Balance Errors` is blank.
- [ ] Ask a friend to use the report without help for 5 minutes. Note where they got confused, and fix it.

### 12.2 Screenshots and PDF

- Each page: full-screen the report (**View → Full screen**, or use Reading view), then take a screenshot with **Win + Shift + S** → save into `Screenshots/` as `01_Executive.png`, etc.
- **File → Export → Export to PDF** → save in `PowerBI/`.
- Optional but powerful: record a 2–3 minute walkthrough video (Win + G → Xbox Game Bar records the screen, or use the Windows Snipping Tool's record option) explaining the business problem → insights → simulator. Interviewers love this.

### 12.3 Publishing online (optional)

Publishing to the Power BI Service needs a **work or school account**; a Gmail address won't work. If your college email works: **Home → Publish → My workspace**. "Publish to web" (a public link) is often disabled by college admins. If you can't publish, GitHub + screenshots + PDF + video is perfectly acceptable.

### 12.4 GitHub repository

1. Create a new public repo on github.com: `BIBA-StyleIQ-PowerBI-Supply-Chain-Analytics`.
2. **Add file → Upload files** → drag in `Dataset/`, `Generator/`, `Documentation/`, `PowerBI/` (the .pbix and PDF), `Screenshots/`. (Fact_Sales.csv is ~16 MB, under GitHub's 25 MB web-upload limit.)
3. Write `README.md` at the top level with these sections:
   - **Title + one-line summary**, with the disclosure: *"BIBA-inspired case study using a simulated dataset. Not BIBA's data."*
   - **Business problem** (flat demand plan in a seasonal business → stockouts at peaks, excess on over-planned lines).
   - **Data** (7 tables, star schema diagram screenshot from Model view, link to README_Data.md, why it was simulated: the Day 1 provenance finding).
   - **Approach** (Power Query → model → DAX → 5 pages → What-if).
   - **Screenshots** (one per page).
   - **Key findings** (your numbers: 16.6% YoY growth, Oct–Nov ≈ 25% of revenue, 7.6% demand lost ≈ ₹13 Cr at MRP, peaks in May/Nov, −20% plan bias, 31 of 60 SKUs = 80% revenue, supplier on-time 65–94%).
   - **Recommendations** (seasonal demand plan, festive pre-build by region, safety stock by supplier reliability, rationalise tail SKUs, clear excess via transfers/markdown).
   - **Limitations** (simulated data; store stock only, no warehouse; lost sales are exactly known only because it's simulated; status thresholds are assumptions).
   - **How to open** (Power BI Desktop, change the `DataFolder` parameter).

### 12.5 Resume entry (update numbers to what you actually built)

**BIBA StyleIQ – Fashion Retail & Supply Chain Intelligence** · *Microsoft Power BI | Power Query | DAX*
- Developed 5 interactive Power BI dashboards with 45+ DAX measures on a 7-table star schema (270K+ sales records, 24 stores, 60 SKUs, 8 suppliers; simulated BIBA-inspired data) to track sales, seasonal demand, inventory health and supplier performance.
- Identified festive-season stockouts, excess inventory and a −20% demand-plan bias; built What-if scenarios for demand, safety-stock and lead-time changes to generate store-level replenishment recommendations.

Only keep counts you actually reached (count your measures in the Data pane).

---

## 13. Study notes

### 13.1 Glossary: supply chain terms you must know

| Term | Meaning | In this project |
|---|---|---|
| SKU | Stock Keeping Unit: one specific product | 60 SKUs |
| Fill rate | % of customer demand served from stock | 92.4% |
| Lost sales | Demand not served because shelf was empty | 7.6% of demand |
| Stockout | Zero stock | `stockout_days` |
| Safety stock | Extra buffer for uncertainty | What-if parameter |
| Lead time | Days from ordering to receiving | 18–40 days contracted |
| Reorder point | Stock level that triggers a new order | Simulator |
| Days of cover | How many days stock will last | ≈ 35 days |
| Inventory turnover | Times stock is sold through per year | ≈ 11× (store stock only) |
| Sell-through | % of received stock that sold | can be added as a stretch |
| Forecast bias | Systematic over- or under-forecast | −20% |
| WAPE / forecast accuracy | Size of forecast error relative to actual | 58.4% at store-SKU-month level |
| OTIF | On-Time In-Full deliveries | stretch measure |
| ABC / Pareto | Few items drive most value | 31 SKUs → 80% revenue |
| EOSS | End-of-season sale (Jan, Jul) | `is_sale_period` |
| Semi-additive | Can sum across some dimensions but not time | Closing stock |

### 13.2 Power BI terms you must know

Power Query, M, Applied Steps, query folding (not relevant for CSV, but know the term), star schema, fact/dimension, cardinality, cross-filter direction, active/inactive relationship, date table, measure vs calculated column, filter context, row context, context transition, CALCULATE, iterator (X-functions), time intelligence, What-if parameter, drill-through, report-page tooltip, bookmark, sync slicers, edit interactions, conditional formatting, decomposition tree, Performance analyzer.

### 13.3 Interview questions to practise (answer them out loud)

1. *Walk me through your project.* → Problem (seasonal retailer, flat planning) → data (provenance issue, built a simulated star schema) → solution (5 pages) → insights (numbers) → recommendation (seasonal planning, supplier-aware safety stock).
2. *Why did you use a simulated dataset?* → The public one was synthetic and wrong; I documented the issues and built a transparent, reproducible one modelled on real Indian retail patterns, and I disclose it everywhere.
3. *Explain filter context and CALCULATE.*
4. *Measure vs calculated column: when do you use each?*
5. *How do you handle closing stock across months?* → Semi-additive; take the last snapshot.
6. *Why didn't you relate Supplier to Product?* → Avoid ambiguous paths; used LOOKUPVALUE.
7. *How does your reorder calculation avoid stores cancelling each other out?* → CROSSJOIN + SUMX per store-SKU.
8. *What would you need to deploy this at a real client?* → Connect to ERP/POS (e.g., SAP) instead of CSV, a central warehouse layer, scheduled refresh in Power BI Service, row-level security per region manager, data-quality monitoring, sign-off of business rules (14/90-day thresholds).
9. *What's the business impact?* → Quantify lost sales (≈ ₹13 Cr at MRP over 2 years, simulated) and excess stock; explain that recovering even part of peak lost sales is worth more than the extra safety stock cost. Use your scenario table.
10. *What are the limitations?* → See README.

### 13.4 Common errors and fixes

| Problem | Cause | Fix |
|---|---|---|
| A slicer shows "(Blank)" | Fact has an ID not in the dimension, or relationship missing | Check relationships in Model view; check IDs |
| Totals look far too big | Using a fact-table ID or date column instead of the dimension's | Use dimension columns; hide fact IDs |
| Months sorted Apr, Aug, Dec… | Text sorting | Sort by column → month_no |
| Year shows as "4,045" | Year being summed | Summarization → Don't summarize |
| Closing stock huge for a year | Summing snapshots over months | Use the LastSnapshot measure |
| YoY % blank | No previous year in the selection, or date table not marked | Select 2023; Mark as date table |
| "A circular dependency was detected" | Calculated column referring to a measure that refers back | Rebuild logic as a measure |
| Relationship can't be created / shows dashed | Would create ambiguity → made inactive | Remove the extra path (e.g., Supplier↔Product) |
| Queries fail after moving folder | Hard-coded paths | Update the `DataFolder` parameter |
| Simulator very slow | CROSSJOIN over all pairs | Expected; filter to fewer months/regions |

### 13.5 Free learning resources

- Microsoft Learn: "Get started with Microsoft Power BI" and the PL-300 (Power BI Data Analyst) learning path. PL-300 is a certification worth considering after this project.
- SQLBI (sqlbi.com) articles on DAX: CALCULATE, context transition, semi-additive measures.
- Power BI Desktop's own **Help → Learn** and sample reports.
