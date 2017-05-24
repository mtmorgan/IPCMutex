#' Inter-process locks
#'
#' @rdname ipcmutex
#'
#' @param id character(1) identifying the lock to be obtained.
#'
#' @examples
#' id <- ipcid("mtx-example")
#'
#' lock(id)
#' try_lock(id)
#' unlock(id)
#' try_lock(id)
#' locked(id)
#'
#' ipcremove(id)
#'
#' @useDynLib IPCMutex, .registration=TRUE
#'
#' @return \code{locked()} returns TRUE when \code{mutex} is locked,
#'     and FALSE otherwise.
#'
#' @export
locked <- function(id)
    .Call(.ipc_locked, id)

#' @rdname ipcmutex
#'
#' @return \code{lock()} creates a named lock, returning \code{TRUE}
#'     on success.
#'
#' @export
lock <- function(id) {
    .Call(.ipc_lock, id)
}

#' @rdname ipcmutex
#'
#' @return \code{trylock()} returns \code{TRUE} if the lock is
#'     obtained, \code{FALSE} otherwise.
#'
#' @export
try_lock <- function(id) {
    .Call(.ipc_try_lock, id)
}

#' @rdname ipcmutex
#'
#' @return \code{unlock()} returns \code{TRUE} on success,
#'     \code{FALSE} (e.g., because there is nothing to unlock)
#'     otherwise.
#'
#' @export
unlock <- function(id) {
    .Call(.ipc_unlock, id)
}
