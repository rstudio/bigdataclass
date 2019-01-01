

# Advanced Operations



## Simple wrapper function
*Create a function that accepts a value that is passed to a specific dplyr operation*


1. The following `dplyr` operation is fixed to only return the mean of *arrtime*.  The desire is to create a function that returns the mean of any variable passed to it.

```r
flights %>%
  summarise(mean = mean(arrtime, na.rm = TRUE))
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1 1481.
```

2. Load the `rlang` library, and create a function with one argument. The function will simply return the result of `equo()`


```r
library(rlang)

my_mean <- function(x){
  x <- enquo(x)
  x
}

my_mean(mpg)
```

```
## <quosure>
## expr: ^mpg
## env:  global
```

3. Add the `summarise()` operation, and replace *arrtime* with *!! x*

```r
library(rlang)

my_mean <- function(x){
  x <- enquo(x)
  flights %>%
    summarise(mean = mean(!! x, na.rm = TRUE))
}
```

4. Test the function with *deptime*

```r
my_mean(deptime)
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1 1334.
```

5. Make the function use what is passed to the *x* argument as the name of the calculation.  Replace *mean = * with *!! quo_name(x) :=* .

```r
my_mean <- function(x){
  x <- enquo(x)
  flights %>%
    summarise(!! quo_name(x) := mean(!! x, na.rm = TRUE))
  
}
```

6. Test the function again with *arrtime*.  The name of the variable should now by *arrtime*

```r
my_mean(arrtime)
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   arrtime
##     <dbl>
## 1   1481.
```

7. Test the function with a formula: *arrtime+deptime*.

```r
my_mean(arrtime+deptime)
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   `arrtime + deptime`
##                 <dbl>
## 1               2815.
```

8. Make the function generic by adding a *.data* argument and replacing *flights* with *.data*

```r
my_mean <- function(.data, x){
  x <- enquo(x)
  .data %>%
    summarise(!! quo_name(x) := mean(!! x, na.rm = TRUE))
  
}
```

9. The function now behaves more like a `dplyr` verb. Start with *flights* and pipe into the function.

```r
flights %>%
  my_mean(arrtime)
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   arrtime
##     <dbl>
## 1   1481.
```

10. Test the function with a different data set.  Use `mtcars` and *mpg* as the *x* argument.

```r
mtcars %>%
  my_mean(mpg)
```

```
##        mpg
## 1 20.09062
```

11. Clean up the function by removing the pipe

```r
my_mean <- function(.data, x){
  x <- enquo(x)
  summarise(
    .data, 
    !! quo_name(x) := mean(!! x, na.rm = TRUE)
  )
}
```

12. Test again, no visible changes should be there for the results

```r
mtcars %>%
  my_mean(mpg)
```

```
##        mpg
## 1 20.09062
```

13. Because the function only uses `dplyr` operations, `show_query()` should work

```r
flights %>%
  my_mean(arrtime) %>%
  show_query()
```

```
## <SQL>
## SELECT AVG("arrtime") AS "arrtime"
## FROM datawarehouse.vflight
```


## Multiple variables
*Create functions that handle a variable number of arguments. The goal of the exercise is to create an "anti-select()" function.*

1. Use *...* as the second argument of a function called `de_select()`.  Inside the function use `enquos()` to parse it

```r
de_select <- function(.data, ...){
  vars <- enquos(...)
  vars
}
```

2. Test the function using *airports*

```r
airports %>%
  de_select(airport, airportname)
```

```
## <listof<quosures>>
## 
## [[1]]
## <quosure>
## expr: ^airport
## env:  0x55b1d91bc2a0
## 
## [[2]]
## <quosure>
## expr: ^airportname
## env:  0x55b1d91bc2a0
```

3. Add a step to the function that iterates through each quosure and prefixes a minus sign to tell `select()` to drop that specific field.  Use `map()` for the iteration, and `expr()` to create the prefixed expression.

```r
de_select <- function(.data, ...){
  vars <- enquos(...)
  vars <- map(vars, ~ expr(- !! .x))
  vars
}
```

4. Run the same test to view the new results


```r
airports %>%
  de_select(airport, airportname)
```

```
## [[1]]
## -~airport
## 
## [[2]]
## -~airportname
```

5. Add the `select()` step.  Use *!!!* to parse the *vars* variable inside `select()`


```r
de_select <- function(.data, ...){
  vars <- enquos(...)
  vars <- map(vars, ~ expr(- !! .x))
  select(
    .data,
    !!! vars
  )
}
```

6. Run the test again, this time the operation will take place.  


```r
airports %>%
  de_select(airport, airportname)
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    city          state country   lat   long
##    <chr>         <chr> <chr>   <dbl>  <dbl>
##  1 Allentown     PA    USA      40.7  -75.4
##  2 Abilene       TX    USA      32.4  -99.7
##  3 Albuquerque   NM    USA      35.0 -107. 
##  4 Albany        GA    USA      31.5  -84.2
##  5 Nantucket     MA    USA      41.3  -70.1
##  6 Waco          TX    USA      31.6  -97.2
##  7 Arcata/Eureka CA    USA      41.0 -124. 
##  8 Atlantic City NJ    USA      39.5  -74.6
##  9 Adak          AK    USA      51.9 -177. 
## 10 Kodiak        AK    USA      57.7 -152. 
## # ... with more rows
```

7. Add a `show_query()` step to see the resulting SQL


```r
airports %>%
  de_select(airport, airportname) %>%
  show_query()
```

```
## <SQL>
## SELECT "city", "state", "country", "lat", "long"
## FROM datawarehouse.airport
```

8. Test the function with a different data set, such as `mtcars`


```r
mtcars %>%
  de_select(mpg, wt, am)
```

```
##                     cyl  disp  hp drat  qsec vs gear carb
## Mazda RX4             6 160.0 110 3.90 16.46  0    4    4
## Mazda RX4 Wag         6 160.0 110 3.90 17.02  0    4    4
## Datsun 710            4 108.0  93 3.85 18.61  1    4    1
## Hornet 4 Drive        6 258.0 110 3.08 19.44  1    3    1
## Hornet Sportabout     8 360.0 175 3.15 17.02  0    3    2
## Valiant               6 225.0 105 2.76 20.22  1    3    1
## Duster 360            8 360.0 245 3.21 15.84  0    3    4
## Merc 240D             4 146.7  62 3.69 20.00  1    4    2
## Merc 230              4 140.8  95 3.92 22.90  1    4    2
## Merc 280              6 167.6 123 3.92 18.30  1    4    4
## Merc 280C             6 167.6 123 3.92 18.90  1    4    4
## Merc 450SE            8 275.8 180 3.07 17.40  0    3    3
## Merc 450SL            8 275.8 180 3.07 17.60  0    3    3
## Merc 450SLC           8 275.8 180 3.07 18.00  0    3    3
## Cadillac Fleetwood    8 472.0 205 2.93 17.98  0    3    4
## Lincoln Continental   8 460.0 215 3.00 17.82  0    3    4
## Chrysler Imperial     8 440.0 230 3.23 17.42  0    3    4
## Fiat 128              4  78.7  66 4.08 19.47  1    4    1
## Honda Civic           4  75.7  52 4.93 18.52  1    4    2
## Toyota Corolla        4  71.1  65 4.22 19.90  1    4    1
## Toyota Corona         4 120.1  97 3.70 20.01  1    3    1
## Dodge Challenger      8 318.0 150 2.76 16.87  0    3    2
## AMC Javelin           8 304.0 150 3.15 17.30  0    3    2
## Camaro Z28            8 350.0 245 3.73 15.41  0    3    4
## Pontiac Firebird      8 400.0 175 3.08 17.05  0    3    2
## Fiat X1-9             4  79.0  66 4.08 18.90  1    4    1
## Porsche 914-2         4 120.3  91 4.43 16.70  0    5    2
## Lotus Europa          4  95.1 113 3.77 16.90  1    5    2
## Ford Pantera L        8 351.0 264 4.22 14.50  0    5    4
## Ferrari Dino          6 145.0 175 3.62 15.50  0    5    6
## Maserati Bora         8 301.0 335 3.54 14.60  0    5    8
## Volvo 142E            4 121.0 109 4.11 18.60  1    4    2
```

## Multiple queries
*Suggested approach to avoid passing multiple, and similar, queries to the database*

1. Create a simple `dplyr` piped operation that returns the mean of *arrdelay* for the months of January, February and March as a group.


```r
flights %>%
  filter(month %in% c(1,2,3)) %>%
  summarise(mean = mean(arrdelay, na.rm = TRUE)) 
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  11.4
```

2. Assign the first operation to a variable called *a*, and create copy of the operation but changing the selected months to January, March and April.  Assign the second one to a variable called *b*.


```r
a <- flights %>%
  filter(month %in% c(1,2,3)) %>%
  summarise(mean = mean(arrdelay, na.rm = TRUE)) 

b <- flights %>%
  filter(month %in% c(1,3,4)) %>%
  summarise(mean = mean(arrdelay, na.rm = TRUE)) 
```

3. Use *union()* to pass *a* and *b* at the same time to the database.


```r
union(a, b)
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.41
## 2 11.4
```

4. Assign to a new variable called *months* an overlapping set of months.  


```r
months <- list(
  c(1,2,3),
  c(1,3,4),
  c(2,4,6)
)
```

5. Use `map()` to cycle through each set of overlapping months.  Notice that it returns three separate results, meaning that it went to the database three times.


```r
months %>%
  map( ~ flights %>%
         filter(month %in% .x) %>%
         summarise(mean = mean(arrdelay, na.rm = TRUE)) 
  )
```

```
## [[1]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  11.4
## 
## [[2]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.41
## 
## [[3]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  11.0
```

6. Add a `reduce()` operation and use `union()` command to create a single query.


```r
months %>%
  map( ~ flights %>%
         filter(month %in% .x) %>%
         summarise(mean = mean(arrdelay, na.rm = TRUE)) 
  ) %>%
  reduce(function(x, y) union(x, y))
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.41
## 2 11.4 
## 3 11.0
```

7. Use `show_query()` to see the resulting single query sent to the database.


```r
months %>%
  map( ~ flights %>%
         filter(month %in% .x) %>%
         summarise(mean = mean(arrdelay, na.rm = TRUE)) 
  ) %>%
  reduce(function(x, y) union(x, y)) %>%
  show_query()
```

```
## <SQL>
## ((SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "bkcyayfbcd"
## WHERE ("month" IN (1.0, 2.0, 3.0))) "bccnkoqcwe")
## UNION
## (SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "ovdqufvacw"
## WHERE ("month" IN (1.0, 3.0, 4.0))) "ncukknqauf"))
## UNION
## (SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "npaxmygwkt"
## WHERE ("month" IN (2.0, 4.0, 6.0))) "xzxjlsirbb")
```


## Multiple queries with an overlaping range

1. Create a table with a *from* and *to* ranges.


```r
ranges <- tribble(
  ~ from, ~to, 
       1,   4,
       2,   5,
       3,   7
)
```

2. See how `map2()` works by passing the two variables as the *x* and *y* arguments, and adding them as the function. 


```r
map2(ranges$from, ranges$to, ~.x + .y)
```

```
## [[1]]
## [1] 5
## 
## [[2]]
## [1] 7
## 
## [[3]]
## [1] 10
```

3. Replace *x + y* with the `dplyr` operation from the previous exercise.  In it, re-write the filter to use *x* and *y* as the month ranges 


```r
map2(
  ranges$from, 
  ranges$to,
  ~ flights %>%
      filter(month >= .x & month <= .y) %>%
      summarise(mean = mean(arrdelay, na.rm = TRUE)) 
)
```

```
## [[1]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  10.3
## 
## [[2]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.19
## 
## [[3]]
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.45
```

4. Add the reduce operation


```r
map2(
  ranges$from, 
  ranges$to,
  ~ flights %>%
      filter(month >= .x & month <= .y) %>%
      summarise(mean = mean(arrdelay, na.rm = TRUE)) 
) %>%
  reduce(function(x, y) union(x, y))
```

```
## # Source:   lazy query [?? x 1]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##    mean
##   <dbl>
## 1  9.45
## 2  9.19
## 3 10.3
```

5. Add a `show_query()` step to see how the final query was constructed.


```r
map2(
  ranges$from, 
  ranges$to,
  ~ flights %>%
      filter(month >= .x & month <= .y) %>%
      summarise(mean = mean(arrdelay, na.rm = TRUE)) 
) %>%
  reduce(function(x, y) union(x, y)) %>%
  show_query()
```

```
## <SQL>
## ((SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "iiozyzpqgv"
## WHERE ("month" >= 1.0 AND "month" <= 4.0)) "xgsthlyaap")
## UNION
## (SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "milzbhhnkl"
## WHERE ("month" >= 2.0 AND "month" <= 5.0)) "cmjeljldyr"))
## UNION
## (SELECT AVG("arrdelay") AS "mean"
## FROM (SELECT *
## FROM (SELECT *
## FROM datawarehouse.vflight) "dawgbvmclj"
## WHERE ("month" >= 3.0 AND "month" <= 7.0)) "wsnlywihee")
```


