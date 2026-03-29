# African Crop Yield Prediction — Linear Regression

## Mission
My mission is to transform agriculture through innovation, sustainability, and education.I aim to empower farmers and young people with modern skills and technology to improve productivity and livelihoods. I am committed to advancing food security and environmentally responsible practices, My goal is to build resilient communities and a sustainable agricultural future by especially promoting hydroponics farming in the communities.

## Dataset
**Source:** [Kaggle — Crop Yield Prediction Dataset](https://www.kaggle.com/datasets/patelris/crop-yield-prediction-dataset) 

**Dataset**: African Crop Yield Dataset (World Bank Open Data)

**Description:** Agricultural and climatic records across 18 African countries (Rwanda, Kenya, Nigeria, Ghana, Ethiopia, Mali, Niger, and more), covering 10 African crop types (Maize, Cassava, Sorghum, Millet, Rice, Beans, Groundnuts, Sweet Potatoes, Yams, Plantains) from 1990 to 2013.  

## Video Presentation
**Link:** https://youtu.be/wp0EIE0TyZk


## API endpoint
**Link:** http://linearregressionmodel-production-548a.up.railway.app/docs


---

## Repository Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb
        ├── saved_models/                  
             ├── best_model.pkl             
             ├── scaler.pkl                 
             └── feature_names.pkl           
│   ├── API/                       
│   └── FlutterApp/                      
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

## How to Run the notebook

```bash
# Install dependencies
pip install numpy pandas matplotlib seaborn scikit-learn joblib notebook

# Run the notebook
jupyter notebook summative/linear_regression/multivariate.ipynb
```
## Step-by-Step: Run the App

### Step 1: Clone the repository

Open a terminal and run:

git clone https://github.com/YOUR_USERNAME/linear_regression_model.git
cd linear_regression_model

### Step 2: Navigate to the Flutter app folder

cd summative/FlutterApp

### Step 3: Install dependencies

flutter pub get

### Step 4: Start the Android emulator

Open Android Studio
Click Virtual Device Manager (top right toolbar)
Press the Play ▶ button next to your device
Wait for the emulator to fully boot (shows the home screen)

### Step 5: Run the app

In the terminal (still inside summative/FlutterApp), run:

flutter run

The app will build and launch on the emulator automatically.
