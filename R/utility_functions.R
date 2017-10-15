
## function to read crosswalk file based on file type
get_cw_file <- function(cw_file, delimiter, sheet) {

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

    ## return
    return(cw)
}

## check for duplicates in crosswalk file
check_dups <- function(cw, column, message_code) {

    out <- switch(message_code,
                  m1 = 'values are duplicated',
                  m2 = 'code values are assigned to more than one label'
                  )

    if (anyDuplicated(cw[[column]])) {

        dups <- cw[[column]][duplicated(cw[[column]])]
        stop(paste(c('The following',
                     out,
                     'in the',
                     column,
                     'column:\n\n',
                     paste(dups, '\n'),
                     '\n',
                     'Please specify a 1:1 mapping.'),
                   collapse = ' '),
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
