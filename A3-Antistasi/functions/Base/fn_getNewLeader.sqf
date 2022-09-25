/*

	Example: _newLeader = [_unit] call A3A_fnc_getNewLeader;
*/


params ["_unit"];

private _group = group _unit;

if (_unit != leader _group) exitWith {};

private _units = units _group;
_units deleteAt (_units find _unit);
private _candidateID = _units findIf { [_x] call A3A_fnc_canFight; };

if (_candidateID == -1) exitWith {};

private _newLeader = _units select _candidateID;

_group selectLeader _newLeader;

_newLeader;
