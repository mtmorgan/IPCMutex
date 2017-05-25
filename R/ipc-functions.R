#' Utilities for working with IPC objects
#'
#' @rdname ipc-functions
#'
#' @description Use \code{ipcid()} to generate a unique mutex or
#'     counter identifier. A mutex or counter with the same \code{id},
#'     including those in different processes, share the same state.
#'
#' @param id character(1) (optional for \code{ipcid()}) identifier
#'     string for mutex or counter.
#'
#' @return \code{ipcid()} returns a character(1) unique identifier,
#'     with \code{id} (if not missing) prepended.
#'
#' @examples
#' ipcid()
#' id <- ipcid("example-identifier")
#' id
#'
#' @export
ipcid <- function(id) {
    uuid <- .Call(.ipc_uuid)
    if (!missing(id))
        uuid <- paste(as.character(id), uuid, sep="-")
    uuid
}

#' @rdname ipc-functions
#'
#' @description \code{ipcremove()} removes external state associated
#'     with mutex or counters created with \code{id}.
#'
#' @return \code{ipcremove()} returns (invisibly) \code{TRUE} if
#'     external resources were release or \code{FALSE} if not (e.g.,
#'     because the resources has already been released).
#'
#'
#' @examples
#' ipcremove(id)
#'
#' @export
ipcremove <- function(id) {
    invisible(.Call(.ipc_remove, id))
}
