

#Spark pipelines



## Recreate the transformations 
*Overview of how most of the existing code will be reused*

1. Register a new table called *current* containing a sample of the base *flights* table

```r
model_data <- sdf_partition(
  tbl(sc, "flights"),
  training = 0.01,
  testing = 0.01,
  rest = 0.98
)
```

2. Recreate the `dplyr` code in the `cached_flights` variable from the previous unit

```r
pipeline_df <- model_data$training %>%
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

3. Create a new Spark pipeline

```r
flights_pipeline <- ml_pipeline(sc) %>%
  ft_dplyr_transformer(
    tbl = pipeline_df
  ) %>%
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
  ft_r_formula(delayed ~ arrdelay + dephour) %>%
  ml_logistic_regression()

flights_pipeline
```

```
## Pipeline (Estimator) with 5 stages
## <pipeline_417e407697a7> 
##   Stages 
##   |--1 SQLTransformer (Transformer)
##   |    <dplyr_transformer_417e675dac97> 
##   |     (Parameters -- Column Names)
##   |--2 Binarizer (Transformer)
##   |    <binarizer_417e6cf95ba7> 
##   |     (Parameters -- Column Names)
##   |      input_col: arrdelay
##   |      output_col: delayed
##   |--3 Bucketizer (Transformer)
##   |    <bucketizer_417e70d355f9> 
##   |     (Parameters -- Column Names)
##   |      input_col: crsdeptime
##   |      output_col: dephour
##   |--4 RFormula (Estimator)
##   |    <r_formula_417e441e8089> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |     (Parameters)
##   |      formula: delayed ~ arrdelay + dephour
##   |--5 LogisticRegression (Estimator)
##   |    <logistic_regression_417e5a9871df> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |      prediction_col: prediction
##   |      probability_col: probability
##   |      raw_prediction_col: rawPrediction
##   |     (Parameters)
##   |      elastic_net_param: 0
##   |      fit_intercept: TRUE
##   |      max_iter: 100
##   |      reg_param: 0
##   |      standardization: TRUE
##   |      threshold: 0.5
##   |      tol: 1e-06
```

## Fit, evaluate, save


1. Fit (train) the pipeline's model

```r
model <- ml_fit(flights_pipeline, model_data$training)
model
```

```
## PipelineModel (Transformer) with 5 stages
## <pipeline_417e407697a7> 
##   Stages 
##   |--1 SQLTransformer (Transformer)
##   |    <dplyr_transformer_417e675dac97> 
##   |     (Parameters -- Column Names)
##   |--2 Binarizer (Transformer)
##   |    <binarizer_417e6cf95ba7> 
##   |     (Parameters -- Column Names)
##   |      input_col: arrdelay
##   |      output_col: delayed
##   |--3 Bucketizer (Transformer)
##   |    <bucketizer_417e70d355f9> 
##   |     (Parameters -- Column Names)
##   |      input_col: crsdeptime
##   |      output_col: dephour
##   |--4 RFormulaModel (Transformer)
##   |    <r_formula_417e441e8089> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |     (Transformer Info)
##   |      formula:  chr "delayed ~ arrdelay + dephour" 
##   |--5 LogisticRegressionModel (Transformer)
##   |    <logistic_regression_417e5a9871df> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |      prediction_col: prediction
##   |      probability_col: probability
##   |      raw_prediction_col: rawPrediction
##   |     (Transformer Info)
##   |      coefficients:  num [1:2] 25.629 -0.194 
##   |      intercept:  num -397 
##   |      num_classes:  int 2 
##   |      num_features:  int 2 
##   |      threshold:  num 0.5
```

2. Use the newly fitted model to perform predictions using `ml_transform()`

```r
predictions <- ml_transform(
  x = model,
  dataset = model_data$testing
)
```

3. Use `group_by()` to see how the model performed

```r
predictions %>%
  group_by(delayed, prediction) %>%
  tally()
```

```
## # A tibble: 2 x 3
##   delayed prediction     n
## *   <dbl>      <dbl> <dbl>
## 1       0          0 55624
## 2       1          1 14564
```

4. Save the model into disk using `ml_save()`

```r
ml_save(model, "saved_model", overwrite = TRUE)
```

```
## Model successfully saved.
```

```r
list.files("saved_model")
```

```
## [1] "metadata" "stages"
```
5. Save the pipeline using `ml_save()`

```r
ml_save(flights_pipeline, "saved_pipeline", overwrite = TRUE)
```

```
## Model successfully saved.
```

```r
list.files("saved_pipeline")
```

```
## [1] "metadata" "stages"
```

6. Close the Spark session

```r
spark_disconnect(sc)
```

```
## NULL
```
## Reload model

*Use the saved model inside a different Spark session*

1. Open a new Spark connection and reload the data

```r
library(sparklyr)
sc <- spark_connect(master = "local", version = "2.0.0")
spark_flights <- spark_read_csv(
  sc,
  name = "flights",
  path = "/usr/share/class/flights/data/",
  memory = FALSE,
  columns = file_columns,
  infer_schema = FALSE
)
```

2. Use `ml_load()` to reload the model directly into the Spark session

```r
reload <- ml_load(sc, "saved_model")
reload
```

```
## PipelineModel (Transformer) with 5 stages
## <pipeline_417e407697a7> 
##   Stages 
##   |--1 SQLTransformer (Transformer)
##   |    <dplyr_transformer_417e675dac97> 
##   |     (Parameters -- Column Names)
##   |--2 Binarizer (Transformer)
##   |    <binarizer_417e6cf95ba7> 
##   |     (Parameters -- Column Names)
##   |      input_col: arrdelay
##   |      output_col: delayed
##   |--3 Bucketizer (Transformer)
##   |    <bucketizer_417e70d355f9> 
##   |     (Parameters -- Column Names)
##   |      input_col: crsdeptime
##   |      output_col: dephour
##   |--4 RFormulaModel (Transformer)
##   |    <r_formula_417e441e8089> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |--5 LogisticRegressionModel (Transformer)
##   |    <logistic_regression_417e5a9871df> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |      prediction_col: prediction
##   |      probability_col: probability
##   |      raw_prediction_col: rawPrediction
##   |     (Transformer Info)
##   |      coefficients:  num [1:2] 25.629 -0.194 
##   |      intercept:  num -397 
##   |      num_classes:  int 2 
##   |      num_features:  int 2 
##   |      threshold:  num 0.5
```


3.  Create a new table called *current*. It needs to pull today's flights

```r
library(lubridate)

current <- tbl(sc, "flights") %>%
  filter(
    month == !! month(now()),
    dayofmonth == !! day(now())
  )

show_query(current)
```

```
## <SQL>
## SELECT *
## FROM `flights`
## WHERE ((`month` = 12.0) AND (`dayofmonth` = 30))
```

4.  Create a new table called *current*. It needs to pull today's flights

```r
head(current)
```

```
## # Source: spark<?> [?? x 31]
##   flightid year  month dayofmonth dayofweek deptime crsdeptime arrtime
## * <chr>    <chr> <chr> <chr>      <chr>     <chr>   <chr>      <chr>  
## 1 6549712  2008  12    30         2         2111    2020       2308   
## 2 6549713  2008  12    30         2         1430    1430       1941   
## 3 6549714  2008  12    30         2         708     700        940    
## 4 6549715  2008  12    30         2         1444    1430       1713   
## 5 6549716  2008  12    30         2         1649    1645       1920   
## 6 6549717  2008  12    30         2         1120    1110       1349   
## # ... with 23 more variables: crsarrtime <chr>, uniquecarrier <chr>,
## #   flightnum <chr>, tailnum <chr>, actualelapsedtime <chr>,
## #   crselapsedtime <chr>, airtime <chr>, arrdelay <chr>, depdelay <chr>,
## #   origin <chr>, dest <chr>, distance <chr>, taxiin <chr>, taxiout <chr>,
## #   cancelled <chr>, cancellationcode <chr>, diverted <chr>,
## #   carrierdelay <chr>, weatherdelay <chr>, nasdelay <chr>,
## #   securitydelay <chr>, lateaircraftdelay <chr>, score <chr>
```

5. Run predictions against the new data set

```r
new_predictions <- ml_transform(
  x = ml_load(sc, "saved_model"),
  dataset = current
)
```

6. Get a quick count of expected delayed flights

```r
new_predictions %>%
  summarise(late_fligths = sum(prediction, na.rm = TRUE))
```

```
## # Source: spark<?> [?? x 1]
##   late_fligths
## *        <dbl>
## 1         3689
```

## Reload pipeline
*Overview of how to use new data to re-fit the pipeline, thus creating a new pipeline model*

1. Use `ml_load()` to reload the pipeline into the Spark session

```r
flights_pipeline <- ml_load(sc, "saved_pipeline")
flights_pipeline
```

```
## Pipeline (Estimator) with 5 stages
## <pipeline_417e407697a7> 
##   Stages 
##   |--1 SQLTransformer (Transformer)
##   |    <dplyr_transformer_417e675dac97> 
##   |     (Parameters -- Column Names)
##   |--2 Binarizer (Transformer)
##   |    <binarizer_417e6cf95ba7> 
##   |     (Parameters -- Column Names)
##   |      input_col: arrdelay
##   |      output_col: delayed
##   |--3 Bucketizer (Transformer)
##   |    <bucketizer_417e70d355f9> 
##   |     (Parameters -- Column Names)
##   |      input_col: crsdeptime
##   |      output_col: dephour
##   |--4 RFormula (Estimator)
##   |    <r_formula_417e441e8089> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |     (Parameters)
##   |      formula: delayed ~ arrdelay + dephour
##   |--5 LogisticRegression (Estimator)
##   |    <logistic_regression_417e5a9871df> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |      prediction_col: prediction
##   |      probability_col: probability
##   |      raw_prediction_col: rawPrediction
##   |     (Parameters)
##   |      elastic_net_param: 0
##   |      fit_intercept: TRUE
##   |      max_iter: 100
##   |      reg_param: 0
##   |      standardization: TRUE
##   |      threshold: 0.5
##   |      tol: 1e-06
```

2. Create a new sample data set using `sample_frac()`

```r
sample <- tbl(sc, "flights") %>%
  sample_frac(0.001) 
```

3. Re-fit the model using `ml_fit()` and the new sample data

```r
new_model <- ml_fit(flights_pipeline, sample)
new_model
```

```
## PipelineModel (Transformer) with 5 stages
## <pipeline_417e407697a7> 
##   Stages 
##   |--1 SQLTransformer (Transformer)
##   |    <dplyr_transformer_417e675dac97> 
##   |     (Parameters -- Column Names)
##   |--2 Binarizer (Transformer)
##   |    <binarizer_417e6cf95ba7> 
##   |     (Parameters -- Column Names)
##   |      input_col: arrdelay
##   |      output_col: delayed
##   |--3 Bucketizer (Transformer)
##   |    <bucketizer_417e70d355f9> 
##   |     (Parameters -- Column Names)
##   |      input_col: crsdeptime
##   |      output_col: dephour
##   |--4 RFormulaModel (Transformer)
##   |    <r_formula_417e441e8089> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |     (Transformer Info)
##   |      formula:  chr "delayed ~ arrdelay + dephour" 
##   |--5 LogisticRegressionModel (Transformer)
##   |    <logistic_regression_417e5a9871df> 
##   |     (Parameters -- Column Names)
##   |      features_col: features
##   |      label_col: label
##   |      prediction_col: prediction
##   |      probability_col: probability
##   |      raw_prediction_col: rawPrediction
##   |     (Transformer Info)
##   |      coefficients:  num [1:2] 27.83 -0.41 
##   |      intercept:  num -430 
##   |      num_classes:  int 2 
##   |      num_features:  int 2 
##   |      threshold:  num 0.5
```

4. Save the newly fitted model 

```r
ml_save(new_model, "new_model", overwrite = TRUE)
```

```
## Model successfully saved.
```

```r
list.files("new_model")
```

```
## [1] "metadata" "stages"
```

5. Disconnect from Spark

```r
spark_disconnect(sc)
```

```
## NULL
```
