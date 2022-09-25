#define NEAREST_MARKER_DISTANCE_LIMIT 300
#define STATUS_TEXT "UpdateState"
#define NEAR_MARKER_TEXT "Lays unconscious at the %1"
#define AWAY_MARKER_TEXT "Lays unconscious in the middle of nowhere"

private _possibleMarkers = outposts + airportsX + resourcesX + factories + seaports + milbases + ["NATO_carrier", "CSAT_carrier"];
private _nearestMarker = [_possibleMarkers, player] call BIS_fnc_nearestPosition;
private _locationName = [_nearestMarker] call A3A_fnc_localizar;

if (player distance2D (getMarkerPos _nearestMarker) < NEAREST_MARKER_DISTANCE_LIMIT) then
{
	[[STATUS_TEXT, format [NEAR_MARKER_TEXT, _locationName]]]
		call SCRT_fnc_misc_updateRichPresence;
}
else
{
	[[STATUS_TEXT, AWAY_MARKER_TEXT]]
		call SCRT_fnc_misc_updateRichPresence;
};
