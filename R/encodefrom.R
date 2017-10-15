#' Encode data frame column using external crosswalk file.
#'
#'
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

#' Standard evaluation version of \code{\link{encodefrom}}
#'
#' @inheritParams encodefrom
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

    ## read in crosswalk file
    cw <- get_cw_file(cw_file, delimiter, sheet)

    ## confirm columns are in crosswalk
    confirm_col(cw, raw, 'm1')
    confirm_col(cw, clean, 'm1')
    confirm_col(cw, label, 'm1')

    ## verify that raw, clean, and label are unique in crosswalk file (1:1 mapping)
    check_dups(cw, raw, 'm2')
    check_dups(cw, clean, 'm2')
    check_dups(cw, label, 'm2')

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

    if (tibble::is_tibble(.data) && !ignore_tibble) {

        ## set up labels for labeller
        val_labels <- cw[[clean]]
        names(val_labels) <- cw[[label]]

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
