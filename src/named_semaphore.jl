const PERMS = Base.S_IRUSR | Base.S_IWUSR | Base.S_IRGRP | Base.S_IROTH # 0644

struct NamedSemaphore
    name::String
    handle::Ptr{Void}

    function NamedSemaphore(name::String, create::Bool=true, create_exclusive::Bool=false)
        new(name, sem_open(name, create, create_exclusive))
    end
end

lock(sem::NamedSemaphore) = sem_wait(sem.handle)
trylock(sem::NamedSemaphore) = sem_trywait(sem.handle)
unlock(sem::NamedSemaphore) = sem_post(sem.handle)
close(sem::NamedSemaphore) = sem_close(sem.handle)
delete!(sem::NamedSemaphore) = sem_unlink(sem.name)
count(sem::NamedSemaphore) = sem_getvalue(sem.handle)
reset(sem::NamedSemaphore) = error("can not reset a NamedSemaphore")

# create or open a semaphore
# semaphore is created in unlocked state (i.e. value is 1)
function sem_open(name::String, create::Bool=true, create_exclusive::Bool=false)
    if create
        flags = Base.JL_O_CREAT
        if create_exclusive
            flags |= Base.JL_O_EXCL
        end
        handle = ccall(:sem_open, Ptr{Void}, (Cstring, Cint, Base.Cmode_t, Cuint), name, flags, PERMS, Cuint(1))
    else
        handle = ccall(:sem_open, Ptr{Void}, (Cstring, Cint), name, Base.JL_O_RDWR)
    end
    systemerror("error creating/opening semaphore", handle == 0)
    handle
end

# unlock a semaphore
function sem_post(handle::Ptr{Void})
    ret = ccall(:sem_post, Cint, (Ptr{Void},), handle)
    systemerror("error unlocking semaphore", ret != 0)
end

# lock a semaphore
function sem_wait(handle::Ptr{Void})
    ret = ccall(:sem_wait, Cint, (Ptr{Void},), handle)
    systemerror("error locking semaphore", ret != 0)
end

function sem_trywait(handle::Ptr{Void})
    ret = ccall(:sem_trywait, Cint, (Ptr{Void},), handle)
    eagain = (Libc.errno() == Libc.EAGAIN)
    locked = (ret == 0)
    systemerror("error locking semaphore", !locked && !eagain)
    locked
end

# close a semaphore (in this process, semaphore will still exist in system)
function sem_close(handle::Ptr{Void})
    ret = ccall(:sem_close, Cint, (Ptr{Void},), handle)
    systemerror("error closing semaphore", ret != 0)
end

# unlink a semaphore (semaphore will be deleted from system once all opened references to it are closed)
function sem_unlink(name::String)
    ret = ccall(:sem_unlink, Cint, (Cstring,), name)
    systemerror("error unlinking semaphore", ret != 0)
end

# Gets the current value of the semaphore.
# If one or more processes or threads are blocked waiting to lock the semaphore with sem_wait(3),
# POSIX.1 permits two possibilities for the value returned in sval: either 0 is returned; or a
# negative number whose absolute value is the count of the number of processes and threads currently
# blocked in sem_wait(3). Linux adopts the former behavior.
function sem_getvalue(handle::Ptr{Void})
    val = Ref{Cint}(0)
    ret = ccall(:sem_getvalue, Cint, (Ptr{Void},Ptr{Cint}), handle, val)
    systemerror("error getting semaphore value", ret != 0)
    val[]
end
