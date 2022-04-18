// HandleDamage event handler for rebels and PvPers

#define CRITICAL_DAMAGE 0.9
#define UNSUFFICITED_DAMAGE 0.1
#define STOP_HELPING_DAMAGE 0.25
#define FULL_DAMAGE 1.0
#define GET_TO_COVER_DAMAGE 0.6

params ["_unit", "_part", "_damage", "_injurer", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

// Functionality unrelated to Antistasi revive
// Helmet popping: use _hitpoint rather than _part to work around ACE calling its fake hitpoint "head"
if (isNil "A3A_hasPIRMedical" || { !A3A_hasPIRMedical })
then
{
	if (_damage < 1) exitWith {};
	if (_hitPoint != "hithead") exitWith {};
	if (random 100 >= helmetLossChance) exitWith {};

	removeHeadgear _unit;
};

if (_part == "" && { _damage > UNSUFFICITED_DAMAGE }) then
{
	// Contact report generation for rebels
	if (side (group _injurer) == Occupants || { side (group _injurer) == Invaders })
	then
	{
		// Check if unit is part of a rebel garrison
		private _marker = _unit getVariable ["markerX", ""];

		if (_marker == "") exitWith {};
		if (sidesX getVariable [_marker, sideUnknown] != teamPlayer) exitWith {};

		// Limit last attack var changes and task updates to once per 30 seconds
		private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];

		if (_lastAttackTime + 30 >= serverTime) exitWith {};

		garrison setVariable [_marker + "_lastAttack", serverTime, true];

		[_marker, side (group _injurer), side (group _unit)] remoteExec
			["A3A_fnc_underAttack", 2];
	};

	// this will not work the same with ACE, as damage isn't accumulated

	if (!isNil "A3A_hasLAMBS" && { A3A_hasLAMBS }) exitWith {};
	if (isPlayer (leader (group _unit))) exitWith {};
	if (_damage >= FULL_DAMAGE) exitWith {};
	if (_damage <= GET_TO_COVER_DAMAGE) exitWith {};

	[_unit, _injurer] spawn A3A_fnc_unitGetToCover;
};

// Let ACE medical handle the rest (inc return value) if it's running
if (A3A_hasACEMedical) exitWith {};
if (!isNil "A3A_hasPIRMedical" && { A3A_hasPIRMedical }) exitWith {};

// ----------------------------- makeUnconscious -------------------------------

private _makeUnconscious =
{
	params ["_unit", "_injurer"];

	_unit setVariable ["incapacitated", true, true];
	_unit setUnconscious true;

	if (vehicle _unit != _unit) then { moveOut _unit; };
	if (isPlayer _unit) then { _unit allowDamage false; };

	private _fromside = if (!isNull _injurer)
	then { side group _injurer } else { sideUnknown };

	[_unit, _fromside] spawn A3A_fnc_unconscious;
};

switch (true)
do
{
	// -------------------------------- hitpoint -----------------------------------
	case (_part != ""):
	{
		if (_damage <= CRITICAL_DAMAGE) exitWith {};
		if (_part in ["arms", "hands", "legs"]) exitWith {};

		_damage = CRITICAL_DAMAGE;

		if (_unit getVariable ["incapacitated", false]) exitWith {};

		[_unit, _injurer] call _makeUnconscious;
	};

	// ------------------------ not death overall damage ---------------------------
	case (_damage < 1):
	{
		if (_damage <= STOP_HELPING_DAMAGE) exitWith {};

		if (_unit getVariable ["helping", false]) then
		{
			_unit setVariable ["cancelRevive", true];
		};

		if !(isPlayer (leader group _unit)) exitWith {};
		if !(autoHeal) exitWith {};

		_helped = _unit getVariable ["helped", objNull];

		if !(isNull _helped) exitWith {};

		[_unit] call A3A_fnc_askHelp;
	};

	// -------------------------------- civilian -----------------------------------
	case (side _injurer == civilian):
	{
		_damage = CRITICAL_DAMAGE;
	};

	// ---------------------------- not incapacitated ------------------------------
	case !(_unit getVariable ["incapacitated", false]):
	{
		_damage = CRITICAL_DAMAGE;
		[_unit, _injurer] call _makeUnconscious;
	};

	// ------------------------------ incapacitated --------------------------------
	_overall = (_unit getVariable ["overallDamage", 0]) + (_damage - 1);

	case (_overall <= 1):
	{
		_unit setVariable ["overallDamage", _overall];
		_damage = CRITICAL_DAMAGE;
	};

	// ----------------------------- respawn player --------------------------------
	case (isPlayer _unit):
	{
		_damage = 0;
		[_unit] spawn A3A_fnc_respawn;
	};

	// -------------------------------- kill unit ----------------------------------
	default
	{
		_unit removeAllEventHandlers "HandleDamage";
	};
};

_damage
