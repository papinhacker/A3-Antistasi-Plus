/*
 * The reason for this split, is we can't open dialog boxes during initServer in singleplayer.
 * This is an issue if we want to get params data before initialising the server.

 * So if it's singleplayer, we wait for initServer.sqf to finish (and the player to be spawned in), then get params, then load.
 */
if (isNil "logLevel") then {LogLevel = 2};

// removing post-apocalyptic stuff
private _forbiddenTerrainObjects = [ 
    "Land_TTowerBig_2_F",
    "Land_Communication_F",
    "Land_Vysilac_FM",
    "Land_A_TVTower_base",
    "Land_Telek1",
    "Land_vn_tower_signal_01"
]; 
 
private _allTerrainObjects = (nearestTerrainObjects [[worldSize/2, worldSize/2], ["HIDE"], worldSize,false]) select {
    private _terrainObjectName = toLower(str _x);
    (_forbiddenTerrainObjects findIf {_x in _terrainObjectName} != -1) && {(isOnRoad _x || "dead" in _terrainObjectName || "tram" in _terrainObjectName)}
}; 

{
    hideObjectGlobal _x; 
    _x enableSimulationGlobal false;
} forEach _allTerrainObjects;

[] call A3A_fnc_initServer;