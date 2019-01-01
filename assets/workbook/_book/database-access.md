

# Access a database



## Connect to a database

*The simpliest way to connect to a database.  More complex examples will be examined later in the class.*

1. Click on the `Connections` tab

2. Click on the `New Connection` button

<img src="images/connections-tab.PNG" width = 600>

3. Select `Postgres Dev`

<img src="images/postgres-dsn.PNG" width = 300>

4. Click OK

<img src="images/new-connection.PNG" width = 300>


## Explore the database using the RStudio IDE

*Becoming familiar with the new interface for databases inside the RStudio IDE*

1. Expand the `datawarehouse` schema

2. Expand the `airport` table

3. Click on the table icon to the right of the `airport` table 

4. *(Optional)* Expand and explore the other tables

5. Click on the *disconnect* icon to close the connection

<img src="images/connected.PNG" width = 500>


## List drivers and DSNs 

*Learn how to use the `odbc` package to get DB info from your machine*

1. To get a list of drivers available in the server

```r
library(odbc)

odbcListDrivers()[1:2]
```

```
##             name attribute
## 1 AmazonRedshift    Driver
## 2           Hive    Driver
## 3         Impala    Driver
## 4         Oracle    Driver
## 5     PostgreSQL    Driver
## 6     Salesforce    Driver
## 7      SQLServer    Driver
## 8       Teradata    Driver
```

2. Click on the *ellipsis* button located in the **Files** tab

<img src="images/ellipsis.PNG" width = 300>

3. Type: `/etc`

<img src="images/gotofolder.PNG" width = 300>

4. Locate and open the `odbcinst.ini` file

5. To see a list of DSNs available in the server


```r
odbcListDataSources()
```

```
##            name description
## 1  Postgres Dev  PostgreSQL
## 2 Postgres Prod  PostgreSQL
```

6. Using the *ellipsis* button again, navigate to `/etc/odbc.ini`

## Connect to a database using code

*Use the `odbc` package along with `DBI` to open a connection to a database*

1. Run the following code to connect

```r
library(DBI)
con <- dbConnect(odbc::odbc(), "Postgres Dev")
```

2. Use `dbListTables()` to retrieve a list of tables

```r
dbListTables(con)
```

```
## [1] "airport"     "carrier"     "flight"      "flightscore" "vflight"
```

3. Use `dbGetQuery()` to run a quick query

```r
odbc::dbGetQuery(con, "SELECT * FROM datawarehouse.airport LIMIT 10")
```

```
##    airport                 airportname          city state country
## 1      ABE Lehigh Valley International     Allentown    PA     USA
## 2      ABI            Abilene Regional       Abilene    TX     USA
## 3      ABQ   Albuquerque International   Albuquerque    NM     USA
## 4      ABY  Southwest Georgia Regional        Albany    GA     USA
## 5      ACK          Nantucket Memorial     Nantucket    MA     USA
## 6      ACT               Waco Regional          Waco    TX     USA
## 7      ACV                      Arcata Arcata/Eureka    CA     USA
## 8      ACY Atlantic City International Atlantic City    NJ     USA
## 9      ADK                        Adak          Adak    AK     USA
## 10     ADQ                      Kodiak        Kodiak    AK     USA
##         lat       long
## 1  40.65236  -75.44040
## 2  32.41132  -99.68190
## 3  35.04022 -106.60919
## 4  31.53552  -84.19447
## 5  41.25305  -70.06018
## 6  31.61129  -97.23052
## 7  40.97812 -124.10862
## 8  39.45758  -74.57717
## 9  51.87796 -176.64603
## 10 57.74997 -152.49386
```

4. Use the SQL chunk

```sql
SELECT * FROM datawarehouse.airport LIMIT 10
```


<div class="knitsql-table">


Table: (\#tab:unnamed-chunk-6)Displaying records 1 - 10

airport   airportname                   city            state   country         lat         long
--------  ----------------------------  --------------  ------  --------  ---------  -----------
ABE       Lehigh Valley International   Allentown       PA      USA        40.65236    -75.44040
ABI       Abilene Regional              Abilene         TX      USA        32.41132    -99.68190
ABQ       Albuquerque International     Albuquerque     NM      USA        35.04022   -106.60919
ABY       Southwest Georgia Regional    Albany          GA      USA        31.53552    -84.19447
ACK       Nantucket Memorial            Nantucket       MA      USA        41.25305    -70.06018
ACT       Waco Regional                 Waco            TX      USA        31.61129    -97.23052
ACV       Arcata                        Arcata/Eureka   CA      USA        40.97812   -124.10862
ACY       Atlantic City International   Atlantic City   NJ      USA        39.45758    -74.57717
ADK       Adak                          Adak            AK      USA        51.87796   -176.64603
ADQ       Kodiak                        Kodiak          AK      USA        57.74997   -152.49386

</div>

5. Use the `output.var` option to load results to a variable

```sql
SELECT * FROM datawarehouse.airport LIMIT 10
```

6. Test the variable

```r
sql_top10
```

```
##    airport                 airportname          city state country
## 1      ABE Lehigh Valley International     Allentown    PA     USA
## 2      ABI            Abilene Regional       Abilene    TX     USA
## 3      ABQ   Albuquerque International   Albuquerque    NM     USA
## 4      ABY  Southwest Georgia Regional        Albany    GA     USA
## 5      ACK          Nantucket Memorial     Nantucket    MA     USA
## 6      ACT               Waco Regional          Waco    TX     USA
## 7      ACV                      Arcata Arcata/Eureka    CA     USA
## 8      ACY Atlantic City International Atlantic City    NJ     USA
## 9      ADK                        Adak          Adak    AK     USA
## 10     ADQ                      Kodiak        Kodiak    AK     USA
##         lat       long
## 1  40.65236  -75.44040
## 2  32.41132  -99.68190
## 3  35.04022 -106.60919
## 4  31.53552  -84.19447
## 5  41.25305  -70.06018
## 6  31.61129  -97.23052
## 7  40.97812 -124.10862
## 8  39.45758  -74.57717
## 9  51.87796 -176.64603
## 10 57.74997 -152.49386
```


7. Disconnect from the database using `dbDisconnect()`

```r
dbDisconnect(con)
```

## Connect to a database without a DSN
*A more complex way of connecting to a database, using best practices: http://db.rstudio.com/best-practices/managing-credentials/#prompt-for-credentials *


1. Use the following code to start a new connection that does not use the pre-defined DSN

```r
con <- dbConnect(
  odbc::odbc(),
  Driver = "PostgreSQL",
  Server = "localhost",
  UID    = rstudioapi::askForPassword("Database user"),
  PWD    = rstudioapi::askForPassword("Database password"),
  Port = 5432,
  Database = "postgres"
)
```

2. When prompted, type in **rstudio_dev** for the user, and **dev_user** as the password

3. Disconnect from the database using `dbDisconnect()`

```r
dbDisconnect(con)
```

```
## Warning: Connection already closed.
```


## Secure credentials in a file

*Credentials can be saved in a YAML file and then read using the `config` package: http://db.rstudio.com/best-practices/managing-credentials/#stored-in-a-file-with-config *

1. Open and explore the `config.yml` file available in your working directory

2. Load the `datawarehouse-dev` vaelus to a variable

```r
dw <- config::get("datawarehouse-dev")
```

3. Check that the variable loaded propery, by checking the `driver` value

```r
dw$driver
```

```
## [1] "PostgreSQL"
```
4. Use info in the config.yml file to connect to the database

```r
con <- dbConnect(odbc::odbc(),
   Driver = dw$driver,
   Server = dw$server,
   UID    = dw$uid,
   PWD    = dw$pwd,
   Port   = dw$port,
   Database = dw$database
)
```

5. Disconnect from the database using `dbDisconnect()`

```r
dbDisconnect(con)
```



## Environment variables
*Use .Renviron file to store credentials*

1. Open and explore the `.Renviron` file available in your working directory

2. Confirm that the environment variables are loaded by using `Sys.getenv()`

```r
Sys.getenv("uid")
```

```
## [1] "rstudio_dev"
```

3. Pass the credentials using the environment variables

```r
con <- dbConnect(
  odbc::odbc(),
  Driver = "PostgreSQL",
  Server = "localhost",
  UID    = Sys.getenv("uid"),
  PWD    = Sys.getenv("pwd"),
  Port = 5432,
  Database = "postgres"
)
```

4. Disconnect from the database using `dbDisconnect()`

```r
dbDisconnect(con)
```


## Use options()
*Set options() in a separate R script*

1. Open and explore the `options.R` script available in your working directory

2. Source the `options.R` script

```r
source("options.R")
```

3. Confirm that the environment variables are loaded by using `Sys.getenv()`

```r
getOption("database_userid")
```

```
## [1] "rstudio_dev"
```

4. Pass the credentials using the environment variables

```r
con <- dbConnect(
  odbc::odbc(),
  Driver = "PostgreSQL",
  Server = "localhost",
  UID    = getOption("database_userid"),
  PWD    = getOption("database_password"),
  Port = 5432,
  Database = "postgres"
)
```

5. Disconnect from the database using `dbDisconnect()`

```r
dbDisconnect(con)
```

```
## Warning: Connection already closed.
```
