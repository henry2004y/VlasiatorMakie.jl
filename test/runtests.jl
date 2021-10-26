using VlasiatorMakie, Vlasiator, LazyArtifacts
using Test

using GLMakie

@testset "VlasiatorMakie.jl" begin
   rootpath = artifact"testdata"
   files = joinpath.(rootpath, ("bulk.1d.vlsv", "bulk.2d.vlsv", "bulk.amr.vlsv"))

   meta1 = load(files[1])
   meta2 = load(files[2])
   meta3 = load(files[3])

   var = "proton/vg_rho"

   fig, ax, plt = lines(meta1, var)
   @test plt isa Lines

   fig = vlheatmap(meta2, var)
   @test fig isa Figure

   fig, ax, plt = heatmap(meta2, var)
   @test plt isa Heatmap
  
   fig = vlslice(meta3, var)
   @test fig isa Figure

   location = [0.0, 0.0, 0.0]
   fig = vdfslice(meta1, location)
   @test fig isa Figure

   fig = vdfslices(meta1, location)
   @test fig isa Figure

   fig = vdfvolume(meta1, location)
   @test fig isa Figure
end
