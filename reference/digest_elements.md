# Derive digests of argument values or their contents

Get digests of argument values. Optionally, functions can be run on some
arguments before calculating digests. An example would be reading
contents of a file where the file path is an argument.

## Usage

``` r
digest_elements(args, funs.unwrap = NULL)
```

## Arguments

- args:

  Named list of arguments to digest

- funs.unwrap:

  Named list of functions to be applied to elements (matched on names)
  in \`args\`. Optional.

## Value

A data.table with columns 'name' and 'res' (digest values)
