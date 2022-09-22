---
title: Flattening Google Analytics 4 data
author: Collin K. Berke, Ph.D.
date: '2022-09-20'
slug: flattening-google-analytics-4-data
categories:
  - BigQuery
tags:
  - Tutorial
  - Data Wrangling
  - SQL
subtitle: ''
summary: ''
authors: []
lastmod: '2022-09-20T00:18:09-05:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

### Introduction

With the introduction of the Google Analytics 4 (GA4) BigQuery integration, understanding how to work with the underlying analytics data has become increasingly important. When first diving into this data, some of the data types may seem hard to work with. Specifically, analysts might be unfamiliar with the array and struct data types. Even more unfamiliar may be the combination of these two data types into complex, nested data structures. As such, some may become frustrated writing queries against this data. I know I did. 

If you're mainly coming from working with flat data files, these more complex data types may not be intuitive to work with, as the SQL syntax is not as straight forward as a simple `SELECT` `FROM` statement. Much of this unfamiliarity may come from the required use of unfamiliar BigQuery functions and operators, many of which are used to transform data from a nested structure to a flattened, denormalized form. 

As such, this post aims to do three things:
1. Overview the array, struct, and array of struct data types in BigQuery;
2. Overview some of the approaches to flatten these data types; and 
3. Apply this knowledge in the denormalization of Google Analytics 4 data stored in BigQuery. 

This post mostly serves as notes that I wish I had when I began working with these data structures.

### Arrays, structs, and array of structs 

Before discussing the use of these data types in GA4 data, let's take a step back and simply define what array and struct data types are in BigQuery. A good starting point is BigQuery's [arrays](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_type) and [structs](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#struct_type) documentation. According to the docs,

> An array is an ordered list of zero or more elements of non-Array values. Elements in an array must share the same type.

> A struct is a container of ordered fields each with a type (required) and field name (optional). 

Both definitions contain technical jargon that don't really define, in an intuitive, useful way, what these data types are and how to use them, especially in the analysis of GA4 data. So let's break each down by bringing in additional perspectives and through the use of several simplified examples.  

While learning more about arrays and structs, I found several blog posts that helped me better understand these structures and how to use them. Here is a list of the ones I found to be very helpful:

* [How to work with Arrays and Structs in Google BigQuery](https://medium.com/google-cloud/how-to-work-with-array-and-structs-in-bigquery-9c0a2ea584a6) by Deepti Garg
* [Explore Arrays and Structs for Better Query Performance in Google BigQuery](https://towardsdatascience.com/explore-arrays-and-structs-for-better-performance-in-google-bigquery-8978fb00a5bc) by Skye Tran
* [Tutorial: BigQuery arrays and structs](https://shotlefttodatascience.com/2019/12/27/tutorial-bigquery-arrays-and-structs/) from Sho't left to data science 

I highly suggest reading all of these. In fact, much of what follows is adapted from these posts, with a few examples I created to help me better understand how these data types are structured, stored, and queried. Towards the end of the post, the techniques learned from these posts and overviewed here will be applied to GA4 data, specifically the publicly available [`bigquery-public-data.ga4_obfuscated_sample_ecommerce`](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset) data. 

### Arrays 

Arrays are a collection of elements of the same datatype. If you're familiar with the R programming language, an array is similair to a vector. 

Let's create a table containing an array of planets in our solar system as an example, and then use the `INFORMATION_SCHEMA` view to verify the data was entered correctly. The following code will create this table in BigQuery:

```sql 
create or replace table examples.array_planets_example as 
with a as (
   select ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"] as planets
)
select planets from a;
```

The `INFORMATION_SCHEMA.COLUMNS` view for the `array_planets_example` table can be queried to verify the data was entered correctly. This table is available for every table created in BigQuery, and it contains metadata about the table and the fields within. Here is the query needed to return this information:
    
```sql
select table_name,
   column_name,
   is_nullable,
   data_type
from examples.INFRORMATION_SCHEMA.COLUMNS
where table_name = "array_planets_example";
```

The returned table will contain a `data_type` field, where the value `ARRAY<STRING>` will be present. This value represents the field in the `array_planets_example` contains an array with a list of string values. Although this example array contains a series of string values, arrays can hold various other data types, as long as the values are the same type across the collection. Overviewing all of the different data types that can be stored in an array is beyond the scope of this post, but check out the [BigQuery docs](https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays) for more examples.  

#### Querying an array

Multiple approaches are available to query an array. The type of approach will depend on if the returned data needs to maintain its grouped, nested structure, or if the returned data needs to be flattened. If maintaining the nested structure is required, then a simple `SELECT` statement will work. Using the `array_planets_example` table as an example, the query applying this approach will look something like this:

```sql
select planets
from examples.array_planets_example
```

If each element of the array is to be outputted onto its own row (i.e., denormalized), multiple approaches are available. The first approach is to use the `unnest()` function. Here is an example using the planets array we created earlier:

```sql
select planets
from examples.array_planets_example,
unnest(planets) as planets
```

The second approach is to apply a correlated join through the use of `cross join unnest()`. This approach looks like this:

```sql
select planets
from examples.array_planets_example
cross join unnest(planets) as planets
```

You'll notice this is only slightly different than the query above, and in fact the `,` used in the `FROM` clause is short-hand for the `cross join` statement. The last and final approach is to use a comma-join. This is similair to our first query, but now we refer to the table name before the array name we want flattened. 

```sql
select planets
from examples.array_planets_example, array_planets_example.planets as planets;
```

Which one do you choose? It really comes down to a matter of preference. All three approaches will lead to the same result. It depends on how explicit you want the code to be.

There is one note to be aware of if you're applying these conventions to other arrays outside of analyzing GA4 data. The cross join approach will exclude `NULL` arrays. So if you want to retain rows containing `NULL` arrays, you'll need to apply a left join. More about this is described in the BigQuery [docs](https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays#querying_array-type_fields_in_a_struct).

Keep these approaches top-of-mind. They will be applied to flatten some of the fields in the GA4 dataset. In other words, get comfortable with using them.

### Structs 

The structs data type holds attributes in key-value pairs. Structs can hold many different data types, even structs. We will see the use of structs within structs in the GA4 data. Keeping with the solar system theme of the post, the following example code will create a table utilizing the struct data type to hold the dimensions and distances of the planets in our solar system. The data used for this table is reported [here](https://www.jpl.nasa.gov/edu/pdfs/scaless_reference.pdf).

```sql
create or replace table examples.struct_solar_system as
with a as (
  select "Mercury" as planet,
  struct(0.39 as au_sun, 57900000 as km_sun, 4879 as km_diameter) as dims_distance union all
  select "Venus" as planet,
  struct(0.72 as au_sun, 108200000 as km_sun, 12104 as km_diameter) as dims_distance union all
  select "Earth" as planet,
  struct(1 as au_sun, 149600000 as km_sun, 12756 as km_diameter) as dims_distance union all
  select "Mars" as planet,
  struct(1.52 as au_sun, 227900000 as km_sun, 6792 as km_diameter) as dims_distance union all
  select "Jupiter" as planet,
  struct(5.2 as au_sun, 778600000 as km_sun, 142984 as km_diameter) as dims_distance union all
  select "Saturn" as planet,
  struct(9.54 as au_sun, 1433500000 as km_sun, 120536 as km_diameter) as dims_distance union all
  select "Uranus" as planet,
  struct(19.2 as au_sun, 2872500000 as km_sun, 51118 as km_diameter) as dims_distance union all
  select "Neptune" as planet,
  struct(30.06 as au_sun, 4495100000 as km_sun, 49528 as km_diameter) as dims_distance 
)
select * from a;
```

This table contains two columns. A column that holds a string value for the name of the planet and a struct column that contains a list of key value pairs of distance and dimensions for each planet. 

The `INFRORMATION_SCHEMA.COLUMNS` table can then be queried again to verify the datatypes for each column were inputted correctly. Here is the code to do this:

```sql
select 
  table_name, 
  column_name,
  is_nullable,
  data_type
from examples.INFORMATION_SCHEMA.COLUMNS
where table_name = "struct_solar_system";
```

The returned table will contain a `data_type` column with two values: `STRING` and `STRUCT<au_sun FLOAT64, km_sun INT64, km_diameter INT64>`. Take notice that the `STRUCT` value contains information about the data types contained within. 

#### Querying a struct

Querying a struct requires the use of the `.` operator (i.e., dot operator) in the `FROM` clause to flatten the table. Take for example the case where we want to return a table of only the distance of each planet from the sun in kilometers. The following query will be used:

```sql
select 
  planet,
  dims_distance.km_sun
from examples.struct_solar_system;
```

Say a denormalized table that contains both the distance from the sun in kilometers and each planet's diameter in kilometers is wanted. The following query would be used:

```sql
select 
  planet,
  dims_distance.km_sun,
  dims_distance.km_diameter
from examples.struct_solar_system;
```

When reviewing these two examples, observe how the dot notation is being used. In the first, our select statement contains `dims_distance.km_sun`, which unnests the values and gives each its own row for each planet. This is expanded in the second query, where an additional line is added to the select statement, `dims_distance.km_diameter`. To unnest all the values in the struct, use the following query:

```sql
select 
  planet,
  dims_distance.au_sun,
  dims_distance.km_sun,
  dims_distance.km_diameter,
from examples.struct_solar_system;
```

In fact, let's expand this query to answer the following question: which planets are the closest and farthest from our sun. Take notice how the `ORDER BY` portion of the query doesn't require the `dims_distance` prefix for the field we want to arrange our data. 

```sql
select 
  planet,
  dims_distance.au_sun,
  dims_distance.km_sun,
  dims_distance.km_diameter,
from examples.struct_solar_system
order by km_sun;
```

### Array and structs in GA4 data 

Now that we have learned a little bit about our solar system, let's return to Earth and the task at hand, flattening GA4 data. We just discussed how these data types are created and queried, it is now time to combine them into more complex data structures, as both of these structures are combined to create nested data structures in the GA4 data. It's best to start with an example. Specifically, let's look at how these structures are applied in the `event_params` field.

We can start off by querying the `INFORMATION_SCHEMA.COLUMNS` view for one event to get an idea of its structure. The query to do this can be seen here:

```sql
select 
  table_name,
  column_name,
  is_nullable,
  data_type
from bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS
where table_name = "events_20210131" and column_name = "event_params";
```

The data type is described in the returned table's `data_type` field. This field contains the following value `ARRAY<STRUCT<key STRING, value STRUCT<string_value STRING, int_value INT64, float_value FLOAT64, double_value FLOAT64>>>`. It should be immediately apparent that both the array and struct values are being used here to create a nested structure. In fact, the `event_params` value uses a struct within a struct. Given this structure, all the above methods will need to be employed to flatten this data.

To simplify this, let's look at one instance of one event in the GA4 data. Specifically, let's look at one instance of a `page_view` event. With this simplified example, we'll go step-by-step, adding additional elements to the query needed to flatten this nested data.

```sql
select 
  event_date,
  event_timestamp,
  event_name,
  event_params
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
where event_name = 'page_view'
limit 1;
```

After running this query, you'll notice the output to the console is quite verbose, especially if you're using the [`bq` command-line tool](https://cloud.google.com/bigquery/docs/bq-command-line-tool). The verbosity of the output is due to the nested structure of the `event_params` field holding much of the data.

The first layer of the structure is an array, so the initial step is to use the `unnest()` function. The following can be done to achieve this:

```sql
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
```

You'll notice a nested `FROM` statement is being used here. This is done to limit the result set to one row, representing one `page_view` event for this simplified example. Later iterations of the query will eliminate this nested query.

Now say we're only interested in viewing the `page_location` parameter. We can use a where statement to filter out this information. Here is what this will look like:

```sql
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
```

Interested in viewing both the `page_location` and `page_title` parameters? Use the `IN` operator in the `WHERE` clause.

```sql
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
```

Wanna turn the key field into columns so you only have one row for this specific event? Use BigQuery's [`pivot()` operation](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#pivot_operator). Here is how to achieve this in a query:

```sql
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
pivot(max(string_value) for key in ('page_location', 'page_title'))
```

Since the string values are all we care about here, the `value.string_value` was the only one retained in the query. The other nested value elements were eliminated from the `SELECT` statement.

### Combine other nested fields in the GA4 data

Now that the `event_params` field has been flattened, let's supplement this information with additional data in the table. Moreover, this will provide another example of how to apply these steps to flatten other elements in the GA4 data. Knowing where users originate is some additional context that may add to our event analysis, so let's add that data to our flattened data. But first, let's get some more information on what data type is used for the `geo` field in the GA4 data.

Once again, querying the `INFORMATION_SCHEMA.COLUMNS` view can be used to explore the `geo` field's data type. Here is what the query looks like:

```sql
select 
  table_name,
  column_name,
  is_nullable,
  data_type
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS`
where table_name = "events_20210131" and column_name = "geo";
```

The value `STRUCT<continent STRING, sub_continent STRING, country STRING, region STRING, city STRING, metro STRING>` is returned. Let's write a query to return the table without first unnesting the data. 

```sql
select
  event_date,
  event_name,
  user_pseudo_id,
  geo 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
where event_name = "page_view"
limit 1;
```

You'll notice this field contains a struct, where the dot operator will need to be applied to flatten this data. Let's start by flattening this data and then combine it with the `events_param` data. For the sake of keeping the returned table simple, let's just return the `region` and `city` fields in a denormalized form. The following will return a flattened table with these fields:

```sql
select
  event_date,
  event_name,
  user_pseudo_id,
  geo.region,
  geo.city
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
limit 1;
```

As expected, the table will return a flattened table containing five fields: `event_date`, `event_name`, `user_pseudo_id`, `geo.region`, and `geo.city`. This table was also limited to return only the first instance of the `page_view` in the table.

Now, the next step is to add this geo data to our flattened `event_params` query. This is as simple as adding the `.` operator with the needed `geo` elements into the `FROM` statement. The query will now look like this:

```sql
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
pivot(max(string_value) for key in ('page_location', 'page_title'))
```

The resulting table will contain one row with several fields representing the specific event. This is great for one event, but the next step will be to expand this denormalization to all `page_view` events in the table. 

### Expand the unnesting to multiple page view events

Now that we have the flattened table for one `page_view` event, let's expand it to additional events. This requires a simple modification to the initial nested query, remove the `limit 1` line. 

```sql
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
  ), unnest(event_params) as event_param
  where key in ('page_location', 'page_title')
)
pivot(max(string_value) for key in ('page_location', 'page_title'));
```

We can now refactor the query to be more concise. Here is what this will look like:

```sql
select * 
from (
  select 
    event_date,
    event_name,
    user_pseudo_id,
    event_params.key,
    event_params.value.string_value,
    geo.region,
    geo.city
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`,
  unnest(event_params) as event_params
  where event_name = 'page_view' and key in ('page_location', 'page_title')
)
pivot(max(string_value) for key in ('page_location', 'page_title'));
```

### Apply these approaches across multiple days

Generating results for one day may not be enough, so there's a few modifications that can be made to expand the final query to return additional days. This involves modifying the `FROM` and `WHERE` statements in the initial query.

The first step is to modify the `FROM` statement to use the `*` wildcard operator at the end of the table name. Since the GA4 tables are partitioned by day, this will allow for a range of tables to be defined within the `WHERE` clause. The table name will now be `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`. 

To define the range of dates for the events (i.e., to query multiple tables), the `WHERE` clause will be expanded to include the use of `_table_suffix`. The `_table_suffix` is a special column used within a separate wildcard table that is used to match the range of values. Explaining the use of the wildcard table is beyond the scope of this post, but more about how this works can be found [here](https://cloud.google.com/bigquery/docs/querying-wildcard-tables). The `WHERE` clause will now look like this:

```sql
where event_name = 'page_view' and
key in ('page_location', 'page_title') and
_table_suffix between "20210126" and "20210131"
```

You'll notice this statement uses the `between` operator, where two string values representing the date range are passed. This statement is inclusive, so it will include partitioned tables from `20210126` and `20210131`, and all tables in between. Here is the query in its final form:

```sql
select * 
from (
  select 
    event_date,
    event_name,
    user_pseudo_id,
    event_params.key,
    event_params.value.string_value,
    geo.region,
    geo.city
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  unnest(event_params) as event_params
  where event_name = 'page_view' and 
  key in ('page_location', 'page_title') and
  _table_suffix between "20210126" and "20210131"
)
pivot(max(string_value) for key in ('page_location', 'page_title'))
order by event_date
```

### Wrap up

This post started out simple by defining what arrays, structs, and array of structs data types are in BigQuery. Through the use of several examples, this post overviewed several approaches to query these different data types, specifically highlighting how to flatten each type. A second aim of this post was to show the application of these methods to the flattening of GA4 data stored in BigQuery. This included the flattening and combination of the complex, nested `event_params` and `geo` fields. Finally, this post shared queries that expanded the result set across multiple days worth of data.

If you found this post helpful or just have interest in this type of content, I would appreciate the follow on [GitHub](https://github.com/collinberke) and/or [Twitter](https://twitter.com/BerkeCollin). If you have suggestions on how to improve these queries or found something that I missed, please file an issue in the repo found [here](https://github.com/collinberke/berkeBlog). 

### Additional resources

I spent a lot of time researching how to write, use, and query arrays and structs in BigQuery. In the process of preparing this post, I wrote a lot of example queries and followed along with BigQuery's [turtorial on working with arrays and structs](https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays). As a result, I created multiple files that I organized into the GitHub repo for this post. These might be useful as a review after reading this post, or they might be a helpful quickstart quide for your own analysis of GA4 data stored in BigQuery. These additional notes can be found [here](https://github.com/collinberke/berkeBlog/tree/master/content/post/2022-09-20-flattening-google-analytics-4-data). 

### Additional references

* [How to work with Arrays and Structs in Google BigQuery](https://medium.com/google-cloud/how-to-work-with-array-and-structs-in-bigquery-9c0a2ea584a6)
* [Explore Arrays and Structs for Better Query Performance in Google BigQuery](https://towardsdatascience.com/explore-arrays-and-structs-for-better-performance-in-google-bigquery-8978fb00a5bc)
* [Tutorial: BigQuery arrays and structs](https://shotlefttodatascience.com/2019/12/27/tutorial-bigquery-arrays-and-structs/)
