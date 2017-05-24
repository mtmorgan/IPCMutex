library(IPCMutex)
id <- ipcid("session-lock")

lock(id)
try_lock(id)
unlock(id)
tryCatch(unlock(id), error=conditionMessage)
try_lock(id)
try_lock(id)
unlock(id)

fun <- function(i, id) {
    res <- IPCMutex::try_lock(id)
    if (res) {
        Sys.sleep(1)
        IPCMutex::unlock(id)
    }
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
