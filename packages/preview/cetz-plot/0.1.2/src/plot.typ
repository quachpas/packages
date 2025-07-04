#import "/src/cetz.typ": util, draw, matrix, vector, styles, palette
#import util: bezier

#import "/src/axes.typ"
#import "/src/plot/sample.typ": sample-fn, sample-fn2
#import "/src/plot/line.typ": add, add-hline, add-vline, add-fill-between
#import "/src/plot/contour.typ": add-contour
#import "/src/plot/boxwhisker.typ": add-boxwhisker
#import "/src/plot/util.typ" as plot-util
#import "/src/plot/legend.typ" as plot-legend
#import "/src/plot/annotation.typ": annotate, calc-annotation-domain
#import "/src/plot/bar.typ": add-bar
#import "/src/plot/errorbar.typ": add-errorbar
#import "/src/plot/mark.typ"
#import "/src/plot/violin.typ": add-violin
#import "/src/plot/formats.typ"
#import plot-legend: add-legend

#let default-colors = (blue, red, green, yellow, black)

#let default-plot-style(i) = {
  let color = default-colors.at(calc.rem(i, default-colors.len()))
  return (stroke: color,
          fill: color.lighten(75%))
}

#let default-mark-style(i) = {
  return default-plot-style(i)
}

/// Create a plot environment. Data to be plotted is given by passing it to the
/// `plot.add` or other plotting functions. The plot environment supports different
/// axis styles to draw, see its parameter `axis-style:`.
///
/// ```cexample
/// plot.plot(size: (2,2), x-tick-step: none, y-tick-step: none, {
///   plot.add(((0,0), (1,1), (2,.5), (4,3)))
/// })
/// ```
///
/// To draw elements insides a plot, using the plots coordinate system, use
/// the `plot.annotate(..)` function.
///
/// === Options
///
/// You can use the following options to customize each axis of the plot. You must pass them as named arguments prefixed by the axis name followed by a dash (`-`) they should target. Example: `x-min: 0`, `y-ticks: (..)` or `x2-label: [..]`.
///
/// #show-parameter-block("label", ("none", "content"), default: "none", [
///   The axis' label. If and where the label is drawn depends on the `axis-style`.])
/// #show-parameter-block("min", ("auto", "float"), default: "auto", [
///   Axis lower domain value. If this is set greater than than `max`, the axis' direction is swapped])
/// #show-parameter-block("max", ("auto", "float"), default: "auto", [
///   Axis upper domain value. If this is set to a lower value than `min`, the axis' direction is swapped])
/// #show-parameter-block("equal", ("string"), default: "none", [
///   Set the axis domain to keep a fixed aspect ratio by multiplying the other axis domain by the plots aspect ratio,
///   depending on the other axis orientation (see `horizontal`).
///   This can be useful to force one axis to grow or shrink with another one.
///   You can only "lock" two axes of different orientations.
///   ```cexample
///   plot.plot(size: (2,1), x-tick-step: 1, y-tick-step: 1,
///             x-equal: "y",
///   {
///     plot.add(domain: (0, 2 * calc.pi),
///       t => (calc.cos(t), calc.sin(t)))
///   })
///   ```
/// ])
/// #show-parameter-block("horizontal", ("bool"), default: "axis name dependant", [
///   If true, the axis is considered an axis that gets drawn horizontally, vertically otherwise.
///   The default value depends on the axis name on axis creation. Axes which name start with `x` have this
///   set to `true`, all others have it set to `false`. Each plot has to use one horizontal and one
///   vertical axis for plotting, a combination of two y-axes will panic: ("y", "y2").
/// ])
/// #show-parameter-block("tick-step", ("none", "auto", "float"), default: "auto", [
///   The increment between tick marks on the axis. If set to `auto`, an
///   increment is determined. When set to `none`, incrementing tick marks are disabled.])
/// #show-parameter-block("minor-tick-step", ("none", "float"), default: "none", [
///   Like `tick-step`, but for minor tick marks. In contrast to ticks, minor ticks do not have labels.])
/// #show-parameter-block("ticks", ("none", "array"), default: "none", [
///   A List of custom tick marks to additionally draw along the axis. They can be passed as
///   an array of `<float>` values or an array of `(<float>, <content>)` tuples for
///   setting custom tick mark labels per mark.
///
///   ```cexample
///   plot.plot(x-tick-step: none, y-tick-step: none,
///             x-min: 0, x-max: 4,
///             x-ticks: (1, 2, 3),
///             y-min: 1, y-max: 2,
///             y-ticks: ((1, [One]), (2, [Two])),
///   {
///     plot.add(((0,0),))
///   })
///   ```
///
///   Examples: `(1, 2, 3)` or `((1, [One]), (2, [Two]), (3, [Three]))`])
/// #show-parameter-block("format", ("none", "string", "function"), default: "float", [
///   How to format the tick label: You can give a function that takes a `<float>` and return
///   `<content>` to use as the tick label. You can also give one of the predefined options:
///   / float: Floating point formatting rounded to two digits after the point (see `decimals`)
///   / sci: Scientific formatting with $times 10^n$ used as exponet syntax
///
///   ```cexample
///   let formatter(v) = if v != 0 {$ #{v/calc.pi} pi $} else {$ 0 $}
///   plot.plot(x-tick-step: calc.pi, y-tick-step: none,
///             x-min: 0, x-max: 2 * calc.pi,
///             x-format: formatter,
///   {
///     plot.add(((0,0),))
///   })
///   ```
/// ])
/// #show-parameter-block("decimals", ("int"), default: "2", [
///   Number of decimals digits to display for tick labels, if the format is set
///   to `"float"`.
/// ])
/// #show-parameter-block("mode", ("none", "string"), default: "none", [
///   The scaling function of the axis. Takes `lin` (default) for linear scaling,
///   and `log` for logarithmic scaling.])
/// #show-parameter-block("base", ("none", "number"), default: "none", [
///   The base to be used when labeling axis ticks in logarithmic scaling])
/// #show-parameter-block("grid", ("bool", "string"), default: "false", [
///   If `true` or `"major"`, show grid lines for all major ticks. If set
///   to `"minor"`, show grid lines for minor ticks only.
///   The value `"both"` enables grid lines for both, major- and minor ticks.
///
///   ```cexample
///   plot.plot(x-tick-step: 1, y-tick-step: 1,
///             y-minor-tick-step: .2,
///             x-min: 0, x-max: 2, x-grid: true,
///             y-min: 0, y-max: 2, y-grid: "both", {
///     plot.add(((0,0),))
///   })
///   ```
/// ])
/// #show-parameter-block("break", ("bool"), default: "false", [
///   If true, add a "sawtooth" at the start or end of the axis line, depending
///   on the axis bounds. If the axis min. value is > 0, a sawtooth is added
///   to the start of the axes, if the axis max. value is < 0, a sawtooth is added
///   to its end.])
///
/// - body (body): Calls of `plot.add` or `plot.add-*` commands. Note that normal drawing
///   commands like `line` or `rect` are not allowed inside the plots body, instead wrap
///   them in `plot.annotate`, which lets you select the axes used for drawing.
/// - size (array): Plot size tuple of `(<width>, <height>)` in canvas units.
///   This is the plots inner plotting size without axes and labels.
/// - axis-style (none, string): How the axes should be styled:
///   / scientific: Frames plot area using a rectangle and draw axes `x` (bottom), `y` (left), `x2` (top), and `y2` (right) around it.
///     If `x2` or `y2` are unset, they mirror their opposing axis.
///   / scientific-auto: Draw set (used) axes `x` (bottom), `y` (left), `x2` (top) and `y2` (right) around
///     the plotting area, forming a rect if all axes are in use or a L-shape if only `x` and `y` are in use.
///   / school-book: Draw axes `x` (horizontal) and `y` (vertical) as arrows pointing to the right/top with both crossing at $(0, 0)$
///   / left: Draw axes `x` and `y` as arrows, while the y axis stays on the left (at `x.min`)
///               and the x axis at the bottom (at `y.min`)
///   / `none`: Draw no axes (and no ticks).
///
///   ```cexample-vertical
///   let opts = (x-tick-step: none, y-tick-step: none, size: (2,1))
///   let data = plot.add(((-1,-1), (1,1),), mark: "o")
///
///   for name in (none, "school-book", "left", "scientific") {
///     plot.plot(axis-style: name, ..opts, data, name: "plot")
///     content(((0,-1), "-|", "plot.south"), repr(name))
///     set-origin((3.5,0))
///   }
///   ```
/// - plot-style (style,function): Styling to use for drawing plot graphs.
///   This style gets inherited by all plots and supports `palette` functions.
///   The following style keys are supported:
///   #show-parameter-block("stroke", ("none", "stroke"), default: 1pt, [
///     Stroke style to use for stroking the graph.
///   ])
///   #show-parameter-block("fill", ("none", "paint"), default: none, [
///     Paint to use for filled graphs. Note that not all graphs may support filling and
///     that you may have to enable filling per graph, see `plot.add(fill: ..)`.
///   ])
/// - mark-style (style,function): Styling to use for drawing plot marks.
///   This style gets inherited by all plots and supports `palette` functions.
///   The following style keys are supported:
///   #show-parameter-block("stroke", ("none", "stroke"), default: 1pt, [
///     Stroke style to use for stroking the mark.
///   ])
///   #show-parameter-block("fill", ("none", "paint"), default: none, [
///     Paint to use for filling marks.
///   ])
/// - fill-below (bool): If true, the filled shape of plots is drawn _below_ axes.
/// - name (string): The plots element name to be used when referring to anchors
/// - legend (none, auto, coordinate): The position the legend will be drawn at. See plot-legends for information about legends. If set to `<auto>`, the legend's "default-placement" styling will be used. If set to a `<coordinate>`, it will be taken as relative to the plot's origin.
/// - legend-anchor (auto, string): Anchor of the legend group to use as its origin.
///   If set to `auto` and `lengend` is one of the predefined legend anchors, the
///   opposite anchor to `legend` gets used.
/// - legend-style (style): Style key-value overwrites for the legend style with style root `legend`.
/// - ..options (any): Axis options, see _options_ below.
#let plot(body,
          size: (1, 1),
          axis-style: "scientific",
          name: none,
          plot-style: default-plot-style,
          mark-style: default-mark-style,
          fill-below: true,
          legend: auto,
          legend-anchor: auto,
          legend-style: (:),
          ..options
          ) = draw.group(name: name, ctx => {
  draw.assert-version(version(0, 4, 0))

  // Create plot context object
  let make-ctx(x, y, size) = {
    assert(x != none, message: "X axis does not exist")
    assert(y != none, message: "Y axis does not exist")
    assert(size.at(0) > 0 and size.at(1) > 0, message: "Plot size must be > 0")

    let x-scale =  ((x.max - x.min) / size.at(0))
    let y-scale =  ((y.max - y.min) / size.at(1))

    if y.horizontal {
      (x-scale, y-scale) = (y-scale, x-scale)
    }

    return (x: x, y: y, size: size, x-scale: x-scale, y-scale: y-scale)
  }

  // Setup data viewport
  let data-viewport(data, x, y, size, body, name: none) = {
    if body == none or body == () { return }

    assert.ne(x.horizontal, y.horizontal,
      message: "Data must use one horizontal and one vertical axis!")

    // If y is the horizontal axis, swap x and y
    // coordinates by swapping the transformation
    // matrix columns.
    if y.horizontal {
      (x, y) = (y, x)
      body = draw.set-ctx(ctx => {
        ctx.transform = matrix.swap-cols(ctx.transform, 0, 1)
        return ctx
      }) + body
    }

    // Setup the viewport
    axes.axis-viewport(size, x, y, none, body, name: name)
  }

  let data = ()
  let anchors = ()
  let annotations = ()
  let body = if body != none { body } else { () }

  for cmd in body {
    assert(type(cmd) == dictionary and "type" in cmd,
           message: "Expected plot sub-command in plot body")
    if cmd.type == "anchor" {
      anchors.push(cmd)
    } else if cmd.type == "annotation" {
      annotations.push(cmd)
    } else { data.push(cmd) }
  }

  assert(axis-style in (none, "scientific", "scientific-auto", "school-book", "left"),
    message: "Invalid plot style")

  // Create axes for data & annotations
  let axis-dict = (:)
  for d in data + annotations {
    if "axes" not in d { continue }

    for (i, name) in d.axes.enumerate() {
      if not name in axis-dict {
        axis-dict.insert(name, axes.axis(
          min: none, max: none))
      }

      let axis = axis-dict.at(name)
      let domain = if i == 0 {
        d.at("x-domain", default: (none, none))
      } else {
        d.at("y-domain", default: (none, none))
      }
      if domain != (none, none) {
        axis.min = util.min(axis.min, ..domain)
        axis.max = util.max(axis.max, ..domain)
      }

      axis-dict.at(name) = axis
    }
  }

  // Create axes for anchors
  for a in anchors {
    for (i, name) in a.axes.enumerate() {
      if not name in axis-dict {
        axis-dict.insert(name, axes.axis(min: none, max: none))
      }
    }
  }

  // Adjust axis bounds for annotations
  for a in annotations {
    let (x, y) = a.axes.map(name => axis-dict.at(name))
    (x, y) = calc-annotation-domain(ctx, x, y, a)
    axis-dict.at(a.axes.at(0)) = x
    axis-dict.at(a.axes.at(1)) = y
  }

  // Set axis options
  axis-dict = plot-util.setup-axes(ctx, axis-dict, options.named(), size)

  // Prepare styles
  for i in range(data.len()) {
    if "style" not in data.at(i) { continue }

    let style-base = plot-style
    if type(style-base) == function {
      style-base = (style-base)(i)
    }
    assert.eq(type(style-base), dictionary,
      message: "plot-style must be of type dictionary")

    if type(data.at(i).style) == function {
      data.at(i).style = (data.at(i).style)(i)
    }
    assert.eq(type(style-base), dictionary,
      message: "data plot-style must be of type dictionary")

    data.at(i).style = util.merge-dictionary(
      style-base, data.at(i).style)

    if "mark-style" in data.at(i) {
      let mark-style-base = mark-style
      if type(mark-style-base) == function {
        mark-style-base = (mark-style-base)(i)
      }
      assert.eq(type(mark-style-base), dictionary,
        message: "mark-style must be of type dictionary")

      if type(data.at(i).mark-style) == function {
        data.at(i).mark-style = (data.at(i).mark-style)(i)
      }

      if type(data.at(i).mark-style) == dictionary {
        data.at(i).mark-style = util.merge-dictionary(
          mark-style-base,
          data.at(i).mark-style
        )
      }
    }
  }

  draw.group(name: "plot", {
    draw.anchor("origin", (0, 0))

    // Prepare
    for i in range(data.len()) {
      if "axes" not in data.at(i) { continue }

      let (x, y) = data.at(i).axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      if "plot-prepare" in data.at(i) {
        data.at(i) = (data.at(i).plot-prepare)(data.at(i), plot-ctx)
        assert(data.at(i) != none,
          message: "Plot prepare(self, cxt) returned none!")
      }
    }

    // Background Annotations
    for a in annotations.filter(a => a.background) {
      let (x, y) = a.axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      data-viewport(a, x, y, size, {
        draw.anchor("default", (0, 0))
        a.body
      })
    }

    // Fill
    if fill-below {
      for d in data {
        if "axes" not in d { continue }

        let (x, y) = d.axes.map(name => axis-dict.at(name))
        let plot-ctx = make-ctx(x, y, size)

        data-viewport(d, x, y, size, {
          draw.anchor("default", (0, 0))
          draw.set-style(..d.style)

          if "plot-fill" in d {
            (d.plot-fill)(d, plot-ctx)
          }
        })
      }
    }

    if axis-style in ("scientific", "scientific-auto") {
      let draw-unset = if axis-style == "scientific" {
        true
      } else {
        false
      }

      let mirror = if axis-style == "scientific" {
        auto
      } else {
        none
      }

      axes.scientific(
        size: size,
        draw-unset: draw-unset,
        bottom: axis-dict.at("x", default: none),
        top: axis-dict.at("x2", default: mirror),
        left: axis-dict.at("y", default: none),
        right: axis-dict.at("y2", default: mirror),)
    } else if axis-style == "left" {
      axes.school-book(
        size: size,
        axis-dict.x,
        axis-dict.y,
        x-position: axis-dict.y.min,
        y-position: axis-dict.x.min)
    } else if axis-style == "school-book" {
      axes.school-book(
        size: size,
        axis-dict.x,
        axis-dict.y,)
    }

    // Stroke + Mark data
    for d in data {
      if "axes" not in d { continue }

      let (x, y) = d.axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      data-viewport(d, x, y, size, {
        draw.anchor("default", (0, 0))
        draw.set-style(..d.style)

        if not fill-below and "plot-fill" in d {
          (d.plot-fill)(d, plot-ctx)
        }
        if "plot-stroke" in d {
          (d.plot-stroke)(d, plot-ctx)
        }
      })

      if "mark" in d and d.mark != none {
        draw.scope({
          if y.horizontal {
            draw.set-ctx(ctx => {
              ctx.transform = matrix.swap-cols(ctx.transform, 0, 1)
              return ctx
            })
          }

          draw.set-style(..d.style, ..d.mark-style)
          mark.draw-mark(d.data, x, y, d.mark, d.mark-size, size)
        })
      }
    }

    // Foreground Annotations
    for a in annotations.filter(a => not a.background) {
      let (x, y) = a.axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      data-viewport(a, x, y, size, {
        draw.anchor("default", (0, 0))
        a.body
      })
    }

    // Place anchors
    for a in anchors {
      let (x, y) = a.axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      let pt = a.position.enumerate().map(((i, v)) => {
        if v == "min" { return axis-dict.at(a.axes.at(i)).min }
        if v == "max" { return axis-dict.at(a.axes.at(i)).max }
        return v
      })
      pt = axes.transform-vec(size, x, y, none, pt)
      if pt != none {
        draw.anchor(a.name, pt)
      }
    }
  })

  // Draw the legend
  if legend != none {
    let items = data.filter(d => "label" in d and d.label != none)
    if items.len() > 0 {
      let legend-style = styles.resolve(ctx.style,
        base: plot-legend.default-style, merge: legend-style, root: "legend")

      plot-legend.add-legend-anchors(legend-style, "plot", size)
      plot-legend.legend(legend, anchor: legend-anchor, {
        for item in items {
          let preview = if "plot-legend-preview" in item {
            _ => {(item.plot-legend-preview)(item) }
          } else {
            auto
          }

          plot-legend.item(item.label, preview,
            mark: item.at("mark", default: none),
            mark-size: item.at("mark-size", default: none),
            mark-style: item.at("mark-style", default: none),
            ..item.at("style", default: (:)))
        }
      }, ..legend-style)
    }
  }

  draw.copy-anchors("plot")
})

/// Add an anchor to a plot environment
///
/// This function is similar to `draw.anchor` but it takes an additional
/// axis tuple to specify which axis coordinate system to use.
///
/// ```cexample
/// plot.plot(size: (2,2), name: "plot",
///           x-tick-step: none, y-tick-step: none, {
///   plot.add(((0,0), (1,1), (2,.5), (4,3)))
///   plot.add-anchor("pt", (1,1))
/// })
///
/// line("plot.pt", ((), "|-", (0,1.5)), mark: (start: ">"), name: "line")
/// content("line.end", [Here], anchor: "south", padding: .1)
/// ```
///
/// - name (string): Anchor name
/// - position (tuple): Tuple of x and y values.
///   Both values can have the special values "min" and
///   "max", which resolve to the axis min/max value.
///   Position is in axis space defined by the axes passed to `axes`.
/// - axes (tuple): Name of the axes to use `("x", "y")` as coordinate
///   system for `position`. Note that both axes must be used,
///   as `add-anchors` does not create them on demand.
#let add-anchor(name, position, axes: ("x", "y")) = {
  ((
    type: "anchor",
    name: name,
    position: position,
    axes: axes,
  ),)
}
