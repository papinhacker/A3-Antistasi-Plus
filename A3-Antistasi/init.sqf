#include "Includes\common.inc"
FIX_LINE_NUMBERS()
Info("Init Started");
//Arma 3 - Antistasi by Barbolani & The Official AntiStasi Community
//Do whatever you want with this code, but credit me for the thousand hours spent making this.
private _fileName = "init.sqf";
scriptName "init.sqf";

if (isNil "logLevel") then {logLevel = 2};
Info("Init SQF started");

//Singleplayer is no longer supported
if (!isMultiplayer) then {
	["noSinglplayer",false,1,false,false] call BIS_fnc_endMission;
};

enableSaving [false,false];
if !(toLower worldName == "cam_lao_nam") then {
	mapX setObjectTexture [0, "Pictures\Mission\whiteboard.jpg"];
};

tf_radio_channel_name = "TaskForceRadio#1";
tf_radio_channel_password = "2018";

Info("Init Finished");
