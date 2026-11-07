# pie 的 test case ( @makechart/viewer 的 mctest )
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, lv = 1, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map (i) ->
    name: "N#i", val: Math.round(rnd! * 100), c1: "A#{Math.floor(rnd! * 4)}", c2: "B#{Math.floor(rnd! * 3)}"
  binding:
    name: {key: \name}
    value: {key: \val}
    category: [{key: \c1}, {key: \c2}].slice(0, lv)
flat = (n, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map (i) -> {name: "Item #i", val: Math.round(rnd! * 100)}
  binding: {name: {key: \name}, value: {key: \val}}
with-subset = (d) ->
  r = mctest.random 99
  d.subset = d.raw.map -> {} <<< it <<< {val: Math.round(it.val * r!)}
  d
click = (sel, opt = {}) -> (c, ctx) ->
  n = ctx.root.querySelectorAll(sel)[opt.idx or 0]
  n.dispatchEvent new MouseEvent(\click, {bubbles: true, shift-key: !!opt.shift})

mctest.suite do
  size: [480, 360]
  data:
    flat: flat 6
    lv1: mk 12, 1
    lv2: mk 16, 2
    subset: with-subset flat 6
  cases:
    * name: "flat", data: \flat
    * name: "lv1", data: \lv1
    * name: "lv2", data: \lv2
    * name: "donut:0.3", data: \flat, config: {donut: {percent: 0.3, padding: 0.1}}
    * name: "legend:bottom", data: \flat, config: {legend: {position: \bottom}}
    * name: "partial", data: \subset, config: {common: {subset: {mode: \partial}}}
    * name: "picked", data: \flat, steps: (c) -> c.filter {name: {type: \index, value: <["Item 1" "Item 3"]>}}
    * name: "click", data: \flat
      steps:
        * click 'path.data', idx: 2
        * click 'path.data', idx: 4, shift: true
    * name: "hover", data: \lv2
      steps: (c, ctx) ->
        ctx.root.querySelectorAll('path.data')[3].dispatchEvent new MouseEvent(\mouseover, {bubbles: true})
    * name: "update", data: \flat, steps: (c) -> d = flat 4, 7; c.set-raw d.raw, d.binding
    * name: "legend:dim", data: \flat, config: {legend: {subset: {mode: \dim}}}
      # legend.select 不發事件, 照 pie 的 legend select handler 重畫
      steps: (c) ->
        c.legend.select ["Item #i" for i in [0 1 3 4 5]]
        c.parse!; c.bind!; c.resize!; c.render!

# lite 版才有: anim 的 manual 時鐘拍動畫中間格
mctest.suite do
  size: [480, 360]
  data: {flat: flat 6}
  cases:
    * name: "anim:update-frames", data: \flat
      steps: (c, ctx) ->
        d = flat 4, 7
        c.set-raw d.raw, d.binding
        for i from 1 to 4
          c.anim.step 70
          ctx.capture "t#{i * 70}"
