import joblib
import os
import pandas as pd
from models.property import Property

# Get current file directory (backend/services)
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(CURRENT_DIR, "..", "ai_model", "price_model.pkl")
MODEL_PATH = os.path.normpath(MODEL_PATH)
model = joblib.load(MODEL_PATH)

def read_mean_values(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    data_sections = {
        "GLOBAL": 0,
        "STATE": {},
        "TOWN": {},
        "DISTRICT": {},
        "TYPE": {}
    }

    current_section = None
    for line in lines:
        line = line.strip()

        if not line:
            continue

        # Detect section headers
        if line.startswith("# GLOBAL"):
            current_section = "GLOBAL"
        elif line.startswith("# STATE"):
            current_section = "STATE"
        elif line.startswith("# TOWN"):
            current_section = "TOWN"
        elif line.startswith("# DISTRICT"):
            current_section = "DISTRICT"
        elif line.startswith("# TYPE"):
            current_section = "TYPE"
        else:
            # detect line wiht ":" and current section is not none.
            if current_section == "GLOBAL":
                data_sections["GLOBAL"] = float(line)
            elif ":" in line and current_section:
                k, v = line.split(":", 1)
                data_sections[current_section][k.strip()] = float(v.strip())

    return (
        data_sections["GLOBAL"],
        data_sections["STATE"],
        data_sections["TOWN"],
        data_sections["DISTRICT"],
        data_sections["TYPE"]
    )


MEAN_VALUES_PATH = os.path.join(CURRENT_DIR, "..", "ai_model", "mean_values.txt")
MEAN_VALUES_PATH = os.path.normpath(MEAN_VALUES_PATH)
global_mean, state_mean, town_mean, district_mean, type_mean = read_mean_values(MEAN_VALUES_PATH)

def predict(property_id):
    prop = Property.find_by_id(property_id)

    if not prop:    
        return False, "Property Not Found !"

    state = prop.state.lower() if prop.state else None
    town = prop.city.lower() if prop.city else None
    district = prop.district.lower() if prop.district else None
    type_ = prop.residence_type.lower() if prop.residence_type else None
    size = prop.land_size
    bed = prop.num_bedrooms
    bath = prop.num_bathrooms   

    # Get mean values based on input (fallback to global if not found)
    state_mean_val = state_mean.get(state, global_mean)
    town_mean_val = town_mean.get(town, global_mean)
    district_mean_val = district_mean.get(district, global_mean)
    type_mean_val = type_mean.get(type_, global_mean)

    # Create a single-row dataframe for prediction
    df = pd.DataFrame([{
        'size': size,
        'bed': bed,
        'bath': bath,
        'type_mean': type_mean_val,
        'town_mean': town_mean_val,
        'district_mean': district_mean_val,
        'state_mean': state_mean_val,
    }])

    predicted_price = model.predict(df)[0]
    return True, float(predicted_price)

