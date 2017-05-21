#' Inter-process locks
#'
#' @rdname ipcmutex
#'
#' @param id character(1) identifying the lock to be obtained.
#'
#' @return \code{lock()} returns a \code{Mutex-class} instance.
#'
#' @export
lock <- function(id = .SHM_MUTEX_ID) {
    ext <- .Call(.ipcmutex_lock, id)
    .Mutex(ext = ext, id = id)
}

#' @rdname ipcmutex
#'
#' @return On success, \code{trylock()} returns a \code{Mutex-class}
#'     instance containing an external pointer to the lock. On
#'     failure, \code{trylock()} returns NULL.
#'
#' @export
trylock <- function(id = .SHM_MUTEX_ID) {
    ext <- .Call(.ipcmutex_trylock, id)
    if (!is.null(ext))
        ext <- .Mutex(ext = ext, id = id)
    ext
}

#' @rdname ipcmutex
#'
#' @param mutex An instance of class \code{Mutex}.
#'
#' @return \code{unlock()} returns a \code{Mutex-class} instance with
#'
#' @export
unlock <- function(mutex) {
    ext <- .Call(.ipcmutex_unlock, .ext(mutex))
    initialize(mutex, ext = ext)
}

#' @import methods
.Mutex <- setClass(
    "Mutex",
    slots = c(ext = "externalptr", id = "character")
)

.ext <- function(x) x@ext

.id <- function(x) x@id

.locked <- function(x) .Call(.ipcmutex_locked, .ext(x))

#' @rdname ipcmutex
#'
#' @return \code{locked()} returns TRUE when \code{mutex} is locked,
#'     and FALSE otherwise.
#'
#' @export
locked <- function(mutex)
    .locked(mutex)

#' @rdname ipcmutex
#'
#' @param object An instance of class \code{Mutex}.
#'
#' @export
setMethod(show, "Mutex", function(object) {
    cat(
        "class: ", class(object), "\n",
        "id: ", .id(object), "\n",
        "locked: ", .locked(object), "\n",
        sep=""
    )
})
