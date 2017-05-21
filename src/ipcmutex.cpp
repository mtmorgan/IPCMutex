#include <boost/interprocess/sync/named_mutex.hpp>

using namespace boost::interprocess;

#include <Rinternals.h>
#include <R_ext/Rdynload.h>

extern "C" {

    const char *ipcmutex_id(SEXP id)
    {
        bool test = IS_SCALAR(id, STRSXP) && (STRING_ELT(id, 0) != R_NaString);
        if (!test)
            Rf_error("'id' must be character(1) and not NA");
        return CHAR(STRING_ELT(id, 0));
    }

    // ExternalPtr

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
            Rf_error("'ext' must be an external pointer");
        named_mutex *mtx = (named_mutex *) R_ExternalPtrAddr(ext);
        if (mtx == NULL)
            Rf_error("'ext' contanied a NULL external pointer");
        return mtx;
    }

    void ipcmutex_externalptr_finalize(SEXP ext)
    {
        named_mutex *mtx = ipcmutex_externalptr_get_mutex(ext);
        if (mtx == NULL)
            return;

        mtx->unlock();

        delete mtx;
        R_ClearExternalPtr(ext);
    }

    // API implementation

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
        mtx->unlock();
        return Rf_ScalarLogical(TRUE);
    }

    static const R_CallMethodDef callMethods[] = {
        /* zip_compression.c */
        {".ipcmutex_lock", (DL_FUNC) & ipcmutex_lock, 1},
        {".ipcmutex_unlock", (DL_FUNC) & ipcmutex_unlock, 1},
        {".ipcmutex_trylock", (DL_FUNC) & ipcmutex_trylock, 1},
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
