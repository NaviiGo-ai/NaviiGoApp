# Runtime Personalization Acceptance Checklist

Due to emulator constraints in the development environment, the final runtime networking layer must be validated manually on a physical device.

**Prerequisites:**
- Physical device or emulator with network connectivity
- Staging Firebase Auth account

## Test Execution Steps

1. **Login & Initial State**: Login with the staging Firebase account. Ensure the AI Profile `visitedPlaceIds` and `behavioralAffinities` are empty.
2. **Web Generation**: Generate a trip on Web. Save 2 places and Unsave 1 place.
3. **Mobile Generation**: Open the Flutter app. Generate a new trip. Verify the saved categories from Web influenced the Mobile generation.
4. **Mobile Trip Tracking**: Start the trip on Mobile. Check-in to 1 activity. Complete 1 activity.
5. **Contextual Skip**: Skip 1 activity citing `NOT_INTERESTED`.
6. **Offline Simulation**: Disable WiFi/Cellular data (Airplane Mode). Kill the app completely.
7. **Offline Re-connect**: Relaunch the app. Re-enable WiFi. Ensure the Hive analytics queue automatically flushes.
8. **Finish & Review**: Finish the trip. Complete the Post-trip Review.
9. **Web Regeneration**: Open Web. Generate a trip to the *exact same* destination. Confirm that the exact visited POIs are excluded (or heavily penalized) and the skipped category is reduced.
10. **Reset Verification**: Reset the personalization profile via Web settings. Generate one final trip to the exact same destination. Confirm the recommendations revert back to the exact initial baseline (Day 1).

## Expected Outcomes
- **Idempotency**: Repeated button presses (e.g. mashing "Save") should only emit a single event per interaction sequence.
- **Offline Reliability**: Events created in Airplane mode must arrive at the backend sequentially upon reconnection.
- **Cross-Platform State**: Actions on Mobile must instantly alter generation intelligence on Web, and vice versa, anchored to the Firebase UID.
- **Unsave/Dismiss**: Unsaving a place must *cancel* the previous positive save signal, not aggressively penalize the broader category.
- **Current Intent Win**: Explicitly demanding "Food" in the form parameters must overpower long-term architecture preferences, proving the `x3` intent multiplier.
