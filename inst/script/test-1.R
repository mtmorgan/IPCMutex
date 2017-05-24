library(IPCMutex)
id <- cid("process-lock")
mtx <- mutex(id)

mtx <- lock(mtx)
trylock(mtx)
unlock(mtx)
tryCatch(unlock(mtx), error=conditionMessage)
trylock(mtx)
trylock(mtx)
unlock(mtx)

fun <- function(i, id) {
    mtx <- IPCMutex::mutex(id)
    res <- IPCMutex::trylock(mtx)
    if (res)
        Sys.sleep(1)
    res
}

BiocParallel::register(BiocParallel::MulticoreParam(4))
system.time(res <- BiocParallel::bplapply(1:4, fun, id))
stopifnot(sum(unlist(res)) == 1L)

BiocParallel::register(BiocParallel::SnowParam(4))
system.time(res <- BiocParallel::bplapply(1:4, fun, id))
stopifnot(sum(unlist(res)) == 1L)

BiocParallel::register(BiocParallel::SnowParam(4))
system.time(res <- BiocParallel::bplapply(1:4, fun, id))
stopifnot(sum(unlist(res)) == 1L)

ipcremove(id)
