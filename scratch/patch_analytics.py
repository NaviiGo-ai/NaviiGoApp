import os

file_path = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend\services\analytics_engine.py"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_block = """
        if place_id and weight != 0:
            dest_id = ev.get("destinationId", "")
            if dest_id:
                # We dynamically look up the tag/category for the place
                from services.destination_cache import get_destination_data
                dest_data = asyncio.run(get_destination_data(dest_id)) if asyncio.get_event_loop().is_running() else asyncio.run_coroutine_threadsafe(get_destination_data(dest_id), asyncio.get_event_loop()).result()
                
                # if inside async function, we can't asyncio.run. We should await it.
                # Oh wait, we are inside an async function: async def process_analytics_events
                pass
"""

# Let's write a targeted replacement
replacement = """
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

# Find the target to replace
target = """
        # Assuming we apply this globally for now, or based on category if we looked it up
        if place_id and weight != 0:
            # Fake mapping for this execution pass since we don't have a canonical lookup yet
            # In a real impl, we'd query destinations to get tags.
            pass
"""

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Patched analytics_engine.py successfully.")
else:
    print("Could not find target in analytics_engine.py.")
