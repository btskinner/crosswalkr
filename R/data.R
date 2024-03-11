#' State crosswalk data set.
#'
#' An example state crosswalk. Includes information for all states
#' plus the District of Columbia.
#'
#' @format A data frame with 51 rows and 7 variables:
#' \describe{
#'   \item{stfips}{Two-digit state FIPS codes}
#'   \item{stabbr}{Two-letter state abbreviation}
#'   \item{stname}{Full state name}
#'   \item{cenreg}{Census region number}
#'   \item{cenregnm}{Census region name}
#'   \item{cendiv}{Census division number}
#'   \item{cendivnm}{Census division name}
#' }
"stcrosswalk"

#' State and territory crosswalk data set.
#'
#' An example state and territory crosswalk. Includes information
#' for all states plus the District of Columbia plus territories.
#'
#' @format A data frame with 69 rows and 10 variables:
#' \describe{
#'   \item{stfips}{Two-digit FIPS codes}
#'   \item{stabbr}{Two-letter abbreviation}
#'   \item{stname}{Full name}
#'   \item{cenreg}{Census region number}
#'   \item{cenregnm}{Census region name}
#'   \item{cendiv}{Census division number}
#'   \item{cendivnm}{Census division name}
#'   \item{is_state}{Indicator for status as state}
#'   \item{is_state_dc}{Indicator for status as state or DC}
#'   \item{status}{1 := Under U.S. sovereignty; 2 := Minor Outlying Islands;
#'      3 := Independent nation under Compact of Free Association with U.S.;
#'      4 := Individual Minor Outlying Islands (within status 2)}
#' }
"sttercrosswalk"
