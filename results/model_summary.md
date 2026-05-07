# Model Summary

## Data Quality

- Raw rows: 39,644
- Raw columns: 61
- Missing values: 0
- Duplicate `Record_ID` values: 0
- Corrupted records removed: 1
- Final modelling rows: 39,643
- Zero-body-word articles retained: 1,181, representing 3.0% of records

The corrupted record had impossible text-ratio values and was removed before modelling. Leakage variables linked to historical keyword and referenced-article performance were excluded because they would not be available before publication.

## Target Variable

`Engagement` was extremely right-skewed:

- mean: 3,395 shares
- median: 1,400 shares
- maximum: 843,300 shares
- top 1% of articles: 21.8% of total shares

The target was transformed using `log(Engagement + 1)` to reduce skew and improve regression stability.

## Feature Engineering

- Five skewed count predictors were log-transformed: content word count, external links, internal links, image count, and video count.
- Ten micro-sentiment variables were reduced through PCA.
- PC1 and PC2 explained 56.5% of cumulative variance.
- LASSO shrank `Sentiment_PC1` to zero, so `Sentiment_PC2` was retained in the final interpretable model.

## Main OLS Results

| Predictor | Direction / Effect | p-value |
|---|---:|---:|
| Saturday publication | +27.0% vs Monday | <2e-16 |
| Sunday publication | +27.0% vs Monday | <2e-16 |
| Tuesday publication | -5.9% vs Monday | 0.0003 |
| Wednesday publication | -5.9% vs Monday | 0.0003 |
| Social Media genre | +69.1% vs International | <2e-16 |
| No genre classification | +52.4% vs International | <2e-16 |
| Technology genre | +42.2% vs International | <2e-16 |
| Lifestyle genre | +32.5% vs International | <2e-16 |
| Business genre | +26.5% vs International | <2e-16 |
| Overall subjectivity | positive coefficient 0.691 | <2e-16 |
| Image count, log-transformed | positive coefficient 0.071 | <2e-16 |
| Video count, log-transformed | positive coefficient 0.084 | <2e-16 |
| External links, log-transformed | positive coefficient 0.092 | <2e-16 |
| Title sentiment | positive coefficient 0.085 | 0.000022 |
| Title subjectivity | positive coefficient 0.042 | 0.009 |
| Days elapsed | not significant | 0.669 |

## Performance

- Baseline RMSE: 0.9137
- LASSO RMSE: 0.8779
- OLS RMSE: 0.8779
- OLS adjusted R-squared: 0.0864
- VIF checks: all below 5

## Interpretation

The strongest practical insight is that engagement appears to depend more on content packaging and publishing strategy than on volume alone. Weekend timing, genre, media richness, and headline framing are the clearest levers for controlled follow-up testing.
