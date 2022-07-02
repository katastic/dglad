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
	cooldown primary;

	this(pair _pos, int teamIndex)
		{
		immutable int FIRE_COOLDOWN = 10;
		super(_pos, teamIndex, g.potion_bmp);
		primary.setMax(FIRE_COOLDOWN);
		}		
		
	// acquire range could be slightly closer than tracking range (hysterisis)
	bool isTracking = false;
	immutable float TRACKING_RANGE = 200;
	unit myTarget;

	void setTarget(unit u)
		{
		myTarget = u;
		isTracking = true;
		}
	
	bool isTargetInRange(unit u)
		{
		if(distanceTo(this, u) < TRACKING_RANGE)
			{
			return true;
			}
		return false;
		}
		
	override void onTick()
		{
		// Firing pattern mechanic possibilities (for when multiple players exist)
		// - fire only at first person in list (simple, current) [strat: whoever isn't that player, fight] [ALWAYS FAVORS one player which is bad.]
		// - fire at each person in order					[strat: Spread DPS across players]
		// - fire SAME RATE, but at AS MANY PLAYERS exist.	[DPS increases with players in range]
		// -> fire at FIRST PERSON to be targetted until we no longer have that target in range. [strat: grab aggro, others fight it.]
		primary.onTick();
		
		if(!isTracking)
			{
			foreach(u; g.world.units)
				{
				if(u !is this && u.myTeamIndex != this.myTeamIndex && distanceTo(u, this) < 200 && primary.isReadySet()) // is ready set must come after, as it MUTATES too!
					{
					setTarget(u);
					break;
					}
				}
			}else{
			if(!isTargetInRange(myTarget))
				{
				isTracking = false;
				}else{
				if(primary.isReadySet())
					{
					pair v = apair(angleTo(myTarget, this), 15);
					g.world.bullets ~= new bullet(this.pos, v, angleTo(myTarget, this), yellow, 0, 100, this, 0);
					}
				}
			}
		}
	}

class structure : unit
	{
	immutable float maxHP=500.0;
	float hp=maxHP;
	int level=1; //ala upgrade level
//	int myTeamIndex=0;
	immutable int countdown_rate = 200; // 60 fps, 60 ticks = 1 second
	int countdown = countdown_rate; // I don't like putting variables in the middle of classes but I ALSO don't like throwing 1-function-only variables at the top like the entire class uses them.
	
	this(pair _pos, int teamIndex, ALLEGRO_BITMAP* b)
		{
		super(0, _pos, pair(0,0), b);
		myTeamIndex = teamIndex; //must come after constructor
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
