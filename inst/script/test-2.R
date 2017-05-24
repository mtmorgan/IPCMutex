library(IPCMutex)

id <- ipcid("my")
cnt <- counter(id)
cnt
yield(cnt)
yield(cnt)
close(cnt)

tryCatch(yield(cnt), error = conditionMessage)

cnt <- counter(id)
yield(cnt)
close(cnt)
tryCatch(yield(cnt), error = conditionMessage)

cnt <- counter(id)
yield(cnt)
ipcremove(id)

## new counter, new sequence
yield(counter(id))
yield(counter(id))
counter(id)                          # current state

ipcremove(id)                        # all processes done with counter

## existing counter, continuing
yield(cnt)

id <- ipcid("parallel")
counter(id)

fun <- function(i, id)
    IPCMutex::yield(IPCMutex::counter(id))

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
counter("test-persistent")              # current state
res <- unlist(BiocParallel::bplapply(1:50, fun, "test-persistent"))
range(res)
stopifnot(!any(duplicated(res)))
