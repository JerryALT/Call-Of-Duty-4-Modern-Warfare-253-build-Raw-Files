/****************************************************************************

Level: 		Exfil (village_defend.bsp)
Campaign: 	British SAS Woodland Scheme
Objectives:	1. Defend the lower hill approach. (note: level does not progress without player participation)
			2. Man the minigun and cover your team's movement. (required to progress, friendlies don't budge otherwise)
			3. Survive until the exfiltration force arrives. (Time Remaining: ~6 minutes, freeform gameplay)
			4. Destroy the enemy attack helicopter. (Appearing/Disappearing recurring objective X 4, optional but accumulates)
			5. Board the rescue helicopter before it leaves. (secret achievement for carrying a buddy back to the helo)

Moments:

	- Ultranationalists use megaphones from helicopters to convince the player's team to surrender after 1st obj, and then...
	- Independence Day helicopter swarm dropping troops into the level all around, music
	- Enemy attack helicopter shooting buildings and breaking them where player is hiding
	- UAZ jeeps and BMPs driving in and unloading troops
	- Friendly troops emerge from back of Sea Knight and then run back on board before it leaves
	- Sea Knight lands in unpredictable location far from the player due to "it's too hot" and player has to run for it, music
	- Enemy troops heard squawking through radios before storming buildings the player is hiding inside of
	- Enemy troops flashbanging and storming buildings the player is hiding inside of
	- Sea Knight leaves with rear door closing if player doesn't make it
	
	Survival Mode Extreme Edition - Surrender or Die!

	1. Features
	
		Helicopters:
		
		- unarmed enemy MI-17 transport helicopters with fastrope deployments
		- armed enemy KA-50 attack helicopters doing ground attack with rockets and machine guns against the player
			- blow holes in buildings that the player is hiding inside of, preceded by nearby enemy radio voice cues
		- shooting down KA-50 and MI-17 helicopters with RPGs and/or Stingers
		- KA-50 and MI-17 helicopters crashing outside of the level, out of sight
		- Sea Knight arrives and opens rear door to let people on board
		- Sea Knight has side door gunner(s) firing mounted guns
		
		Ground Vehicles:
		
		- BMP with soldiers unloading from them
		- BMP gets destroyed by minigun, RPG, AT/4
		- T-72 gets destroyed by Javelin
		- UAZ jeeps with soldiers unloading from them
		
		Minigun:
		
		- mounted minigun capable of shooting down helicopters and destroying ground vehicles 
			- winds up to full rotational speed with left trigger, then starts to fire bullets with right trigger
			- overheats after 30 seconds of sustained fire, so you have to control your firing, but can keep it spooled up
			- limited ammo reserve, 10000 rnds
			
		Preplanned Explosive Killzones:
		
		- preplanned explosive detonator switches and marked killzones 
			- special textures showing hand drawn top down diagrams of the killzones next to each detonation station
			- players have to figure it out and learn the level by playing it
			- one detonator clacker per window+diagram combo
			- some scripted moments where AI out of player's sight report on the radio and the killzone explodes automatically
			
		Player Weapons Caches:
		
		- weapons caches (RPGs/Stingers, Machine Guns, Sniper Rifles, Submachine Guns, Novelty Weapons, Various Grenades) 
	
	2. Story integration
		- Al-Asad gets killed at the outset
		- Al-Asad must survive
	
	3. Player falling back early
		- make the battle indefinite until the player meets a participation metric like pegasusday
		- the timer doesn't start until later in the level when they receive a radio transmission from HQ
	
	4. Player not falling back at all or staying on the minigun forever
		- activate smokescreens for the enemy to run through
	
	5. Player hiding in a corner waiting for the timer to run out
		- solve this by having AI track down the player
			- manual player location volume detection for each building
				- use nearby custom spawners for known hiding locations
				- flashbang and clear rooms and kill player
				- magic grenade spam through windows where player is hiding
			- automatic player goalentitying for outdoor hiding spots
				- player execution routine for AI in both indoor and outdoor spots
				- use helicopters to flush out player in outdoor hiding places without top cover
		
Rules used in Pegasusday:
	1. The first battle would go on forever until the player satisfied a participation metric - X kills && X time elapsed.
		- didn't matter how far away he was, could snipe from far away if he wanted to
		- the player could run away but would encounter token resistance away from the main battle
			- token resistance spawned rarely to make it clear where the main battle was
	2. The fall back to the machine gun and cover the squad objective was required, or the war would go on indefinitely.
	3. The timer starts when the player is going to be attacked from all sides.
	4. Enemy threat escalates to introduce tanks which have several ways of killing the player caught in the open.
		- These are not required to win but are presented as optional objectives
		- They accumulate but do not display a count remaining on the objective text
		- The player has several options built into the level with which to destroy the tanks.
			- Fixed weapon
			- Normal anti-tank weapons
	5. There are almost no perfect hiding places where the player is safe with his back to a wall. Maybe the guard hut.
		
*****************************************************************************/

#include maps\_utility;
#include maps\_vehicle;
#include maps\_anim;

main()
{
	level.xenon = false;
    
	if (isdefined( getdvar("xenonGame") ) && getdvar("xenonGame") == "true" )
		level.xenon = true;
	
	//add_start( "zpu", ::start_zpu );
	//add_start( "cobras", ::start_cobras );
	//add_start( "end", ::start_end );
	//add_start( "seaknights", ::start_seaknights );
	default_start( ::start_village_defend );
	maps\village_defend_fx::main();
	maps\_load::main();	
	
	maps\createart\village_defend_art::main();	

	maps\_compass::setupMiniMap("compass_map_village_defend");
	//level thread maps\village_defend_amb::main();	
}

start_village_defend()
{
	return;
}

