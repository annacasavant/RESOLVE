using CSV
using DataFrames
cur_dir =  joinpath(@__DIR__)
main_dir = abspath(joinpath(cur_dir, ".."))
data_dir = joinpath(main_dir, "hydro_ts")    

function get_hydro_ts_dict(hydro)
    #CO_hydro_ts = CSV.read(joinpath(data_dir, "IL_hydro_ts.csv"), DataFrame)

    hydro_plants = []
    for name in hydro 
        push!(hydro_plants, name)
    end
    hydro_plant_nums = [2, 2, 1, 3, 3, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1,1 ]
    num_units_dict = Dict(k => v for (k,v) in zip(hydro_plants, hydro_plant_nums))

    hydro_ts_dict = Dict{String, Vector{Float64}}()


        for name in hydro_plants[1:end-3] # notincluding  Small CO, WAPA CRPS, or WAPA CAP - don't have ts for them currently 
            hydro_data = CSV.read(joinpath(data_dir, "$name.csv"), DataFrame)
            hydro_data.datetime = Date.(hydro_data.datetime, dateformat"m/d/y")
            df_2019 = filter( row -> year(row.datetime) == 2019, hydro_data)
            # println(df_2019)
            days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]*24
            hydro_ts = []            
            for (idx, value) in enumerate(days_in_month)
                df_2019_data = (df_2019[:, :power_predicted_mwh] ./ df_2019[:, :n_hours]) ./num_units_dict[name]
                month_ts = fill(df_2019_data[idx], value)
                append!(hydro_ts, month_ts)
            end
            hydro_ts_dict["$name"] = hydro_ts
        end
        return hydro_ts_dict
end






