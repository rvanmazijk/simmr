#' Plot different features of an object created from \code{\link{simmr_mcmc}}.
#'
#' This function allows for 4 different types of plots of the simmr output
#' created from \code{\link{simmr_mcmc}}. The types are: histogram, kernel
#' density plot, matrix plot (mose useful) and boxplot. There are some minor
#' customisation options.
#'
#' The matrix plot should form a necessary part of any SIMM analysis since it
#' allows the user to judge which sources are idenitifiable by the model.
#' Further detail about these plots is provided in the vignette.
#'
#' @param x An object of class \code{simmr_output} created via
#' \code{\link{simmr_mcmc}}
#' @param type The type of plot required. Can be one or more of 'histogram',
#' 'density', 'matrix', 'boxplot', or 'convergence'
#' @param group Which group to plot. Currently only one group allowed at a time
#' @param binwidth The width of the bins for the histogram. Defaults to 0.05
#' @param alpha The degree of transparency of the plots. Not relevant for
#' matrix plots
#' @param title The title of the plot.
#' @param ggargs Extra arguments to be included in the ggplot (e.g. axis limits)
#' @param ...  Currently not used
#'
#' @import ggplot2
#' @import graphics
#' @import viridis
#' @importFrom reshape2 "melt"
#' @importFrom coda "gelman.plot"
#' @importFrom stats "cor"
#'
#' @author Andrew Parnell <andrew.parnell@@ucd.ie>
#' @seealso See \code{\link{simmr_mcmc}} for creating objects suitable for this
#' function, and many more examples. See also \code{\link{simmr_load}} for
#' creating simmr objects, \code{\link{plot.simmr_input}} for creating isospace
#' plots, \code{\link{summary.simmr_output}} for summarising output.
#' @examples
#'
#' \dontrun{
#' # A simple example with 10 observations, 2 tracers and 4 sources
#'
#' # The data
#' mix = matrix(c(-10.13, -10.72, -11.39, -11.18, -10.81, -10.7, -10.54,
#' -10.48, -9.93, -9.37, 11.59, 11.01, 10.59, 10.97, 11.52, 11.89,
#' 11.73, 10.89, 11.05, 12.3), ncol=2, nrow=10)
#' colnames(mix) = c('d13C','d15N')
#' s_names=c('Source A','Source B','Source C','Source D')
#' s_means = matrix(c(-14, -15.1, -11.03, -14.44, 3.06, 7.05, 13.72, 5.96), ncol=2, nrow=4)
#' s_sds = matrix(c(0.48, 0.38, 0.48, 0.43, 0.46, 0.39, 0.42, 0.48), ncol=2, nrow=4)
#' c_means = matrix(c(2.63, 1.59, 3.41, 3.04, 3.28, 2.34, 2.14, 2.36), ncol=2, nrow=4)
#' c_sds = matrix(c(0.41, 0.44, 0.34, 0.46, 0.46, 0.48, 0.46, 0.66), ncol=2, nrow=4)
#' conc = matrix(c(0.02, 0.1, 0.12, 0.04, 0.02, 0.1, 0.09, 0.05), ncol=2, nrow=4)
#'
#' # Load into simmr
#' simmr_1 = simmr_load(mixtures=mix,
#'                      source_names=s_names,
#'                      source_means=s_means,
#'                      source_sds=s_sds,
#'                      correction_means=c_means,
#'                      correction_sds=c_sds,
#'                      concentration_means = conc)
#'
#' # Plot
#' plot(simmr_1)
#'
#'
#' # MCMC run
#' simmr_1_out = simmr_mcmc(simmr_1)
#'
#' # Plot
#' plot(simmr_1_out) # Creates all 5 plots
#' plot(simmr_1_out,type='boxplot')
#' plot(simmr_1_out,type='histogram')
#' plot(simmr_1_out,type='density')
#' plot(simmr_1_out,type='matrix')
#' plot(simmr_1_out,type='convergence')
#' }
#' @export
plot.simmr_output <-
function(x,
         type = c('isospace',
                  'histogram',
                  'density',
                  'matrix',
                  'boxplot',
                  'convergence'),
         group = 1,
         binwidth = 0.05,
         alpha = 0.5,
         title = if(length(group)==1){ 'simmr output plot'} else {paste('simmr output plot: group',group)},
         ggargs = NULL,
          ...) {

  # Get the specified type
  type=match.arg(type,several.ok=TRUE)

  # Iso-space plot is special as all groups go on one plot
  # Add in extra dots here as they can be sent to this plot function
  if('isospace' %in% type) graphics::plot(x$input,group=group,title=title,...)

  for(i in 1:length(group)) {

    # Stupid CRAN fix for variables - see here http://stackoverflow.com/questions/9439256/how-can-i-handle-r-cmd-check-no-visible-binding-for-global-variable-notes-when
    Proportion = Source = ..density.. = NULL

    # Prep data
    out_all = do.call(rbind,x$output[[group[i]]][,1:x$input$n_sources])
    df = reshape2::melt(out_all)
    colnames(df) = c('Num','Source','Proportion')

    if ('histogram'%in%type) {
      g=ggplot(df,aes(x=Proportion,y=..density..,fill=Source)) +
        scale_fill_viridis(discrete=TRUE) +
        geom_histogram(binwidth=binwidth,alpha=alpha) +
        theme_bw() +
        ggtitle(title[i]) +
        facet_wrap(~ Source) +
        theme(legend.position='none') +
        ggargs
      print(g)
    }

    if ('density'%in%type) {
      g=ggplot(df,aes(x=Proportion,y=..density..,fill=Source)) +
        scale_fill_viridis(discrete=TRUE) +
        geom_density(alpha=alpha,linetype=0) +
        theme_bw() +
        theme(legend.position='none') +
        ggtitle(title[i])  +
        ylab("Density") +
        facet_wrap(~ Source) +
        ggargs
      print(g)
    }

    if ('boxplot'%in%type) {
      g=ggplot(df,aes(y=Proportion,x=Source,fill=Source,alpha=alpha)) +
        scale_fill_viridis(discrete=TRUE) +
        geom_boxplot(alpha=alpha,notch=TRUE,outlier.size=0) +
        theme_bw() +
        ggtitle(title[i]) +
        theme(legend.position='none') +
        coord_flip() +
        ggargs
      print(g)
    }

    if ('convergence'%in%type) {
      coda::gelman.plot(x$output[[group[i]]],transform=TRUE)
    }

    if ('matrix'%in%type) {
      # These taken from the help(pairs) file
      panel.hist <- function(x, ...) {
        usr <- graphics::par("usr"); on.exit(graphics::par(usr))
        graphics::par(usr = c(usr[1:2], 0, 1.5) )
        h <- graphics::hist(x, plot = FALSE)
        breaks <- h$breaks; nB <- length(breaks)
        y <- h$counts; y <- y/max(y)
        graphics::rect(breaks[-nB], 0, breaks[-1], y, col = "lightblue", ...)
      }
      panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
      {
        usr <- graphics::par("usr"); on.exit(graphics::par(usr))
        graphics::par(usr = c(0, 1, 0, 1))
        r <- stats::cor(x, y)
        txt <- format(c(r, 0.123456789), digits = digits)[1]
        txt <- paste0(prefix, txt)
        if(missing(cex.cor)) cex.cor <- 0.8/graphics::strwidth(txt)
        graphics::text(0.5, 0.5, txt, cex = cex.cor * abs(r))
      }
      panel.contour <- function(x, y, ...)
      {
        usr <- graphics::par("usr"); on.exit(graphics::par(usr))
        graphics::par(usr = c(usr[1:2], 0, 1.5) )
        kd <- MASS::kde2d(x,y)
        kdmax <- max(kd$z)
        graphics::contour(kd,add=TRUE,drawlabels=FALSE,levels=c(kdmax*0.1,kdmax*0.25,kdmax*0.5,kdmax*0.75,kdmax*0.9))
      }
      graphics::pairs(out_all,xlim=c(0,1),ylim=c(0,1),main=title[i],diag.panel=panel.hist,lower.panel=panel.cor,upper.panel=panel.contour)
    }

  }


}
