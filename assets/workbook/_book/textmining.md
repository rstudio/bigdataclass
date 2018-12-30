

# Text mining with sparklyr

### Data source

For this example, there are two files that will be analyzed.  They are both the full works of Sir Arthur Conan Doyle and Mark Twain.  The files were downloaded from the [Gutenberg Project](https://www.gutenberg.org/) site via the `gutenbergr` package.  Intentionally, no data cleanup was done to the files prior to this analysis.  See the appendix below to see how the data was downloaded and prepared.


```r
readLines("/usr/share/class/bonus/arthur_doyle.txt", 30) 
```

```
##  [1] "THE RETURN OF SHERLOCK HOLMES,"                  
##  [2] ""                                                
##  [3] "A Collection of Holmes Adventures"               
##  [4] ""                                                
##  [5] ""                                                
##  [6] "by Sir Arthur Conan Doyle"                       
##  [7] ""                                                
##  [8] ""                                                
##  [9] ""                                                
## [10] ""                                                
## [11] "CONTENTS:"                                       
## [12] ""                                                
## [13] "     The Adventure Of The Empty House"           
## [14] ""                                                
## [15] "     The Adventure Of The Norwood Builder"       
## [16] ""                                                
## [17] "     The Adventure Of The Dancing Men"           
## [18] ""                                                
## [19] "     The Adventure Of The Solitary Cyclist"      
## [20] ""                                                
## [21] "     The Adventure Of The Priory School"         
## [22] ""                                                
## [23] "     The Adventure Of Black Peter"               
## [24] ""                                                
## [25] "     The Adventure Of Charles Augustus Milverton"
## [26] ""                                                
## [27] "     The Adventure Of The Six Napoleons"         
## [28] ""                                                
## [29] "     The Adventure Of The Three Students"        
## [30] ""
```


## Data Import

1. Open a Spark session

```r
library(sparklyr)
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
conf <- spark_config()
conf$`sparklyr.cores.local` <- 4
conf$`sparklyr.shell.driver-memory` <- "8G"
conf$spark.memory.fraction <- 0.9

sc <- spark_connect(master = "local", config = conf,version = "2.0.0")
```


1. The `spark_read_text()` is a new function which works like `readLines()` but for `sparklyr`. Use it to read the *mark_twain.txt* file into Spark.

```r
twain_path <- paste0("file:///usr/share/class/bonus/mark_twain.txt")
twain <-  spark_read_text(sc, "twain", twain_path) 
```

2. Read the *arthur_doyle.txt* file into Spark

```r
doyle_path <-  paste0("file:///usr/share/class/bonus/arthur_doyle.txt")
doyle <-  spark_read_text(sc, "doyle", doyle_path) 
```


## Prepare the data

1. Use `sdf_bind_rows()` to append the two files together

```r
all_words <- doyle %>%
  mutate(author = "doyle") %>%
  sdf_bind_rows({
    twain %>%
      mutate(author = "twain")
  }) %>%
  filter(nchar(line) > 0)
```

2. Use Hive's *regexp_replace* to remove punctuation

```r
all_words <- all_words %>%
  mutate(line = regexp_replace(line, "[_\"\'():;,.!?\\-]", " ")) 
```

3. Use `ft_tokenizer()` to separate each word. 

```r
all_words <- all_words %>%
    ft_tokenizer(input.col = "line",
               output.col = "word_list")
```

```
## Warning: The parameter `input.col` is deprecated and will be removed in a
## future release. Please use `input_col` instead.
```

```
## Warning: The parameter `output.col` is deprecated and will be removed in a
## future release. Please use `output_col` instead.
```

```r
head(all_words, 4)
```

```
## # Source: spark<?> [?? x 3]
##   line                              author word_list 
## * <chr>                             <chr>  <list>    
## 1 "THE RETURN OF SHERLOCK HOLMES "  doyle  <list [5]>
## 2 A Collection of Holmes Adventures doyle  <list [5]>
## 3 by Sir Arthur Conan Doyle         doyle  <list [5]>
## 4 "CONTENTS "                       doyle  <list [1]>
```

4. Remove "stop words" with the `ft_stop_words_remover()` transformer

```r
all_words <- all_words %>%
  ft_stop_words_remover(input.col = "word_list",
                        output.col = "wo_stop_words")
```

```
## Warning: The parameter `input.col` is deprecated and will be removed in a
## future release. Please use `input_col` instead.
```

```
## Warning: The parameter `output.col` is deprecated and will be removed in a
## future release. Please use `output_col` instead.
```

```r
head(all_words, 4)
```

```
## # Source: spark<?> [?? x 4]
##   line                              author word_list  wo_stop_words
## * <chr>                             <chr>  <list>     <list>       
## 1 "THE RETURN OF SHERLOCK HOLMES "  doyle  <list [5]> <list [3]>   
## 2 A Collection of Holmes Adventures doyle  <list [5]> <list [3]>   
## 3 by Sir Arthur Conan Doyle         doyle  <list [5]> <list [4]>   
## 4 "CONTENTS "                       doyle  <list [1]> <list [1]>
```

5. Un-nest the tokens with **explode** 

```r
all_words <- all_words %>%
  mutate(word = explode(wo_stop_words)) %>%
  select(word, author) %>%
  filter(nchar(word) > 2)
  
head(all_words, 4)
```

```
## # Source: spark<?> [?? x 2]
##   word       author
## * <chr>      <chr> 
## 1 return     doyle 
## 2 sherlock   doyle 
## 3 holmes     doyle 
## 4 collection doyle
```

6. Cache the *all_words* variable using `compute()`  

```r
all_words <- all_words %>%
  compute("all_words")
```


## Data Analysis

1. Words used the most by author


```r
word_count <- all_words %>%
  group_by(author, word) %>%
  tally() %>%
  arrange(desc(n)) 
  
word_count
```

```
## # A tibble: 10 x 3
##    author word      n
##  * <chr>  <chr> <dbl>
##  1 twain  one   20028
##  2 doyle  upon  16482
##  3 twain  would 15735
##  4 doyle  one   14534
##  5 doyle  said  13716
##  6 twain  said  13204
##  7 twain  could 11301
##  8 doyle  would 11300
##  9 twain  time  10502
## 10 doyle  man   10478
```

2. Figure out which words are used by Doyle but not Twain


```r
doyle_unique <- filter(word_count, author == "doyle") %>%
  anti_join(filter(word_count, author == "twain"), by = "word") %>%
  arrange(desc(n)) %>%
  compute("doyle_unique")

doyle_unique
```

```
## # A tibble: 10 x 3
##    author word          n
##  * <chr>  <chr>     <dbl>
##  1 doyle  nigel       972
##  2 doyle  alleyne     500
##  3 doyle  ezra        421
##  4 doyle  maude       337
##  5 doyle  aylward     336
##  6 doyle  catinat     301
##  7 doyle  sharkey     281
##  8 doyle  lestrade    280
##  9 doyle  summerlee   248
## 10 doyle  congo       211
```

3. Use `wordcloud` to visualize the data in the previous step

```r
doyle_unique %>%
  head(100) %>%
  collect() %>%
  with(wordcloud::wordcloud(
    word, 
    n,
    colors = c("#999999", "#E69F00", "#56B4E9","#56B4E9")))
```

<img src="textmining_files/figure-html/unnamed-chunk-13-1.png" width="672" />

4. Find out how many times Twain used the word "sherlock"

```r
all_words %>%
  filter(author == "twain",
         word == "sherlock") %>%
  tally()
```

```
## # Source: spark<?> [?? x 1]
##       n
## * <dbl>
## 1    16
```

5. Against the `twain` variable, use Hive's *instr* and *lower* to make all ever word lower cap, and then look for "sherlock" in the line

```r
twain %>%
  mutate(line = lower(line)) %>%
  filter(instr(line, "sherlock") > 0) %>%
  pull(line)
```

```
##  [1] "late sherlock holmes, and yet discernible by a member of a race charged"  
##  [2] "sherlock holmes."                                                         
##  [3] "\"uncle sherlock! the mean luck of it!--that he should come just"         
##  [4] "another trouble presented itself. \"uncle sherlock 'll be wanting to talk"
##  [5] "flint buckner's cabin in the frosty gloom. they were sherlock holmes and" 
##  [6] "\"uncle sherlock's got some work to do, gentlemen, that 'll keep him till"
##  [7] "\"by george, he's just a duke, boys! three cheers for sherlock holmes,"   
##  [8] "he brought sherlock holmes to the billiard-room, which was jammed with"   
##  [9] "of interest was there--sherlock holmes. the miners stood silent and"      
## [10] "the room; the chair was on it; sherlock holmes, stately, imposing,"       
## [11] "\"you have hunted me around the world, sherlock holmes, yet god is my"    
## [12] "\"if it's only sherlock holmes that's troubling you, you needn't worry"   
## [13] "they sighed; then one said: \"we must bring sherlock holmes. he can be"   
## [14] "i had small desire that sherlock holmes should hang for my deeds, as you" 
## [15] "\"my name is sherlock holmes, and i have not been doing anything.\""      
## [16] "late sherlock holmes, and yet discernible by a member of a race charged"
```

Most of these lines are in a short story by Mark Twain called [A Double Barrelled Detective Story](https://www.gutenberg.org/files/3180/3180-h/3180-h.htm#link2H_4_0008). As per the [Wikipedia](https://en.wikipedia.org/wiki/A_Double_Barrelled_Detective_Story) page about this story, this is a satire by Twain on the mystery novel genre, published in 1902.



```r
spark_disconnect(sc)
```

```
## NULL
```
