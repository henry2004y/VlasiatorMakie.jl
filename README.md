# VlasiatorMakie.jl

> ⚠️ **INFO: This repository is deprecated**
> 
> `VlasiatorMakie` has been moved into the monorepo at [Vlasiator.jl]([https://github.com/JuliaPlots/Makie.jl](https://github.com/henry2004y/Vlasiator.jl/tree/master/ext/VlasiatorMakieExt)).
> For Julia 1.9+, it is recommended to rely on `VlasiatorMakieExt` via
> ```julia
> using Vlasiator, GLMakie
> ```

[![Build Status](https://github.com/henry2004y/VlasiatorMakie.jl/workflows/CI/badge.svg)](https://github.com/henry2004y/VlasiatorMakie.jl/actions?query=workflow%3ACI+branch%3Amain)
[![Coverage](https://codecov.io/gh/henry2004y/VlasiatorMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/henry2004y/VlasiatorMakie.jl)

Makie recipes for visualization of [Vlasiator.jl](https://github.com/henry2004y/Vlasiator.jl.git).

## Installation

```julia
] add VlasiatorMakie
```

## Usage

Both simple type conversion recipes for 1D and 2D data and full recipes for customized and interactive plots are provided.
See more example outputs in [Vlasiator gallery](https://henry2004y.github.io/Vlasiator.jl/dev/gallery/#Makie) and detailed usages in the [manual](https://henry2004y.github.io/Vlasiator.jl/dev/manual/#Makie-Backend) and test scripts. Due to the current limitation of the full recipes from Makie, it is recommended to work with the simpler type recipes, i.e. identical plotting functions as in Makie but with the first two arguments being `meta` and `var`.

```julia
using Vlasiator, VlasiatorMakie, GLMakie

file = "bulk.0000001.vlsv"
meta = load(file)

heatmap(meta, "proton/vg_rho")
```

3D isosurface:

```julia
fig = volume(meta, "fg_b", EARTH, 3; algorithm=:iso, isovalue=0.0, isorange=1e-9)
```

Single figure contour plot:

```julia
fig = Figure(resolution=(700, 600), fontsize=18)
ga = fig[1,1] = GridLayout()
ax = Axis(fig[1,1],
   aspect = DataAspect(),
   title = "t = $(round(meta.time, digits=1))s",
   xlabel = L"x [$R_E$]",
   ylabel = L"y [$R_E$]"
)
hmap = heatmap!(meta, "proton/vg_rho", colormap=:turbo)
cbar = Colorbar(fig, hmap, label=L"$\rho$ [amu/cc]", width=13,
                ticksize=13, tickalign=1, height=Relative(1))
fig[1,2] = cbar
colgap!(ga, 1)
```

Multi-figure contour plots:

```julia
fig = Figure(resolution=(1100, 800), fontsize=18)

axes = []
v_str = ["CellID", "proton/vg_rho", "proton/vg_v",
   "vg_pressure", "vg_b_vol", "vg_e_vol"]
c_str = ["", L"$\rho$ [amu/cc]", "[m/s]", "[Pa]", "[T]", "[V/m]"]
c = 1

for i in 1:2, j in 1:2:5
   ax = Axis(fig[i,j], aspect=DataAspect(),
      xgridvisible=false, ygridvisible=false,
      title = v_str[c],
      xlabel = L"x [$R_E$]",
      ylabel = L"y [$R_E$]")
   hmap = heatmap!(meta, v_str[c], colormap=:turbo)
   cbar = Colorbar(fig, hmap, label=c_str[c], width=13,
                ticksize=13, tickalign=1, height=Relative(1))
   fig[i, j+1] = cbar
   c += 1
   push!(axes, ax) # just in case you need them later.
end

fig[0, :] = Label(fig, "t = $(round(meta.time, digits=1))s")
```

Adjusting axis limits:

```julia
location = [0, 0, 0]
fig = VlasiatorMakie.vdfslice(meta, location)
xlims!(fig.content[1], -1000, 1000)
ylims!(fig.content[1], -1000, 1000)
limits!(fig.content[1], 0, 10, 0, 10) # xmin, xmax, ymin, ymax
```

Saving figure:

```julia
fig = vdfvolume(meta, location)
save("output.png", fig)
```

The resolution is a property of the Figure object returned from the function.
