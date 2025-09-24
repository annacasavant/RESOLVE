using DelimitedFiles
using CSV
using DataFrames

cap_limit = DataFrame(readdlm("Model_v2.6.0 - Base Case/capacity_limits.tab"), :auto)

cap_limit_local = DataFrame(readdlm("Model_v2.6.0 - Base Case/capacity_limits_local.tab"), :auto)

hydro_budget = DataFrame(readdlm("Model_v2.6.0 - Base Case/energy_sharing_daily_max_changes.tab"), :auto)

fuel_prices = DataFrame(readdlm("Model_v2.6.0 - Base Case/fuel_prices.tab"), :auto)

fuels = DataFrame(readdlm("Model_v2.6.0 - Base Case/fuels.tab"), :auto)

ramp_intertimepoint = DataFrame(readdlm("Model_v2.6.0 - Base Case/ramps_intertimepoint.tab"), :auto)

renewable_targets = DataFrame(readdlm("Model_v2.6.0 - Base Case/renewable_targets.tab"), :auto)

reserve_resources = DataFrame(readdlm("Model_v2.6.0 - Base Case/reserve_resources.tab"), :auto)

reserve_timepoint_requirements = readdlm("Model_v2.6.0 - Base Case/reserve_timepoint_requirements.tab")

resource_prm_nqc = DataFrame(readdlm("Model_v2.6.0 - Base Case/resource_prm_nqc.tab"), :auto)

resource_VRE = DataFrame(readdlm("Model_v2.6.0 - Base Case/resource_variable_renewable.tab"), :auto)

VRE_prm = DataFrame(readdlm("Model_v2.6.0 - Base Case/resource_variable_renewable_prm.tab"), :auto)

resource_vintage_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/resource_vintage_params.tab"), :auto)

resource_storage_vintage_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/resource_vintage_storage_params.tab"), :auto)

resources = DataFrame(readdlm("Model_v2.6.0 - Base Case/resources.tab"), :auto)

shapes = DataFrame(readdlm("Model_v2.6.0 - Base Case/shapes.tab"), :auto)

system_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/system_params.tab"), :auto)

tech_dispatch_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/tech_dispatchable_params.tab"), :auto)

tech_storage_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/tech_storage_params.tab"), :auto)

tech_thermal_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/tech_thermal_params.tab"), :auto)

technologies = DataFrame(readdlm("Model_v2.6.0 - Base Case/technologies.tab"), :auto)

# cap_group = DataFrame(readdlm("Model_v2.6.0 - Base Case/capacity_groups.tab"), :auto)

zone_params = DataFrame(readdlm("Model_v2.6.0 - Base Case/zone_timepoint_params.tab"), :auto)

storage_params = CSV.read("Model_v2.6.0 - Base Case\\storage_params.csv", DataFrame)

hydro_params = CSV.read("Model_v2.6.0 - Base Case\\hydro_params.csv", DataFrame)
