import os
import io
import numpy as np
import pandas as pd
import joblib

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Literal

try:
    from .predict import predict_yield, COUNTRY_ENCODING, CROP_ENCODING
except ImportError:
    from predict import predict_yield, COUNTRY_ENCODING, CROP_ENCODING

# ─────────────────────────────────────────────────────────────────────────────
# App setup
# ─────────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="🌾 African Crop Yield Prediction API",
    description=(
        "Predicts crop yield (hg/ha) for 18 African countries and 10 crop types "
        "using a machine learning model trained on FAO STAT / World Bank data (1990–2013). "
        "Supports single predictions and model retraining with new data."
    ),
    version="1.0.0",
)

# ─────────────────────────────────────────────────────────────────────────────
# CORS Middleware — allows Flutter app and any frontend to call this API
# ─────────────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Allow all origins (restrict in production)
    allow_credentials=True,
    allow_methods=["*"],        # Allow GET, POST, OPTIONS, etc.
    allow_headers=["*"],        # Allow all headers
)

# ─────────────────────────────────────────────────────────────────────────────
# Pydantic input model — enforced types + realistic range constraints
# ─────────────────────────────────────────────────────────────────────────────
class APIModel(BaseModel):
    model_config = {"protected_namespaces": ()}


class CropYieldInput(APIModel):
    country: Literal[
        "Angola", "Burkina Faso", "Cameroon", "Ethiopia", "Ghana",
        "Guinea", "Kenya", "Malawi", "Mali", "Mozambique",
        "Niger", "Nigeria", "Rwanda", "Senegal", "Tanzania",
        "Uganda", "Zambia", "Zimbabwe"
    ] = Field(..., description="African country name")

    crop: Literal[
        "Beans", "Cassava", "Groundnuts", "Maize", "Millet",
        "Plantains", "Rice", "Sorghum", "Sweet potatoes", "Yams"
    ] = Field(..., description="Crop type")

    year: int = Field(
        ..., ge=1990, le=2030,
        description="Year of the observation (1990–2030)"
    )
    average_rain_fall_mm_per_year: float = Field(
        ..., ge=50.0, le=3000.0,
        description="Annual rainfall in mm (50–3000)"
    )
    avg_temp: float = Field(
        ..., ge=10.0, le=40.0,
        description="Average temperature in °C (10–40)"
    )
    humidity_pct: float = Field(
        ..., ge=10.0, le=100.0,
        description="Relative humidity in % (10–100)"
    )
    pesticides_tonnes: float = Field(
        ..., ge=0.0, le=500.0,
        description="Pesticide use in tonnes (0–500)"
    )
    fertilizer_kg_ha: float = Field(
        ..., ge=0.0, le=500.0,
        description="Fertilizer applied in kg/ha (0–500)"
    )
    arable_land_pct: float = Field(
        ..., ge=1.0, le=90.0,
        description="Arable land as % of total land (1–90)"
    )
    soil_quality_index: float = Field(
        ..., ge=0.0, le=100.0,
        description="Soil quality index (0–100)"
    )
    irrigation_coverage_pct: float = Field(
        ..., ge=0.0, le=100.0,
        description="Irrigation coverage in % (0–100)"
    )
    gdp_per_capita_usd: float = Field(
        ..., ge=100.0, le=20000.0,
        description="GDP per capita in USD (100–20000)"
    )
    rural_population_pct: float = Field(
        ..., ge=10.0, le=100.0,
        description="Rural population as % of total (10–100)"
    )
    co2_emissions_metric_tons: float = Field(
        ..., ge=0.0, le=5.0,
        description="CO₂ emissions in metric tons per capita (0–5)"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "country":                        "Ghana",
                "crop":                           "Maize",
                "year":                           2010,
                "average_rain_fall_mm_per_year":  1050.0,
                "avg_temp":                       24.5,
                "humidity_pct":                   68.0,
                "pesticides_tonnes":              32.8,
                "fertilizer_kg_ha":               30.5,
                "arable_land_pct":                44.0,
                "soil_quality_index":             65.0,
                "irrigation_coverage_pct":        11.2,
                "gdp_per_capita_usd":             1380.0,
                "rural_population_pct":           58.0,
                "co2_emissions_metric_tons":      0.13,
            }
        }
    }


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic output model
# ─────────────────────────────────────────────────────────────────────────────
class PredictionResponse(APIModel):
    predicted_yield_hg_ha: float = Field(..., description="Predicted yield in hg/ha")
    predicted_yield_kg_ha: float = Field(..., description="Predicted yield in kg/ha")
    predicted_yield_t_ha:  float = Field(..., description="Predicted yield in t/ha")
    model_used:            str   = Field(..., description="Model class used for prediction")
    country:               str   = Field(..., description="Country input")
    crop:                  str   = Field(..., description="Crop type input")


class RetrainResponse(APIModel):
    message:        str   = Field(..., description="Status message")
    rows_used:      int   = Field(..., description="Number of training rows used")
    best_model:     str   = Field(..., description="Best model after retraining")
    test_r2:        float = Field(..., description="R² score on test set")
    test_mse:       float = Field(..., description="MSE on test set")


# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
def root():
    """Health check — confirms the API is running."""
    return {
        "status":  "online",
        "message": "African Crop Yield Prediction API is running.",
        "docs":    "/docs",
    }


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(data: CropYieldInput):
    """
    **Predict crop yield** for a single African farm data point.

    - Accepts all 14 input features with enforced types and range constraints.
    - Applies the same preprocessing pipeline used during training
      (log transform on pesticides, label encoding for country and crop).
    - Returns yield in hg/ha, kg/ha, and t/ha.
    """
    try:
        result = predict_yield(data.model_dump())
        return PredictionResponse(**result)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
async def retrain(file: UploadFile = File(...)):
    """
    **Retrain the model** using newly uploaded data.

    - Upload a CSV file with the same columns as the training dataset.
    - The API retrains Linear Regression, Decision Tree, and Random Forest.
    - The best-performing model (lowest Test MSE) is saved, replacing the old one.

    **Required CSV columns:**
    `Area, Item, Year, average_rain_fall_mm_per_year, avg_temp, humidity_pct,
    pesticides_tonnes, fertilizer_kg_ha, arable_land_pct, soil_quality_index,
    irrigation_coverage_pct, gdp_per_capita_usd, rural_population_pct,
    co2_emissions_metric_tons, hg/ha_yield`
    """
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import StandardScaler, LabelEncoder
    from sklearn.linear_model import LinearRegression
    from sklearn.tree import DecisionTreeRegressor
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.metrics import mean_squared_error, r2_score

    # ── 1. Read uploaded CSV ──────────────────────────────────────────────────
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are accepted.")

    contents = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(contents))
    except Exception:
        raise HTTPException(status_code=400, detail="Could not parse CSV file.")

    required_cols = {
        "Area", "Item", "Year", "average_rain_fall_mm_per_year", "avg_temp",
        "humidity_pct", "pesticides_tonnes", "fertilizer_kg_ha", "arable_land_pct",
        "soil_quality_index", "irrigation_coverage_pct", "gdp_per_capita_usd",
        "rural_population_pct", "co2_emissions_metric_tons", "hg/ha_yield"
    }
    missing = required_cols - set(df.columns)
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"CSV is missing required columns: {sorted(missing)}"
        )

    if len(df) < 50:
        raise HTTPException(
            status_code=400,
            detail="CSV must contain at least 50 rows for retraining."
        )

    # ── 2. Preprocess ─────────────────────────────────────────────────────────
    df.dropna(inplace=True)

    # Log-transform pesticides
    df["log_pesticides"] = np.log1p(df["pesticides_tonnes"])
    df.drop(columns=["pesticides_tonnes"], inplace=True)

    # Encode categorical columns
    for col in ["Area", "Item"]:
        le = LabelEncoder()
        df[col + "_encoded"] = le.fit_transform(df[col].astype(str))
        df.drop(columns=[col], inplace=True)

    TARGET   = "hg/ha_yield"
    FEATURES = [c for c in df.columns if c != TARGET]

    X = df[FEATURES]
    y = df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler         = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled  = scaler.transform(X_test)

    # ── 3. Train all three models ─────────────────────────────────────────────
    models = {
        "LinearRegression":     LinearRegression(),
        "DecisionTreeRegressor": DecisionTreeRegressor(max_depth=10, random_state=42),
        "RandomForestRegressor": RandomForestRegressor(n_estimators=100, max_depth=15,
                                                        random_state=42, n_jobs=-1),
    }

    best_name  = None
    best_model = None
    best_mse   = float("inf")
    best_r2    = 0.0

    for name, model in models.items():
        model.fit(X_train_scaled, y_train)
        mse = mean_squared_error(y_test, model.predict(X_test_scaled))
        r2  = r2_score(y_test, model.predict(X_test_scaled))
        if mse < best_mse:
            best_mse   = mse
            best_r2    = r2
            best_name  = name
            best_model = model

    # ── 4. Save the new best model ────────────────────────────────────────────
    BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
    models_dir  = os.path.join(BASE_DIR, "saved_models")
    os.makedirs(models_dir, exist_ok=True)

    joblib.dump(best_model, os.path.join(models_dir, "best_model.pkl"))
    joblib.dump(scaler,     os.path.join(models_dir, "scaler.pkl"))
    joblib.dump(FEATURES,   os.path.join(models_dir, "feature_names.pkl"))

    return RetrainResponse(
        message=f"Model retrained successfully. Best model: {best_name}",
        rows_used=len(df),
        best_model=best_name,
        test_r2=round(best_r2, 6),
        test_mse=round(best_mse, 2),
    )
