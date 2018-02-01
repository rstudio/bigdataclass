# 
# database setup script
#
# expects
# - bzip2 installed on the system (and available on the PATH)
# - to be executed with write privileges in the local directory
# - postgres database listening at localhost:5432
# - rstudio_admin user in the database (password: admin_user_be_careful)
# - rstudio_admin user can create schemas
# - schema "datawarehouse" does not already exist
# - rstudio_dev and rstudio_prod users exist in the database
#
# will
# - download data files
# - write files locally (to flights folder)
# - clean data
# - create "datawarehouse" schema in the database
# - populate "datawarehouse" schema with data
# - write bonus files locally (to bonus folder)

library(odbc);
library(DBI);
library(readr);
library(dplyr);
library(dbplyr);

# download raw data files
dir.create("flights")
flight_file <- "flights/flights_2008.csv" 
flight_bz2 <- paste0(flight_file,".bz2")
if(!file.exists(flight_bz2)){
  download.file("http://stat-computing.org/dataexpo/2009/2008.csv.bz2", flight_bz2)
  system2("bzip2",c("-d",flight_bz2))
}

airport_file <- "flights/airport_lookup.csv"
if(!file.exists(airport_file)){
  download.file("http://stat-computing.org/dataexpo/2009/airports.csv", airport_file)
}

carrier_file <- "flights/carrier_lookup.csv"
if(!file.exists(carrier_file)){
  download.file("http://stat-computing.org/dataexpo/2009/carriers.csv", carrier_file)
}
# read & clean data files

rawdata <- read_csv(flight_file)

print(names(rawdata))
rawdata <- rename_all(rawdata,tolower)
print(names(rawdata))

# Carrier Lookup
raw_carrier <- read_csv(carrier_file)
raw_carrier <- raw_carrier %>% rename(carrier=Code, carriername=Description)

# Airport Lookup
raw_airport <- read_csv(airport_file)
raw_airport <- raw_airport %>% rename(airport=iata, airportname=airport)

# Protect against bad data 
stopifnot(
  nrow(rawdata) > 0
  , nrow(raw_carrier) > 0
  , nrow(raw_airport) > 0
)

print(nrow(rawdata))
print(nrow(raw_carrier))
print(nrow(raw_airport))

# clean up data...
rawdata <- rawdata %>% 
  mutate_if(is.integer,function(x){x[is.na(x)]<-0; return(x)})

raw_carrier <- raw_carrier %>% filter(!is.na(carrier))
raw_carrier <- raw_carrier %>% 
  group_by(carrier) %>% 
  mutate(id=row_number(), maxid=max(id)) %>% 
  filter(id==maxid) %>%
  ungroup() %>%
  select(-id, -maxid)
raw_airport <- raw_airport %>% filter(!is.na(airport))

rawdata <- rawdata %>% filter(
  uniquecarrier %in% raw_carrier$carrier
  , origin %in% raw_airport$airport
  , dest %in% raw_airport$airport
  ) %>%
  mutate(flightid=row_number()) %>%
  select(flightid, everything()) %>%
  mutate(score=as.integer(NA))

uniq_airport <- unique(c(rawdata$origin, rawdata$dest))
uniq_carrier <- unique(rawdata$uniquecarrier)

raw_airport <- raw_airport %>% filter(airport %in% uniq_airport)
raw_carrier <- raw_carrier %>% filter(carrier %in% uniq_carrier)


print(nrow(rawdata))
print(nrow(raw_airport))
print(nrow(raw_carrier))

# Connect to DB
con <- dbConnect(
  odbc::odbc()
  ,driver="PostgreSQL"
  ,host="localhost"
  ,uid="rstudio_admin"
  ,pwd="admin_user_be_careful"
  ,port="5432"
  ,Database="postgres"
);

# Create schema
dbExecute(con,"CREATE SCHEMA datawarehouse;")
dbExecute(con,"SET search_path TO datawarehouse;")

# Write to DB
dbWriteTable(con, "flight", rawdata)
dbWriteTable(con, "carrier", raw_carrier, overwrite=TRUE)
dbWriteTable(con, "airport", raw_airport, overwrite=TRUE)
dbExecute(con, "CREATE TABLE flightscore 
  (
    flightid integer PRIMARY KEY
    , score integer
    , ts timestamp NOT NULL DEFAULT current_timestamp
  );");

# Define Foreign Keys
dbExecute(con,"ALTER TABLE flight ADD CONSTRAINT pk_flight PRIMARY KEY (flightid);")
dbExecute(con,"ALTER TABLE flightscore ADD CONSTRAINT fk_flight FOREIGN KEY
  (flightid) REFERENCES flight(flightid);")

dbExecute(con,"ALTER TABLE carrier ADD CONSTRAINT pk_carrier PRIMARY KEY (carrier);")
dbExecute(con, 
          "ALTER TABLE flight ADD CONSTRAINT fk_carrier FOREIGN KEY 
          (uniquecarrier) REFERENCES carrier(carrier);"
)
dbExecute(con,"ALTER TABLE airport ADD CONSTRAINT pk_airport PRIMARY KEY (airport);")
dbExecute(con,
          "ALTER TABLE flight ADD CONSTRAINT fk_airport_origin FOREIGN KEY
          (origin) REFERENCES airport(airport);"
)
dbExecute(con, 
          "ALTER TABLE flight ADD CONSTRAINT fk_airport_dest FOREIGN KEY
          (dest) REFERENCES airport(airport);"
)

# Define View
flight <- tbl(con,in_schema("datawarehouse","flight"))
carrier <- tbl(con,in_schema("datawarehouse","carrier"))
airport <- tbl(con,in_schema("datawarehouse","airport"))

prep <- flight %>% 
  left_join(carrier, by=c("uniquecarrier"="carrier")) %>%
  left_join(airport %>% 
              rename(name=airportname) %>%
              rename_all(.funs = list(function(x){paste0("origin",x)}))
            , by=c("origin"="originairport")) %>%
  left_join(airport %>% 
              rename(name=airportname) %>%
              rename_all(.funs=list(function(x){paste0("dest",x)}))
            ,by=c("dest"="destairport"))

col_prep <- colnames(prep)

col_carrier <- col_prep %>% stringr::str_subset("carrier")
col_origin <- col_prep %>% stringr::str_subset("origin")
col_dest <- col_prep %>% stringr::str_subset("dest")
col_other <- col_prep[! col_prep %in% c(col_carrier,col_origin,col_dest)]

prep_f <- prep %>% select_at(c(col_carrier,col_origin, col_dest, col_other))

prep_f_sql <- prep_f %>% sql_render() %>% as.character()

dbExecute(con, paste0(
  "CREATE VIEW datawarehouse.vflight AS "
  , prep_f_sql
  , ";"
))

# Grant Privelelges
dbExecute(con, "GRANT USAGE ON SCHEMA datawarehouse TO rstudio_dev, rstudio_prod;")
dbExecute(con, "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA datawarehouse TO rstudio_dev, rstudio_prod;")

# write files per month/year
dir_loc <- "flights/data"
dir.create(dir_loc)
def_df <- expand.grid(year=min(rawdata$year):max(rawdata$year), month=1:12)

lapply(seq_len(nrow(def_df))
       , FUN = function(idx, defdata, folderpath, inputdata) {

        # get month/year 
         rec <- defdata[idx,]
         rec_yr <- defdata[[idx,'year']]
         rec_mo <- defdata[[idx,'month']]
         print(sprintf("Writing file year: %s ",rec_yr))
         print(sprintf("Writing file month: %s ", rec_mo))
        
        # build filename
         filename <- paste0(folderpath,"/flight_",rec_yr,"_",rec_mo,".csv")
         print(sprintf("Filename: %s", filename))

        # write csv (filtered appropriately) 
         write_csv(inputdata %>% filter(year == rec_yr, month == rec_mo)
                   , path=filename)
         print("Done")
         
         invisible(filename)
       }
       , defdata = def_df
       , folderpath = dir_loc
       , inputdata = rawdata)


# Bonus Section --------------------------------------------------

library(gutenbergr)
library(dplyr)

dir.create("bonus")
gutenberg_works()  %>%
  filter(author == "Doyle, Arthur Conan") %>%
  pull(gutenberg_id) %>%
  gutenberg_download() %>%
  pull(text) %>%
  writeLines("bonus/arthur_doyle.txt")

gutenberg_works()  %>%
  filter(author == "Twain, Mark") %>%
  pull(gutenberg_id) %>%
  gutenberg_download() %>%
  pull(text) %>%
  writeLines("bonus/mark_twain.txt")