# VlasiatorMakie.jl

Makie recipes for visualization of [Vlasiator.jl](https://github.com/henry2004y/Vlasiator.jl.git).

## Installation

```julia
] add VlasiatorMakie
```

## Usage

```julia
using Vlasiator, VlasiatorMakie, GLMakie

file = "bulk.0000001.vlsv"
meta = load(file)

heatmap(meta, "proton/vg_rho")
```

Both simple type conversion recipes for 1D and 2D data and full recipes for customized and interactive plots are provided.
See more example outputs in [Vlasiator gallery](https://henry2004y.github.io/Vlasiator.jl/dev/gallery/#Makie) and detailed usages in the [manual](https://henry2004y.github.io/Vlasiator.jl/dev/manual/#Makie-Backend) and test scripts.
