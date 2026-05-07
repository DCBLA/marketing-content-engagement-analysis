# Marketing Content Engagement Analysis
# Portfolio-ready version of the original coursework analysis.

set.seed(123)

required_packages <- c(
  "tidyverse",
  "e1071",
  "scales",
  "corrplot",
  "psych",
  "caret",
  "car",
  "rpart",
  "rpart.plot",
  "glmnet"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install missing packages before running this script: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(tidyverse)
library(e1071)
library(scales)
library(corrplot)
library(psych)
library(caret)
library(car)
library(rpart)
library(rpart.plot)
library(glmnet)

data_path <- file.path("data", "raw", "Global_media_data.csv")

if (!file.exists(data_path)) {
  stop("Expected data file not found: ", data_path)
}

df <- readr::read_csv(data_path, show_col_types = FALSE)

# Data quality checks
print(glimpse(df))
print(dim(df))
print(colSums(is.na(df)))
print(sum(duplicated(df$Record_ID)))

# Remove the corrupted record with impossible text-ratio values.
ratio_problem <- df$Unique_Words_Rate < 0 | df$Unique_Words_Rate > 1 |
  df$Non_Stop_Words_Rate < 0 | df$Non_Stop_Words_Rate > 1 |
  df$Unique_Non_Stop_Rate < 0 | df$Unique_Non_Stop_Rate > 1

print(df$Record_ID[ratio_problem])
df <- df[!ratio_problem, ]

# Remove variables that are not appropriate for a publication-time model.
df_clean <- df %>%
  select(-Record_ID) %>%
  select(-matches("^Tag_Perf_")) %>%
  select(-matches("^Ref_.*_Impact$")) %>%
  select(-matches("^Topic_")) %>%
  select(-Is_Weekend, -Pub_Day_Mon)

print(sum(df_clean$Content_Word_Count == 0))

# Target variable analysis
target_summary <- tibble(
  mean = mean(df_clean$Engagement),
  median = median(df_clean$Engagement),
  sd = sd(df_clean$Engagement),
  min = min(df_clean$Engagement),
  max = max(df_clean$Engagement),
  skewness = skewness(df_clean$Engagement),
  kurtosis = kurtosis(df_clean$Engagement)
)

print(target_summary)

top_1_cutoff <- quantile(df_clean$Engagement, 0.99)
top_1_share_pct <- df_clean %>%
  filter(Engagement >= top_1_cutoff) %>%
  summarise(pct = sum(Engagement) / sum(df_clean$Engagement) * 100)

print(top_1_share_pct)

df_clean <- df_clean %>%
  mutate(log_engagement = log(Engagement + 1))

# Feature engineering: labels for exploratory analysis.
df_clean <- df_clean %>%
  mutate(
    pub_day = case_when(
      Pub_Day_Tue == 1 ~ "Tue",
      Pub_Day_Wed == 1 ~ "Wed",
      Pub_Day_Thu == 1 ~ "Thu",
      Pub_Day_Fri == 1 ~ "Fri",
      Pub_Day_Sat == 1 ~ "Sat",
      Pub_Day_Sun == 1 ~ "Sun",
      TRUE ~ "Mon"
    ),
    pub_day = factor(pub_day, levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
    genre_factor = case_when(
      Genre_Lifestyle == 1 ~ "Lifestyle",
      Genre_Entertainment == 1 ~ "Entertainment",
      Genre_Business == 1 ~ "Business",
      Genre_SocialMedia == 1 ~ "SocialMedia",
      Genre_Tech == 1 ~ "Tech",
      Genre_International == 1 ~ "International",
      TRUE ~ "No_Genre"
    ),
    genre_factor = relevel(factor(genre_factor), ref = "International")
  )

# PCA on correlated micro-sentiment variables.
pca_vars <- c(
  "Global_Pos_Rate",
  "Global_Neg_Rate",
  "Pos_to_NonNeutral_Rate",
  "Neg_to_NonNeutral_Rate",
  "Avg_Pos_Intensity",
  "Min_Pos_Intensity",
  "Max_Pos_Intensity",
  "Avg_Neg_Intensity",
  "Min_Neg_Intensity",
  "Max_Neg_Intensity"
)

pca_result <- prcomp(df_clean[, pca_vars], center = TRUE, scale. = TRUE)
print(summary(pca_result))
print(round(pca_result$rotation[, 1:2], 3))

df_clean$Sentiment_PC1 <- pca_result$x[, 1]
df_clean$Sentiment_PC2 <- pca_result$x[, 2]

model_df <- df_clean %>%
  transmute(
    log_engagement,
    Days_Elapsed,
    Title_Word_Count,
    Content_Word_Count = log(Content_Word_Count + 1),
    External_Links = log(External_Links + 1),
    Internal_Links = log(Internal_Links + 1),
    Image_Count = log(Image_Count + 1),
    Video_Count = log(Video_Count + 1),
    Avg_Word_Length,
    Keyword_Total,
    Pub_Day_Tue,
    Pub_Day_Wed,
    Pub_Day_Thu,
    Pub_Day_Fri,
    Pub_Day_Sat,
    Pub_Day_Sun,
    genre_factor,
    Overall_Subjectivity,
    Overall_Sentiment,
    Title_Subjectivity,
    Title_Sentiment,
    Sentiment_PC1,
    Sentiment_PC2
  )

print(psych::describe(model_df %>% select(where(is.numeric))))

# Train/test split and baseline.
train_index <- createDataPartition(model_df$log_engagement, p = 0.8, list = FALSE)
train <- model_df[train_index, ]
test <- model_df[-train_index, ]

baseline_pred <- mean(train$log_engagement)
baseline_rmse <- sqrt(mean((test$log_engagement - baseline_pred)^2))
baseline_mae <- mean(abs(test$log_engagement - baseline_pred))

print(tibble(model = "baseline", rmse = baseline_rmse, mae = baseline_mae))

# LASSO selection.
x_train <- model.matrix(log_engagement ~ ., data = train)[, -1]
y_train <- train$log_engagement
x_test <- model.matrix(log_engagement ~ ., data = test)[, -1]
y_test <- test$log_engagement

lasso_cv <- cv.glmnet(x_train, y_train, alpha = 1)
selected <- rownames(coef(lasso_cv, s = lasso_cv$lambda.min))[
  which(coef(lasso_cv, s = lasso_cv$lambda.min) != 0)
]
selected <- selected[selected != "(Intercept)"]
print(selected)

pred_lasso <- predict(lasso_cv, s = lasso_cv$lambda.min, newx = x_test)
lasso_rmse <- sqrt(mean((y_test - pred_lasso)^2))
print(tibble(model = "lasso", rmse = lasso_rmse))

# Interpretable OLS model. Sentiment_PC1 is removed because LASSO shrank it to zero.
train_ols <- train %>% select(-Sentiment_PC1)
test_ols <- test %>% select(-Sentiment_PC1)

model_lm <- lm(log_engagement ~ ., data = train_ols)
print(summary(model_lm))
print(round(vif(model_lm), 2))

pred_lm <- predict(model_lm, newdata = test_ols)
rmse_lm <- sqrt(mean((test_ols$log_engagement - pred_lm)^2))
mae_lm <- mean(abs(test_ols$log_engagement - pred_lm))

print(tibble(model = "ols", rmse = rmse_lm, mae = mae_lm))

dummy_vars <- names(coef(model_lm))[grepl("Pub_Day_|genre_factor", names(coef(model_lm)))]
dummy_effects <- tibble(
  variable = dummy_vars,
  pct_vs_reference = (exp(coef(model_lm)[dummy_vars]) - 1) * 100
)

print(dummy_effects)
print(round(confint(model_lm), 4))

# Pruned decision tree for segmentation.
model_tree <- rpart(
  log_engagement ~ .,
  data = train_ols,
  method = "anova",
  control = rpart.control(cp = 0.001)
)

best_cp <- model_tree$cptable[which.min(model_tree$cptable[, "xerror"]), "CP"]
model_pruned <- prune(model_tree, cp = best_cp)
pred_tree <- predict(model_pruned, newdata = test_ols)
tree_mae <- mean(abs(test_ols$log_engagement - pred_tree))

print(tibble(model = "pruned_tree", mae = tree_mae))

# Robustness check with an alternative split.
set.seed(456)
train_index_2 <- createDataPartition(model_df$log_engagement, p = 0.8, list = FALSE)
train_2 <- model_df[train_index_2, ] %>% select(names(train_ols))
model_lm_2 <- lm(log_engagement ~ ., data = train_2)

print(sort(abs(coef(model_lm)[-1]), decreasing = TRUE)[1:5])
print(sort(abs(coef(model_lm_2)[-1]), decreasing = TRUE)[1:5])
