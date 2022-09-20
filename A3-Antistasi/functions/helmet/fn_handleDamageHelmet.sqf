params [
	"_unit",
	"_",
	"_damage",
	"_",
	"_",
	"_",
	"_",
	"_hitPoint"
];

if (headgear _unit == "") exitWith {};
if (_damage < 1) exitWith {};
if (_hitPoint != "hithead") exitWith {};
if (random 100 >= helmetLossChance) exitWith {};

removeHeadgear _unit;

nil;
