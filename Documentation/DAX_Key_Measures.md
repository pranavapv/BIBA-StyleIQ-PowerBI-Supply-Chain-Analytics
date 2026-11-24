# BIBA StyleIQ: Key DAX Measures

The model has 63 measures in 7 display folders inside a dedicated `_Measures` table. This file lists every measure by folder and gives the full formula for the ones that show the main DAX patterns. The step-by-step guide (Day 5 and Day 10) has the rest.

## Measure map

| Folder | Measures |
|---|---|
| 1 Sales | Net Revenue, Gross Revenue, Units Sold, COGS, Gross Margin, Gross Margin %, Discount Given, Discount %, Avg Selling Price, Sales Lines, Net Revenue (Cr) |
| 2 Time | Revenue PY, Revenue YoY %, Revenue PM, Revenue MoM %, Revenue FYTD, Avg Daily Revenue |
| 3 Share & Rank | Online Share %, Festive Share %, % of Total Revenue, Product Rank, Cumulative Revenue % |
| 4 Inventory | Closing Stock Units, Closing Stock Value, Avg Inventory Value, Inventory Turnover, Days of Cover, Actual Demand, Planned Demand, Lost Sales Units, Lost Sales %, Fill Rate %, Lost Sales Value, Stockout Days, Forecast Bias %, Forecast Accuracy %, Stock Balance Errors, Store-SKU Count (Latest), Excess Stock Value, Closing Stock Value (Cr), Lost Sales Value (Cr), Excess Stock Value (L) |
| 5 Supplier | PO Count, Delivered POs, On-Time %, OTIF %, Short-Ship %, Supplier Fill Rate %, Avg Delay Days, Avg Lead Time Days, Purchase Spend |
| 6 Scenario | Demand Uplift % Value, Safety Stock Days Value, Extra Lead Time Days Value, Avg Daily Demand, Scenario Daily Demand, Reorder Point Units, Recommended Order Units, Recommended Order Value, Store-SKUs to Reorder |
| 7 Report Helpers | Pareto 80% Line, Product Title, Trend Title |

## Time intelligence

Returns blank instead of a misleading number when more than one year is in context:

```
Revenue PY = CALCULATE ( [Net Revenue], SAMEPERIODLASTYEAR ( Dim_Date[date] ) )

Revenue YoY % =
IF ( HASONEVALUE ( Dim_Date[year] ),
     DIVIDE ( [Net Revenue] - [Revenue PY], [Revenue PY] ) )

Revenue FYTD = TOTALYTD ( [Net Revenue], Dim_Date[date], "3/31" )   -- Indian financial year

Avg Daily Revenue = DIVIDE ( [Net Revenue], COUNTROWS ( Dim_Date ) ) -- compares seasons of different lengths
```

## Share, rank and Pareto (ALLSELECTED respects slicers)

```
% of Total Revenue =
DIVIDE ( [Net Revenue], CALCULATE ( [Net Revenue], ALLSELECTED ( Dim_Product ) ) )

Product Rank =
IF ( HASONEVALUE ( Dim_Product[product_label] ),
     RANKX ( ALLSELECTED ( Dim_Product[product_label] ), [Net Revenue] ) )

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

## Semi-additive stock (last snapshot in the period)

Stock can be added across stores, but not across months:

```
Closing Stock Units =
VAR LastSnapshot =
    CALCULATE ( MAX ( Fact_Inventory_Monthly[month_end_date] ),
                REMOVEFILTERS ( Fact_Inventory_Monthly[stock_status], Fact_Inventory_Monthly[cover_days] ) )
RETURN
    CALCULATE ( SUM ( Fact_Inventory_Monthly[closing_stock] ), Dim_Date[date] = LastSnapshot )
```

## Lost sales and forecast quality

```
Lost Sales % = DIVIDE ( [Lost Sales Units], [Actual Demand] )
Fill Rate %  = 1 - [Lost Sales %]

Lost Sales Value =
SUMX ( Fact_Inventory_Monthly,
       Fact_Inventory_Monthly[est_lost_sales_units] * RELATED ( Dim_Product[mrp_inr] ) )

Forecast Bias % = DIVIDE ( [Planned Demand] - [Actual Demand], [Actual Demand] )

Forecast Accuracy % =
1 - DIVIDE (
    SUMX ( Fact_Inventory_Monthly,
           ABS ( Fact_Inventory_Monthly[planned_demand_units] - Fact_Inventory_Monthly[actual_demand_units] ) ),
    [Actual Demand] )
```

## Supplier

```
OTIF % =
DIVIDE (
    CALCULATE ( [PO Count],
                Fact_Purchase_Orders[delivery_status] = "On Time",
                Fact_Purchase_Orders[shipment_type] = "Full" ),
    [Delivered POs] )
```

## What-if planning simulator (CROSSJOIN + SUMX + context transition)

Each What-if parameter is a disconnected table, `GENERATESERIES(min, max, step)`, plus a `SELECTEDVALUE` measure with a default.

The order is calculated for each store × product pair and then summed. That way surplus stock in one store can't hide a shortage in another.

```
Avg Daily Demand      = DIVIDE ( [Actual Demand], COUNTROWS ( Dim_Date ) )
Scenario Daily Demand = [Avg Daily Demand] * ( 1 + [Demand Uplift % Value] / 100 )

Recommended Order Units =
SUMX (
    CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
    VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
    VAR ROP      = [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] )
    RETURN MAX ( 0, ROP - [Closing Stock Units] )
)

Recommended Order Value =
SUMX (
    CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
    VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
    VAR ROP      = [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] )
    RETURN MAX ( 0, ROP - [Closing Stock Units] ) * CALCULATE ( MAX ( Dim_Product[unit_cost_inr] ) )
)

Store-SKUs to Reorder =
COUNTROWS (
    FILTER (
        CROSSJOIN ( VALUES ( Dim_Store[store_id] ), VALUES ( Dim_Product[product_id] ) ),
        VAR LeadDays = CALCULATE ( MAX ( Dim_Product[lead_time_days] ) ) + [Extra Lead Time Days Value]
        RETURN [Scenario Daily Demand] * ( LeadDays + [Safety Stock Days Value] ) > [Closing Stock Units]
    )
)
```

## Report helpers

```
Pareto 80% Line = 0.8
Product Title   = "Product: " & SELECTEDVALUE ( Dim_Product[product_label], "Select a product" )
Trend Title     = "Monthly net revenue – " & SELECTEDVALUE ( Dim_Store[region], "All regions" )
```
