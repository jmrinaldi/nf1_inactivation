# (C) Gregory Way 2016
# NF1 Inactivation Classifier for Glioblastoma
# scripts/viz/viz_roc.r
#
# Visualizes classifier performance by ROC
#
# Usage:
# Run with nf1_roc.py
#
# Output:
# average training/testing ROC and empirical cdf in multiplot

# Load library
library(ggplot2)

# Load Command Args
args <- commandArgs(trailingOnly = T)
print(args)
roc_fh <- args[1]
roc_png <- args[2]

# Load Data
roc_data <- readr::read_tsv(roc_fh)

# Plot
roc <- ggplot(roc_data, aes(x = fpr, y = tpr, colour = type, fill = type)) +
  labs(x = 'False Positive Rate', y = 'True Positive Rate') +
  geom_smooth(se = F) + ylim(0, 1) +
  geom_abline(intercept = 0, linetype="dotted", lwd = 1.5) +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(),
        title = element_text(size = rel(2)),
        axis.line.x = element_line(size = rel(1), linetype = "solid", color = "black"), 
        axis.line.y = element_line(size = rel(1), linetype = "solid", color = "black"), 
        axis.text = element_text(size = rel(1), color = "black"),
        axis.ticks = element_line(size = rel(1), color = "black"),
        axis.ticks.length = unit(0.2, "cm"),
        axis.title = element_text(size = rel(0.8)),
        axis.title.y = element_text(vjust = 4.5),
        axis.title.x = element_text(vjust = -4.5),
        legend.key.size = unit(1, "cm"),
        legend.text = element_text(size = rel(1.2)), 
        legend.title = element_blank(),
        legend.key = element_rect(fill = 'white'),
        plot.margin = unit(c(1.2, 2, 0, 1.5), 'cm'))

dens_cdf <- ggplot(roc_data, aes(x = auc, colour = type, fill = type)) + 
  stat_ecdf(aes(ymin = 0, ymax = ..y..), geom = 'ribbon', alpha = 0.5) +
  labs(x = 'Balanced AUROC', y = 'CDF') +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(),
        title = element_text(size = rel(2)),
        axis.line.x = element_line(size = rel(1), linetype = "solid", color = "black"), 
        axis.line.y = element_line(size = rel(1), linetype = "solid", color = "black"), 
        axis.text = element_text(size = rel(1), color = "black"),
        axis.ticks = element_line(size = rel(1), color = "black"),
        axis.ticks.length = unit(0.2, "cm"),
        axis.title = element_text(size = rel(0.8)),
        axis.title.y = element_text(vjust = 4.5),
        axis.title.x = element_text(vjust = -4.5),
        legend.key.size = unit(1, "cm"),
        legend.text = element_text(size = rel(1.2)), 
        legend.title = element_blank(),
        plot.margin = unit(c(0, 2, 2, 1.5), 'cm'))

plots <- list(roc, dens_cdf)
layout <- matrix(c(1, 1, 2), nrow = 3, byrow = TRUE)

png(roc_png, height = 500, width = 500)
Rmisc::multiplot(plotlist = plots, layout = layout)
dev.off()