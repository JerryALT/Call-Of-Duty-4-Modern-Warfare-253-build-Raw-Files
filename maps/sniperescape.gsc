#include maps\_utility;
#include maps\_vehicle;
#include maps\sniperescape_code;
#include common_scripts\utility;
#include maps\_anim;

main()
{
	maps\createart\sniperescape_art::main();
	maps\sniperescape_fx::main();
	maps\_mi17::main( "vehicle_mi17_woodland_fly_cheap" );
	maps\_mi17::main( "vehicle_mi-28_flying" );
	maps\_hind::main( "vehicle_mi24p_hind_woodland" );
	maps\createfx\sniperescape_fx::main();
	maps\createfx\sniperescape_audio::main();

	setsaveddvar( "ai_eventDistFootstep", "32" );
	setsaveddvar( "ai_eventDistFootstepLite", "32" );

	precacheModel( "viewhands_player_usmc" );
	add_start( "run", ::start_run );
	add_start( "apart", ::start_apartment );
	add_start( "wounding", ::start_wound );
	add_start( "wounded", ::start_wounded );
	add_start( "pool", ::start_pool );
	default_start( ::rappel );
	createthreatbiasgroup( "price" );
	createthreatbiasgroup( "dog" );
	setignoremegroup( "price", "dog" );

	
	maps\_load::main();
	maps\_claymores_sp::main();
	
	maps\sniperescape_anim::main();
	level thread maps\sniperescape_amb::main();	
	
	
	level.price = getent( "price", "targetname" );
	level.price thread priceInit();
	
	battlechatter_off( "allies" );
	battlechatter_off( "axis" );

	thread do_in_order( ::flag_wait, "player_looks_through_skylight", ::exploder, 1 );
	
	level.engagement_dist_func = [];
	add_engagement_func( "actor_enemy_merc_SHTGN_winchester", ::engagement_shotgun );
	add_engagement_func( "actor_enemy_merc_AR_ak47", ::engagement_rifle );
	add_engagement_func( "actor_enemy_merc_LMG_rpd", ::engagement_gun );
	add_engagement_func( "actor_enemy_merc_SNPR_dragunov", ::engagement_sniper );
	add_engagement_func( "actor_enemy_merc_SMG_skorpion", ::engagement_smg );

	enemies = getaiarray( "axis" );
	array_thread( enemies, ::enemy_override );
	enemy_spawners = getspawnerteamarray( "axis" );
	array_thread( enemy_spawners, ::add_spawn_function, ::enemy_override );

	// flags
	flag_init( "player_rappels" );
	flag_init( "wounding_sight_blocker_deleted" );	
	flag_init( "player_can_rappel" );
	flag_init( "apartment_explosion" );
	flag_init( "heat_area_cleared" );
	flag_init( "player_defends_heat_area" );
	flag_init( "price_is_safe_after_wounding" );
	flag_init( "price_was_hit_by_heli" );
	flag_init( "price_picked_up" );

	// group1 initiates group2 when group1 gets low
	group1_enemies = getentarray( "group_1", "script_noteworthy" );
	ent = spawnstruct();
	ent.count = 0;
	array_thread( group1_enemies, ::group1_enemies_think, ent );
	
	level.debounce_triggers = [];
	run_thread_on_targetname( "move_in_trigger", ::move_in );
	run_thread_on_targetname( "leave_one", ::leave_one_think );
	run_thread_on_targetname( "heli_trigger", ::heli_trigger );
	run_thread_on_targetname( "block_path", ::block_path );
	run_thread_on_targetname( "debounce_trigger", ::debounce_think );

	run_thread_on_noteworthy( "patrol_guy", ::add_spawn_function, ::patrol_guy );
	run_thread_on_noteworthy( "chopper_guys", ::add_spawn_function, ::chopper_guys_land );
	run_thread_on_noteworthy( "chase_chopper_guys", ::add_spawn_function, ::chase_chopper_guys_land );

	thread music();	
	
}

music()
{
//	level endon( "price_is_safe_after_wounding" );
	for( ;; )
	{
		musicPlay( "sniperescape_run_music" ); 
		wait( 137 );
	}
}


priceInit()
{
	self thread magic_bullet_shield();
	self.baseaccuracy = 1000;
	self.animplaybackrate = 1.1;
	self.ignoresuppression = true;
	self.animname = "price";
	
	thread gilli_leaves();
}

playerangles()
{
	for( ;; )
	{
		println( level.player getplayerangles() );
		wait( 0.05 );
	}
}

player_rappel()
{
	// temp glowing object
	rappel_glow = getent( "rappel_glow", "targetname" );
	rappel_glow hide();
	
	// the rappel sequence is relative to this node
	player_node = getnode( "player_rappel_node", "targetname" );

	// this is the model the player will attach to for the rappel sequence
	model = spawn_anim_model( "player_rappel" );
	model hide();
	
	// put the model in the first frame so the tags are in the right place
	player_node anim_first_frame_solo( model, "rappel" );

	// this is sniperescape specific stuff for the helicopter that attacks and the explosion that goes off
	thread heli_attacks_start();
	rappel_trigger = getent( "rappel_trigger", "targetname" );
	rappel_trigger trigger_off();
	flag_wait( "player_can_rappel" );
	rappel_trigger trigger_on();
	rappel_trigger.origin +=( 0, 0, 10 );
	rappel_trigger sethintstring( "Hold &&1 to rappel" );
	
	rappel_glow show();
	rappel_trigger waittill( "trigger" );	
	rappel_trigger delete();
	rappel_glow hide();
	flag_set( "player_rappels" );
	
	level.player thread take_weapons();
	
	delayThread( 3.2, ::flag_set, "apartment_explosion" );

	// this smoothly hooks the player up to the animating tag
	model lerp_player_view_to_tag( "tag_player", 0.5, 0.9, 35, 35, 45, 0 );

	// now animate the tag and then unlink the player when the animation ends
	player_node thread anim_single_solo( model, "rappel" );
	player_node waittill( "rappel" );
	level.player unlink();
	
	level.player give_back_weapons();
	delaythread( 1.5, ::flag_set, "heli_moves_on" );
}

rappel()
{
	thread player_rappel();
	price_node = getnode( "price_rappel_node", "targetname" );
	price_node anim_reach_solo( level.price, "rappel_start" );
	
	// birds fly up
	delayThread( 2, ::exploder, 6 );
	
	delaythread( 3, ::flag_set, "player_can_rappel" );
	thread apartment_explosion();
	price_node anim_single_solo( level.price, "rappel_start" );
	price_node thread anim_loop_solo( level.price, "rappel_idle", undefined, "stop_idle" );
	flag_wait( "player_rappels" );
	price_node notify( "stop_idle" );
	price_node thread anim_single_solo( level.price, "rappel_end" );
	wait( 4 );
	level.price set_force_color( "r" );
	thread battle_through_heat_area();
}

apartment_explosion()
{
	// blow up the apartment if the player doesn't rappel soon enough
//	explosion_death_trigger
	
	flag_wait_or_timeout( "apartment_explosion", 8 );

	// blow up the top floor
	exploder( 3 );
	deathtrig = getent( "explosion_death_trigger", "targetname" );
	wait( 2.4 );

	if( !( level.player istouching( deathtrig ) ) )
		return;
		
	level.player enableHealthShield( false );
	level.player dodamage( level.player.health + 99150, deathtrig.origin );
}

start_run()
{
	node = getnode( "tele_node", "targetname" );
	org = getent( "tele_org", "targetname" );
	
	level.player setplayerangles(( 0, 0, 0 ) );
	level.player setorigin( org.origin +( 0, 0, -34341 ) );
	level.price teleport( node.origin );
	level.player setorigin( org.origin );
	
	thread battle_through_heat_area();
}

battle_through_heat_area()
{
//	level.price thread price_calls_out_kills();

	weapons_dealers = getentarray( "weapons_dealer", "targetname" );
	array_thread( weapons_dealers, ::delete_living );

	// change enemy accuracy on the fly so we can fight tons of guys without it being lame
	thread enemy_accuracy_assignment();

	east_spawners = getentarray( "east_spawner", "targetname" );
	thread spawners_attack( east_spawners, "start_heat_spawners", "stop_heat_spawners" );

	west_spawners = getentarray( "west_spawner", "targetname" );
	thread spawners_attack( west_spawners, "start_heat_spawners", "stop_heat_spawners" );

	wait( 1 );

	// Leftenant Price, follow me!	
	level.price anim_single_queue( level.price, "follow_me" );
	
	objective_add( 1, "active", "Follow Cpt. MacMillan to the extraction point.", ( 4800, 1488, 32 ) );
	objective_current( 1 );
	level.price thread objective_position_update( 1 );

	// Alpha Six, Seaknight Five-Niner is en route, E.T.A. - 20 minutes. Don't be late. We're stretchin' our fuel as it is. Out.	
	delayThread( 3, ::radio_dialogue_queue, "eta_20_min" );
	delayThread( 5.5, ::countdown, 20 );

	// We've got to head for the extraction point! Move!	
	level.price delayThread( 10, ::anim_single_queue, level.price, "head_for_extract" );
	
//	thread player_hit_debug();
	
	flag_wait( "start_heat_spawners" );
	// temporary work around for -onlyents bug
//	spawn_vehicle_from_targetname_and_drive( "introchopper1" );
	thread intro_workaround();

	wait_for_script_noteworthy_trigger( "heat_enemies_back_off" );
	// _colors is waiting for this script to hit, so we have to wait for that to happen so that
	// the orange and yellow colors get set
	waittillframeend;
	
	level.price set_force_color( "o" );

	defend_heat_area_until_enemies_leave();	

	level.price set_force_color( "y" );
	
	thread the_apartment();
}


start_apartment()
{
	thread countdown( 18 );

	ai = getaispeciesarray( "axis", "all" );
	array_thread( ai, ::delete_living );
	price_org = getent( "price_apartment_org", "targetname" );
	player_org = getent( "player_apartment_org", "targetname" );
	
	level.player setplayerangles(( 0, 0, 0 ) );
	level.player setorigin( player_org.origin +( 0, 0, -34341 ) );
	level.price teleport( price_org.origin );
	level.player setorigin( player_org.origin );
	level.price set_force_color( "y" );
	thread the_apartment();
}

the_apartment()
{
	// We'll lose 'em in that apartment! Come on!	
	level.price anim_single_queue( level.price, "lose_them_in_apartment" );
	

	spin_trigger = getent( "price_explore_trigger", "targetname" );
	spin_trigger waittill( "trigger" );
	spin_ent = getent( spin_trigger.target, "targetname" );
	autosave_by_name( "into_the_apartment" );	
//	musicPlay( "bog_a_shantytown" ); 

	spin_ent anim_reach_solo( level.price, "spin" );
	spin_ent anim_single_solo( level.price, "spin" );
	level.price set_force_color( "y" );

	flag_wait( "fence_dog_attacks" );
	
	thread dog_attacks_fence();

	flag_wait( "plant_claymore" );

	// Quickly - plant a claymore in case they come this way!	
	level.price thread anim_single_queue( level.price, "place_claymore" );
	
	flag_wait( "player_moves_through_apartment" );
	thread the_wounding();
}

start_wound()
{
	thread countdown( 16 );

	ai = getaispeciesarray( "axis", "all" );
	array_thread( ai, ::delete_living );
	price_org = getent( "price_apart_org", "targetname" );
	player_org = getent( "player_apart_org", "targetname" );
	
	level.player setplayerangles( player_org.angles );
	level.player setorigin( player_org.origin +( 0, 0, -34341 ) );
	level.price teleport( price_org.origin );
	level.player setorigin( player_org.origin );
	level.price enable_cqbwalk();
	level.price set_force_color( "y" );
	thread the_wounding();
}

the_wounding()
{
	thread price_wounding_kill_trigger();
	
	thread player_touches_wounded_blocker();
//	level.price.maxVisibleDist = 32;
//	level.player.maxVisibleDist = 32;
	
	price_waits_for_enemies_to_walk_past();	
	level.price.maxvisibledist = 200;
	delete_wounding_sight_blocker();
	delaythread( 4.0, ::activate_trigger_with_targetname, "surprise_trigger" );	
	
	
	node = getnode( "price_attack_node", "targetname" );
	level.price disable_ai_color();
	level.price.fixedNodeSafeRadius = 32;
	level.price setgoalnode( node );
	level.price.goalradius = 32;
	
	level.price waittill( "goal" );
	level.price.maxvisibledist = 8000;
	
	node = getnode( "price_apartment_destination_node", "targetname" );
	level.price.fixedNodeSafeRadius = node.fixedNodeSafeRadius;
	level.price setgoalnode( node );

	flag_wait( "price_walks_into_trap" );
	
	wait( 3 );
	
	heli = spawn_vehicle_from_targetname_and_drive( "heli_price" );
	level.price_heli = heli;
	heli thread helipath( heli.target, 70, 70 );
	flag_wait( "price_heli_in_position" );
	wait( 1 );
	heli kills_enemies_then_wounds_price_then_leaves();
	thread wounded_combat();
}

price_waits_for_enemies_to_walk_past()
{
	if( flag( "enemies_walked_past" ) )
		return;
 	if( flag( "wounding_sight_blocker_deleted" ) )
 		return;
 		
	level endon( "wounding_sight_blocker_deleted" );
	flag_wait( "price_says_wait" );

	autosave_by_name( "standby" );	

	// Standby?!	
	level.price thread anim_single_queue( level.price, "standby" );
	flag_wait( "enemies_walked_past" );

	// Now!	
	level.price thread anim_single_queue( level.price, "now" );
}

start_wounded()
{
	wounding_sight_blocker = getent( "wounding_sight_blocker", "targetname" );
	wounding_sight_blocker connectpaths();
	wounding_sight_blocker delete();

	thread countdown( 13 );

	ai = getaispeciesarray( "axis", "all" );
	array_thread( ai, ::delete_living );
	price_org = getnode( "price_apartment_destination_node", "targetname" );
	player_org = getent( "player_post_wound_org", "targetname" );
	
	level.player setplayerangles( player_org.angles );
	level.player setorigin( player_org.origin +( 0, 0, -34341 ) );
	level.price teleport( price_org.origin );
	level.player setorigin( player_org.origin );
	level.price disable_ai_color();
	
	thread wounded_combat();
}

wounded_combat()
{
	flag_set( "price_is_safe_after_wounding" );
	autosave_by_name( "carry_price" );	
//	musicStop();

	wait( 3.5 );
	// Bloody 'ell I?m hit, I can't move!!!!	
	level.price anim_single_queue( level.price, "im_hit" );

	org = getent( "apartment_battle_org", "targetname" );
	objective_string( 1, "Drag MacMillan bodily to the extraction point." );
	objective_position( 1, org.origin );
	// price is hit so he is no longer the objective
	level notify( "stop_updating_objective" );
//	delaythread( 5, ::activate_trigger_with_targetname, "surprise_trigger" );	
	
	zones = getentarray( "zone", "targetname" );
	array_thread( zones, ::enemy_spawn_zone );
	thread price_wounded_logic();

	thread price_followup_line();

	// The extraction point is to the southwest. We can still make it if we hurry.	
	thread do_in_order( ::flag_wait, "price_picked_up", ::radio_dialogue_queue, "extraction_is_southwest" );
	
	flag_wait_or_timeout( "price_picked_up", 20 );
	wait( 5 );
	
	thread enemy_zone_spawner();
	flag_wait( "level_end" );
	iprintlnbold( "End of currently scripted level" );
}

start_pool()
{
	wounding_sight_blocker = getent( "wounding_sight_blocker", "targetname" );
	wounding_sight_blocker connectpaths();
	wounding_sight_blocker delete();

	thread countdown( 8 );

	ai = getaispeciesarray( "axis", "all" );
	array_thread( ai, ::delete_living );
	player_org = getent( "player_pool_org", "targetname" );
	level.player setplayerangles( player_org.angles );
	level.player setorigin( player_org.origin );
	
	wait( 2 );
	pool_spawner = getentarray( "pool_rappel_spawner", "targetname" );
	array_thread( pool_spawner, ::add_spawn_function, ::pool_attack );
	array_thread( pool_spawner, ::wait_then_spawn );
}

pool_attack()
{
	self.animname = "axis";
	node = getent( self.target, "targetname" );
	node anim_single_solo( self, "rappel" );
}

wait_then_spawn()
{
	waitSpread( 0, 6 );
	maps\_spawner::spawn_ai();
}

intro_workaround()
{
	helis = spawn_vehicles_from_targetname( "introchopper1" );
	for ( i=0; i < helis.size; i++ )
	{
		heli = helis[ i ];
		if ( heli.script_vehiclespawngroup == 0 )
		{
			thread gopath( heli );
		}
		else
		{
			heli delete();
		}
	}
}
