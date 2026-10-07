# runtests.jl -- test suite entry point.
# Run: julia --project=code code/test/runtests.jl
#
# Each file below is a standalone script (asserts/tests its own subject and
# prints an "OK" line on success); this just runs them all in one process so
# there is a single command to invoke the whole suite. Add new test files
# here as they are created.

include(joinpath(@__DIR__, "test_paperstyle.jl"))
include(joinpath(@__DIR__, "test_strippanels.jl"))
include(joinpath(@__DIR__, "test_finitesize_frames.jl"))
include(joinpath(@__DIR__, "test_revision_interior_technical.jl"))
