import os

file_path = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend\services\analytics_engine.py"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Let's rewrite the replacement block
replacement = """
        if place_id and weight != 0:
            dest_id = ev.get("destinationId", "goa")
            from services.destination_cache import get_destination_data
            dest_data = await get_destination_data(dest_id)
            
            # Find category
            category = "unknown"
            if dest_data:
                for pool in ["highlights", "restaurants"]:
                    for place in dest_data.get(pool, []):
                        nm = place.get("name", "").replace(" ", "_").lower()
                        if place.get("id") == place_id or nm == place_id or nm.replace("of_", "") == place_id:
                            category = place.get("category", "unknown")
                            break
                    if category != "unknown":
                        break
            
            if category != "unknown":
                current_weight = new_affinities.get(category, 0)
                new_affinities[category] = current_weight + weight
"""

# The target in the current patched file looks like this:
target = """
        if place_id and weight != 0:
            dest_id = ev.get("destinationId", "goa") # fallback to goa for testing if missing
            from services.destination_cache import get_destination_data
            dest_data = await get_destination_data(dest_id)
            
            # Find category
            category = "unknown"
            if dest_data and "places" in dest_data:
                for place in dest_data["places"]:
                    if place.get("id") == place_id or place.get("title", "").replace(" ", "_").lower() == place_id:
                        category = place.get("category", "unknown")
                        break
            
            if category != "unknown":
                current_weight = new_affinities.get(category, 0)
                new_affinities[category] = current_weight + weight
"""

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Patched analytics_engine.py successfully.")
else:
    print("Could not find target in analytics_engine.py.")
