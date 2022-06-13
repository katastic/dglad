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

import std.math : cos, sin;
import std.stdio;

class bullet : baseObject
	{
	bool isDebugging=false;
	float x=0, y=0;
	float vx=0, vy=0;
	float angle=0;
	int type; // 0 = normal bullet whatever
	int lifetime; // frames passed since firing
	bool isDead=false; // to trim
	unit myOwner;
	bool isAffectedByGravity=true;
	COLOR c;
	
	this(float _x, float _y, float _vx, float _vy, float _angle, COLOR _c, int _type, int _lifetime, bool _isAffectedByGravity, unit _myOwner, bool _isDebugging)
		{
		isDebugging = _isDebugging;
		c = _c;
		myOwner = _myOwner;
		x = _x;
		y = _y;
		vx = _vx;
		vy = _vy;
		type = _type;
		lifetime = _lifetime;
		angle = _angle;
		isAffectedByGravity = _isAffectedByGravity;
		super(_x, _y, _vx, _vy, g.bullet_bmp);
		}
	
	void applyGravity()
		{		
		float g = 9.82f;
		vy += g;
//		applyV(angle2, g);
		}

	void applyV(float applyAngle, float vel)
		{
		vx += cos(applyAngle)*vel;
		vy += sin(applyAngle)*vel;
		}

	bool checkUnitCollision(unit u)
		{
//		writefln("[%f,%f] vs u.[%f,%f]", x, y, u.x, u.y);
		if(x - 10 < u.x)
		if(x + 10 > u.x)
		if(y - 10 < u.y)
		if(y + 10 > u.y)
			{
//		writeln("[bullet] Death by unit contact.");
			return true;
			}		
		return false;
		}
		
	void die(unit from)
		{
		isDead=true;
		vx = 0;
		vy = 0;
		import std.random : uniform;
		g.world.particles ~= particle(x, y, vx, vy, 0, uniform!"[]"(3, 6));
		if(isDebugging) writefln("[debug] bullet at [%3.2f, %3.2f] died from [%s]", x, y, from);
		}
	
	override void onTick() // should we check for planets collision?
		{
		lifetime--;
		if(lifetime == 0)
			{
			isDead=true;
			}else{
			foreach(u; g.world.units) // NOTE: this is only scanning units not SUBARRAYS containing turrets
				{

				}
						
			x += vx;
			y += vy;
			}
		}
	
	override bool draw(viewport v)
		{		
		float cx = x + v.x - v.ox;
		float cy = y + v.y - v.oy;
		if(cx > 0 && cx < SCREEN_W && cy > 0 && cy < SCREEN_H)
			{
			al_draw_center_rotated_tinted_bitmap(bmp, c, cx, cy, angle + degToRad(90), 0);
			return true;
			}
		return false;
		}
	}
