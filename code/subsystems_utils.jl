function build_new_load(load, bus)
    new_load = StandardLoad(;
        name = get_name(load),
        available = get_available(load),
        bus = bus, 
        base_power = get_base_power(load),
        constant_active_power = get_constant_active_power(load), 
        constant_reactive_power = get_constant_reactive_power(load),
        impedance_active_power = get_impedance_active_power(load), 
        impedance_reactive_power = get_impedance_reactive_power(load), 
        current_active_power = get_current_active_power(load), 
        current_reactive_power = get_current_reactive_power(load), 
        max_constant_active_power = get_max_constant_active_power(load), 
        max_constant_reactive_power = get_max_constant_reactive_power(load), 
        max_impedance_active_power = get_max_impedance_active_power(load), 
        max_impedance_reactive_power = get_max_impedance_reactive_power(load), 
        max_current_active_power = get_max_current_active_power(load), 
        max_current_reactive_power = get_max_current_reactive_power(load), 
    )
    return new_load 
end





# function find_matching_key(h5_path::String, closest_key::Float64)
#     key_str = string(closest_key)  # Convert float to string

#     h5open(h5_path, "r") do f
#         for key in keys(f)
#             grp = f[key]
#             attrs = attributes(grp)

#             name = read(attrs["name"])  # Read the 'name' attribute
#             cap = read(attrs["system_capacity"])
#             cf = read(attrs["capacity_factor"])
#             ts = read(grp["sienna_timeseries"])
#             return ts
#         end
#     end
# # end

# function get_matching_plant_data(h5_path::String, closest_key::String)
#     h5open(h5_path, "r") do f
#         for key in keys(f)
#             grp = f[key]
#             attrs = attributes(grp)
#             # Read 'name' attribute to compare
#             name = read(attrs["name"])
#             #transformed_plant_name = replace(transformed_closest_key, "_" => " ")
#             if name == strip(closest_key)
#                 cap = read(attrs["system_capacity"])
#                 cf = read(attrs["capacity_factor"])
#                 ts = read(grp["sienna_timeseries"])
#                 return ts
#             end
#         end
#     end 
# end



# function find_closest_name(h5_path::String, plant_name::String)
#     lev = Levenshtein()
#     closest_name = nothing
#     closest_key = nothing
#     min_dist = typemax(Int)  # initialize to max Int

#     h5open(h5_path, "r") do f
#         for key in keys(f)
#             grp = f[key]
#             attrs = attributes(grp)

#             if haskey(attrs, "name")
#                 name = strip(read(attrs["name"]))  # strip whitespace
#                 dist = evaluate(lev, lowercase(name), lowercase(strip(plant_name)))

#                 if dist < min_dist
#                     min_dist = dist
#                     closest_name = name
#                     closest_key = key
#                 end
#             end
#         end
#     end

#     return closest_key
# end

function get_h5_data(row::String, data_type::String)
    file = h5open("$(data_type)_results.h5", "r") do f
        # List keys at root level
        println("Keys at root level:")
        for key in keys(f)
            println(key)
        end

        # Access dataset by key
        data = read(f[row])
        return data  # optionally return the data from the `do` block
    end
end


function make_timeseries(row::String, data_type::String)
    ts = get_h5_data(row, data_type)                  
    resolution = Dates.Hour(1);
    timestamps = range(DateTime("2029-01-01T00:00:00"); step = Hour(1), length = 8760);
    solar_array = TimeSeries.TimeArray(timestamps, ts["sienna_timeseries"])
    solar_TS = SingleTimeSeries(;
           name = "max_active_power",
           data = solar_array, 
		   scaling_factor_multiplier = get_max_active_power,# max active power,
       );
       return solar_TS
end


function make_hydro_ts(timeseries_vector)
    resolution = Dates.Hour(1);
    timestamps = range(DateTime("2029-01-01T00:00:00"); step = Hour(1), length = 8760);
    ts_array = TimeSeries.TimeArray(timestamps, timeseries_vector)
    TS = SingleTimeSeries(;
           name = "max_active_power",
           data = ts_array, 
		   scaling_factor_multiplier = get_max_active_power,# max active power,
       );
       return TS
end


function build_standard_load(row)
    load = StandardLoad(;
        name = row[:name],
        available = true, 
        bus = bus, 
        base_power = row[:base_power],
        constant_active_power = row[:constant_active_power],
        constant_reactive_power = row[:constant_reactive_power],
        impedance_active_power = row[:impedance_active_power],
        impedance_reactive_power = row[:impedance_reactive_power],
        current_active_power = row[:current_active_power],
        current_reactive_power = row[:current_reactive_power],
        max_constant_active_power = row[:max_constant_active_power],
        max_constant_reactive_power = row[:max_constant_reactive_power],
        max_impedance_active_power = row[:max_impedance_active_power],
        max_impedance_reactive_power = row[:max_impedance_reactive_power],
        max_current_active_power = row[:max_current_active_power],
        max_current_reactive_power = row[:max_current_reactive_power],
    )
    return load 
    end

function make_load_ts(load_array)
    resolution = Dates.Hour(1);
    timestamps = range(DateTime("2029-01-01T00:00:00"); step = Hour(1), length = 8760);
    ts_array = TimeSeries.TimeArray(timestamps, load_array)
    TS = SingleTimeSeries(;
           name = "max_active_power",
           data = ts_array, 
		   scaling_factor_multiplier = nothing,# max active power,
       );
       return TS
end

function make_der_time_series(row)
    resolution = Dates.Hour(1);
    timestamps = range(DateTime("2029-01-01T00:00:00"); step = Hour(1), length = 8760);
    ts_df = CSV.read("der_results.CSV", DataFrame)
    ts_array = TimeSeries.TimeArray(timestamps, ts_df[:, :Solar_BTM_Existing])
    TS = SingleTimeSeries(;
           name = "max_active_power",
           data = ts_array , 
		   scaling_factor_multiplier = nothing,# max active power,
       );
       return TS
end