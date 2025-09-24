using PowerSystems
using PowerSimulations
using Dates
using CSV
using DataFrames
using Logging
using TimeSeries
using HiGHS #solver
# using PowerNetworkMatrices
using HydroPowerSimulations
using Xpress
using StorageSystemsSimulations
#using PowerGraphics
mip_gap = 0.01
  

md_sys = System("bah_system.json")


for load in collect(get_components(StandardLoad, md_sys))
    if get_constant_active_power(load) != 0.0
        ts = values(get_time_series_array(SingleTimeSeries, load, "max_active_power"))
        new_ts = ts/(get_constant_active_power(load)*100)
        remove_time_series!(md_sys, SingleTimeSeries, load, "max_active_power")
        resolution = Dates.Hour(1);
        timestamps = range(DateTime("2029-01-01T00:00:00"); step = Hour(1), length = 8760);
        ts_array = TimeSeries.TimeArray(timestamps, new_ts)
        TS = SingleTimeSeries(;
            name = "max_active_power",
            data = ts_array, 
            scaling_factor_multiplier = nothing,# max active power,
        );
        add_time_series!(md_sys, load, TS)
    end
end

#sum(permutedims(stack(get_time_series_values.(SingleTimeSeries,(get_components(StandardLoad,md_sys)),"max_active_power"))),dims=1)

transform_single_time_series!(md_sys, Hour(24), Day(1))


mip_gap = 0.1

optimizer = optimizer_with_attributes(
                Xpress.Optimizer,
                #"parallel" => "on",
                "MIPRELSTOP" => mip_gap)
                
# solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)



logger= configure_logging(console_level=Logging.Info)

template_ed = ProblemTemplate(
    NetworkModel(
        CopperPlatePowerModel;
        use_slacks = true,
    ),
)
set_device_model!(template_ed, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_ed, RenewableDispatch, RenewableFullDispatch) 
set_device_model!(template_ed, StandardLoad, StaticPowerLoad)
set_device_model!(template_ed, HydroDispatch, HydroDispatchRunOfRiver)
set_device_model!(template_ed, RenewableNonDispatch, FixedOutput) 





# storage_model = DeviceModel(
#     EnergyReservoirStorage,
#     StorageDispatchWithReserves;
#     attributes=Dict(
#         "reservation" => true,
#         "energy_target" => false,
#         "cycling_limits" => false,
#         "regularization" => true,
#     ),
# )
# set_device_model!(template_ed, storage_model)

initial_date = "2029-01-01"
start_time = DateTime(string(initial_date,"T00:00:00"))
model = DecisionModel(template_ed, md_sys; name = "ED", optimizer = optimizer, horizon = Dates.Hour(24), calculate_conflict = true, store_variable_names = true)
models = SimulationModels(; decision_models = [model])

steps_sim    = 365
current_date = string( today() )
sequence = SimulationSequence(
    models = models,
    #ini_cond_chronology = InterProblemChronology(),
)

sim = Simulation(
    name = current_date * "_DR-test" * "_" * string(steps_sim)* "steps",
    steps = steps_sim,
    models = models,
    initial_time = DateTime(string(initial_date,"T00:00:00")),
    sequence = sequence,
    simulation_folder = tempdir()#".",
)

build!(sim)

execute!(sim)
### exporting jump model
# save_path = joinpath(main_dir, "jump_natural_units.txt")
# decision_model = model.internal.container.JuMPmodel
# PowerSimulations.serialize_jump_optimization_model(decision_model, save_path)

results = SimulationResults(sim)
ed_results = get_decision_problem_results(results, "ED")
using PowerGraphics 
results = SimulationResults(sim)

ed = get_decision_problem_results(results, "ED")
p = plot_fuel(ed, generator_mapping_file = "C:\\Users\\acasavan\\GitHub_Repos\\my_genmap.yaml", curtailment = false)

sum(permutedims(stack(get_time_series_values.(SingleTimeSeries,(get_components(StandardLoad,md_sys)),"max_active_power"))),dims=1)

   

load_ts = read_parameter(ed, "ActivePowerTimeSeriesParameter__StandardLoad")
load = load_ts[DateTime("2029-01-01T00:00:00")]
sum(load[1, 2:end])

vre_ts = read_realized_variable(ed, "ActivePowerVariable__RenewableDispatch")
sum(vre_ts[1, 2:end])

der_ts = read_parameter(ed, "ActivePowerTimeSeriesParameter__RenewableNonDispatch")
der_ts[DateTime("2029-01-01T00:00:00")]


thermal_ts = read_realized_variable(ed, "ActivePowerVariable__ThermalStandard")
sum(thermal_ts[1, 2:end])

hydro_ts = read_realized_variable(ed, "ActivePowerVariable__HydroDispatch")
sum(hydro_ts[1, 2:end])


slack_down = read_realized_variable(ed, "SystemBalanceSlackDown__System")

total_downs = []
for row in eachrow(slack_down)
    total_down = sum(row[2:end])
    push!(total_downs, total_down)
end

slack_up = read_realized_variable(ed, "SystemBalanceSlackUp__System")

total_ups = []
for row in eachrow(slack_up)
    total_up = sum(row[2:end])
    push!(total_ups, total_up)
end

biomass = []
geothermal = []
storage = []
btm = []
solar = []
wind = []
hydro = []
biogas = []
nfr = []
gas = []
oil = []
coal = []
der = []
for gens in collect(get_components(RenewableDispatch, md_sys))
    if get_prime_mover_type(gens) == PrimeMovers.PVe && get_name(gens) != "Solar_BTM_Existing"
        push!(solar, get_name(gens))
    elseif get_prime_mover_type(gens) == PrimeMovers.WT 
        push!(wind, get_name(gens))
    end
end
for gens in collect(get_components(HydroDispatch, md_sys))
        push!(hydro, get_name(gens))
end
for gens in collect(get_components(ThermalStandard, md_sys))
    if get_fuel(gens) == ThermalFuels.COAL 
        push!(coal, get_name(gens))
    elseif get_fuel(gens) == ThermalFuels.NATURAL_GAS 
        push!(gas, get_name(gens))
    elseif get_fuel(gens) == ThermalFuels.DISTILLATE_FUEL_OIL 
        push!(oil, get_name(gens))
    end
end
for gens in collect(get_components(RenewableNonDispatch, md_sys))
        push!(der, get_name(gens))
end


gas_results = thermal_ts[:, gas]
oil_results = thermal_ts[:, oil] 
coal_results = thermal_ts[:, coal]
solar_results = vre_ts[:, solar]
wind_results = vre_ts[:, wind]
hydro_results = hydro_ts[:, hydro]
total_gas_hour_gen = []
for row in eachrow(gas_results)
    gas_hour_gen = sum(row)
    push!(total_gas_hour_gen, gas_hour_gen)
end

total_oil_hour_gen = []
for row in eachrow(oil_results)
    oil_hour_gen = sum(row)
    push!(total_oil_hour_gen, oil_hour_gen)
end

total_coal_hour_gen = []
for row in eachrow(coal_results)
    coal_hour_gen = sum(row)
    push!(total_coal_hour_gen, coal_hour_gen)
end

total_solar_hour_gen = []
for row in eachrow(solar_results)
    solar_hour_gen = sum(row)
    push!(total_solar_hour_gen, solar_hour_gen)
end

total_wind_hour_gen = []
for row in eachrow(wind_results)
    wind_hour_gen = sum(row)
    push!(total_wind_hour_gen, wind_hour_gen)
end

total_hydro_hour_gen = []
for row in eachrow(hydro_results)
    hydro_hour_gen = sum(row)
    push!(total_hydro_hour_gen, hydro_hour_gen)
end



der_total = []
for (key, df) in der_ts
    
    der_solar = df[:, :"Solar_BTM_Existing"]
    append!(der_total, der_solar)
end







