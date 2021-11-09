# Interactive plots with Observables

"""
    vlslice(meta, var; normal=:y, axisunit=SI, op=:mag)

Interactive 2D slice of 3D `var` in `normal` direction.
"""
function vlslice(meta::MetaVLSV, var; normal=:y, axisunit=SI, op=:mag)
   dir, str1, str2 =
      if normal == :x
         1, "y", "z"
      elseif normal == :y
         2, "x", "z"
      else
         3, "x", "y"
      end

   unitx = axisunit == RE ? " [Re]" : " [m]"

   dx = meta.dcoord[dir] / 2^meta.maxamr

   pArgs = Vlasiator.set_args(meta, var, axisunit; normal, origin=0.0)
   x, y = Vlasiator.get_axis(axisunit, pArgs.plotrange, pArgs.sizes)

   nsize = meta.ncells[dir]
   depth = nsize*2^meta.maxamr

   fig = Figure()
   ax = Axis(fig[1, 1], aspect=DataAspect())
   ax.xlabel = str1*unitx
   ax.ylabel = str2*unitx

   lsgrid = labelslidergrid!(
      fig,
      ["location in normal direction $(String(normal))"],
      [1:depth];
      format = x -> "$(x) cells")

   fig[2, 1] = lsgrid.layout

   sliderobservables = [s.value for s in lsgrid.sliders]

   slice = lift(sliderobservables...) do slvalues...
      begin
         origin = (slvalues[1]-1)*dx + meta.coordmin[dir]
         pArgs = Vlasiator.set_args(meta, var, axisunit; normal, origin)
         Vlasiator.prep2dslice(meta, var, normal, op, pArgs)
      end
   end

   heatmap!(ax, x, y, slice, colormap=:turbo)

   set_close_to!(lsgrid.sliders[1], .5depth)

   fig
end

"TODO: Make it work!"
function vlslices_interactive(meta::MetaVLSV, var; axisunit=SI, op=:mag)
   unitx = axisunit == RE ? " [Re]" : " [m]"

   pArgs1 = Vlasiator.set_args(meta, var, axisunit; normal=:x, origin=0.0)
   pArgs2 = Vlasiator.set_args(meta, var, axisunit; normal=:y, origin=0.0)
   pArgs3 = Vlasiator.set_args(meta, var, axisunit; normal=:z, origin=0.0)

   x, y = Vlasiator.get_axis(axisunit, pArgs3.plotrange, pArgs3.sizes)
   x, z = Vlasiator.get_axis(axisunit, pArgs2.plotrange, pArgs2.sizes)

   d1 = Vlasiator.prep2dslice(meta, var, :x, op, pArgs1)
   d2 = Vlasiator.prep2dslice(meta, var, :y, op, pArgs2)
   d3 = Vlasiator.prep2dslice(meta, var, :z, op, pArgs3)

   fig = Figure()
   ax = Axis3(fig[1, 1], aspect=(1, 1, 1), elevation=pi/6, perspectiveness=0.5)

   ax.xlabel = "x"*unitx
   ax.ylabel = "y"*unitx
   ax.zlabel = "z"*unitx

   xlims!(ax, x[1], x[end])
   ylims!(ax, y[1], y[end])
   zlims!(ax, z[1], z[end])

   lsgrid = labelslidergrid!(
      fig,
      ["x", "y", "z"],
      [1:length(x), 1:length(y), 1:length(z)],
      formats = [i -> "$(round(x[i], digits=2))",
          i -> "$(round(y[i], digits=2))", i -> "$(round(z[i], digits=2))"]
    )
   fig[2, 1] = lsgrid.layout

   h1 = heatmap!(ax, y, z, d1, colormap=:turbo, transformation=(:yz, 0.0))
   h2 = heatmap!(ax, x, z, d2, colormap=:turbo, transformation=(:xz, 0.0))
   h3 = heatmap!(ax, x, y, d3, colormap=:turbo, transformation=(:xy, 0.0))

   # connect sliders to volumeslices update methods
   sl_yz, sl_xz, sl_xy = lsgrid.sliders

   #TODO: make it work properly!
   on(sl_yz.value) do v
      pArgs = Vlasiator.set_args(meta, var, axisunit; normal=:x, origin=v)
      d1 = Vlasiator.prep2dslice(meta, var, :x, op, pArgs)
      h1[3] = d1
   end
   on(sl_xz.value) do v
      pArgs = Vlasiator.set_args(meta, var, axisunit; normal=:y, origin=v)
      d2 = Vlasiator.prep2dslice(meta, var, :y, op, pArgs)
      h2[3] = d2
   end
   on(sl_xy.value) do v
      pArgs = Vlasiator.set_args(meta, var, axisunit; normal=:z, origin=v)
      d1 = Vlasiator.prep2dslice(meta, var, :z, op, pArgs)
      h3[3] = d3
   end

   set_close_to!(sl_yz, .5length(x))
   set_close_to!(sl_xz, .5length(y))
   set_close_to!(sl_xy, .5length(z))

   fig
end

"""
    vdfslices(meta, location; fmin=1f-16, species="proton", unit=SI, verbose=false)

Three orthogonal slices of VDFs from `meta` at `location`.
# Optional Arguments
- `fmin`: minimum VDF threshold for plotting.
- `species`: name of particle.
- `unit`: unit of input `location`, `SI` or `RE`.
"""
function vdfslices(meta, location; fmin=1f-16, species="proton", unit=SI, verbose=false)
   if haskey(meta.meshes, species)
      vmesh = meta.meshes[species]
   else
      throw(ArgumentError("Unable to detect population $species"))
   end

   unit == RE && (location .*= Re)

   # Calculate cell ID from given coordinates
   cidReq = getcell(meta, location)
   cidNearest = getnearestcellwithvdf(meta, cidReq)

   cellused = getcellcoordinates(meta, cidNearest)

   if verbose
      @info "Original coordinates : $location"
      @info "Original cell        : $(getcellcoordinates(meta, cidReq))"
      @info "Nearest cell with VDF: $cellused"
      let
         x, y, z = getcellcoordinates(meta, cidNearest)
         @info "cellid $cidNearest, x = $x, y = $y, z = $z"
      end
   end

   _, vcellf = readvcells(meta, cidNearest; species)

   f = Vlasiator.flatten(vmesh, vcellf)

   fig = Figure()
   ax = Axis3(fig[1, 1], aspect=(1,1,1), title = "VDF at $cellused in log scale")
   ax.xlabel = "vx [m/s]"
   ax.ylabel = "vy [m/s]"
   ax.zlabel = "vz [m/s]"

   x = LinRange(vmesh.vmin[1], vmesh.vmax[1], vmesh.vblock_size[1]*vmesh.vblocks[1])
   y = LinRange(vmesh.vmin[2], vmesh.vmax[2], vmesh.vblock_size[2]*vmesh.vblocks[2])
   z = LinRange(vmesh.vmin[3], vmesh.vmax[3], vmesh.vblock_size[3]*vmesh.vblocks[3])

   lsgrid = labelslidergrid!(
     fig,
     ["vx", "vy", "vz"],
     [1:length(x), 1:length(y), 1:length(z)],
     formats = [i -> "$(round(x[i], digits=2))",
         i -> "$(round(y[i], digits=2))", i -> "$(round(z[i], digits=2))"]
   )
   fig[2, 1] = lsgrid.layout

   for i in eachindex(f)
      if f[i] < fmin f[i] = fmin end
   end
   data = log10.(f)

   plt = volumeslices!(ax, x, y, z, data, colormap=:viridis)
   #TODO: wait for Makie v0.15.4
   cbar = Colorbar(fig, plt,
      label="f(v)",
      minorticksvisible=true)

   fig[1, 2] = cbar

   # connect sliders to volumeslices update methods
   sl_yz, sl_xz, sl_xy = lsgrid.sliders

   on(sl_yz.value) do v; plt[:update_yz][](v) end
   on(sl_xz.value) do v; plt[:update_xz][](v) end
   on(sl_xy.value) do v; plt[:update_xy][](v) end

   set_close_to!(sl_yz, .5length(x))
   set_close_to!(sl_xz, .5length(y))
   set_close_to!(sl_xy, .5length(z))

   fig
end