// HandleDamage event handler for rebels and PvPers

#define DEADLY_DAMAGE_VALUE 1
#define OVERALL_DAMAGE_LIMIT 1
#define REVIVE_ABORT_DAMAGE_VALUE 0.25
#define SAFE_DAMAGE_VALUE 0.9

/* ---------------------------------- main ---------------------------------- */

if (A3A_hasACEMedical) exitWith {};
if (A3A_hasPIRMedical) exitWith {};

/* --------------------------------- params --------------------------------- */

params [
	"_unit",
	"_part",
	"_damage",
	"_injurer",
	"_projectile",
	"_hitIndex",
	"_instigator",
	"_hitPoint"
];

private _makeUnconscious =
{
	params ["_unit", "_injurer"];

	_unit setVariable ["incapacitated", true, true];
	_unit setUnconscious true;

	if (vehicle _unit != _unit) then { moveOut _unit; };
	_unit allowDamage false;

	private _fromside = if (!isNull _injurer) then { side group _injurer } else { sideUnknown };
	[_unit, _fromside] spawn A3A_fnc_unconsciousPlayer;

};

/* ------------------------------- exit checks ------------------------------ */

if (_part != "") exitWith {};
if (_damage <= REVIVE_ABORT_DAMAGE_VALUE) exitWith {};

if (_unit getVariable ["helping", false]) then
{
	_unit setVariable ["cancelRevive", true];
};

if (_damage < DEADLY_DAMAGE_VALUE) exitWith {};

/* --------------------------- prevent death code --------------------------- */

switch (true) do {
	case (side _injurer == civilian):
	{
		SAFE_DAMAGE_VALUE;
	};

	private _isUnconscious = _unit getVariable ["incapacitated", false];

	case (not _isUnconscious):
	{
		_unit setVariable ["incapacitated", true];
		[_unit, _injurer] spawn _makeUnconscious;
		SAFE_DAMAGE_VALUE;
	};

	_overallDamage = (_unit getVariable ["overallDamage", 0]) + _damage - SAFE_DAMAGE_VALUE;

	case (_overallDamage <= OVERALL_DAMAGE_LIMIT):
	{
		_unit setVariable ["overallDamage", _overallDamage];
		SAFE_DAMAGE_VALUE;
	};

	default
	{
		[_unit] spawn A3A_fnc_respawn;
		0;
	};
};
