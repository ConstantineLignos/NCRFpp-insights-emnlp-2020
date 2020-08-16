library(tidyverse)

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
scores.grouped <- scores %>% filter(Best.NCRFpp) %>% group_by(Dataset, Tagset, CharModel)
scores.means <- scores.grouped %>% summarize_if(is.numeric, mean) %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval)
scores.sds <- scores.grouped %>% summarize_if(is.numeric, sd)
print(select(scores.means, Dataset, Tagset, CharModel | starts_with("F1")))
print(select(scores.sds, Dataset, Tagset, CharModel | starts_with("F1")))

# Average differences
scores.delta.summary <- scores.grouped %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval) %>% group_by(Dataset, Tagset) %>% summarize(F1.Delta.Mean = mean(F1.Delta), F1.Delta.SD = sd(F1.Delta), .groups = "keep")
print(scores.delta.summary)

# Test average differences
test.f1.delta <- function(scores) {
  wilcox.test(scores$F1.NCRFpp, scores$F1.seqeval, paired = TRUE, conf.int = TRUE)
}

scores.grouped.dev <- filter(scores.grouped, Dataset == "Dev")
test.f1.delta(filter(scores.grouped.dev, Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.dev, Tagset == "BIOES"))

scores.grouped.test <- filter(scores.grouped, Dataset == "Test")
test.f1.delta(filter(scores.grouped.test, Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.test, Tagset == "BIOES"))

# Average best epoch
scores.best.epoch <- scores %>% filter(Best.NCRFpp, Dataset == "Dev") %>% group_by(Tagset) %>% summarize(Epoch.Mean = mean(Epoch), Epoch.SD = sd(Epoch), .groups = "keep")
print(scores.best.epoch)

# Difference across epochs
ggplot(scores.dev, aes(Epoch, F1.Delta)) + geom_point(alpha = 0.4) + facet_wrap(vars(Tagset), ncol = 1) + geom_smooth(method = "loess", formula = y ~ x, span = 0.2, color = "grey80") + scale_y_continuous(breaks = seq(0, 3, 0.5), limits = c(0, NA)) + ylab("Development Set F1 Increase")
ggsave("scorer.delta.png", width = 4, height = 5.5)
