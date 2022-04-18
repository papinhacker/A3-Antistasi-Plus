// HandleDamage event handler for enemy (gov/inv) AIs

#define CRITICAL_DAMAGE 0.9
// #define UNSUFFICITED_DAMAGE 0.1
#define STOP_HELPING_DAMAGE 0.25
#define FULL_DAMAGE 1.0
#define GET_TO_COVER_DAMAGE 0.6

params ["_unit", "_part", "_damage", "_injurer", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

// Functionality unrelated to Antistasi revive
if (side (group _injurer) == teamPlayer)
then
{
	// Helmet popping: use _hitpoint rather than _part to work around ACE calling its fake hitpoint "head"
	if (isNil "A3A_hasPIRMedical" || { !A3A_hasPIRMedical })
	then
	{
		if (_damage < CRITICAL_DAMAGE) exitWith {};
		if (_hitPoint != "hithead") exitWith {};
		if (random 100 >= helmetLossChance) exitWith {};

		removeHeadgear _unit;
	};


	if !(A3A_hasLAMBS)
	then
	{
		private _groupX = group _unit;

		if
		(
			time > _groupX getVariable ["movedToCover", 0]
			&& { behaviour leader _groupX != "COMBAT"
			&& { behaviour leader _groupX != "STEALTH" }}
		)
		then
		{
			_groupX setVariable ["movedToCover", time + 120];

			{
				[_x, _injurer] call A3A_fnc_unitGetToCover;
			} forEach units _groupX;
		};

		if (_part != "") exitWith {};
		if (_damage >= 1) exitWith {};
		if (_damage <= GET_TO_COVER_DAMAGE) exitWith {};

		[_unit, _injurer] spawn A3A_fnc_unitGetToCover;
	};


	// Contact report generation for PvP players
	if (_part != "") exitWith {};
	if (side group _unit != Occupants) exitWith {};

	// Check if unit is part of a garrison
	private _marker = _unit getVariable ["markerX", ""];

	if (_marker == "") exitWith {};
	if (sidesX getVariable [_marker, sideUnknown] != Occupants) exitWith {};

	// Limit last attack var changes and task updates to once per 30 seconds
	private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];

	if (_lastAttackTime + 30 >= serverTime) exitWith {};

	garrison setVariable [_marker + "_lastAttack", serverTime, true];
	[_marker, teamPlayer, side group _unit] remoteExec ["A3A_fnc_underAttack", 2];
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

	//Make sure to pass group lead if unit is the leader
	if (_unit == leader (group _unit))
	then
	{
		private _index = (units (group _unit)) findIf {[_x] call A3A_fnc_canFight};

		if (_index == -1) exitWith {};

		(group _unit) selectLeader ((units (group _unit)) select _index);
	};

	[_unit, _injurer] spawn A3A_fnc_unconsciousAAF;
};

switch (true)
do
{
	// ---------------------------------- parts ------------------------------------
	case (_part != ""):
	{
		if (_damage <= CRITICAL_DAMAGE) exitWith {};
		if (_part in ["arms", "hands", "legs"]) exitWith {};

		_damage = CRITICAL_DAMAGE;

		if (_unit getVariable ["incapacitated", false]) exitWith {};

		[_unit, _injurer] call _makeUnconscious;
	};

	// --------------------------- common small damage -----------------------------
	case (_damage <= CRITICAL_DAMAGE):
	{
		if (_damage <= STOP_HELPING_DAMAGE) exitWith {};
		if !(_unit getVariable ["helping", false]) exitWith {};

		//Abort helping if hit too hard
		_unit setVariable ["cancelRevive", true];
	};

	// ---------------------------- not incapacitated ------------------------------
	case !(_unit getVariable ["incapacitated", false]):
	{
		_damage = CRITICAL_DAMAGE;
		[_unit, _injurer] call _makeUnconscious;
	};

	// ------------------------------ incapacitated --------------------------------
	private _overall = (_unit getVariable ["overallDamage", 0]) + (_damage - 1);

	case (_overall > 0.5):
	{
		_unit removeAllEventHandlers "HandleDamage";
	};

	default
	{
		_unit setVariable ["overallDamage", _overall];
		_damage = CRITICAL_DAMAGE;
	};
};

_damage
