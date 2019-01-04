

# `dplyr` Basics




## Create a table variable

*Basics to how to point a variable in R to a table or view inside the database*


1. Load the `dplyr`, `DBI` and `dbplyr` libraries

```r
library(dplyr)
library(dbplyr)
library(DBI)
```

2. *(Optional)* Open a connection to the database if it's currently closed

```r
con <- dbConnect(odbc::odbc(), "Postgres Dev")
```


3. Use the `tbl()` and `in_schema()` functions to create a reference to a table

```r
tbl(con, in_schema("datawarehouse", "airport"))
```

```
## # Source:   table<datawarehouse.airport> [?? x 7]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    airport airportname               city        state country   lat   long
##    <chr>   <chr>                     <chr>       <chr> <chr>   <dbl>  <dbl>
##  1 ABE     Lehigh Valley Internatio… Allentown   PA    USA      40.7  -75.4
##  2 ABI     Abilene Regional          Abilene     TX    USA      32.4  -99.7
##  3 ABQ     Albuquerque International Albuquerque NM    USA      35.0 -107. 
##  4 ABY     Southwest Georgia Region… Albany      GA    USA      31.5  -84.2
##  5 ACK     Nantucket Memorial        Nantucket   MA    USA      41.3  -70.1
##  6 ACT     Waco Regional             Waco        TX    USA      31.6  -97.2
##  7 ACV     Arcata                    Arcata/Eur… CA    USA      41.0 -124. 
##  8 ACY     Atlantic City Internatio… Atlantic C… NJ    USA      39.5  -74.6
##  9 ADK     Adak                      Adak        AK    USA      51.9 -177. 
## 10 ADQ     Kodiak                    Kodiak      AK    USA      57.7 -152. 
## # ... with more rows
```

4. Load the reference, not the table data, into a variable

```r
airports <- tbl(con, in_schema("datawarehouse", "airport"))
```


5. Call the variable to see preview the data in the table

```r
airports
```

```
## # Source:   table<datawarehouse.airport> [?? x 7]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    airport airportname               city        state country   lat   long
##    <chr>   <chr>                     <chr>       <chr> <chr>   <dbl>  <dbl>
##  1 ABE     Lehigh Valley Internatio… Allentown   PA    USA      40.7  -75.4
##  2 ABI     Abilene Regional          Abilene     TX    USA      32.4  -99.7
##  3 ABQ     Albuquerque International Albuquerque NM    USA      35.0 -107. 
##  4 ABY     Southwest Georgia Region… Albany      GA    USA      31.5  -84.2
##  5 ACK     Nantucket Memorial        Nantucket   MA    USA      41.3  -70.1
##  6 ACT     Waco Regional             Waco        TX    USA      31.6  -97.2
##  7 ACV     Arcata                    Arcata/Eur… CA    USA      41.0 -124. 
##  8 ACY     Atlantic City Internatio… Atlantic C… NJ    USA      39.5  -74.6
##  9 ADK     Adak                      Adak        AK    USA      51.9 -177. 
## 10 ADQ     Kodiak                    Kodiak      AK    USA      57.7 -152. 
## # ... with more rows
```

6. Set up the pointers to the other of the tables

```r
flights <- tbl(con, in_schema("datawarehouse", "vflight"))
carriers <- tbl(con, in_schema("datawarehouse", "carrier"))
```

## Under the hood 
* Use `show_query()` to preview the SQL statement that will be sent to the database*

1. SQL statement that actually runs when we ran `airports` as a command

```r
show_query(airports)
```

```
## <SQL>
## SELECT *
## FROM datawarehouse.airport
```

2. Easily view the resulting query by adding `show_query()` in another piped command

```r
airports %>%
  show_query()
```

```
## <SQL>
## SELECT *
## FROM datawarehouse.airport
```

3. Insert `head()` in between the two statements to see how the SQL changes

```r
airports %>%
  head() %>%
  show_query()
```

```
## <SQL>
## SELECT *
## FROM datawarehouse.airport
## LIMIT 6
```

4. Use `sql_render()` and `simulate_mssql()` to see how the SQL statement changes from vendor to vendor

```r
airports %>%
  head() %>%
  sql_render(con = simulate_mssql()) 
```

```
## <SQL> SELECT  TOP 6 *
## FROM datawarehouse.airport
```

## Un-translated R commands
*Review of how `dbplyr` handles R commands that have not been translated into a like-SQL command*

1. Preview how `Sys.time()` is translated

```r
airports %>%
  mutate(today = Sys.time()) %>%
  show_query()
```

```
## <SQL>
## SELECT "airport", "airportname", "city", "state", "country", "lat", "long", SYS.TIME() AS "today"
## FROM datawarehouse.airport
```

2. Use PostgreSQL's native commands, in this case `now()`

```r
airports %>%
  mutate(today = now()) %>%
  show_query()
```

```
## <SQL>
## SELECT "airport", "airportname", "city", "state", "country", "lat", "long", NOW() AS "today"
## FROM datawarehouse.airport
```

3. Run the `dplyr` code to confirm it works

```r
airports %>%
  mutate(today = now()) %>%
  select(today) %>%
  head()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   today              
##   <dttm>             
## 1 2019-01-04 17:09:41
## 2 2019-01-04 17:09:41
## 3 2019-01-04 17:09:41
## 4 2019-01-04 17:09:41
## 5 2019-01-04 17:09:41
## 6 2019-01-04 17:09:41
```

## Using bang-bang
*Intro on passing unevaluated code to a dplyr verb*

1. Preview how `Sys.time()` is translated

```r
airports %>%
  mutate(today = Sys.time()) %>%
  show_query()
```

```
## <SQL>
## SELECT "airport", "airportname", "city", "state", "country", "lat", "long", SYS.TIME() AS "today"
## FROM datawarehouse.airport
```

2. Preview how `Sys.time()` is translated when prefixing `!!`

```r
airports %>%
  mutate(today = !!Sys.time()) %>%
  show_query()
```

```
## <SQL>
## SELECT "airport", "airportname", "city", "state", "country", "lat", "long", '2019-01-04T17:09:41Z' AS "today"
## FROM datawarehouse.airport
```

3. Preview how `Sys.time()` is translated when prefixing `!!`

```r
airports %>%
  mutate(today = !!Sys.time()) %>%
  select(today) %>%
  head()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   today               
##   <chr>               
## 1 2019-01-04T17:09:41Z
## 2 2019-01-04T17:09:41Z
## 3 2019-01-04T17:09:41Z
## 4 2019-01-04T17:09:41Z
## 5 2019-01-04T17:09:41Z
## 6 2019-01-04T17:09:41Z
```

## knitr SQL engine

1. Copy the result of the latest `show_query()` exercise

```r
airports %>%
  mutate(today = !!Sys.time()) %>%
  show_query()
```

```
## <SQL>
## SELECT "airport", "airportname", "city", "state", "country", "lat", "long", '2019-01-04T17:09:41Z' AS "today"
## FROM datawarehouse.airport
```

2. Paste the result in this SQL chunk

```sql
SELECT "airport", "airportname", "city", "state", "country", "lat", "long", '2018-01-26T14:50:10Z' AS "today"
FROM datawarehouse.airport
```


<div class="knitsql-table">


Table: (\#tab:unnamed-chunk-18)Displaying records 1 - 10

airport   airportname                   city            state   country         lat         long  today                
--------  ----------------------------  --------------  ------  --------  ---------  -----------  ---------------------
ABE       Lehigh Valley International   Allentown       PA      USA        40.65236    -75.44040  2018-01-26T14:50:10Z 
ABI       Abilene Regional              Abilene         TX      USA        32.41132    -99.68190  2018-01-26T14:50:10Z 
ABQ       Albuquerque International     Albuquerque     NM      USA        35.04022   -106.60919  2018-01-26T14:50:10Z 
ABY       Southwest Georgia Regional    Albany          GA      USA        31.53552    -84.19447  2018-01-26T14:50:10Z 
ACK       Nantucket Memorial            Nantucket       MA      USA        41.25305    -70.06018  2018-01-26T14:50:10Z 
ACT       Waco Regional                 Waco            TX      USA        31.61129    -97.23052  2018-01-26T14:50:10Z 
ACV       Arcata                        Arcata/Eureka   CA      USA        40.97812   -124.10862  2018-01-26T14:50:10Z 
ACY       Atlantic City International   Atlantic City   NJ      USA        39.45758    -74.57717  2018-01-26T14:50:10Z 
ADK       Adak                          Adak            AK      USA        51.87796   -176.64603  2018-01-26T14:50:10Z 
ADQ       Kodiak                        Kodiak          AK      USA        57.74997   -152.49386  2018-01-26T14:50:10Z 

</div>


## Basic aggregation
*A couple of `dplyr` commands that run in-database*

1. How many records are in the **airport** table?

```r
tbl(con, in_schema("datawarehouse", "airport"))  %>%
  tally()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   n              
##   <S3: integer64>
## 1 305
```

2. What is the average character length of the airport codes? How many characters is the longest and the shortest airport name?

```r
airports %>%
  summarise(
    avg_airport_length = mean(str_length(airport), na.rm = TRUE),
    max_airport_name = max(str_length(airportname), na.rm = TRUE),
    min_airport_name = min(str_length(airportname), na.rm = TRUE),
    total_records = n()
  )
```

```
## # Source:   lazy query [?? x 4]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   avg_airport_length max_airport_name min_airport_name total_records  
##                <dbl>            <int>            <int> <S3: integer64>
## 1                  3               40                3 305
```

3. How many records are in the **carrier** table?

```r
carriers %>%
  tally()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   n              
##   <S3: integer64>
## 1 20
```

4. How many characters is the longest **carriername**?

```r
carriers %>%
  summarise(x = max(str_length(carriername), na.rm = TRUE))
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##       x
##   <int>
## 1    83
```

5. What is the SQL statement sent in exercise 4?

```r
carriers %>%
  summarise(x = max(str_length(carriername), na.rm = TRUE)) %>%
  show_query()
```

```
## <SQL>
## SELECT MAX(LENGTH("carriername")) AS "x"
## FROM datawarehouse.carrier
```


