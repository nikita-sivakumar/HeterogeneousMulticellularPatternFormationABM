rm(list=ls())
setwd("/Users/niki/Dropbox/Nikita/College/Projects/Lazzara Lab/ABM_Wendell&Lim/Circuit_ABCD_Asymm_01/Output_3.1/HomotypicAdhesion_ExpExpressionConst")
outpath = paste("/Users/niki/Dropbox/Nikita/College/Projects/Lazzara Lab/ABM_Wendell&Lim/Circuit_ABCD_Asymm_01/Output_3.1/HomotypicAdhesion_ExpExpressionConst/R-plots-100-100/")

library(readxl)
library(ggplot2)
library(plotly)
library(purrr)
library(tidyr)
library(dplyr)
library(plotly)
library(rPraat)

all_features <- read_excel ("HomotypicHeterotypic_all_features_ratios.xlsx")
# all_features <- read_excel ("ExpExpressionCostCD_all_features_ratios.xlsx")
features = unique(all_features$Feature)
radii = unique(all_features$Radius)
all_features$Exp_C <- factor(all_features$Exp_C)
all_features$Exp_D <- factor(all_features$Exp_D,levels=c('10','0.2','0.05'))
all_features$Value <- as.numeric(all_features$Value)
# features = unique(all_features$Feature)
# all_features$Exp_C <- factor(all_features$Exp_C,levels=c('0.05','0.2','10'))
# all_features$Exp_D <- factor(all_features$Exp_D,levels=c('10','0.2','0.05'))
# all_features$label <- factor(all_features$label,levels=c('2','0','3','5','4','1','6'))

# all_features$Hetertoypic_Prob <- as.numeric(all_features$Heterotypic_Prob)
plot = list()
i = 1
freq <- table(all_features$exp_c,all_features$exp_d,all_features$label)
freq <- as.data.frame(freq)

p = ggplot() +
   geom_bar(data = freq, aes(x = Var1, y = Freq, fill = Var3),stat = "identity",position="fill") +
   scale_fill_manual(values=c("#2B613F", "#AEC7A7", "#B8EECE","#FADAF3","#FACBC8","#D69281","#8CCDEA"))+
   facet_grid(rows = vars(Var2),switch="y")+
   theme_classic()

file1 = paste(outpath,"graph.png", sep = "")
png(filename = file1, width = 1000, height = 1000)
print(p)
dev.off()


plot_data$Value <- as.numeric(plot_data$Value)
plot_data = subset(all_features, Homotypic_Prob_C == 100 & Homotypic_Prob_D == 100)
plot_data <- subset(plot_data, (Feature == 'a-count' | Feature == 'b-count' | Feature == 'c-express-count' | Feature == 'd-express-count'))
plot_data_descriptive <- aggregate(plot_data$Value,
                                   by = list(Exp_C=plot_data$Exp_C,Exp_D=plot_data$Exp_D,CellCount=plot_data$Feature),
                                   FUN = function(x) c(mean(x), sd(x)))
plot_data_descriptive <- do.call(data.frame, plot_data_descriptive)

fill <- c("#5F9CD2","#A5A4A3","#95CA57","#BE2227")
p = ggplot() +
   geom_bar(data = plot_data_descriptive, aes(x = Exp_C, y = x.1, fill = CellCount),stat = "identity",position="fill") +
   scale_fill_manual(values=fill)+
   facet_grid(rows = vars(Exp_D),switch="y")+
   theme_classic()
file1 = paste(outpath,"graph_cellcounts.png", sep = "")
png(filename = file1, width = 1000, height = 1000)
print(p)
dev.off()


for(i in 1:length(features)){
   plot_data = subset(all_features, Feature == features[i] & Homotypic_Prob_C == 100 & Homotypic_Prob_D == 100)
   plot_data$Value <- as.numeric(plot_data$Value)
   color = "blue"

   if(str_contains(features[i],"green")){
      color = "#75A245"
   }
   else if(str_contains(features[i],"red")){
      color = "#BE2227"
   }

   plot_data_descriptive <- aggregate(plot_data$Value,
                                      by = list(Exp_C=plot_data$Exp_C,Exp_D=plot_data$Exp_D),
                                      FUN = function(x) c(mean(x), sd(x)))
   plot_data_descriptive <- do.call(data.frame, plot_data_descriptive)

   p = ggplot(plot_data_descriptive,aes(Exp_C,Exp_D,fill = x.1)) +
      geom_tile() +
      xlab("Exp_C") +
      ylab("Exp_D") +
      scale_fill_gradient(low="white",high=color) +
      ggtitle(features[[i]])
      # theme(xlab.text=element_text(size=14),legend.text=element_text(size=14),legend.text=element_text(size=14))
   plot[[i]] = p

   # p2 = ggplot() +
   #    geom_point(data=plot_data, aes(x = factor(Homotypic_Prob), y = factor(Hetertoypic_Prob), color = Value), size=2,alpha=0.1) +
   #    scale_color_continuous(limits=c(0,8)) +
   #    xlab("Homotypic Probability") +
   #    ylab("Heterotypic Probability")

   # plot_data$Value <- as.numeric(plot_data$Value)
   # plot_data_descriptive <- aggregate(plot_data$Value,
   #                                    by = list(Homotypic_Prob = plot_data$Homotypic_Prob, Heterotypic_Prob = plot_data$Heterotypic_Prob),
   #                                    FUN = function(x) c(mean(x), sd(x)))
   # plot_data_descriptive <- do.call(data.frame, plot_data_descriptive)
   # plot_ly(plot_data_descriptive,x=~Homotypic_Prob,y=~Heterotypic_Prob, z=~x.1)
   #
   # p1 = ggplot() +
   #    geom_bar(data = plot_data_descriptive, aes(x = factor(C_Express_Delay), y = x.1, fill = factor(D_Express_Delay)),
   #             stat = "identity", position=position_dodge()) +
   #    geom_errorbar(data = plot_data_descriptive,
   #                  aes (x = factor(C_Express_Delay), y = x.1, fill = factor(D_Express_Delay),
   #                       ymin=x.1 - x.2, ymax=x.1 + x.2), width=.2,position=position_dodge(.9)) +
   #    facet_grid(~ Ratio) +
   #    xlab("N-Cad Expression Delay (ticks)") +
   #    ylab(features[i]) +
   #    labs(fill = "P-Cad Expression Offset (ticks)")
   #
   # plot_data$Value <- as.numeric(plot_data$Value)
   # p2 = ggplot() +
   #    geom_boxplot(data=plot_data, aes(x = factor(Cdel), y = Value, fill = factor(Ddel))) +
   #    facet_grid(~ Ratio) +
   #    labs(fill = "P-Cad Expression Offset (ticks)") +
   #    xlab("N-Cad Expression Delay (ticks)") +
   #    ylab(features[i])
   # bar[[i]] = p1
   # box[[i]] = p2
}

i = 1
for(i in 1:length(features)){
   file1 = paste(outpath,features[i],"graph.png", sep = "")
   png(filename = file1, width = 1000, height = 1000)
   print(plot[[i]])
   dev.off()
}
