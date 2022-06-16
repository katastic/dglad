import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.string;
import std.random;
import std.algorithm : remove;
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;

import helper;
import objects;
import viewportsmod;
import graph;
import particles;
import planetsmod;
import bulletsmod;
import mapsmod;

int SCREEN_W = 1360; //not immutable because its a argc config variable
int SCREEN_H = 720;
immutable ushort TILE_W=32;
immutable ushort TILE_H=32;
immutable float SCROLL_SPEED=5;

//ALLEGRO_CONFIG* 		cfg;  //whats this used for?
ALLEGRO_DISPLAY* 		al_display;
ALLEGRO_EVENT_QUEUE* 	queue;
ALLEGRO_TIMER* 			fps_timer;
ALLEGRO_TIMER* 			screencap_timer;

FONT* 	font1;

BITMAP* smoke_bmp;
BITMAP* bullet_bmp;
BITMAP* dude_bmp;
BITMAP* trailer_bmp;
BITMAP* turret_bmp;
BITMAP* turret_base_bmp;

BITMAP* chest_bmp;
BITMAP* chest_open_bmp;
BITMAP* dwarf_bmp;
BITMAP* goblin_bmp;
BITMAP* boss_bmp;
BITMAP* fountain_bmp;
BITMAP* tree_bmp;
BITMAP* wall_bmp;
BITMAP* wall2_bmp;
BITMAP* wall3_bmp;
BITMAP* grass_bmp;
BITMAP* lava_bmp;
BITMAP* water_bmp;
BITMAP* wood_bmp;
BITMAP* stone_bmp;
BITMAP* reinforced_wall_bmp;
BITMAP* sword_bmp;
BITMAP* carrot_bmp;
BITMAP* potion_bmp;
BITMAP* blood_bmp;

intrinsicGraph!float testGraph;
intrinsicGraph!float testGraph2;
intrinsicGraph!float testGraph3;

void loadResources()	
	{
	font1 = getFont("./data/DejaVuSans.ttf", 18);

	bullet_bmp  			= getBitmap("./data/bullet.png");
	smoke_bmp  				= getBitmap("./data/smoke.png");
	bullet_bmp  			= getBitmap("./data/bullet.png");
	dude_bmp	  			= getBitmap("./data/dude.png");
	trailer_bmp	  			= getBitmap("./data/trailer.png");
	turret_bmp	  			= getBitmap("./data/turret.png");
	turret_base_bmp			= getBitmap("./data/turret_base.png");
	
	sword_bmp  			= getBitmap("./data/sword.png");
	carrot_bmp  		= getBitmap("./data/carrot.png");
	potion_bmp  		= getBitmap("./data/potion.png");
	chest_bmp  			= getBitmap("./data/chest.png");
	chest_open_bmp  	= getBitmap("./data/chest_open.png");

	dwarf_bmp  		= getBitmap("./data/dwarf.png");
	goblin_bmp  	= getBitmap("./data/goblin.png");
	boss_bmp 	 	= getBitmap("./data/boss.png");

	wall_bmp  		= getBitmap("./data/wall.png");
	wall2_bmp  		= getBitmap("./data/wall2.png");
	wall3_bmp  		= getBitmap("./data/wall3.png");
	grass_bmp  		= getBitmap("./data/grass.png");
	lava_bmp  		= getBitmap("./data/lava.png");
	water_bmp  		= getBitmap("./data/water.png");
	fountain_bmp  	= getBitmap("./data/fountain.png");
	wood_bmp  		= getBitmap("./data/wood.png");
	stone_bmp  		= getBitmap("./data/brick.png");
	tree_bmp  		= getBitmap("./data/tree.png");
	blood_bmp  		= getBitmap("./data/blood.png");
	reinforced_wall_bmp  	= getBitmap("./data/reinforced_wall.png");	
	}

alias COLOR = ALLEGRO_COLOR;
alias BITMAP = ALLEGRO_BITMAP;
alias FONT = ALLEGRO_FONT;

/// DEBUGGER CHANNEL STUFF
/// - Can any object send to a variety of "channels"?
/// so we only get data from objects marked isDebugging=true,
/// and we can choose to only display certain channels like 
/// movement or finite state machine.


/// Do we need a MAPPING setup? "debug" includes "object,error,info,etc"
enum logChannel : string
	{
	INFO="info",
	ERROR="error",
	DEBUG="debug",
	FSM="FSM"
	}

class pygmentize// : prettyPrinter
	{
	bool hasStreamStarted=false;
	string style="arduino"; // see pygmentize -L for list of installed styles
	string language="SQL"; // you don't necessarily want "D" for console coloring
	// , you could also create your own custom pygments lexer and specify it here
	//see https://github.com/sol/pygments/blob/master/pygments/lexers/c_cpp.py
	
	// this will be "slower" since we're constantly re-running it with all that overhead
	// we might want to do some sort of batch/buffered version to reduce the number
	// of invocations
	string convert(string input)
		{
		stats.swLogging.start();	
		import std.process : spawnProcess, spawnShell, wait;
	/+	auto pid = spawnProcess(["pygmentize", "-l D"],
                        stdin,
                        stdout,
                        logFile);
      +/
		auto pid = spawnShell(`echo "hello(12,12)" | pygmentize -l D`);
		if (wait(pid) != 0)
			writeln("Compilation failed.");

		stats.swLogging.stop();
		stats.msLogging = stats.swLogic.peek.total!"msecs"; // NOTE only need to update this when we actually access it in the stats class
	
		return input;
		}

	import std.process : spawnProcess, spawnShell, wait, ProcessPipes, pipeProcess, Redirect;
	ProcessPipes pipes;

	string convert2(string input)
		{
		stats.swLogging.start();	
		import std.process : spawnProcess, spawnShell, wait;

		auto pid = spawnShell(format(`echo "%s" | pygmentize -l %s -O style=%s`, input, language, style));
		if (wait(pid) != 0)
			writeln("Compilation failed.");
			
		stats.swLogging.stop();
		stats.msLogging = stats.swLogic.peek.total!"msecs"; // NOTE only need to update this when we actually access it in the stats class
	
		return input;
		}
		
	string convert3(string input)
		{
   		stats.swLogging.start();

		if(!hasStreamStarted)
			{
			hasStreamStarted = true;
			string flags = "-s -l d";
			pipes = pipeProcess(
				["pygmentize", "-s", "-l", language, "-O", format("style=%s", style)],
				 Redirect.stdin);
			// https://dlang.org/library/std/process/pipe_process.html
			}

		pipes.stdin.writeln(input);
		pipes.stdin.flush();
		
		g.stats.number_of_log_entries++;
			
		stats.swLogging.stop();
		stats.msLogging = stats.swLogic.peek.total!"msecs"; // NOTE only need to update this when we actually access it in the stats class
	
		return input;
		}

	this()
		{
		}
		
	~this()
		{
		writeln("total stats.msLogging time", stats.msLogging);
		writeln("total log entries", stats.number_of_log_entries);
		if(hasStreamStarted)pipes.stdin.close();
		}
	}
/+
interface prettyPrinter
	{
	string convert(string input);
	string convert2(A...)(A input);
	}
+/
class logger
	{
	bool echoToFile=false;
	bool echoToStandard=false; //stdout
	bool usePrettyPrinter=false; //dump to stdout
	bool usePrettyPrinterDirectly=true; // calls printf itself
	pygmentize printer;
	string[] data;
	string logFilePath;
	
	this(){
		printer = new pygmentize();
		logFilePath = "game.log";
		}
	
	void enableChannel(logChannel channel)
		{
		}

	void disableChannel(logChannel channel)
		{
		}
	
	void log(T)(T obj, string str2)
		{
		if(!obj.isDebugging)return; // If the object isn't set to debug, we ignore it. So we can just set debug flag at will to snoop its data.
		if(echoToStandard)
			writeln(str2);
		if(usePrettyPrinter)
			writeln(printer.convert3(str2));
		if(usePrettyPrinterDirectly)
			printer.convert3(str2);
		}	

	void logB(T, V...)(T obj, V variadic) /// variadic version
		{
		import std.traits;
		pragma(msg, typeof(variadic)); // debug
		foreach(i, v; variadic) // debug
			writeln(variadic[i]); // debug
			
		if(usePrettyPrinterDirectly)
			printer.convert3(format(variadic[0], variadic[1..$]));
		}
	}
	
logger log3;

void testLogger()
	{
	writeln("start------------------");
	log3 = new logger;
	unit u = new unit(0, pair(1, 2), pair(3, 4), g.grass_bmp);
	u.isDebugging = true;
	log3.logB(u, "guy died [%d]", 23);
	log3.log(u, "word(12, 15.0f)");
	writeln("end--------------------");
	}

/+
	ijk		array indicies
	rst  	viewport space coordinates?
	uvw		texture/bitmap space coordinates?
	xyz		world space coordinates? (also confusingly relative coordinates but those are rare?)

	we could do capital XYZ but that's confusing too probably.
+/

void viewTest()
	{
	viewport v = new viewport(0, 0, 640, 480, 100, -100);
	pair p = pair(300, 300);
	
	setViewport2(v);
	
	vpair vp = p.toViewport(v);
	vpair vp2 = p.toViewport2;
	
	writeln(vp);
	writeln(vp2);
	}

vpair toViewport(T)(T point, viewport v)
	{
	return vpair(point.x + v.x - v.ox, point.y + v.y - v.oy);
	}
	
viewport IMPLIED_VIEWPORT;

void setViewport2(viewport v)
	{
	IMPLIED_VIEWPORT = v;
	}

vpair toViewport2(T)(T point)
	{
	assert(IMPLIED_VIEWPORT !is null);
	alias v = IMPLIED_VIEWPORT;
	return vpair(point.x + v.x - v.ox, point.y + v.y - v.oy);
	}

/// WARNING: This can be a 'CONFUSING' construct if you don't enforce it 
///		through understanding:
///
///  - converts world coordinates to viewport coordinates automatically
///	 - IMPLIED_VIEWPORT (an appropriately loud name) must be set beforehand 
///		with setViewport2(viewport); or you'll segfault.
struct vpair
	{
	float r, s;
	
	this(T)(T obj) // warning: this only works if we [ENFORCE] that x and y MEAN world coordinates regardless of object.
		{ // also, why don't we just use a pair for position on objects instead of indivudal x/y's? 
		r = obj.x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = obj.y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}

	this(float _x, float _y)
		{
		r = _x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = _y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;
		}

	this(pair pos)
		{
		r = pos.x + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = pos.y + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}

	this(vpair vpos)
		{
		r = vpos.r;
		s = vpos.s;		
		}

	/// OFFSET constructors:
	///
	/// Usage example:
	///		 drawBitmap(bmp, vpair(this, -30, 0), flags);
	///
	///	have a this.vpair, but then add an offset
	/// build vpair with an offset
	this(vpair vpos, float xOffset, float yOffset)
		{
		r = vpos.r + xOffset;
		s = vpos.s + yOffset;	
		}
		
	/// build vpair with an offset
	this(T)(T obj, float xOffset, float yOffset)
		{
		r = obj.x + xOffset + IMPLIED_VIEWPORT.x - IMPLIED_VIEWPORT.ox;
		s = obj.y + yOffset + IMPLIED_VIEWPORT.y - IMPLIED_VIEWPORT.oy;		
		}
	}

void testthing()
	{
	bool[100][100] isMapPassable;
	ipair ipTest = ipair(50,50);
	ipair(isMapPassable);
//	ip(isMapPassable);
	}

/// An "index" pair. A pair of indicies for referencing an array
/// typically going to be converted 
struct ipair
	{
	int i, j;

	this(int _i, int _j)
		{
		i = _i;
		j = _j;
		}

	this(T)(T[] dim) //multidim arrays still want T[]? interesting
		{
		}

	// WARNING: take note that we're using implied viewport conversions
	this(pair p)
		{
		alias v=IMPLIED_VIEWPORT;
		this = ipair(cast(int)p.x/TILE_W, cast(int)p.y/TILE_H);
		}

	this(pair p, float xOffset, float yOffset)
		{
		alias v=IMPLIED_VIEWPORT;
		this = ipair(cast(int)(p.x+xOffset)/TILE_W, cast(int)(p.y+yOffset)/TILE_H);
		}

	this(T)(T obj, float xOffset, float yOffset)
		{
		alias v=IMPLIED_VIEWPORT;
		this = ipair(cast(int)(obj.pos.x+xOffset)/TILE_W, cast(int)(obj.pos.y+yOffset)/TILE_H);
		}
	}

struct apair
	{
	float a; /// angle
	float m; /// magnitude
	} // idea: some sort of automatic convertion between angle/magnitude, and xy velocities?

struct rpair // relative pair. not sure best way to implement conversions
	{
	float rx; //'rx' to not conflict with x/y duct typing.
	float ry;
	}

struct pair
	{
	float x;
	float y;
	
	this(T)(T t) //give it any object that has fields x and y
		{
		x = t.x;
		y = t.y;
		}

	this(T)(T t, float offsetX, float offsetY)
		{
		x = t.x + offsetX;
		y = t.y + offsetY;
		}
	
	this(int _x, int _y)
		{
		x = to!float(_x);
		y = to!float(_y);
		}

	this(float _x, float _y)
		{
		x = _x;
		y = _y;
		}
	}

world_t world;
viewport[2] viewports;

class player
	{
	int myTeamIndex;
//	int money=1000; //we might have team based money accounts. doesn't matter yet.
	int kills=0;
	int aikills=0;
	int deaths=0;
	
	this()
		{
		}
		
	void onTick()
		{
		}		
	}
	
class team
	{
	int money=0;
	int aikills=0;
	int kills=0;
	int deaths=0;
	COLOR color;
	
	this(player p, COLOR teamColor)
		{
		color = teamColor;
		}
	}
	
alias tile=ushort;
	
class world_t
	{	
	player[] players;
	team[] teams;
				
	unit[] units;
	particle[] particles;
	bullet[] bullets;
	structure[] structures;
	map_t map;

	this()
		{
		viewTest();
		testLogger();	
		
		players ~= new player();
		//structures ~= new structure(100, 100, g.fountain_bmp);
	
		map = new map_t();
		//map.save();
		map.load();
	
		immutable NUM_UNITS = 1_000;
		
		for(int i = 0; i < NUM_UNITS; i++)
			{
			float cx = uniform!"[]"(1, map.width*TILE_W-32);
			float cy = 100;
			auto u = new unit(0, pair(cx, cy),
				pair(uniform(-objects.WALK_SPEED, objects.WALK_SPEED), uniform(-objects.WALK_SPEED, objects.WALK_SPEED))
				, g.dwarf_bmp);
			u.isDebugging = false;
			units ~= u;
			}
			
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
		map.draw(v);

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
		
		drawStat2(bullets, 	stats.number_of_drawn_bullets, 	stats.number_of_drawn_bullets_clipped);
		drawStat2(particles, stats.number_of_drawn_particles, stats.number_of_drawn_particles_clipped);
		drawStat2(units, 	stats.number_of_drawn_units, stats.number_of_drawn_units_clipped);
		drawStat2(structures, stats.number_of_drawn_structures, stats.number_of_drawn_structures_clipped);		

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

		if(key_w_down)viewports[0].oy-=SCROLL_SPEED;
		if(key_s_down)viewports[0].oy+=SCROLL_SPEED;
		if(key_a_down)viewports[0].ox-=SCROLL_SPEED;
		if(key_d_down)viewports[0].ox+=SCROLL_SPEED;
	
		if(key_i_down)map.save();
		if(key_j_down)map.load();
		
		if(key_0_down)mouseSetTile(0);
		if(key_1_down)mouseSetTile(1);
		if(key_2_down)mouseSetTile(2);
		if(key_3_down)mouseSetTile(3);
		if(key_4_down)mouseSetTile(4);
		if(key_5_down)mouseSetTile(5);
		if(key_6_down)mouseSetTile(6);
		if(key_7_down)mouseSetTile(7);
		if(key_8_down)mouseSetTile(8);
		if(key_9_down)mouseSetTile(9);
		/+
		if(key_space_down)players[0].currentShip.actionFire();
		if(key_q_down)players[0].findNextShip();
		
		if(key_i_down)p2.up();
		if(key_k_down)p2.down();
		if(key_j_down)p2.left();
		if(key_l_down)p2.right();
		if(key_m_down)p2.actionFire();
+/
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

struct frameStats_t
	{	
	ulong number_of_drawn_units=0;
	ulong number_of_drawn_particles=0;
	ulong number_of_drawn_structures=0;
	ulong number_of_drawn_asteroids=0;
	ulong number_of_drawn_bullets=0;
	ulong number_of_drawn_dudes=0;

	ulong number_of_drawn_units_clipped=0;
	ulong number_of_drawn_particles_clipped=0;
	ulong number_of_drawn_structures_clipped=0;
	ulong number_of_drawn_asteroids_clipped=0;
	ulong number_of_drawn_bullets_clipped=0;
	ulong number_of_drawn_dudes_clipped=0;
	}

struct statistics_t
	{
	ulong number_of_log_entries=0;
	frameStats_t frameStats;	// per frame statistics
	alias frameStats this;
	
	ulong fps=0;
	ulong frames_passed=0;
	
	StopWatch swLogic;
	StopWatch swDraw;
	StopWatch swLogging; //note this is a CULMULATIVE timer
	float msLogic;  // FIXME why is only one named milliseconds
	float nsDraw;
	float msLogging;
	
	void reset()
		{ 
		// - NOTE: we are ARE resetting these for each viewport so 
		// it CAN be called more than one time a frame!
		// - note we do NOT reset fps and frames_passed here as
		// they are cumulative or handled elsewhere.
		frameStats = frameStats.init; // damn this is easy now!
		}
	}

statistics_t stats;

int mouse_x = 0; //cached, obviously. for helper routines.
int mouse_y = 0;
int mouse_lmb = 0;
int mouse_in_window = 0;
bool key_w_down = false;
bool key_s_down = false;
bool key_a_down = false;
bool key_d_down = false;
bool key_q_down = false;
bool key_e_down = false;
bool key_f_down = false;
bool key_space_down = false;

bool key_i_down = false;
bool key_j_down = false;
bool key_k_down = false;
bool key_l_down = false;
bool key_m_down = false;

bool key_1_down = false;
bool key_2_down = false;
bool key_3_down = false;
bool key_4_down = false;
bool key_5_down = false;
bool key_6_down = false;
bool key_7_down = false;
bool key_8_down = false;
bool key_9_down = false;
bool key_0_down = false;
