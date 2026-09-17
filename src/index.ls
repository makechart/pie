module.exports =
  pkg:
    name: 'pie', version: '0.0.1'
    extend: {name: "@makechart/base"}
    dependencies: []
    i18n:
      "zh-TW":
        value: "數值"
        name: "名稱"
        category: "分類"
        other: "其它"
  init: ({root, context, pubsub, t}) ->
    pubsub.fire \init, mod: mod {context, t}

mod = ({context, t}) ->
  {chart,d3} = context
  sample: ->
    raw: [1 to 30].map (val) ~>
      {
        val: (10 * Math.random!).toFixed(2)
        c1: "A#{Math.ceil(Math.random! * 7)}"
        c2: "B#{Math.ceil(Math.random! * 4)}"
        c3: "C#{Math.ceil(Math.random! * 4)}"
        name: "N:#{val}"
      }
    binding:
      name: {key: \name}
      category: [{key: \c1}, {key: \c2}, {key: \c3}]
      value: {key: \val}
  config: chart.utils.config.from({
    tip: \tip
    preset: \default
    legend: \legend
  }) <<<
    donut:
      percent: type: \number, default: 0.7, min: 0, max: 1, step: 0.01
      padding: type: \number, default: 0.03, min: 0, max: 1, step: 0.01
  dimension:
    name: {type: \NCO, name: "name", priority: 10}
    value: {type: \R, name: "value", priority: 20}
    category: {type: \C, name: "category", priority: 25, multiple: true}
  init: ->
    @g = Object.fromEntries <[view legend]>.map ~> [it, d3.select(@layout.get-group it).append \g]
    @tint = tint = new chart.utils.tint!
    @tip = new chart.utils.tip {
      root: @root
      accessor: ({evt}) ~>
        if !(evt.target and d = d3.select(evt.target).datum!) => return null
        v = if isNaN(d.value) => '-'
        else "#{d3.format(@cfg.tip.format or '.2s')(d.value)}#{@binding.value.unit or ''}"
        return {name: d.name or (if d.category => d.category[* - 1] else '-'), value: v}
      range: ~> @layout.get-node \view .getBoundingClientRect!
    }
    @legend = new chart.utils.legend do
      layout: @layout
      name: 'legend'
      root: @root
      shape: (d) -> d3.select(@).attr \fill, tint.get d.text
      cfg: selectable: true
    @legend.on \select, ~>
      # legend.crossfilter 打開時, legend 與 wedge 點選共用同一份選取 -
      # 走 filter 這條路, 連動就會跟 wedge 點選完全一樣 ( 也不會有兩套狀態打架 )
      if (@cfg.legend or {}).crossfilter =>
        return @local.legend-to-filter!
      @parse!; @bind!; @resize!; @render!
    @arc = d3.arc!
      .startAngle 0
      .endAngle(Math.PI / 2)
    @total = {}
    @hover = {}

  destroy: -> @tip.destroy!

  # 宣告這張圖自己會發 filter. host ( 例如 dashboard ) 據此決定要不要再拿 select 事件代打.
  # chart.filter 已經幫我們 parse / bind / resize / render, 這裡只要不擋著就好.
  filter: (filters, internal) ->
    if !((@cfg.legend or {}).crossfilter) => return
    @local.filter-to-legend!


  parse: ->
    @tint.reset!
    bind-cat = @binding.category or []
    oall = @all
    @all = all = []
    # subval: 這一筆有多少被選中 ( 由核心的 subset 通道掛上來 ). 往上聚合時一起加,
    # 這樣內外圈的比例都對得起來
    data = @data.map -> {} <<< it <<< {
      value: (if isNaN(+it.value) or !it.value => 0 else +it.value)
      subval: (if !it.subset => null else (if isNaN(+it.subset.value) => 0 else +it.subset.value))
    }
    for i from 0 til bind-cat.length =>
      hash = {}
      data.map ~>
        cat = it.category.slice 0, i + 1
        key = cat.map(-> "#{(it or '')}".replace(/\//g,'//')).join('/')
        if !hash[key] => hash[key] = {category: cat, color-key: cat.0 or it.name, value: 0, subval: null}
        hash[key].value += it.value
        if it.subval? => hash[key].subval = (hash[key].subval or 0) + it.subval
      all.push [v for k,v of hash]
    all.push data.map(->{color-key: it.category.0 or it.name} <<< it)

    for i from 0 til all.length =>
      list = all[i]
      list.sort (a,b) ->
        for j from 0 til i =>
          la = all[j].filter ->
            for k from 0 til j => if it.category[k] != a.category[k] => return false
            return true
          lb = all[j].filter ->
            for k from 0 til j => if it.category[k] != b.category[k] => return false
            return true
          ia = la.map(->it.category[j]).indexOf(a.category[j])
          ib = lb.map(->it.category[j]).indexOf(b.category[j])
          if ia == ib => continue
          return ia - ib
        b.value - a.value
    all.map (list,j) -> list.map (n,i) -> n._idx = i; n._lv = j
    if oall => all.map (d,i) -> d.map (e,j) ->
      if oall[i] and oall[i][j] => e <<< oall[i][j]{old, cur}
    lgdata = @all.0.map -> text: it.color-key, key: it.color-key, value: it.value
    @legend.data lgdata

  bind: ->
    # picked 決定這一片佔不佔角度 ( shrink 時關掉就整片消失 );
    # legend-dim 則是 dim 模式下「留著位置但灰掉」
    @all.map (list) ~> list.map (n) ~>
      n.picked = @legend.is-visible n.color-key
      n.legend-dim = !@legend.is-selected n.color-key

  resize: ->
    @tip.toggle(if @cfg.{}tip.enabled? => @cfg.tip.enabled else true)
    @root.querySelector('.pdl-layout').classList.toggle \legend-bottom, (@cfg.legend.position == \bottom)
    @legend.config({} <<< @cfg.legend)
    @legend.update!
    @layout.update false
    rbox = @root.getBoundingClientRect!
    lbox = @layout.get-box \legend
    if @cfg.legend.position == \bottom =>
      [w, h] = [rbox.width, rbox.height - lbox.height]
    else
      [w, h] = [rbox.width - lbox.width, rbox.height]
    size = if w > h => h else w
    @layout.get-node \view .style <<<
      width: "#{size}px", height: "#{size}px"
    @layout.update false

  render: ->
    {binding, legend, arc, tint, all, cfg, hover} = @
    render = ~> @render!
    self = @
    # 被 filter 排除的 wedge 的透明度; 與 hover 的效果相乘, 兩者互不覆蓋
    dimmed = ((cfg.common or {}).subset or {}).opacity
    dimmed = if dimmed? => dimmed else 0.2
    # partial: wedge 角度不變, 沿半徑切內外兩段 - 內段是被選中的部分, 外段灰掉.
    # 這樣單一 wedge 的選取 ( 角度 / 位置 ) 完全不受影響
    partial = (@subset.mode! == \partial) and !!@_subset
    picked-of = (d) ->
      f = ((binding.name or {}).filter or {}).value
      # f 是 [] 表示「什麼都沒選」, 跟「沒有篩選」不一樣, 所以這裡只看存不存在
      if !f => return 1
      key = d.name or (if d.category => d.category[* - 1] else null)
      if key in f => 1 else dimmed
    box = @layout.get-box \view
    [w,h] = [box.width, box.height]
    size = Math.min(w,h)

    @total.old = @total.cur
    @total.cur = @all.0.reduce(((a,b) -> a + (if b.picked => b.value else 0)),0) or 1
    if !@total.old => @total.old = @total.cur

    all.map (list, j) ~>
      offset = 0

      r1 = cfg.donut.percent * size/2
      r2 = size/2
      rp = cfg.donut.padding * (r2 - r1) / ((all.length - 1) or 1)
      rd = ((r2 - r1) * (1 - cfg.donut.padding)) / (all.length or 1)
      rr1 = r1 + (rd + rp) * j
      rr2 = r1 + (rd + rp) * j + rd
      rp = 0.002 * rp

      for i from 0 til list.length =>
        obj = list[i]
        if !obj.old => obj.old = {s: (if list[i - 1] => that.old.e else 0), e: 0, es: 0, r1: rr1, r2: rr1, rp: rp}
        if obj.cur => obj.old = obj.cur
        val = (obj.value or 0)

        ratio = if !partial => 1
        else if !val => 0
        else Math.max 0, Math.min(1, (obj.subval or 0) / val)
        # es: 被選中那一段的結束位置. 跟 wedge 同一個圓心角起點, 順時鐘吃掉 ratio 的角度 -
        # 整片的角度與位置完全不動, 只有色塊吃到哪裡在變
        obj.cur =
          s: offset
          e: offset + (if obj.picked => val else 0)
          es: offset + (if obj.picked => val * ratio else 0)
          r1: rr1, r2: rr2, rp: rp
        for k in <[old cur]> =>
          o = obj[k]
          t = if k == \old => @total.old else @total.cur
          o.angle =
            s: 2 * Math.PI * o.s / t
            e: 2 * Math.PI * o.e / t
            es: 2 * Math.PI * (o.es ? o.e) / t
        if obj.picked => offset += val

    # ek: 結束角要用哪一個 - e 是整片 wedge, es 是被選中的那一段
    interpolate-arc = (a1, a2, i, ek = \e) ~> (t) ~>
      arc
        .innerRadius (a2.r1 - a1.r1) * t + a1.r1
        .outerRadius (a2.r2 - a1.r2) * t + a1.r2
        .padAngle (a2.rp - a1.rp) * t + a1.rp

      s = (a2.angle.s - a1.angle.s) * t + a1.angle.s
      [e1, e2] = [(a1.angle[ek] ? a1.angle.e), (a2.angle[ek] ? a2.angle.e)]
      e = (e2 - e1) * t + e1
      @arc.startAngle s .endAngle e
      @arc!

    if @cfg? and @cfg.palette => @tint.set(@cfg.palette.colors.map -> it.value or it)
    box = @layout.get-box \view
    @g.view.attr \transform, "translate(#{box.width / 2},#{box.height / 2})"

    @g.view.selectAll \g.ring .data @all
      ..exit!remove!
      ..enter!append \g .attr \class, \ring

    @g.view.selectAll \g.ring
      .each (d,j) ->
        n = d3.select(@)
        n.selectAll \path.data .data(d, -> it.name or it._idx)
          ..exit!remove!
          ..enter!append \path .attr \class, \data
            .on \mouseover, (e,n,i) ~>
              hover.item = n
              render!
            .on \mouseout, (e,n,i) ~>
              hover.item = null
              render!
            .on \click, (e,n,i) ->
              # mod 自己的工具方法放在 mod.local, 核心建構時綁到實例上
              self.local.toggle-select e, n
            .attr \opacity, (d,i) ~> 0
            .attr \fill, (d,i) ~> tint.get(d.color-key or d._idx)
        n.selectAll \path.data
          .transition!duration 350
          .attrTween \d, (d,i) ->
            interpolate-arc d.old, d.cur, j
          .attr \fill, (d,i) ~>
            c = tint.get(d.color-key or d._idx)
            # legend 關掉的只降透明 ( 保留顏色才認得出是哪一項 ); 灰化是 partial 的手法
            if partial and !d.legend-dim => self.subset.color(c) else c
          .attr \opacity, (d,i) ~>
            # partial 時灰階本身已經表示未選中, 不再降透明
            op = if d.legend-dim => legend.opacity!
            else if partial => 1
            else picked-of d
            if !(h = hover.item) => return op
            if h.category =>
              for j from 0 til h.category.length =>
                if d.category[j] != h.category[j] => return op * 0.3
                if j == d.category.length - 1 => break
              if d._lv == h._lv and d != h => return op * 0.3
              return op
            else if hover.item.name == d.name => op else op * 0.3

        if !partial => n.selectAll \path.subset .remove!
        else
          n.selectAll \path.subset .data((d.filter -> !it.legend-dim), -> it.name or it._idx)
            ..exit!remove!
            ..enter!append \path .attr \class, \subset
              # 蓋在上面但不吃事件, 點擊 / hover 一律由底下那片 wedge 處理
              .style \pointer-events, \none
              .attr \opacity, 0
          n.selectAll \path.subset
            .transition!duration 350
            .attrTween \d, (d,i) -> interpolate-arc d.old, d.cur, j, \es
            .attr \fill, (d,i) ~> tint.get(d.color-key or d._idx)
            .attr \opacity, 1

        legend.render!

  # 這張圖自己的工具方法. `local` 是核心保留給圖表的位置, 核心不管裡面有什麼,
  # 建構時會綁到實例上, 所以呼叫端寫 `@local.xxx()` 就好
  local:

    # filter -> legend: 讓 legend 的勾選跟著外面的篩選狀態走
    filter-to-legend: ->
      vs = ((@binding.name or {}).filter or {}).value
      @legend.select (if vs? => vs else null)

    # legend -> filter: legend 的勾選就是 filter 的值列表.
    # 全選 ( selected! 回 null ) = 沒有篩選; 全不選 ( 回 [] ) = 篩選出空集合, 兩者不同 -
    # 混為一談的話「全不選」按下去會彈回全選
    legend-to-filter: ->
      vs = @legend.selected!
      @filter {name: (if vs? => {type: \index, value: vs} else undefined)}, true

    # wedge 的選取: 單擊只選這一個, shift 增刪, 再點一次選到只剩自己的那個就清空.
    # 走 chart.filter 這條既有的路 ( 跟 bar 的 brush 一樣 ), 所以 host 收到的是同一種 filter 事件.
    toggle-select: (evt, d) ->
      key = d.name or (if d.category => d.category[* - 1] else null)
      if !key? => return
      vs = (((@binding.name or {}).filter or {}).value or []).slice!
      vs = if evt and evt.shiftKey =>
        if key in vs => vs.filter (-> it != key) else vs ++ [key]
      else if vs.length == 1 and vs.0 == key => []
      else [key]
      @filter {name: (if vs.length => {type: \index, value: vs} else undefined)}, true
