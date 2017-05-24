library(IPCMutex)

cid("my")
cnt <- counter(cid("my"))
cnt
yield(cnt)
yield(cnt)
close(cnt)

tryCatch(yield(cnt), error = conditionMessage)

cnt <- counter(cid("my"))
yield(cnt)
close(cnt)
tryCatch(yield(cnt), error = conditionMessage)

cnt <- counter(cid("my"))
yield(cnt)
ipcremove(cid("my"))

## new counter, new sequence
yield(counter(cid("my")))
yield(counter(cid("my")))
counter(cid("my"))                      # current state
ipcremove(cid("my"))                    # all processes done with counter

## existing counter, continuing
yield(cnt)

id <- cid("parallel")
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
