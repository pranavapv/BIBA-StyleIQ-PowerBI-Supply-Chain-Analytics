# BIBA StyleIQ — Day 1: Data Inventory & Provenance Check

Source checked: GitHub `Shushree-Data-analyst/biba-supply-chain-analytics` (downloaded 12 Nov 2026)

## 1. What's in the repository

| File | What it is |
|---|---|
| `Raw & cleaned Data/BIBA_Supply_chain1.csv` | Raw data, 4,544 rows × 13 columns, dates as DD-MM-YYYY |
| `Raw & cleaned Data/BIBA_Cleaned.csv` | Same 4,544 rows, dates converted, plus `Month` and `Year` (15 columns) |
| `Biba_supply_Dashbord.pbix` | The author's Power BI report |
| `Biba_supply_chain.ipynb` | Python cleaning / EDA notebook |
| `biba_SQL_Queries/` | 13 MySQL query files |
| `BIBA_Supply_Chain_Report.pdf`, `README.md` | Write-up |

## 2. Data dictionary (one row = one "order" record)

| Column | Type | Range / values |
|---|---|---|
| order_id | text | BIBA-01001 … BIBA-06000 (456 IDs missing) |
| order_date | date | 1 Jan 2022 – 31 Dec 2023 |
| product_category | text | Anarkali, Kurta, Lehenga, Palazzo Set, Salwar Suit (~900 rows each) |
| season | text | Festive, Monsoon, Summer, Winter (~1,130 rows each) |
| region | text | North, South, East, West, Central India (~900 rows each) |
| demand_forecast_units | whole number | 50 – 400 |
| actual_demand_units | whole number | 41 – 479 |
| stock_ordered_units | whole number | 43 – 497 |
| unit_price_inr | decimal | ₹801 – ₹9,995 (each category has its own price band) |
| holding_cost_inr | decimal | 0 – ₹8,768 |
| overstock_units | whole number | 0 – 66 |
| stockout_units | whole number | 0 – 127 |
| forecast_accuracy_pct | decimal | 79.6 – 100 |

Quality: 0 blank cells, 0 duplicate rows, 0 duplicate order IDs.

## 3. Provenance verdict: **synthetic (made-up) data, not real BIBA data**

The README calls it "real-world fashion retail data" but gives no source, and the data itself shows it was generated:

1. **Season has nothing to do with the date.** Every month has roughly 25% of each season. January has 82 "Summer" orders; July has 80 "Winter" orders.
2. **There is no festive peak.** Average demand is 220 units in "Festive" rows and 220 in all others; Oct–Nov average 218 vs Jun–Jul 225. Real ethnic-wear sales jump around Diwali and wedding season.
3. **Everything is evenly spread.** ~900 rows per category, ~900 per region, 158–214 orders every month. Real sales are lumpy.
4. **Formula-made columns.** Holding cost is exactly 1.5% × overstock units × unit price on every one of the 2,558 overstock rows. Overstock and stockout are exactly the gap between stock ordered and actual demand.
5. **Forecast accuracy doesn't match the forecast.** Only 2,410 of 4,544 rows have an accuracy figure within 1 point of what the forecast and actual demand imply, so the column was generated separately.

**README calculation error:** the "₹12.61 Cr overstock carrying cost" is overstock units × holding cost. But holding cost already includes the units, so this counts them twice. The actual total holding cost in the data is about **₹0.34 Cr**. The ₹29.68 Cr "combined risk" headline is therefore wrong.

## 4. What this data can and can't support in Power BI

| Planned page | Possible? | Why |
|---|---|---|
| Executive Overview | Yes | Revenue, orders, units, region and category splits all work |
| Product & Sales Analytics | Partly | Only 5 categories, no individual products, so no "top 10 products" |
| Inventory Intelligence | Partly | Overstock and stockout work; inventory turnover and stock on hand don't (no stock snapshots or cost of goods) |
| Seasonal Demand Analysis | No, not meaningfully | Season labels are random, so any seasonal "insight" is noise |
| Inventory Planning Simulator | Yes | What-if on demand and safety stock works with forecast, actual and ordered units |

## 5. Implications for the resume

- "4,500+ orders" is accurate as a row count, but the project must say **synthetic / BIBA-inspired dataset**, not BIBA's data.
- Using the same dataset as a public project means an interviewer can find someone else's identical work.
- No seasonal findings can be claimed from this data.
