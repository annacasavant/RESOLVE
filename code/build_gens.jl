using PowerSystems
using DataFrames
using Dates
using TimeSeries
using InfrastructureSystems
using HDF5
const IS = InfrastructureSystems

cur_dir = joinpath(@__DIR__)
main_dir = abspath(joinpath(cur_dir, ".."))
sys = System(100)
include("tab_files.jl")

include("subsystems_utils.jl")

hydro = []
storage = []
thermals = []
flex_loads = []
hydro_elec = []
vre = []
solar = []
wind =  []
thermal_dispatch = []
der = []

caps = CSV.read(joinpath(main_dir, "Model_v2.6.0 - Base Case\\generation_caps.csv"), DataFrame)


for row in eachrow(caps)
    if row["2025"] != " -   "
        if row["LADWP Category"] == "Solar"
            name = row["Resources"]
            push!(solar, name)
        elseif row["LADWP Category"] == "Solar_BTM"
            name = row["Resources"]
            push!(der, name)
        elseif row["LADWP Category"] == "Wind"
            name = row["Resources"]
            push!(wind, name)
        elseif row["LADWP Category"] == "Hydro"
            name = row["Resources"]
            push!(hydro, name)
        end
        if row["LADWP Category"] == "Gas" ||  row["LADWP Category"] == "Oil" || row["LADWP Category"] == "Coal" || row["LADWP Category"] == "New Firm Resources" || row["LADWP Category"] == "New Geothermal" || row["LADWP Category"] == "Biomass" || row["LADWP Category"] == "Hydrogen"
            name = row["Resources"]
            push!(thermals, name)   
        end
    end
end
# include("resolve_hydro_data_preprocess.jl")

solar[31] = "Sune_Alamosa_Solar_PSCO_Contract"


bus = ACBus(;
number = 1,
name = "bus", 
bustype = ACBusTypes.REF,
angle = 0.0,
magnitude = 1.0,
voltage_limits = (min = 0.0, max = 1.0),
base_voltage = 1,
)
add_component!(sys, bus)       


# load_values = Vector{Float64}(zone_params[2:961, 3])
# load_norm = load_values/maximum(load_values)
# resolution = Dates.Hour(1)
# timestamps = range(DateTime("2025-01-01T0:00:00"); step = resolution, length = 960);
# load_timearray = TimeArray(timestamps, load_norm)
# load = PowerLoad(
#     name = "Load",
#     available = true, 
#     bus = bus,
#     active_power = 0.0, 
#     reactive_power = 0.0, 
#     base_power = 1.0, 
#     max_active_power = maximum(load_values),
#     max_reactive_power = 0.0,

# )
# add_component!(sys, load)

# load_time_series = SingleTimeSeries(;
#             name = "max_active_power",
#             data = load_timearray,)

# add_time_series!(sys, load, load_time_series)
########## VRE Time Series ############################ USING RESOLVE DATA 

# solar_ts_dict = Dict{String, Any}()
# # Loop through each row of solar and shapes
# for (row1, row2) in (zip(eachrow(solar), eachrow(shapes)))
#     name = row1[]
#     # Grab all rows from shapes where x1 matches row1["x1"]
#     matching_rows = filter(r -> r["x1"] == name, eachrow(shapes))
#     # Now matching_rows is a list of DataFrameRows where x1 matches the name
#     # Extract the x2 values from those rows
#     solar_values = Vector{Float64}([r["x4"] for r in matching_rows] ) 
#     solar_norm = solar_values/(maximum(solar_values))
#     resolution = Dates.Hour(1)
#     timestamps = range(DateTime("2025-01-01T0:00:00"); step = resolution, length = 960);
#     solar_timearray = TimeArray(timestamps, solar_norm)
#     solar_time_series = SingleTimeSeries(;
#             name = "max_active_power",
#             data = solar_timearray,
#             scaling_factor_multiplier = get_max_active_power)
#     # Store the result in the dictionary
#     solar_ts_dict[name] = solar_time_series
# end

# wind_ts_dict = Dict{String, Any}()
# for (row1, row2) in (zip(eachrow(wind), eachrow(shapes)))
#     name = row1[]
#     # Grab all rows from shapes where x1 matches row1["x1"]
#     matching_rows = filter(r -> r["x1"] == name, eachrow(shapes))
#     # Now matching_rows is a list of DataFrameRows where x1 matches the name
#     # Extract the x2 values from those rows
#     wind_values = Vector{Float64}([r["x4"] for r in matching_rows])
#     wind_norm = wind_values/maximum(wind_values)
#     resolution = Dates.Hour(1)
#     timestamps = range(DateTime("2025-01-01T0:00:00"); step = resolution, length = 960);
#     wind_timearray = TimeArray(timestamps, wind_norm)
#     wind_time_series = SingleTimeSeries(;
#             name = "max_active_power",
#             data = wind_timearray,
#             scaling_factor_multiplier = get_max_active_power)
#     # Store the result in the dictionary
#     wind_ts_dict[name] = wind_time_series
# end


########## VRE Time Series ############################ USING WECC DATA 

# include("bus_mapping_geo.jl")

# solar_single_ts = Dict{String, SingleTimeSeries}()
# for row in eachrow(solar)
#     name = row[1]
#     println(name)
#     solar_timearray = solar_ts[name]
#     solar_time_series = SingleTimeSeries(;
#         name = "max_active_power",
#         data = solar_timearray,
#         scaling_factor_multiplier = get_max_active_power)
#     solar_single_ts[row[1]] = solar_time_series
# end

# wind_single_ts = Dict{String, SingleTimeSeries}()
# for row in eachrow(wind)
#     name = row[1]
#     println(name)
#     wind_timearray = wind_ts[name]
#     wind_time_series = SingleTimeSeries(;
#         name = "max_active_power",
#         data = wind_timearray,
#         scaling_factor_multiplier = get_max_active_power)
#     wind_single_ts[row[1]] = wind_time_series
# end


vre_capacities = Dict{String, Any}()

for row in eachrow(caps)
    if row["2025"] != " -   "
    type = row["LADWP Category"]
    if row["Resources"] == "SunE_Alamosa_Solar_PSCO_Contract"
        name = "Sune_Alamosa_Solar_PSCO_Contract"
    else
        name = row["Resources"]
    end
    if type == "Solar" || type == "Wind" || type == "Solar_BTM"
        if row["2025"] != " -   "
        cap = row["2025"]
            vre_capacities[name] = parse(Float64, cap)
    end
end
end
end

for row in solar
    ts = make_timeseries(row, "solar")
        solars = RenewableDispatch(
        name = row,
        available = true,
        bus = bus,
        active_power = 0.0,
        reactive_power = 0,
        rating = 1.0,
        prime_mover_type = PrimeMovers.PVe,
        reactive_power_limits = (min = 0.0, max = 0.0),
        power_factor = 1.0,
        operation_cost = RenewableGenerationCost(nothing),
        base_power = vre_capacities[row]
    )
    add_component!(sys, solars)
    add_time_series!(sys, solars, ts)
    end

for row in der
    ts = make_der_time_series(row)
    ders = RenewableNonDispatch(
        name = row,
        available = true,
        bus = bus,
        active_power = 0.0,
        reactive_power = 0,
        rating = 1.0,
        prime_mover_type = PrimeMovers.PVe,
        power_factor = 1.0,
        base_power = vre_capacities[row]
    )
    add_component!(sys, ders)
    add_time_series!(sys, ders, ts)
end


# solar_ts_dict = solar_mapping(collect(get_components(x-> get_prime_mover_type(x) == PrimeMovers.PVe, RenewableDispatch, sys)), wecc_sys)



for row in wind
    ts = make_timeseries(row, "wind")
        winds = RenewableDispatch(
            name = row,
            available = true,
            bus = bus,
            active_power = 0.0,
            reactive_power = 0,
            rating = 1.0,
            prime_mover_type = PrimeMovers.WT,
            reactive_power_limits = (min = 0.0, max = 0.0),
            power_factor = 1.0,
            operation_cost = RenewableGenerationCost(nothing),
            base_power = vre_capacities[row]
        )
        add_component!(sys, winds)
        add_time_series!(sys, winds, ts)
end

hydro_reservoir = CSV.read("hydro_reservoir.csv", DataFrame)
hydro_res_dict = Dict(Pair.(hydro_reservoir.plant, hydro_reservoir.storage_capacity))

include("hydro_ts_data_preprocess.jl")

hydro_ts_dict = get_hydro_ts_dict(hydro)


############## FOR PSY5 VERSION ###################
# for row in eachrow(hydro_params)[1: end-7]
#     resource = row[:"resrouce"]
#     if resource in hydro
#             resource = row[:"resrouce"]
        
#             if resource in hydro_reservoir[:, :plant]
#                 hydros = HydroEnergyReservoir(
#                     name = row["resrouce"],
#                     available = true, 
#                     bus = bus, 
#                     active_power = 0.0,
#                     reactive_power = 0.0, 
#                     rating = 1.0,
#                     prime_mover_type= PrimeMovers.HA,
#                     active_power_limits = (min = 0.0, max = row["2025"]),
#                     reactive_power_limits = nothing,
#                     ramp_limits = nothing, 
#                     time_limits = nothing, 
#                     base_power = row["2025"]/100,
#                     storage_capacity = hydro_res_dict[resource], 
#                     inflow = hydro_res_dict[resource], 
#                     initial_storage = hydro_res_dict[resource], 
#                     operation_cost = HydroGenerationCost(nothing),
#                 )
#                 add_component!(sys, hydros)
#                 timeseries_vector = hydro_ts_dict[row[:resrouce]] ./ (get_rating(hydros)*get_base_power(hydros))
#                 hydro_timeseries = make_hydro_ts(timeseries_vector)
#                 add_time_series!(sys, hydros, hydro_timeseries)
#             else 
#                 hydros = HydroDispatch(;
#                     name = row["resrouce"],
#                     available = true, 
#                     bus = bus, 
#                     active_power = 0.0,
#                     reactive_power = 0.0, 
#                     rating = 1.0,
#                     prime_mover_type= PrimeMovers.HA,
#                     active_power_limits = (min = 0.0, max = row["2025"]),
#                     reactive_power_limits = nothing,
#                     ramp_limits = nothing, 
#                     time_limits = nothing, 
#                     base_power = row["2025"]/100,
#                     operation_cost = HydroGenerationCost(nothing),
#                 )
#                 timeseries_vector = hydro_ts_dict[row[:resrouce]] ./ (get_rating(hydros)*get_base_power(hydros))
#                 hydro_timeseries = make_hydro_ts(timeseries_vector)
#                 add_component!(sys, hydros)
#                 add_time_series!(sys, hydros, hydro_timeseries)
#             end
#     end
# end

for row in eachrow(hydro_params)[1: end-7]
    resource = row[:"resrouce"]
    if resource in hydro
        hydros = HydroDispatch(;
        name = resource, 
        available = true, 
        bus = bus, 
        active_power = 0.0, 
        reactive_power = 0.0, 
        rating = 1.0, 
        prime_mover_type = PrimeMovers.HY,
        active_power_limits = (min = 0.0, max = row["2025"]), 
        reactive_power_limits = nothing, 
        ramp_limits = nothing, 
        time_limits = nothing, 
        base_power = row["2025"]/100,
        operation_cost = HydroGenerationCost(nothing)
        )
        add_component!(sys, hydros)
        timeseries_vector = hydro_ts_dict[row[:resrouce]] ./ (get_rating(hydros)*get_base_power(hydros))
        hydro_timeseries = make_hydro_ts(timeseries_vector)
        add_time_series!(sys, hydros, hydro_timeseries)     
    end

end

fuel_dict = Dict(
    "CO_NG" => ThermalFuels.NATURAL_GAS,
    "CO_DFO" => ThermalFuels.DISTILLATE_FUEL_OIL,
    "Coal_Uinta" => ThermalFuels.COAL,
    "Coal_SPRB" => ThermalFuels.COAL,
    "NG_CCS_95" => ThermalFuels.NATURAL_GAS,
    "Must_run_Fuel" => ThermalFuels.OTHER,
    "NG_CCS_90" => ThermalFuels.NATURAL_GAS,
    "NG_CCS_100" => ThermalFuels.NATURAL_GAS,
    "Must_run_fuel" => ThermalFuels.OTHER
)


fuel_prices_ts = CSV.read(joinpath(main_dir, "Model_v2.6.0 - Base Case\\fuel_prices_ts.csv"), DataFrame)
# fuel_ts_dict = Dict{String, SingleTimeSeries}()

# for (name, col) in zip(names(fuel_prices_ts[:, 1:9]), eachcol(fuel_prices_ts)[1:9])
#     fuel_values = col
#     resolution = Dates.Hour(1)
#     timestamps = range(DateTime("2025-01-01T0:00:00"); step = resolution, length = 960);
#     fuel_timearray = TimeArray(timestamps, fuel_values)
#     fuel_single_time_series = SingleTimeSeries(;
#             name = "fuel_cost",
#             data = fuel_timearray,)
#     fuel_ts_dict[name] = fuel_single_time_series
# end

fuel_ts_dict = Dict{String, Float64}(
    "Uranium"  => 0.7,
    "NG_CCS_100" => 0.05219749999999997,
    "NG_CCS_95" => 0.15906078759999998,
    "Must_run_Fuel" => 0,
    "NG_CCS_90" => 0.26594232505000004,
    "CO_NG" => 2.1898099999999987,
    "Coal_SPRB" => 1.3974000000000013,
    "CO_DFO" => 20.715854510249983,
    "Coal_Uinta" => 2.3153999999999977
)


prime_mover_dict = Dict(
    ThermalFuels.NATURAL_GAS => PrimeMovers.CT ,
    ThermalFuels.COAL => PrimeMovers.ST,
    ThermalFuels.OTHER => PrimeMovers.OT,
    ThermalFuels.DISTILLATE_FUEL_OIL => PrimeMovers.ST
)

filtered_tech_thermal_params = filter(row -> row["x1"] in thermals, tech_thermal_params)
filterd_tech_dispatch = filter(row -> row["x1"] in thermals, tech_dispatch_params)
filtered_technologies = filter(row -> row["x1"] in thermals, technologies)


fuel_type = []
for row in eachrow(filtered_tech_thermal_params)[2:end]
        fuel_data = row["x2"]
        println(fuel_data)
        fuels = fuel_dict[fuel_data]
        push!(fuel_type, fuels)
end



thermal_standard = []
for (row_dispatch, row_thermal, row_tech, elem) in Iterators.drop(zip(eachrow(tech_dispatch_params), eachrow(tech_thermal_params), eachrow(technologies), eachrow(fuel_type)), 1)        
        ramp = row_dispatch["x3"]
        if row_thermal["x1"] in thermals
            min_down = row_dispatch["x4"]
            min_up = row_dispatch["x5"]
            base = row_dispatch["x6"]
            fuels = row_thermal["x2"]
            fuel_standard = fuel_dict[fuels]
            min_active_power = row_dispatch["x2"]
            prime_mover = prime_mover_dict[fuel_standard]
            thermal_stand = ThermalStandard(
                name = row_thermal["x1"],
                available = true, 
                status = true, 
                bus = bus, 
                active_power = 0.0, 
                reactive_power = 0.0, 
                rating = 1.0, 
                active_power_limits = (min = min_active_power, max = 1.0 ), 
                reactive_power_limits = nothing, 
                ramp_limits = (up = ramp/base, down = ramp/base),
                operation_cost = ThermalGenerationCost(nothing),
                base_power = base, 
                time_limits = (up = min_up, down = min_down),
                prime_mover_type = prime_mover,
                fuel = fuel_standard,
            )
            add_component!(sys, thermal_stand)
            push!(thermal_standard, row_thermal["x1"])
            ## ThermalGenCost Construction
            heat_rate = row_thermal["x3"]
            intercept = row_thermal["x4"]
            start_up_cost = row_dispatch["x7"]
            shut_down = row_dispatch["x8"]
            value_curve = LinearCurve(heat_rate, intercept)
            fuel = row_thermal["x2"]
            fuel_ts = fuel_ts_dict[fuel]
            vom = LinearCurve(row_tech["x8"])
            fuel_curve = FuelCurve(;value_curve = value_curve, fuel_cost = fuel_ts , vom_cost = vom)
            op_cost = ThermalGenerationCost(
                variable = fuel_curve, 
                fixed = 0.0,
                start_up = row_dispatch["x7"],
                shut_down = row_dispatch["x8"]
            )
            set_operation_cost!(thermal_stand, op_cost)
            #set_fuel_cost!(sys, thermal_stand, fuel_ts)
        end
    end



for row in eachrow(storage_params)[1:31]
    if row["Capacity 2025"] != 0
        power_cap = row["Capacity 2025"]
        duration = row["Min Duration"]
        energy_cap = power_cap*duration
        storages = EnergyReservoirStorage(
            name = row["resource"],
            available = true, 
            bus= bus, 
            prime_mover_type = PrimeMovers.BA,
            storage_technology_type = StorageTech.LIB,
            storage_capacity = energy_cap,
            storage_level_limits = (min = 0.0, max = 1.0),
            initial_storage_capacity_level = 1.0, 
            rating = 1.0, 
            active_power = 0.0, 
            input_active_power_limits = (min = 0.0, max = 1.0),
            output_active_power_limits = (min = 0.0, max = 1.0),
            efficiency = (in = row["Charge Eff"], out = row["Discharge Eff"]),
            reactive_power = 0.0, 
            reactive_power_limits = nothing, 
            base_power = energy_cap
        )
            add_component!(sys, storages)

    end
end

###### Building Loads from WECC ##################

load_data = CSV.read("load_params.csv", DataFrame)
load_ts = CSV.read("load_ts.csv", DataFrame)
load_ts_dict = Dict(pairs(eachcol(load_ts)))
include("subsystems_utils.jl")
for row in eachrow(load_data)
    load = build_standard_load(row)
    add_component!(sys, load)   
    load_array = load_ts_dict[Symbol(row[:name])] # have to convert the string to a symbol 
    load_array_float = Float64.(load_array)
    if typeof(load_array_float) != Vector{Float64}
        @error "type is wrong"
    end
    load_timeseries = make_load_ts(load_array_float)
    add_time_series!(sys, load, load_timeseries)
end



# load_values = Vector{Float64}(zone_params[2:961, 3])
# load_norm = load_values/maximum(load_values)
# load_ts = make_powerload(state_loads)
# load = PowerLoad(
#     name = "Load",
#     available = true, 
#     bus = bus,
#     active_power = 0.0, 
#     reactive_power = 0.0, 
#     base_power = 1.0, 
#     max_active_power = maximum(load_values),
#     max_reactive_power = 0.0,

# )
# add_component!(sys, load)               
# add_time_series!(sys, load, load_ts)

### get time series from WECC

to_json(sys, "9_24_CO_system.json", force = true)   

show_components(ThermalStandard, sys, [:ramp_limits])


maximum(sum(permutedims(stack(get_time_series_values.(SingleTimeSeries,(get_components(StandardLoad,sys)),"max_active_power"))),dims=1))

new = System("new_CO_system.json")

sum(permutedims(stack(get_time_series_values.(SingleTimeSeries,(get_components(StandardLoad,new)),"max_active_power"))),dims=1)

timeseries = []

for load in collect(get_components(StandardLoad, new))
    ts = values(get_time_series_array(SingleTimeSeries, load, "max_active_power"))
    push!(timeseries, ts)
end

cap = []
names = []
for gens in collect(get_components(ThermalStandard, sys))
    total_cap = get_base_power(gens)
    push!(names, get_name(gens))
    push!(cap, total_cap)
end

for gens in collect(get_components(RenewableDispatch, sys))
    total_cap = get_base_power(gens)
    push!(names, get_name(gens))
    push!(cap, total_cap)
end

for gens in collect(get_components(HydroDispatch, sys))
    total_cap = get_base_power(gens)
    push!(names, get_name(gens))
    push!(cap, total_cap)
end


for gens in collect(get_components(RenewableNonDispatch, sys))
    total_cap = get_base_power(gens)
    push!(names, get_name(gens))
    push!(cap, total_cap)
end

for gens in collect(get_components(EnergyReservoirStorage, sys))
    total_cap = get_base_power(gens)
    push!(names, get_name(gens))
    push!(cap, total_cap)
end





