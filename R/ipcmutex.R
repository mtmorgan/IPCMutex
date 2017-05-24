#' Inter-process locks
#'
#' @rdname ipcmutex
#'
#' @param id character(1) identifying the lock to be obtained.
#'
#' @return \code{mutex()} returns a \code{Mutex-class} instance.
#'
#' @examples
#' id <- cid("mtx-example")
#' mtx <- mutex(id)
#' mtx
#' trylock(mtx)
#' unlock(mtx)
#' locked(mtx)
#'
#' ## reference semantics
#' mty <- mtx <- mutex(id)
#' lock(mtx)
#' locked(mty)
#' unlock(mtx)
#' locked(mty)
#'
#' ipcremove(id)
#'
#' ## finalizer triggered on garbage collection
#' id <- cid("mtx-gc")
#' mtx <- mutex(id)
#'
#' lock(mtx)
#' locked(mtx)
#' rm(mtx)
#' gc(); gc()
#' locked(mutex(id))
#'
#' ipcremove(id)
#'
#' @useDynLib IPCMutex, .registration=TRUE
#'
#' @export
mutex <- function(id) {
    ext <- .Call(.ipcmutex, id)
    .Mutex(ext = ext, id = id)
}

#' @rdname ipcmutex
#'
#' @return \code{locked()} returns TRUE when \code{mutex} is locked,
#'     and FALSE otherwise.
#'
#' @export
locked <- function(mutex)
    .Call(.ipcmutex_locked, .ext(mutex))

#' @rdname ipccounter
#'
#' @param mutex An instance of class \code{Mutex}.
#'
#' @return \code{lock()} returns a \code{Mutex-class} instance.
#'
#' @export
lock <- function(mutex) {
    .Call(.ipcmutex_lock, .ext(mutex))
    mutex
}

#' @rdname ipcmutex
#'
#' @return On success, \code{trylock()} returns \code{TRUE} if the
#'     lock is obtained, \code{FALSE} otherwise.
#'
#' @export
trylock <- function(mutex) {
    .Call(.ipcmutex_trylock, .ext(mutex))
}

#' @rdname ipcmutex
#'
#' @return \code{unlock()} returns a \code{Mutex-class} instance.
#'
#' @export
unlock <- function(mutex) {
    .Call(.ipcmutex_unlock, .ext(mutex))
    mutex
}

#' @import methods
.Mutex <- setClass(
    "Mutex",
    slots = c(ext = "externalptr", id = "character")
)

.ext <- function(x) x@ext

.id <- function(x) x@id

#' @rdname ipcmutex
#'
#' @param object An instance of class \code{Mutex}.
#'
#' @export
setMethod(show, "Mutex", function(object) {
    cat(
        "class: ", class(object), "\n",
        "id: ", .id(object), "\n",
        "locked(): ", locked(object), "\n",
        sep=""
    )
})
