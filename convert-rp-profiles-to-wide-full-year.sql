-- This is a DuckDB script to join profiles over representative periods into a
-- single profile for the whole year.
--
-- It assumes three files are available in the current folder:
-- - profiles-rep-periods.csv
-- - rep-periods-mapping.csv
-- - rep-periods-data.csv
--
-- To use it, run:
--
--    duckdb -f PATH/TO/THIS/FILE
--
-- A new CSV file `profiles.csv` will be created.
--
-- It extends the full year by using rep_periods_mapping and rep_periods_data
-- to figure out the indices of the profile in the year, aggregating the
-- weighted profile values over representative periods.
--
-- It uses sum(value * weight) where
-- - value is from profiles_rep_periods
-- - weight is from rep_periods_mapping
--
-- At the moment, other columns (year, scenario, etc.) are ignored.

create or replace table profiles_rep_periods as
from read_csv('profiles-rep-periods.csv');

create or replace table rep_periods_mapping as
from read_csv('rep-periods-mapping.csv');

create or replace table rep_periods_data as
from read_csv('rep-periods-data.csv');

create or replace table profiles as
with cte_period_with_starting_timestep as ( -- compute the starting timestep as cumulative sum
  select
    period,
    sum(num_timesteps) over (order by period) - num_timesteps as starting_timestep,
    rpmap.rep_period,
    rpmap.weight,
  from rep_periods_mapping as rpmap
  left join rep_periods_data as rpdata
    on rpmap.rep_period = rpdata.rep_period
), cte_joined_profiles as ( -- compute the actual period from 1:8760
  select
    profile_name,
    starting_timestep + timestep as period,
    weight,
    value,
  from cte_period_with_starting_timestep as cte_periods
  left join profiles_rep_periods as prof
    on prof.rep_period = cte_periods.rep_period
), cte_profiles as ( -- group the profiles in case there are multiple profiles per period
  select
    profile_name,
    period,
    sum(weight * value) as value,
  from cte_joined_profiles
  group by profile_name, period
), cte_wide_profiles as ( -- pivot to make it wide
  pivot cte_profiles
  on profile_name
  using sum(value)
  order by period
)
from cte_wide_profiles;

copy profiles to 'profiles.csv';
