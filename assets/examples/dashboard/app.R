library(shinydashboard)
library(shiny)
library(dplyr)
library(rlang)
library(ggplot2)
library(dplyr)
library(dbplyr)
library(DBI)
library(dbplot)
library(purrr)
library(DT)


con <- pool::dbPool(odbc::odbc(), dsn =  "Postgres Dev")
onStop(function() {
  pool::poolClose(con)
})

airports <- tbl(con, in_schema("datawarehouse", "airport"))
flights <- tbl(con, in_schema("datawarehouse", "flight"))
carriers <- tbl(con, in_schema("datawarehouse", "carrier"))


airline_list <- carriers %>%  
  select(carrier, carriername) %>%   
  collect()  %>%                    
  split(.$carriername) %>%          
  map(~.$carrier)    

ui <- dashboardPage(

  dashboardHeader(title = "Quick Example"),
  dashboardSidebar(selectInput("select", "Selection", airline_list)),
  dashboardBody(
    tabsetPanel(id = "tabs",
      tabPanel(
        title = "Dashboard", 
        value = "page1", 
        valueBoxOutput("total"),
        dataTableOutput("monthly")
      )
      )
    )
)

server <- function(input, output, session) {
  
  base_dashboard <- reactive({
    flights %>% 
      filter(uniquecarrier == input$select)})

  output$total <- renderValueBox({
    base_dashboard() %>%
      tally() %>%
      pull() %>%
      valueBox(subtitle = "Flights")})
    
  output$monthly <- renderDataTable(datatable({
    base_dashboard() %>%
      group_by(month) %>%
      tally() %>%
      collect() %>%
      mutate(n = as.numeric(n)) %>%
      rename(flights = n) %>%
      arrange(month)}, 
    list( target = "cell"),
    rownames = FALSE)
    
    )
  
  observeEvent(input$monthly_cell_clicked, {
    
    cell <- input$monthly_cell_clicked
    if(!is.null(cell$value)){
      tab_title <- paste0(month.name[cell$value], "_", input$select)
      appendTab(inputId = "tabs",
                tabPanel(
                  tab_title,
                  DT::renderDataTable({
                    base_dashboard() %>%
                      filter(month == cell$value) %>%
                      select(3:10) %>%
                      head(100) %>%
                      collect() 
                  }, rownames = FALSE)
                ))
      updateTabsetPanel(session, "tabs", selected = tab_title)
    }

  })
  
}
shinyApp(ui, server)