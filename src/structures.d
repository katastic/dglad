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

import std.math : cos, sin, PI;
import std.stdio;
import std.random;
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;

class tower : structure
	{
	this(pair _pos)
		{
		super(_pos, g.potion_bmp);
		}
		
	override void onTick()
		{
		foreach(u; g.world.units)
			{
			if(distanceTo(u, this) < 100)
				{
				pair v = apair(angleTo(u, this), 15);
				g.world.bullets ~= new bullet(this.pos, v, angleTo(u, this), yellow, 0, 100, this, 0);
				}
			}
		}
	}

class structure : unit
	{
	immutable float maxHP=500.0;
	float hp=maxHP;
	int level=1; //ala upgrade level
	int team=0;
	immutable int countdown_rate = 200; // 60 fps, 60 ticks = 1 second
	int countdown = countdown_rate; // I don't like putting variables in the middle of classes but I ALSO don't like throwing 1-function-only variables at the top like the entire class uses them.
	
	this(pair _pos, ALLEGRO_BITMAP* b)
		{
		super(0, _pos, pair(0,0), b);
		}

	override bool draw(viewport v)
		{
		drawCenteredBitmap(bmp, vpair(this.pos), 0);
		return true;
		}

	void onHit(unit u, float damage)
		{
		hp -= damage;
		}
		
	void spawnDude()
		{
		writeln("structure spawning dude.");
		g.world.units ~= new soldier(this.pos, g.world.atlas); // FIXME. THIS SHOULD CRASH but it's not
		} 
		
	override void onTick()
		{
		countdown--;
		if(countdown < 0){countdown = countdown_rate; spawnDude();}
		}
	}
