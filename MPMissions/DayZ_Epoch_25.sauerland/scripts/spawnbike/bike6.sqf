private ["_targetBike"];
if (dayz_combat == 1) then { 
    cutText [format["You are in Combat and cannot Re-Pack your Mozzie"], "PLAIN DOWN"];
} else {
	player removeAction s_player_deploybike6;
	player playActionNow "Medic";
	r_interrupt = false;
	_targetBike = nearestObjects [player, ["CSJ_GyroC"], 5];
   deleteVehicle (_targetBike select 0);
	_dis=10;
	_sfx = "repair";
	[player,_sfx,0,false,_dis] call dayz_zombieSpeak;
	[player,_dis,true,(getPos player)] spawn player_alertZombies;
	
	sleep 6;
	
	_pos = getposASL player;
	_object = "WeaponHolder" createVehicle getpos player; _object addMagazinecargo ["PartGeneric", 1]; _object addMagazinecargo ["PartVRotor", 1];_object addMagazinecargo ["PartGeneric", 1]; _object addMagazinecargo ["PartEngine", 1];
	_object setPosASL _pos;
	player addWeapon "ItemToolbox";

	cutText [format["You have packed your Mozzie. Your parts have been dropped on the ground."], "PLAIN DOWN"];
	
	r_interrupt = false;
	player switchMove "";
	player playActionNow "stop";	
};