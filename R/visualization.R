classifIcePlot = function(pred, var, knots, lines, centered, center.x) {
  # ICE plots for regression tasks
  #
  # Args:
  #   pred (data frame): predictions from makePredictionsIce...(...)
  #   var (string): selected variable of interest on horizontal axis
  #   knots (numeric): selected number of knots = unique values on horizontal axis
  #   lines (numeric): selected number of lines = number sampled of observations
  #   centered (boolean): if TRUE, plot additional crosshair at center.x
  #   center.x (numeric): indicates the centering point to plot crosshair at
  # Returns:
  #   ggplot2 object
  iceplot.data = melt(pred, id.vars = var) %>%
    mutate(class = sub('\\..*$','', variable))
  # create class variable by stripping away parts of string after the
  # dot e.g.(class1.pred1) -> (class1)
  if (lines <= 15) {
    line.alpha = 1
    line.size = 0.7
  } else if (lines > 15 & lines <= 45) {
    line.alpha = 0.7
    line.size = 0.5
  } else if (lines > 45 & lines <= 100) {
    line.alpha = 0.6
    line.size = 0.4
  } else if (lines > 10) {
    line.alpha = 0.4
    line.size = 0.3
  }
  plot = ggplot() +
    geom_line(
      data = iceplot.data,
      aes_string(
        x = var, y = "value", group = "variable", color = "class"),
      size = line.size,
      alpha = line.alpha
    ) +
    geom_line(
      data = iceplot.data[grep("ave", iceplot.data$variable), ],
      aes_string(
        x = var, y = "value", group = "class", color = "class"),
      size = 1, linetype = "dashed") +
    theme_pubr()

  if (centered == TRUE) {
    if (is.factor(pred[[var]])) {
      center.x = match(center.x, levels(pred[[var]]))
    }
    plot = plot +
      geom_hline(yintercept = 0, linetype = "dashed") +
      geom_vline(xintercept = as.numeric(center.x), linetype = "dashed")
  } else {}
  return(plot)
}

classifPartialDependencePlot = function(pred, var, target, knots) {
  # ICE plots for regression tasks
  #
  # Args:
  #   pred (data.frame): of predictions from makePredictionsIce...(...)
  #   var (string): selected variable of interest on horizontal axis
  #   target (string): selected target variable for predictons
  # Returns:
  #   ggplot2 object
  iceplot.data = melt(pred, id.vars = var) %>%
    mutate(class = sub('\\..*$','', variable))
  pdp.data = iceplot.data[grep("ave", iceplot.data$variable), ]

  plot = ggplot(
    data = pdp.data,
    aes_string( x = var, y = "value", group = "class", color = "class")) +
    geom_line(size = 0.3) +
    labs(y = paste("Probability for for classif.", target, "as..", sep = " "),
         color = "Class") +
    theme(legend.position= "bottom", legend.direction = "vertical") +
    theme_pubr()
  return(plot)
}

regrPartialDependencePlot = function(pred, var, target, knots) {
  # PDP for regression tasks
  #
  # Args:
  #   pred (data.frame): predictions from makePredictionsIce...(...)
  #   var (string): selected variable of interest on horizontal axis
  #   target (string): selected target variable for predictons
  # Returns:
  #   ggplot2 object
  plot = ggplot() +
    geom_line(
      data = pred,
      aes_string(x = var, y = "preds.ave", group = factor(var)),
      color = "steelblue",
      size = 1) +
    labs(y =  target) +
    theme_pubr()
  return(plot)
}

regrIcePlot = function(pred, var, target, knots, lines, centered, center.x) {
  # ICE plots for regression tasks
  #
  # Args:
  #   pred (data.frame): predictions from makePredictionsIce...(...)
  #   var (string): selected variable of interest on horizontal axis
  #   target (string): selected target variable for predictons
  #   lines (numeric): selected number of lines = number sampled of observations
  #   centered (boolean): if TRUE, plot additional crosshair at center.x
  #   center.x (numeric): indicates the centering point to plot crosshair at
  # Returns:
  #   ggplot2 object
  if (lines <= 15) {
    line.alpha = 1
    line.size = 0.7
  } else if (lines > 15 & lines <= 45) {
    line.alpha = 0.7
    line.size = 0.5
  } else if (lines > 45 & lines <= 100) {
    line.alpha = 0.6
    line.size = 0.4
  } else if (lines > 10) {
    line.alpha = 0.4
    line.size = 0.3
  }

  iceplot.data = melt(pred, id.vars = var)

  plot = ggplot() +
    geom_line(
      data = iceplot.data,
      aes_string(
        x = var, y = "value", group = "variable"),
      color = "steelblue",
      size = line.size,
      alpha = line.alpha) +
    geom_line(
      data = iceplot.data[iceplot.data$variable == "preds.ave", ],
      aes_string(x = var, y = "value", group = "variable"),
      color = "brown",
      size = 1) +
    labs(y =  target) +
    theme_pubr()

  if (centered == TRUE) {
    if (is.factor(pred[[var]])) {
      center.x = match(center.x, levels(pred[[var]]))
    }
    plot = plot +
      geom_hline(yintercept = 0, linetype = "dashed") +
      geom_vline(xintercept = as.numeric(center.x), linetype = "dashed")
  } else {}
  return(plot)
}


regrAlePlot = function(data, target, var1, var2 = NULL, knots = NULL,
                       gfx.package = "ggplot2") {
  # ALE plots for regression tasks
  #
  # Args:
  #   pred (data.frame): predictions from makePredictionsIce...(...)
  #   target (string): target variable for predictions
  #   var1 (string): selected variable of interest on horizontal axis
  #   var2 (string): selected interaction variable for ALE second order effects
  #   gfx.package (string): selected package for rendering plots
  #                         (ggplot2 or plotly)
  # Returns:
  #   ggplot2 or plotly object
  if ("error" %in% data) {
    plot = ggplot() +
      annotate(
        geom = "text",
        x = 1, y = 1,
        label = paste(
          "ALEPlot function returned error or warning message. \n",
          "See console output for more details."),
        size = 5
      ) +
      theme_pubr()
  } else {
    # no error or warning
    if (is.null(var2)) {
      # line plot
      plot = ggplot(
        data = data,
        aes_string(x = var1, y = "ale.effect", group = factor(var1))) +
        geom_line(size = 1, color = "steelblue") +
        labs(y = paste("ALE main effect on", target), x = var1) +
        theme_pubr()
    } else {
      # two variables
      if (gfx.package == "ggplot2") {
        # 2d heat map
        plot = ggplot(
          data = data, aes_string(x = var1, y = var2, color = "ale.effect")) +
          stat_summary_2d(aes(z = ale.effect), fun = mean, bins = 50) +
          theme_pubr()
      } else if (gfx.package == "plotly") {
        # 3d scatter
        df = acast(data, get(var1) ~ get(var2), value.var = "ale.effect", drop = FALSE)
        x = rownames(df)
        x.axis.type = ifelse(is.factor(data[[var1]]), "category", "linear")
        y = colnames(df)
        plot = plot_ly(x = x, y = y, z = df, type = "surface") %>%
        layout(scene = list(
          xaxis = list(title = var1, type = x.axis.type),
          yaxis = list(title = var2),
          zaxis = list(title = paste("ALE effect on", target)))
        )
      }
    }
  }
  return(plot)
}

classifAlePlot = function(data, target, target.levels = NULL, var1, var2) {
  # ALE plots for classification tasks
  #
  # Args:
  #   pred (data.frame): predictions from makePredictionsIce...(...)
  #   target (string): target variable for predictions
  #   var1 (string): selected variable of interest on horizontal axis
  #   var2 (string): selected interaction variable for ALE second order effects
  #   gfx.package (string): selected package for rendering plots
  #                         (ggplot2 or plotly)
  # Returns:
  #   ggplot2 or plotly object

  if ("error" %in% data) {
    plot = ggplot() +
      annotate(
        geom = "text",
        x = 1, y = 1,
        label = paste(
          "ALEPlot function returned error or warning message. \n",
          "See console output for more details."),
        size = 5
      ) +
      theme_pubr()
  } else {
    if (is.null(var2)) {
      # no error or warning
      aleplot.data = melt(data, id.vars = var1)
      
      plot = ggplot(
        data = aleplot.data,
        aes_string(x = var1, y = "value", group = "variable", color = "variable")) +
        geom_line(size = 0.3) +
        labs(y = paste("ALE effect on probability for classif.", target, "as..", sep = " "),
             color = "Class") +
        theme(legend.position= "bottom", legend.direction = "vertical") +
        theme_pubr()
    } else {
      x1 = data$x[[1]]
      x2 = data$x[[2]]
      f.list = data$f
      plot.list = lapply(
        seq(target.levels),
        FUN = function(class.index) {
          df = f.list[[class.index]] 
          rownames(df) = x1
          colnames(df) = x2
          df = melt(df, na.rm = TRUE)
          colnames(df) = c(var1, var2, "ale.effect")
          plot = ggplot(
            data = df,
            aes_string(x = var1, y = var2, color = "ale.effect")) +
            stat_summary_2d(aes(z = ale.effect), fun = mean, bins = 50) +
            theme_pubr()
          return(plot)}
      )
      # n = length(plot.list)
      # n.col = floor(sqrt(n))
      # plot = do.call("arrangeGrob", c(plot.list, ncol = n.col))
      plot = arrangeGridSharedLegend(plot.list)
    }
  }
  return(plot)
}


scatterPlot = function(data, target, var, highlighted) {
  # 2 dimensional scatter plot
  #
  # Args:
  #   data (data.frame): data containing at least two columns
  #   target (string): vertical axis variable
  #   var (string): horizontal axis variable
  #   highlighted (numeric vector): row indices of highlighted observations
  # Returns:
  #   ggplot2 object
  if (nrow(data) <= 100) {
    pointsize = 1.5
  } else if (nrow(data) > 100 & nrow(data) <= 600) {
    pointsize = 1.2
  } else if (nrow(data > 600) & nrow(data) <= 1000) {
    pointsize = 0.8
  } else {
    pointsize = 0.6
  }
  plot = ggplot(data = data, aes_string(y = target, x = var)) +
    geom_point(size = pointsize, color = "steelblue", shape = 1) +
    geom_point(
      data = data[which(rownames(data) %in% highlighted), ],
      shape = 19,
      color = "brown",
      size = 3) +
    theme_pubr()
  return(plot)
}

scatterPlot3D = function(data, target, var, highlighted = NULL) {
  # 3 dimensional scatter plot
  #
  # Args:
  #   data (data.frame): data containing at least three columns
  #   target (string): z axis variable
  #   var (string vector): x and y axis variables
  #   highlighted (numeric vector): row indices of highlighted observations
  # Returns:
  #   plotly object
  plot = plot_ly(x = ~get(var[[1]]), y = ~get(var[[2]]), z = ~get(target)) %>%
    add_markers(data = data, marker = list(size = 3)) %>%
    layout(scene = list(xaxis = list(title = var[[1]]),
                        yaxis = list(title = var[[2]]),
                        zaxis = list(title = target))
    )
  if (!is.null(highlighted)) {
    plot = plot %>%
      add_markers(data = data[which(rownames(data) %in% highlighted), ],
                  marker = list(size = 5, color = "brown"))
  } else {}
  return(plot)
}

placeholderPlot = function() {
  # placeholder plot appears, if no observations can be found for predictions
  # Returns:
  #   ggplot2 object
  plot = ggplot() +
    annotate(geom = "text",
             x = 1, y = 1,
             label = "No observations detected.
             Change filter selections and / or sampling mode in data tab.",
             size = 5
    ) +
    theme_pubr()
  return(plot)
}

# arrangeGridSharedLegend = function(plots, position = c("bottom", "right")) {
#   function to arrange multiple ggplots with shared legend
#
#   position = match.arg(position)
#   g = ggplotGrob(plots[[1]] + theme(legend.position=position))$grobs
#   legend = g[[which(sapply(g, function(x) x$name) == "guide-box")]]
#   lheight = sum(legend$height)
#   lwidth = sum(legend$width)
#   gl = lapply(plots, function(x) x + theme_pubr(legend = "none"))
#   
#   combined = switch(
#     position,
#     "bottom" = arrangeGrob(
#       do.call(arrangeGrob, gl),
#       legend,
#       ncol = 1,
#       heights = unit.c(unit(1, "npc") - lheight, lheight)),
#     "right" = arrangeGrob(
#       do.call(arrangeGrob, gl),
#       legend,
#       ncol = 2,
#       widths = unit.c(unit(1, "npc") - lwidth, lwidth)))
#   #   combined
#   dev.off()
#   grid.draw(combined)
# }

