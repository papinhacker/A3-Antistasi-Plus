//Attempt to figure out our current ace medical target;
if !A3A_hasACE exitWith {};

currentAceTarget = objNull;

[
	"ace_interactMenuOpened",
	{ currentAceTarget = ace_interact_menu_selectedTarget; }
] call CBA_fnc_addEventHandler;

[
	"ace_medicalMenuOpened",
	{ currentAceTarget = param [1]; }
] call CBA_fnc_addEventHandler;