#' Inter-process locks
#'
#' @rdname ipcmutex
#' 
#' @export
lock <- function(id = .SHM_MUTEX_ID) {
    .Call(.ipcmutex_lock, id)
}

#' @rdname ipcmutex
#' 
#' @export
unlock <- function(id = .SHM_MUTEX_ID) {
    .Call(.ipcmutex_unlock, id)
}

#' @rdname ipcmutex
#' 
#' @export
trylock <- function(id = .SHM_MUTEX_ID) {
    .Call(.ipcmutex_trylock, id)
}
