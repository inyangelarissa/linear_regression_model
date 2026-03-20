# African Crop Yield Prediction — Linear Regression

## Mission
My mission is to transform agriculture through innovation, sustainability, and education.I aim to empower farmers and young people with modern skills and technology to improve productivity and livelihoods. I am committed to advancing food security and environmentally responsible practices, My goal is to build resilient communities and a sustainable agricultural future by especially promoting hydroponics farming in the communities.

## Dataset
**Source:** [Kaggle — Crop Yield Prediction Dataset](https://www.kaggle.com/datasets/patelris/crop-yield-prediction-dataset) (filtered to African countries + enriched with World Bank indicators)  
**Description:** Agricultural and climatic records across 18 African countries (Rwanda, Kenya, Nigeria, Ghana, Ethiopia, Mali, Niger, and more), covering 10 African crop types (Maize, Cassava, Sorghum, Millet, Rice, Beans, Groundnuts, Sweet Potatoes, Yams, Plantains) from 1990 to 2013.  
**Size:** 43,200+ rows × 15 columns — features include annual rainfall, average temperature, humidity, fertilizer use, pesticide use, soil quality index, irrigation coverage, GDP per capita, rural population %, CO₂ emissions, and arable land %.  
**Target variable:** `hg/ha_yield` — crop yield in hectograms per hectare.

---

## Repository Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb     ← Main notebook
│   ├── API/                       ← (Leave empty for now)
│   └── FlutterApp/                ← (Leave empty for now)
│
├── saved_models/                  ← Auto-generated when notebook is run
│   ├── best_model.pkl             ← Best performing model
│   ├── scaler.pkl                 ← Fitted StandardScaler
│   └── feature_names.pkl         ← Feature list for prediction
│
└── README.md
```

---

## Key Visualizations

1. **Missing value analysis** — count and % chart per feature
2. **Target distribution** — raw yield histogram + log-transformed + regional boxplot by African region
3. **Scatter plots** — all 12 features vs crop yield with trend lines and human-readable axis labels
4. **Correlation heatmap** — all features with readable column names and data source annotation
5. **Yield by country & crop** — bar charts for all 18 African countries and 10 crop types
6. **Gradient descent loss curve** — train vs validation MSE over 100 epochs
7. **Before & After scatter** — raw data vs linear regression fit with regression line
8. **Feature importance** — Random Forest importance scores
9. **Model comparison** — Train vs Test MSE and R² side by side for all 3 models

---

## How to Run

```bash
# Install dependencies
pip install numpy pandas matplotlib seaborn scikit-learn joblib notebook

# Run the notebook
jupyter notebook summative/linear_regression/multivariate.ipynb
```
