library(tidyverse)

theme_set(theme_bw() + theme(text=element_text(family="Times")))
options(pillar.sigfig = 5)
options(tibble.print_max = 100)

scores.raw <- read_delim("../exp_logs/merged.tsv", "\t")

mult100 <- function(x) {
  x * 100
}

# Note that we make a minor mess by convert the best to numeric (when we do mult100) and back to logical again
scores <- scores.raw %>% mutate_at(c("Tagset", "Dataset", "Seed", "CharModel", "Output"), as.factor) %>% mutate_at(vars(ends_with(".seqeval")), mult100) %>% mutate_at(vars(ends_with(".NCRFpp")), mult100) %>% mutate_at(vars(starts_with("Best")), as.logical) %>% mutate(Tagset = recode(Tagset, BMES = "BIOES"), Output = fct_relevel(Output, "CRF", after = Inf)) %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval)
summary(scores)
scores.dev <- scores %>% filter(Dataset == "Dev")

# Per-condition means and SDs
scores.grouped <- scores %>% filter(Best.NCRFpp) %>% group_by(Output, Dataset, Tagset, CharModel)
scores.means <- scores.grouped %>% summarize_if(is.numeric, mean) %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval)
scores.sds <- scores.grouped %>% summarize_if(is.numeric, sd)
print(select(scores.means, Dataset, Tagset, CharModel | starts_with("F1")))
print(select(scores.sds, Dataset, Tagset, CharModel | starts_with("F1")))

# Average differences
scores.delta.summary <- scores.grouped %>% mutate(F1.Delta = F1.NCRFpp - F1.seqeval) %>% group_by(Output, Dataset, Tagset) %>% summarize(F1.Delta.Mean = mean(F1.Delta), F1.Delta.SD = sd(F1.Delta), .groups = "keep")
print(scores.delta.summary)

# Test average differences
test.f1.delta <- function(scores) {
  wilcox.test(scores$F1.NCRFpp, scores$F1.seqeval, paired = TRUE, conf.int = TRUE)
}

# Dev p-values
scores.grouped.dev <- filter(scores.grouped, Dataset == "Dev")
# Softmax
test.f1.delta(filter(scores.grouped.dev, Output == "Softmax", Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.dev, Output == "Softmax", Tagset == "BIOES"))
# CRF
test.f1.delta(filter(scores.grouped.dev, Output == "CRF", Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.dev, Output == "CRF", Tagset == "BIOES"))

# Test p-values
scores.grouped.test <- filter(scores.grouped, Dataset == "Test")
# Softmax
test.f1.delta(filter(scores.grouped.test, Output == "Softmax", Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.test, Output == "Softmax", Tagset == "BIOES"))
# CRF
test.f1.delta(filter(scores.grouped.test, Output == "CRF", Tagset == "BIO"))
test.f1.delta(filter(scores.grouped.test, Output == "CRF", Tagset == "BIOES"))

# Average best epoch
scores.best.epoch <- scores %>% filter(Best.NCRFpp, Dataset == "Dev") %>% group_by(Output, Tagset) %>% summarize(Epoch.Mean = mean(Epoch), Epoch.SD = sd(Epoch), .groups = "keep")
print(scores.best.epoch)

# Difference across epochs
ggplot(filter(scores.dev, Output == "Softmax"), aes(Epoch, F1.Delta)) + geom_point(alpha = 0.3) + facet_grid(cols = vars(Tagset)) + geom_smooth(method = "loess", formula = y ~ x, span = 0.2, color = "grey80") + scale_y_continuous(breaks = seq(0, 3, 0.5), limits = c(0, NA)) + ylab("Development Set F1 Increase")
ggsave("scorer.delta.png", width = 8, height = 3)

# Version of plot for slides, just made things a bit bigger
ggplot(filter(scores.dev, Output == "Softmax"), aes(Epoch, F1.Delta)) + geom_point(alpha = 0.3) + facet_grid(cols = vars(Tagset)) + geom_smooth(method = "loess", formula = y ~ x, span = 0.2, color = "grey80") + scale_y_continuous(breaks = seq(0, 3, 0.5), limits = c(0, NA)) + ylab("Development Set F1 Increase") + theme(axis.text = element_text(size = 16), strip.text.x = element_text(size = 16), axis.title = element_text(size = 18))
