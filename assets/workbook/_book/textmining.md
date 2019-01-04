

# Text mining with sparklyr

For this example, there are two files that will be analyzed.  They are both the full works of Sir Arthur Conan Doyle and Mark Twain.  The files were downloaded from the [Gutenberg Project](https://www.gutenberg.org/) site via the `gutenbergr` package.  Intentionally, no data cleanup was done to the files prior to this analysis.  See the appendix below to see how the data was downloaded and prepared.


```r
readLines("/usr/share/class/bonus/arthur_doyle.txt", 30) 
```


## Data Import

1. Open a Spark session

```r
library(sparklyr)
library(dplyr)

conf <- spark_config()
conf$`sparklyr.cores.local` <- 4
conf$`sparklyr.shell.driver-memory` <- "8G"
conf$spark.memory.fraction <- 0.9

sc <- spark_connect(master = "local", config = conf,version = "2.0.0")
```


2. The `spark_read_text()` is a new function which works like `readLines()` but for `sparklyr`. Use it to read the *mark_twain.txt* file into Spark.

```r
twain_path <- "file:///usr/share/class/bonus/mark_twain.txt"
twain <- spark_read_text(sc, "twain", twain_path) 
```

3. Read the *arthur_doyle.txt* file into Spark

```r
doyle_path <- "file:///usr/share/class/bonus/arthur_doyle.txt"
doyle <- spark_read_text(sc, "doyle", doyle_path) 
```


## Tidying data

1. Add a identification column to each data set.


```r
twain_id <- twain %>% 
  mutate(author = "twain")

doyle_id <- doyle %>%
  mutate(author = "doyle")
```

2. Use `sdf_bind_rows()` to append the two files together

```r
both <- doyle_id %>%
  sdf_bind_rows(twain_id) 

both
```

3. Filter out empty lines


```r
all_lines <- both %>%
  filter(nchar(line) > 0)
```

4. Use Hive's *regexp_replace* to remove punctuation

```r
all_lines <- all_lines %>%
  mutate(line = regexp_replace(line, "[_\"\'():;,.!?\\-]", " ")) 

head(all_lines)
```

## Transform the data

1. Use `ft_tokenizer()` to separate each word. in the line.  It places it in a list column.

```r
word_list <- all_lines %>%
    ft_tokenizer(input_col = "line",
               output_col = "word_list")

head(word_list, 4)
```

2. Remove "stop words" with the `ft_stop_words_remover()` transformer. The list is of stop words Spark uses is available here: https://github.com/apache/spark/blob/master/mllib/src/main/resources/org/apache/spark/ml/feature/stopwords/english.txt


```r
wo_stop <- word_list %>%
  ft_stop_words_remover(input_col = "word_list",
                        output_col = "wo_stop_words")

head(wo_stop, 4)
```

3. Un-nest the tokens inside *wo_stop_words* using `explode()`.  This will create a row per word.

```r
exploded <- wo_stop %>%
  mutate(word = explode(wo_stop_words))

head(exploded)
```

4. Select the *word* and *author* columns, and remove any word with less than 3 characters.

```r
all_words <- exploded %>%
  select(word, author) %>%
  filter(nchar(word) > 2)
  
head(all_words, 4)
```

5. Cache the *all_words* variable using `compute()`  

```r
all_words <- all_words %>%
  compute("all_words")
```


## Data Exploration

1. Words used the most by author


```r
word_count <- all_words %>%
  group_by(author, word) %>%
  tally() %>%
  arrange(desc(n)) 
  
word_count
```

2. Words most used by Twain


```r
twain_most <- word_count %>%
  filter(author == "twain")

twain_most
```

3. Use `wordcloud` to visualize the top 50 words used by Twain


```r
twain_most %>%
  head(50) %>%
  collect() %>%
  with(wordcloud::wordcloud(
    word, 
    n,
    colors = c("#999999", "#E69F00", "#56B4E9","#56B4E9")))
```

4. Words most used by Doyle


```r
doyle_most <- word_count %>%
  filter(author == "doyle")

doyle_most
```

5. Used `wordcloud` to visualize the top 50 words used by Doyle that have more than 5 characters


```r
doyle_most %>%
  filter(nchar(word) > 5) %>%
  head(50) %>%
  collect() %>%
  with(wordcloud::wordcloud(
    word, 
    n,
    colors = c("#999999", "#E69F00", "#56B4E9","#56B4E9")
    ))
```

6. Use `anti_join()` to figure out which words are used by Doyle but not Twain. Order the results by number of words.


```r
doyle_unique <- doyle_most %>%
  anti_join(twain_most, by = "word") %>%
  arrange(desc(n)) 

doyle_unique
```

7. Use `wordcloud` to visualize top 50 records in the previous step

```r
doyle_unique %>%
  head(50) %>%
  collect() %>%
  with(wordcloud::wordcloud(
    word, 
    n,
    colors = c("#999999", "#E69F00", "#56B4E9","#56B4E9")))
```

8. Find out how many times Twain used the word "sherlock"

```r
all_words %>%
  filter(author == "twain",
         word == "sherlock") %>%
  tally()
```

9. Against the `twain` variable, use Hive's *instr* and *lower* to make all ever word lower cap, and then look for "sherlock" in the line

```r
twain %>%
  mutate(line = lower(line)) %>%
  filter(instr(line, "sherlock") > 0) %>%
  pull(line)
```

Most of these lines are in a short story by Mark Twain called [A Double Barrelled Detective Story](https://www.gutenberg.org/files/3180/3180-h/3180-h.htm#link2H_4_0008). As per the [Wikipedia](https://en.wikipedia.org/wiki/A_Double_Barrelled_Detective_Story) page about this story, this is a satire by Twain on the mystery novel genre, published in 1902.



```r
spark_disconnect(sc)
```
