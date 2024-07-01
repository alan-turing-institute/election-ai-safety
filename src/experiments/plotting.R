library(ggplot2)

plot_proportions <- function(proportions_df, 
                             title,
                             subtitle = NULL,
                             model_order,
                             model_labels,
                             model_colours,
                             jitter_width,
                             alpha = 0.5, 
                             theme = theme_minimal(),
                             xlab = "Model",
                             ylab = "Proportion of \"Human\" assignments per content generated") {
  if ("experiment" %in% colnames(proportions_df)) {
    experiment_averages <- aggregate(proportions ~ experiment,
                                     data = aggregate(proportions ~ model + experiment,
                                                      data = proportions_df,
                                                      FUN = mean),
                                     FUN = mean)
    print(experiment_averages)
    proportions_df$experiment_average <- experiment_averages$proportions[match(proportions_df$experiment, experiment_averages$experiment)]
  } else {
    model_averages <- aggregate(proportions ~ model,
                                data = proportions_df,
                                FUN = mean)
    print(model_averages)
    print(mean(model_averages$proportions))
    proportions_df$model_average <- mean(model_averages$proportions)
  }
  
  plot <- ggplot(proportions_df, aes(x = model, y = proportions, color = model))
  
  if ("experiment" %in% colnames(proportions_df)) {
    plot <- plot + 
      geom_hline(aes(yintercept = experiment_average), linetype = "twodash", color = "grey70", linewidth = 0.9) +
      facet_wrap(. ~ experiment, ncol=3) +
      coord_flip()
  } else {
    plot <- plot + 
      geom_hline(aes(yintercept = model_average), linetype = "twodash", color = "grey70", linewidth = 0.9)
  }
  
  plot <- plot +
    geom_jitter(width = jitter_width, height = 0, alpha = alpha) +
    stat_summary(fun.data = function(x) mean_se(x, 2), geom = "crossbar", width = 0.5) +
    scale_x_discrete(limits = model_order, labels = model_labels) +
    scale_color_manual(name = "Model",
                       values = model_colours,
                       labels = model_labels) +
    ylim(0, 1) +
    labs(title = title,
         subtitle = subtitle,
         x = xlab,
         y = ylab) +
    theme
  
  return(plot)
}

plot_proportions_per_pipeline <- function(proportions_df, 
                                          title,
                                          subtitle = NULL,
                                          model_order,
                                          model_labels,
                                          model_colours,
                                          jitter_width,
                                          alpha = 0.5, 
                                          theme = theme_minimal(),
                                          xlab = "Model",
                                          ylab = "Proportion of \"Human\" assignments per content generated") {
  pipeline_averages <- aggregate(proportions ~ pipeline_stage_id,
                                 data = aggregate(proportions ~ model + pipeline_stage_id,
                                                  data = proportions_df,
                                                  FUN = mean),
                                 FUN = mean)
  print(pipeline_averages)
  proportions_df$pipeline_average <- pipeline_averages$proportions[match(proportions_df$pipeline_stage_id, pipeline_averages$pipeline_stage_id)]
  proportions_df$pipeline_stage_id <- factor(proportions_df$pipeline_stage_id,
                                    levels = c(1, 3, 2, 4),
                                    labels = c("News article\ngeneration",
                                               "Social media\naccount generation",
                                               "Social media\nreaction generation",
                                               "Social media\npost reply generation"))
  
  plot <- ggplot(proportions_df, aes(x = model, y = proportions, color = model)) +
    geom_hline(aes(yintercept = pipeline_average), linetype = "twodash", color = "grey70", linewidth = 0.9) +
    geom_jitter(width = jitter_width, height = 0, alpha = alpha) +
    stat_summary(fun.data = function(x) mean_se(x, 2), geom = "crossbar", width = 0.5) +
    scale_x_discrete(limits = model_order, labels = model_labels) +
    scale_color_manual(name = "Model",
                       values = model_colours,
                       labels = model_labels) +
    facet_wrap(. ~ pipeline_stage_id, ncol=4) +
    coord_flip() + 
    ylim(0, 1) +
    labs(title = title,
         subtitle = subtitle,
         x = xlab,
         y = ylab) +
    theme
  
  return(plot)
}

plot_proportions_vs_human <- function(proportions_df, 
                                      title,
                                      subtitle = NULL,
                                      model_order,
                                      model_labels,
                                      theme = theme_minimal(),
                                      xlab = "Model",
                                      ylab = "Proportion of \"Human\" assignments per content generated") {
  if ("experiment" %in% colnames(proportions_df)) {
    experiment_averages <- aggregate(proportions ~ experiment + model_type, 
                                     data = aggregate(proportions ~ model + model_type + experiment,
                                                      data = proportions_df,
                                                      FUN = mean),
                                     FUN = mean)
    print(experiment_averages)
    # match on experiment and model_type
    proportions_df$experiment_average <- experiment_averages$proportions[match(
      paste(proportions_df$experiment, proportions_df$model_type), 
      paste(experiment_averages$experiment, experiment_averages$model_type))]
    
  } else {
    model_type_averages <- aggregate(proportions ~ model_type, 
                                     data = aggregate(proportions ~ model + model_type,
                                                      data = proportions_df,
                                                      FUN = mean),
                                     FUN = mean)
    print(model_type_averages)
    proportions_df$model_average <- model_type_averages$proportions[match(proportions_df$model_type, model_type_averages$model_type)]
  }
  
  # compute correlation
  avg_prop <- aggregate(proportions ~ ai_model + model_type, data = proportions_df, FUN = mean)
  if (all(avg_prop[avg_prop$model_type == "AI",]$ai_model == avg_prop[avg_prop$model_type == "Human",]$ai_model)) {
    print(paste("correlation between average AI and Human proportions:",
                cor(avg_prop[avg_prop$model_type == "AI",]$proportions,
                    avg_prop[avg_prop$model_type == "Human",]$proportions,
                    method = "spearman")))
  }
  
  plot <- ggplot(proportions_df, aes(x = ai_model, y = proportions, color = model_type))
  
  if ("experiment" %in% colnames(proportions_df)) {
    plot <- plot + 
      geom_hline(aes(yintercept = experiment_average, color = model_type), linetype = "twodash", linewidth = 0.9) +
      facet_wrap(. ~ experiment, ncol=3) +
      coord_flip()
  } else {
    plot <- plot + 
      geom_hline(aes(yintercept = model_average, color = model_type), linetype = "twodash", linewidth = 0.9)
  }
  
  plot <- plot +
    stat_summary(aes(linetype = model_type), fun.data = function(x) mean_se(x, 2),
                 geom = "crossbar", width = 0.6, position = "dodge", linewidth = 1.1, fatten = 2) +
    scale_linetype_manual(values = c("Human" = "solid", "AI" = "21")) + 
    scale_color_manual(values = c("Human" = "#00BFC4", "AI" = "#F8766D")) +
    scale_x_discrete(limits = model_order, labels = model_labels) +
    ylim(0, 1) +
    labs(title = title,
         subtitle = subtitle,
         x = xlab,
         y = ylab) +
    theme
  
  return(plot)
}

plot_facet_lollipop_per_pipeline_vs_human <- function(proportions_pipeline_df, 
                                                      model_order,
                                                      model_labels,
                                                      theme = theme_minimal() + 
                                                        theme(
                                                          panel.grid.major.y = element_blank(),
                                                          panel.grid.major.x = element_line(color = "grey", linewidth = 0.5),
                                                          panel.border = element_blank(),
                                                          axis.ticks.y = element_blank(),
                                                          # change x-axis labels size
                                                          axis.text.x = element_text(linewidth = 8),
                                                          plot.title = element_text(linewidth = 16)
                                                        ),
                                                      xlab = "Model",
                                                      ylab = "Average proportion of \"Human\" assignments per content generated",
                                                      title = "Average proportion of \"Human\" assignments across pipeline stages per content generated") {
  # facet lollipop plots
  average_proportions <- aggregate(proportions ~ model + ai_model + pipeline_stage_id + model_type, data = proportions_pipeline_df, FUN = mean)
  average_proportions$pipeline_stage_id <- factor(average_proportions$pipeline_stage_id,
                                         levels = c(1, 3, 2, 4),
                                         labels = c("News article\ngeneration",
                                                    "Social media\naccount generation",
                                                    "Social media\nreaction generation",
                                                    "Social media\npost reply generation"))
  
  # compute correlation
  if (all(average_proportions[average_proportions$model_type == "AI", c("ai_model", "pipeline_stage_id")] == 
          average_proportions[average_proportions$model_type == "Human", c("ai_model", "pipeline_stage_id")])) {
    print(paste("correlation between average AI and Human proportions:",
                cor(average_proportions[average_proportions$model_type == "AI",]$proportions,
                    average_proportions[average_proportions$model_type == "Human",]$proportions,
                    method = "spearman")))
  }
  
  # create plot
  ggplot(average_proportions, aes(x = ai_model, y = proportions, color = model_type)) +
    geom_linerange(aes(xmin=ai_model, xmax=ai_model, ymin=0, ymax=proportions,
                       colour = model_type, linetype = model_type),
                   position = position_dodge(0.25),
                   linewidth = 0.9) +
    scale_y_continuous(limits = c(0, 1)) +
    facet_wrap(. ~ pipeline_stage_id, ncol=4) +
    geom_point(aes(shape = model_type), size=3, alpha=0.8, position = position_dodge(0.25)) +
    scale_x_discrete(limits = rev(model_order), labels = rev(model_labels)) +
    scale_linetype_manual(values = c("Human" = "solid", "AI" = "21")) + 
    scale_shape_manual(values = c("Human" = 16, "AI" = 17)) +
    scale_color_manual(values = c("Human" = "#00BFC4", "AI" = "#F8766D")) +
    coord_flip() +
    labs(title = title,
         x = xlab,
         y = ylab) + 
    theme
}
