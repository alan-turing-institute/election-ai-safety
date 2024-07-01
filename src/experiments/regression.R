# we assume that you are running this script from the location of this file
# i.e. your current working directory is <repo's root directory>src/regression
#
# we do not make the data to run this script available for privacy reasons

library(tidyverse)
library(lme4)
library(jtools)
library(broom.mixed)
library(huxtable)
library(aod)

code_vars <- function(data, ai = TRUE) {
  data$age_bracket <- factor(data$age_bracket, levels = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+"))
  data$gender <- factor(data$gender, levels = c("Male", "Female", "Other"))
  data$education_binary <- factor(data$education_binary, levels = c("No degree", "Degree"))
  data$politics_binary <- factor(data$politics_binary, levels = c("Left", "Right"))
  data$pipeline_stage <- factor(data$pipeline_stage, levels = c("bio", "news", "reaction", "reply"))
  
  if (ai) {
    data$model <- factor(data$model, levels = c("GPT2", "T5", "GPTNeo", "FlanT5", "GPT35", "GPT35T", "GPT4", "Llama2", "Mistral", "Gemini", "Phi", "Gemma", "Llama3")) 
  } else {
    data$ai_model <- factor(data$ai_model, levels = c("GPT2", "T5", "GPTNeo", "FlanT5", "GPT35", "GPT35T", "GPT4", "Llama2", "Mistral", "Gemini", "Phi", "Gemma", "Llama3")) 
  }
  
  return (data)
}

scale_data <- function(data) {
  data$age_scaled <- scale(data$age, center = TRUE, scale = TRUE)
  data$politics_scaled <- scale(data$politics, center = TRUE, scale = TRUE)
  data$tfidf_distance_scaled <- scale(data$tfidf_distance, center = TRUE, scale = TRUE)
  
  return (data)
}


# Predict humanness of AI content --------------------------------------------------------------
exp_voting <- read.csv("data not provided")
exp_lw <- read.csv("data not provided")
exp_rw <- read.csv("data not provided")
exp_all <- read.csv("data not provided")

# Code categorical vars
exp_voting <- code_vars(exp_voting)
exp_lw <- code_vars(exp_lw)
exp_rw <- code_vars(exp_rw)
exp_all <- code_vars(exp_all)

# Rescale numerical vars
exp_voting <- scale_data(exp_voting)
exp_lw <- scale_data(exp_lw)
exp_rw <- scale_data(exp_rw)
exp_all <- scale_data(exp_all)

# Fit models
m_voting <- glmer(assigned_human ~ age_scaled + gender + education_binary + politics_scaled + tfidf_distance_scaled + model + pipeline_stage + 
              (1 | prolific_id), data = exp_voting, family = "binomial", control = glmerControl(optimizer = "bobyqa"), nAGQ = 10)

m_lw <- glmer(assigned_human ~ age_scaled + gender + education_binary + politics_scaled + tfidf_distance_scaled + model + pipeline_stage +
              (1 | prolific_id), data = exp_lw, family = "binomial", control = glmerControl(optimizer = "bobyqa"), nAGQ = 10)

m_rw <- glmer(assigned_human ~ age_scaled + gender + education_binary + politics_scaled + tfidf_distance_scaled + model + pipeline_stage +
              (1 | prolific_id), data = exp_rw, family = "binomial", control = glmerControl(optimizer = "bobyqa"), nAGQ = 10)

m_all <- glmer(assigned_human ~ age_scaled + gender + education_binary + politics_scaled + tfidf_distance_scaled + model + pipeline_stage + 
              (1 | prolific_id), data = exp_all, family = "binomial", control = glmerControl(optimizer = "bobyqa"), nAGQ = 10)

# Generate table and plots
# - Present ORs instead of raw coefficients
# - Note: CIs are approximated by using the SEs. Would be preferable to use likelihood profiling or 
#   bootstrapping but these take too long to compute
model_names <- c("Exp MP (LW)", "Exp MP (RW)", "Exp Voting (RW)", "Exp all")
coefs = c("Age" = "age_scaled",
          "Gender (female)" = "genderFemale",
          "Gender (other)" = "genderOther", 
          "Education (degree)" = "education_binaryDegree",
          "Politics" = "politics_scaled",
          "TFIDF distance" = "tfidf_distance_scaled",
          "T5" = "modelT5",
          "GPT-Neo" = "modelGPTNeo",
          "Flan-T5" = "modelFlanT5",
          "GPT-3.5 (t-d-003)" = "modelGPT35",
          "GPT-3.5 Turbo" = "modelGPT35T",
          "GPT-4" = "modelGPT4",
          "Llama 2" = "modelLlama2",
          "Mistral" = "modelMistral",
          "Gemini 1.0 Pro" = "modelGemini",
          "Phi-2" = "modelPhi",
          "Gemma" = "modelGemma",
          "Llama 3" = "modelLlama3", 
          "Pipeline (news)" = "pipeline_stagenews",
          "Pipeline (reaction)" = "pipeline_stagereaction",
          "Pipeline (reply)" = "pipeline_stagereply")

# Generate coef plot
plot_summs(
  m_lw, m_rw, m_voting, m_all,
  model.names = model_names, 
  coefs = coefs,
  exp = TRUE)

# Generate results table 
table_ai <- export_summs(
  m_lw, m_rw, m_voting, m_all,
  exp = TRUE, 
  error_format = "[{conf.low}, {conf.high}]", 
  error_pos = "right",
  model.names = model_names,
  coefs = coefs,
  statistics = c(0))

# Export table 
quick_xlsx(table_ai, file = "regression_table.xlsx", open = TRUE)
quick_docx(table_ai, file = "regression_table.docx", open = TRUE)

# Run tests
# Note: this is experimental only
l <- cbind(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0)
wald.test(b = fixef(m2), Sigma = vcov(m2), L = l)

