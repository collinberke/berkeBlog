/* Examples from the Work with arrays BigQuery tutorial: 
https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays */

/* Building arrays */ 
select [1, 2, 3] as numbers;

select ["apple", "pear", "orange"] as fruit;

select [true, false, true] as booleans;

-- Arrays can be created from compatible types
select [a, b, c] as like_types
from 
  (select 5 as a,
          37 as b,
          406 as c);

select [a, b, c]
from
  (select cast(5 as int64) as a,
          cast(37 as float64) as b,
          406 as c); 

-- Explicitly set the array type 
select array<float64>[1, 2, 3] as floats;

select array<string>[] as empty_string;

-- Use  a function to create an array
select generate_array(11, 33, 2) as odds;

-- Use function to create an array, descending values
select generate_array(21, 14, -1) as countdown;

-- Generating arrays of dates
select 
  generate_date_array('2017-11-21', '2017-12-31', interval 1 week)
    as date_array;

select 
  generate_date_array('2017-11-21', '2021-12-31', interval 1 year)
    as date_array;

/* Accessing array elements */ 
-- offest is 0 indexed
-- ordinal is 1 based indexed
with sequences as 
  (select [0, 1, 1, 2, 3, 5] as some_numbers
   union all select [2, 4, 8, 16, 32] as some_numbers
   union all select [5, 10] as some_numbers)
select some_numbers,
       some_numbers[offset(1)] as offset_1,
       some_numbers[ordinal(1)] as ordinal_1
from sequences;

/* Calculating array lengths */ 

with sequences as
  (select [0, 1, 1, 2, 3, 5] as some_numbers 
   union all select [2, 4, 8, 16, 32] as some_numbers 
   union all select [5, 10] as some_numbers)

select some_numbers,
  array_length(some_numbers) as len 
from sequences;

/* Converting elements in an array to rows in a table */ 

-- You need to use the `unnest()` function
select * 
from unnest(['foo', 'bar', 'baz', 'qux', 'corge', 'garply', 'waldo', 'fred'])
  as element 
with offset as offset 
order by offset;

with sequences as (
  select 1 as id, [0, 1, 1, 2, 3, 5] as some_numbers 
  union all select 2 as id, [2, 4, 8, 16, 32] as some_numbers 
  union all select 3 as id, [5, 10] as some_numbers 
)
select * from sequences;

with sequences as (
  select 1 as id, [0, 1, 1, 2, 3, 5] as some_numbers
  union all select 2 as id, [2, 4, 8, 16, 32] as some_numbers
  union all select 3 as id, [5, 10] as some_numbers
)
select id, flattend_numbers 
from sequences, unnest(sequences.some_numbers) as flattend_numbers;

-- Preserving the values of other columns, use cross join
with sequences as 
  (select 1 as id, [0, 1, 1, 2, 3, 5] as some_numbers
   union all select 2 as id, [2, 4, 8, 16, 32] as some_numbers
   union all select 3 as id, [5, 10] as some_numbers)
select id, flattend_numbers
from sequences 
cross join unnest(sequences.some_numbers) as flattend_numbers;

-- Eliminate the use of the cross join using a comma-join
with sequences as 
  (select 1 as id, [0, 1, 1, 2, 3, 5] as some_numbers
   union all select 2 as id, [2, 4, 8, 16, 32] as some_numbers
   union all select 3 as id, [5, 10] as some_numbers)
select id, flattend_numbers
from sequences, sequences.some_numbers as flattend_numbers;

/* Querying nested arrays */

-- Unnesting a table with an array of structs column 
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select
   race,
   participant
from races r
cross join unnest(r.participants) as participant;

-- Unnesting a table with an array of structs column using a comma-join
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select 
  race,
  participant
from races r, unnest(r.participants) as participant;

-- Denormalizing the races table
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select 
  race,
  participant.name,
  laps
from (
  select 
    race,
    participant 
  from races r, r.participants as participant
), unnest(participant.laps) as laps;


-- Determining the fastest racer
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select 
   race,
   (select name 
    from unnest(participants) 
    order by (
      select sum(duration)
      from unnest(laps) as duration) ASC
    limit 1) as fastest_racer
from races;

-- Determining the racer with the fastest lap, naieve way
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select 
   race,
   name,
   laps 
from (
  select  
    race,
    participants.name,
    participants.laps
  from races,
  unnest(participants) as participants
), unnest(laps) as laps
order by laps;

-- Determining the racer with the fastest time, the quick way
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select race,
(select name
 from unnest(participants),
  unnest(laps) as duration
  order by duration asc limit 1) as runner_with_fastest_lap
from races;

-- Using an explicit cross join to identify the racer with the fastest lap
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.5, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps)] as participants
)
select 
race,
(select name
from unnest(participants)
cross join unnest(laps) as duration
order by duration asc limit 1) as runner_with_fastest_lap
from races;

-- Flattening arrays with cross join excludes NULL arrays,
-- use a left join to include nulls
with races as (
  select "800M" as race,
  [struct("Rudisha" as name, [23.4, 26.3, 26.4, 26.1] as laps),
   struct("Makhloufi" as name, [24.5, 25.4, 26.6, 26.1] as laps),
   struct("Murphy" as name, [23.9, 26, 27, 26] as laps),
   struct("Bosse" as name, [23.6, 26.2, 26.5, 27.1] as laps),
   struct("Rotich" as name, [24.7, 25.6, 26.9, 26.4] as laps),
   struct("Lewandowski" as name, [25, 25.7, 26.3, 27.2] as laps),
   struct("Kipketer" as name, [23.2, 26.1, 27.3, 29.4] as laps),
   struct("Berian" as name, [23.7, 26.1, 27, 29.3] as laps),
   struct("Nathan" as name, array<float64>[] as laps),
   struct("David" as name, null as laps)
   ] as participants
)
select
name, sum(duration) as finish_time
from races, races.participants left join participants.laps duration
group by name;

/* Creating arrays from subqueries */

-- using the array() function
with sequences as
 (select [0, 1, 1, 2, 3, 5] as some_numbers
 union all select [2, 4, 8, 16, 32] as some_numbers
 union all select [5, 10] as some_numbers)
 select some_numbers,
  array(select x * 2 
        from unnest(some_numbers) as x) as doubled
 from sequences;

/* Filtering arrays */

with sequences as
 (select [0, 1, 1, 2, 3, 5] as some_numbers
  union all select [2, 4, 8, 16, 32] as some_numbers
  union all select [5, 10] as some_numbers)
select some_numbers,
  array(select x * 2 
        from unnest(some_numbers) as x
        where x < 5) as doubled_less_than_five
from sequences;

-- using select distinct to return unique rows
with sequences as
  (select [0, 1, 1, 2, 3, 5] as some_numbers)
select array(select distinct x
             from unnest(some_numbers) as x) as unique_numbers
from sequences;

-- using the `in` keyword
with sequences as
 (select [0, 1, 1, 2, 3, 5] as some_numbers
 union all select [2, 4, 8, 16, 32] as some_numbers
 union all select [5, 10] as some_numbers)
select 
  array(select x
        from unnest(some_numbers) as x
        where 2 in unnest(some_numbers)) as contains_two
from sequences;

/* Scanning arrays */ 

-- Does an array contain a specific value
select 2 in unnest([0, 1, 1, 2, 3, 5]) as contains_value;

-- Return the rows with the value
with sequences as 
  (select 1 as id, [0, 1, 1, 2, 3, 5] as some_numbers 
   union all select 2 as id, [2, 4, 8, 16, 32] as some_numbers
   union all select 3 as id, [5, 10] as some_numbers)
select id as matching_rows
from sequences
where 2 in unnest(sequences.some_numbers)
order by matching_rows;

/* Arrays and aggregation */

with fruits as 
   (select "apple" as fruit 
    union all select "pear" as fruit
    union all select "banana" as fruit)
select array_agg(fruit) as fruit_basket
from fruits;

-- maintain the array order by using order by
with fruits as
  (select "apple" as fruit
   union all select "pear" as fruit
   union all select "banana" as fruit)
select array_agg(fruit order by fruit) as fruit_basket
from fruits;

-- using aggregate functions when aggregating arrays
with sequences as 
  (select [0, 1, 1, 2, 3, 5] as some_numbers
   union all select [2, 4, 8, 16, 32] as some_numbers
   union all select [5, 10] as some_numbers)
select some_numbers,
  (select sum(x)
   from unnest(s.some_numbers) x) as sums
from sequences s;

-- concatinating array values across rows
with aggregate_example as 
  (select [1, 2] as numbers
   union all select [3, 4] as numbers
   union all select [5, 6] as numbers)
select array_concat_agg(numbers) as count_to_six_agg
from aggregate_example;

-- converting arrays to strings
with greetings as 
  (select ["Hello", "World"] as greeting)
select array_to_string(greeting, " ") as greetings
from greetings;

-- replacing null values in strings
select 
  array_to_string(arr, ".", "N") as non_empty_string,
  array_to_string(arr, ".", "") as empty_string,
  array_to_string(arr, ".") as omitted
from (select ["a", NULL, "b", NULL, "c", NULL] as arr);

/* Combining arrays */

-- use array_concat()
select array_concat([1, 2], [3, 4], [5, 6]) as count_to_six;

/* Zipping arrays */

with combinations as (
  select 
   ['a', 'b'] as letters,
   [1, 2, 3] as numbers
)
select 
  array(
    select as struct 
     letters[safe_offset(index)] as letter,
     numbers[safe_offset(index)] as number 
    from combinations
    cross join
      unnest(
        generate_array(
          0,
          least(array_length(letters), array_length(numbers)) - 1)) as index
      order by index
);

with combinations as (
  select 
   ['a', 'b'] as letters,
   [1, 2, 3] as numbers
)
select 
  array(
    select as struct 
     letters[safe_offset(index)] as letter,
     numbers[safe_offset(index)] as number 
    from combinations
    cross join
      unnest(
        generate_array(
          0,
          greatest(array_length(letters), array_length(numbers)) - 1)) as index
      order by index
);

/* Building arrays of arrays */

with points as
 (select [1, 5] as point 
  union all select [2, 8] as point 
  union all select [3, 7] as point 
  union all select [4, 1] as point 
  union all select [5, 7] as point)
select array(
  select struct(point)
  from points
) as coordinates;
