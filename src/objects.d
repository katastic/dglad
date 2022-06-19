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
import structures;
	
//immutable float FALL_ACCEL = .1;
immutable float WALK_SPEED = 2.5;
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

ipair[] soldier_coords = [ipair(0,0), ipair(72,0), ipair(144,0), ipair(217,0), 
					      ipair(288,0), ipair(72+288,0), ipair(144+288,0), ipair(217+288,0)];
ipair[] archer_coords = [ipair(0,70), ipair(72,70), ipair(144,70), ipair(217,70),
						ipair(288,70), ipair(72+288,70), ipair(144+288,70), ipair(217+288,70)];

ipair[] mage_coords = [ipair(0,144), ipair(72,144), ipair(144,144), ipair(217,144),
						ipair(288,144), ipair(72+288,144), ipair(144+288,144), ipair(217+288,144)];

class animation
	{
	BITMAP* atlas;

	void parseMap3(ipair[] pt)
		{
		atlas = getBitmap("./data/extra/gauntlet.png");
		int w = 32;
		int h = 32;
		int wo = w + 4; // width plus padding offset
		bmps[DIR.UP][0] = al_create_sub_bitmap(atlas, pt[0].i, pt[0].j, w, h);
		bmps[DIR.RIGHT][0] = al_create_sub_bitmap(atlas, pt[1].i, pt[1].j, w, h);
		bmps[DIR.DOWN][0] = al_create_sub_bitmap(atlas, pt[2].i, pt[2].j, w, h);
		bmps[DIR.LEFT][0] = al_create_sub_bitmap(atlas, pt[3].i, pt[3].j, w, h);

		bmps[DIR.UP][1] = al_create_sub_bitmap(atlas, pt[4].i, pt[4].j, w, h);
		bmps[DIR.RIGHT][1] = al_create_sub_bitmap(atlas, pt[5].i, pt[5].j, w, h);
		bmps[DIR.DOWN][1] = al_create_sub_bitmap(atlas, pt[6].i, pt[6].j, w, h);
		bmps[DIR.LEFT][1] = al_create_sub_bitmap(atlas, pt[7].i, pt[7].j, w, h);
		}

	// do we want/care to reset walk cycle when you change direction? 
    import std.traits;
	int numDirections; 
	int numFrames=2;
	int index = 0; /// frame index
	bool usesFlippedGraphics = false; /// NYI. use half the sideways graphics and flips them based on direction given. Usually meaningless given RAM amounts.
	BITMAP*[2][DIR.max] bmps;
	
	this(int _numFrames, ipair[] coordinates)
		{
		parseMap3(coordinates);
		writeln("----------21353523521");
		foreach(immutable d; [EnumMembers!DIR])
			{
			writeln(d);
//			bmps[d][0] = new ALLEGRO_BITMAP;
	//		bmps[d][1] = new ALLEGRO_BITMAP;
			}
		}
		
	void nextFrame()
		{
		index++;
		if(index == numFrames)index = 0;
		}
		
	bool draw(pair pos, DIR dir) /// implied viewport
		{
		if(isOnScreen(pos))
			{
			if(!g.useLighting)
			{
				drawCenteredBitmap( bmps[dir][index], vpair(pos), 0);
			}else{
				drawCenteredTintedBitmap( bmps[dir][index], getShadeTint(g.world.units[0].pos, pos), vpair(pos), 0);				
			}
			return true;
		}else{
			return false;}
		}
	}

float toAngle(DIR d)
	{
	switch(d)
		{
		case DIR.RIGHT:
			return degToRad(0);
		break;
		case DIR.DOWN:
			return degToRad(90);
		break;
		case DIR.LEFT:
			return degToRad(180);
		break;
		case DIR.UP:
			return degToRad(270);
		break;
		default:
		break;
		}
	
	assert(0, "fail");	
	}

class archer : unit
	{
	float spinAngle = 0;
	float SPIN_SPEED = degToRad(10);
	int COOLDOWN_TIME = 30;

	bool isSpinning = false;

//	int spinCooldown=0;
	void spin()
		{
		if(!isSpinning && mp > 80)
			{
			mp -= 80; 
	//		spinCooldown = COOLDOWN_TIME;
			spinAngle = 0;
			isSpinning = true;
			freezeMovement = true;
			}
		}

	override void actionSpecial()
		{
		spin();
		}
		
	override void onTick()
		{
		if(isSpinning)
			{
			writefln("%3.2f", spinAngle);
			immutable int NUM_SHOTS = 10;
			if(fmod(spinAngle,2f*PI/NUM_SHOTS) < .1) // fixme: this needs to be different. divide distance into number of shots, and a total time for action so you can adjust that for balance.
				{
				// fireShot();
				g.world.bullets ~= new bullet( this.pos, pair(apair( spinAngle, 10)), spinAngle, red, 100, 0, this, 0);
//	this(pair _pos, pair _vel, float _angle, COLOR _c, int _type, int _lifetime, bool _isAffectedByGravity, unit _myOwner, bool _isDebugging)
				writefln("firing shot at %3.2f", spinAngle);
				}
			spinAngle += SPIN_SPEED;
			if(spinAngle > 2*PI){isSpinning = false; freezeMovement = false; spinAngle = 0;}
			}else{
			super.onTick();
			}
		}

	this(pair _pos)
		{
		super(0, _pos, pair(0, 0), g.dude_bmp);
		anim = new animation(1, archer_coords);
		}
		
	override bool draw(viewport v)
		{
		return anim.draw(this.pos, direction);
		}
	}
	
class mage : unit
	{
	this(pair _pos)
		{
		super(0, _pos, pair(0, 0), g.dude_bmp);
		anim = new animation(1, mage_coords);
		}
		
	override bool draw(viewport v)
		{
		return anim.draw(this.pos, direction);
		}	
	}

class soldier : unit
	{
	float CHARGE_SPEED = 10.0;
	int COOLDOWN_TIME = 30;
	
	this(pair _pos)
		{
		super(0, _pos, pair(0, 0), g.dude_bmp);
		anim = new animation(1, soldier_coords);
		}

	override bool draw(viewport v)
		{
		anim.nextFrame();
		anim.draw(this.pos, direction);
		return true;
		}
	
	int chargeCooldown=0;
	void charge() // "HUURRRLL"
		{
		if(chargeCooldown == 0 && mp > 80)
			{
			mp -= 80; 
			chargeCooldown = COOLDOWN_TIME;
			freezeMovement = true;
			}
		}
	
	override void onTick()
		{
		if(chargeCooldown) // can't do anything except run forward during charge.
			{
			pos += vel;
			chargeCooldown--;
			if(chargeCooldown == 0)freezeMovement = false;
			return;
			}
		super.onTick();
		// normal stuff
		}
	
	override void actionSpecial()
		{
		charge();
		}

	override void actionUp()
		{
		if(chargeCooldown)return;
		vel = apair(toAngle(DIR.UP), CHARGE_SPEED);
		super.actionUp();
		}
	override void actionDown()
		{
		if(chargeCooldown)return;
		vel = apair(toAngle(DIR.DOWN), CHARGE_SPEED);
		super.actionDown();
		}
	override void actionLeft()
		{
		if(chargeCooldown)return;
		vel = apair(toAngle(DIR.LEFT), CHARGE_SPEED);
		super.actionLeft();
		}
	override void actionRight()
		{
		if(chargeCooldown)return;
		vel = apair(toAngle(DIR.RIGHT), CHARGE_SPEED);
		super.actionRight();
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

class unit : baseObject // WARNING: This applies PHYSICS. If you inherit from it, make sure to override if you don't want those physics.
	{
	animation anim;
	float maxHP=100.0; /// Maximum health points
	float hp=100.0; /// Current health points
	float ap=0; /// armor points (reduced on hits then armor breaks)
	float armor=0; /// flat reduction (or percentage) on damages, haven't decided.
	float mp=100;
	float maxMP=100;
	float manaChargeRate = 2;
	int myTeamIndex=0;
	bool isPlayerControlled=false;
	float weapon_damage = 5;
	bool isFlipped = false; // flip horizontal
	bool freezeMovement = false; /// for special abilities/etc. NOT the same as being frozen by a spell or something like that.

	bool attemptMove(pair offset)
		{
		ipair ip3 = ipair(this.pos, offset.x, offset.y); 
//		writeln(this.pos);
//		writeln(ip3);
		if(isMapValid(ip3) && isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j]))
			{
			this.pos += offset;
			return true;
			}else{
			return false;
			}
		}

	void worldClipping()
		{
		if(pos.x < 0){pos.x = 0; vel.x = -vel.x; isFlipped=true;}
		if(pos.x >= (g.world.map.width)*TILE_W){pos.x = (g.world.map.width)*TILE_W-1; vel.x = -vel.x; isFlipped=true;}
		if(pos.y < 0){pos.y = 0; vel.y = -vel.y;}
		if(pos.y >= (g.world.map.height)*TILE_W){pos.y = (g.world.map.height)*TILE_H-1; vel.y = -vel.y;}
		}
	
	void velToDirection(pair v) /// so looking direction follows AI velocity 
		{
		// we don't have diagonals made yet so lets just do left/right
		if(v.x < 0) direction = DIR.LEFT;
		if(v.x > 0) direction = DIR.RIGHT;
		}
	
	void travel()
		{
		pos += vel;
		ipair ip3 = ipair(this.pos); 
		if(isMapValid(ip3) && !isPassableTile(g.world.map.bmpIndex[ip3.i][ip3.j]))
			{
			pos -= vel;	
			pos -= vel;
			vel = 0;
			}else
			{
			if(vel == 0)vel = apair(uniform!"[]"(0, 2*PI), WALK_SPEED); // if we were stuck, then map editor freed us, lets start moving again.
			}
		velToDirection(vel);
		}
	
	override void onTick()
		{			
		if(mp < maxMP)mp += manaChargeRate;			

		if(!isPlayerControlled && !freezeMovement)
			{
			travel();
			}
	
		worldClipping();
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
		drawCenteredBitmap(bmp, vpair(this.pos), isFlipped);
//		if(isDebugging) drawTextCenter(vpair(this, 0, -32), black, "J%1dF%1d V%3.1f,%3.1f", isJumping, isFalling, vx, vy);
		
		if(isPlayerControlled) 
			{
			}
	
		draw_hp_bar(pos.x - bmp.w/2, pos.y - bmp.h/2, v, hp, maxHP);		
		draw_mp_bar(pos.x - bmp.w/2, pos.y - bmp.h/2 + 5, v, mp, maxMP);		
		return true;
		}
	
	override void actionFire()
		{
		g.world.bullets ~= new bullet( this.pos, pair(apair( toAngle(direction), 10)), toAngle(direction), red, 100, 0, this, 0);
		}

	override void actionUp()
		{
		if(!freezeMovement)
			{
			attemptMove(pair(0, -WALK_SPEED));
			direction = DIR.UP;
			} 
		}
		
	override void actionDown()
		{
		if(!freezeMovement)
			{
			attemptMove(pair(0, WALK_SPEED));
			direction = DIR.DOWN;
			}
		}
		
	override void actionLeft()
		{
		if(!freezeMovement)
			{
			attemptMove(pair(-WALK_SPEED, 0));
			direction = DIR.LEFT;
			}
		}
	override void actionRight()
		{
		if(!freezeMovement)
			{
			attemptMove(pair(WALK_SPEED, 0));
			direction = DIR.RIGHT;
			}
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
	DIR direction;
	bool isDebugging=true;

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
	
	// INPUTS 
	// ------------------------------------------
	void actionUp(){}
	void actionDown(){}
	void actionLeft(){}
	void actionRight(){}
	void actionFire(){}
	void actionSpecial(){}
	void actionShifter(){}
	void actionFour(){} // four button controller. find better name when applicable{

	void onTick()
		{
		// THOU. SHALT. NOT. PUT. PHYSICS. IN BASE. baseObject.
		}
	}	
