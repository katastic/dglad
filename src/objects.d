import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.conv;
import std.random;
import std.stdio;
import std.math;
import std.string;
import std.algorithm : remove;

import g;
import helper;
import viewportsmod;
import particles;
import guns;
import turretmod;
import bulletsmod;
import mapsmod;
	
immutable float FALL_ACCEL = .1;
immutable float WALK_SPEED = 1;
immutable float JUMP_SPEED = 5;

enum DIR
	{
		UP = 0,	// some only have 1 direction and stop here.
		DOWN,
		LEFT,
		RIGHT,	// some only have 4 (U,D,L,R) directions and stop here.
		UPLEFT,
		UPRIGHT,
		DOWNRIGHT,
		DOWNLEFT,
	}

class animation
	{
	// do we want/care to reset walk cycle when you change direction? 
    import std.traits;
	int numDirections; 
	int numFrames;
	int index = 0; /// frame index
	bool usesFlippedGraphics = false; /// NYI. use half the sideways graphics and flips them based on direction given. Usually meaningless given RAM amounts.
	BITMAP*[][DIR] bmps;
	
	this(int _numFrames)
		{
		foreach(immutable d; [EnumMembers!DIR])
			{
			bmps[d] ~= al_create_bitmap(32,32);
			}
		}
		
	void nextFrame()
		{
		index++;
		if(index == numFrames)index = 0;
		}
		
	void draw(pair pos, DIR dir) /// implied viewport
		{
		drawCenteredBitmap( bmps[dir][index], vpair(pos), 0);
		}
	}

class soldier : unit
	{
	this(float _x, float _y)
		{
		super(0, pair(0, 0), pair(0, 0), g.grass_bmp);
		}
	
	int chargeCooldown=0;
	void charge() // "HUURRRLL"
		{
		chargeCooldown = 100;
		}
	
	override void onTick()
		{
		if(chargeCooldown) // can't do anything except run forward during charge.
			{
			pos += vel;
			chargeCooldown--;
			return;
			}
			
		// normal stuff
		}
	
	override void actionSpecial()
		{
		charge();
		}
	}


/+
class item : baseObject
	{
	bool isInside = false; //or isHidden? Not always the same though...
	int team;
	
	this(uint _team, float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* b)
		{	
		writeln("ITEM EXISTS BTW at ", x, " ", y);
		super(_x, _y, _vx, _vy, b);
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
			x += vx;
			y += vy;
			vx *= .99; 
			vy *= .99; 
			}
		}
	}+/

class dude : baseObject
	{
	// do dudes walk around the surface or bounce around the inside?

	this(pair _pos, pair _vel)
		{
		super(_pos, _vel, g.dude_bmp);
		}

	// originally a copy of structure.draw
	override bool draw(viewport v)
		{		
		return true;
		}

	override void onTick()
		{
		pos.x += vel.x;
		pos.y += vel.y;
		}
	}
	
class structure : baseObject
	{
	immutable float maxHP=500.0;
	float hp=maxHP;
	int level=1; //ala upgrade level
	int team=0;
	int direction=0;
	immutable int countdown_rate = 200; // 60 fps, 60 ticks = 1 second
	int countdown = countdown_rate; // I don't like putting variables in the middle of classes but I ALSO don't like throwing 1-function-only variables at the top like the entire class uses them.
	
	this(pair _pos, ALLEGRO_BITMAP* b)
		{
		super(_pos, pair(0,0), b);
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
		g.world.units ~= new unit(1, pair(100, 100), pair(.3, 0), g.dude_bmp);
		} 
		
	override void onTick()
		{
		countdown--;
		if(countdown < 0){countdown = countdown_rate; spawnDude();}
		}
	}

class baseObject
	{
	ALLEGRO_BITMAP* bmp;
	@disable this(); 
	bool isDead = false;	
	pair pos; 	/// baseObjects are centered at X/Y (not top-left) so we can easily follow other baseObjects.
	pair vel; /// Velocities.
	float w=0, h=0;   /// width, height 
	float angle=0;	/// pointing angle 

	this(pair _pos, pair _vel, BITMAP* _bmp)
		{
		pos = _pos;
		vel = _vel;
		bmp = _bmp;
//		writeln("I set x y", _x, " ", _y);
		}
		
	bool draw(viewport v)
		{
		al_draw_center_rotated_bitmap(bmp, 
			pos.x - v.ox + v.x, 
			pos.y - v.oy + v.y, 
			angle, 0);

		return true;
		}
	
	// INPUTS (do we support mouse input?)
	// ------------------------------------------
	void actionUp(){ pos.y-= 10;}
	void actionDown(){pos.y+= 10;}
	void actionLeft(){pos.x-= 10;}
	void actionRight(){pos.x+= 10;}
	
	void actionFire()
		{
		}
		
	void actionSpecial()
		{
		}

	void actionShifter()
		{
		}

	void actionFour() // four button controller. find better name when applicable
		{
		}
	
	void onTick()
		{
		// THOU. SHALT. NOT. PUT. PHYSICS. IN BASE. baseObject.
		}
	}	

class unit : baseObject // WARNING: This applies PHYSICS. If you inherit from it, make sure to override if you don't want those physics.
	{
	bool isDebugging=true;
	float maxHP=100.0; /// Maximum health points
	float hp=100.0; /// Current health points
	float ap=0; /// armor points (reduced on hits then armor breaks)
	float armor=0; /// flat reduction (or percentage) on damages, haven't decided.
	int myTeamIndex=0;
	bool isPlayerControlled=false;
	float weapon_damage = 5;
	bool isFlipped = false; // flip horizontal

	override void onTick()
		{			
/+		bool isMapValid(int i, int j)
			{
			if(i < 0 || j < 0)return false;
			if(i > (g.world.map.width-1)*TILE_W)return false;
			if(j > (g.world.map.height-1)*TILE_H)return false;
	// writefln("                  = %d", g.world.map.data[cx][cy].isPassable);
			return true;
			} no function overloading on nested functions maybe? odd+/
			
		bool isMapValid(ipair p)
			{
			if(p.i < 0 || p.j < 0)return false;
			if(p.i >= g.world.map.width)return false;
			if(p.j >= g.world.map.height)return false;
	// writefln("                  = %d", g.world.map.data[cx][cy].isPassable);
			return true;
			}
			
		bool isMapValid_px(int x, int y)
			{
			long i = cast(long)x/TILE_W;
			long j = cast(long)y/TILE_H;
			if(i < 0 || j < 0)return false;
			if(i > (g.world.map.width-1)*TILE_W)return false;
			if(j > (g.world.map.height-1)*TILE_H)return false;
	// writefln("                  = %d", g.world.map.data[cx][cy].isPassable);
			return true;
			}

		bool isMapValidref(float x, float y, ref ipair rowcol)
			{
			int i = cast(int)x/TILE_W;
			int j = cast(int)y/TILE_H;
			if(i < 0 || j < 0)return false;
			if(i > (g.world.map.width-1)*TILE_W)return false;
			if(j > (g.world.map.height-1)*TILE_H)return false;
	// writefln("                  = %d", g.world.map.data[cx][cy].isPassable);
			rowcol.i = i;
			rowcol.j = j;
			return true;
			}
/+
		void checkAbove()
			{ 
			ipair ip3 = ipair(this, 0, -cast(float)(TILE_H)); 
			if(isMapValid(ip3.i, ip3.j) && !isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j]))
				{
				// contact above
				vel.y = 0;
				pos.y++;
				}
			}+/
		
//		checkAbove();
		if(isPlayerControlled == false)
			{
			pos += vel;
			ipair ip3 = ipair(this, 0, -cast(float)(TILE_H)); 
			if(isMapValid(ip3) && !isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j]))
				{
				pos -= vel;	
				pos -= vel;
				vel = 0;
				}
			}
		if(pos.x < 0){pos.x = 0; vel.x = -vel.x; isFlipped=true;}
		if(pos.x >= (g.world.map.width)*TILE_W){pos.x = (g.world.map.width)*TILE_W-1; vel.x = -vel.x; isFlipped=true;}
		if(pos.y < 0){pos.y = 0; vel.y = -vel.y;}
		if(pos.y >= (g.world.map.height)*TILE_W){pos.y = (g.world.map.height)*TILE_H-1; vel.y = -vel.y;}
		}
		
	void onCollision(baseObject who)
		{
		}
		
	void onHit(bullet b) //projectile based damage
		{
		// b.myOwner
		}

	void onCrash(unit byWho) //for crashing into each other/objects
		{
		}

	void doAttackStructure(structure s)
		{
		s.onHit(this, weapon_damage);
		}

	void doAttack(unit u)
		{
		u.onAttack(this, weapon_damage);
		}
		
	void onAttack(unit from, float amount) /// I've been attacked!
		{
		hp -= amount;
		}
	
	this(uint _teamIndex, pair _pos, pair _vel, ALLEGRO_BITMAP* b)
		{
		myTeamIndex = _teamIndex; 
		super(_pos, _vel, b);
		//writefln("xy v:xy %f,%f %f,%f", x, y, vx, vy);
		}

	override bool draw(viewport v)
		{
		if(!isWideInsideScreen(vpair(this.pos), bmp))return false;
		// NOTE we're drawing with "center" being at the bottom of the image.
		drawBitmap(bmp, vpair(this.pos, -bmp.w/2, 0), isFlipped);
//		if(isDebugging) drawTextCenter(vpair(this, 0, -32), black, "J%1dF%1d V%3.1f,%3.1f", isJumping, isFalling, vx, vy);
		
		if(isPlayerControlled) 
			{
			}
	
		draw_hp_bar(pos.x, pos.y - bmp.w/2, v, hp, 100);		
		return true;
		}
	}
