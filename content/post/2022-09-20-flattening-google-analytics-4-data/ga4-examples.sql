
/* GA4 query examples */ 

select 
  table_name,
  column_name,
  is_nullable,
  data_type
from bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS
where table_name = "events_20210131" and column_name = "event_params";

select 
  event_date,
  event_timestamp,
  event_name,
  event_params
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
where event_name = 'page_view'
limit 1;

select 
   event_date,
   event_timestamp,
   event_name,
   event_params
from(
   select 
    event_date,
    event_timestamp,
    event_name,
    event_params
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_params;

select 
   event_date,
   event_timestamp,
   event_name,
   event_params.key,
   event_params.value
from(
   select 
    event_date,
    event_timestamp,
    event_name,
    event_params
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_params;

/* Flatten the event_params field */

select 
  event_date,
  event_name,
  key,
  value.string_value,
  value.int_value,
  value.double_value, 
  value.float_value
from (
  select 
    event_date,
    event_timestamp,
    event_name,
    event_params
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_param;

-- Only return the page_location information
select 
  event_date,
  event_name,
  key,
  value.string_value,
  value.int_value,
  value.double_value, 
  value.float_value
from (
  select 
    event_date,
    event_timestamp,
    event_name,
    event_params
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_param
where key = 'page_location';

-- Return page_location and page_title
select 
  event_date,
  event_name,
  key,
  value.string_value,
  value.int_value,
  value.double_value, 
  value.float_value
from (
  select 
    event_date,
    event_timestamp,
    event_name,
    event_params
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_param
where key in ('page_location', 'page_title');

-- Use pivot operator to transform to one row  
select *
from(
  select 
    event_date,
    event_name,
    key,
    value.string_value
  from (
    select 
      event_date,
      event_timestamp,
      event_name,
      event_params
    from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
    where event_name = 'page_view'
    limit 1
  ), unnest(event_params) as event_param
  where key in ('page_location', 'page_title')
)
pivot(max(string_value) for key in ('page_location', 'page_title'));

/* Flatten the geo field */

select 
  table_name,
  column_name,
  is_nullable,
  data_type
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS`
where table_name = "events_20210131" and column_name = "geo";

select
  event_date,
  event_name,
  user_pseudo_id,
  geo 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
where event_name = "page_view"
limit 1;

select
  event_date, 
  event_name,
  user_pseudo_id,
  geo.region,
  geo.city
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
where event_name = "page_view"
limit 1;

-- Add the `geo` field to the `event_params` flattened table
select *
from(
  select 
    event_date,
    event_name,
    user_pseudo_id,
    key,
    value.string_value,
    geo.region,
    geo.city
  from (
    select 
      event_date,
      user_pseudo_id,
      event_name,
      event_params,
      geo
    from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
    where event_name = 'page_view'
    limit 1
  ), unnest(event_params) as event_param
  where key in ('page_location', 'page_title')
)
pivot(max(string_value) for key in ('page_location', 'page_title'));

-- Return a flattened table with `page_location` and `page_title`
select 
  event_date,
  event_name,
  user_pseudo_id,
  event_params.key,
  event_params.value.string_value,
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`,
unnest(event_params) as event_params
where event_name = 'page_view' and key in ('page_location', 'page_title');

-- Add `geo` struct elements to the table
select 
  event_date,
  event_name,
  user_pseudo_id,
  event_params.key,
  event_params.value.string_value,
  geo.city,
  geo.region
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`,
unnest(event_params) as event_params
where event_name = 'page_view' and key in ('page_location', 'page_title');

-- Pivot the `string_value` field 
select * 
from (
  select 
    event_date,
    event_name,
    user_pseudo_id,
    event_params.key,
    event_params.value.string_value,
    geo.city,
    geo.region
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`,
  unnest(event_params) as event_params
  where event_name = 'page_view' and key in ('page_location', 'page_title')
)
pivot(max(string_value) for key in ('page_location', 'page_title'));

-- Expand the query to include multiple days
select * 
from (
  select 
    event_date,
    event_name,
    user_pseudo_id,
    event_params.key,
    event_params.value.string_value,
    geo.city,
    geo.region
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  unnest(event_params) as event_params
  where event_name = 'page_view' and 
  key in ('page_location', 'page_title') and
  _table_suffix between "20210126" and "20210131"
)
pivot(max(string_value) for key in ('page_location', 'page_title'))
order by event_date

/* Flatten the user device param */

select 
  event_date,
  user_pseudo_id,
  device.category,
  device.mobile_brand_name,
  device.mobile_model_name
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
limit 1;

/* Flatten the event_params with device attached */ 
select
  event_date,
  event_name,
  event_param.key,
  event_param.value.string_value,
  event_param.value.int_value,
  event_param.value.double_value,
  event_param.value.float_value,
  device.mobile_model_name
from (
  select 
    event_date,
    event_timestamp,
    event_name,
    event_params,
    device
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  where event_name = 'page_view'
  limit 1
), unnest(event_params) as event_param
