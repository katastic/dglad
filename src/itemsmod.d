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

class money : consumableItem /// copper, silver, gold bars
	{
	int amount = 100;
	this(pair _pos)
		{
		super(_pos);
		}

	override bool use(ref unit by)
		{
		if(!teams[by.myTeamIndex].isAI) /// don't give ENEMY AI teams money!
			{
			teams[by.myTeamIndex].money += amount;
			return true;
			}else{
			return false;
			}
		}
	}

class invulnerabilityPotion : consumableItem
	{
	this(pair _pos)
		{
		super(_pos);
		}

	override bool use(ref unit by)
		{
		by.flyingCooldown = 1_000;
		return true;
		}
	}

class flightPotion : consumableItem
	{
	this(pair _pos)
		{
		super(_pos);
		}

	override bool use(ref unit by)
		{
		by.flyingCooldown = 1_000;
		return true;
		}
	}

class food : consumableItem		/// small medium large meats also health potion
	{
	int healAmount=30;
	
	this(pair _pos)
		{
		super(_pos);
		}

	override bool use(ref unit by)
		{
		by.hp += healAmount;
		clampHigh(by.hp, by.hpMax);
		return true;
		}
	}

class consumableItem : item
	{
	this(pair _pos)
		{
		super(_pos);
		}

	bool use(ref unit by)
		{
		return true; //returns false for invalid pickup attempts.
		}

	override void onPickup(ref unit by)
		{
		if(by.myTeamIndex != 0) // neutral cannot pickup items, also AI teams? (should AI pickup food/potions? But not money!)
			//  && !teams[by.myTeamIndex].isAI
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
