__precompile__(true)

module Semaphores

import Base: lock, trylock, unlock, close, delete!, count

export NamedSemaphore
export lock, trylock, unlock, close, delete!, count

include("named_semaphore.jl")

end # module
