#' @rdname ipcmutex
#'
#' @name .SHM_MUTEX_ID
#'
#' @return \code{.SHM_MUTEX_ID} is a character(1) identifier used as a
#'     default lock. It is composed as \code{IPCMutex::<pid>}, where
#'     \code{<pid>} is from \code{Sys.getpid()}.
NULL

#' @export
.SHM_MUTEX_ID <- NULL

.onLoad <- function(libname, pkgname) {
    .SHM_MUTEX_ID <<- paste(pkgname, Sys.getpid(), sep="::")
}
