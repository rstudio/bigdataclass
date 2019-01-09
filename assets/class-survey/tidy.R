library(tidyverse)

add_conf <- function(name, size, file) {
  list(
    name = name,
    size = size,
    file = file
  )
}

response_files <- list(
  add_conf(2018, 88, "responses-2018.csv"),
  add_conf(2019, 90, "responses-2019.csv")
)

all <- map_df(
  response_files, 
  ~ {
    read_csv(.x$file) %>%
      gather(timestamp) %>%
      mutate(conference = .x$name) %>%
      rename(
        question = timestamp,
        answer = value) %>%
      filter(question != "Timestamp") %>%
      separate(question, c("group1", "group2"), "\\[") %>%
      mutate(
        group2 = substr(group2, 1, nchar(group2)-1),
        score = -1
      ) %>%
      mutate(question = ifelse(is.na(group2), group1, group2)) %>%
      select(conference, question, answer, score, group1, group2)
    
  }) 

tidy_responses <- all %>%
  mutate(score = case_when(
    answer == "I don't use it" ~ 0,
    answer == "I use it occasionally" ~ 1,
    answer == "I use it most days" ~ 2,
    answer == "I can't live without it" ~ 3,
    answer == "I'm the one that folks come to for help" ~ 4,
    TRUE ~ score
  ))

tidy_responses <- tidy_responses %>%
  mutate(score = case_when(
    answer == "Enough to make me dangerous" ~ 0,
    answer == "Enough to help the guy that knows enough to be dangerous" ~ 1,
    answer == "Enough to stop being dangerous" ~ 2,
    answer == "Enough to write an R package for my company's use" ~ 3,
    answer == "Enough to publish an R package on CRAN" ~ 4,
    TRUE ~ score
  ))

tidy_responses <- tidy_responses %>%
  mutate(score = case_when(
    answer == "Never" ~ 0,
    answer == "Occasionally" ~ 1,
    answer == "Most Days" ~ 2,
    answer == "Always" ~ 3,
    answer == "Ninja" ~ 4,
    TRUE ~ score
  ))

tidy_responses <- tidy_responses %>%
  mutate(score = case_when(
    answer == "I'm not sure what this is" ~ 0,
    answer == "I've done it once or twice" ~ 1,
    answer == "I do that on occasion" ~ 2,
    answer == "I do that very often" ~ 3,
    answer == "Anytime, anywhere!" ~ 4,
    TRUE ~ score
  ))

tidy_responses <- tidy_responses %>%
  mutate(score = case_when(
    answer == "Not even close - We've had some conversations about it, but nothing has been done yet" ~ 0,
    answer == "On the road map - We'll have one soon, hopefully" ~ 1,
    answer == "Under construction - We are working through a POC today" ~ 2,
    answer == "Silo - There's a Data Lake somewhere in the company, but we have no access" ~ 3,
    answer == "Early days - Passed the POC phase, but not fully there" ~ 4,
    answer == "Getting there - It's used for certain operations" ~ 5,
    answer == "Mature - We use it for a lot of things" ~ 6,
    answer == "Fully mature - We use it for everything" ~ 7,
    TRUE ~ score
  ))

rm(all)
rm(add_conf)
rm(response_files)

