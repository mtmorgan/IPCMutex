#' @import methods
setClass(
    "IPC",
    contains = "VIRTUAL",
    slots = c(ext = "externalptr", id = "character")
)

.ext <- function(x) x@ext

.id <- function(x) x@id
