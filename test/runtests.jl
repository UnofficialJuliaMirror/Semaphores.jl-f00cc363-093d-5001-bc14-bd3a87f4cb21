using Semaphores
using Base.Test

using Semaphores

sem = NamedSemaphore("/testsem")
close(sem)
delete!(sem)
sem = NamedSemaphore("/testsem", true, true)

@test count(sem) == 1

lock(sem)
@test count(sem) == 0
@test !trylock(sem)
unlock(sem)
@test count(sem) == 1
@test trylock(sem)
@test count(sem) == 0

const N = 10
for idx in 1:N
    unlock(sem)
end
@test count(sem) == N
for idx in 1:N
    lock(sem)
end
@test count(sem) == 0

close(sem)
delete!(sem)
