import os
import sys
import asyncio
import pandas as pd
import h5py 
import numpy as np
import matplotlib.pyplot as plt


# Set working directory to the parent of `r2x_ssc`
os.chdir('C:\\Users\\acasavan\\NREL REPOS\\r2x-ssc\\src')
from r2x_ssc.data_fetching import fetch_hsds_or_cache

df = pd.read_csv("C:\\Users\\acasavan\\RESOLVE\\wind_coords.csv")

points = []
names = []
for index, row in df.iterrows():
        lon = row['lon']
        lat = row['lat']
        name = row['plant']
        point = (lat, lon)
        points.append(point)
        names.append(name)


wind_params = {
    "data_type": "wind",
    "year": 2019,
    "hub_height": 80,
    "wind_turbine_name": "IEA_Reference_3.4MW_130",
    "en_icing_cutoff": False,
    "icing_cutoff_temp": 1000,
    "icing_cutoff_rh": 0,
    "icing_persistence_timesteps": 1,
    "en_low_temp_cutoff": False,
    "low_temp_cutoff": 0,
    "time_ranges": [],
    } 

wind_filepaths = asyncio.run(fetch_hsds_or_cache(wind_params,points,cache_enabled=True))


from r2x_ssc.simulation import run_parallel_sims


wind_results = run_parallel_sims(wind_filepaths, wind_params,names)


output_path = r"C:\\Users\\acasavan\\RESOLVE\\\wind_results.h5"
with h5py.File(output_path, "w") as f:
    for name, info in wind_results.items():
        safe_name = name.replace("/", "_").replace(" ", "_")

        grp = f.create_group(safe_name)
        grp.attrs["name"] = name
        grp.attrs["system_capacity"] = info["system_capacity"]
        grp.attrs["capacity_factor"] = info["capacity_factor"]
        grp.create_dataset("sienna_timeseries", data=info["sienna_timeseries"])


