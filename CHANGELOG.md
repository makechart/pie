# Change Logs

## v0.0.5

 - add `desc` ( en / zh-TW ) to the config items, shown under the label in the makechart style panel

## v0.0.4

 - fix bug: with `category` bound, clicking a category wedge, or a legend item with `legend.crossfilter`
   ( legend items are the first category level ), wrote the category label into the `name` filter. a host
   matches `name` against the data point column, so nothing matched ( e.g. a dashboard went empty, with no
   error ). they now filter the `name` of every data point under that category; a category wedge shows
   as picked when any data point under it is picked
 - declare `interactions` ( needs `@plotdb/chart` >= 3.16.0 ): clicking a wedge filters `name`; the legend
   filters `name` too, only with `legend.crossfilter` ( otherwise it just shows / hides items )
 - add `interactions:*`, `click:category*` and `legend:crossfilter-category` test cases
 - devDependencies: `@makechart/viewer` ^0.0.7, and refresh the lock so its `@plotdb/chart` is 3.16.0


## v0.0.3

 - extend the lite base ( `@makechart/base` `lite/index.html`, no d3 ): needs `@makechart/base` >= 0.2.0
   and `@plotdb/chart` >= 3.7.0. scales / shapes / transitions use `chart.utils`, and transitions run on
   `chart.anim`, so animation can be recorded frame by frame ( `anim.manual` / `step` )
 - add test cases ( `test/index.ls`, run with `npm test` via `@makechart/viewer` )


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
