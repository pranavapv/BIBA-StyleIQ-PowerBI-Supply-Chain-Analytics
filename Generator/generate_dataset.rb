# BIBA StyleIQ - simulated dataset generator
#
# Produces a SIMULATED, BIBA-inspired ethnic-wear retail dataset for a Power BI
# portfolio project. None of these numbers are BIBA's real data. Store names,
# supplier names, products, prices and volumes are all invented.
#
# Run:  ruby generate_dataset.rb      (Ruby 2.6+, standard library only)
# Output: ../Dataset/*.csv            Fixed random seed, so output is reproducible.

require 'csv'
require 'date'

SEED = 2047
R = Random.new(SEED)
OUT = File.expand_path('../Dataset', __dir__)
Dir.mkdir(OUT) unless Dir.exist?(OUT)

START_DATE = Date.new(2022, 1, 1)
END_DATE   = Date.new(2023, 12, 31)

def rnd(a, b); a + R.rand * (b - a); end
def lognormal(sigma); Math.exp(sigma * gauss); end
def gauss
  u1 = R.rand; u1 = 1e-12 if u1 < 1e-12
  Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math::PI * R.rand)
end
def poisson(lam)
  return 0 if lam <= 0
  if lam > 30
    v = (lam + Math.sqrt(lam) * gauss).round
    return v < 0 ? 0 : v
  end
  l = Math.exp(-lam); k = 0; p = 1.0
  loop { p *= R.rand; break if p <= l; k += 1 }
  k
end

# ---------------------------------------------------------------- Suppliers
SUPPLIERS = [
  # id, name, city, state, specialisation, contracted lead days, on-time prob, short-ship prob
  ['SUP01', 'Supplier 01 - Jaipur',    'Jaipur',    'Rajasthan',     'Block-print cotton',         21, 0.90, 0.05],
  ['SUP02', 'Supplier 02 - Tiruppur',  'Tiruppur',  'Tamil Nadu',    'Knits & everyday cotton',    18, 0.93, 0.04],
  ['SUP03', 'Supplier 03 - Surat',     'Surat',     'Gujarat',       'Synthetic & georgette',      20, 0.82, 0.10],
  ['SUP04', 'Supplier 04 - Ludhiana',  'Ludhiana',  'Punjab',        'Salwar suits & winterwear',  24, 0.78, 0.12],
  ['SUP05', 'Supplier 05 - Lucknow',   'Lucknow',   'Uttar Pradesh', 'Chikankari embroidery',      30, 0.70, 0.15],
  ['SUP06', 'Supplier 06 - Varanasi',  'Varanasi',  'Uttar Pradesh', 'Silk & brocade',             35, 0.74, 0.10],
  ['SUP07', 'Supplier 07 - Kolkata',   'Kolkata',   'West Bengal',   'Handloom & festive',         28, 0.85, 0.08],
  ['SUP08', 'Supplier 08 - Delhi NCR', 'Noida',     'Uttar Pradesh', 'Bridal & heavy embroidery',  40, 0.65, 0.18],
]
SUP = SUPPLIERS.map { |s| [s[0], s] }.to_h

# ---------------------------------------------------------------- Products
CATS = {
  # category => [MRP choices, base daily units at a reference store, suppliers, fabrics]
  'Kurta'       => [[899, 1099, 1299, 1499, 1799, 1999, 2499],        0.62,  %w[SUP01 SUP02 SUP05], %w[Cotton Rayon Linen Chikankari\ Cotton]],
  'Palazzo Set' => [[1499, 1799, 1999, 2299, 2799, 3499],             0.28,  %w[SUP02 SUP03 SUP01], %w[Rayon Cotton Georgette Crepe]],
  'Salwar Suit' => [[1999, 2499, 2999, 3499, 3999, 4999],             0.22,  %w[SUP04 SUP01 SUP07], %w[Cotton Silk\ Blend Chanderi Woollen]],
  'Anarkali'    => [[2499, 2999, 3499, 3999, 4999, 5999],             0.12,  %w[SUP03 SUP05 SUP07], %w[Georgette Chanderi Silk\ Blend Net]],
  'Lehenga'     => [[5999, 7999, 9999, 11999, 14999],                 0.04,  %w[SUP08 SUP06],       %w[Silk Brocade Net Velvet]],
}
COLOURS = %w[Indigo Maroon Mustard Teal Ivory Rani\ Pink Emerald Peach Navy Wine Saffron Olive Lilac Coral]
PRINTS  = %w[Floral Block-Print Paisley Bandhani Ikat Zari Mirror-Work Embroidered Solid Leheriya Kalamkari Gota]

products = []
CATS.each do |cat, (mrps, base, sups, fabrics)|
  12.times do |i|
    collection =
      if cat == 'Lehenga' then i < 7 ? 'Wedding' : 'Festive'
      elsif i < 6 then 'Everyday'
      elsif i < 10 then 'Festive'
      else 'Wedding'
      end
    mrp  = mrps[R.rand(mrps.size)]
    mrp  = mrps[-1 - R.rand(2)] if collection != 'Everyday' && cat != 'Lehenga'
    fab  = fabrics[R.rand(fabrics.size)]
    name = "#{COLOURS[R.rand(COLOURS.size)]} #{PRINTS[R.rand(PRINTS.size)]} #{fab} #{cat}"
    launch = START_DATE
    launch = Date.new(2023, 9, 1) if i == 9   # Festive 2023 collection
    launch = Date.new(2023, 3, 1) if i == 5   # Spring/Summer 2023 drop
    popularity = lognormal(0.55)
    # Planner's demand estimate per SKU. Some ranges are over-bought (assortment misses).
    plan_bias = lognormal(0.18)
    plan_bias = rnd(1.7, 2.3) if [3, 8].include?(i)
    plan_bias = rnd(0.6, 0.75) if i == 0       # chronic under-planning of a bestseller
    products << {
      product_id: format('P%03d', products.size + 1), product_name: name, category: cat,
      collection: collection, fabric: fab, mrp_inr: mrp,
      unit_cost_inr: (mrp * rnd(0.36, 0.44)).round(2), supplier_id: sups[R.rand(sups.size)],
      launch_date: launch, base: base * popularity, plan_bias: plan_bias
    }
  end
end

# ---------------------------------------------------------------- Stores
STORE_DEFS = [
  # city, state, region, type
  ['New Delhi', 'Delhi', 'North', 'Flagship'], ['New Delhi', 'Delhi', 'North', 'Mall'],
  ['Gurugram', 'Haryana', 'North', 'Mall'], ['Lucknow', 'Uttar Pradesh', 'North', 'Mall'],
  ['Chandigarh', 'Chandigarh', 'North', 'Shop-in-Shop'], ['Jaipur', 'Rajasthan', 'North', 'Mall'],
  ['Mumbai', 'Maharashtra', 'West', 'Flagship'], ['Mumbai', 'Maharashtra', 'West', 'Mall'],
  ['Pune', 'Maharashtra', 'West', 'Mall'], ['Ahmedabad', 'Gujarat', 'West', 'Shop-in-Shop'],
  ['Bengaluru', 'Karnataka', 'South', 'Flagship'], ['Bengaluru', 'Karnataka', 'South', 'Shop-in-Shop'],
  ['Chennai', 'Tamil Nadu', 'South', 'Mall'], ['Hyderabad', 'Telangana', 'South', 'Mall'],
  ['Kochi', 'Kerala', 'South', 'Shop-in-Shop'],
  ['Kolkata', 'West Bengal', 'East', 'Flagship'], ['Kolkata', 'West Bengal', 'East', 'Shop-in-Shop'],
  ['Bhubaneswar', 'Odisha', 'East', 'Mall'], ['Guwahati', 'Assam', 'East', 'Shop-in-Shop'],
  ['Indore', 'Madhya Pradesh', 'Central', 'Mall'], ['Bhopal', 'Madhya Pradesh', 'Central', 'Shop-in-Shop'],
  ['Nagpur', 'Maharashtra', 'Central', 'Mall'], ['Raipur', 'Chhattisgarh', 'Central', 'Shop-in-Shop'],
  ['Online', 'Pan India', 'Online', 'Online'],
]
STORE_MULT = { 'Flagship' => 1.7, 'Mall' => 1.0, 'Shop-in-Shop' => 0.55, 'Online' => 2.6 }
REGION_AFF = {
  'North'   => { 'Lehenga' => 1.35, 'Salwar Suit' => 1.35, 'Kurta' => 0.9,  'Anarkali' => 1.1, 'Palazzo Set' => 0.9 },
  'West'    => { 'Lehenga' => 1.1,  'Salwar Suit' => 0.8,  'Kurta' => 1.0,  'Anarkali' => 1.25, 'Palazzo Set' => 1.25 },
  'South'   => { 'Lehenga' => 0.75, 'Salwar Suit' => 0.75, 'Kurta' => 1.35, 'Anarkali' => 0.9, 'Palazzo Set' => 1.15 },
  'East'    => { 'Lehenga' => 0.9,  'Salwar Suit' => 1.1,  'Kurta' => 1.0,  'Anarkali' => 1.15, 'Palazzo Set' => 0.9 },
  'Central' => { 'Lehenga' => 1.0,  'Salwar Suit' => 1.25, 'Kurta' => 1.0,  'Anarkali' => 0.9, 'Palazzo Set' => 0.85 },
  'Online'  => Hash.new(1.0),
}
city_count = Hash.new(0)
stores = STORE_DEFS.each_with_index.map do |(city, state, region, type), i|
  city_count[city] += 1
  name = type == 'Online' ? 'Online Store' : "#{city} #{type} #{city_count[city]}"
  { store_id: format('S%02d', i + 1), store_name: name, city: city, state: state,
    region: region, store_type: type, mult: STORE_MULT[type] * rnd(0.85, 1.15) }
end

# ---------------------------------------------------------------- Calendar & demand drivers
FESTIVALS = {
  # name => [[date 2022, date 2023], days of build-up before, uplift, regions (nil = all)]
  'Diwali'          => [[Date.new(2022, 10, 24), Date.new(2023, 11, 12)], 16, 1.9, nil],
  'Durga Puja'      => [[Date.new(2022, 10, 1),  Date.new(2023, 10, 20)], 12, 1.9, %w[East]],
  'Navratri'        => [[Date.new(2022, 9, 26),  Date.new(2023, 10, 15)], 9,  1.5, %w[West Central]],
  'Onam'            => [[Date.new(2022, 9, 8),   Date.new(2023, 8, 29)],  8,  1.6, %w[South]],
  'Eid ul-Fitr'     => [[Date.new(2022, 5, 3),   Date.new(2023, 4, 22)],  8,  1.35, nil],
  'Raksha Bandhan'  => [[Date.new(2022, 8, 11),  Date.new(2023, 8, 30)],  6,  1.3, nil],
  'Karva Chauth'    => [[Date.new(2022, 10, 13), Date.new(2023, 11, 1)],  5,  1.35, %w[North Central]],
  'Pongal / Sankranti' => [[Date.new(2022, 1, 14), Date.new(2023, 1, 15)], 6, 1.35, %w[South]],
}
MONTH_CURVE = [nil, 0.92, 0.88, 1.0, 1.0, 0.95, 0.85, 0.78, 0.92, 0.98, 1.3, 1.25, 1.02]

def festival_on(date)
  FESTIVALS.each do |name, (dates, days, _, _)|
    dates.each { |d| return name if date <= d && date > d - days }
  end
  nil
end

def festival_mult(date, region)
  m = 1.0
  FESTIVALS.each do |_, (dates, days, up, regs)|
    next if regs && !regs.include?(region) && region != 'Online'
    up = 1 + (up - 1) * 0.4 if region == 'Online' && regs
    dates.each do |d|
      next unless date <= d && date > d - days
      ramp = 1 - (d - date).to_f / days       # builds towards the festival day
      m *= 1 + (up - 1) * (0.5 + ramp)
    end
  end
  m
end

def wedding_season?(d)
  md = d.month * 100 + d.day
  (md >= 1115 && md <= 1215) || (md >= 115 && md <= 228) || (md >= 415 && md <= 531)
end
def eoss?(d); (d.month == 1 || d.month == 7) && d.day <= 25; end
def season_of(d)
  case d.month
  when 12, 1, 2 then 'Winter'
  when 3, 4, 5 then 'Summer'
  when 6, 7, 8, 9 then 'Monsoon'
  else 'Festive (Oct-Nov)'
  end
end

def demand_mult(date, product, store)
  cat = product[:category]
  m = MONTH_CURVE[date.month]
  m *= festival_mult(date, store[:region])
  m *= (product[:collection] == 'Everyday' ? 1.0 : 1.25) if festival_on(date)
  if %w[Lehenga Anarkali].include?(cat) || product[:collection] == 'Wedding'
    m *= wedding_season?(date) ? 1.6 : 0.85
  end
  m *= 1.3 if %w[Kurta Palazzo\ Set].include?(cat) && [4, 5, 6].include?(date.month)
  m *= 0.55 if cat == 'Lehenga' && [6, 7, 8].include?(date.month)
  m *= 1.25 if cat == 'Salwar Suit' && product[:fabric] == 'Woollen' && [12, 1].include?(date.month)
  m *= (product[:collection] == 'Everyday' ? 1.7 : 1.2) if eoss?(date)
  wk = date.wday
  if store[:store_type] == 'Online'
    m *= wk == 0 ? 1.1 : 1.0
    m *= 0.75 + 0.6 * ((date - START_DATE).to_f / (END_DATE - START_DATE))  # online grows ~2x
  else
    m *= [0, 6].include?(wk) ? 1.4 : (wk == 5 ? 1.1 : 0.9)
    m *= date.year == 2023 ? 1.1 : 1.0
  end
  m
end

def discount_pct(date, product)
  return(product[:collection] == 'Everyday' ? 35 : 20) if eoss?(date)
  return 10 if festival_on(date)
  0
end

# ---------------------------------------------------------------- Dim tables
CSV.open("#{OUT}/Dim_Supplier.csv", 'w') do |c|
  c << %w[supplier_id supplier_name city state specialisation contracted_lead_time_days]
  SUPPLIERS.each { |s| c << s[0..5] }
end
CSV.open("#{OUT}/Dim_Product.csv", 'w') do |c|
  c << %w[product_id product_name category collection fabric mrp_inr unit_cost_inr supplier_id launch_date]
  products.each { |p| c << [p[:product_id], p[:product_name], p[:category], p[:collection], p[:fabric], p[:mrp_inr], p[:unit_cost_inr], p[:supplier_id], p[:launch_date]] }
end
CSV.open("#{OUT}/Dim_Store.csv", 'w') do |c|
  c << %w[store_id store_name city state region store_type]
  stores.each { |s| c << [s[:store_id], s[:store_name], s[:city], s[:state], s[:region], s[:store_type]] }
end
MONTHS = %w[_ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
DAYS = %w[Sun Mon Tue Wed Thu Fri Sat]
CSV.open("#{OUT}/Dim_Date.csv", 'w') do |c|
  c << %w[date year month_no month_name year_month quarter fiscal_year week_of_year weekday_no weekday is_weekend season festival is_sale_period is_wedding_season]
  (START_DATE..END_DATE).each do |d|
    fy = d.month >= 4 ? "FY#{(d.year + 1) % 100}" : "FY#{d.year % 100}"
    c << [d, d.year, d.month, MONTHS[d.month], d.strftime('%Y-%m'), "Q#{(d.month - 1) / 3 + 1}", fy, d.cweek,
          d.wday == 0 ? 7 : d.wday, DAYS[d.wday], [0, 6].include?(d.wday) ? 'Yes' : 'No', season_of(d),
          festival_on(d) || '', eoss?(d) ? 'Yes' : 'No', wedding_season?(d) ? 'Yes' : 'No']
  end
end

# ---------------------------------------------------------------- Simulation
sales = CSV.open("#{OUT}/Fact_Sales.csv", 'w')
sales << %w[sale_id date store_id product_id units_sold mrp_inr discount_pct gross_revenue_inr net_revenue_inr cogs_inr]
inv = CSV.open("#{OUT}/Fact_Inventory_Monthly.csv", 'w')
inv << %w[month_end_date store_id product_id opening_stock units_received units_sold closing_stock planned_demand_units actual_demand_units est_lost_sales_units stockout_days closing_stock_value_cost_inr]
pos = CSV.open("#{OUT}/Fact_Purchase_Orders.csv", 'w')
pos << %w[po_id order_date store_id product_id supplier_id qty_ordered expected_delivery_date actual_delivery_date qty_received unit_cost_inr po_value_inr delivery_status]

sale_id = 0; po_id = 0
stats = Hash.new(0)

stores.each do |st|
  products.each do |pr|
    aff = REGION_AFF[st[:region]][pr[:category]]
    true_rate = pr[:base] * st[:mult] * aff * rnd(0.85, 1.15)
    planned   = true_rate * pr[:plan_bias]                       # planner's average daily demand
    sup = SUP[pr[:supplier_id]]
    lead = sup[5]
    safety = planned * 12
    order_q = [(planned * 45).round, 3].max
    stock = nil
    pipeline = []                                                # [arrive_date, qty]
    m = nil

    (START_DATE..END_DATE).each do |d|
      if d < pr[:launch_date]
        next
      end
      if stock.nil?
        stock = [(planned * 75).round, 3].max
        m = { open: stock, recv: 0, sold: 0, plan: 0.0, dem: 0, lost: 0, so_days: 0 }
      end

      # receive deliveries
      pipeline.select { |a, _| a == d }.each { |_, q| stock += q; m[:recv] += q }
      pipeline.reject! { |a, _| a == d }

      lam = true_rate * demand_mult(d, pr, st)
      dem = poisson(lam)
      sold = [dem, stock].min
      stock -= sold
      m[:sold] += sold; m[:dem] += dem; m[:lost] += dem - sold
      m[:so_days] += 1 if stock == 0
      m[:plan] += planned

      if sold > 0
        disc = discount_pct(d, pr)
        gross = sold * pr[:mrp_inr]
        sale_id += 1
        sales << [format('SL%07d', sale_id), d, st[:store_id], pr[:product_id], sold, pr[:mrp_inr], disc,
                  gross, (gross * (1 - disc / 100.0)).round(2), (sold * pr[:unit_cost_inr]).round(2)]
        stats[:units] += sold; stats[:rev] += gross * (1 - disc / 100.0)
      end

      # weekly review (Monday): reorder-point policy on FLAT planned demand
      if d.wday == 1
        festive_build = (d.month == 9 && d.day >= 10) || d.month == 10 || (d.month == 11 && d.day <= 10) ? 1.4 : 1.0
        rop = (planned * (lead + 7) + safety) * festive_build
        ip = stock + pipeline.sum { |_, q| q }
        if ip < rop
          qty = [order_q, (rop - ip).ceil].max
          delay = R.rand < sup[6] ? R.rand(-2..1) : R.rand(4..18)
          arrive = d + lead + delay
          got = R.rand < sup[7] ? (qty * rnd(0.75, 0.95)).round : qty
          po_id += 1
          status = if arrive > END_DATE then 'Open'
                   elsif delay > 1 then 'Late'
                   else 'On Time'
                   end
          status = "#{status} - Short Shipped" if got < qty && status != 'Open'
          pos << [format('PO%06d', po_id), d, st[:store_id], pr[:product_id], pr[:supplier_id], qty, d + lead,
                  arrive > END_DATE ? '' : arrive, arrive > END_DATE ? '' : got, pr[:unit_cost_inr],
                  (qty * pr[:unit_cost_inr]).round(2), status]
          pipeline << [arrive, got] if arrive <= END_DATE
        end
      end

      # month end snapshot
      if (d + 1).month != d.month
        inv << [d, st[:store_id], pr[:product_id], m[:open], m[:recv], m[:sold], stock, m[:plan].round,
                m[:dem], m[:lost], m[:so_days], (stock * pr[:unit_cost_inr]).round(2)]
        m = { open: stock, recv: 0, sold: 0, plan: 0.0, dem: 0, lost: 0, so_days: 0 }
      end
    end
  end
end
[sales, inv, pos].each(&:close)
puts "sales lines #{sale_id}, POs #{po_id}, units #{stats[:units]}, net revenue Rs #{(stats[:rev] / 1e7).round(2)} Cr"
