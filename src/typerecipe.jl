# Type conversion from Vlasiator to Makie

"Conversion for 1D plots"
function Makie.convert_arguments(P::PointBased, meta::MetaVLSV, var)
   data = readvariable(meta, var)
   x = LinRange(meta.coordmin[1], meta.coordmax[1], meta.ncells[1])

   ([Point2f(i, j) for (i, j) in zip(x, data)],)
end

"Conversion for 2D plots."
function Makie.convert_arguments(P::SurfaceLike, meta::MetaVLSV, var;
   axisunit=EARTH, op=:mag)
   pArgs = Vlasiator.set_args(meta, var, axisunit)
   x, y = Vlasiator.get_axis(axisunit, pArgs.plotrange, pArgs.sizes)
   data = Vlasiator.prep2d(meta, var, op)

   (x, y, data)
end