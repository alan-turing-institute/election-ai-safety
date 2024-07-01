# we assume that you are running this script from the location of this file
# i.e. your current working directory is <repo's root directory>src/plotting

source("plotting.R")

theme <- ggthemes::theme_hc() + theme(
  panel.grid.major.y = element_line(color = "grey", linewidth = 0.5, linetype = "dotted"),
  panel.grid.major.x = element_blank(),
  panel.border = element_blank(),
  axis.ticks.x = element_blank(),
  axis.ticks.y = element_blank(),
  axis.text.x = element_text(size = 10, face = "bold", margin = margin(t = 0, r = 0, b = 20, l = 0)),
  axis.text.y = element_text(size = 10, face = "bold", margin = margin(t = 0, r = 0, b = 0, l = 20)),
  axis.title.x = element_text(size = 14),
  axis.title.y = element_text(size = 14),
  plot.title = element_text(size = 16),
  legend.title = element_blank(),
  legend.text = element_text(size = 16),
  legend.key.width = unit(0.75, "cm"),
  legend.key.height = unit(1, "cm"),
  legend.position = "top"
)

cols <- ggthemes::tableau_color_pal(palette = "Tableau 20")(14)
names(cols) <- c("H",
                 "GPT2",
                 "T5",
                 "GPT35",
                 "GPTNeo",
                 "FlanT5",
                 "GPT35T",
                 "Phi",
                 "Mistral",
                 "Llama2",
                 "GPT4",
                 "Gemma",
                 "Gemini",
                 "Llama3")

# corresponding labels
# model_labels <- c("GPT2" = "GPT-2\n(2019-02)\n(1.5B)",
#                   "T5" = "T5\n(2019-10)\n(2.85B)",
#                   "GPTNeo" = "GPT-Neo\n(2021-03)\n(2.7B)",
#                   "FlanT5" = "Flan-T5\n(2022-10)\n(2.85B)",
#                   "GPT3" = "GPT-3.5 (t-d-003)\n(2022-11)\n(?)",
#                   "GPT3pt5" = "GPT-3.5 (turbo)\n(2023-03)\n(?)",
#                   "GPT4" = "GPT-4\n(2023-03)\n(?)",
#                   "Llama2" = "Llama 2\n(2023-07)\n(13B*)",
#                   "Mistral" = "Mistral\n(2023-09)\n(7B*)",
#                   "Gemini" = "Gemini\n(2023-12)\n(?)",
#                   "Phi" = "Phi-2\n(2023-12)\n(2.7B*)",
#                   "Gemma" = "Gemma\n(2024-02)\n(7B*)",
#                   "Llama3" = "Llama 3\n(2024-04)\n(70B*)")
model_labels <- c("GPT2" = "GPT-2",
                  "T5" = "T5",
                  "GPTNeo" = "GPT-Neo",
                  "FlanT5" = "Flan-T5",
                  "GPT35" = "GPT-3.5\n(t-d-003)",
                  "GPT35T" = "GPT-3.5\nTurbo",
                  "GPT4" = "GPT-4",
                  "Llama2" = "Llama 2",
                  "Mistral" = "Mistral",
                  "Gemini" = "Gemini\n1.0 Pro",
                  "Phi" = "Phi-2",
                  "Gemma" = "Gemma",
                  "Llama3" = "Llama 3")

##############################
##### EXPERIMENT VT ##########
##############################

expvt_prop <- read.csv("../../data/experiments/vt/proportions.csv")
expvt_prop <- expvt_prop[61:nrow(expvt_prop),]

# exp_vt_proportions_per_pipeline_by_release

plot_facet_lollipop_per_pipeline_vs_human(proportions_pipeline_df = expvt_prop,
                                          title = "",
                                          model_order = names(model_labels),
                                          model_labels = model_labels,
                                          theme = theme + 
                                            theme(panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid")))

##############################
##### EXPERIMENT MP_L ########
##############################

expmpl_prop <- read.csv("../../data/experiments/mp_l/proportions.csv")
expmpl_prop <- expmpl_prop[61:nrow(expmpl_prop),]

# exp_mpl_proportions_per_pipeline_by_release

plot_facet_lollipop_per_pipeline_vs_human(proportions_pipeline_df = expmpl_prop,
                                          title = "",
                                          model_order = names(model_labels),
                                          model_labels = model_labels,
                                          theme = theme + 
                                            theme(panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid")))

##############################
##### EXPERIMENT MP_R ########
##############################

expmpr_prop <- read.csv("../../data/experiments/mp_r/proportions.csv")
expmpr_prop <- expmpr_prop[61:nrow(expmpr_prop),]

# exp_mpr_proportions_per_pipeline_by_release

plot_facet_lollipop_per_pipeline_vs_human(proportions_pipeline_df = expmpr_prop,
                                          title = "",
                                          model_order = names(model_labels),
                                          model_labels = model_labels,
                                          theme = theme + 
                                            theme(panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid")))

##############################
##### ALL EXPERIMENTS ########
##############################

### together

all_exp <- rbind(expvt_prop,
                 expmpl_prop,
                 expmpr_prop)

avg_proportions_per_post <- aggregate(proportions ~ model, data = all_exp, FUN = mean)
avg_proportions_per_post <- avg_proportions_per_post[order(avg_proportions_per_post$proportions),]

# define custom order
model_order <- avg_proportions_per_post[avg_proportions_per_post$model!="H",]$model

# aggregated_proportions_per_post

plot_proportions(proportions_df = all_exp[all_exp$model_type == "AI",],
                 title = "",
                 jitter_width = 0.01,
                 alpha = 0.5,
                 model_order = names(model_labels),
                 model_labels = model_labels,
                 model_colours = cols,
                 theme = theme + theme(legend.position = "none"))

# aggregated_proportions_vs_human

plot_proportions_vs_human(proportions_df = all_exp,
                          title = "",
                          model_order = model_order,
                          model_labels = model_labels,
                          theme = theme +
                            theme(panel.grid.major.x = element_line(color = "grey", linewidth = 0.5, linetype = "dotted")))

### split

expvt_prop$experiment <- "Voting"
expmpl_prop$experiment <- "MP (LW)"
expmpr_prop$experiment <- "MP (RW)"
expall_prop <- rbind(expvt_prop,
                     expmpl_prop,
                     expmpr_prop)

theme <- ggthemes::theme_hc() + theme(
  panel.border = element_blank(),
  axis.ticks.x = element_blank(),
  axis.ticks.y = element_blank(),
  axis.text.x = element_text(size = 10, face = "bold", margin = margin(t = 0, r = 0, b = 20, l = 0)),
  axis.text.y = element_text(size = 10, face = "bold", margin = margin(t = 0, r = 0, b = 0, l = 20)),
  axis.title.x = element_text(size = 14),
  axis.title.y = element_text(size = 14),
  plot.title = element_text(size = 16),
  legend.title = element_blank(),
  legend.text = element_text(size = 16),
  legend.position = "top"
)

# all_proportions_per_post

plot_proportions(proportions_df = expall_prop[expall_prop$model_type == "AI",],
                 title = "",
                 jitter_width = 0.01,
                 alpha = 0.5,
                 model_order = rev(names(model_labels)),
                 model_labels = model_labels,
                 model_colours = cols,
                 theme = theme + 
                   theme(legend.position = "none",
                         panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid"),
                         panel.grid.major.y = element_blank(),
                         panel.grid.major.x = element_line(color = "grey", linewidth = 0.5, linetype = "dotted"),
                         panel.spacing = unit(1, "lines")))

# all_proportions_per_pipeline

plot_proportions_per_pipeline(proportions_df = expall_prop[expall_prop$model_type == "AI",],
                              title = "",
                              jitter_width = 0.01,
                              alpha = 0.5,
                              model_order = rev(names(model_labels)),
                              model_labels = model_labels,
                              model_colours = cols,
                              theme = theme +
                                theme(legend.position = "none",
                                      panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid"),
                                      panel.grid.major.y = element_blank(),
                                      panel.grid.major.x = element_line(color = "grey", linewidth = 0.5, linetype = "dotted"),
                                      panel.spacing = unit(1, "lines")))

# all_proportions_vs_human

plot_proportions_vs_human(proportions_df = expall_prop,
                          title = "",
                          model_order = rev(model_order),
                          model_labels = model_labels,
                          theme = theme + 
                            theme(panel.border = element_rect(color = "grey", fill = NA, size = 1, linetype = "solid"),
                                  panel.grid.major.y = element_line(color = "grey", linewidth = 0.5, linetype = "dotted"),
                                  panel.grid.major.x = element_line(color = "grey", linewidth = 0.5, linetype = "dotted"),
                                  panel.spacing = unit(1, "lines")))

# compute correlation between AI and Human proportions for pipeline stages

# compute correlation by aggregating all
proportions_pipeline_df <- expall_prop
average_proportions <- aggregate(proportions ~ model + ai_model + pipeline_stage_id + model_type + experiment, data = proportions_pipeline_df, FUN = mean)
if (all(average_proportions[average_proportions$model_type == "AI", c("ai_model", "pipeline_stage_id", "experiment")] == 
        average_proportions[average_proportions$model_type == "Human", c("ai_model", "pipeline_stage_id", "experiment")])) {
  print(paste("correlation between average AI and Human proportions:",
              cor(average_proportions[average_proportions$model_type == "AI",]$proportions,
                  average_proportions[average_proportions$model_type == "Human",]$proportions,
                  method = "spearman")))
}

# compute correlation by only aggregating to experiment
avg_prop <- aggregate(proportions ~ ai_model + model_type + experiment, data = expall_prop, FUN = mean)
if (all(avg_prop[avg_prop$model_type == "AI", c("ai_model", "experiment")] == avg_prop[avg_prop$model_type == "Human", c("ai_model", "experiment")])) {
  print(paste("correlation between average AI and Human proportions:",
              cor(avg_prop[avg_prop$model_type == "AI",]$proportions,
                  avg_prop[avg_prop$model_type == "Human",]$proportions,
                  method = "spearman")))
}
