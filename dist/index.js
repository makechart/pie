(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'pie',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: [],
      i18n: {
        "zh-TW": {
          value: "數值",
          name: "名稱",
          category: "分類",
          other: "其它"
        }
      }
    },
    init: function(arg$){
      var root, context, pubsub, t;
      root = arg$.root, context = arg$.context, pubsub = arg$.pubsub, t = arg$.t;
      return pubsub.fire('init', {
        mod: mod({
          context: context,
          t: t
        })
      });
    }
  };
  mod = function(arg$){
    var context, t, chart, d3, ref$;
    context = arg$.context, t = arg$.t;
    chart = context.chart, d3 = context.d3;
    return {
      sample: function(){
        return {
          raw: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30].map(function(val){
            return {
              val: (10 * Math.random()).toFixed(2),
              c1: "A" + Math.ceil(Math.random() * 7),
              c2: "B" + Math.ceil(Math.random() * 4),
              c3: "C" + Math.ceil(Math.random() * 4),
              name: "N:" + val
            };
          }),
          binding: {
            name: {
              key: 'name'
            },
            category: [
              {
                key: 'c1'
              }, {
                key: 'c2'
              }, {
                key: 'c3'
              }
            ],
            value: {
              key: 'val'
            }
          }
        };
      },
      config: (ref$ = chart.utils.config.from({
        tip: 'tip',
        preset: 'default',
        legend: 'legend'
      }), ref$.donut = {
        percent: {
          type: 'number',
          'default': 0.7,
          min: 0,
          max: 1,
          step: 0.01
        },
        padding: {
          type: 'number',
          'default': 0.03,
          min: 0,
          max: 1,
          step: 0.01
        }
      }, ref$),
      dimension: {
        name: {
          type: 'NCO',
          name: "name",
          priority: 10
        },
        value: {
          type: 'R',
          name: "value",
          priority: 20
        },
        category: {
          type: 'C',
          name: "category",
          priority: 25,
          multiple: true
        }
      },
      init: function(){
        var tint, this$ = this;
        this.g = Object.fromEntries(['view', 'legend'].map(function(it){
          return [it, d3.select(this$.layout.getGroup(it)).append('g')];
        }));
        this.tint = tint = new chart.utils.tint();
        this.tip = new chart.utils.tip({
          root: this.root,
          accessor: function(arg$){
            var evt, d, v, ref$;
            evt = arg$.evt;
            if (!(evt.target && (d = d3.select(evt.target).datum()))) {
              return null;
            }
            v = isNaN(d.value)
              ? '-'
              : d3.format(this$.cfg.tip.format || '.2s')(d.value) + "" + (this$.binding.value.unit || '');
            return {
              name: d.name || (d.category ? (ref$ = d.category)[ref$.length - 1] : '-'),
              value: v
            };
          },
          range: function(){
            return this$.layout.getNode('view').getBoundingClientRect();
          }
        });
        this.legend = new chart.utils.legend({
          layout: this.layout,
          name: 'legend',
          root: this.root,
          shape: function(d){
            return d3.select(this).attr('fill', tint.get(d.text));
          },
          cfg: {
            selectable: true
          }
        });
        this.legend.on('select', function(){
          this$.parse();
          this$.bind();
          this$.resize();
          return this$.render();
        });
        this.arc = d3.arc().startAngle(0).endAngle(Math.PI / 2);
        this.total = {};
        return this.hover = {};
      },
      destroy: function(){
        return this.tip.destroy();
      },
      parse: function(){
        var bindCat, oall, all, data, i$, to$, i, hash, k, v, list, lgdata;
        this.tint.reset();
        bindCat = this.binding.category || [];
        oall = this.all;
        this.all = all = [];
        data = this.data.map(function(it){
          var ref$;
          return ref$ = import$({}, it), ref$.value = isNaN(+it.value) || !it.value
            ? 0
            : +it.value, ref$;
        });
        for (i$ = 0, to$ = bindCat.length; i$ < to$; ++i$) {
          i = i$;
          hash = {};
          data.map(fn$);
          all.push((fn1$()));
        }
        all.push(data.map(function(it){
          return import$({
            colorKey: it.category[0] || it.name
          }, it);
        }));
        for (i$ = 0, to$ = all.length; i$ < to$; ++i$) {
          i = i$;
          list = all[i];
          list.sort(fn2$);
        }
        all.map(function(list, j){
          return list.map(function(n, i){
            n._idx = i;
            return n._lv = j;
          });
        });
        if (oall) {
          all.map(function(d, i){
            return d.map(function(e, j){
              var ref$;
              if (oall[i] && oall[i][j]) {
                return e.old = (ref$ = oall[i][j]).old, e.cur = ref$.cur, e;
              }
            });
          });
        }
        lgdata = this.all[0].map(function(it){
          return {
            text: it.colorKey,
            key: it.colorKey,
            value: it.value
          };
        });
        return this.legend.data(lgdata);
        function fn$(it){
          var cat, key;
          cat = it.category.slice(0, i + 1);
          key = cat.map(function(it){
            return ((it || '') + "").replace(/\//g, '//');
          }).join('/');
          if (!hash[key]) {
            hash[key] = {
              category: cat,
              colorKey: cat[0] || it.name,
              value: 0
            };
          }
          return hash[key].value += it.value;
        }
        function fn1$(){
          var ref$, results$ = [];
          for (k in ref$ = hash) {
            v = ref$[k];
            results$.push(v);
          }
          return results$;
        }
        function fn2$(a, b){
          var i$, to$, j, la, lb, ia, ib;
          for (i$ = 0, to$ = i; i$ < to$; ++i$) {
            j = i$;
            la = all[j].filter(fn$);
            lb = all[j].filter(fn1$);
            ia = la.map(fn2$).indexOf(a.category[j]);
            ib = lb.map(fn3$).indexOf(b.category[j]);
            if (ia === ib) {
              continue;
            }
            return ia - ib;
          }
          return b.value - a.value;
          function fn$(it){
            var i$, to$, k;
            for (i$ = 0, to$ = j; i$ < to$; ++i$) {
              k = i$;
              if (it.category[k] !== a.category[k]) {
                return false;
              }
            }
            return true;
          }
          function fn1$(it){
            var i$, to$, k;
            for (i$ = 0, to$ = j; i$ < to$; ++i$) {
              k = i$;
              if (it.category[k] !== b.category[k]) {
                return false;
              }
            }
            return true;
          }
          function fn2$(it){
            return it.category[j];
          }
          function fn3$(it){
            return it.category[j];
          }
        }
      },
      bind: function(){
        var this$ = this;
        return this.all.map(function(list){
          return list.map(function(n){
            return n.picked = this$.legend.isSelected(n.colorKey);
          });
        });
      },
      resize: function(){
        var ref$, rbox, lbox, w, h, size;
        this.tip.toggle(((ref$ = this.cfg).tip || (ref$.tip = {})).enabled != null ? this.cfg.tip.enabled : true);
        this.root.querySelector('.pdl-layout').classList.toggle('legend-bottom', this.cfg.legend.position === 'bottom');
        this.legend.config(import$({}, this.cfg.legend));
        this.legend.update();
        this.layout.update(false);
        rbox = this.root.getBoundingClientRect();
        lbox = this.layout.getBox('legend');
        if (this.cfg.legend.position === 'bottom') {
          ref$ = [rbox.width, rbox.height - lbox.height], w = ref$[0], h = ref$[1];
        } else {
          ref$ = [rbox.width - lbox.width, rbox.height], w = ref$[0], h = ref$[1];
        }
        size = w > h ? h : w;
        ref$ = this.layout.getNode('view').style;
        ref$.width = size + "px";
        ref$.height = size + "px";
        return this.layout.update(false);
      },
      render: function(){
        var binding, legend, arc, tint, all, cfg, hover, render, box, ref$, w, h, size, interpolateArc, x$, this$ = this;
        binding = this.binding, legend = this.legend, arc = this.arc, tint = this.tint, all = this.all, cfg = this.cfg, hover = this.hover;
        render = function(){
          return this$.render();
        };
        box = this.layout.getBox('view');
        ref$ = [box.width, box.height], w = ref$[0], h = ref$[1];
        size = Math.min(w, h);
        this.total.old = this.total.cur;
        this.total.cur = this.all[0].reduce(function(a, b){
          return a + (b.picked ? b.value : 0);
        }, 0) || 1;
        if (!this.total.old) {
          this.total.old = this.total.cur;
        }
        all.map(function(list, j){
          var offset, r1, r2, rp, rd, rr1, rr2, i$, to$, i, obj, that, val, results$ = [];
          offset = 0;
          r1 = cfg.donut.percent * size / 2;
          r2 = size / 2;
          rp = cfg.donut.padding * (r2 - r1) / (all.length - 1 || 1);
          rd = ((r2 - r1) * (1 - cfg.donut.padding)) / (all.length || 1);
          rr1 = r1 + (rd + rp) * j;
          rr2 = r1 + (rd + rp) * j + rd;
          rp = 0.002 * rp;
          for (i$ = 0, to$ = list.length; i$ < to$; ++i$) {
            i = i$;
            obj = list[i];
            if (!obj.old) {
              obj.old = {
                s: (that = list[i - 1]) ? that.old.e : 0,
                e: 0,
                r1: rr1,
                r2: rr1,
                rp: rp
              };
            }
            if (obj.cur) {
              obj.old = obj.cur;
            }
            val = obj.value || 0;
            obj.cur = {
              s: offset,
              e: offset + (obj.picked ? val : 0),
              r1: rr1,
              r2: rr2,
              rp: rp
            };
            obj.old.angle = {
              s: 2 * Math.PI * obj.old.s / this$.total.old,
              e: 2 * Math.PI * obj.old.e / this$.total.old
            };
            obj.cur.angle = {
              s: 2 * Math.PI * obj.cur.s / this$.total.cur,
              e: 2 * Math.PI * obj.cur.e / this$.total.cur
            };
            if (obj.picked) {
              results$.push(offset += val);
            }
          }
          return results$;
        });
        interpolateArc = function(a1, a2, i){
          return function(t){
            var ref$, s, e;
            arc.innerRadius((a2.r1 - a1.r1) * t + a1.r1).outerRadius((a2.r2 - a1.r2) * t + a1.r2).padAngle((a2.rp - a1.rp) * t + a1.rp);
            ref$ = ['s', 'e'].map(function(i){
              return (a2.angle[i] - a1.angle[i]) * t + a1.angle[i];
            }), s = ref$[0], e = ref$[1];
            this$.arc.startAngle(s).endAngle(e);
            return this$.arc();
          };
        };
        if (this.cfg != null && this.cfg.palette) {
          this.tint.set(this.cfg.palette.colors.map(function(it){
            return it.value || it;
          }));
        }
        box = this.layout.getBox('view');
        this.g.view.attr('transform', "translate(" + box.width / 2 + "," + box.height / 2 + ")");
        x$ = this.g.view.selectAll('g.ring').data(this.all);
        x$.exit().remove();
        x$.enter().append('g').attr('class', 'ring');
        return this.g.view.selectAll('g.ring').each(function(d, j){
          var n, x$;
          n = d3.select(this);
          x$ = n.selectAll('path.data').data(d, function(it){
            return it.name || it._idx;
          });
          x$.exit().remove();
          x$.enter().append('path').attr('class', 'data').on('mouseover', function(e, n, i){
            hover.item = n;
            return render();
          }).on('mouseout', function(e, n, i){
            hover.item = null;
            return render();
          }).attr('opacity', function(d, i){
            return 0;
          }).attr('fill', function(d, i){
            return tint.get(d.colorKey || d._idx);
          });
          n.selectAll('path.data').transition().duration(350).attrTween('d', function(d, i){
            return interpolateArc(d.old, d.cur, j);
          }).attr('fill', function(d, i){
            return tint.get(d.colorKey || d._idx);
          }).attr('opacity', function(d, i){
            var h, i$, to$, j;
            if (!(h = hover.item)) {
              return 1;
            }
            if (h.category) {
              for (i$ = 0, to$ = h.category.length; i$ < to$; ++i$) {
                j = i$;
                if (d.category[j] !== h.category[j]) {
                  return 0.3;
                }
                if (j === d.category.length - 1) {
                  break;
                }
              }
              if (d._lv === h._lv && d !== h) {
                return 0.3;
              }
              return 1;
            } else if (hover.item.name === d.name) {
              return 1;
            } else {
              return 0.3;
            }
          });
          return legend.render();
        });
      }
    };
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
