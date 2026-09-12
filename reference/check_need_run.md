# Check if function needs to be re-run based on argument changes

Compares current arguments against stored digests to determine if a
function needs to be re-executed.

## Usage

``` r
check_need_run(args, path.res, path.digest, funs.unwrap, force)
```

## Arguments

- args:

  Named list of arguments

- path.res:

  Path to results file

- path.digest:

  Path to digest file

- funs.unwrap:

  Named list of functions to apply before digesting

- force:

  Logical, if TRUE always return that run is needed

## Value

List with elements: run (logical), digest.new (data.table), digest.all
(data.table or NULL)
