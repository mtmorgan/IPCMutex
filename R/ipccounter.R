#' Inter-process counter
#'
#' @rdname ipccounter
#'
#' @param id character(1) identifying the lock to be obtained.
#'
#' @return \code{counter()} returns a \code{Counter-class} instance.
#'
#' @examples
#' cnt <- counter()
#' cnt
#' yield(cnt)
#' yield(cnt)
#' close(cnt)
#'
#' ## reference semantics
#' cntx <- cnty <- counter()
#' yield(cntx)
#' yield(cnty)
#' close(cntx)         # only once
#'
#' cntx <- counter()
#' yield(cntx)
#' yield(counter())    # same counter
#' close(cntx)
#'
#' ## finalizer triggered on garbage collection
#' yield(counter())
#' gc(); gc()
#' yield(counter())
#'
#' ## named counters
#' cnt1 <- counter("counter 1")
#' cnt2 <- counter("counter 2")
#' yield(cnt1); yield(cnt1)
#' yield(cnt2)
#' close(cnt1); close(cnt2)
#'
#' @useDynLib IPCMutex, .registration=TRUE
#'
#' @export
count <- function(id, master = FALSE) {
    ext <- .Call(.ipccounter, id, master)
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
#'     call to \code{yield()}, without incrementing the counter.
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
#' @export
reset <- function(counter, n) {
    invisible(.Call(.ipccounter_reset, .ext(counter), n))
}

#' @rdname ipccounter
#'
#' @param con A \code{Counter-class} instance that has not yet been
#'     closed.
#' @return \code{close()} returns \code{Counter-class} instance that
#'     can no longer count.
#'
#' @export
close.Counter <- function(con) {
    ext <- .Call(.ipccounter_close, .ext(con))
    initialize(con, ext = ext)
}

#' @rdname ipccounter
#'
#' @import methods
.Counter <- setClass(
    "Counter",
    slots = c(ext = "externalptr", id = "character")
)

#' @rdname ipccounter
#'
#' @param object An instance of class \code{Mutex}.
#'
#' @export
setMethod(show, "Counter", function(object) {
    cat(
        "class: ", class(object), "\n",
        "id: ", .id(object), "\n",
        sep=""
    )
})
