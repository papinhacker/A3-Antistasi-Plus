/*
Author: Spoffy, jaj22, Håkon
Description:
    Heals rebel units near HQ, restores there stamina,
    and allows units and vehicles to go undercover again.
    Ace compatible.

Arguments: <Nil>

Return Value: <Nil>

Scope: Any
Environment: Any
Public: Yes
Dependencies:
    <Object> boxX - Vehicle box at hq init to variable in init field in sqm
    <Marker> respawnTeamPlayer - HQ marker

Example:

License: MIT License
*/

PIRUnitFullHeal =
{
    params ["_unit"];

    _unit setVariable ["dam_player_krovstoit0", true, true];
    _unit setVariable ["dam_uncondition_injured0", true, true];
    _unit setVariable ["dam_conec_istorii0", true, true];
    _unit setDamage 0;

    if (lifeState _unit == "INCAPACITATED")
    then
    {
        _unit setUnconscious false;
        [_unit,"UnconsciousOutProne"] remoteExecCall ["switchMove", 0];
    };

    [
        {
            params ["_unit"];
            _unit setVariable ["dam_ignore_CountTimeEffect0", 0, true];
            _unit setVariable ["dam_ignore_HealEffect0", 24, true];
        },
        [_unit],
        2
    ] call CBA_fnc_waitAndExecute;

    _unit setVariable ["dam_ignore_CountPlayerList0", [], true];
    _unit setVariable ["dam_ignore_CountPlayerEffect0", 0, true];
    _unit setVariable ["dam_ignore_Apteka0", 0, true];

    [
        {
            params ["_unit"];
            _unit setVariable ["dam_player_lecit0", false, true];
        },
        [_unit],
        2
    ] call CBA_fnc_waitAndExecute;
};

if (serverTime - (boxX getVariable ["lastUsed", -30]) < 30)
exitWith
{
    if (hasInterface)
    then
    {
        [
            localize "STR_antistasi_singleWord_Heal",
            localize "STR_antistasi_Base_vehicleBoxHeal_UsedRecently"
        ] call A3A_fnc_customHint;
    };
};

boxX setVariable ["lastUsed", serverTime, true];

//Heal, restore stamina, and clear report for rebel units near HQ
private _posHQ = getMarkerPos respawnTeamPlayer;

{
    if ((side (group _x) == teamPlayer) && { _x distance _posHQ < 50 })
    then
    {
        if (!isNil "ace_advanced_fatigue_fnc_handlePlayerChanged")
        then
        {
            // abuse the init/respawn function to reset ACE stamina
            [_x, objNull] remoteExec
                ["ace_advanced_fatigue_fnc_handlePlayerChanged", _x];
        }
        else
        {
            [_x, 0] remoteExec ["setFatigue", _x];
        };

        switch (true) do
        {
            case (A3A_hasACEMedical):
            {
                [_x, _x] call ace_medical_treatment_fnc_fullHeal;
            };
            case (A3A_hasPIRMedical):
            {
                [_x] RemoteExecCall ["PIRUnitFullHeal", _x];
                _x setVariable ["incapacitated", false, true];
                _x setVariable ["compromised", 0, true];
            };
            default
            {
                _x setDamage 0;
                _x setVariable ["incapacitated", false, true];
                _x setVariable ["compromised", 0, true];
            };
        };

    };
} forEach allUnits;

//clear report from vehicles that are alive, at HQ, and reported
private _reportCleared = false;
{
    if
    (
        alive _x
        && { _x distance _posHQ < 150
        && { _x in reportedVehs }}
    )
    then
    {
        reportedVehs deleteAt (reportedVehs find _x);
        _reportCleared = true;
    };
} forEach vehicles;

//spare publicVariable for every vehicle at hq
if (_reportCleared) then { publicVariable "reportedVehs"; };

[
    localize "STR_antistasi_singleWord_Heal",
    localize "STR_antistasi_Base_vehicleBoxHeal_Healed"
] call A3A_fnc_customHint;

nil
