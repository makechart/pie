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
# chart.interactions! ( 哪個操作會發哪幾維的 filter ) 要等於 want
interactions-is = (want) -> (c) ->
  got = JSON.stringify c.interactions!
  if got != JSON.stringify(want) => throw new Error("interactions: #got, 應為 #{JSON.stringify want}")
# name 的 filter 值 ( 排序後比較 ) 要等於 want(c); want 回 null 表示沒有篩選
name-filter-is = (want) -> (c) ->
  got = ((c.binding.name or {}).filter or {}).value
  got = if got? => got.slice!sort! else null
  w = want c
  w = if w? => w.slice!sort! else null
  if JSON.stringify(got) != JSON.stringify(w) => throw new Error("name filter: #{JSON.stringify got}, 應為 #{JSON.stringify w}")
# 第 lv 圈第 i 個類別底下所有資料點的 name
under = (c, lv, i) ->
  cat = c.all[lv][i].category
  c.all[* - 1].filter((n) -> [0 til cat.length].every (k) -> n.category[k] == cat[k]).map (.name)
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
    # 類別 wedge 與圖例 ( key 是第一層類別 ) 篩的是底下資料點的 name, 不是類別名稱
    * name: "click:category", data: \lv2
      steps:
        * click '.ring:first-child path.data', idx: 1
        * name-filter-is (c) -> under c, 0, 1
    * name: "click:category-twice", data: \lv2
      steps:
        * click '.ring:first-child path.data', idx: 1
        * click '.ring:first-child path.data', idx: 1
        * name-filter-is -> null
    * name: "legend:crossfilter-category", data: \lv1, config: {legend: {crossfilter: true}}
      steps:
        * (c) -> c.legend.select [c.all.0.1.color-key]; c.local.legend-to-filter!
        * name-filter-is (c) -> under c, 0, 1
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
    # 點 wedge 一律篩 name; 圖例只有 crossfilter 時才篩, 也是 name
    * name: "interactions:default", data: \flat, steps: [interactions-is {click: <[name]>}]
    * name: "interactions:crossfilter", data: \flat, config: {legend: {crossfilter: true}}
      steps: [interactions-is {click: <[name]>, legend: <[name]>}]
    * name: "anim:update-frames", data: \flat
      steps: (c, ctx) ->
        d = flat 4, 7
        c.set-raw d.raw, d.binding
        for i from 1 to 4
          c.anim.step 70
          ctx.capture "t#{i * 70}"
