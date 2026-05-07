# Data Dictionary

The project uses article-level media performance data. The target variable is `Engagement`, defined as total social shares.

| Variable | Description |
|---|---|
| `Record_ID` | Unique identifier for each article |
| `Days_Elapsed` | Days between publication and data extraction |
| `Title_Word_Count` | Number of words in the title |
| `Content_Word_Count` | Number of words in the main text |
| `Unique_Words_Rate` | Ratio of unique words in the content |
| `Non_Stop_Words_Rate` | Ratio of non-common words in the content |
| `Unique_Non_Stop_Rate` | Ratio of unique non-common words |
| `External_Links` | Total number of hyperlinks |
| `Internal_Links` | Number of links to the same platform |
| `Image_Count` | Number of images included |
| `Video_Count` | Number of videos included |
| `Avg_Word_Length` | Average word length |
| `Keyword_Total` | Number of article tags or keywords |
| `Genre_Lifestyle` | Lifestyle genre indicator |
| `Genre_Entertainment` | Entertainment genre indicator |
| `Genre_Business` | Business genre indicator |
| `Genre_SocialMedia` | Social media genre indicator |
| `Genre_Tech` | Technology genre indicator |
| `Genre_International` | International/world genre indicator |
| `Tag_Perf_*` | Historical keyword performance variables excluded from modelling to avoid leakage |
| `Ref_*_Impact` | Referenced-article performance variables excluded from modelling to avoid leakage |
| `Pub_Day_Mon` to `Pub_Day_Sun` | Publication day indicators |
| `Is_Weekend` | Weekend publication indicator |
| `Topic_A_Weight` to `Topic_E_Weight` | Latent topic weights excluded from final modelling due to compositional multicollinearity |
| `Overall_Subjectivity` | Text subjectivity level |
| `Overall_Sentiment` | Text sentiment polarity |
| `Global_Pos_Rate` | Proportion of positive words in the content |
| `Global_Neg_Rate` | Proportion of negative words in the content |
| `Pos_to_NonNeutral_Rate` | Positive word rate among non-neutral words |
| `Neg_to_NonNeutral_Rate` | Negative word rate among non-neutral words |
| `Avg_Pos_Intensity` | Average positive word intensity |
| `Min_Pos_Intensity` | Minimum positive word intensity |
| `Max_Pos_Intensity` | Maximum positive word intensity |
| `Avg_Neg_Intensity` | Average negative word intensity |
| `Min_Neg_Intensity` | Minimum negative word intensity |
| `Max_Neg_Intensity` | Maximum negative word intensity |
| `Title_Subjectivity` | Subjectivity level of the title |
| `Title_Sentiment` | Sentiment polarity of the title |
| `Title_Abs_Subjectivity` | Absolute subjectivity level of the title |
| `Title_Abs_Sentiment` | Absolute sentiment polarity of the title |
| `Engagement` | Total social shares |
