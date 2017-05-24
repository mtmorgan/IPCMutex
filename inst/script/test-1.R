library(IPCMutex)
mtx <- lock()
trylock()
unlock(mtx)
trylock()
trylock()
gc()
(mtx <- trylock())
unlock(mtx)
(mtx <- lock("foo"))
unlock(mtx)
tryCatch(unlock(mtx), error=conditionMessage)

gc()
fun <- function(i, id) {
    res <- IPCMutex::trylock(id)
    Sys.sleep(1)
    !is.null(res)
}

BiocParallel::register(BiocParallel::MulticoreParam(2))
system.time(res <- BiocParallel::bplapply(1:4, fun, "test1"))
res

BiocParallel::register(BiocParallel::SnowParam(2))
system.time(res <- BiocParallel::bplapply(1:4, fun, "test2"))
res

BiocParallel::register(BiocParallel::SnowParam(4))
system.time(res <- BiocParallel::bplapply(1:4, fun, "test3"))
res
