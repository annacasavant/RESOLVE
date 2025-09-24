include("tab_files.jl")
include("build_gens.jl")


gens = thermals
n = length(thermals)

fuel_resources = DataFrame(
    "Bus Number" => fill(0, n),           # Int
    "ID" => fill(0, n),                   # Int
    "Name" => fill("", n),                # String
    "Bus Name" => fill("", n),            # String
    "Type" => fill("", n),                # String
    "Base Power" => fill(0.0, n),         # Float64
    "Fuel Cost" => fill(0.0, n),          # Float64
    "Fuel Rate" => fill(0.0, n),          # Float64
    "fuel_type" => fill("", n)            # String
)




fuel_resources[!, "Name"] = gens
bus_number = ones(length(gens))
fuel_resources[!, "Bus Number"] = bus_number

fuel_dict = Dict(
    "CO_NG" => "Natural Gas",
    "CO_DFO" => "Diesel",
    "Coal_Uinta" => "Coal",
    "Coal_SPRB" => "Coal",
    "NG_CCS_95" => "Natural Gas",
    "Must_run_Fuel" => "Must Run",
    "NG_CCS_90" => "Natural Gas",
    "NG_CCS_100" => "Natural Gas",
)

fuel_types = []
fuel_rates = []
for row in eachrow(tech_thermal_params)[2:end ]
    if row["x1"] in thermals
    fuel_type = fuel_dict[row["x2"]]
    fuel_rate = fuel_rate = row["x3"]
    push!(fuel_rates, fuel_rate)
    push!(fuel_types, fuel_type)
end
end
fuel_resources[!, "fuel_type"] = fuel_types
fuel_resources[!, "Fuel Rate"] = fuel_rates
fuel_resources[!, "Fuel Cost"] = ones(length(gens))

base_powers = []
for row in eachrow(tech_dispatch_params)
    if row["x1"] in thermals
    base_power = row["x6"]
    push!(base_powers, base_power)
    end
end
fuel_resources[!, "Base Power"] = base_powers