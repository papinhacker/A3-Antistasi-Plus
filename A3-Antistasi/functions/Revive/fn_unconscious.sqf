#define KEY_R 19
#define BLEEDING_REMAIN_VALUE 300
#define BLEEDOUT_TIME 450
#define ALLOW_DAMAGE_PAUSE_TIME 5
#define IDD_MISSION 46

/* --------------------------------- params --------------------------------- */

params ["_unit", "_injurer"];

private _bleedOut = time + BLEEDOUT_TIME;
private _isPlayer = false;
private _playersX = false;
private _inPlayerGroup = false;

/* -------------------------- включаем кровотечение ------------------------- */

_unit setBleedingRemaining BLEEDING_REMAIN_VALUE;

/* -------------------------------------------------------------------------- */

private [
	"_saveVolume",
	"_helpX",
	"_helped",
	"_textX"
];

if (isPlayer _unit) then
{
	_isPlayer = true;

	/* ------------ пауза возвращаем возможность получить повреждение ----------- */

	_unit spawn
	{
		sleep ALLOW_DAMAGE_PAUSE_TIME;
		_this allowDamage true;
	};

	/* ------------------------- закрываем любой диалог ------------------------- */

	closeDialog 0;

	/* ----------------- добавляем обработчик по нажатию кнопки ----------------- */

	if (not isNil "respawnMenu") then
	{
		(findDisplay IDD_MISSION) displayRemoveEventHandler ["KeyDown", respawnMenu];
	};

	respawnMenu = (findDisplay IDD_MISSION) displayAddEventHandler
	[
		"KeyDown",
		{
			if (_this select 1 != KEY_R) exitWith { false; };

			(findDisplay IDD_MISSION) displayRemoveEventHandler ["KeyDown", _thisEventHandler];

			private _isPlayerActive = not (player getVariable ["incapacitated", false]);

			if (_isPlayerActive) exitWith { false; };

			[player] spawn A3A_fnc_respawn;

			false;
		}
	];

	/* --------------------------- отключаем добивание -------------------------- */

	if (_injurer != Invaders) then
	{
		[_unit, true] remoteExec ["setCaptive", 0, _unit];
		_unit setCaptive true
	};

	openMap false;

	{
		if
		(
			not isPlayer _x
			&& { vehicle _x != _x
			&& { _x distance _unit < 50 }}
		)
		then
		{
			unassignVehicle _x;
			[_x] orderGetIn false;
		}
	} forEach units group _unit;
}
else
{
	if ({isPlayer _x} count units  group _unit > 0) then
	{
		_inPlayerGroup = true;
	};

	_unit stop true;

	if (_inPlayerGroup) then
	{
		[_unit, "heal1"] remoteExec ["A3A_fnc_flagaction", 0, _unit];

		if (_injurer != Invaders) then
		{
			[_unit, true] remoteExec ["setCaptive", 0, _unit];
			_unit setCaptive true
		};
	}
	else
	{
		if
		(
			{if ((isPlayer _x) and (_x distance _unit < distanceSPWN2)) exitWith {1}} count allUnits != 0
		)
		then
		{
			_playersX = true;
			[_unit, "heal"] remoteExec ["A3A_fnc_flagaction", 0, _unit];

			if (_unit != petros) then
			{
				if (_injurer != Invaders) then
				{
					[_unit, true] remoteExec ["setCaptive", 0, _unit];
					_unit setCaptive true;
				}
			};
		};
	};
};

_unit setFatigue 1;
sleep 2;

if (_isPlayer) then
{
	group _unit setCombatMode "YELLOW";
	[_unit,"heal1"] remoteExec ["A3A_fnc_flagaction",0,_unit];

	if (isDiscordRichPresenceActive) then {
		private _possibleMarkers = outposts + airportsX + resourcesX + factories + seaports + milbases + ["NATO_carrier", "CSAT_carrier"];
		private _nearestMarker = [_possibleMarkers, player] call BIS_fnc_nearestPosition;
		private _locationName = [_nearestMarker] call A3A_fnc_localizar;

		if(player distance2D (getMarkerPos _nearestMarker) < 300) then {
			[["UpdateState", format ["Lays unconscious at the %1", _locationName]]] call SCRT_fnc_misc_updateRichPresence;
		} else {
			[["UpdateState", "Lays unconscious in the middle of nowhere"]] call SCRT_fnc_misc_updateRichPresence;
		};
	};
};


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

if (_isPlayer) then
{
	(findDisplay IDD_MISSION) displayRemoveEventHandler ["KeyDown", respawnMenu];

	if (isMultiplayer) then
	{
		[_unit, "remove"] remoteExec ["A3A_fnc_flagaction", 0, _unit];
	};
}
else
{
	_unit stop false;

	if (_inPlayerGroup or _playersX) then
	{
		[_unit, "remove"] remoteExec ["A3A_fnc_flagaction",0,_unit];
	};
};

if (captive _unit) then
{
	[_unit, false] remoteExec ["setCaptive", 0, _unit];
	_unit setCaptive false;
};

_unit setVariable ["overallDamage", damage _unit];

if (_isPlayer and (_unit getVariable ["respawn", false])) exitWith {};

if (time > _bleedOut) exitWith {
	if (_isPlayer) then
	{
		[_unit] call A3A_fnc_respawn
	}
	else
	{
		_unit setDamage 1;
	};
};

if (alive _unit) then
{
	_unit setUnconscious false;
	_unit setBleedingRemaining 0;
	_unit switchMove "unconsciousoutprone";

	if (isPlayer _unit) then
	{
		[] call SCRT_fnc_misc_updateRichPresence;
	};
};
