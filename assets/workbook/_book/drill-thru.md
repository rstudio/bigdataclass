#Dashboard drill-down



<img src="images/shinydashboard-1.PNG" width = 600>




## Add a tabset to the dashboard
*Prepare the `ui` to accept new tabs based on the user's input*

1. Wrap the "output" functions in the **ui** with a `tabPanel()`

```r
# Goes from this
valueBoxOutput("total"),
dataTableOutput("monthly")

# To this
tabPanel(
  valueBoxOutput("total"),
  dataTableOutput("monthly")
  )
```


2. Set the panel's `title` and `value`. The new code should look like this

```r
tabPanel(
  title = "Dashboard", 
  value = "page1", 
  valueBoxOutput("total"),
  dataTableOutput("monthly")
  )
```

3. Wrap that code inside a `tabsetPanel()`, set the `id` to `tabs`


```r
tabsetPanel(
  id = "tabs",
  tabPanel(
    title = "Dashboard",
    value = "page1",
    valueBoxOutput("total"),
    dataTableOutput("monthly")
  )
)
```

4. Re-run the app

## Add interactivity
*Add an click-event that creates a new tab*

1. Set the `selection` and `rownames` in the current `datatable()` function

```r
output$monthly <- renderDataTable(datatable({
  base_dashboard() %>%
    group_by(month) %>%
    tally() %>%
    collect() %>%
    mutate(n = as.numeric(n)) %>%
    rename(flights = n) %>%
    arrange(month)}, 
  list( target = "cell"),    # New code
  rownames = FALSE))         # New code
```

2. Use `observeEvent()` and `appendTab()` to add the interactivity

```r
observeEvent(input$monthly_cell_clicked, {
  appendTab(
    inputId = "tabs", # This is the tabsets panel's ID
    tabPanel(
      "test_new", # This will be the label of the new tab
      renderDataTable(mtcars, rownames = FALSE)
    )
  )
}) 
```

3. Re-run the app

4. Click on a row inside the `datatable` and then select the new tab called `test_new` to see the `mtcars` data

## Add title to the new tab
*Use the input's info to create a custom label*

1. Load the clicked cell's info into a variable, and create a new lable by concatenating the cell's month and the selected airline's code

```r
observeEvent(input$monthly_cell_clicked, {
  cell <- input$monthly_cell_clicked # New code

  if (!is.null(cell$value)) { # New code
    tab_title <- paste0(month.name[cell$value], "_", input$select)
    appendTab(
      inputId = "tabs",
      tabPanel(
        tab_title, # Changed code
        renderDataTable(mtcars, rownames = FALSE)
      )
    )
  }
})
```

2. Re-run the app, and click on one of the month's to confirm that the new label works

3. Use `updateTabsetPanel` to switch the dashboard's focus to the newly created tab. It goes after the `tabPanel()` code

```r
updateTabsetPanel(session, "tabs", selected = tab_title)
```

## pool pakcage
*Improve connectivity using the pool package*

1.Change `dbConnect()` to `dbPool()`

```r
# Goes from this
con <- DBI::dbConnect(odbc::odbc(), "Postgres Dev")

# To this
con <- pool::dbPool(odbc::odbc(), dsn =  "Postgres Dev")
```

2. Add an `onStop()` step to close the pool connection

```r
onStop(function() {
  poolClose(con)
})
```





