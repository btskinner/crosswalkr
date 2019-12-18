crosswalkr <img src="man/figures/logo.png" align="right" />
===========================================================

[![Travis-CI Build
Status](https://travis-ci.org/btskinner/crosswalkr.svg?branch=master)](https://travis-ci.org/btskinner/crosswalkr)
[![GitHub
release](https://img.shields.io/github/release/btskinner/crosswalkr.svg)](https://github.com/btskinner/crosswalkr)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/crosswalkr)](http://cran.r-project.org/package=crosswalkr)

Overview
--------

This package offers a pair of functions, `renamefrom()` and
`encodefrom()`, for renaming and encoding data frames using external
crosswalk files. It is especially useful when constructing master data
sets from multiple smaller data sets that do not name or encode
variables consistently across files. Based on `renamefrom` and
`encodefrom` [Stata commands written by Sally Hudson and
team](https://github.com/slhudson/rename-and-encode).

Installation
------------

Install the latest release version from CRAN with

    install.packages('crosswalkr')

Install the latest development version from Github with

    devtools::install_github('btskinner/crosswalkr')

Usage
-----

    library(crosswalkr)
    library(dplyr)
    library(haven)

    ## starting data frame
    df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
                     fips = c(21,47,51),
                     region = c('South','South','South'))
    df

    ##       state fips region
    ## 1  Kentucky   21  South
    ## 2 Tennessee   47  South
    ## 3  Virginia   51  South

    ## crosswalk with which to convert old names to new names with labels
    cw <- data.frame(old_name = c('state','fips'),
                     new_name = c('stname','stfips'),
                     label = c('Full state name', 'FIPS code'))
    cw

    ##   old_name new_name           label
    ## 1    state   stname Full state name
    ## 2     fips   stfips       FIPS code

### Renaming

Convert old variable names to new names and add labels from crosswalk.

    df1 <- renamefrom(df, cw_file = cw, raw = old_name, clean = new_name, label = label)
    df1

    ##      stname stfips
    ## 1  Kentucky     21
    ## 2 Tennessee     47
    ## 3  Virginia     51

Convert old variable names to new names using old names as labels
(ignoring labels in crosswalk).

    df2 <- renamefrom(df, cw_file = cw, raw = old_name, clean = new_name, name_label = TRUE)
    df2

    ##      stname stfips
    ## 1  Kentucky     21
    ## 2 Tennessee     47
    ## 3  Virginia     51

Convert old variable names to new names, but keep unmatched old names in
the data frame.

    df3 <- renamefrom(df, cw_file = cw, raw = old_name, clean = new_name, drop_extra = FALSE)
    df3 

    ##      stname stfips region
    ## 1  Kentucky     21  South
    ## 2 Tennessee     47  South
    ## 3  Virginia     51  South

### Encoding

    ## starting data frame
    df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
                     stfips = c(21,47,51),
                     cenregnm = c('South','South','South'))
    df

    ##       state stfips cenregnm
    ## 1  Kentucky     21    South
    ## 2 Tennessee     47    South
    ## 3  Virginia     51    South

    ## use state crosswalk data file from package
    cw <- get(data(stcrosswalk))
    cw

    ## # A tibble: 51 x 7
    ##    stfips stabbr stname               cenreg cenregnm  cendiv cendivnm          
    ##     <int> <chr>  <chr>                 <int> <chr>      <int> <chr>             
    ##  1      1 AL     Alabama                   3 South          6 East South Central
    ##  2      2 AK     Alaska                    4 West           9 Pacific           
    ##  3      4 AZ     Arizona                   4 West           8 Mountain          
    ##  4      5 AR     Arkansas                  3 South          7 West South Central
    ##  5      6 CA     California                4 West           9 Pacific           
    ##  6      8 CO     Colorado                  4 West           8 Mountain          
    ##  7      9 CT     Connecticut               1 Northeast      1 New England       
    ##  8     10 DE     Delaware                  3 South          5 South Atlantic    
    ##  9     11 DC     District of Columbia      3 South          5 South Atlantic    
    ## 10     12 FL     Florida                   3 South          5 South Atlantic    
    ## # … with 41 more rows

Create a new column with factor-encoded values

    df$state2 <- encodefrom(df, var = state, cw_file = cw, raw = stname, clean = stfips, label = stabbr)
    df

    ##       state stfips cenregnm state2
    ## 1  Kentucky     21    South     KY
    ## 2 Tennessee     47    South     TN
    ## 3  Virginia     51    South     VA

Create a new column with labelled values.

    ## convert to tbl_df
    df <- tbl_df(df)
    df$state3 <- encodefrom(df, var = state, cw_file = cw, raw = stname, clean = stfips, label = stabbr)

Create new column with factor-encoded values (ignores the fact that `df`
is a tibble)

    df$state4 <- encodefrom(df, var = state, cw_file = cw, raw = stname, clean = stfips, label = stabbr, ignore_tibble = TRUE)

Show factors with labels:

    as_factor(df)

    ## # A tibble: 3 x 6
    ##   state     stfips cenregnm state2 state3 state4
    ##   <fct>      <dbl> <fct>    <fct>  <fct>  <fct> 
    ## 1 Kentucky      21 South    KY     KY     KY    
    ## 2 Tennessee     47 South    TN     TN     TN    
    ## 3 Virginia      51 South    VA     VA     VA

Show factors without labels:

    zap_labels(df)

    ## # A tibble: 3 x 6
    ##   state     stfips cenregnm state2 state3 state4
    ##   <fct>      <dbl> <fct>    <fct>   <int> <fct> 
    ## 1 Kentucky      21 South    KY         21 KY    
    ## 2 Tennessee     47 South    TN         47 TN    
    ## 3 Virginia      51 South    VA         51 VA
