/*
	DZAI Server Initialization File
	
	Description: Handles startup process for DZAI. Does not contain any values intended for modification.
*/
private ["_startTime","_directoryAsArray","_worldname"];

if (!isServer || !isNil "DZAI_isActive") exitWith {};
DZAI_isActive = true;

_startTime = diag_tickTime;

_directoryAsArray = toArray __FILE__;
_directoryAsArray resize ((count _directoryAsArray) - 25);
DZAI_directory = toString _directoryAsArray;
if (isNil "_this") then {_this = []};
if ((count _this) > 0) then {
	//diag_log "DEBUG :: Startup parameters found!";
	if ("readoverridefile" in _this) then {DZAI_overrideEnabled = true} else {DZAI_overrideEnabled = nil};
	if ("enabledebugmarkers" in _this) then {DZAI_debugMarkersEnabled = true} else {DZAI_debugMarkersEnabled = nil};
} else {
	//diag_log "DEBUG :: Startup parameters not found!";
	DZAI_overrideEnabled = nil;
	DZAI_debugMarkersEnabled = nil;
};

//Report DZAI version to RPT log
#include "DZAI_version.hpp"
diag_log format ["[DZAI] Initializing %1 version %2 using base path %3.",DZAI_TYPE,DZAI_VERSION,DZAI_directory];

//Load DZAI main configuration file
call compile preprocessFileLineNumbers format ["%1\init\dzai_config.sqf",DZAI_directory];

//Load DZAI functions
call compile preprocessFileLineNumbers format ["%1\init\dzai_functions.sqf",DZAI_directory];

//Set side relations
if (({(side _x) == west} count allUnits) == 0) then {createCenter west};
if (({(side _x) == east} count allUnits) == 0) then {createCenter east};
east setFriend [west, 0];        
west setFriend [east, 0];

//Detect DayZ mod variant and version being used.
if (isNil "DZAI_modName") then {DZAI_modName = "Default"};
if (isNil "DZAI_modVersion") then {DZAI_modVersion = toLower (getText (configFile >> "CfgMods" >> "DayZ" >> "version"))};
if (isNil "DZAI_modAutoDetect") then {DZAI_modAutoDetect = true};

if (DZAI_modAutoDetect) then {
	private["_modVariant"];
	_modVariant = toLower (getText (configFile >> "CfgMods" >> "DayZ" >> "dir"));
	if (DZAI_debugLevel > 0) then {diag_log format ["DZAI Debug: Detected mod variant %1.",_modVariant];};
	DZAI_modName = call {
		if (_modVariant == "@dayz_epoch") exitWith {"epoch"};
		if (_modVariant in ["dayzoverwatch","@dayzoverwatch"]) exitWith {"overwatch"};
		if (_modVariant == "@dayzhuntinggrounds") exitWith {"huntinggrounds"};
		if (_modVariant == "@dayzunleashed") exitWith {"unleashed"};
		if ((_modVariant == "dayzlingor") && {(toLower (getText (configFile >> "CfgMods" >> "DayZ" >> "action"))) == "http://www.skaronator.com"}) exitWith {"lingorskaro"};
		""
	};
};

//Create reference marker to act as boundary for spawning AI air/land vehicles. These values will be later modified on a per-map basis.
if (isNil "DZAI_maxHeliPatrols") then {DZAI_maxHeliPatrols = 0};
if (isNil "DZAI_maxLandPatrols") then {DZAI_maxLandPatrols = 0};
if (isNil "DZAI_maxSeaPatrols") then {DZAI_maxSeaPatrols = 0};
if ((DZAI_maxHeliPatrols > 0) or {(DZAI_maxLandPatrols > 0)} or {(DZAI_maxSeaPatrols > 0)}) then {
	_centerPos = (getMarkerPos 'center');
	if ((_centerPos distance [0,0,0]) < 5) then {
		_centerPos = getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition");
	};
	_centerMarker = createMarker ["DZAI_centerMarker", _centerPos];
	_centerMarker setMarkerShape "ELLIPSE";
	_centerMarker setMarkerType "Empty";
	_centerMarker setMarkerBrush "Solid";
	_centerMarker setMarkerSize [7000, 7000];
	_centerMarker setMarkerAlpha 0;
};

//Load map-specific configuration file. Config files contain trigger/marker information, addition and removal of items/skins, and/or other variable customizations.
//Classname files will overwrite basic settings specified in base_classnames.sqf
_worldname = (toLower worldName);
if (_worldname in ["chernarus","utes","zargabad","fallujah","takistan","tavi","lingor","namalsk","mbg_celle2","oring","panthera2","isladuala","sara","smd_sahrani_a2","trinity","napf","caribou","cmr_ovaron","sauerland","fdf_isle1_a","caribou"]) then {
	if (DZAI_modAutoDetect) then {
		if (DZAI_modName in ["epoch","unleashed","overwatch","huntinggrounds"]) then {
			call compile preprocessFileLineNumbers format ["%1\init\world_classname_configs\dayz_%2.sqf",DZAI_directory,DZAI_modName];
		} else {
			call compile preprocessFileLineNumbers format ["%1\init\world_classname_configs\default_classnames\%2.sqf",DZAI_directory,_worldname];
		};
	};
	[] execVM format ["%1\init\world_spawn_configs\world_%2.sqf",DZAI_directory,_worldname];
} else {
	if (DZAI_modAutoDetect) then {
		if (DZAI_modName == "epoch") then {
			call compile preprocessFileLineNumbers format ["%1\init\world_classname_configs\dayz_epoch_classnames.sqf",DZAI_directory];
		};
	};
	if (DZAI_staticAI) then {[] execVM format ["%1\scripts\setup_autoStaticSpawns.sqf",DZAI_directory];};
};

//Continue loading required DZAI script files
[] execVM format ['%1\scripts\DZAI_startup.sqf',DZAI_directory];

//Report DZAI startup settings to RPT log
diag_log format ["[DZAI] DZAI settings: Debug Level: %1. DebugMarkers: %2. WorldName: %3. ModName: %4 (Ver: %5). DZAI_dynamicWeaponList: %6. VerifyTables: %7.",DZAI_debugLevel,((!isNil "DZAI_debugMarkersEnabled") && {DZAI_debugMarkersEnabled}),_worldname,DZAI_modName,DZAI_modVersion,DZAI_dynamicWeaponList,DZAI_verifyTables];
diag_log format ["[DZAI] AI spawn settings: Static: %1. Dynamic: %2. Air: %3. Land: %4.",DZAI_staticAI,DZAI_dynAISpawns,(DZAI_maxHeliPatrols>0),(DZAI_maxLandPatrols>0)];
diag_log format ["[DZAI] AI settings: DZAI_findKiller: %1. DZAI_useHealthSystem: %2. DZAI_weaponNoise: %3. DZAI_zombieEnemy: %4.",DZAI_findKiller,DZAI_useHealthSystem,DZAI_weaponNoise,DZAI_zombieEnemy];
diag_log format ["[DZAI] DZAI loading completed in %1 seconds.",(diag_tickTime - _startTime)];
