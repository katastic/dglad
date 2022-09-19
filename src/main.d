// GLOBAL CONSTANTS
// =============================================================================
immutable bool DEBUG_NO_BACKGROUND = false; /// No graphical background so we draw a solid clear color. Does this do anything anymore?

// =============================================================================

import std.stdio;
import std.conv;
import std.string;
import std.format;
import std.random;
import std.algorithm;
import std.traits; // EnumMembers
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
//thread yielding?
//-------------------------------------------
//import core.thread; //for yield... maybe?
//extern (C) int pthread_yield(); //does this ... work? No errors yet I can't tell if it changes anything...
//------------------------------

pragma(lib, "dallegro5ldc");

version(ALLEGRO_NO_PRAGMA_LIB){}else{
	pragma(lib, "allegro");	// these ARE in fact used.
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
	pragma(lib, "allegro_audio");
	pragma(lib, "allegro_acodec");
	}

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;

import helper;
import objects;
import viewportsmod;
import g;
import mapsmod;
import audiomod;

display_t display;

//=============================================================================

bool initialize()
	{
	al_set_config_value(al_get_system_config(), "trace", "level", "info"); // enable logging. see https://github.com/liballeg/allegro5/issues/1339
	// "debug"
	if (!al_init())
		{
		auto ver 		= al_get_allegro_version();
		auto major 		= ver >> 24;
		auto minor 		= (ver >> 16) & 255;
		auto revision 	= (ver >> 8) & 255;
		auto release 	= ver & 255;

		writefln("The system Allegro version (%s.%s.%s.%s) does not match the version of this binding (%s.%s.%s.%s)",
			major, minor, revision, release,
			ALLEGRO_VERSION, ALLEGRO_SUB_VERSION, ALLEGRO_WIP_VERSION, ALLEGRO_RELEASE_NUMBER);

		assert(0, "The system Allegro version does not match the version of this binding!");
		}else{
				writefln("The Allegro version (%s.%s.%s.%s)",
			ALLEGRO_VERSION, ALLEGRO_SUB_VERSION, ALLEGRO_WIP_VERSION, ALLEGRO_RELEASE_NUMBER);
		}
	
static if (false) // MULTISAMPLING. Not sure if helpful.
	{
	with (ALLEGRO_DISPLAY_OPTIONS)
		{
		al_set_new_display_option(ALLEGRO_SAMPLE_BUFFERS, 1, ALLEGRO_REQUIRE);
		al_set_new_display_option(ALLEGRO_SAMPLES, 8, ALLEGRO_REQUIRE);
		}
	}

	al_display 	= al_create_display(g.SCREEN_W, g.SCREEN_H);
	queue		= al_create_event_queue();

	if (!al_install_keyboard())      assert(0, "al_install_keyboard failed!");
	if (!al_install_mouse())         assert(0, "al_install_mouse failed!");
	if (!al_init_image_addon())      assert(0, "al_init_image_addon failed!");
	if (!al_init_font_addon())       assert(0, "al_init_font_addon failed!");
	if (!al_init_ttf_addon())        assert(0, "al_init_ttf_addon failed!");
	if (!al_init_primitives_addon()) assert(0, "al_init_primitives_addon failed!");

	audio = new audioSystem();
	audio.initialize();
	
	al_register_event_source(queue, al_get_display_event_source(al_display));
	al_register_event_source(queue, al_get_keyboard_event_source());
	al_register_event_source(queue, al_get_mouse_event_source());
	
	with(ALLEGRO_BLEND_MODE)
		{
		al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA);
		}
				
	// load animations/etc
	// --------------------------------------------------------
	g.loadResources();

	// SETUP viewports
	// --------------------------------------------------------
	g.viewports[0] = new viewport(0, 0, g.SCREEN_W, g.SCREEN_H, 0, 0);

	// SETUP world
	// --------------------------------------------------------
	g.world = new g.world_t;
	g.world.initialize();
	
	// FPS Handling
	// --------------------------------------------------------
	fps_timer 		= al_create_timer(1.0f);
	screencap_timer = al_create_timer(7.5f);
	al_register_event_source(queue, al_get_timer_event_source(fps_timer));
	al_register_event_source(queue, al_get_timer_event_source(screencap_timer));
	al_start_timer(fps_timer);
	al_start_timer(screencap_timer);
	
	return 0;
	}
	
struct display_t
	{
	void startFrame()	
		{
		g.stats.reset();
		resetClipping(); //why would we need this? One possible is below! To clear to color the whole screen!
		al_clear_to_color(ALLEGRO_COLOR(0,0,0,1)); //only needed if we aren't drawing a background
		}
		
	void endFrame()
		{	
		al_flip_display();
		}

	void drawFrame()
		{
		startFrame();
		//------------------
		draw2();
		//------------------
		endFrame();
		}

	void resetClipping()
		{
		al_set_clipping_rectangle(0, 0, g.SCREEN_W-1, g.SCREEN_H-1);
		}
		
	void draw2()
		{
		
	static if(true) //draw left viewport
		{
		al_set_clipping_rectangle(
			g.viewports[0].x, 
			g.viewports[0].y, 
			g.viewports[0].x + g.viewports[0].w ,  //-1
			g.viewports[0].y + g.viewports[0].h); //-1
		
		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(0, 0, 0, 1));
		
		g.world.draw(g.viewports[0]);
		}

	static if(false) //draw right viewport
		{
		al_set_clipping_rectangle(
			g.viewports[1].x, 
			g.viewports[1].y, 
			g.viewports[1].x + g.viewports[1].w  - 1, 
			g.viewports[1].y + g.viewports[1].h - 1);

		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(.8,.7,.7, 1));

		g.world.draw(g.viewports[1]);
		}
		
		//Viewport separator
	static if(false)
		{
		al_draw_line(
			g.SCREEN_W/2 + 0.5, 
			0 + 0.5, 
			g.SCREEN_W/2 + 0.5, 
			g.SCREEN_H + 0.5,
			al_map_rgb(0,0,0), 
			10);
		}
		
		// Draw FPS and other text
		display.resetClipping();
		
		float last_position_plus_one = textHelper(false); // we use the auto-intent of one initial frame to find the total text length for the box
		textHelper(true);  //reset

		al_draw_filled_rounded_rectangle(16, 32, 64+650, last_position_plus_one+32, 8, 8, ALLEGRO_COLOR(.7, .7, .7, .7));

		unit u = g.world.units[0];
		drawText2(20, "obj[%.2f,%.2f][%.2f %.2f]", u.pos.x, u.pos.y, u.vel.x, u.vel.y);
		drawText2(20, "fps[%d] objrate[%d]", g.stats.fps, 
					(g.stats.number_of_drawn_particles[0] +
					g.stats.number_of_drawn_units[0] + 
					g.stats.number_of_drawn_particles[0] + 
					g.stats.number_of_drawn_bullets[0] + 
					g.stats.number_of_drawn_structures[0]) * g.stats.fps ); 
		
//		drawText2(20, "money [%d] deaths [%d]", g.world.players[0].myTeamIndex.money, g.world.players[0].deaths);
		drawText2(20, "drawn  : structs [%d] particles [%d] bullets [%d] units [%d]", 
			g.stats.number_of_drawn_structures[0], 
			g.stats.number_of_drawn_particles[0],
			g.stats.number_of_drawn_bullets[0],
			g.stats.number_of_drawn_units[0]);

		drawText2(20, "clipped: structs [%d] particles [%d] bullets [%d] units [%d]", 
			g.stats.number_of_drawn_structures[1], 
			g.stats.number_of_drawn_particles[1],
			g.stats.number_of_drawn_bullets[1],
			g.stats.number_of_drawn_units[1]);

		float ifNotZeroPercent(T)(T stat)
			{
			if(stat[0] + stat[1] == 0)
				return 100;
			else
				return cast(float)stat[1] / (cast(float)stat[0] + cast(float)stat[1]) * 100.0;
			}

		with(g.stats)
			{
		drawText2(20, "percent: structs [%3.1f%%] particles [%3.1f%%] bullets [%3.1f%%] units [%3.1f%%]", 
			ifNotZeroPercent(number_of_drawn_structures), 
			ifNotZeroPercent(number_of_drawn_particles), 
			ifNotZeroPercent(number_of_drawn_bullets),
			ifNotZeroPercent(number_of_drawn_units));
			}
		
		draw_target_dot(g.mouse_x, g.mouse_y);		// DRAW MOUSE PIXEL HELPER/FINDER

		int val = -1;
		int val2 = -1;
		int i = (g.mouse_x + cast(int)g.viewports[0].ox + cast(int)g.viewports[0].x)/TILE_W;
		int j = (g.mouse_y + cast(int)g.viewports[0].oy + cast(int)g.viewports[0].x)/TILE_H;
		if(i >= 0 && j >= 0
			&& i < g.world.map.width && j < g.world.map.height)
			{
			val = isPassableTile(g.world.map.bmpIndex[i][j]);
			val2 = g.world.map.bmpIndex[i][j];
			}
					
		al_draw_textf(
			g.font1, 
			ALLEGRO_COLOR(0, 0, 0, 1), 
			g.mouse_x, 
			g.mouse_y - 30, 
			ALLEGRO_ALIGN_CENTER, "mouse [%d, %d] = isPassable[%d] bmpIndex[%d]", g.mouse_x, g.mouse_y, val, val2);
		}
	}

void logic()
	{
	g.world.logic();
	}

void mouseLeft()
	{
	if(isMouseInsideMap())
		{
		viewport v = g.viewports[0]; // fixme
		int i = cast(int)(mouse_x - v.x + v.ox)/TILE_W;	// clear redundency here with isMouseInsideMap
		int j = cast(int)(mouse_y - v.y + v.oy)/TILE_H; // more of a code repeating than performance issue though.
		g.world.map.isPassable[i][j] = true;
		g.world.map.bmpIndex[i][j] = 0;
		}
	}
	
void mouseRight()
	{
	if(isMouseInsideMap())
		{
		viewport v = g.viewports[0]; // fixme
		int i = cast(int)(mouse_x - v.x + v.ox)/TILE_W;
		int j = cast(int)(mouse_y - v.y + v.oy)/TILE_H;
		g.world.map.isPassable[i][j] = false;
		g.world.map.bmpIndex[i][j] = 1;
		}
	}

void execute()
	{
	ALLEGRO_EVENT event;
		
	bool isKey(ALLEGRO_KEY key)
		{
		// captures: event.keyboard.keycode
		return (event.keyboard.keycode == key);
		}

	void isKeySet(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = true;
			}
		}
	void isKeyRel(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = false;
			}
		}
		
	bool exit = false;
	while(!exit)
		{
		while(al_get_next_event(queue, &event))
			{
			switch(event.type)
				{
				case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
					exit = true;
					break;
					}
				case ALLEGRO_EVENT_KEY_DOWN:
					{						
					isKeySet(KEY_ESCAPE, exit);
					keyPressed[event.keyboard.keycode] = true;
					break;
					}
					
				case ALLEGRO_EVENT_KEY_UP:				
					{
					keyPressed[event.keyboard.keycode] = false;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_AXES:
					{
					g.mouse_x = event.mouse.x;
					g.mouse_y = event.mouse.y;
					g.mouse_in_window = true;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
					{
					writeln("mouse enters window");
					g.mouse_in_window = true;
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
					{
					writeln("mouse left window");
					g.mouse_in_window = false;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					{
					if(!g.mouse_in_window)break;
					
					if(event.mouse.button == 1)mouseLeft();
					if(event.mouse.button == 2)mouseRight();
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
					{
					g.mouse_lmb = false;
					break;
					}
				
				case ALLEGRO_EVENT_TIMER:
					{
					if(event.timer.source == screencap_timer)
						{
						al_stop_timer(screencap_timer); // Do this FIRST so inner code cannot take so long as to re-trigger timers.
						writeln("saving screenshot [screen.png]");
						al_save_screen("screen.png");	
//	auto sw = StopWatch(AutoStart.yes);
//						al_save_bitmap("screen.png", al_get_backbuffer(al_display));
//				sw.stop();
//	int secs, msecs;
//	sw.peek.split!("seconds", "msecs")(secs, msecs);
//	writefln("Saving screenshot took %d.%ds", secs, msecs);
			}						
					if(event.timer.source == fps_timer) //ONCE per second
						{
						g.stats.fps = g.stats.frames_passed;
						g.stats.frames_passed = 0;
						}
					break;
					}
				default:
				}
			}

		logic();
		display.drawFrame();
		g.stats.frames_passed++;
//		Fiber.yield();  // THIS SEGFAULTS. I don't think this does what I thought.
//		pthread_yield(); //doesn't seem to change anything useful here. Are we already VSYNC limited to 60 FPS?
		}
	}

void shutdown() 
	{
		
	}
	
void setupFloatingPoint()
	{
	import std.compiler : vendor, Vendor;
//	static if(vendor == Vendor.digitalMars)
		{
		import std.math.hardware : FloatingPointControl;
		FloatingPointControl fpctrl;
		fpctrl.enableExceptions(FloatingPointControl.severeExceptions);
		}
	// enables hardware trap exceptions on uninitialized floats (NaN), (I would imagine) division by zero, etc.
	// see 
	// 		https://dlang.org/library/std/math/hardware/floating_point_control.html
	// we could disable this on [release] mode if necessary for performance
	
	// LDC2 reports
	//   module hardware is in file 'std/math/hardware.d' which cannot be read

	}

//=============================================================================
int main(string [] args)
	{
	setupFloatingPoint();
	writeln("args length = ", args.length);
	foreach(size_t i, string arg; args)
		{
		writeln("[",i, "] ", arg);
		}
		
	if(args.length > 2)
		{
		g.SCREEN_W = to!int(args[1]);
		g.SCREEN_H = to!int(args[2]);
		writeln("New resolution is ", g.SCREEN_W, "x", g.SCREEN_H);
		}

	return al_run_allegro(
		{
		initialize();
		execute();
		shutdown();
		return 0;
		});

	return 0;
	}
