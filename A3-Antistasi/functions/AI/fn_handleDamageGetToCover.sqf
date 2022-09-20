params [
	"_unit",
	"_part",
	"_damage",
	"_injurer"
];

if (isPlayer _unit) exitWith {};
if (_part != "") exitWith {};
if (_damage < 0.4) exitWith {};
if (_damage > 1.0) exitWith {};

[_unit, _injurer] spawn A3A_fnc_unitGetToCover;

nil;
