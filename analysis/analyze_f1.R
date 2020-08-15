library(tidyverse)
library(xtable)

theme_set(theme_bw())
options(pillar.sigfig = 5)

scores.raw <- read_delim("../exp_logs/merged.tsv", "\t")

mult100 <- function(x) {
  x * 100
}

# Note that we make a minor mess by convert the best to numeric (when we do mult100) and back to logical again
scores <- scores.raw %>% mutate_at(c("Tagset", "Dataset", "Seed", "CharModel"), as.factor) %>% mutate_at(vars(ends_with(".seqeval")), mult100) %>% mutate_at(vars(ends_with(".NCRFpp")), mult100) %>% mutate_at(vars(starts_with("Best")), as.logical) %>% mutate(Tagset = recode(Tagset, BMES = "BIOES")) %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval)
summary(scores)
scores.dev <- scores %>% filter(Dataset == "Dev")

# Per-condition means and SDs
scores.grouped <- scores %>% filter(Best.NCRFpp) %>% group_by(Dataset, Tagset, CharModel) %>% select(-c(Epoch, Loss, F1.Delta))
scores.means <- scores.grouped %>% summarize_if(is.numeric, mean) %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval)
scores.sds <- scores.grouped %>% summarize_if(is.numeric, sd)
print(select(scores.means, Dataset, Tagset, CharModel | starts_with("F1")))
print(select(scores.sds, Dataset, Tagset, CharModel | starts_with("F1")))

# Average differences
scores.delta.summary <- scores.grouped %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval) %>% group_by(Dataset, Tagset) %>% summarize(F1.Delta.Mean = mean(F1.Delta), F1.Delta.SD = sd(F1.Delta), .groups = "keep")

# Average best epoch
scores.best.epoch <- scores %>% filter(Best.NCRFpp, Dataset == "Dev") %>% group_by(Tagset) %>% summarize(Epoch.Mean = mean(Epoch), Epoch.SD = sd(Epoch), .groups = "keep")

ggplot(filter(scores.dev), aes(F1.Delta)) + geom_histogram(bins = 50) + facet_wrap(vars(Tagset), ncol = 1)

ggplot(filter(scores.dev), aes(Epoch, F1.Delta)) + geom_point() + facet_wrap(vars(Tagset), ncol = 1) + geom_smooth(method = "loess", formula = y ~ x, span = 0.2, color = "gray60") + scale_y_continuous(breaks = seq(0, 3, 0.5), limits = c(0, NA)) + ylab("Dev F1 Difference")
ggsave("scorer.delta.png", width = 4, height = 6)

ggplot(filter(scores.dev, Tagset == "BIOES"), aes(F1.Delta)) + geom_histogram(bins = 50)

