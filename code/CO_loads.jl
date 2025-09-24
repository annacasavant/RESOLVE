using Pkg
Pkg.add("PowerSystems")
Pkg.add("Plots")
Pkg.add("CSV")
Pkg.add("DataFrames")

using PowerSystems 
using Plots 
using CSV
using DataFrames

wecc_sys = System("wecc_sys.json")
buses = CSV.read("CO_buses.csv", DataFrame)

co_loads = []
for row in eachrow(buses)
    load = get_components(x-> get_number(get_bus(x)) == buses, PowerLoad, wecc_sys)
    ts = get_time_series_array(SingleTimeSeries, load[1], "max_active_power")
    push!(co_loads, values(ts))
end
    