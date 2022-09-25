#define KEY_R 19
#define BLEEDING_REMAIN_VALUE 300
#define DISEMBARK_RADIUS 50

/* ---------------------------------- texts --------------------------------- */

/* --------------------------------- params --------------------------------- */

params ["_unit", "_injurer"];

_unit setBleedingRemaining BLEEDING_REMAIN_VALUE;

/* --------------------------- delay allow damage --------------------------- */

_unit spawn
{
	sleep 5;
	_this allowDamage true;
};

/* -------------------------------------------------------------------------- */

closeDialog 0;

if (!isNil "respawnMenu") then
{
	(findDisplay 46) displayRemoveEventHandler ["KeyDown", respawnMenu];
};

respawnMenu = (findDisplay 46) displayAddEventHandler
[
	"KeyDown",
	{
		if (_this select 1 != KEY_R) exitWith { false; };
		if !(player getVariable ["incapacitated", false]) exitWith { false; };

		(findDisplay 46) displayRemoveEventHandler ["KeyDown", respawnMenu];
		[player] spawn A3A_fnc_respawn;

		false;
	}
];

/* --------------------------- invaders are devils -------------------------- */

if (_injurer != Invaders) then
{
	[_unit, true] remoteExec ["setCaptive", 0, _unit];
	_unit setCaptive true;
};

openMap false;

/* ----------------------------- disembark units ---------------------------- */

{
	if
	(
		not isPlayer _x
		&& { vehicle _x != _x
		&& { _x distance _unit < DISEMBARK_RADIUS }}
	)
	then
	{
		unassignVehicle _x;
		[_x] orderGetIn false;
	}
} forEach units group _unit;

_unit setFatigue 1;
sleep 2;

group _unit setCombatMode "YELLOW";
[_unit, "heal1"] remoteExec ["A3A_fnc_flagaction", 0, _unit];

/* --------------------------------- discord -------------------------------- */

if (isDiscordRichPresenceActive) then { [] spawn A3A_fnc_discordRichUpdate; };

/* --------------------------- injured simulation --------------------------- */

while
{
	(time < _bleedOut)
	&& (_unit getVariable ["incapacitated", false])
	&& (alive _unit)
	&& (!(_unit getVariable ["respawning", false]))
}
do
{
	if (random 10 < 1) then
	{
		playSound3D [selectRandom injuredSounds, _unit, false, getPosASL _unit, 1, 1, 50];
	};

	if (_isPlayer) then {
		_helped = _unit getVariable ["helped", objNull];

		if (isNull _helped) then
		{
			_helpX = [_unit] call A3A_fnc_askHelp;

			if (isNull _helpX) then
			{
				_textX = format ["<t size='0.6'>There is no AI near to help you.<t size='0.5'><br/>Press R to Respawn</t></t>"];
			}
			else
			{
				if (_helpX != _unit) then
				{
					_textX = format ["<t size='0.6'>%1 is on the way to help you.<t size='0.5'><br/>Press R to Respawn</t></t>",name _helpX];
				}
				else
				{
					_textX = "<t size='0.6'>Wait until you get assistance or<t size='0.5'><br/>Press R to Respawn</t></t>";
				};
			};
		}
		else
		{
			if (!isNil "_helpX") then
			{
				if (!isNull _helpX) then
				{
					_textX = format ["<t size='0.6'>%1 is on the way to help you.<t size='0.5'><br/>Press R to Respawn</t></t>", name _helpX];
				}
				else
				{
					_textX = "<t size='0.6'>Wait until you get assistance or<t size='0.5'><br/>Press R to Respawn</t></t>";
				};
			}
			else
			{
				_textX = "<t size='0.6'>Wait until you get assistance or<t size='0.5'><br/>Press R to Respawn</t></t>";
			};
		};

		[_textX, 0, 0, 3, 0, 0, 4] spawn bis_fnc_dynamicText;

		if (_unit getVariable "respawning") exitWith {};
	}
	else
	{
		if (_inPlayerGroup) then
		{
			if (autoHeal) then
			{
				_helped = _unit getVariable ["helped", objNull];

				if (isNull _helped) then
				{
					[_unit] call A3A_fnc_askHelp;
				};
			};
		}
		else
		{
			_helped = _unit getVariable ["helped", objNull];

			if (isNull _helped) then
			{
				[_unit] call A3A_fnc_askHelp;
			};
		};
	};

	sleep 3;

	if !(isNull attachedTo _unit) then
	{
		_bleedOut = _bleedOut + 4;
	};
};

(findDisplay 46) displayRemoveEventHandler ["KeyDown", respawnMenu];

if (isMultiplayer) then
{
	[_unit, "remove"] remoteExec ["A3A_fnc_flagaction", 0, _unit];
};

/* --------------------------------- captive -------------------------------- */

if (captive _unit) then
{
	[_unit, false] remoteExec ["setCaptive", 0, _unit];
	_unit setCaptive false;
};

_unit setVariable ["overallDamage", damage _unit];

if (_unit getVariable ["respawn", false]) exitWith {};

if (time > _bleedOut) exitWith { [_unit] call A3A_fnc_respawn; };
if (not alive _unit) exitWith {};

_unit setUnconscious false;
_unit setBleedingRemaining 0;
_unit switchMove "unconsciousoutprone";
