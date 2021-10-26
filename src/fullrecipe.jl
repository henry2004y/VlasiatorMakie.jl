# Full recipes for customized Vlasiator plots.

"""
    viz(meta, var)

Visualize Vlasiator output `var` in `meta` with various options:
* `axisunit`   - unit of axis of type `AxisUnit`
* `colorscale` - scale of colormap of type `ColorScale`
* `normal`     - slice normal direction
* `vmin`       - minimum color value
* `vmax`       - maximum color value
* `op`         - selection of vector components
"""
@recipe(Viz, meta, var) do scene
   Attributes(;
      # generic attributes
      colormap      = :turbo,
      markersize    = Makie.theme(scene, :markersize),
      colorrange    = Makie.automatic,
      levels        = 5,
      linewidth     = 1.0,
      alpha         = 1.0,

      # Vlasiator.jl attributes
      axisunit      = RE,
      colorscale    = Linear,
      normal        = :y, # only works in 3D
      vmin          = -Inf,
      vmax          = Inf,
      op            = :mag,
      origin        = 0.0,
   )
end

function Makie.plot!(vlplot::Viz)
   meta        = vlplot[:meta][]
   var         = vlplot[:var][]
   op          = vlplot.op[]
   normal      = vlplot.normal[]
   axisunit    = vlplot.axisunit[]
   vmin        = vlplot.vmin[]
   vmax        = vlplot.vmax[]
   colorscale  = vlplot.colorscale[]
   origin      = vlplot.origin[]

   if ndims(meta) == 1
      data = readvariable(meta, var)

      x = LinRange(meta.coordmin[1], meta.coordmax[1], meta.ncells[1])

      lines!(vlplot, x, data)
   elseif ndims(meta) == 2
      pArgs = Vlasiator.set_args(meta, var, axisunit)

      x, y = Vlasiator.get_axis(axisunit, pArgs.plotrange, pArgs.sizes)
      data = Vlasiator.prep2d(meta, var, op)

      if var in ("fg_b", "fg_e", "vg_b_vol", "vg_e_vol") || endswith(var, "vg_v")
         rho_ = findfirst(endswith("rho"), meta.variable)
         if !isnothing(rho_)
            rho = readvariable(meta, meta.variable[rho_])
            rho = reshape(rho, pArgs.sizes[1], pArgs.sizes[2])
            mask = findall(==(0.0), rho)

            if ndims(data) == 2
               @inbounds data[mask] .= NaN
            else
               ind = CartesianIndices((pArgs.sizes[1], pArgs.sizes[2]))
               for m in mask
                  @inbounds data[:, ind[m][1], ind[m][2]] .= NaN
               end
            end
         end
      end

      if colorscale == Log # Logarithmic plot
         if any(<(0), data)
            throw(DomainError(data, "Nonpositive data detected: use linear scale instead!"))
         end
         datapositive = data[data .> 0.0]
         v1 = isinf(vmin) ? minimum(datapositive) : vmin
         v2 = isinf(vmax) ? maximum(x->isnan(x) ? -Inf : x, data) : vmax
      elseif colorscale == Linear
         v1 = isinf(vmin) ? minimum(x->isnan(x) ? +Inf : x, data) : vmin
         v2 = isinf(vmax) ? maximum(x->isnan(x) ? -Inf : x, data) : vmax
         nticks = 9
         ticks = range(v1, v2, length=nticks)
      end
      vlplot.colorrange = [v1, v2]

      heatmap!(vlplot, x, y, data, colormap=vlplot.colormap)
   else # 3D
      pArgs = Vlasiator.set_args(meta, var, axisunit; normal, origin)
      x, y = Vlasiator.get_axis(axisunit, pArgs.plotrange, pArgs.sizes)
      data = Vlasiator.prep2dslice(meta, var, normal, op, pArgs)

      heatmap!(vlplot, x, y, data, colormap=vlplot.colormap)
   end
   vlplot
end

function vlheatmap(meta, var; addcolorbar=true, axisunit=RE, kwargs...)
   pArgs = Vlasiator.set_args(meta, var, axisunit)

   fig = Figure()
   c = viz(fig[1,1], meta, var; axisunit, kwargs...)
   c.axis.title = @sprintf "t= %4.1fs" meta.time
   # TODO: current limitation in Makie 0.15.1: no conversion from initial String type
   c.axis.xlabel = pArgs.strx
   c.axis.ylabel = pArgs.stry
   c.axis.autolimitaspect = 1
   if addcolorbar
      cbar = Colorbar(fig[1,2], c.plot, label=pArgs.cb_title, tickalign=1)
      colgap!(fig.layout, 7)
   end
   fig
end

"""
    vdfvolume(meta, location; species="proton", unit=SI, flimit=-1.0, verbose=false)

Meshscatter plot of VDFs in 3D.
"""
function vdfvolume(meta, location; species="proton", unit=SI, flimit=-1.0, verbose=false)
   ncells = meta.ncells
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

   vcellids, vcellf = readvcells(meta, cidNearest; species)

   V = getvcellcoordinates(meta, vcellids; species)

   # Set sparsity threshold
   if flimit < 0
      flimit =
         if hasvariable(meta, species*"/vg_effectivesparsitythreshold")
            readvariable(meta, species*"/vg_effectivesparsitythreshold", cidNearest)
         elseif hasvariable(meta, species*"/EffectiveSparsityThreshold")
            readvariable(meta, species*"/EffectiveSparsityThreshold", cidNearest)
         else
            1e-16
         end
   end

   # Drop velocity cells which are below the sparsity threshold
   findex_ = vcellf .≥ flimit
   fselect = vcellf[findex_]
   Vselect = V[findex_]

   cmap = :turbo
   colors = to_colormap(cmap, 101)
   alphas = LinRange(0, 1, 101)
   cmap_alpha = RGBAf.(colors, alphas)

   fig = Figure()
   ax = Axis3(fig[1, 1], aspect=(1,1,1), title = "VDF at $cellused in log scale")
   ax.xlabel = "vx [m/s]"
   ax.ylabel = "vy [m/s]"
   ax.zlabel = "vz [m/s]"
   #TODO: wait for https://github.com/JuliaPlots/Makie.jl/pull/1404   
   plt = meshscatter!(ax, Vselect, color=log10.(fselect),
      marker=Rect3f(Vec3f(0), Vec3f(4*vmesh.dv[1])),
      colormap=cmap_alpha,
      transparency=true, shading=false)

   cbar = Colorbar(fig, plt, label="f(v)")

   fig[1, 2] = cbar

   fig
end

struct LogMinorTicks end

function MakieLayout.get_minor_tickvalues(::LogMinorTicks, scale, tickvalues, vmin, vmax)
   vals = Float64[]
   extended_tickvalues = [
      tickvalues[1] - (tickvalues[2] - tickvalues[1]);
      tickvalues;
      tickvalues[end] + (tickvalues[end] - tickvalues[end-1]);
   ]
   for (lo, hi) in zip(
        @view(extended_tickvalues[1:end-1]),
        @view(extended_tickvalues[2:end])
     )
       interval = hi-lo
       steps = log10.(LinRange(10^lo, 10^hi, 11))
       append!(vals, steps[2:end-1])
   end
   return filter(x -> vmin < x < vmax, vals)
end

custom_formatter(values) = map(
  v -> "10" * Makie.UnicodeFun.to_superscript(round(Int64, v)),
  values
)

function vdfslice(meta, location;
   species="proton", unit=SI, unitv="km/s", slicetype=:nothing, vslicethick=0.0,
   center=:nothing, fmin=-Inf, fmax=Inf, weight=:particle, flimit=-1.0, verbose=false)

   v1, v2, r1, r2, fweight, strx, stry, str_title =
      Vlasiator.prep_vdf(meta, location;
         species, unit, unitv, slicetype, vslicethick, center, weight, flimit, verbose)

   isinf(fmin) && (fmin = minimum(fweight))
   isinf(fmax) && (fmax = maximum(fweight))

   verbose && @info "Active f range is $fmin, $fmax"

   h = fit(Histogram, (v1, v2), weights(fweight), (r1, r2))

   clims = (fmin, maximum(h.weights))

   data = [isinf(x) ? NaN : x for x in log10.(h.weights)]

   fig = Figure()

   ax, hm = heatmap(fig[1, 1],  r1, r2, data,
      colormap=:turbo, colorrange=log10.(clims))

   cb = Colorbar(fig[1, 2], hm;
      label="f(v)",
      tickformat=custom_formatter,
      minorticksvisible=true,
      minorticks=LogMinorTicks() )

   ax.title = str_title
   ax.xlabel = strx
   ax.ylabel = stry

   fig
end