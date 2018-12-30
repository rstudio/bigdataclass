
# Intro to dashboards

<img src="images/shinydashboard-1.PNG" width = 600>



## Basic structure
*Preview a simple `shinydashboard`*

1. Create and preview a simple `shinydashboard` 

```r
ui <- dashboardPage(
  dashboardHeader(title = "Quick Example"),
  dashboardSidebar(selectInput("select", "Selection", c("one", "two"))),
  dashboardBody(
    valueBoxOutput("total"),
    dataTableOutput("monthly")
  )
)

server <- function(input, output, session) {
  output$total <- renderValueBox(valueBox(100, subtitle = "Flights"))
  output$monthly <- renderDataTable(datatable(mtcars))
}

shinyApp(ui, server)
```



## Dropdown data
*Review a technique to populate a dropdown*

1. Use `purrr` to create a list with the correct structure for the `shiny` drop down

```r
airline_list <- carriers %>%  
  select(carrier, carriername) %>%   # In case more fields are added
  collect()  %>%                     # All would be collected anyway
  split(.$carriername) %>%           # Create a list item for each name
  map(~.$carrier)                    # Add the carrier code to each item

head(airline_list)
```

```
## $`AirTran Airways Corporation`
## [1] "FL"
## 
## $`Alaska Airlines Inc.`
## [1] "AS"
## 
## $`Aloha Airlines Inc.`
## [1] "AQ"
## 
## $`American Airlines Inc.`
## [1] "AA"
## 
## $`American Eagle Airlines Inc.`
## [1] "MQ"
## 
## $`Atlantic Southeast Airlines`
## [1] "EV"
```

2. In the app code, replace `c("one", "two", "three")` with `airline_list`


```r
# Goes from this:
dashboardSidebar(selectInput("select", "Selection", c("one", "two"))),
# To this:
dashboardSidebar(selectInput("select", "Selection", airline_list)),
```

3. Re-run the app

## Update dashboard items
*Create base query for the dashboard using `dplyr` and pass the results to the dashboard*

1. Save the base "query" to a variable. It will contain a carrier selection. To transition into `shiny` programming easier, the variable will be a function.

```r
base_dashboard <- function(){
  flights %>%
    filter(uniquecarrier == "DL")
  }

head(base_dashboard())
```

```
## # Source:   lazy query [?? x 31]
## # Database: postgres [rstudio_dev@localhost:/postgres]
##   flightid  year month dayofmonth dayofweek deptime crsdeptime arrtime
##      <int> <dbl> <dbl>      <dbl>     <dbl>   <dbl>      <dbl>   <dbl>
## 1  1158322  2008     2          1         5      NA       1200      NA
## 2  1158341  2008     2          1         5      NA       2045      NA
## 3  1158881  2008     2          1         5      NA        840      NA
## 4  1158686  2008     2          1         5     555        600      NA
## 5  1158779  2008     2          1         5      NA        954      NA
## 6  1159428  2008     2          1         5      NA       1030      NA
## # ... with 23 more variables: crsarrtime <dbl>, uniquecarrier <chr>,
## #   flightnum <dbl>, tailnum <chr>, actualelapsedtime <dbl>,
## #   crselapsedtime <dbl>, airtime <dbl>, arrdelay <dbl>, depdelay <dbl>,
## #   origin <chr>, dest <chr>, distance <dbl>, taxiin <dbl>, taxiout <dbl>,
## #   cancelled <dbl>, cancellationcode <chr>, diverted <dbl>,
## #   carrierdelay <dbl>, weatherdelay <dbl>, nasdelay <dbl>,
## #   securitydelay <dbl>, lateaircraftdelay <dbl>, score <int>
```

3. Use the base query to figure the number of flights for that carrier

```r
base_dashboard() %>%
  tally() %>% 
  pull()
```

```
## integer64
## [1] 451931
```

4. In the app, remove the `100` number and pipe the `dplyr` code into the valueBox() function

```r
# Goes from this:
  output$total <- renderValueBox(valueBox(100, subtitle = "Flights"))
# To this:
  output$total <- renderValueBox(
    base_dashboard() %>%
      tally() %>% 
      pull() %>%
      valueBox(subtitle = "Flights"))
```

5. Create a table with the month name and the number of flights for that month 

```r
base_dashboard() %>%
  group_by(month) %>%
  tally() %>%
  collect() %>%
  mutate(n = as.numeric(n)) %>%
  rename(flights = n) %>%
  arrange(month)
```

```
## # A tibble: 12 x 2
##    month flights
##    <dbl>   <dbl>
##  1     1   38256
##  2     2   36275
##  3     3   39829
##  4     4   37049
##  5     5   36349
##  6     6   37844
##  7     7   39335
##  8     8   38173
##  9     9   36304
## 10    10   38645
## 11    11   36939
## 12    12   36933
```

6. In the app, replace `head(mtcars)` with the piped code, and re-run the app

```r
# Goes from this:
  output$monthly <- renderTable(head(mtcars))
# To this:
  output$monthly <- renderDataTable(datatable(
    base_dashboard() %>%
      group_by(month) %>%
      tally() %>%
      collect() %>%
      mutate(n = as.numeric(n)) %>%
      rename(flights = n) %>%
      arrange(month)))
```

## Integrate the dropdown
*Use `shiny`'s `reactive()` function to integrate the user input in one spot*

1. In the original `base_dashboard()` code, replace `function` with `reactive`, and `"DL"` with `input$select`

```r
# Goes from this
base_dashboard <- function(){
flights %>%
  filter(uniquecarrier == "DL")}
# To this
base_dashboard <- reactive({
  flights %>% 
    filter(uniquecarrier == input$select)})
```

2. Insert the new code right after the `server <- function(input, output, session)` line. The full code should now look like this:

```r
ui <- dashboardPage(
  dashboardHeader(title = "Quick Example"),
  dashboardSidebar(selectInput("select", "Selection", airline_list)),
  dashboardBody(
    valueBoxOutput("total"),
    dataTableOutput("monthly")
  )
)

server <- function(input, output, session) {
  base_dashboard <- reactive({
    flights %>%
      filter(uniquecarrier == input$select)
  })
  output$total <- renderValueBox(
    base_dashboard() %>%
      tally() %>%
      pull() %>%
      valueBox(subtitle = "Flights")
  )
  output$monthly <- renderDataTable(datatable(
    base_dashboard() %>%
      group_by(month) %>%
      tally() %>%
      collect() %>%
      mutate(n = as.numeric(n)) %>%
      rename(flights = n) %>%
      arrange(month)
  ))
}
shinyApp(ui, server)
```

9. Re-run the app

10. Disconnect form database

```r
dbDisconnect(con)
```

