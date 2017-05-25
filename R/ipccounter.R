#' Inter-process counter
#'
#' @rdname ipccounter
#'
#' @param id character(1) counter or mutex identifier
#'
#' @useDynLib IPCMutex, .registration=TRUE
#'
#' @return \code{yield()} returns an integer(1) value representing
#'     the next number in sequence. The first value returned is 1.
#'
#' @examples
#' id <- ipcid()
#'
#' yield(id)
#' yield(id)
#'
#' @export
yield <- function(id) {
    .Call(.ipc_yield, id)
}

#' @rdname ipccounter
#'
#' @return \code{value()} returns the value to be returned by the next
#'     call to \code{yield()}, without incrementing the counter. If
#'     the counter is not longer available, \code{yield()} returns
#'     \code{NA}.
#'
#' @examples
#' value(id)
#' yield(id)
#'
#' @export
value <- function(id) {
    .Call(.ipc_value, id)
}

#' @rdname ipccounter
#'
#' @param n integer(1) value from which \code{yield()} will
#'     increment.
#'
#' @return \code{reset()} returns \code{n}, invisibly.
#'
#' @examples
#' reset(id, 10)
#' value(id)
#' yield(id)
#'
#' ipcremove(id)
#'
#' @export
reset <- function(id, n = 1) {
    invisible(.Call(.ipc_reset, id, n))
}
