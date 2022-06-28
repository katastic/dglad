import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.stdio;

import viewportsmod;
import objects;
import g;
import helper;

class flightPotion : consumableItem
	{
	this(pair _pos)
		{
		super(_pos);
		}

	override void use(ref unit by)
		{
		by.flyingCooldown = 1_000;
		}
	}

class food : consumableItem		// meats also health potion
	{
	int healAmount=30;
	
	this(pair _pos)
		{
		super(_pos);
		}

	override void use(ref unit by)
		{
		by.hp += healAmount;
		clampHigh(by.hp, by.hpMax);
		}
	}

class consumableItem : item
	{
	this(pair _pos)
		{
		super(_pos);
		}

	void use(ref unit by)
		{
		}

	override void onPickup(ref unit by)
		{
		use(by);
		}

	}

class item : baseObject
	{
	bool isInside = false; //or isHidden? Not always the same though...
	int team;
	
	this(pair _pos)
		{	
		writeln("ITEM EXISTS BTW at ", _pos.x, " ", _pos.y);
		super(pair(_pos), pair(0,0),g.potion_bmp);
		}
		
	void onPickup(ref unit by)
		{
		}
		
	override bool draw(viewport v)
		{
		if(!isInside)
			{
			super.draw(v);
			return true;
			}
		return false;
		}
		
	override void onTick()
		{
		if(!isInside)
			{
			pos.x += vel.x;
			pos.y += vel.y;
			vel.x *= .99; 
			vel.y *= .99; 
			}
		}
	}
