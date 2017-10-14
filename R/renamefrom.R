#' Rename data frame columns using external crosswalk file.
#'
#' @param .data Data frame
#' @param cw_file External crosswalk file with columns representing
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
#'     columns (default = \code{NULL}).
#' @param delimiter String delimiter used to parse
#'     \code{cw_file}. Only necessary if using a delimited file that
#'     isn't a comma-separated or tab-separated file (guessed by
#'     function based on file ending) (default = \code{NULL}).
#' @param sheet Specify sheet if \code{cw_file} is an Excel file and
#'     required sheet isn't the first one (default = \code{NULL}).
#' @param drop_extra Drop extra columns in current data frame if they
#'     are not matched in \code{cw_file} (default = \code{NULL}).
#' @param case_ignore Ignore case when matching current (\code{raw})
#'     column names with new (\code{clean}) column names (default =
#'     \code{TRUE}).
#' @param keep_label Keep current label, if any, on data frame columns
#'     that aren't matched in \code{cw_file}. Default \code{FALSE}
#'     means that unmatched columns have any existing labels set to
#'     \code{NULL}.
#' @param name_label Use old (\code{raw}) column name as new
#'     (\code{clean}) column name label. Cannot be used if
#'     \code{label} option is set.
#' @return Data frame with new column names and labels.
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
    label <- if (!is.null(label)) { deparse(substitute(label)) }

    ## give to _ version
    renamefrom_(.data, cw_file, raw, clean, label, delimiter, sheet,
                drop_extra, case_ignore, keep_label, name_label)

}


#' Standard evaluation version of \code{\link{renamefrom}}
#'
#' @inheritParams renamefrom
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

    ## figure out crosswalk file type using file ending
    ext <- tolower(tools::file_ext(cw_file))

    ## read based on filetype
    if (ext == 'xls' || ext == 'xlsx') {

        ## excel
        sheet <- ifelse(!is.null(sheet), sheet, 1)
        cw <- readxl::read_excel(cw_file, sheet = sheet)

    } else if (ext == 'rda' || ext == 'rdata' || ext == 'rds') {

        ## R
        if (ext == 'rds') { cw <- readRDS(cw_file) }
        else { cw <- get(load(cw_file)) }

    } else if (ext == 'dta') {

        ## stata
        cw <- haven::read_stata(cw_file)

    } else {

        ## csv
        if (ext == 'csv' && is.null(delimiter)) { delim <- ',' }

        ## tsv
        else if (ext == 'tsv' && is.null(delimiter)) { delim <- '\t' }

        ## user-supplied
        else if (!is.null(delimiter)) { delim <- delimiter }

        ## error
        else {

            stop('File type not recognized; please supply delimiter string.',
                 call. = FALSE)
        }

        ## delimited
        cw <- readr::read_delim(cw_file, delim = delim,
                                col_types = readr::cols(.default = 'c'))

    }

    ## get starting names
    names_ <- names(.data)

    ## ignore case by setting names to lower
    if (case_ignore) { names_ <- tolower(names_) }

    ## verify that raw and clean are unique (1:1 mapping)
    if (anyDuplicated(cw[[raw]])) {

        ## raw column
        dups <- cw[[raw]][duplicated(cw[[raw]])]
        stop(paste(c('The following values are duplicated in the', raw, 'column:\n',
                     paste(dups, '\n'),
                     'Please specify a 1:1 mapping from old names to new names.'),
                   collapse = ' '))

    }

    if (anyDuplicated(cw[[clean]])) {

        ## clean column
        dups <- cw[[clean]][duplicated(cw[[clean]])]
        stop(paste(c('The following values are duplicated in the', clean, 'column:\n',
                     paste(dups, '\n'),
                     'Please specify a 1:1 mapping from old names to new names.'),
                   collapse = ' '))

    }

    ## drop unmatched names
    if (drop_extra) {
        .data <- .data[names_ %in% cw[[raw]]]

        ## update names_
        names_ <- names(.data)
        if (case_ignore) { names_ <- tolower(names_) }
    }

    ## apply new names, leaving unmatched old names alone
    mask <- match(names_, cw[[raw]], nomatch = 0)
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

        extra_ <- names(.data)[!(names(.data) %in% names(label_list))]

        null_label_list <- list()
        for (i in 1:length(extra_)) {
            null_label_list[extra_[i]] <- list(NULL)
        }

        ## set to NULL
        labelled::var_label(.data) <- null_label_list

    }

    ## return data frame
    return(.data)

}


