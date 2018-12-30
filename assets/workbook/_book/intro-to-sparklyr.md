

#Intro to `sparklyr`


## New Spark session
*Learn to open a new Spark session*

1. Use `spark_connect()` to create a new local Spark session

```r
sc <- spark_connect(master = "local", version = "2.0.0")
```

2. Click on the `SparkUI` button to view the current Spark session's UI

3. Click on the `Log` button to see the message history

## Data transfer
*Practice uploading data to Spark*

1. Copy the `mtcars` dataset into the session

```r
spark_mtcars <- sdf_copy_to(sc, mtcars, "my_mtcars")
```

2. In the **Connections** pane, expande the `my_mtcars` table

3. Go to the Spark UI, note the new jobs

4. In the UI, click the Storage button, note the new table

5. Click on the **In-memory table my_mtcars** link

## Simple dplyr example
*See how Spark handles `dplyr` commands*

1. Run the following code snipett

```r
spark_mtcars %>%
  group_by(am) %>%
  summarise(avg_wt = mean(wt, na.rm = TRUE))
```

```
## # Source: spark<?> [?? x 2]
##      am avg_wt
## * <dbl>  <dbl>
## 1     0   3.77
## 2     1   2.41
```

2. Go to the Spark UI and click the **SQL** button 

3. Click on the top item inside the **Completed Queries** table

4. At the bottom of the diagram, expand **Details**

## Map data
*See the machanics of how Spark is able to use files as a data source*

1. Examine the contents of the /usr/share/class/flights/data folder

2. Read the top 5 rows of the `flight_2008_1` CSV file.  It is located under /usr/share/class/flights


```r
library(readr)
top_rows <- read.csv("/usr/share/class/flights/data/flight_2008_1.csv", nrows = 5)
```

3. Create a list based on the column names, and add a list item with "character" as its value.

```r
library(purrr)
file_columns <- top_rows %>%
  rename_all(tolower) %>%
  map(function(x) "character")
head(file_columns)
```

```
## $flightid
## [1] "character"
## 
## $year
## [1] "character"
## 
## $month
## [1] "character"
## 
## $dayofmonth
## [1] "character"
## 
## $dayofweek
## [1] "character"
## 
## $deptime
## [1] "character"
```

4. Use `spark_read()` to "map" the file's structure and location to the Spark context

```r
spark_flights <- spark_read_csv(
  sc,
  name = "flights",
  path = "/usr/share/class/flights/data/",
  memory = FALSE,
  columns = file_columns,
  infer_schema = FALSE
)
```

5. In the Connections pane, click on the table icon by the `flights` variable

6. Verify that the new variable pointer work using `tally()`

```r
spark_flights %>%
  tally()
```

```
## # Source: spark<?> [?? x 1]
##         n
## *   <dbl>
## 1 7009728
```

## Caching data
*Learn how to cache a subset of the data in Spark*

1. Create a subset of the *flights* table object

```r
cached_flights <- spark_flights %>%
  mutate(
    arrdelay = ifelse(arrdelay == "NA", 0, arrdelay),
    depdelay = ifelse(depdelay == "NA", 0, depdelay)
  ) %>%
  select(
    month,
    dayofmonth,
    arrtime,
    arrdelay,
    depdelay,
    crsarrtime,
    crsdeptime,
    distance
  ) %>%
  mutate_all(as.numeric)
```

2. Use `compute()` to extract the data into Spark memory

```r
cached_flights <- compute(cached_flights, "sub_flights")
```

3. Confirm new variable pointer works

```r
cached_flights %>%
  tally()
```

```
## # Source: spark<?> [?? x 1]
##         n
## *   <dbl>
## 1 7009728
```

## `sdf` Functions
*Overview of a few `sdf_` functions: http://spark.rstudio.com/reference/#section-spark-dataframes *

1. Use `sdf_pivot` to create a column for each value in month

```r
cached_flights %>%
  arrange(month) %>%
  sdf_pivot(month ~ dayofmonth)
```

```
## # Source: spark<?> [?? x 32]
##    month `1.0` `2.0` `3.0` `4.0` `5.0` `6.0` `7.0` `8.0` `9.0` `10.0`
##  * <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
##  1     1     1     2     3     4     5     6     7     8     9     10
##  2     2     1     2     3     4     5     6     7     8     9     10
##  3     3     1     2     3     4     5     6     7     8     9     10
##  4     4     1     2     3     4     5     6     7     8     9     10
##  5     5     1     2     3     4     5     6     7     8     9     10
##  6     6     1     2     3     4     5     6     7     8     9     10
##  7     7     1     2     3     4     5     6     7     8     9     10
##  8     8     1     2     3     4     5     6     7     8     9     10
##  9     9     1     2     3     4     5     6     7     8     9     10
## 10    10     1     2     3     4     5     6     7     8     9     10
## # ... with more rows, and 21 more variables: `11.0` <dbl>, `12.0` <dbl>,
## #   `13.0` <dbl>, `14.0` <dbl>, `15.0` <dbl>, `16.0` <dbl>, `17.0` <dbl>,
## #   `18.0` <dbl>, `19.0` <dbl>, `20.0` <dbl>, `21.0` <dbl>, `22.0` <dbl>,
## #   `23.0` <dbl>, `24.0` <dbl>, `25.0` <dbl>, `26.0` <dbl>, `27.0` <dbl>,
## #   `28.0` <dbl>, `29.0` <dbl>, `30.0` <dbl>, `31.0` <dbl>
```

2. Use `sdf_partition()` to sepparate the data into discrete groups

```r
partition <- cached_flights %>%
  sdf_partition(training = 0.01, testing = 0.09, other = 0.9)

tally(partition$training)
```

```
## # Source: spark<?> [?? x 1]
##       n
## * <dbl>
## 1 70069
```

## Feature transformers
*See how to use Spark's feature transformers: http://spark.rstudio.com/reference/#section-spark-feature-transformers *

1. Use `ft_binarizer()` to identify "delayed" flights

```r
cached_flights %>%
  ft_binarizer(
    input_col = "depdelay",
    output_col = "delayed",
    threshold = 15
  ) %>%
  select(
    depdelay,
    delayed
  ) %>%
  head(100)
```

```
## # Source: spark<?> [?? x 2]
##    depdelay delayed
##  *    <dbl>   <dbl>
##  1       -4       0
##  2       -1       0
##  3       15       0
##  4       -2       0
##  5        2       0
##  6       -4       0
##  7       19       1
##  8        1       0
##  9        0       0
## 10       -3       0
## # ... with more rows
```

2. Use `ft_bucketizer()` to split the data into groups

```r
cached_flights %>%
  ft_bucketizer(
    input_col = "crsdeptime",
    output_col = "dephour",
    splits = c(0, 400, 800, 1200, 1600, 2000, 2400)
  ) %>%
  select(
    crsdeptime,
    dephour
  ) %>%
  head(100)
```

```
## # Source: spark<?> [?? x 2]
##    crsdeptime dephour
##  *      <dbl>   <dbl>
##  1        910       2
##  2        835       2
##  3       1555       3
##  4        730       1
##  5       2045       5
##  6       1135       2
##  7       1310       3
##  8       1220       3
##  9       1515       3
## 10        630       1
## # ... with more rows
```

## Fit a model with `sparklyr`
*Build on the recently learned transformation techniques to feed data into a model*

1. Combine the `ft_` and `sdf_` functions to prepare the da

```r
sample_data <- cached_flights %>%
  filter(!is.na(arrdelay)) %>%
  ft_binarizer(
    input_col = "arrdelay",
    output_col = "delayed",
    threshold = 15
  ) %>%
  ft_bucketizer(
    input_col = "crsdeptime",
    output_col = "dephour",
    splits = c(0, 400, 800, 1200, 1600, 2000, 2400)
  ) %>%
  mutate(dephour = paste0("h", as.integer(dephour))) %>%
  sdf_partition(training = 0.01, testing = 0.09, other = 0.9)
```

2. Cache the training data

```r
training <- sdf_register(sample_data$training, "training")
tbl_cache(sc, "training")
```

3. Run a logistic regression model in Spark

```r
delayed_model <- training %>%
  ml_logistic_regression(delayed ~ depdelay + dephour)
```

4. View the model results

```r
summary(delayed_model)
```

```
## Coefficients:
## (Intercept)    depdelay  dephour_h2  dephour_h3  dephour_h4  dephour_h1 
##  -3.7840583   0.1373576   1.1044356   1.0458168   1.1399381   1.2710293 
##  dephour_h5 
##   1.0980554
```

## Run predictions in Spark
*Quick review of running predictions and reviewing accuracy*

1. Use `sdf_predict()` agains the test dataset

```r
delayed_testing <- sdf_predict(delayed_model, sample_data$testing)
```

```
## Warning in sdf_predict.ml_model(delayed_model, sample_data$testing): The
## signature sdf_predict(model, dataset) is deprecated and will be removed
## in a future version. Use sdf_predict(dataset, model) or ml_predict(model,
## dataset) instead.
```

```r
delayed_testing %>%
  head()
```

```
## # Source: spark<?> [?? x 17]
##   month dayofmonth arrtime arrdelay depdelay crsarrtime crsdeptime distance
## * <dbl>      <dbl>   <dbl>    <dbl>    <dbl>      <dbl>      <dbl>    <dbl>
## 1     7          1     NaN        0        0        739        634      155
## 2     7          1     NaN        0        0        939        818      289
## 3     7          1     NaN        0        0        940        815      447
## 4     7          1     NaN        0        0       1135       1015      337
## 5     7          1     NaN        0        0       1803       1633      326
## 6     7          1     NaN        0        0       2000       1730      487
## # ... with 9 more variables: delayed <dbl>, dephour <chr>,
## #   features <list>, label <dbl>, rawPrediction <list>,
## #   probability <list>, prediction <dbl>, probability_0 <dbl>,
## #   probability_1 <dbl>
```

2. Use `group_by()` to see how effective the new model is

```r
delayed_testing %>%
  group_by(delayed, prediction) %>%
  tally()
```

```
## # A tibble: 4 x 3
##   delayed prediction      n
## *   <dbl>      <dbl>  <dbl>
## 1       0          1  10345
## 2       0          0 489359
## 3       1          1  90930
## 4       1          0  41097
```



