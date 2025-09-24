using GeoJSON
using PowerSystems
using JSON3
using CSV
using DataFrames
import WECC
using PowerSystems
using PolygonOps
using InfrastructureSystems


include("extract_states_functions.jl")


sys = WECC.build_system(
    WECC.WECCSystems,
    "WECC_ADS_2030_PCM";
    load_year = 2030,
    load_data_source = "ADS",
    pv_wind_data_source = "ADS",
    trim_components = false,
    skip_serialization = true,
    update_names = false
);

#Supplement lat/lon data (89496 buses have lat/lon, 3844 do not)
# for arc in get_components(Arc, wecc_sys)
#     from_bus = get_from(arc)
#     to_bus = get_to(arc)
#     if determine_lon_lat(from_bus) === nothing && determine_lon_lat(to_bus) === nothing 
#         @error "two buses connected without latlon info" 
#     elseif determine_lon_lat(from_bus) === nothing 
#         geo_info = get_supplemental_attributes(GeographicInfo, to_bus)[1]
#         add_supplemental_attribute!(wecc_sys, from_bus, geo_info)
#     elseif determine_lon_lat(to_bus) === nothing 
#         geo_info = get_supplemental_attributes(GeographicInfo, from_bus)[1]
#         add_supplemental_attribute!(wecc_sys, to_bus, geo_info)
#     end 
# end 

## read in GeoJSON data 
fc = GeoJSON.read("C:\\Users\\acasavan\\TA_experiments\\state_boundaries.json")
# states = [feature.properties[:STATE] for feature in fc.features]

# State to extract:
state_name = "Colorado"
state_geometry = filter(x -> x.NAME == state_name, fc.features)[1].geometry

# Grabbing state buses
study_buses = get_state_bus_numbers(sys, state_geometry)

# Build state extracted from WECC.jl
region_sys = build_region!(sys, study_buses)    


to_json(region_sys, "co_regional_wecc_sys.json")





region_sys = System(100)

region_sys = build_extracted_region(sys, study_buses) 


for row in eachrow(study_buses)
    area = get_area(get_bus(sys, row[1]))
    if isnothing(area)
        println(area)
    end
end