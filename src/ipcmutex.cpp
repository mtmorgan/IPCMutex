#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>

using namespace boost::interprocess;

class IpcMutex
{

protected:

    managed_shared_memory *shm;
    
private:

    std::string id;
    interprocess_mutex *mtx;
    bool is_locked;

public:

    IpcMutex(const char *_id) : id(_id), is_locked(false) {
        shm = new managed_shared_memory(open_or_create, id.c_str(), 1024);
        mtx = shm->find_or_construct<interprocess_mutex>("mtx")();
    }

    ~IpcMutex() {
        unlock();
        delete shm;
    }

    bool locked() {
        return is_locked;
    }

    bool lock() {
        mtx->lock();
        is_locked = true;
        return is_locked;
    }

    bool try_lock() {
        is_locked = mtx->try_lock();
        return is_locked;
    }

    bool unlock() {
        mtx->unlock();
        is_locked = false;
        return is_locked;
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

const char *ipc_id(SEXP id)
{
    bool test = IS_SCALAR(id, STRSXP) && (STRING_ELT(id, 0) != R_NaString);
    if (!test)
        Rf_error("'id' must be character(1) and not NA");
    return CHAR(STRING_ELT(id, 0));
}

SEXP ipc_remove(SEXP id_sexp) {
    const char *id = ipc_id(id_sexp);
    bool status = shared_memory_object::remove(id);
    return Rf_ScalarLogical(status);
}

// Counter

int ipccounter_n(SEXP n_sexp)
{
    int n = Rf_asInteger(n_sexp);
    if (R_NaInt == n)
        Rf_error("'n' must be integer(1) and not NA");
    return n;
}

void ipccounter_externalptr_finalize(SEXP);

IpcCounter *ipccounter_externalptr_get(SEXP);

static SEXP IPCCOUNTER_TAG = NULL;

SEXP ipccounter_externalptr(IpcCounter *cnt)
{
    SEXP ext = PROTECT(R_MakeExternalPtr((void *) cnt, IPCCOUNTER_TAG, NULL));
    R_RegisterCFinalizerEx(ext, ipccounter_externalptr_finalize, TRUE);
    UNPROTECT(1);
    return ext;
}

void ipccounter_externalptr_finalize(SEXP ext)
{
    IpcCounter *cnt = ipccounter_externalptr_get(ext);
    if (cnt == NULL)
        return;
    delete cnt;

    R_SetExternalPtrAddr(ext, NULL);
}

IpcCounter *ipccounter_externalptr_get(SEXP ext) {
    bool test = (EXTPTRSXP == TYPEOF(ext)) &&
        (IPCCOUNTER_TAG == R_ExternalPtrTag(ext));
    if (!test)
        Rf_error("'ext' is not an IPCMutex Counter external pointer");

    return (IpcCounter *) R_ExternalPtrAddr(ext);
}

SEXP ipccounter(SEXP id_sexp) {
    const char *id = ipc_id(id_sexp);
    IpcCounter *cnt = new IpcCounter(id);
    return ipccounter_externalptr(cnt);
}

SEXP ipccounter_yield(SEXP ext) {
    IpcCounter *cnt = ipccounter_externalptr_get(ext);
    if (NULL == cnt)
        Rf_error("'counter' already released");
    return Rf_ScalarInteger(cnt->yield());
}

SEXP ipccounter_value(SEXP ext) {
    IpcCounter *cnt = ipccounter_externalptr_get(ext);
    int value = (NULL == cnt) ? R_NaInt : cnt->value();
    return Rf_ScalarInteger(value);
}

SEXP ipccounter_reset(SEXP ext, SEXP n_sexp) {
    IpcCounter *cnt = ipccounter_externalptr_get(ext);
    if (NULL == cnt)
        Rf_error("'counter' already released");
    int n = ipccounter_n(n_sexp);
    return Rf_ScalarInteger(cnt->reset(n));
}

SEXP ipccounter_close(SEXP ext) {
    IpcCounter *cnt = ipccounter_externalptr_get(ext);
    if (NULL == cnt)
        Rf_error("'counter' already released");
    delete cnt;
    R_SetExternalPtrAddr(ext, NULL);
    return ext;
}

// IpcMutex

static SEXP IPCMUTEX_TAG = NULL;

void ipcmutex_externalptr_finalize(SEXP);

SEXP ipcmutex_externalptr(IpcMutex *mtx)
{
    SEXP ext = PROTECT(R_MakeExternalPtr((void *) mtx, IPCMUTEX_TAG, NULL));
    R_RegisterCFinalizerEx(ext, ipcmutex_externalptr_finalize, TRUE);
    UNPROTECT(1);
    return ext;
}

IpcMutex *ipcmutex_externalptr_get_mutex(SEXP ext, bool check_valid) {
    bool test = (EXTPTRSXP == TYPEOF(ext)) &&
        (IPCMUTEX_TAG == R_ExternalPtrTag(ext));
    if (!test)
        Rf_error("'ext' is not an IPCMutex external pointer");

    IpcMutex *mtx = (IpcMutex *) R_ExternalPtrAddr(ext);
    if (check_valid && (NULL == mtx))
        Rf_error("lock removed");
    
    return mtx;
}

void ipcmutex_externalptr_finalize(SEXP ext)
{
    IpcMutex *mtx = ipcmutex_externalptr_get_mutex(ext, false);
    if (mtx == NULL)
        return;
    delete mtx;
    R_SetExternalPtrAddr(ext, NULL);
}

// mutex API implementation

SEXP ipcmutex(SEXP id_sexp)
{
    const char *id = ipc_id(id_sexp);
    IpcMutex *mtx = new IpcMutex(id);
    return ipcmutex_externalptr(mtx);
}

SEXP ipcmutex_lock(SEXP ext)
{
    IpcMutex *mtx = ipcmutex_externalptr_get_mutex(ext, true);
    return Rf_ScalarLogical(mtx->lock());
}

SEXP ipcmutex_trylock(SEXP ext)
{
    IpcMutex *mtx = ipcmutex_externalptr_get_mutex(ext, true);
    return Rf_ScalarLogical(mtx->try_lock());
}

SEXP ipcmutex_unlock(SEXP ext)
{
    IpcMutex *mtx = ipcmutex_externalptr_get_mutex(ext, true);
    return Rf_ScalarLogical(mtx->unlock());
}

SEXP ipcmutex_locked(SEXP ext)
{
    IpcMutex *mtx = ipcmutex_externalptr_get_mutex(ext, true);
    return Rf_ScalarLogical(mtx->locked());
}

// expose to R

#include <R_ext/Rdynload.h>

extern "C" {

    static const R_CallMethodDef callMethods[] = {
        {".ipc_remove", (DL_FUNC) & ipc_remove, 1},
        // lock
        {".ipcmutex", (DL_FUNC) & ipcmutex, 1},
        {".ipcmutex_locked", (DL_FUNC) & ipcmutex_locked, 1},
        {".ipcmutex_lock", (DL_FUNC) & ipcmutex_lock, 1},
        {".ipcmutex_unlock", (DL_FUNC) & ipcmutex_unlock, 1},
        {".ipcmutex_trylock", (DL_FUNC) & ipcmutex_trylock, 1},
        // counter
        {".ipccounter", (DL_FUNC) & ipccounter, 1},
        {".ipccounter_value", (DL_FUNC) & ipccounter_value, 1},
        {".ipccounter_reset", (DL_FUNC) & ipccounter_reset, 2},
        {".ipccounter_yield", (DL_FUNC) & ipccounter_yield, 1},
        {".ipccounter_close", (DL_FUNC) & ipccounter_close, 1},
        {NULL, NULL, 0}
    };

    void R_init_IPCMutex(DllInfo *info)
    {
        R_registerRoutines(info, NULL, callMethods, NULL, NULL);
        IPCMUTEX_TAG = install("IPCMUTEX");
    }

    void R_unload_IPCMutex(DllInfo *info)
    {
        (void) info;
    }

}
