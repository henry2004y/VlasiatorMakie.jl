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

   fig, ax, plt = heatmap(meta2, var, EARTH, 0, :z)
   @test plt isa Heatmap

   fig, ax = vlslice(meta3, var)
   @test fig isa Figure

   fig, ax = vlslices(meta3, var)
   @test fig isa Figure

   fig = volume(meta3, "fg_b", EARTH, 3; algorithm=:iso, isovalue=0.0, isorange=1e-9)
   @test fig isa Makie.FigureAxisPlot

   location = [0.0, 0.0, 0.0]
   fig = VlasiatorMakie.vdfslice(meta1, location)
   @test fig isa Figure

   fig = vdfslices(meta1, location)
   @test fig isa Figure

   fig, ax = vdfvolume(meta1, location)
   @test fig isa Figure
end
