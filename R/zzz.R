.SHM_MUTEX_ID <- NULL

.onLoad <- function(libname, pkgname) {
    .SHM_MUTEX_ID <<- paste(pkgname, Sys.getpid(), sep="::")
}
