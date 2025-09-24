import os
import sys
import asyncio
import pandas as pd
import h5py 
import numpy as np

os.chdir('C:\\Users\\acasavan\\NREL REPOS\\r2x-ssc\\src')
from r2x_ssc.data_fetching import fetch_hsds_or_cache


points = [(39.0, -105.55)]
names = ["Solar_BTM_Existing"]

solar_params = {
    "data_type": "solar",
    "year": 2019,
    "time_ranges": []#[("2023-01-01", "2023-01-08")],
}

solar_filepaths = asyncio.run(fetch_hsds_or_cache(solar_params,points,cache_enabled=True))


from r2x_ssc.simulation import run_parallel_sims


solar_results =  run_parallel_sims(solar_filepaths, solar_params,names)
output_path = r"C:\\Users\\acasavan\\RESOLVE\\der_results.CSV"
name = "Solar_BTM_Existing"
timeseries = solar_results[name]['sienna_timeseries']

# Create a DataFrame
df = pd.DataFrame({name: timeseries})

# Save to CSV
df.to_csv(output_path, index=False)