import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import g;
import viewportsmod;
import objects;
import helper;
import turretmod;
import planetsmod;
import particles;
import mapsmod;
import bulletsmod;
import graph;
import structures;
import blood;

import std.math : cos, sin, PI;
import std.stdio;
import std.random;
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;

class world_t
	{	
	atlasHandler atlas;
		
	player[] players;
	team[] teams;
				
	unit[] units;
	particle[] particles;
	bullet[] bullets;
	structure[] structures;
	map_t map;
	static_blood_handler_t blood;

	this()
		{
		// see 'bug' https://forum.dlang.org/post/uvjvtzidbqartwkbbaww@forum.dlang.org
		// cannot use global module references until constructor finishes.
		// "shouldnt" be doing that anyway technically.
		}
		
	void initialize()
		{
		viewTest();
		atlas = new atlasHandler();
		testLogger();			
				
		players ~= new player();
		
		//structures ~= new structure(100, 100, g.fountain_bmp);
	
		map = new map_t();
		//map.save();
		map.load();
	
		blood = new static_blood_handler_t(map);
	
		structures ~= new structure(pair(300, 300), g.fountain_bmp);
		structures ~= new tower(pair(400, 300));
		structures ~= new tower(pair(350, 250));
	
			units ~= new elf(pair(200, 200), atlas);
			units[0].isPlayerControlled = true;
			units[0].isDebugging = true;
			units ~= new ghost(pair(225, 200), atlas);
			units[1].isPlayerControlled = true;
			units[1].isDebugging = true;
	
		immutable NUM_UNITS = 2;
		
		for(int i = 0; i < NUM_UNITS; i++)
			{
//			float cx = uniform!"[]"(1, map.width*TILE_W-32);
			float cx = uniform!"[]"(1, 200);
			float cy = 100;
			auto u = new soldier(pair(cx, cy), atlas);
			u.pos = pair(apair(uniform!"[]"(0, 2*PI), objects.WALK_SPEED));
			u.isDebugging = false;
			
//			if(i == 0){u.isPlayerControlled = true; u.isDebugging = true;}
			units ~= u;
			}
			
		viewports[0].attach(units[1]);
			
		testGraph = new intrinsicGraph!float("Draw (ms)", g.stats.nsDraw, g.SCREEN_W-400, 5, COLOR(1,0,0,1), 1_000_000);
		testGraph2 = new intrinsicGraph!float("Logic (ms)", g.stats.msLogic, g.SCREEN_W-400, 115, COLOR(1,0,0,1), 1_000_000);
		//testGraph3 = new intrinsicGraph!float("Logging (ms)", g.stats.msLogic, 100, 440, COLOR(1,0,0,1), 1_000_000);
	
		stats.swLogic = StopWatch(AutoStart.no);
		stats.swDraw = StopWatch(AutoStart.no);
		}
		
	void draw(viewport v)
		{
		stats.swDraw.start();

		setViewport2(v); // for all subsequent implied drawing routines
		map.drawBackLayer(v);
		blood.draw(v);
		map.drawFrontLayer(v);

		void draw(T)(ref T obj)
			{
			foreach(ref o; obj)
				{
				o.draw(v);
				}
			}
		
		void drawStat(T, U)(ref T obj, ref U stat)
			{
			foreach(ref o; obj)
				{
				stat++;
				o.draw(v);
				}
			}

		void drawStat2(T, U)(ref T obj, ref U stat, ref U clippedStat)
			{
			foreach(ref o; obj)
				{
				if(o.draw(v))
					{
					stat++;
					}else{
					clippedStat++;
					}
				}
			}

		void drawStat3(T)(ref T obj, ref ulong[2] stat)
			{
			foreach(ref o; obj)
				{
				if(o.draw(v))
					{
					stat[0]++;
					}else{
					stat[1]++;
					}
				}
			}
		
		drawStat3(bullets, 	stats.number_of_drawn_bullets);
		drawStat3(particles, stats.number_of_drawn_particles);
		drawStat3(units, stats.number_of_drawn_units);
		drawStat3(structures, stats.number_of_drawn_structures);		

		testGraph.draw(v);
		testGraph2.draw(v);
//		testGraph3.draw(v);
		stats.swDraw.stop();
		stats.nsDraw = stats.swDraw.peek.total!"nsecs";
		stats.swDraw.reset();
		}
		
	int timer=0;
	void logic()
		{
		stats.swLogic.start();	

		assert(testGraph !is null);
		testGraph.onTick();
		testGraph2.onTick();
	
		map.onTick();
		viewports[0].onTick();
		players[0].onTick();

		if(keyPressed[KEY_OPENBRACE])g.useLighting = true;
		if(keyPressed[KEY_CLOSEBRACE])g.useLighting = false;

		if(keyPressed[KEY_UP])viewports[0].oy-=SCROLL_SPEED;
		if(keyPressed[KEY_DOWN])viewports[0].oy+=SCROLL_SPEED;
		if(keyPressed[KEY_LEFT])viewports[0].ox-=SCROLL_SPEED;
		if(keyPressed[KEY_RIGHT])viewports[0].ox+=SCROLL_SPEED;
	
		if(keyPressed[KEY_N])map.save();
		if(keyPressed[KEY_M])map.load();
		
		if(keyPressed[KEY_1])mouseSetTile(0);
		if(keyPressed[KEY_2])mouseSetTile(1);
		if(keyPressed[KEY_3])mouseSetTile(2);
		if(keyPressed[KEY_4])mouseSetTile(3);
		if(keyPressed[KEY_5])mouseSetTile(4);
		if(keyPressed[KEY_6])mouseSetTile(5);
		if(keyPressed[KEY_7])mouseSetTile(6);
		if(keyPressed[KEY_8])mouseSetTile(7);
		if(keyPressed[KEY_9])mouseSetTile(8);
		if(keyPressed[KEY_0])mouseSetTile(9);
		
		if(keyPressed[KEY_I])world.units[0].actionUp();
		if(keyPressed[KEY_K])world.units[0].actionDown();
		if(keyPressed[KEY_J])world.units[0].actionLeft();
		if(keyPressed[KEY_L])world.units[0].actionRight();
		if(keyPressed[KEY_O])world.units[0].actionFire();
		if(keyPressed[KEY_P])world.units[0].actionSpecial();
		
		if(world.units.length > 1)
			{
			if(keyPressed[KEY_W])world.units[1].actionUp();
			if(keyPressed[KEY_S])world.units[1].actionDown();
			if(keyPressed[KEY_A])world.units[1].actionLeft();
			if(keyPressed[KEY_D])world.units[1].actionRight();
			if(keyPressed[KEY_Q])world.units[1].actionFire();
			if(keyPressed[KEY_E])world.units[1].actionSpecial();
			}
		
		tick(particles);
		tick(units);
		tick(bullets);
		tick(structures);
			
		prune(units);
		prune(particles);
		prune(bullets);
		prune(structures);
		
		stats.swLogic.stop();
		stats.msLogic = stats.swLogic.peek.total!"msecs";
		stats.swLogic.reset();
		}
	}
