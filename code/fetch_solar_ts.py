import os
import sys
import asyncio
import pandas as pd
import h5py 
import numpy as np

os.chdir('C:\\Users\\acasavan\\TA_experiments\\src\\r2x-ssc\\src')
from r2x_ssc.data_fetching import fetch_hsds_or_cache

df = pd.read_csv("C:\\Users\\acasavan\\RESOLVE\\solar_coords.csv")

points = []
names = []
for index, row in df.iterrows():
        lon = row['lon']
        lat = row['lat']
        name = row['plant']
        point = (lat, lon)
        points.append(point)
        names.append(name)

solar_params = {
    "data_type": "solar",
    "year": 2019,
    "time_ranges": []#[("2023-01-01", "2023-01-08")],
}

solar_filepaths = asyncio.run(fetch_hsds_or_cache(solar_params,points,cache_enabled=True))


from r2x_ssc.simulation import run_parallel_sims


solar_results =  run_parallel_sims(solar_filepaths, solar_params,names)
output_path = r"C:\\Users\\acasavan\\RESOLVE\\solar_results.h5"

with h5py.File(output_path, "w") as f:
    for name, info in solar_results.items():
        safe_name = name.replace("/", "_").replace(" ", "_")

        grp = f.create_group(safe_name)
        grp.attrs["name"] = name
        grp.attrs["system_capacity"] = info["system_capacity"]
        grp.attrs["capacity_factor"] = info["capacity_factor"]
        grp.create_dataset("sienna_timeseries", data=info["sienna_timeseries"])

