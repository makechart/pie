# Change Logs

## v0.0.2

 - wedge click selects: a single click picks one, shift adds / removes, and clicking the only
   selected one again clears the selection. it goes out through `chart.filter`, the same path
   bar's brush uses, so a host sees one kind of event
 - legend crossfilter ( `cfg.legend.crossfilter` ): legend and wedges share one selection in
   `binding.name.filter`, so the two can never disagree. "select all" ( no filter at all ) and
   "select none" ( an empty value list ) stay distinct — merging them makes the "select none"
   button bounce back to "select all"
 - support subset presentation: `partial` cuts each wedge along the arc ( clockwise ), with the
   subset aggregated up the rings so inner and outer rings agree
 - dim legend items instead of removing them when `cfg.legend.subset.mode` is `dim`


## v0.0.1

init release
