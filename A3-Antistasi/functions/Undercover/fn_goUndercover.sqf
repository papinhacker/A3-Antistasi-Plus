/*
Maintainer: Wurzel0701
    Activates undercover if possible and controls its status till undercover is broken/ended

Arguments:
    <NIL>

Return Value:
    <NIL>

Scope: Local
Environment: Scheduled
Public: Yes
Dependencies:
    <OBJECT> A3A_faction_civ
    <ARRAY> reportedVehs
    <ARRAY> controlsX
    <ARRAY> airportsX
    <ARRAY> milbases
    <ARRAY> outposts
    <ARRAY> seaports
    <ARRAY> undercoverVehicles
    <BOOL> A3A_hasACE
    <SIDE> Occupants
    <STRING> civHeli
    <ARRAY> civBoats
    <SIDE> Invaders
    <ARRAY> detectionAreas
    <NAMESPACE> sidesX
    <SIDE> teamPlayer
    <NUMBER> aggressionOccupants
    <NUMBER> aggressionInvaders
    <NUMBER> tierWar

Example:
    [] call A3A_fnc_goUndercover;
*/

#define MAGIC_NUMBER 1.4
#define FACE_DISTANCE 350

// -----------------------------------------------------------------------------

#define STR_TITLE "Undercover"
#define STR_SPOTTED "You have been reported or spotted by the enemy!"
#define STR_GARRISON "The Installation Garrison has recognised you!"
#define STR_BLOCKPOST_PASS "The blockpost guards has not recognised you!"
#define STR_BLOCKPOST_FAIL "The blockpost guards has recognised you!!!"
#define STR_HEALING_FACE "You cannot stay Undercover while healing a compromised resistance member<br/><br/>The enemy added you to their Wanted List!"
#define STR_HEALING "You cannot stay Undercover while healing a compromised resistance member!"
#define STR_WEAPON_FACE "You cannot stay Undercover while showing:<br/><br/>A weapon is visible<br/>Wearing a vest<br/>Wearing a helmet<br/>Wearing NVGs<br/>Wearing a mil uniform<br/><br/>The enemy added you to their Wanted List!"
#define STR_WEAPON "You cannot stay Undercover while:<br/><br/>A weapon is visible<br/>Wearing a vest<br/>Wearing a helmet<br/>Wearing NVGs<br/>Wearing a mil uniform!"
#define STR_WANTED_LIST "You are on the Wanted List!"
#define STR_NOT_CIV_VEH "You entered a non civilian vehicle!"
#define STR_REPORTED_VEH "You entered a reported vehicle!"
#define STR_EXPLOSIVES "Explosives have been spotted on your vehicle!"
#define STR_AIRSPACE "You have violated the airspace of %1!"
#define STR_ROADS "You went too far away from any roads and have been spotted!"
#define STR_AREA "You cannot stay Undercover inside military area"

// ---------------------------------- Start ------------------------------------

private _fileName = "fn_goUndercover";

private _result = [] call A3A_fnc_canGoUndercover;

if !(_result #0)
exitWith
{
    if
    (
        _result #1 == "Spotted by enemies"
        && { !(isNull (objectParent player)) }
    )
    then
    {
        reportedVehs pushBackUnique (objectParent player);
        publicVariable "reportedVehs";

        {
            if (isPlayer _x && { captive _x })
            then
            {
                [_x, false] remoteExec ["setCaptive"];
                _x setCaptive false;
            };
        }
        forEach
        (
            (crew (objectParent player))
            + (assignedCargo (objectParent player)) - [player]
        );
    };
};

// ------------------------------ Undercover ON --------------------------------

["Undercover ON", 0, 0, 4, 0, 0, 4] spawn bis_fnc_dynamicText;

[player, true] remoteExec ["setCaptive", 0, player];
player setCaptive true;
[] spawn A3A_fnc_statistics;

if (player == leader (group player))
then
{
    {
        if
        (
            !(isplayer _x)
            && { local _x
            && { _x getVariable ["owner", _x] == player }}
        )
        then
        {
            [_x] spawn A3A_fnc_undercoverAI;
        };
    } forEach (units group player);
};

// ------------------------------- Check cycle ---------------------------------

private _roadblocks = controlsX select { isOnRoad (getMarkerPos _x) };
private _secureAreas = airportsX + outposts + seaports + milbases + _roadblocks;

private _isOpenRoadBlock = false;

private
[
    "_veh",
    "_vehType",
    "_secureArea",
    "_isOnDetectionArea",
    "_isOnSecureArea",
    "_areaSide",
    "_aggro"
];

while { alive player } do
{
    sleep 1;

    _veh = objectParent player;

    if (isNull _veh)
    then  // player on foot
    {
        switch (true) do
        {
            // ------------------------- undercover in fact off ----------------------------

            case !(captive player):
            {
                [STR_TITLE, STR_SPOTTED] call A3A_fnc_customHint;

                player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                break;
            };

            // ---------------------------- isOnDetectionArea ------------------------------

            _isOnDetectionArea = detectionAreas findIf { player inArea _x } != -1;

            case (_isOnDetectionArea):
            {
                [STR_TITLE, STR_GARRISON] call A3A_fnc_customHint;

                player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                break;
            };

            // ------------------------------- secureArea ----------------------------------

            _secureArea = [_secureAreas, player] call BIS_fnc_nearestPosition;
            _areaSide = sidesX getVariable [_secureArea, sideUnknown];

            case
            (
                _areaSide != teamPlayer
                && { player inArea _secureArea }
            ):
            {
                if (_secureArea in _roadblocks) then
                {
                    if (_isOpenRoadBlock) then { continue; };

                    _aggro = if (_areaSide == Occupants)
                    then { aggressionOccupants + tierWar * 10 }
                    else { aggressionInvaders + tierWar * 10 };

                    if (random 100 >= _aggro) then
                    {
                        [STR_TITLE, STR_BLOCKPOST_PASS] call A3A_fnc_customHint;

                        _isOpenRoadBlock = true;
                        continue;
                    };

                    [STR_TITLE, STR_BLOCKPOST_FAIL] call A3A_fnc_customHint;
                }
                else
                {
                    [STR_TITLE, STR_GARRISON] call A3A_fnc_customHint;
                };

                player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                break;
            };

            // ---------------------- enemy see you heal resistance ------------------------

            case
            (
                !(isNil { player getVariable "ace_medical_treatment_endInAnim"})
                && { side currentAceTarget != civilian
                && { currentAceTarget isKindOf "Man" }}
            ):
            {
                if
                (
                    allUnits findIf
                    {
                        (side _x == Invaders
                        || { side _x == Occupants })
                        && { _x knowsAbout player > MAGIC_NUMBER
                        && { _x distance player < FACE_DISTANCE }}
                    } != -1
                )
                then
                {
                    [STR_TITLE, STR_HEALING_FACE] call A3A_fnc_customHint;
                    player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                    break;
                }
                else
                {
                    if
                    (
                        allUnits findIf
                        {
                            (side _x == Invaders
                            || { side _x == Occupants })
                            && { _x knowsAbout player > MAGIC_NUMBER }
                        } != -1
                    )
                    then
                    {
                        [STR_TITLE, STR_HEALING] call A3A_fnc_customHint;

                        break;
                    };
                };
            };

            // --------------------------- military ammunition -----------------------------

            case
            (
                primaryWeapon player != ""
                || { secondaryWeapon player != ""
                || { handgunWeapon player != ""
                || { vest player != ""
                || { getNumber (configfile >> "CfgWeapons" >> headgear player >> "ItemInfo" >> "HitpointsProtectionInfo" >> "Head" >> "armor") > 2
                || { hmd player != ""
                || { !(uniform player in (A3A_faction_civ getVariable "uniforms")) }}}}}}
            ):
            {
                if
                (
                    allUnits findIf
                    {
                        (side _x == Invaders
                        || { side _x == Occupants })
                        && { _x knowsAbout player > MAGIC_NUMBER
                        && { _x distance player < FACE_DISTANCE }}
                    } != -1
                )
                then
                {
                    [STR_TITLE, STR_WEAPON_FACE] call A3A_fnc_customHint;

                    player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                    break;
                }
                else
                {
                    [STR_TITLE, STR_WEAPON] call A3A_fnc_customHint;

                    break;
                };
            };

            // -------------------------- they are finding you -----------------------------

            case (dateToNumber date < player getVariable ["compromised", 0]):
            {
                [STR_TITLE, STR_WANTED_LIST] call A3A_fnc_customHint;

                player setVariable ["compromised", dateToNumber [date #0, date #1, date #2, date #3, (date #4) + 30]];

                break;
            };
        };
    }
    else // player in vehicle
    {
        switch (true) do
        {
            // ------------------- you in fact allready not undercover ---------------------

            case !(captive player):
            {
                [STR_TITLE, STR_SPOTTED] call A3A_fnc_customHint;

                reportedVehs pushBackUnique _veh;
                publicVariable "reportedVehs";

                break;
            };

            // ------------------------------- bad vehicle ---------------------------------

            _vehType = typeOf _veh;

            case !(_vehType in undercoverVehicles):
            {
                [STR_TITLE, STR_NOT_CIV_VEH] call A3A_fnc_customHint;

                break;
            };

            // --------------------------- compromised vehicle -----------------------------

            case (_veh in reportedVehs):
            {
                [STR_TITLE, STR_REPORTED_VEH] call A3A_fnc_customHint;

                break;
            };

            // ----------------------------- bomb on vehicle -------------------------------

            case
            (
                A3A_hasACE
                && { ((position player nearObjects ["DemoCharge_Remote_Ammo", 5]) #0) mineDetectedBy Occupants
                || { ((position player nearObjects ["SatchelCharge_Remote_Ammo", 5]) #0) mineDetectedBy Occupants
                || { ((position player nearObjects ["DemoCharge_Remote_Ammo", 5]) #0) mineDetectedBy Invaders
                || { ((position player nearObjects ["SatchelCharge_Remote_Ammo", 5]) #0) mineDetectedBy Invaders }}}}
            ):
            {
                [STR_TITLE, STR_EXPLOSIVES] call A3A_fnc_customHint;

                reportedVehs pushBackUnique (objectParent player);
                publicVariable "reportedVehs";

                break;
            };

            // --------------------------------- no fly ------------------------------------

            private _detectedBy = _veh getVariable ["NoFlyZoneDetected", ""];

            case (_detectedBy != ""):
            {
                [
                    STR_TITLE,
                    format [STR_AIRSPACE, [_detectedBy] call A3A_fnc_localizar]
                ] call A3A_fnc_customHint;

                reportedVehs pushBackUnique _veh;
                publicVariable "reportedVehs";
                _veh setVariable ["NoFlyZoneDetected", nil, true];

                break;
            };

            // ------------------- next iteration if civ heli or boat ----------------------

            case
            (
                _vehType == civHeli
                && { _vehType in civBoats }
            ): { continue; };

            // ----------------------------- not on the road -------------------------------

            case
            (
                !(isOnRoad position _veh)
                && { count (_veh nearRoads 50) == 0 }
            ):
            {
                if
                (
                    allUnits findIf
                    {
                        (side _x == Invaders
                        || { side _x == Occupants })
                        && { _x knowsAbout player > MAGIC_NUMBER
                        && { _x distance player < FACE_DISTANCE }}
                    } != -1
                )
                then
                {
                    [STR_TITLE, STR_ROADS] call A3A_fnc_customHint;

                    reportedVehs pushBackUnique _veh;
                    publicVariable "reportedVehs";

                    break;
                }
                else
                {
                    if
                    (
                        allUnits findIf
                        {
                            (side _x == Invaders
                            || { side _x == Occupants })
                            && { _x knowsAbout player > MAGIC_NUMBER }
                        } != -1
                    )
                    then
                    {
                        [STR_TITLE, STR_ROADS] call A3A_fnc_customHint;

                        break;
                    }
                };
            };

            // ---------------------------- isOnDetectionArea ------------------------------

            _isOnDetectionArea = detectionAreas findIf { player inArea _x } != -1;

            case (_isOnDetectionArea):
            {
                reportedVehs pushBackUnique _veh;
                publicVariable "reportedVehs";

                break;
            };

            // ------------------------------- secureArea ----------------------------------

            _secureArea = [_secureAreas, player] call BIS_fnc_nearestPosition;
            _areaSide = sidesX getVariable [_secureArea, sideUnknown];

            case
            (
                _areaSide != teamPlayer
                && { player inArea _secureArea }
            ):
            {
                if (_secureArea in _roadblocks) then
                {
                    if (_isOpenRoadBlock) then { continue; };

                    _aggro = if (_areaSide == Occupants)
                    then { aggressionOccupants + tierWar * 10 }
                    else { aggressionInvaders + tierWar * 10 };

                    if (random 100 >= _aggro) then
                    {
                        [STR_TITLE, STR_BLOCKPOST_PASS] call A3A_fnc_customHint;

                        _isOpenRoadBlock = true;
                        continue;
                    };

                    [STR_TITLE, STR_BLOCKPOST_FAIL] call A3A_fnc_customHint;
                }
                else
                {
                    [STR_TITLE, STR_AREA] call A3A_fnc_customHint;
                };

                reportedVehs pushBackUnique _veh;
                publicVariable "reportedVehs";

                break;
            };

            default { _isOpenRoadBlock = false; };
        };
    };
};

// ----------------------------- Undercover OFF --------------------------------

if (captive player)
then
{
    [player, false] remoteExec ["setCaptive"];
    player setCaptive false;
};

if !(isNull _veh)
then
{
    {
        if !(isPlayer _x) then { continue; };

        [_x, false] remoteExec["setCaptive", 0, _x];
        _x setCaptive false;
    } forEach ((assignedCargo (vehicle player)) + (crew (vehicle player)) - [player]);
};

["Undercover OFF", 0, 0, 4, 0, 0, 4] spawn bis_fnc_dynamicText;

[] spawn A3A_fnc_statistics;