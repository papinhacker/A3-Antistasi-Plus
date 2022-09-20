params [
	"_unit",
	"_part",
	"_damage",
	"_injurer"
];

if (_part != "") exitWith {};
if (_damage <= 0.1) exitWith {};

private _unitSide = side _unit;
private _injurerSide = side _injurer;

if (_unitSide == _injurerSide) exitWith {};

/* ------------- if unit is not part of marker current garrison ------------- */

private _marker = _unit getVariable ["markerX", ""];

if (_marker == "") exitWith {};

if (sidesX getVariable [_marker, sideUnknown] != _unitSide) exitWith {};

/* ---------- Limit last attack task updates to once per 30 seconds --------- */

private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];

if (_lastAttackTime + 30 >= serverTime) exitWith {};

garrison setVariable [_marker + "_lastAttack", serverTime, true];

/* -------------------------------------------------------------------------- */

[_marker, _injurerSide, _unitSide] remoteExec ["A3A_fnc_underAttack", 2];

nil;
