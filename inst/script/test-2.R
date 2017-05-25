library(IPCMutex)

id <- ipcid()
yield(id)
yield(id)
ipcremove(id)

## new counter, new sequence
yield(id)
yield(id)
ipcremove(id)                        # all processes done with counter

id <- ipcid()                           # for use in parallel code

fun <- function(i, id)
    IPCMutex::yield(id)

BiocParallel::register(BiocParallel::SnowParam(4))
res <- unlist(BiocParallel::bplapply(1:50, fun, id))
range(res)
stopifnot(
    identical(range(res), c(1L, 50L)),
    !any(duplicated(res))
)

BiocParallel::register(BiocParallel::SnowParam(4))
res <- unlist(BiocParallel::bplapply(1:50, fun, id))
range(res)
stopifnot(
    identical(range(res), 50L + c(1L, 50L)),
    !any(duplicated(res))
)

BiocParallel::register(BiocParallel::MulticoreParam(4))
res <- unlist(BiocParallel::bplapply(1:50, fun, id))
range(res)
stopifnot(
    identical(range(res), 100L + c(1L, 50L)),
    !any(duplicated(res))
)

ipcremove(id)

## No ipcremove() call, so persistent across independent processes
id <- "test-persistent"
res <- unlist(BiocParallel::bplapply(1:50, fun, id))
range(res)
stopifnot(!any(duplicated(res)))
