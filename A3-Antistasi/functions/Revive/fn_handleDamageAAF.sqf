// HandleDamage event handler for enemy (gov/inv) AIs

#define DEADLY_DAMAGE_VALUE 1
#define OVERALL_DAMAGE_LIMIT 0.6
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

/* ------------------------------- exit checks ------------------------------ */

if (_part != "") exitWith {};
if (_damage <= REVIVE_ABORT_DAMAGE_VALUE) exitWith {};

if (_unit getVariable ["helping", false]) then
{
	_unit setVariable ["cancelRevive", true];
};

if (_damage < DEADLY_DAMAGE_VALUE) exitWith {};

/* --------------------------- prevent death code --------------------------- */

private _isUnconscious = _unit getVariable ["incapacitated", false];

switch (true) do {
	case (not _isUnconscious):
	{
		_unit setVariable ["incapacitated", true];
		[_unit, _injurer] spawn A3A_fnc_unconsciousAAF;
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
		_unit removeAllEventHandlers "HandleDamage";
		nil;
	};
};
