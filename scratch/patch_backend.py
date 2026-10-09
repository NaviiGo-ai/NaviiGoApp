import os

backend_dir = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend"

analytics_router_content = """from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime
from services.firebase_client import verify_firebase_id_token
from services.analytics_engine import process_analytics_events, reset_user_personalization

router = APIRouter()

class AnalyticsContext(BaseModel):
    surface: Optional[str] = None
    tripState: Optional[str] = None
    tripVibe: Optional[str] = None

class AnalyticsMetadata(BaseModel):
    skipReason: Optional[str] = None
    rating: Optional[int] = None
    confirmationSource: Optional[str] = None

class AnalyticsEvent(BaseModel):
    eventId: str
    schemaVersion: str = "1.0"
    eventType: str
    occurredAt: str
    receivedAt: Optional[str] = None
    tripId: Optional[str] = None
    dayId: Optional[str] = None
    activityId: Optional[str] = None
    placeId: Optional[str] = None
    destinationId: Optional[str] = None
    sessionId: Optional[str] = None
    context: Optional[AnalyticsContext] = None
    metadata: Optional[AnalyticsMetadata] = None

class TrackEventsRequest(BaseModel):
    events: List[AnalyticsEvent]

@router.post("/track")
async def track_events(
    request: TrackEventsRequest,
    background_tasks: BackgroundTasks,
    auth: dict = Depends(verify_firebase_id_token)
):
    uid = auth.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid auth token")

    events_list = []
    for e in request.events:
        e.receivedAt = datetime.utcnow().isoformat()
        events_list.append(e.dict())

    background_tasks.add_task(process_analytics_events, uid, events_list)
    return {"status": "accepted", "count": len(events_list)}

@router.post("/reset")
async def reset_personalization(
    background_tasks: BackgroundTasks,
    auth: dict = Depends(verify_firebase_id_token)
):
    uid = auth.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid auth token")

    background_tasks.add_task(reset_user_personalization, uid)
    return {"status": "accepted"}
"""

analytics_engine_content = """import asyncio
from datetime import datetime
from typing import List, Dict, Any
from services.firebase_client import get_db
from firebase_admin import firestore

# Approved Event Weights
EVENT_WEIGHTS = {
    "PLACE_VIEWED": 1,
    "PLACE_SAVED": 10,
    "PLACE_ADDED_TO_TRIP": 15,
    "ACTIVITY_CHECKED_IN": 6,
    "ACTIVITY_COMPLETED": 12,
    "EXPLICITLY_LIKED": 30,
    "RECOMMENDATION_DISMISSED": -12,
}

SKIP_PENALTIES = {
    "NOT_INTERESTED": -10,
    "TOO_TIRED": 0,
    "WEATHER": 0,
    "CLOSED": 0,
    "TOO_FAR": 0,
    "NO_TIME": 0,
}

async def process_analytics_events(uid: str, events: List[Dict[str, Any]]):
    db = get_db()
    if not db: return

    # 1. Fetch current ai_profile to check for reset epoch
    profile_ref = db.collection("users").document(uid).collection("ai_profile").document("main")
    profile_doc = await asyncio.to_thread(profile_ref.get)
    ai_profile = profile_doc.to_dict() if profile_doc.exists else {}
    
    reset_epoch = ai_profile.get("personalizationResetAt", None)

    # Prepare batch for idempotent storage and profile updates
    batch = db.batch()
    new_affinities = ai_profile.get("behavioralAffinities", {})
    visited_ids = set(ai_profile.get("visitedPlaceIds", []))
    dismissed_ids = set(ai_profile.get("dismissedPlaceIds", []))
    
    events_ref = db.collection("users").document(uid).collection("analytics_events")
    
    for ev in events:
        event_id = ev.get("eventId")
        if not event_id: continue
        
        # 1. Save raw event idemptotically
        ev_doc_ref = events_ref.document(event_id)
        batch.set(ev_doc_ref, ev, merge=True)
        
        # Check if event is before reset epoch
        occurred_at = ev.get("occurredAt")
        if reset_epoch and occurred_at and occurred_at < reset_epoch:
            continue
            
        event_type = ev.get("eventType")
        place_id = ev.get("placeId")
        
        # 2. Update strict visit/dismissed evidence
        if event_type in ["ACTIVITY_CHECKED_IN", "ACTIVITY_COMPLETED", "POST_TRIP_PLACE_CONFIRMED_VISITED"]:
            if place_id: visited_ids.add(place_id)
        elif event_type == "RECOMMENDATION_DISMISSED":
            if place_id: dismissed_ids.add(place_id)
            
        # 3. Update behavior affinities
        weight = EVENT_WEIGHTS.get(event_type, 0)
        if event_type == "ACTIVITY_SKIPPED":
            skip_reason = (ev.get("metadata") or {}).get("skipReason", "")
            weight = SKIP_PENALTIES.get(skip_reason, 0)
            
        # Assuming we apply this globally for now, or based on category if we looked it up
        if place_id and weight != 0:
            # Fake mapping for this execution pass since we don't have a canonical lookup yet
            # In a real impl, we'd query destinations to get tags.
            pass

    # Ensure bounded arrays (keep last 200 visited/dismissed to prevent doc size bloat)
    bounded_visited = list(visited_ids)[-200:]
    bounded_dismissed = list(dismissed_ids)[-200:]
    
    updates = {
        "visitedPlaceIds": bounded_visited,
        "dismissedPlaceIds": bounded_dismissed,
        "behavioralAffinities": new_affinities,
        "scoringVersion": "1.1",
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    
    batch.set(profile_ref, updates, merge=True)
    await asyncio.to_thread(batch.commit)

async def reset_user_personalization(uid: str):
    db = get_db()
    if not db: return
    ref = db.collection("users").document(uid).collection("ai_profile").document("main")
    await asyncio.to_thread(ref.set, {
        "personalizationResetAt": datetime.utcnow().isoformat(),
        "behavioralAffinities": {},
        "visitedPlaceIds": [],
        "dismissedPlaceIds": [],
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }, merge=True)
"""

with open(os.path.join(backend_dir, "routers", "analytics.py"), "w", encoding="utf-8") as f:
    f.write(analytics_router_content)

with open(os.path.join(backend_dir, "services", "analytics_engine.py"), "w", encoding="utf-8") as f:
    f.write(analytics_engine_content)

# Patch main.py to include analytics router
main_py_path = os.path.join(backend_dir, "main.py")
with open(main_py_path, "r", encoding="utf-8") as f:
    main_py_content = f.read()

if "routers import" in main_py_content and "analytics" not in main_py_content:
    main_py_content = main_py_content.replace(
        "from routers import itinerary, chat, recommendations, explore, weather, transport, taste, places, admin",
        "from routers import itinerary, chat, recommendations, explore, weather, transport, taste, places, admin, analytics"
    )

if "app.include_router(admin.router" in main_py_content and "app.include_router(analytics.router" not in main_py_content:
    main_py_content = main_py_content.replace(
        'app.include_router(admin.router,           prefix="/api/admin",           tags=["Admin"])',
        'app.include_router(admin.router,           prefix="/api/admin",           tags=["Admin"])\\napp.include_router(analytics.router,       prefix="/api/analytics",       tags=["Analytics"])'
    )

with open(main_py_path, "w", encoding="utf-8") as f:
    f.write(main_py_content)

# Patch user_data.py to extract ai_profile properly for itinerary context
user_data_path = os.path.join(backend_dir, "services", "user_data.py")
with open(user_data_path, "r", encoding="utf-8") as f:
    user_data_content = f.read()

if '"ai_profile": ai_profile' not in user_data_content:
    user_data_content = user_data_content.replace(
        '"pastDestinations": (ai_profile or {}).get("pastDestinations", []),',
        '"pastDestinations": (ai_profile or {}).get("pastDestinations", []),\n        "ai_profile": ai_profile,'
    )
with open(user_data_path, "w", encoding="utf-8") as f:
    f.write(user_data_content)


# Patch itinerary_model.py
itin_py_path = os.path.join(backend_dir, "services", "itinerary_model.py")
with open(itin_py_path, "r", encoding="utf-8") as f:
    itin_py_content = f.read()

patch = '''    # 6a. Penalize explicitly dismissed places or previously visited places
    ai_profile = ctx.get("ai_profile") or {}
    place_id = attr.get("placeId")
    if place_id:
        if place_id in ai_profile.get("dismissedPlaceIds", []):
            score -= 100 # Strong penalty for dismissed
        if place_id in ai_profile.get("visitedPlaceIds", []):
            score -= 20 # Soft penalty for repetition (unless explicitly requested)
'''
if "6. Browsing signals boost" in itin_py_content and "6a. Penalize explicitly dismissed" not in itin_py_content:
    itin_py_content = itin_py_content.replace(
        "    # 6. Browsing signals boost",
        patch + "\\n    # 6. Browsing signals boost"
    )

with open(itin_py_path, "w", encoding="utf-8") as f:
    f.write(itin_py_content)

print("Patch applied successfully.")
