##' @importFrom utils packageVersion
.onAttach <- function(libname,pkgname){
    packageStartupMessage(paste0("recycle ",packageVersion("recycle")))
}
