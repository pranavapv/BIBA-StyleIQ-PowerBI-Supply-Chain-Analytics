# BIBA StyleIQ: Planning Simulator Scenario Results

**Data:** simulated, BIBA-inspired dataset (not BIBA's real data).
**Page:** Planning Simulator (Power BI Online), built on Day 10.
**Planning window:** 2023-10 + 2023-11 (last festive season). Stock is taken at 30 Nov 2023.
**Scope:** all 24 stores × 60 products (1,440 store-SKU pairs), Region = All, Category = All.

## Logic

- Daily demand = actual demand in the window ÷ days in the window (61), × (1 + demand uplift %)
- Reorder point (ROP) = daily demand × (supplier lead time + extra delay days + safety stock days)
- Order = max(0, ROP − closing stock), worked out **for each store × product pair** and then summed (CROSSJOIN + SUMX)
- Order value = order units × unit cost

## Results

| Scenario | Demand Uplift | Safety Days | Extra Lead Days | Store-SKUs to reorder | Order Units | Order Value | vs Base |
|---|---|---|---|---|---|---|---|
| Base | 0% | 12 | 0 | 1,143 | 20,643 | ₹2.90 Cr (₹29.04M) | — |
| Demand +10% | 10% | 12 | 0 | 1,183 | 24,039 | ₹3.36 Cr (₹33.56M) | +16% |
| Demand +20% | 20% | 12 | 0 | 1,226 | 27,512 | ₹3.82 Cr (₹38.17M) | +31% |
| Higher buffer | 0% | 18 (+50%) | 0 | 1,213 | 26,537 | ₹3.65 Cr (₹36.52M) | +26% |
| Supplier delay | 0% | 12 | 10 | 1,254 | 30,574 | ₹4.16 Cr (₹41.64M) | +43% |
| Peak + delay | 20% | 18 | 10 | 1,337 | 47,423 | ₹6.33 Cr (₹63.33M) | +118% |

Base breakdown of order value:

| By category | ₹ L | | By supplier | ₹ L |
|---|---|---|---|---|
| Anarkali | 72.5 | | SUP05 Lucknow | 64.0 |
| Kurta | 63.9 | | SUP03 Surat | 41.5 |
| Palazzo Set | 62.2 | | SUP01 Jaipur | 41.1 |
| Lehenga | 52.1 | | SUP02 Tiruppur | 38.7 |
| Salwar Suit | 39.8 | | SUP06 Varanasi | 34.3 |
| | | | SUP07 Kolkata | 30.6 |
| | | | SUP04 Ludhiana | 22.5 |
| | | | SUP08 Delhi NCR | 17.8 |

All values were checked in Power BI against an independent calculation on the source data.

## Interpretation

A 20% festive demand uplift raises the required order value by 31% (₹2.90 Cr → ₹3.82 Cr). A 10-day supplier delay alone raises it by 43% (₹4.16 Cr), so lead-time reliability matters as much as forecasting. Together with a 50% larger safety buffer, the order more than doubles (₹6.33 Cr, +118%).

Order value grows faster than the uplift because stock on hand is fixed: the gap between the reorder point and the stock widens faster than demand, and more store-SKUs cross their reorder point (1,143 → 1,337). The largest order goes to SUP05 Lucknow (₹64 L), which is also the least reliable large supplier (71.3% on-time). Its purchase orders should be placed first, or it should get extra safety days.
