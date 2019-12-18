#' Encode data frame column using external crosswalk file.
#'
#' @param .data Data frame or tbl_df
#' @param var Column name of vector to be encoded
#' @param cw_file Either data frame object or string with path to
#'     external crosswalk file, including path, which has columns
#'     representing \code{raw} (current) vector values, \code{clean}
#'     (new) vector values, and \code{label}s for values. Values in
#'     \code{raw} and \code{clean} columns must be unique (1:1 match)
#'     or an error will be thrown. Acceptable file types include:
#'     delimited (.csv, .tsv, or other), R (.rda, .rdata, .rds), or
#'     Stata (.dta).
#' @param raw Name of column in \code{cw_file} that contains values in
#'     current vector.
#' @param clean Name of column in \code{cw_file} that contains new
#'     values for vector.
#' @param label Name of column in \code{cw_file} with labels for new
#'     values.
#' @param delimiter String delimiter used to parse
#'     \code{cw_file}. Only necessary if using a delimited file that
#'     isn't a comma-separated or tab-separated file (guessed by
#'     function based on file ending).
#' @param sheet Specify sheet if \code{cw_file} is an Excel file and
#'     required sheet isn't the first one.
#' @param case_ignore Ignore case when matching current (\code{raw})
#'     vector name with new (\code{clean}) column name.
#' @param ignore_tibble Ignore \code{.data} status as tbl_df and
#'     return vector as a factor rather than labelled vector.
#' @return Vector that is either a factor or labelled, depending on
#'     data input and options
#' @examples
#' df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
#'                  stfips = c(21,47,51),
#'                  cenregnm = c('South','South','South'))
#'
#' df_tbl <- tibble::as_tibble(df)
#'
#' cw <- get(data(stcrosswalk))
#'
#' df$state2 <- encodefrom(df, state, cw, stname, stfips, stabbr)
#' df_tbl$state2 <- encodefrom(df_tbl, state, cw, stname, stfips, stabbr)
#' df_tbl$state3 <- encodefrom(df_tbl, state, cw, stname, stfips, stabbr,
#'                             ignore_tibble = TRUE)
#'
#' haven::as_factor(df_tbl)
#' haven::zap_labels(df_tbl)
#' @export
encodefrom <- function(.data,
                       var,
                       cw_file,
                       raw,
                       clean,
                       label,
                       delimiter = NULL,
                       sheet = NULL,
                       case_ignore = TRUE,
                       ignore_tibble = FALSE
                       ) {

    ## evaluate and convert to string
    var <- deparse(substitute(var))
    raw <- deparse(substitute(raw))
    clean <- deparse(substitute(clean))
    label <- deparse(substitute(label))

    ## give to _ version
    encodefrom_(.data, var, cw_file, raw, clean, label, delimiter, sheet,
                case_ignore, ignore_tibble)

}

#' @describeIn encodefrom Standard evaluation version of
#'     \code{\link{encodefrom}} (\code{var}, \code{raw}, \code{clean},
#'     and \code{label} must be strings when using this version)
#'
#' @export
encodefrom_ <- function(.data,
                        var,
                        cw_file,
                        raw,
                        clean,
                        label,
                        delimiter = NULL,
                        sheet = NULL,
                        case_ignore = TRUE,
                        ignore_tibble = FALSE
                        ) {

    ## read in crosswalk file if string or load if in memory
    if (is.character(cw_file)) { cw <- get_cw_file(cw_file, delimiter, sheet) }
    else { cw <- cw_file }

    ## convert everything to character
    .data[] <- lapply(.data, factor_to_character)
    cw[] <- lapply(cw, factor_to_character)

    ## confirm columns are in crosswalk
    confirm_col(cw, raw, 'm1')
    confirm_col(cw, clean, 'm1')
    confirm_col(cw, label, 'm1')

    ## verify that raw values are unique in crosswalk file
    check_dups(cw = cw, column_1 = raw, message_code = 'm2')
    ## verify that raw values are >= clean values
    check_nums(cw = cw, column_1 = raw, column_2 = clean)
    ## verify that clean and label values map 1:1 in crosswalk file
    check_dups(cw = cw, column_1 = clean, column_2 = label, message_code = 'm3')

    ## ignore case by setting names and var to lower
    if (case_ignore) {
        names(.data) <- tolower(names(.data))
        var <- tolower(var)
    }

    ## confirm var in data
    confirm_col(.data, var, 'm2')

    ## get vector of values
    val_vec <- .data[[var]]

    ## convert raw to clean values
    mask <- match(val_vec, cw[[raw]], nomatch = 0)
    val_vec[mask != 0] <- cw[[clean]][mask]

    ## convert new clean values to type found in crosswalk
    class(val_vec) <- class(cw[[clean]])

    if (tibble::is_tibble(.data) && !ignore_tibble) {

        ## set up labels for labeller
        val_labels <- methods::as(unique(cw[[clean]]), typeof(val_vec))
        names(val_labels) <- unique(cw[[label]])

        ## label vector
        val_vec_l <- labelled::labelled(val_vec, labels = val_labels)

        ## return vector as labelled vector
        return(val_vec_l)

    } else {

        ## get unique levels and labels (assumed in order)
        new_lev <- unique(cw[[clean]])
        new_lab <- cw[[label]][match(new_lev, cw[[clean]])]

        ## convert to factor
        val_vec_f <- factor(val_vec, levels = new_lev, labels = new_lab)

        ## return vector as true factor
        return(val_vec_f)
    }
}
