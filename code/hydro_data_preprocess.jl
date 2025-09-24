using CSV
using DataFrames


hydro_data = CSV.read("C:\\Users\\acasavan\\RESOLVE\\Model_v2.6.0 - Base Case\\Hydro Data from CETA Transmission Study.csv", DataFrame)


# Replace with your actual column names
plant_col = :Resource    # column with repeating names
value_col = :Pmax       # column with float values (e.g., water flow)

# Create dictionary: plant name => Vector of values
hydro_by_plant = Dict{String, Vector{Float64}}()

# Group by plant name
for subdf in groupby(hydro_data, plant_col)
    name = first(subdf[!, plant_col])
    values = Vector{Float64}(subdf[!, value_col])
    hydro_by_plant[name] = values
end

hydro_ts_dict = Dict{String, Any}()

for row in eachrow(hydro)
    name = first(row)
    println(name)                  
    daily_values = hydro_by_plant[name]
    hydro_values = repeat(daily_values, inner=24)
    hydro_norm = hydro_values/maximum(hydro_values)
    resolution = Dates.Hour(1)
    timestamps = range(DateTime("2025-01-01T0:00:00"); step = resolution, length = 960);
    hydro_timearray = TimeArray(timestamps, hydro_norm)
    hydro_time_series = SingleTimeSeries(;
            name = "max_active_power",
            data = hydro_timearray,
            scaling_factor_multiplier = get_max_active_power)
    hydro_ts_dict[name] = hydro_time_series
end


