#' Inter-process counter
#'
#' @rdname ipccounter
#'
#' @useDynLib IPCMutex, .registration=TRUE
#'
#' @rdname ipccounter
#'
#' @export
.Counter <- setClass("Counter", contains = "IPC")

#' @rdname ipccounter
#'
#' @return \code{counter()} returns a \code{Counter-class} instance.
#'
#' @examples
#' id <- ipcid("cnt-example")
#' cnt <- counter(id)
#'
#' yield(cnt)
#' yield(cnt)
#' yield(counter(id))
#'
#' @export
counter <- function(id) {
    ext <- .Call(.ipccounter, id)
    .Counter(ext = ext, id = id)
}

#' @rdname ipccounter
#'
#' @param  counter instance of class \code{Count}.
#'
#' @return \code{counter()} returns an integer(1) value representing
#'     the next number in sequence. The first value returned is 1.
#'
#' @export
yield <- function(counter) {
    .Call(.ipccounter_yield, .ext(counter))
}

#' @rdname ipccounter
#'
#' @return \code{value()} returns the value to be returned by the next
#'     call to \code{yield()}, without incrementing the counter. If
#'     the counter is not longer available, \code{yield()} returns
#'     \code{NA}.
#'
#' @examples
#' value(cnt)
#' yield(cnt)
#'
#' @export
value <- function(counter) {
    .Call(.ipccounter_value, .ext(counter))
}

#' @rdname ipccounter
#'
#' @param n integer(1) value from which \code{yield(counter)} will
#'     increment.
#'
#' @return \code{reset()} returns \code{n}, invisibly.
#'
#' @examples
#' reset(cnt, 1)
#' value(cnt)
#' yield(cnt)
#'
#' @export
reset <- function(counter, n = 1) {
    invisible(.Call(.ipccounter_reset, .ext(counter), n))
}

#' @rdname ipccounter
#'
#' @param con A \code{Counter-class} instance that has not yet been
#'     closed.
#'
#' @param ... Ignored.
#'
#' @return \code{close()} returns \code{Counter-class} instance that
#'     can no longer count. Creating a new counter with the same
#'     \code{id} continues counting.
#'
#' @examples
#' close(cnt)
#' tryCatch(yield(cnt), error = conditionMessage)
#' yield(counter(id))
#'
#' ipcremove(id)
#'
#' @export
close.Counter <- function(con, ...) {
    ext <- .Call(.ipccounter_close, .ext(con))
    initialize(con, ext = ext)
}

#' @export
ipcid.Counter <- function(id)
    .id(id)

#' @rdname ipccounter
#'
#' @param object An instance of class \code{Counter}.
#'
#' @export
setMethod(show, "Counter", function(object) {
    cat(
        "class: ", class(object), "\n",
        "ipcid(): ", ipcid(object), "\n",
        "value(): ", value(object), "\n",
        sep=""
    )
})
