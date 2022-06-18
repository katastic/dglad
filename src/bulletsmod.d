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
	float angle=0;
	int type; // 0 = normal bullet whatever
	int lifetime; // frames passed since firing
	bool isDead=false; // to trim
	unit myOwner;
	COLOR c;
	
	this(pair _pos, pair _vel, float _angle, COLOR _c, int _type, int _lifetime, unit _myOwner, bool _isDebugging)
		{
		isDebugging = _isDebugging;
		c = _c;
		myOwner = _myOwner;
		pos.x = _pos.x;
		pos.y = _pos.y;
		vel.x = _vel.x;
		vel.y = _vel.y;
		type = _type;
		lifetime = _lifetime;
		angle = _angle;
		super(pair(this.pos), pair(this.vel), g.bullet_bmp);
		}
	
	void applyV(float applyAngle, float _vel)
		{
		vel.x += cos(applyAngle)*_vel;
		vel.y += sin(applyAngle)*_vel;
		}

	bool checkUnitCollision(unit u)
		{
//		writefln("[%f,%f] vs u.[%f,%f]", x, y, u.x, u.y);
		if(pos.x - 10 < u.pos.x)
		if(pos.x + 10 > u.pos.x)
		if(pos.y - 10 < u.pos.y)
		if(pos.y + 10 > u.pos.y)
			{
//		writeln("[bullet] Death by unit contact.");
			return true;
			}		
		return false;
		}
		
	void die(unit from)
		{
		isDead=true;
		vel.x = 0;
		vel.y = 0;
		import std.random : uniform;
		g.world.particles ~= particle(pair(this.pos), pair(this.vel), 0, uniform!"[]"(3, 6));
		if(isDebugging) writefln("[debug] bullet at [%3.2f, %3.2f] died from [%s]", pos.x, pos.y, from);
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
						
			pos.x += vel.x;
			pos.y += vel.y;
			}
		}
	
	override bool draw(viewport v)
		{		
		float cx = pos.x + v.x - v.ox;
		float cy = pos.y + v.y - v.oy;
		if(cx > 0 && cx < SCREEN_W && cy > 0 && cy < SCREEN_H)
			{
			al_draw_center_rotated_tinted_bitmap(bmp, c, cx, cy, angle + degToRad(90), 0);
			return true;
			}
		return false;
		}
	}
