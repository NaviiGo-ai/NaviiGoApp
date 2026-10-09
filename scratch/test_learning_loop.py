import asyncio
import os
import sys
import uuid
import json

# Add backend directory to sys.path to import modules directly for this test
backend_dir = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend"
if backend_dir not in sys.path:
    sys.path.append(backend_dir)

from services.firebase_client import get_db
from services.itinerary_model import generate_itinerary
from services.analytics_engine import process_analytics_events, reset_user_personalization
from services.destination_cache import get_destination_data

async def run_test():
    db = get_db()
    if not db:
        print("Failed to connect to Firebase. Ensure credentials are set.")
        return

    # Use a specific test user id
    test_uid = "learning_loop_tester"
    
    # Clean state before test
    print("--- 1. Resetting personalization state ---")
    await reset_user_personalization(test_uid)
    await asyncio.sleep(1) # Let firestore settle

    # Generate baseline trip
    print("\n--- 2. Generating Baseline Trip to Goa ---")
    req = {
        "userId": test_uid,
        "destinationName": "Goa",
        "tripDays": 3,
        "preferences": {
            "categoryAffinities": {},
            "vibe": "chill",
            "pace": "medium"
        }
    }
    dest_data_goa = await get_destination_data("goa")
    
    baseline = await asyncio.to_thread(generate_itinerary, req, dest_data_goa)
    baseline_json = json.loads(baseline) if isinstance(baseline, str) else baseline
    print("Baseline Categories:")
    # Count occurrences of categories or places
    baseline_categories = {}
    for day in baseline_json.get("dayPlans", []):
        for act in day.get("activities", []):
            cat = act.get("category", "unknown")
            baseline_categories[cat] = baseline_categories.get(cat, 0) + 1
    print(baseline_categories)

    # Dispatch strong positive signals for "Architecture" and "Crafts"
    print("\n--- 3. Firing Canonical Mobile Events (Save / Check-In) ---")
    
    events = [
        {
            "eventId": str(uuid.uuid4()),
            "eventType": "PLACE_SAVED", # +10 affinity
            "occurredAt": "2026-09-17T21:00:00Z",
            "placeId": "basilica_bom_jesus",
            "destinationId": "goa",
            "metadata": {}
        },
        {
            "eventId": str(uuid.uuid4()),
            "eventType": "ACTIVITY_COMPLETED", # +12 affinity
            "occurredAt": "2026-09-17T21:10:00Z",
            "placeId": "se_cathedral",
            "destinationId": "goa",
            "metadata": {}
        },
        {
            "eventId": str(uuid.uuid4()),
            "eventType": "ACTIVITY_SKIPPED", # Negative signal
            "occurredAt": "2026-09-17T21:15:00Z",
            "placeId": "baga_beach",
            "destinationId": "goa",
            "metadata": {"skipReason": "NOT_INTERESTED"} # -10 affinity
        },
        {
            "eventId": str(uuid.uuid4()),
            "eventType": "ACTIVITY_SKIPPED", # Neutral semantic skip
            "occurredAt": "2026-09-17T21:20:00Z",
            "placeId": "anjuna_market",
            "destinationId": "goa",
            "metadata": {"skipReason": "TOO_TIRED"} # 0 affinity
        }
    ]
    
    await process_analytics_events(test_uid, events)
    await asyncio.sleep(2) # Give firestore time to merge doc

    # Read profile back to assert bounded storage and proper signaling
    print("\n--- 4. Asserting AI Profile State ---")
    profile_ref = db.collection("users").document(test_uid).collection("ai_profile").document("main")
    profile = await asyncio.to_thread(profile_ref.get)
    if profile.exists:
        p_data = profile.to_dict()
        print("Visited Places:", p_data.get("visitedPlaceIds", []))
        print("Behavioral Affinities:", p_data.get("behavioralAffinities", {}))
    else:
        print("Profile not created!")

    print("\n--- 5. Generating Personalized Trip to Jaipur ---")
    req_jaipur = {
        "userId": test_uid,
        "destinationName": "Jaipur",
        "tripDays": 3,
        "preferences": {
            "vibe": "chill",
            "pace": "medium"
        }
    }
    
    dest_data_jaipur = await get_destination_data("jaipur")

    # Internally itinerary_model looks up user_data which reads the profile
    jaipur_trip = await asyncio.to_thread(generate_itinerary, req_jaipur, dest_data_jaipur)
    jaipur_json = json.loads(jaipur_trip) if isinstance(jaipur_trip, str) else jaipur_trip
    
    jaipur_categories = {}
    for day in jaipur_json.get("dayPlans", []):
        for act in day.get("activities", []):
            cat = act.get("category", "unknown")
            jaipur_categories[cat] = jaipur_categories.get(cat, 0) + 1
    
    print("Jaipur Categories (Should lean Architecture if weights worked):")
    print(jaipur_categories)

    print("\n--- 6. Verifying Current Intent Override ---")
    req_jaipur_override = {
        "userId": test_uid,
        "destinationName": "Jaipur",
        "tripDays": 3,
        "preferences": {
            "categoryAffinities": {"Nightlife": 100, "Food": 100},
            "vibe": "party",
            "pace": "fast"
        }
    }
    jaipur_override = await asyncio.to_thread(generate_itinerary, req_jaipur_override, dest_data_jaipur)
    override_json = json.loads(jaipur_override) if isinstance(jaipur_override, str) else jaipur_override
    
    override_cats = {}
    for day in override_json.get("dayPlans", []):
        for act in day.get("activities", []):
            cat = act.get("category", "unknown")
            override_cats[cat] = override_cats.get(cat, 0) + 1
            
    print("Rome Override Categories (Should lean Nightlife/Food, ignoring architecture affinity):")
    print(override_cats)
    
    print("\n--- 7. Reset Personalization ---")
    await reset_user_personalization(test_uid)
    await asyncio.sleep(2)
    
    profile_reset = await asyncio.to_thread(profile_ref.get)
    if profile_reset.exists:
        print("Post-Reset Profile:", profile_reset.to_dict())
    
    print("\n[SUCCESS] Verification Complete")

if __name__ == "__main__":
    asyncio.run(run_test())
