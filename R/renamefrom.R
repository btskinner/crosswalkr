#' Rename data frame columns using external crosswalk file.
#'
#' @param .data Data frame or tbl_df
#' @param cw_file Either data frame object or string with path to
#'     external crosswalk file, which has columns representing
#'     \code{raw} (current) column names, \code{clean} (new) column
#'     names, and labels (optional). Values in \code{raw} and
#'     \code{clean} columns must be unique (1:1 match) or an error
#'     will be thrown. Acceptable file types include: delimited (.csv,
#'     .tsv, or other), R (.rda, .rdata, .rds), or Stata (.dta).
#' @param raw Name of column in \code{cw_file} that contains column
#'     names of current data frame.
#' @param clean Name of column in \code{cw_file} that contains new
#'     column names.
#' @param label Name of column in \code{cw_file} with labels for
#'     columns.
#' @param delimiter String delimiter used to parse
#'     \code{cw_file}. Only necessary if using a delimited file that
#'     isn't a comma-separated or tab-separated file (guessed by
#'     function based on file ending).
#' @param sheet Specify sheet if \code{cw_file} is an Excel file and
#'     required sheet isn't the first one.
#' @param drop_extra Drop extra columns in current data frame if they
#'     are not matched in \code{cw_file}.
#' @param case_ignore Ignore case when matching current (\code{raw})
#'     column names with new (\code{clean}) column names.
#' @param keep_label Keep current label, if any, on data frame columns
#'     that aren't matched in \code{cw_file}. Default \code{FALSE}
#'     means that unmatched columns have any existing labels set to
#'     \code{NULL}.
#' @param name_label Use old (\code{raw}) column name as new
#'     (\code{clean}) column name label. Cannot be used if
#'     \code{label} option is set.
#' @return Data frame or tbl_df with new column names and labels.
#' @examples
#' df <- data.frame(state = c('Kentucky','Tennessee','Virginia'),
#'                  fips = c(21,47,51),
#'                  region = c('South','South','South'))
#'
#' cw <- data.frame(old_name = c('state','fips'),
#'                  new_name = c('stname','stfips'),
#'                  label = c('Full state name', 'FIPS code'))
#'
#' df1 <- renamefrom(df, cw, old_name, new_name, label)
#' df2 <- renamefrom(df, cw, old_name, new_name, name_label = TRUE)
#' df3 <- renamefrom(df, cw, old_name, new_name, drop_extra = FALSE)
#'
#' @export
renamefrom <- function(.data,
                       cw_file,
                       raw,
                       clean,
                       label = NULL,
                       delimiter = NULL,
                       sheet = NULL,
                       drop_extra = TRUE,
                       case_ignore = TRUE,
                       keep_label = FALSE,
                       name_label = FALSE
                       ) {

    ## evaluate and convert to string
    raw <- deparse(substitute(raw))
    clean <- deparse(substitute(clean))
    label <- if (!missing(label)) { deparse(substitute(label)) }

    ## give to _ version
    renamefrom_(.data, cw_file, raw, clean, label, delimiter, sheet,
                drop_extra, case_ignore, keep_label, name_label)

}

#' @describeIn renamefrom Standard evaluation version of
#'     \code{\link{renamefrom}} (\code{raw}, \code{clean}, and
#'     \code{label} must be strings when using this version)
#'
#' @export
renamefrom_ <- function(.data,
                        cw_file,
                        raw,
                        clean,
                        label = NULL,
                        delimiter = NULL,
                        sheet = NULL,
                        drop_extra = TRUE,
                        case_ignore = TRUE,
                        keep_label = FALSE,
                        name_label = FALSE
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
    if (!is.null(label)) { confirm_col(cw, label, 'm1') }

    ## verify that raw and clean are unique in crosswalk file (1:1 mapping)
    check_dups(cw, raw, 'm1')
    check_dups(cw, clean, 'm1')

    ## get starting names from dataset and crosswalk
    names_d <- names(.data)
    names_r <- cw[[raw]]

    ## ignore case by setting data and raw names to lower
    if (case_ignore) {
        names_d <- tolower(names_d)
        names_r <- tolower(names_r)
    }

    ## drop unmatched names
    if (drop_extra) {
        .data <- .data[names_d %in% names_r]
        names_d <- names(.data)
        if (case_ignore) { names_d <- tolower(names_d) }
    }

    ## apply new names, leaving unmatched old names alone
    mask <- match(names_d, names_r, nomatch = 0)
    new_names <- cw[[clean]][mask]
    names(.data)[mask != 0] <- new_names

    ## lists
    label_list <- list()

    ## apply new labels
    if (!is.null(label) || name_label) {

        mask <- match(names(.data), cw[[clean]], nomatch = 0)

        ## get labels
        if (!is.null(label)) {

            ## labels: new from crosswalk column
            new_labels <- cw[[label]][mask]

        } else {

            ## labels: old name
            new_labels <- cw[[raw]][mask]

        }

        ## create list linking new names to labels
        for (i in 1:length(new_labels)) {
            label_list[[new_names[i]]] <- new_labels[[i]]
        }

        ## label
        labelled::var_label(.data) <- label_list

    }

    ## erase old labels
    if (!keep_label) {

        ## get extra column names (if they exist)
        extra_ <- names(.data)[!(names(.data) %in% names(label_list))]

        ## if there are extra names...
        if (!identical(extra_, character(0))) {

            null_label_list <- list()
            for (i in 1:length(extra_)) {
                null_label_list[extra_[i]] <- list(NULL)
            }

            ## set to NULL
            labelled::var_label(.data) <- null_label_list

        }
    }

    ## return data frame
    return(.data)

}


