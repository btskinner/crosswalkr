![](https://img.shields.io/badge/dev-beta-red.svg) [![GitHub
release](https://img.shields.io/github/release/btskinner/crosswalkr.svg)](https://github.com/btskinner/crosswalkr)
[![Travis-CI Build
Status](https://travis-ci.org/btskinner/crosswalkr.svg?branch=master)](https://travis-ci.org/btskinner/crosswalkr)

This package offers a pair of functions, `renamefrom()` and
`encodefrom()`, for renaming and encoding data frames using external
crosswalk files. It is especially useful when constructing master data
sets from multiple smaller data sets that do not name or encode
variables consistently across files. Based on `renamefrom` and
`encodefrom` [Stata commands written by Sally Hudson and
team](https://github.com/slhudson/rename-and-encode).

### Install

Install the latest development version from Github with

    devtools::install_github('btskinner/crosswalkr')

### Dependencies

This package relies on the following packages, available in CRAN:

-   haven
-   labelled
-   readr
-   readxl
-   tibble

Available functions
-------------------

### `renamefrom()`

    library(crosswalkr)

    ## starting data frame
    df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
                     fips = c(21,47,51),
                     region = c('South','South','South'))

    ## crosswalk with to convert old names to new names with labels
    cw <- data.frame(old_name = c('state','fips'),
                     new_name = c('stname','stfips'),
                     label = c('Full state name', 'FIPS code'))

##### Convert old to new using labels in crosswalk file

    df1 <- renamefrom(df, cw, old_name, new_name, label)
    df1

    ##      stname stfips
    ## 1  Kentucky     21
    ## 2 Tennessee     47
    ## 3  Virginia     51

##### Convert old to new using old names as labels

    df2 <- renamefrom(df, cw, old_name, new_name, name_label = TRUE)
    df2

    ##      stname stfips
    ## 1  Kentucky     21
    ## 2 Tennessee     47
    ## 3  Virginia     51

##### Convert old to new, but keep unmatched old names in data frame

    df3 <- renamefrom(df, cw, old_name, new_name, drop_extra = FALSE)
    df3

    ##      stname stfips region
    ## 1  Kentucky     21  South
    ## 2 Tennessee     47  South
    ## 3  Virginia     51  South

### `encodefrom()`

    ## starting data frame
    df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
                     stfips = c(21,47,51),
                     cenregnm = c('South','South','South'))

    ## starting tbl_df
    df_tbl <- tibble::as_data_frame(df)

    ## use state crosswalk data file from package
    cw <- get(data(stcrosswalk))

##### Create new column with factor-encoded values

    df$state2 <- encodefrom(df, state, cw, stname, stfips, stabbr)
    df

    ##       state stfips cenregnm state2
    ## 1  Kentucky     21    South     KY
    ## 2 Tennessee     47    South     TN
    ## 3  Virginia     51    South     VA

##### Create new column with labelled values

    df_tbl$state2 <- encodefrom(df_tbl, state, cw, stname, stfips, stabbr)

##### Create new column with factor-encoded values (ignores the fact that `df_tbl` is a tibble)

    df_tbl$state3 <- encodefrom(df_tbl, state, cw, stname, stfips, stabbr, ignore_tibble = TRUE)

##### Results

    haven::as_factor(df_tbl)

    ## # A tibble: 3 x 5
    ##       state stfips cenregnm state2 state3
    ##      <fctr>  <dbl>   <fctr> <fctr> <fctr>
    ## 1  Kentucky     21    South     KY     KY
    ## 2 Tennessee     47    South     TN     TN
    ## 3  Virginia     51    South     VA     VA

    haven::zap_labels(df_tbl)

    ## # A tibble: 3 x 5
    ##       state stfips cenregnm state2 state3
    ##      <fctr>  <dbl>   <fctr>  <chr> <fctr>
    ## 1  Kentucky     21    South     21     KY
    ## 2 Tennessee     47    South     47     TN
    ## 3  Virginia     51    South     51     VA
