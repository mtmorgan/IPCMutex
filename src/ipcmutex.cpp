#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>

using namespace boost::interprocess;

class IpcMutex
{

protected:

    managed_shared_memory *shm;
    
private:

    interprocess_mutex *mtx;
    bool *locked;

public:

    IpcMutex(const char *id) {
        shm = new managed_shared_memory{open_or_create, id, 1024};
        mtx = shm->find_or_construct<interprocess_mutex>("mtx")();
        locked = shm->find_or_construct<bool>("locked")();
    }

    ~IpcMutex() {
        delete shm;
    }

    bool is_locked() {
        return *locked;
    }

    bool lock() {
        mtx->lock();
        *locked = true;
        return *locked;
    }

    bool try_lock() {
        *locked = mtx->try_lock();
        return *locked;
    }

    bool unlock() {
        mtx->unlock();
        *locked = false;
        return *locked;
    }

};

class IpcCounter : IpcMutex
{

private:

    int *i;

public:
    
    IpcCounter(const char *id) : IpcMutex(id) {
        i = shm->find_or_construct<int>("i")();
    }

    ~IpcCounter() {}

    int value() {
        return *i + 1;
    }

    int reset(int n) {
        lock();
        *i = n - 1;
        unlock();
        return n;
    }

    int yield() {
        int result;
        lock();
        result = ++(*i);
        unlock();
        return result;
    }

};

#include <Rinternals.h>

// internal

const char *ipc_id(SEXP id)
{
    bool test = IS_SCALAR(id, STRSXP) && (STRING_ELT(id, 0) != R_NaString);
    if (!test)
        Rf_error("'id' must be character(1) and not NA");
    return CHAR(STRING_ELT(id, 0));
}

int ipccounter_n(SEXP n_sexp)
{
    int n = Rf_asInteger(n_sexp);
    if (R_NaInt == n)
        Rf_error("'n' must be integer(1) and not NA");
    return n;
}

// utilities

SEXP ipc_remove(SEXP id_sexp) {
    const char *id = ipc_id(id_sexp);
    bool status = shared_memory_object::remove(id);
    return Rf_ScalarLogical(status);
}

// mutex

SEXP ipc_locked(SEXP id_sexp)
{
    IpcMutex mutex = IpcMutex(ipc_id(id_sexp));
    bool status = mutex.is_locked();
    return Rf_ScalarLogical(status);
}

SEXP ipc_lock(SEXP id_sexp)
{
    IpcMutex mutex = IpcMutex(ipc_id(id_sexp));
    mutex.lock();
    return Rf_ScalarLogical(true);
}

SEXP ipc_try_lock(SEXP id_sexp)
{
    IpcMutex mutex = IpcMutex(ipc_id(id_sexp));
    bool status = mutex.try_lock();
    return Rf_ScalarLogical(status);
}

SEXP ipc_unlock(SEXP id_sexp)
{
    IpcMutex mutex = IpcMutex(ipc_id(id_sexp));
    bool status = mutex.unlock();
    return Rf_ScalarLogical(status);
}

// count

SEXP ipc_value(SEXP id_sexp)
{
    IpcCounter cnt = IpcCounter(ipc_id(id_sexp));
    return Rf_ScalarInteger(cnt.value());
}

SEXP ipc_reset(SEXP id_sexp, SEXP n_sexp)
{
    IpcCounter cnt = IpcCounter(ipc_id(id_sexp));
    int n = ipccounter_n(n_sexp);
    return Rf_ScalarInteger(cnt.reset(n));
}

SEXP ipc_yield(SEXP id_sexp)
{
    IpcCounter cnt = IpcCounter(ipc_id(id_sexp));
    return Rf_ScalarInteger(cnt.yield());
}

// expose to R

#include <R_ext/Rdynload.h>

extern "C" {

    static const R_CallMethodDef callMethods[] = {
        // lock
        {".ipc_lock", (DL_FUNC) & ipc_lock, 1},
        {".ipc_try_lock", (DL_FUNC) & ipc_try_lock, 1},
        {".ipc_unlock", (DL_FUNC) & ipc_unlock, 1},
        {".ipc_locked", (DL_FUNC) & ipc_locked, 1},
        // counter
        {".ipc_yield", (DL_FUNC) & ipc_yield, 1},
        {".ipc_value", (DL_FUNC) & ipc_value, 1},
        {".ipc_reset", (DL_FUNC) & ipc_reset, 2},
        // cleanup
        {".ipc_remove", (DL_FUNC) & ipc_remove, 1},
        {NULL, NULL, 0}
    };

    void R_init_IPCMutex(DllInfo *info)
    {
        R_registerRoutines(info, NULL, callMethods, NULL, NULL);
    }

    void R_unload_IPCMutex(DllInfo *info)
    {
        (void) info;
    }

}
