// HandleDamage event handler for rebels and PvPers

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

// Let ACE medical handle the rest (inc return value) if it's running
if (A3A_hasACEMedical) exitWith {};
if (!isNil "A3A_hasPIRMedical" && { A3A_hasPIRMedical }) exitWith {};

// -----------------------------------------------------------------------------

private _makeUnconscious =
{
	params ["_unit", "_injurer"];
	_unit setVariable ["incapacitated",true,true];
	_unit setUnconscious true;
	if (vehicle _unit != _unit) then
	{
		moveOut _unit;
	};
	if (isPlayer _unit) then {_unit allowDamage false};
	private _fromside = if (!isNull _injurer) then {side group _injurer} else {sideUnknown};
	[_unit,_fromside] spawn A3A_fnc_unconscious;
};

if (_part == "") then
{
	if (_damage >= 1) then
	{
		if (side _injurer == civilian) then
		{
			// apparently civilians are non-lethal
			_damage = 0.9;
		}
		else
		{
			if !(_unit getVariable ["incapacitated",false]) then
			{
				_damage = 0.9;
				[_unit, _injurer] call _makeUnconscious;
			}
			else
			{
				// already unconscious, check whether we're pushed into death
				_overall = (_unit getVariable ["overallDamage",0]) + (_damage - 1);
				if (_overall > 1) then
				{
					if (isPlayer _unit) then
					{
						_damage = 0;
						[_unit] spawn A3A_fnc_respawn;
					}
					else
					{
						_unit removeAllEventHandlers "HandleDamage";
					};
				}
				else
				{
					_unit setVariable ["overallDamage",_overall];
					_damage = 0.9;
				};
			};
		};
	}
	else
	{
		if (_damage > 0.25) then
		{
			if (_unit getVariable ["helping",false]) then
			{
				_unit setVariable ["cancelRevive",true];
			};
			if (isPlayer (leader group _unit)) then
			{
				if (autoHeal) then
				{
					_helped = _unit getVariable ["helped",objNull];
					if (isNull _helped) then {[_unit] call A3A_fnc_askHelp;};
				};
			};
		};
	};
}
else
{
	if (_damage >= 1) then
	{
		if !(_part in ["arms","hands","legs"]) then
		{
			_damage = 0.9;
			if (_part in ["head","body"]) then
			{
				if !(_unit getVariable ["incapacitated",false]) then
				{
					[_unit, _injurer] call _makeUnconscious;
				};
			};
		};
	};
};

_damage
