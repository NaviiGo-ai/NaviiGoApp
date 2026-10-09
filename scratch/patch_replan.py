import os
import json

backend_dir = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend"

# 1. Create replan_engine.py
replan_engine_content = """
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import uuid

class ProposedChange(BaseModel):
    proposalId: str = Field(default_factory=lambda: str(uuid.uuid4()))
    reason: str
    affectedDay: int
    summary: str
    keptActivities: List[Dict[str, Any]] = Field(default_factory=list)
    removedActivities: List[Dict[str, Any]] = Field(default_factory=list)
    movedActivities: List[Dict[str, Any]] = Field(default_factory=list)
    addedActivities: List[Dict[str, Any]] = Field(default_factory=list)
    updatedTransfers: List[Dict[str, Any]] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    bookingImpact: str = ""
    estimatedTimeImpact: str = ""
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
def generate_replan_proposal(
    trip: dict,
    dest_data: dict,
    current_day_idx: int,
    current_time: str,
    reason: str,
    completed_activity_ids: List[str],
    skipped_activity_ids: List[str],
    location: Optional[Dict[str, float]] = None
) -> ProposedChange:
    day = trip["dayPlans"][current_day_idx]
    activities = day.get("activities", [])
    
    kept = []
    removed = []
    added = []
    
    if reason == "RAIN_PLAN":
        for act in activities:
            if act.get("id") in completed_activity_ids or act.get("id") in skipped_activity_ids:
                kept.append(act)
                continue
            
            # Simple indoor check heuristic
            if act.get("category") in ["Museum", "Shopping", "Food", "must-see", "cultural"]:
                kept.append(act)
            else:
                removed.append(act)
                
        indoor_candidates = []
        if dest_data:
            for pool in ["highlights", "restaurants"]:
                for p in dest_data.get(pool, []):
                    if p.get("category") in ["Museum", "Shopping", "indoor", "Food"]:
                        indoor_candidates.append(p)
                        
        if indoor_candidates:
            new_act = indoor_candidates[0]
            added.append({
                "id": str(uuid.uuid4()),
                "title": new_act.get("name", "Indoor Activity"),
                "category": new_act.get("category", "unknown"),
                "time": current_time,
                "placeId": new_act.get("id", ""),
                "description": new_act.get("description", "A great indoor escape from the rain."),
                "duration": 60
            })
            
        summary = "We found some indoor alternatives to help you stay dry while preserving your bookings."
        warnings = ["Outdoor activities have been removed due to rain."]
        
    elif reason == "I_AM_TIRED":
        for act in activities:
            if act.get("id") in completed_activity_ids or act.get("id") in skipped_activity_ids:
                kept.append(act)
            else:
                removed.append(act)
                
        summary = "Ending the day early so you can rest. Your remaining activities have been cleared."
        warnings = []
        
    else:
        kept = activities
        summary = f"Replanning requested for: {reason}"
        warnings = ["This replan mode is currently using default logic."]

    return ProposedChange(
        reason=reason,
        affectedDay=current_day_idx,
        summary=summary,
        keptActivities=kept,
        removedActivities=removed,
        addedActivities=added,
        warnings=warnings
    )
"""

with open(os.path.join(backend_dir, "services", "replan_engine.py"), "w", encoding="utf-8") as f:
    f.write(replan_engine_content)
    print("Created replan_engine.py")

# 2. Modify itinerary.py
itinerary_py = os.path.join(backend_dir, "routers", "itinerary.py")
with open(itinerary_py, "r", encoding="utf-8") as f:
    content = f.read()

replan_endpoint = """
class ReplanRequest(BaseModel):
    tripId: str
    currentDay: int
    currentTime: str
    reason: str
    completedActivityIds: List[str] = Field(default_factory=list)
    skippedActivityIds: List[str] = Field(default_factory=list)
    location: Optional[Dict[str, float]] = None

class ReplanAcceptRequest(BaseModel):
    tripId: str
    proposalId: str
    proposalData: Dict[str, Any]

@router.post("/replan")
async def replan_itinerary(payload: ReplanRequest, request: Request):
    try:
        authorization = request.headers.get("Authorization", "")
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Sign in required")
            
        token_claims = verify_firebase_id_token(authorization.removeprefix("Bearer ").strip())
        uid = token_claims.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid session")
            
        from services.firebase_client import get_db
        db = get_db()
        trip_doc = db.collection("users").document(uid).collection("trips").document(payload.tripId).get()
        if not trip_doc.exists:
            raise HTTPException(status_code=404, detail="Trip not found")
            
        trip_data = trip_doc.to_dict()
        trip_obj = trip_data.get("generatedData", trip_data)
        
        dest_name = trip_obj.get("destName", "").lower()
        gemini_data = await get_destination_data(dest_name=dest_name, purpose="cultural", budget=1000, days=3)
        
        from services.replan_engine import generate_replan_proposal
        proposal = generate_replan_proposal(
            trip=trip_obj,
            dest_data=gemini_data,
            current_day_idx=payload.currentDay,
            current_time=payload.currentTime,
            reason=payload.reason,
            completed_activity_ids=payload.completedActivityIds,
            skipped_activity_ids=payload.skippedActivityIds,
            location=payload.location
        )
        
        return {"success": True, "proposal": proposal.dict()}
        
    except Exception as e:
        print(f"[Replan] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/replan/accept")
async def accept_replan(payload: ReplanAcceptRequest, request: Request):
    try:
        authorization = request.headers.get("Authorization", "")
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Sign in required")
            
        token_claims = verify_firebase_id_token(authorization.removeprefix("Bearer ").strip())
        uid = token_claims.get("uid")
        
        from services.firebase_client import get_db
        db = get_db()
        trip_ref = db.collection("users").document(uid).collection("trips").document(payload.tripId)
        trip_doc = trip_ref.get()
        if not trip_doc.exists:
            raise HTTPException(status_code=404, detail="Trip not found")
            
        trip_data = trip_doc.to_dict()
        trip_obj = trip_data.get("generatedData", trip_data)
        
        proposal = payload.proposalData
        day_idx = proposal.get("affectedDay", 0)
        
        # Archive previous revision
        revisions = trip_data.get("revisions", [])
        revisions.append({
            "revisionId": proposal.get("proposalId"),
            "reason": proposal.get("reason"),
            "timestamp": datetime.utcnow().isoformat(),
            "dayPlans": [trip_obj["dayPlans"][day_idx]] # Just save the affected day for brevity
        })
        
        # Apply mutation
        day_plan = trip_obj["dayPlans"][day_idx]
        new_activities = []
        for act in proposal.get("keptActivities", []): new_activities.append(act)
        for act in proposal.get("addedActivities", []): new_activities.append(act)
        day_plan["activities"] = new_activities
        
        # Save canonical itinerary
        if "generatedData" in trip_data:
            trip_data["generatedData"] = trip_obj
            trip_data["revisions"] = revisions
            trip_ref.set(trip_data, merge=True)
        else:
            trip_ref.set({"dayPlans": trip_obj["dayPlans"], "revisions": revisions}, merge=True)
            
        return {"success": True}
        
    except Exception as e:
        print(f"[ReplanAccept] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
"""

if "class ReplanRequest" not in content:
    content += "\n" + replan_endpoint
    with open(itinerary_py, "w", encoding="utf-8") as f:
        f.write(content)
    print("Added replan endpoints to itinerary.py")
else:
    print("Endpoints already exist in itinerary.py")
