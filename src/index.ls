module.exports =
  pkg:
    name: 'pie', version: '0.0.1'
    extend: {name: "base", version: "0.0.1"}
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
    @legend.on \select, ~> @parse!; @bind!; @resize!; @render!
    @arc = d3.arc!
      .startAngle 0
      .endAngle(Math.PI / 2)
    @total = {}
    @hover = {}

  destroy: -> @tip.destroy!

  parse: ->
    @tint.reset!
    bind-cat = @binding.category or []
    oall = @all
    @all = all = []
    data = @data.map -> {} <<< it <<< {value: if isNaN(+it.value) or !it.value => 0 else +it.value}
    for i from 0 til bind-cat.length =>
      hash = {}
      data.map ~>
        cat = it.category.slice 0, i + 1
        key = cat.map(-> "#{(it or '')}".replace(/\//g,'//')).join('/')
        if !hash[key] => hash[key] = {category: cat, color-key: cat.0 or it.name, value: 0}
        hash[key].value += it.value
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
    @all.map (list) ~> list.map (n) ~> n.picked = @legend.is-selected n.color-key

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
        if !obj.old => obj.old = {s: (if list[i - 1] => that.old.e else 0), e: 0, r1: rr1, r2: rr1, rp: rp}
        if obj.cur => obj.old = obj.cur
        val = (obj.value or 0)

        obj.cur =
          s: offset
          e: offset + (if obj.picked => val else 0)
          r1: rr1, r2: rr2, rp: rp
        obj.old.angle = s: 2 * Math.PI * obj.old.s / @total.old, e: 2 * Math.PI * obj.old.e / @total.old
        obj.cur.angle = s: 2 * Math.PI * obj.cur.s / @total.cur, e: 2 * Math.PI * obj.cur.e / @total.cur
        if obj.picked => offset += val

    interpolate-arc = (a1, a2, i) ~> (t) ~>
      arc
        .innerRadius (a2.r1 - a1.r1) * t + a1.r1
        .outerRadius (a2.r2 - a1.r2) * t + a1.r2
        .padAngle (a2.rp - a1.rp) * t + a1.rp

      [s,e] = <[s e]>.map (i) -> (a2.angle[i] - a1.angle[i]) * t + a1.angle[i]
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
            .attr \opacity, (d,i) ~> 0
            .attr \fill, (d,i) ~> tint.get(d.color-key or d._idx)
        n.selectAll \path.data
          .transition!duration 350
          .attrTween \d, (d,i) ->
            interpolate-arc d.old, d.cur, j
          .attr \fill, (d,i) ~> tint.get(d.color-key or d._idx)
          .attr \opacity, (d,i) ~>
            if !(h = hover.item) => return 1
            if h.category =>
              for j from 0 til h.category.length =>
                if d.category[j] != h.category[j] => return 0.3
                if j == d.category.length - 1 => break
              if d._lv == h._lv and d != h => return 0.3
              return 1
            else if hover.item.name == d.name => 1 else 0.3

        legend.render!
