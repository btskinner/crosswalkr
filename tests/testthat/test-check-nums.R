context('check_nums')

## get crosswalk
cw <- get_cw_file('./testdata/cw_dup_3.csv')

test_that('Failed to catch more values in column 1 than column 2', {

    expect_error(check_nums(cw, 'a', 'b'))

})

test_that('Should be no error: unique column 1 = unique column 2', {

    expect_error(check_nums(cw[1:2,], 'a', 'b'), regexp = NA)

})


test_that('Should be no error: unique column 2 > unique column 1', {

    expect_error(check_nums(cw, 'b', 'a'), regexp = NA)

})




