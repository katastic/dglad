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
	}

class dude : baseObject
	{
	// do dudes walk around the surface or bounce around the inside?

	this(rpair relpos, float _vx, float _vy)
		{
		super(relpos.rx, relpos.ry, _vx, _vy, g.dude_bmp);
		}

	// originally a copy of structure.draw
	override bool draw(viewport v)
		{		
		return true;
		}

	override void onTick()
		{
		x += vx;
		y += vy;
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
	
	this(float x, float y, ALLEGRO_BITMAP* b)
		{
		super(x, y, 0, 0,b);
		writeln("we MADE a structure. @ ", x, " ", y);
		}

	override bool draw(viewport v)
		{
		drawCenteredBitmap(bmp, vpair(this), 0);
		return true;
		}

	void onHit(unit u, float damage)
		{
		hp -= damage;
		}
		
	void spawnDude()
		{
		g.world.units ~= new unit(1, 100, 100, .3, 0, g.dude_bmp);
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
	float x=0, y=0; 	/// baseObjects are centered at X/Y (not top-left) so we can easily follow other baseObjects.
	float vx=0, vy=0; /// Velocities.
	float w=0, h=0;   /// width, height 
	float angle=0;	/// pointing angle 

	this(float _x, float _y, float _vx, float _vy, BITMAP* _bmp)
		{
		x = _x;
		y = _y;
		vx = _vx;
		vy = _vy;
		bmp = _bmp;
//		writeln("I set x y", _x, " ", _y);
		}
		
	bool draw(viewport v)
		{
		al_draw_center_rotated_bitmap(bmp, 
			x - v.ox + v.x, 
			y - v.oy + v.y, 
			angle, 0);

		return true;
		}
	
	// INPUTS (do we support mouse input?)
	// ------------------------------------------
	void up(){ y-= 10;}
	void down(){y+= 10;}
	void left(){x-= 10;}
	void right(){x+= 10;}
	void actionFire()
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
	
	bool isJumping = false;
	bool isFalling = true;

	void applyGravity()
		{
		vy += .1;
		}

	void applyV(float applyAngle, float vel)
		{
		vx += cos(applyAngle)*vel;
		vy += sin(applyAngle)*vel;
		}

	override void onTick()
		{
		if(!isJumping && percent(5))
			{
//			writeln("TRIGGER. JUMP");
			isJumping = true;
			vy = -3;
			}
			
		bool isMapValid(int i, int j)
			{
			if(i < 0 || j < 0)return false;
			if(i > (g.world.map.width-1)*TILE_W)return false;
			if(j > (g.world.map.height-1)*TILE_H)return false;
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

		void checkAbove()
			{ 
			ipair ip3 = ipair(this, 0, -cast(float)(TILE_H)); 
			if(isMapValid(ip3.i, ip3.j) && !isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j]))
				{
				// contact above
				vy = 0;
				y++;
				}
			}
		
		checkAbove();
			
		ipair ip3 = ipair(this, 0, TILE_H); 
		if(isMapValid(ip3.i, ip3.j) && !isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j])) //!g.world.map.isPassable[ip3.i][ip3.j])
				{ 
				if(vy < 0) // we're moving up, lets not reset jumping yet
					{
//					writeln("1");
					}else{
						// EVENT: floor below us
					isJumping = false;
					isFalling = false; // is there really a distinction here between jumping and falling?
					y = (ip3.j-1)*TILE_H;
					vy = 0;
//					writeln("2 set falling to false");
					}
				}else{
	//			writeln("3 set falling to true");
				isFalling = true;
				vy += FALL_ACCEL;
				}
		y += vy;

		// sideways
		if(vx > 0)
			{
			ipair ip = ipair(this, vx, 0);
			if(isMapValid(ip.i, ip.j) && !isPassableTile(g.world.map.bmpIndex[ip.i][ip.j]))//!g.world.map.isPassable[ip.i][ip.j])
				{
				vx = -WALK_SPEED;
				isFlipped = false;
				//log3.log(this, format("[%s] hit 'right', move left %d,%d", this, ip.i, ip.j));
				//write(format("[%s] hit \"right\", move left %d,%d", this, ip.i, ip.j));
//				writeln("hit right, move left");
				}
			}
		if(vx < 0)
			{
			ipair ip = ipair(this, vx, 0);
			if(isMapValid(ip.i, ip.j) && !isPassableTile(g.world.map.bmpIndex[ip.i][ip.j]))//!g.world.map.isPassable[ip2.i][ip2.j])
				{
				vx = WALK_SPEED;
				isFlipped = true;
				//log3.log(this, format("[%s] hit 'left', move right %d,%d", this, ip.i, ip.j));
//				writeln("hit left, move right");
				}
			}
				
		x += vx;
		if(x < 0){x = 0; vx = -vx; isFlipped=true;}
		if(x >= (g.world.map.width)*TILE_W){x = (g.world.map.width)*TILE_W-1; vx = -vx; isFlipped=true;}
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
	
	this(uint _teamIndex, float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* b)
		{
		myTeamIndex = _teamIndex; 
		super(_x, _y, _vx, _vy, b);
		//writefln("xy v:xy %f,%f %f,%f", x, y, vx, vy);
		}

	override bool draw(viewport v)
		{
		if(!isWideInsideScreen(vpair(this), bmp))return false;
		// NOTE we're drawing with "center" being at the bottom of the image.
		drawBitmap(bmp, vpair(this, -bmp.w/2, 0), isFlipped);
		if(isDebugging) drawTextCenter(vpair(this, 0, -32), black, "J%1dF%1d V%3.1f,%3.1f", isJumping, isFalling, vx, vy);
		
		if(isPlayerControlled) 
			{
			}
	
		draw_hp_bar(x, y - bmp.w/2, v, hp, 100);		
		return true;
		}
	}
