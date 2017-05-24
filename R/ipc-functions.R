#' Utilities for working with IPC objects
#' 
#' @rdname ipc-functions
#'
#' @param id character(1) identifying the counter. By default,
#'     counters with the same \code{id}, including counters in
#'     different processes, share the same state.
#'
#' @return \code{ipcid()} returns a character(1) identifier mangled to
#'     include the system process identifier, providing a convenient
#'     way of making an approximately unique or process-local counter.
#'
#' @examples
#' id <- ipcid("example-identifier")
#' id
#'
#' @export
ipcid <- function(id)
    UseMethod("ipcid")

#' @export
ipcid.default <- function(id) {
    paste(as.character(id), Sys.getpid(), sep="::")
}

#' @rdname ipc-functions
#'
#' @return \code{ipcremove()} returns (invisibly) \code{TRUE} if
#'     external resources were release or \code{FALSE} if not (e.g.,
#'     because the resources has already been released). Use
#'     \code{ipcremove()} to remove external state associated with
#'     \code{id}.
#'
#' @examples
#' ipcremove(id)
#'
#' @export
ipcremove <- function(id) {
    invisible(.Call(.ipc_remove, id))
}
