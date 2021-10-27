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

"""
    vdfslices(meta, location; species="proton", unit=SI, verbose=false)

Three orthogonal slices of VDFs from `meta` at `location`.
"""
function vdfslices(meta, location; species="proton", unit=SI, verbose=false)
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
      if f[i] < 1f-16 f[i] = 1f-16 end
   end
   data = log10.(f)

   plt = volumeslices!(ax, x, y, z, data, colormap=:viridis)
   #TODO: wait for https://github.com/JuliaPlots/Makie.jl/pull/1404
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