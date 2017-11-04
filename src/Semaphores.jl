__precompile__(true)

module Semaphores

import Base: lock, trylock, unlock, close, delete!, count, reset

export NamedSemaphore, ResourceCounter, SemBuf
export lock, trylock, unlock, close, delete!, count, reset, change

include("named_semaphore.jl")
include("sysv_semaphore.jl")
include("resource_counter.jl")

end # module
