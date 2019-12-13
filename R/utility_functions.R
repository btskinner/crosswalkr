
## function to read crosswalk file based on file type
get_cw_file <- function(cw_file, delimiter = NULL, sheet = NULL) {

    ## check to make sure file exists
    if (!file.exists(cw_file)) {

        stop(paste(c('Crosswalk file not found.',
                     'Please confirm file name and path.'),
                   collapse = ' '),
             call. = FALSE)
    }

    ## get file ending; ignore case (.RData == .Rdata == .rdata)
    ext <- tolower(tools::file_ext(cw_file))

    ## read based on filetype
    if (ext == 'xls' || ext == 'xlsx') {

        ## excel
        sheet <- ifelse(!is.null(sheet), sheet, 1)
        cw <- readxl::read_excel(cw_file, sheet = sheet, col_types = 'text')

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

    ## return
    return(cw)
}

## check for duplicates in crosswalk file
check_dups <- function(cw, column_1, column_2 = NULL, message_code = 'm1') {

    ## set proper out message code
    out <- switch(message_code,
                  m1 = 'values are duplicated',
                  m2 = 'code values are assigned to more than one label',
                  m3 = 'code values don\'t uniquely map'
                  )

    ## if only checking one column for duplicates...
    if (is.null(column_2) && anyDuplicated(cw[[column_1]])) {

        ## get duplicate values
        dups <- cw[[column_1]][duplicated(cw[[column_1]])]
        ## stop message with list of duplicates to aid user
        stop(paste(c('The following',
                     out,
                     'in the',
                     column_1,
                     'column:\n\n',
                     paste(dups, '\n'),
                     '\n',
                     'Please specify a 1:1 mapping.'),
                   collapse = ' '),
             call. = FALSE)

    } else if (!is.null(column_2)) {

        ## collapse cw to distinct pairs
        cw_dp <- unique(cw[,c(column_1,column_2)])
        ## compare unique Ns
        col_1_n <- length(unique(cw_dp[[column_1]]))
        col_2_n <- length(unique(cw_dp[[column_2]]))
        cw_dp_n <- nrow(cw_dp)
        ## put in list
        n_list <- list(col_1_n, col_2_n, cw_dp_n)
        ## if Ns are all equal, then we don't have a 1:1 mapping
        uniq_map <- all(sapply(n_list, function(x) x == n_list[1]))
        ## stop if not equal
        if (!uniq_map) {

            ## get list of duplicates for printing
            uniq_vals <- unique(cw_dp[[column_1]])
            dups <- sapply(uniq_vals, function(x) {
                paste0(x, ': ',
                       paste(unlist(cw_dp[cw_dp[[column_1]] == x, column_2]),
                             collapse = ', '))
            })

            ## stop message with list of duplicates to aid user
            stop(paste(c('The following',
                         out,
                         'across these columns:\n\n',
                         paste0('< ', column_1, ' > : < ', column_2, ' >'),
                         '\n\n',
                         paste(dups, '\n'),
                         '\n',
                         'Please specify a 1:1 mapping.'),
                       collapse = ' '),
                 call. = FALSE)
        }

    }

}

## check number of unique values in column 1 is >= to that in column 2
check_nums <- function(cw, column_1, column_2) {

    ## collapse cw to distinct pairs
    cw_dp <- unique(cw[,c(column_1,column_2)])
    ## get counts of unique values
    col_1_n <- length(unique(cw_dp[[column_1]]))
    col_2_n <- length(unique(cw_dp[[column_2]]))
    ## stop if column 1 values are < column 2
    if (col_1_n < col_2_n) {
        stop(paste(c('You have fewer unique source values in \n\n< ',
                     column_1,
                     ' >\n\n than target values in \n\n< ',
                     column_2,
                     ' >\n\n Unique source values must be greater than or ',
                     'equal to target values.'),
                     collapse = ''),
             call. = FALSE)
    }
}

## confirm columns exist in crosswalk file
confirm_col <- function(cw, column, message_code) {

    out <- switch(message_code,
                  m1 = 'crosswalk file.',
                  m2 = 'current data frame.'
                  )

    if (!(column %in% names(cw))) {

        stop(paste(c(column, 'is not in the', out,
                     'Please confirm name of column or crosswalk file.'),
                   collapse = ' '),
             call. = FALSE)

        }
}

## convert factor column to character
factor_to_character <- function(x) if (is.factor(x)) as.character(x) else x
