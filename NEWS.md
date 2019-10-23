# crosswalkr 0.2.5

* increment for change in contact information

# crosswalkr 0.2.4

## Bug fix

* Bug fix for #3 (h/t @ekatef), in which columns with uppercase names
  were dropped by default due to internal conflict with `case_ignore`
  and `drop_extra` options.

# crosswalkr 0.2.3

## Bug fix

* Bug fix for issue #2 due to update of [labelled](https://github.com/larmarange/labelled) package to 2.1.0

# crosswalkr 0.2.2

* encoded vector now output in same class as clean values from
  crosswalk file; this means that if the raw variable is a character
  (like state name) and the clean encoding value is an integer (like
  FIPS code), then the new labelled vector will be an integer
  class. This is the logical behavior and should work better with
  transfer to Stata, which only takes labels on numeric classes.  
* new tests

# crosswalkr 0.2.1

* adjustments to account for new **haven** `labelled` classes  
* various improvements and bug fixes

# crosswalkr 0.1.2

* update documentation
* update vignette

# crosswalkr 0.1.1

* Initial CRAN release
