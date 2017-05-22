#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/sync/named_mutex.hpp>
#include <iostream>

using namespace boost::interprocess;

class IpcCounter
{
private:

    bool _master;
    std::string _id;
    managed_shared_memory *_shm;
    named_mutex *_mtx;
    int *_i;

public:
    
    IpcCounter(const char *id, bool master) : _id(id), _master(master) {
        if (_master)
            shared_memory_object::remove(id);
        _shm = new managed_shared_memory{open_or_create, id, 4096};
        _mtx = new named_mutex{open_or_create, id};
        _i = _shm->find_or_construct<int>("counter")();
    }

    ~IpcCounter() {
        delete _shm;
        delete _mtx;
        if (_master)
            shared_memory_object::remove(_id.c_str());
    }

    int value() {
        int result;
        _mtx->lock();
        result = *_i + 1;
        _mtx->unlock();
        return result;
    }

    int reset(int n) {
        _mtx->lock();
        *_i = n - 1;
        _mtx->unlock();
        return n;
    }

    int yield() {
        int result;
        _mtx->lock();
        result = ++(*_i);
        _mtx->unlock();
        return result;
    }

};

#include <Rinternals.h>

const char *ipcmutex_id(SEXP id)
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

bool ipccounter_master(SEXP master_sexp)
{
    bool master = Rf_asLogical(master_sexp);
    if (R_NaInt == master)
        Rf_error("'master' must logical(1) and not NA");
    return master;
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

SEXP ipccounter(SEXP id_sexp, SEXP master_sexp) {
    const char *id = ipcmutex_id(id_sexp);
    bool master = ipccounter_master(master_sexp);
    IpcCounter *cnt = new IpcCounter(id, master);
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
    if (NULL == cnt)
        Rf_error("'counter' already released");
    return Rf_ScalarInteger(cnt->value());
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

SEXP ipcmutex_externalptr(named_mutex *mtx)
{
    SEXP ext = PROTECT(R_MakeExternalPtr((void *) mtx, IPCMUTEX_TAG, NULL));
    R_RegisterCFinalizerEx(ext, ipcmutex_externalptr_finalize, TRUE);
    UNPROTECT(1);
    return ext;
}

named_mutex *ipcmutex_externalptr_get_mutex(SEXP ext) {
    bool test = (EXTPTRSXP == TYPEOF(ext)) &&
        (IPCMUTEX_TAG == R_ExternalPtrTag(ext));
    if (!test)
        Rf_error("'ext' is not an IPCMutex external pointer");

    return (named_mutex *) R_ExternalPtrAddr(ext);
}

void ipcmutex_externalptr_finalize(SEXP ext)
{
    named_mutex *mtx = ipcmutex_externalptr_get_mutex(ext);
    if (mtx == NULL)
        return;

    mtx->unlock();

    delete mtx;
    R_SetExternalPtrAddr(ext, NULL);
}

// mutex API implementation

SEXP ipcmutex_lock(SEXP id)
{
    const char *cid = ipcmutex_id(id);
    named_mutex *mtx = new named_mutex{open_or_create, cid};

    mtx->lock();
    return ipcmutex_externalptr(mtx);
}

SEXP ipcmutex_trylock(SEXP id)
{
    const char *cid = ipcmutex_id(id);
    named_mutex *mtx = new named_mutex{open_or_create, cid};

    bool status = mtx->try_lock();
    return status ? ipcmutex_externalptr(mtx) : R_NilValue;
}

SEXP ipcmutex_unlock(SEXP ext)
{
    named_mutex *mtx = ipcmutex_externalptr_get_mutex(ext);
    if (mtx == NULL)
        Rf_error("lock already released");
    mtx->unlock();

    R_SetExternalPtrAddr(ext, NULL);
    return ext;
}

SEXP ipcmutex_locked(SEXP ext)
{
    named_mutex *mtx = ipcmutex_externalptr_get_mutex(ext);
    return Rf_ScalarLogical(NULL != mtx);
}

// expose to R

#include <R_ext/Rdynload.h>

extern "C" {

    static const R_CallMethodDef callMethods[] = {
        // lock
        {".ipcmutex_lock", (DL_FUNC) & ipcmutex_lock, 1},
        {".ipcmutex_unlock", (DL_FUNC) & ipcmutex_unlock, 1},
        {".ipcmutex_trylock", (DL_FUNC) & ipcmutex_trylock, 1},
        {".ipcmutex_locked", (DL_FUNC) & ipcmutex_locked, 1},
        // counter
        {".ipccounter", (DL_FUNC) & ipccounter, 2},
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
