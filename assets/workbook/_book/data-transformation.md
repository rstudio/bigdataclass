

# Data transformation



## Group and sort records
*Learn how to use `group_by()` and `arrange()` to better understand aggregated data*


1. How many flights are there per month?

```r
flights %>%
  group_by(month) %>%
  tally() 
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    month n              
##    <dbl> <S3: integer64>
##  1     1 605765         
##  2     2 569236         
##  3     3 616090         
##  4     4 598126         
##  5     5 606293         
##  6     6 608665         
##  7     7 627931         
##  8     8 612279         
##  9     9 540908         
## 10    10 556205         
## # ... with more rows
```

2. Order the results by the month number by using `arrange()`

```r
flights %>%
  group_by(month) %>%
  tally() %>%
  arrange(month)
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: month
##    month n              
##    <dbl> <S3: integer64>
##  1     1 605765         
##  2     2 569236         
##  3     3 616090         
##  4     4 598126         
##  5     5 606293         
##  6     6 608665         
##  7     7 627931         
##  8     8 612279         
##  9     9 540908         
## 10    10 556205         
## # ... with more rows
```

3. Order the results by the number of flights, starting with the month with most flights by using `desc()` inside the `arrange()` command

```r
flights %>%
  group_by(month) %>%
  tally() %>%
  arrange(desc(n)) 
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: desc(n)
##    month n              
##    <dbl> <S3: integer64>
##  1     7 627931         
##  2     3 616090         
##  3     8 612279         
##  4     6 608665         
##  5     5 606293         
##  6     1 605765         
##  7     4 598126         
##  8     2 569236         
##  9    10 556205         
## 10    12 544958         
## # ... with more rows
```

## Answering questions with `dplyr`
*Quick review of how to translate questions into `dplyr` code*

1. Which are the top 4 months with the most flight activity?

```r
flights %>%
  group_by(month) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(4)
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: desc(n)
##   month n              
##   <dbl> <S3: integer64>
## 1     7 627931         
## 2     3 616090         
## 3     8 612279         
## 4     6 608665
```

2. What were the top 5 calendar days with most flight activity?

```r
flights %>%
  group_by(month, dayofmonth) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(5)
```

```
## # Source:     lazy query [?? x 3]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Groups:     month
## # Ordered by: desc(n)
##   month dayofmonth n              
##   <dbl>      <dbl> <S3: integer64>
## 1     7         18 21128          
## 2     7         11 21125          
## 3     7         25 21102          
## 4     7         10 21058          
## 5     7         17 21055
```

3. Which are the top 5 carriers (airlines) with the most flights?


```r
flights %>%
  group_by(carriername) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(5)
```

```
## # Source:     lazy query [?? x 2]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: desc(n)
##   carriername                                                  n           
##   <chr>                                                        <S3: intege>
## 1 Southwest Airlines Co.                                       1201754     
## 2 American Airlines Inc.                                        604885     
## 3 Skywest Airlines Inc.                                         567159     
## 4 American Eagle Airlines Inc.                                  490693     
## 5 US Airways Inc. (Merged with America West 9/05. Reporting f…  453589
```

4. Figure the percent ratio of flights per month

```r
flights %>%
  group_by(month) %>%
  tally() %>%
  arrange(desc(n)) %>%
  mutate(percent = n/sum(n, na.rm = TRUE))
```

```
## # Source:     lazy query [?? x 3]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: desc(n)
##    month n               percent
##    <dbl> <S3: integer64>   <dbl>
##  1     7 627931           0.0896
##  2     3 616090           0.0879
##  3     8 612279           0.0873
##  4     6 608665           0.0868
##  5     5 606293           0.0865
##  6     1 605765           0.0864
##  7     4 598126           0.0853
##  8     2 569236           0.0812
##  9    10 556205           0.0793
## 10    12 544958           0.0777
## # ... with more rows
```

5. Figure the percent ratio of flights per carrier

```r
flights %>%
  group_by(carriername) %>%
  tally() %>%
  arrange(desc(n)) %>%
  mutate(percent = n/sum(n, na.rm = TRUE))
```

```
## # Source:     lazy query [?? x 3]
## # Database:   postgres [rstudio_dev@localhost:/postgres]
## # Ordered by: desc(n)
##    carriername                                          n           percent
##    <chr>                                                <S3: integ>   <dbl>
##  1 Southwest Airlines Co.                               1201754      0.171 
##  2 American Airlines Inc.                                604885      0.0863
##  3 Skywest Airlines Inc.                                 567159      0.0809
##  4 American Eagle Airlines Inc.                          490693      0.0700
##  5 US Airways Inc. (Merged with America West 9/05. Rep…  453589      0.0647
##  6 Delta Air Lines Inc.                                  451931      0.0645
##  7 United Air Lines Inc.                                 449515      0.0641
##  8 Expressjet Airlines Inc.                              374510      0.0534
##  9 Northwest Airlines Inc.                               347652      0.0496
## 10 Continental Air Lines Inc.                            298455      0.0426
## # ... with more rows
```

## Aggregate mulitple columns
*Practice using `summarise _` functions*

1. Use `summarise_all()` to send the same function to all fields

```r
flights %>%
  select(depdelay, arrdelay) %>%
  summarise_all(mean, na.rm = TRUE)
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   depdelay arrdelay
##      <dbl>    <dbl>
## 1     9.97     8.17
```

2. Use `summarise_at()` to pre-select the fields that will receive the function

```r
flights %>%
  summarise_at(c("depdelay", "arrdelay"), mean, na.rm = TRUE)
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   depdelay arrdelay
##      <dbl>    <dbl>
## 1     9.97     8.17
```

3. Use `summarise_if()` to summarize only if the field meets a criterion

```r
flights %>%
  summarise_if(is.numeric,mean, na.rm = TRUE)
```

```
## Applying predicate on the first 100 rows
```

```
## # Source:   lazy query [?? x 30]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   carrierdelay originlat originlong destlat destlong flightid  year month
##          <dbl>     <dbl>      <dbl>   <dbl>    <dbl>    <dbl> <dbl> <dbl>
## 1         15.8      36.9      -95.1    36.9    -95.1 3504864.  2008  6.38
## # ... with 22 more variables: dayofmonth <dbl>, dayofweek <dbl>,
## #   deptime <dbl>, crsdeptime <dbl>, arrtime <dbl>, crsarrtime <dbl>,
## #   flightnum <dbl>, actualelapsedtime <dbl>, crselapsedtime <dbl>,
## #   airtime <dbl>, arrdelay <dbl>, depdelay <dbl>, distance <dbl>,
## #   taxiin <dbl>, taxiout <dbl>, cancelled <dbl>, diverted <dbl>,
## #   weatherdelay <dbl>, nasdelay <dbl>, securitydelay <dbl>,
## #   lateaircraftdelay <dbl>, score <dbl>
```

4. Combine with `group_by()` to create more complex results

```r
flights %>%
  select(month, depdelay, arrdelay) %>%
  group_by(month) %>%
  summarise_all(mean, na.rm = TRUE)
```

```
## # Source:   lazy query [?? x 3]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    month depdelay arrdelay
##    <dbl>    <dbl>    <dbl>
##  1     1    11.5    10.2  
##  2     2    13.7    13.1  
##  3     3    12.5    11.2  
##  4     4     8.20    6.81 
##  5     5     7.64    5.98 
##  6     6    13.6    13.3  
##  7     7    11.8     9.98 
##  8     8     9.61    6.91 
##  9     9     3.96    0.698
## 10    10     3.80    0.415
## # ... with more rows
```

## View record level data
*Important tips to record preview data*

How many flights in July 18th were one or more hours late?

```r
flights %>%
  filter(
    depdelay >= 60,
    month == 7,
    dayofmonth == 18
  ) %>%
  tally()
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   n              
##   <S3: integer64>
## 1 1239
```


1. Use `filter()` to retrieve only the needed data, and `head()` to limit the preview even further.

```r
flights %>%
  filter(
    depdelay >= 60,
    month == 7,
    dayofmonth == 18
  ) %>%
  head(100)
```

```
## # Source:   lazy query [?? x 44]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    uniquecarrier carrierdelay carriername origin originname origincity
##    <chr>                <dbl> <chr>       <chr>  <chr>      <chr>     
##  1 WN                       0 Southwest … ABQ    Albuquerq… Albuquerq…
##  2 WN                      42 Southwest … ABQ    Albuquerq… Albuquerq…
##  3 WN                     122 Southwest … ABQ    Albuquerq… Albuquerq…
##  4 WN                       0 Southwest … ABQ    Albuquerq… Albuquerq…
##  5 WN                      71 Southwest … ABQ    Albuquerq… Albuquerq…
##  6 WN                      14 Southwest … ABQ    Albuquerq… Albuquerq…
##  7 WN                      84 Southwest … AUS    Austin-Be… Austin    
##  8 WN                      56 Southwest … AUS    Austin-Be… Austin    
##  9 WN                       0 Southwest … BNA    Nashville… Nashville 
## 10 WN                      32 Southwest … BNA    Nashville… Nashville 
## # ... with more rows, and 38 more variables: originstate <chr>,
## #   origincountry <chr>, originlat <dbl>, originlong <dbl>, dest <chr>,
## #   destname <chr>, destcity <chr>, deststate <chr>, destcountry <chr>,
## #   destlat <dbl>, destlong <dbl>, flightid <int>, year <dbl>,
## #   month <dbl>, dayofmonth <dbl>, dayofweek <dbl>, deptime <dbl>,
## #   crsdeptime <dbl>, arrtime <dbl>, crsarrtime <dbl>, flightnum <dbl>,
## #   tailnum <chr>, actualelapsedtime <dbl>, crselapsedtime <dbl>,
## #   airtime <dbl>, arrdelay <dbl>, depdelay <dbl>, distance <dbl>,
## #   taxiin <dbl>, taxiout <dbl>, cancelled <dbl>, cancellationcode <chr>,
## #   diverted <dbl>, weatherdelay <dbl>, nasdelay <dbl>,
## #   securitydelay <dbl>, lateaircraftdelay <dbl>, score <int>
```

2. Use `collect()` and `View()` to preview the data in the IDE. Make sure to **always** limit the number of returned rows. https://github.com/tidyverse/tibble/issues/373


```r
flights %>%
  filter(
    depdelay >= 60,
    month == 7,
    dayofmonth == 18
  ) %>%
  collect() %>%
  head(100) %>%
  View("my_preview")
```

## Case statements
*See how to use the flexibility of case statements for special cases*

1. Use `case_when()` to bucket each month one of four seasons

```r
flights %>%
  mutate(
    season = case_when(
      month >= 3 && month <= 5  ~ "Spring",
      month >= 6 && month <= 8  ~ "Summer",
      month >= 9 && month <= 11 ~ "Fall",
      TRUE ~ "Winter"
    )
  ) %>%
  group_by(season) %>%
  tally()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   season n              
##   <chr>  <S3: integer64>
## 1 Fall   1620385        
## 2 Spring 1820509        
## 3 Summer 1848875        
## 4 Winter 1719959
```

2. Add a specific case for "Winter"

```r
flights %>%
  mutate(
    season = case_when(
      month >= 3 && month <= 5  ~ "Spring",
      month >= 6 && month <= 8  ~ "Summer",
      month >= 9 && month <= 11 ~ "Fall",
      month == 12 | month <= 2  ~ "Winter"
    )
  ) %>%
  group_by(season) %>%
  tally()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   season n              
##   <chr>  <S3: integer64>
## 1 Fall   1620385        
## 2 Spring 1820509        
## 3 Summer 1848875        
## 4 Winter 1719959
```

3. Append an entry for Monday at the end of the case statement

```r
flights %>%
  mutate(
    season = case_when(
      month >= 3 && month <= 5  ~ "Spring",
      month >= 6 && month <= 8  ~ "Summer",
      month >= 9 && month <= 11 ~ "Fall",
      month == 12 | month <= 2  ~ "Winter",
      dayofweek == 1 ~ "Monday"
    )
  ) %>%
  group_by(season) %>%
  tally()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   season n              
##   <chr>  <S3: integer64>
## 1 Fall   1620385        
## 2 Spring 1820509        
## 3 Summer 1848875        
## 4 Winter 1719959
```

4. Move the "Monday" entry to the top of the case statement

```r
flights %>%
  mutate(
    season = case_when(
      dayofweek == 1 ~ "Monday",
      month >= 3 && month <= 5  ~ "Spring",
      month >= 6 && month <= 8  ~ "Summer",
      month >= 9 && month <= 11 ~ "Fall",
      month == 12 | month <= 2  ~ "Winter"
    )
  ) %>%
  group_by(season) %>%
  tally()
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   season n              
##   <chr>  <S3: integer64>
## 1 Fall   1376740        
## 2 Monday 1036201        
## 3 Spring 1554210        
## 4 Summer 1577629        
## 5 Winter 1464948
```


##  Data enrichment
*Upload a small dataset in order to combine it with the datawarehouse data*

1. Load the `planes` data into memory

```r
planes <- nycflights13::planes
```

2. Using `DBI`, copy the `planes` data to the datawarehouse as a temporary table, and load it to a variable

```r
dbWriteTable(con, "planes", planes, temporary = TRUE)
tbl_planes <- tbl(con, "planes")
```

3. Create a "lazy" variable that joins the flights table to the new temp table

```r
combined <- flights %>%
  left_join(tbl_planes, by = "tailnum") 
```

4. View a sample of flights of planes with more than 100 seats

```r
combined %>%
  filter(seats > 100) %>%
  head()
```

```
## # Source:   lazy query [?? x 52]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   uniquecarrier carrierdelay carriername origin originname origincity
##   <chr>                <dbl> <chr>       <chr>  <chr>      <chr>     
## 1 WN                      NA Southwest … ABQ    Albuquerq… Albuquerq…
## 2 WN                      NA Southwest … ABQ    Albuquerq… Albuquerq…
## 3 WN                      14 Southwest … ABQ    Albuquerq… Albuquerq…
## 4 WN                      NA Southwest … ABQ    Albuquerq… Albuquerq…
## 5 WN                      NA Southwest … ABQ    Albuquerq… Albuquerq…
## 6 WN                      NA Southwest … ABQ    Albuquerq… Albuquerq…
## # ... with 46 more variables: originstate <chr>, origincountry <chr>,
## #   originlat <dbl>, originlong <dbl>, dest <chr>, destname <chr>,
## #   destcity <chr>, deststate <chr>, destcountry <chr>, destlat <dbl>,
## #   destlong <dbl>, flightid <int>, year.x <dbl>, month <dbl>,
## #   dayofmonth <dbl>, dayofweek <dbl>, deptime <dbl>, crsdeptime <dbl>,
## #   arrtime <dbl>, crsarrtime <dbl>, flightnum <dbl>, tailnum <chr>,
## #   actualelapsedtime <dbl>, crselapsedtime <dbl>, airtime <dbl>,
## #   arrdelay <dbl>, depdelay <dbl>, distance <dbl>, taxiin <dbl>,
## #   taxiout <dbl>, cancelled <dbl>, cancellationcode <chr>,
## #   diverted <dbl>, weatherdelay <dbl>, nasdelay <dbl>,
## #   securitydelay <dbl>, lateaircraftdelay <dbl>, score <int>,
## #   year.y <int>, type <chr>, manufacturer <chr>, model <chr>,
## #   engines <int>, seats <int>, speed <int>, engine <chr>
```

5. How many flights are from McDonnel Douglas planes 

```r
combined %>%
  filter(manufacturer == "MCDONNELL DOUGLAS") %>%
  tally() 
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   n              
##   <S3: integer64>
## 1 137250
```

6. See how many flights each plane McDonnel Douglas had

```r
combined %>%
  filter(manufacturer == "MCDONNELL DOUGLAS") %>%
  group_by(tailnum) %>%
  tally() 
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    tailnum n              
##    <chr>   <S3: integer64>
##  1 N424AA  1479           
##  2 N426AA  1413           
##  3 N433AA  1153           
##  4 N434AA  1208           
##  5 N435AA  1185           
##  6 N436AA  1155           
##  7 N437AA  1233           
##  8 N438AA  1243           
##  9 N439AA  1251           
## 10 N454AA  1432           
## # ... with more rows
```

7. Get the total number of planes, and the average, minimum & maximum number of flights for the manufacturer

```r
combined %>%
  filter(manufacturer == "MCDONNELL DOUGLAS") %>%
  group_by(tailnum) %>%
  tally() %>%
  summarise(planes = n(),
            avg_flights = mean(n, na.rm = TRUE),
            max_flights = max(n, na.rm = TRUE),
            min_flights = min(n, na.rm = TRUE))
```

```
## # Source:   lazy query [?? x 4]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   planes          avg_flights max_flights     min_flights    
##   <S3: integer64>       <dbl> <S3: integer64> <S3: integer64>
## 1 102                   1346. 1850            1068
```

8. Disconnect from the database

```r
dbDisconnect(con)
```
