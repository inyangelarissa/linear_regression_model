import os
import numpy as np
import pandas as pd
import joblib

# ─────────────────────────────────────────────────────────────────────────────
# Paths — works whether called from repo root or from summative/linear_regression/
# ─────────────────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH  = os.path.join(BASE_DIR, "saved_models", "best_model.pkl")
SCALER_PATH = os.path.join(BASE_DIR, "saved_models", "scaler.pkl")
FEATS_PATH  = os.path.join(BASE_DIR, "saved_models", "feature_names.pkl")

# ─────────────────────────────────────────────────────────────────────────────
# Label encoding maps — must match the alphabetical order LabelEncoder used
# in multivariate.ipynb (LabelEncoder sorts classes alphabetically)
# ─────────────────────────────────────────────────────────────────────────────
COUNTRY_ENCODING = {
    "Angola":       0,
    "Burkina Faso": 1,
    "Cameroon":     2,
    "Ethiopia":     3,
    "Ghana":        4,
    "Guinea":       5,
    "Kenya":        6,
    "Malawi":       7,
    "Mali":         8,
    "Mozambique":   9,
    "Niger":        10,
    "Nigeria":      11,
    "Rwanda":       12,
    "Senegal":      13,
    "Tanzania":     14,
    "Uganda":       15,
    "Zambia":       16,
    "Zimbabwe":     17,
}

CROP_ENCODING = {
    "Beans":          0,
    "Cassava":        1,
    "Groundnuts":     2,
    "Maize":          3,
    "Millet":         4,
    "Plantains":      5,
    "Rice":           6,
    "Sorghum":        7,
    "Sweet potatoes": 8,
    "Yams":           9,
}


# ─────────────────────────────────────────────────────────────────────────────
# Helper — load artifacts once
# ─────────────────────────────────────────────────────────────────────────────
def _load_artifacts():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"\n  Model not found at: {MODEL_PATH}"
            "\n  Please run multivariate.ipynb first to train and save the model."
        )
    model    = joblib.load(MODEL_PATH)
    scaler   = joblib.load(SCALER_PATH)
    features = joblib.load(FEATS_PATH)
    return model, scaler, features


# ─────────────────────────────────────────────────────────────────────────────
# Main prediction function
# ─────────────────────────────────────────────────────────────────────────────
def predict_yield(input_data: dict) -> dict:
    """
    Predict crop yield for a single data point.

    Parameters
    ----------
    input_data : dict
        Raw, human-readable input values. Pass the country name and crop
        name as strings — this function encodes them automatically.

        Required keys:
        ┌─────────────────────────────────────┬────────┬──────────────────────────┐
        │ Key                                 │ Type   │ Example                  │
        ├─────────────────────────────────────┼────────┼──────────────────────────┤
        │ country                             │ str    │ "Ghana"                  │
        │ crop                                │ str    │ "Maize"                  │
        │ year                                │ int    │ 2010                     │
        │ average_rain_fall_mm_per_year       │ float  │ 1050.0                   │
        │ avg_temp                            │ float  │ 24.5   (°C)              │
        │ humidity_pct                        │ float  │ 68.0   (%)               │
        │ pesticides_tonnes                   │ float  │ 32.8   (raw tonnes)      │
        │ fertilizer_kg_ha                    │ float  │ 30.5   (kg/ha)           │
        │ arable_land_pct                     │ float  │ 44.0   (%)               │
        │ soil_quality_index                  │ float  │ 65.0   (0–100)           │
        │ irrigation_coverage_pct             │ float  │ 11.2   (%)               │
        │ gdp_per_capita_usd                  │ float  │ 1200.0 (USD)             │
        │ rural_population_pct                │ float  │ 58.0   (%)               │
        │ co2_emissions_metric_tons           │ float  │ 0.13                     │
        └─────────────────────────────────────┴────────┴──────────────────────────┘

    Returns
    -------
    dict
        {
            "predicted_yield_hg_ha" : float   # hectograms per hectare
            "predicted_yield_kg_ha" : float   # kilograms per hectare (÷100)
            "predicted_yield_t_ha"  : float   # tonnes per hectare (÷100000)
            "model_used"            : str     # model class name
            "country"               : str
            "crop"                  : str
        }
    """
    model, scaler, features = _load_artifacts()

    # ── 1. Encode country and crop ────────────────────────────────────────────
    country = input_data.get("country", "")
    crop    = input_data.get("crop", "")

    if country not in COUNTRY_ENCODING:
        raise ValueError(
            f"Unknown country: '{country}'.\n"
            f"Valid options: {sorted(COUNTRY_ENCODING.keys())}"
        )
    if crop not in CROP_ENCODING:
        raise ValueError(
            f"Unknown crop: '{crop}'.\n"
            f"Valid options: {sorted(CROP_ENCODING.keys())}"
        )

    # ── 2. Apply log transform to pesticides (same as notebook) ──────────────
    pesticides_raw = float(input_data.get("pesticides_tonnes", 0))
    log_pesticides = np.log1p(pesticides_raw)

    # ── 3. Build feature row in the exact order saved by the notebook ─────────
    row = pd.DataFrame([{
        "Year":                          int(input_data["year"]),
        "average_rain_fall_mm_per_year": float(input_data["average_rain_fall_mm_per_year"]),
        "avg_temp":                      float(input_data["avg_temp"]),
        "humidity_pct":                  float(input_data["humidity_pct"]),
        "fertilizer_kg_ha":              float(input_data["fertilizer_kg_ha"]),
        "arable_land_pct":               float(input_data["arable_land_pct"]),
        "soil_quality_index":            float(input_data["soil_quality_index"]),
        "irrigation_coverage_pct":       float(input_data["irrigation_coverage_pct"]),
        "gdp_per_capita_usd":            float(input_data["gdp_per_capita_usd"]),
        "rural_population_pct":          float(input_data["rural_population_pct"]),
        "co2_emissions_metric_tons":     float(input_data["co2_emissions_metric_tons"]),
        "log_pesticides":                log_pesticides,
        "Area_encoded":                  COUNTRY_ENCODING[country],
        "Item_encoded":                  CROP_ENCODING[crop],
    }])

    # ── 4. Reorder columns to match training feature order ────────────────────
    row = row[features]

    # ── 5. Scale and predict ──────────────────────────────────────────────────
    row_scaled        = scaler.transform(row)
    predicted_hg_ha   = float(model.predict(row_scaled)[0])
    predicted_hg_ha   = max(0.0, round(predicted_hg_ha, 2))

    return {
        "predicted_yield_hg_ha": predicted_hg_ha,
        "predicted_yield_kg_ha": round(predicted_hg_ha / 100, 4),
        "predicted_yield_t_ha":  round(predicted_hg_ha / 100_000, 6),
        "model_used":            type(model).__name__,
        "country":               country,
        "crop":                  crop,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Run directly — demo prediction
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":

    sample = {
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

    try:
        result = predict_yield(sample)

        print("\n" + "=" * 55)
        print("   🌾  AFRICAN CROP YIELD — PREDICTION RESULT")
        print("=" * 55)
        print(f"  Country          : {result['country']}")
        print(f"  Crop             : {result['crop']}")
        print(f"  Model used       : {result['model_used']}")
        print("-" * 55)
        print("  Input values:")
        skip = {"country", "crop"}
        for k, v in sample.items():
            if k not in skip:
                print(f"    {k:<40s}: {v}")
        print("-" * 55)
        print(f"  Predicted yield  : {result['predicted_yield_hg_ha']:>12,.2f}  hg/ha")
        print(f"  Predicted yield  : {result['predicted_yield_kg_ha']:>12,.4f}  kg/ha")
        print(f"  Predicted yield  : {result['predicted_yield_t_ha']:>12,.6f}  t/ha")
        print("=" * 55)

    except FileNotFoundError as e:
        print(e)
    except ValueError as e:
        print(f"\n⚠️  Input error: {e}")