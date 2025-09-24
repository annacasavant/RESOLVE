function get_state_bus_numbers(sys, state_geometry)
    bus_numbers = [] 
    for b in get_components(ACBus, sys)
        lon_lat = get_lon_lat(b)
        if lon_lat !== nothing 
            if ins_state_polygon(state_geometry, lon_lat)
                push!(bus_numbers, get_number(b))
            end 
        end 
    end 
    return bus_numbers
end 

# function in_state_polygon(state_geometry::GeoJSON.MultiPolygon, lon_lat)    
#     for geometry in state_geometry
#         if inpolygon(lon_lat, geometry[1]) == 1 
#             return true 
#         end 
#     end 
#     return false  
# end 

function ins_state_polygon(state_geometry::GeoJSON.Polygon, lon_lat)
    geometry = state_geometry[1]
    if inpolygon(lon_lat, geometry) == 1 
            return true 
    end 
    return false 
end 


function get_lon_lat(b::ACBus)
    ext = get_ext(b)
    lat = ext["latitude"]
    lon = ext["longitude"]
    return (lon, lat)    
end

function determine_lon_lat(b::ACBus)
    # Note: for PSY5, GeoJSON entry becomes a field in ACBus
    geo_info_attribute = get_supplemental_attributes(GeographicInfo, b)
    if !isempty(geo_info_attribute)
        lon = geo_info_attribute[1].geo_json["Longitude"]
        lat = geo_info_attribute[1].geo_json["Latitude"]
        return (lon, lat)
    else
        return nothing 
    end 
end 

function build_region!(sys, bus_numbers)
    bus_numbers = Set(bus_numbers)
    region_services = Set(Vector{Service}())
    area_mapping = get_aggregation_topology_mapping(Area, sys)
    loadzone_mapping =  get_aggregation_topology_mapping(LoadZone, sys)
    service_mapping = get_contributing_device_mapping(sys)

    # TOPOLOGIES: 
    region_aggregation_topologies = Vector{AggregationTopology}()
    for x in get_components(AggregationTopology, sys)
        bus_numbers_in_topology = [get_number(x) for x in get_buses(sys, x)]
        if any(x -> x in bus_numbers, bus_numbers_in_topology)
            push!(region_aggregation_topologies, x)
        end 
    end 
    region_buses = Vector{ACBus}()
    for x in get_components(ACBus, sys)
        if get_number(x) ∈ bus_numbers
            push!(region_buses, x)
        end 
    end 
    region_arcs = Vector{Arc}()
    for x in get_components(Arc, sys)
        if get_number(get_from(x)) ∈ bus_numbers && get_number(get_to(x)) ∈ bus_numbers
            push!(region_arcs, x)
        end 
    end 
    # DEVICES:
    region_static_injection = Vector{StaticInjection}() 
    for x in get_components(StaticInjection, sys)
        if get_number(get_bus(x)) ∈ bus_numbers
            push!(region_static_injection, x)
            for s in get_services(x)
                push!(region_services, s)
            end 
        end 
    end 
    region_ac_branches = Vector{ACBranch}()     #NOTE -- in psy5, Transformer3W will need separate handling
    for x in get_components(ACBranch, sys)
        if get_number(get_from(get_arc(x))) ∈ bus_numbers && get_number(get_to(get_arc(x))) ∈ bus_numbers
            push!(region_ac_branches, x)
            for s in get_services(x)
                push!(region_services, s)
            end 
        end 
    end 
    region_area_interchanges = Vector{AreaInterchange}()
    for x in get_components(AreaInterchange, sys)
        if get_from_area(x) ∈ region_aggregation_topologies && get_to_area(x) ∈ region_aggregation_topologies
            push!(region_area_interchanges, x)  #TODO - does it make sense to include an AreaInterchange if the areas are only partially included?
            # NOTE -- AreaInterchange cannot have Services
        end 
    end 

    region_sys = System(100.0)

    for x in region_aggregation_topologies
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_buses
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_arcs
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_static_injection
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_ac_branches
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_area_interchanges
        _move_component_with_timeseries!(sys, region_sys, x)
    end 
    for x in region_services
        _move_component_with_timeseries!(sys, region_sys, x)
    end 

    #Remap buses to loadzones:
    for loadzone in get_components(LoadZone, region_sys)
        bus_nums = [get_number(x) for x in loadzone_mapping[get_name(loadzone)]]
        loadzone_buses = collect(get_components(x-> (get_number(x) ∈ bus_nums), Bus, region_sys))
        map(z-> set_load_zone!(z, loadzone), loadzone_buses)
    end

    #Remap buses to areas
    for area in get_components(Area, region_sys)
        bus_nums = [get_number(x) for x in area_mapping[get_name(area)]]
        area_buses = collect(get_components(x-> (get_number(x) ∈ bus_nums), Bus, region_sys))
        map(z-> set_area!(z, area), area_buses)
    end

    #Remap devices to services:
    for service in get_components(Service, region_sys)
        contributing_devices = service_mapping[(type = typeof(service), name = get_name(service))].contributing_devices
        contributing_devices_region_sys = []
        for d in contributing_devices
            corresponding_device = get_component(typeof(d), region_sys, get_name(d))
            if corresponding_device !== nothing 
                push!(contributing_devices_region_sys, corresponding_device)
            end 
        end 
        map(z-> add_service!(z, service, region_sys), contributing_devices_region_sys)
    end 
    return region_sys
end 

#moves component from sys1 to sys2 and assigns the timeseries
function _move_component_with_timeseries!(sys1, sys2, comp)
    if has_time_series(comp) && !has_supplemental_attributes(comp)
        ts_datas = [] 
        for metadata in InfrastructureSystems.get_time_series_metadata(comp)
            ts_type = InfrastructureSystems.time_series_metadata_to_data(metadata)
            if ts_type <: StaticTimeSeries
                push!(ts_datas, deepcopy(get_time_series(ts_type, comp, get_name(metadata))))
            end 
        end 
        remove_component!(sys1, comp)
        add_component!(sys2, comp)
        for ts_data in ts_datas
            add_time_series!(sys2, comp, ts_data)
        end 
    elseif !has_time_series(comp) && has_supplemental_attributes(comp)
        attributes = get_supplemental_attributes(comp)
        remove_component!(sys1, comp)
        add_component!(sys2, comp)
        for attribute in attributes
            add_supplemental_attribute!(sys2, comp, attribute)
        end 
    elseif has_time_series(comp) && has_supplemental_attributes(comp)
        attributes = get_supplemental_attributes(comp)
        ts_datas = [] 
        for metadata in InfrastructureSystems.get_time_series_metadata(comp)
            ts_type = InfrastructureSystems.time_series_metadata_to_data(metadata)
            if ts_type <: StaticTimeSeries
                push!(ts_datas, deepcopy(get_time_series(ts_type, comp, get_name(metadata))))
            end 
        end 
        remove_component!(sys1, comp)
        add_component!(sys2, comp)
        for attribute in attributes
            add_supplemental_attribute!(sys2, comp, attribute)
        end 
        for ts_data in ts_datas
            add_time_series!(sys2, comp, ts_data)
        end 
    elseif !has_time_series(comp) && !has_supplemental_attributes(comp)
        remove_component!(sys1, comp)
        add_component!(sys2, comp)
    else 
        @error "invalid combination of supplemental attributes and timeseries" 
    end 
end 




function export_fleet_as_csv(sys, file)
    set_units_base_system!(sys, "NATURAL_UNITS")
    gen_df = DataFrame(GenName=String[], Type=String[], Rating=Float64[], BusName=String[], BusNumber=Int[], Area=String[], Available = Bool[], Lat=Float64[], Lon= Float64[]) 
    for g in get_components(Generator, sys)
        lon, lat = get_lon_lat(get_bus(g))
        push!(gen_df, (GenName= get_name(g), Type=string(typeof(g)), Rating= get_rating(g), BusName=get_name(get_bus(g)), BusNumber=get_number(get_bus(g)), Area=get_name(get_area(get_bus(g))), Available= get_available(g), Lat=lat, Lon =lon))
    end 
    sort!(gen_df,[:Type, :Area, :Rating], rev = true)
    CSV.write(file, gen_df)
    return 
end 


region_sys = System(100.0)

function build_extracted_region(sys, study_buses)
    bus_numbers = Set(unique(study_buses))
    # region_services = Set(Vector{Service}())

    for x in bus_numbers
        bus =  get_bus(sys, x)
        remove_component!(sys, bus)
        add_component!(region_sys, bus)
        powerload = get_components(r-> get_bus(r) == x, PowerLoad, sys)
        if !isnothing(powerload)
            remove_component!(sys, powerload)
            add_component!(region_sys, powerload)
        end
        vre = get_components(r -> get_bus(r) == x, RenewableDispatch, sys)
        if !isnothing(vre)
            remove_component!(sys, vre)
            add_components!(region_sys, vre)
        end
        thermal_std = get_components(r -> get_bus(r) == x, ThermalStandard, sys)
        if !isnothing(thermal_std)
            remove_component!(sys, thermal_std)
            add_components!(region_sys, thermal_std)
        end
        thermal_mts = get_components(r -> get_bus(r) ==x, ThermalMultiStart, sys)
        if !isnothing(thermal_mts)
            remove_component!(sys, thermal_mts)
            add_components!(region_sys, thermal_mts)
        end
        hydro = get_components(r -> get_bus(r) == x, HydroDispatch, sys)
        if !isnothing(hydro)
            remove_component!(sys, hydro)
            add_components!(region_sys, hydro)
    end
    return region_sys
end
end


function convert_to_multipolygon(poly::GeoJSON.Polygon{2, Float32})
    # Wrap the polygon’s coordinates in an extra array to make it a multipolygon
    coords = [poly.coordinates]  # adds an extra layer of nesting
    return GeoJSON.MultiPolygon(coords)
end