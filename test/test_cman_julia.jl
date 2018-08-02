using Compat
using Compat.Test
using MPI
using Compat.Distributed

# Start workers via `mpiexec` that communicate among themselves via MPI;
# communicate with the workers via TCP
if !Compat.Sys.iswindows() && Compat.occursin( "OpenRTE", Compat.open(f->read(f, String),`mpiexec --version`))
    mgr = MPI.MPIManager(np=4, mpirun_cmd=`mpiexec --oversubscribe -n 4`)
else
    mgr = MPI.MPIManager(np=4)
end
addprocs(mgr)

refs = []
for w in workers()
    push!(refs, @spawnat w MPI.Comm_rank(MPI.COMM_WORLD))
end
ids = falses(nworkers())
for r in refs
    id = fetch(r)
    @test !ids[id+1]
    ids[id+1] = true
end
for id in ids
    @test id
end

s = @distributed (+) for i in 1:10
    i^2
end
@test s == 385

@mpi_do mgr n = 2
@mpi_do mgr n + 2
