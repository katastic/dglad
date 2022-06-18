import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.string;
import std.format;
import std.math;
import std.random;
import std.conv;
import viewportsmod;
import g;
import objects;
import planetsmod;

import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;

 // <--- older keyboard code
// ----------------------------------------------------------------------------------
//https://www.allegro.cc/manual/5/keyboard.html
//	(instead of individual KEYS touching ANY OBJECT METHOD. Because what if we 
// 		change objects? We have to FIND all keys associated with that object and 
// 		change them.)
alias ALLEGRO_KEY = ubyte;
struct keyset_t
		{
		baseObject obj;
		ALLEGRO_KEY [ __traits(allMembers, keys_label).length] key;
		// If we support MOUSE clicks, we could simply attach a MOUSE in here 
		// and have it forward to the object's click_on() method.
		// But again, that kills the idea of multiplayer.
		}
		
enum keys_label
	{
	ERROR = 0,
	UP_KEY,
	DOWN_KEY,
	LEFT_KEY,
	RIGHT_KEY,
	FIRE_UP_KEY,
	FIRE_DOWN_KEY,
	FIRE_LEFT_KEY,
	FIRE_RIGHT_KEY,
	ACTION_KEY
	}
// ----------------------------------------------------------------------------------

/+
 see (d) allegro5/keycodes.d

	converted ALLEGRO_KEY ALLEGRO_KEY_X to
	ALLEGRO_KEY KEY_X
	because that's incredibly needlessly redundant and verbose. How could you
    possibly mistake say, KEY_X, for anything but a keyboard key in videogame code?
   
   it also reduces on the text length of code making it easier to read
+/
// ---------------------------------------------------------------------------------------------------
	ALLEGRO_KEY KEY_A      = 1;
	ALLEGRO_KEY KEY_B      = 2;
	ALLEGRO_KEY KEY_C      = 3;
	ALLEGRO_KEY KEY_D      = 4;
	ALLEGRO_KEY KEY_E      = 5;
	ALLEGRO_KEY KEY_F      = 6;
	ALLEGRO_KEY KEY_G      = 7;
	ALLEGRO_KEY KEY_H      = 8;
	ALLEGRO_KEY KEY_I      = 9;
	ALLEGRO_KEY KEY_J      = 10;
	ALLEGRO_KEY KEY_K      = 11;
	ALLEGRO_KEY KEY_L      = 12;
	ALLEGRO_KEY KEY_M      = 13;
	ALLEGRO_KEY KEY_N      = 14;
	ALLEGRO_KEY KEY_O      = 15;
	ALLEGRO_KEY KEY_P      = 16;
	ALLEGRO_KEY KEY_Q      = 17;
	ALLEGRO_KEY KEY_R      = 18;
	ALLEGRO_KEY KEY_S      = 19;
	ALLEGRO_KEY KEY_T      = 20;
	ALLEGRO_KEY KEY_U      = 21;
	ALLEGRO_KEY KEY_V      = 22;
	ALLEGRO_KEY KEY_W      = 23;
	ALLEGRO_KEY KEY_X      = 24;
	ALLEGRO_KEY KEY_Y      = 25;
	ALLEGRO_KEY KEY_Z      = 26;

	ALLEGRO_KEY KEY_0      = 27;
	ALLEGRO_KEY KEY_1      = 28;
	ALLEGRO_KEY KEY_2      = 29;
	ALLEGRO_KEY KEY_3      = 30;
	ALLEGRO_KEY KEY_4      = 31;
	ALLEGRO_KEY KEY_5      = 32;
	ALLEGRO_KEY KEY_6      = 33;
	ALLEGRO_KEY KEY_7      = 34;
	ALLEGRO_KEY KEY_8      = 35;
	ALLEGRO_KEY KEY_9      = 36;

	ALLEGRO_KEY KEY_PAD_0      = 37;
	ALLEGRO_KEY KEY_PAD_1      = 38;
	ALLEGRO_KEY KEY_PAD_2      = 39;
	ALLEGRO_KEY KEY_PAD_3      = 40;
	ALLEGRO_KEY KEY_PAD_4      = 41;
	ALLEGRO_KEY KEY_PAD_5      = 42;
	ALLEGRO_KEY KEY_PAD_6      = 43;
	ALLEGRO_KEY KEY_PAD_7      = 44;
	ALLEGRO_KEY KEY_PAD_8      = 45;
	ALLEGRO_KEY KEY_PAD_9      = 46;

	ALLEGRO_KEY KEY_F1      = 47;
	ALLEGRO_KEY KEY_F2      = 48;
	ALLEGRO_KEY KEY_F3      = 49;
	ALLEGRO_KEY KEY_F4      = 50;
	ALLEGRO_KEY KEY_F5      = 51;
	ALLEGRO_KEY KEY_F6      = 52;
	ALLEGRO_KEY KEY_F7      = 53;
	ALLEGRO_KEY KEY_F8      = 54;
	ALLEGRO_KEY KEY_F9      = 55;
	ALLEGRO_KEY KEY_F10      = 56;
	ALLEGRO_KEY KEY_F11      = 57;
	ALLEGRO_KEY KEY_F12      = 58;

	ALLEGRO_KEY KEY_ESCAPE   = 59;
	ALLEGRO_KEY KEY_TILDE      = 60;
	ALLEGRO_KEY KEY_MINUS      = 61;
	ALLEGRO_KEY KEY_EQUALS   = 62;
	ALLEGRO_KEY KEY_BACKSPACE   = 63;
	ALLEGRO_KEY KEY_TAB      = 64;
	ALLEGRO_KEY KEY_OPENBRACE   = 65;
	ALLEGRO_KEY KEY_CLOSEBRACE   = 66;
	ALLEGRO_KEY KEY_ENTER      = 67;
	ALLEGRO_KEY KEY_SEMICOLON   = 68;
	ALLEGRO_KEY KEY_QUOTE      = 69;
	ALLEGRO_KEY KEY_BACKSLASH   = 70;
	ALLEGRO_KEY KEY_BACKSLASH2   = 71; /* DirectInput calls this DIK_OEM_102: "< > | on UK/Germany keyboards" */
	ALLEGRO_KEY KEY_COMMA      = 72;
	ALLEGRO_KEY KEY_FULLSTOP   = 73;
	ALLEGRO_KEY KEY_SLASH      = 74;
	ALLEGRO_KEY KEY_SPACE      = 75;

	ALLEGRO_KEY KEY_INSERT   = 76;
	ALLEGRO_KEY KEY_DELETE   = 77;
	ALLEGRO_KEY KEY_HOME      = 78;
	ALLEGRO_KEY KEY_END      = 79;
	ALLEGRO_KEY KEY_PGUP      = 80;
	ALLEGRO_KEY KEY_PGDN      = 81;
	ALLEGRO_KEY KEY_LEFT      = 82;
	ALLEGRO_KEY KEY_RIGHT      = 83;
	ALLEGRO_KEY KEY_UP      = 84;
	ALLEGRO_KEY KEY_DOWN      = 85;

	ALLEGRO_KEY KEY_PAD_SLASH   = 86;
	ALLEGRO_KEY KEY_PAD_ASTERISK   = 87;
	ALLEGRO_KEY KEY_PAD_MINUS   = 88;
	ALLEGRO_KEY KEY_PAD_PLUS   = 89;
	ALLEGRO_KEY KEY_PAD_DELETE   = 90;
	ALLEGRO_KEY KEY_PAD_ENTER   = 91;

	ALLEGRO_KEY KEY_PRINTSCREEN   = 92;
	ALLEGRO_KEY KEY_PAUSE      = 93;
// ---------------------------------------------------------------------------------------------------

COLOR white  = COLOR(1,1,1,1);
COLOR black  = COLOR(0,0,0,1);
COLOR red    = COLOR(1,0,0,1);
COLOR green  = COLOR(0,1,0,1);
COLOR blue   = COLOR(0,0,1,1);
COLOR yellow = COLOR(1,1,0,1);
COLOR orange = COLOR(1,0.65,0,1);

//mixin template grey(T)(T w)
	//{
	//COLOR(w, w, w, 1);
	//}

/// This function corrects a bug/error/oversight in al_save_bitmap that dumps ALPHA channel from the screen into the picture
///
void al_save_screen(string path)
	{
	auto sw = StopWatch(AutoStart.yes);
	auto disp = al_get_backbuffer(al_display);
	auto w = disp.w;
	auto h = disp.h;
	ALLEGRO_BITMAP* temp = al_create_bitmap(w, h);
	al_lock_bitmap(temp, al_get_bitmap_format(temp), ALLEGRO_LOCK_WRITEONLY);
	al_lock_bitmap(disp, al_get_bitmap_format(temp), ALLEGRO_LOCK_READONLY); // makes HUGE difference (6.4 seconds vs 270 milliseconds)
	al_set_target_bitmap(temp);
//	al_clear_to_color(ALLEGRO_COLOR(0,0,0,1));
//	al_draw_bitmap(disp, 0, 0, 0);
	for(int j = 0; j < h; j++)
		for(int i = 0; i < w; i++)
			{
			auto pixel = al_get_pixel(disp, i, j);
			pixel.a = 1.0; // remove alpha
			al_put_pixel(i, j, pixel);
			}
	al_unlock_bitmap(disp);
	al_unlock_bitmap(temp);
	al_save_bitmap(path.toStringz, temp);
	al_reset_target();
	al_destroy_bitmap(temp);
	
	sw.stop();
	int secs, msecs;
	sw.peek.split!("seconds", "msecs")(secs, msecs);
	writefln("Saving screenshot took %d.%ds", secs, msecs);
	}

void tick(T)(ref T obj)
	{
	foreach(ref o; obj)
		{
		o.onTick();
		}
	}

//prune ready-to-delete entries (copied from g)
void prune(T)(ref T obj)
	{
	import std.algorithm : remove;
	for(size_t i = obj.length ; i-- > 0 ; )
		{
		if(obj[i].isDead)obj = obj.remove(i); continue;
		}
	//see https://forum.dlang.org/post/sagacsjdtwzankyvclxn@forum.dlang.org
	}

pair deViewport(pair p, viewport v)
	{
	pair p2 = pair(p.x + v.x - v.ox, p.y + v.y - v.oy);
	return p2;
	}

/// Draws a rectangle but it's missing the inside of lines. Currently just top left and bottom right corners.
void drawSplitRectangle(pair ul, pair lr, float legSize, float thickness, COLOR c)
	{
	// upper left
	al_draw_line(ul.x, ul.y, ul.x + legSize, ul.y, c, thickness); // horizontal
	al_draw_line(ul.x, ul.y, ul.x, ul.y + legSize, c, thickness); // vertical
	
	// lower right
	al_draw_line(lr.x, lr.y, lr.x - legSize, lr.y, c, thickness); // horizontal
	al_draw_line(lr.x, lr.y, lr.x, lr.y - legSize, c, thickness); // vertical
	}

/// Draw text using most common settings
void drawText(A...)(float x, float y, COLOR c, string formatStr, A a)
	{
	al_draw_text(g.font1, c, x, y, ALLEGRO_ALIGN_LEFT, format(formatStr, a).toStringz); 
	}

/// Draw text using most common settings
void drawTextCenter(A...)(float x, float y, COLOR c, string formatStr, A a)
	{
	al_draw_text(g.font1, c, x, y, ALLEGRO_ALIGN_CENTER, format(formatStr, a).toStringz); 
	}

/// Draw text using most common settings /w vpair
void drawTextCenter(A...)(vpair pos, COLOR c, string formatStr, A a)
	{
	al_draw_text(g.font1, c, pos.r, pos.s, ALLEGRO_ALIGN_CENTER, format(formatStr, a).toStringz); 
	}

/// Draw text with help of textHelper auto-indenting
void drawText2(A...)(float x, string formatStr, A a)
	{
	al_draw_text(g.font1, ALLEGRO_COLOR(0, 0, 0, 1), x, textHelper(), ALLEGRO_ALIGN_LEFT, format(formatStr, a).toStringz); 
	}	
	
/// Draw a shield! ring
void drawShield(pair pos, viewport v, float radius, float thickness, COLOR c, float shieldCoefficent)
	{
	al_draw_circle(pos.x + v.x - v.ox, pos.y + v.y - v.oy, radius, COLOR(0,0,.5,.50), thickness*shieldCoefficent);	
	al_draw_circle(pos.x + v.x - v.ox, pos.y + v.y - v.oy, radius, COLOR(0,0,1,1), thickness*shieldCoefficent*.50);	
	}

// TODO: does this track viewport offset or not?!
void drawAngleHelper(baseObject o, viewport v, float angle, float distance, ALLEGRO_COLOR color)
	{
	float cx = cos(angle)*distance;
	float cy = sin(angle)*distance;
	al_draw_line(
		o.pos.x + v.x - v.ox, 
		o.pos.y + v.y - v.oy, 
		o.pos.x + cx + v.x - v.ox, 
		o.pos.y + cy + v.y - v.oy, 
		color, 1);
	}

float radToDeg(T)(T angle)
	{
	return angle/(2.0*PI)*360.0;
	}

float degToRad(T)(T angle)
	{
	return angle*(2.0*PI)/360.0;
	}
	
void testRad()
	{
	for(int i = 0; i < 10; i++)
		{
		double x = -2*PI -.5 + .1*i;
		writeln(x, " ", wrapRad(x));
		}
	}
	
T wrapRad(T)(T angle)
	{
	if(angle >= 0)
		angle = fmod(angle, 2.0*PI);
	else
		angle += 2.0*PI;
		angle = fmod(angle, 2.0*PI);
			// everyone does this. What if angle is more than 360 negative though?
			// it'll be wrong. though a few more "hits" though this function and it'll be fixed.
			// otherwise, we could do a while loop but is that slower even when we don't need it?
			// either find the answer or stop caring.
	
	////	writeln(fmod(angle, 2.0*PI).radToDeg);
	//while(angle > 2*PI)angle -= 2*PI;
	//while(angle < 0)angle += 2*PI;
	return angle;
	}

void wrapRadRef(T)(ref T angle)
	{
	angle = fmod(angle, 2.0*PI);
	}

/// angleTo:		angleTo (This FROM That)
///
/// Get angle to anything that has an x and y coordinate fields
/// 	Cleaner:	float angle = angleTo(this, g.world.units[0]);
///  	Verses :	float angle = atan2(y - g.world.units[0].y, x - g.world.units[0].x);
float angleTo(T, U)(T _this, U fromThat) 
	{
	return atan2(_this.y - fromThat.y, _this.x - fromThat.x).wrapRad;
	}

float angleDiff(T)(T _thisAngle, T toThatAngle)
	{
	return abs(_thisAngle - toThatAngle);
	}

/// modified from https://stackoverflow.com/questions/28036652/finding-the-shortest-distance-between-two-angles
float angleDiff2( double angle1, double angle2 )
	{
	//δ=(T−C+540°)mod360°−180°
	return (angle2 - angle1 + 540.degToRad) % 2*PI - PI;
	}

float distanceTo(T, U)(T t, U u)
	{
	return sqrt((u.x - t.x)^^2 + (u.y - t.y)^^2);
	}
	
float distance(float x, float y)
	{
	return sqrt(x*x + y*y);
	}

/// 2D array width/height helpers
size_t w(T)(T[][] array2d)
	{
	array2d[0].length;
	}

/// Ditto
size_t h(T)(T[][] array2d)
	{
	array2d.length;
	}

//	writeln(array.length); // 10, h
//	writeln(array[0].length); // 5, w

bool isMouseInsideMap() /// NOTE: uses global context (obviously, no function arguments)
	{
	viewport v = g.viewports[0];
	int i = cast(int)(mouse_x - v.x + v.ox)/TILE_W;
	int j = cast(int)(mouse_y - v.y + v.oy)/TILE_H;
	if(i >= 0 && j >= 0)
	if(i < g.world.map.width && j < g.world.map.height)
		{
		return true;
		}
	return false;
	}

void mouseSetTile(ushort number)
	{
	if(isMouseInsideMap())
		{
		viewport v = g.viewports[0]; // fixme
		int i = cast(int)(mouse_x - v.x + v.ox)/TILE_W;	// clear redundency here with isMouseInsideMap
		int j = cast(int)(mouse_y - v.y + v.oy)/TILE_H; // more of a code repeating than performance issue though.
		
		if(number == 0 || number == 1 || number == 3 || number == 4) 
			{
			g.world.map.isPassable[i][j] = true;
			}else{
			g.world.map.isPassable[i][j] = false;
			}
		
		g.world.map.bmpIndex[i][j] = number;
		}
	}

// Graphical helper functions
//=============================================================================
/// For bitmap culling. Is this point inside the screen?
bool isInsideScreen(float x, float y, viewport v) 
	{
	if(x > 0 && x < v.w && y > 0 && y < v.h)
		{return true;} else{ return false;}
	}
/// For bitmap culling. Is this point inside the screen? using implied viewport
bool isInsideScreen(float x, float y) 
	{
	alias v=IMPLIED_VIEWPORT;
	if(x > 0 && x < v.w && y > 0 && y < v.h)
		{return true;} else{ return false;}
	}

/// Same as above but includes a bitmaps width/height instead of a single point
bool isWideInsideScreen(float x, float y, ALLEGRO_BITMAP* b, viewport v) 
	{
	if(x >= -b.w/2 && x - b.w/2 < v.w && y - b.h/2 >= -b.w/2 && y < v.h)
		{return true;} else{ return false;} //fixme
	}

/// Same as above but includes a bitmaps width/height instead of a single point, using implied viewport
bool isWideInsideScreen(float x, float y, ALLEGRO_BITMAP* b) 
	{
	alias v=IMPLIED_VIEWPORT;
	if(x >= -b.w/2 && x - b.w/2 < v.w && y - b.h/2 >= -b.w/2 && y < v.h)
		{return true;} else{ return false;} //fixme
	}

/// Same as above but includes a bitmaps width/height instead of a single point, using implied viewport and vpair
bool isWideInsideScreen(vpair p, ALLEGRO_BITMAP* b) 
	{
	alias v=IMPLIED_VIEWPORT;
	if(p.r >= -b.w/2 && p.r - b.w/2 < v.w && p.s - b.h/2 >= -b.w/2 && p.s < v.h)
		{return true;} else{ return false;} //fixme
	}

/*
//inline this? or template...
void draw_target_dot(pair xy)
	{
	draw_target_dot(xy.x, xy.y);
	}
*/
void draw_target_dot(float x, float y)
	{
	draw_target_dot(to!(int)(x), to!(int)(y));
	}

void draw_target_dot(int x, int y)
	{
	al_draw_pixel(x + 0.5, y + 0.5, al_map_rgb(0,1,0));

	immutable r = 2; //radius
	al_draw_rectangle(x - r + 0.5f, y - r + 0.5f, x + r + 0.5f, y + r + 0.5f, al_map_rgb(0,1,0), 1);
	}

/// For each call, this increments and returns a new Y coordinate for lower text.
int textHelper(bool doReset=false)
	{
	static int number_of_entries = -1;
	
	number_of_entries++;
	immutable int text_height = 20;
	immutable int starting_height = 20;
	
	if(doReset)number_of_entries = 0;
	
	return starting_height + text_height*number_of_entries;
	}

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

void draw_hp_bar(float x, float y, viewport v, float hp, float max)
	{
	float _x = x;
	float _y = y - 10;
	float _hp = hp/max*20.0;

//	if(hp != max)
		al_draw_filled_rectangle(
			_x - 20/2 + v.x - v.ox, 
			_y + v.y - v.oy, 
			_x + _hp/2  + v.x - v.ox, 
			_y + 5 + v.y - v.oy, 
			ALLEGRO_COLOR(1, 0, 0, 0.70));
	}

void draw_mp_bar(float x, float y, viewport v, float hp, float max)
	{
	float _x = x;
	float _y = y - 10;
	float _hp = hp/max*20.0;

//	if(hp != max)
		al_draw_filled_rectangle(
			_x - 20/2 + v.x - v.ox, 
			_y + v.y - v.oy, 
			_x + _hp/2  + v.x - v.ox, 
			_y + 5 + v.y - v.oy, 
			ALLEGRO_COLOR(0, 0, 1, 0.70));
	}

// Helper functions
//=============================================================================

bool percent(float chance)
	{
	return uniform!"[]"(0.0, 100.0) < chance;
	}

// TODO Fix naming conflict here. This series returns the value. The other works by 
// reference
/+
	capLow		(non-reference versions)
	
		capRefLow?	(reference versions)
		rCapLow	
		refCapLow
	
	also is cap ambiguous? I like that it's smaller than 'clamp'
		cap:
			verb
				2.provide a fitting climax or conclusion to.
+/

T capHigh(T)(T val, T max)
	{
	if(val > max)
		{
		return max;
		}else{
		return val;
		}
	}	
// Ditto.
T capLow(T)(T val, T max)
	{
	if(val < max)
		{
		return max;
		}else{
		return val;
		}
	}	
// Ditto.
T capBoth(T)(T val, T min, T max)
	{
	assert(min < max);
	if(val < max)
		{
		val = max;
		}
	if(val > min)
		{
		val = min;
		}
	return val;
	}	

// can't remember the best name for this. How about clampToMax? <-----
void clampHigh(T)(ref T val, T max)
	{
	if(val > max)
		{
		val = max;
		}
	}	

void clampLow(T)(ref T val, T min)
	{
	if(val < min)
		{
		val = min;
		}
	}	

void clampBoth(T)(ref T val, T min, T max)
	{
	assert(min < max);
	if(val < min)
		{
		val = min;
		}
	if(val > max)
		{
		val = max;
		}
	}	

// <------------ Duplicates??
void cap(T)(ref T val, T low, T high)
	{
	if(val < low){val = low; return;}
	if(val > high){val = high; return;}
	}

// Cap and return value.
// better name for this? 
pure T cap_ret(T)(T val, T low, T high)
	{
	if(val < low){val = low; return val;}
	if(val > high){val = high; return val;}
	return val;
	}

/// Font Height = Ascent + Descent
int h(const ALLEGRO_FONT *f)
	{
	return al_get_font_line_height(f);
	}

/// Font Ascent
int a(const ALLEGRO_FONT *f)
	{
	return al_get_font_ascent(f);
	}

/// Font Descent
int d(const ALLEGRO_FONT *f)
	{
	return al_get_font_descent(f);
	}

//helper functions using universal function call syntax.
/// Return BITMAP width
int w(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_width(b);
	}
	
/// Return BITMAP height
int h(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_height(b);
	}

/// Same as al_draw_bitmap but center the sprite
/// we can also chop off the last item.
/// we could also throw an assert!null in here but maybe not for performance reasons.
void al_draw_centered_bitmap(ALLEGRO_BITMAP* b, float x, float y, int flags=0)
	{
	al_draw_bitmap(b, x - b.w/2, y - b.h/2, flags);
	}

/// Implied (viewport) drawing routines
/// ----------------------------------------------------------------------
void drawBitmap(ALLEGRO_BITMAP* b, vpair pos, int flags=0)
	{
	al_draw_bitmap(b, pos.r, pos.s, flags);
	}

void drawCenteredBitmap(ALLEGRO_BITMAP* b, vpair pos, int flags=0)
	{
	al_draw_bitmap(b, pos.r - b.w/2, pos.s - b.h/2, flags);
	}

/// Set texture target back to normal (the screen)
void al_reset_target() 
	{
	al_set_target_backbuffer(al_get_current_display());
	}

/// draw scaled bitmap but with a scale factor (simpler than the allegro API version)
void al_draw_scaled_bitmap2(ALLEGRO_BITMAP *bitmap, float x, float y, float scaleX, float scaleY, int flags=0)
	{
	al_draw_scaled_bitmap(bitmap, 0, 0, bitmap.w, bitmap.h, x, y, bitmap.w * scaleX, bitmap.h * scaleY, flags);
	}

void al_draw_center_rotated_bitmap(BITMAP* bmp, float x, float y, float angle, int flags)
	{
	al_draw_rotated_bitmap(bmp, bmp.w/2, bmp.h/2, x, y, angle, flags);
	}

void al_draw_center_rotated_tinted_bitmap(BITMAP* bmp, COLOR tint, float x, float y, float angle, int flags)
	{
	al_draw_tinted_rotated_bitmap(bmp, tint, bmp.w/2, bmp.h/2, x, y, angle, flags);
	}

// you know, we could do some sort of scoped lambda like thing that auto resets the target
/*
	DAllegro might already have that somewhere...
	
	foo();
	al_target(my_bitmap)
		{
		al_clear_to_color(...);
		al_draw_filled_rectangle(...);
		} // calls al_reset_target at end
	bar();

	al_target would be a class
		this

*/
//ALLEGRO_BITMAP* target, 

void al_target2(ALLEGRO_BITMAP* target, scope void delegate() func)
	{
	al_set_target_bitmap(target);
	func();
	al_reset_target();
	}
	
import std.stdio;
void test2()
	{
	ALLEGRO_BITMAP* bmp;
	al_target2(bmp, { al_draw_pixel(5, 5, ALLEGRO_COLOR(1,1,1,1)); });
	}

struct al_target()
	{
	this(ALLEGRO_BITMAP* target)
		{
		al_set_target(target);
		}
		
		//wheres the middle???
		
	~this()
		{
		al_reset_target();
		}
	}

/// Print variablename = value
/// usage because of D oddness:    
/// writeval(var.stringof, var);
void writeval(T)(string x, T y) 
	{
	writeln(x, " = ", y);
	}

/// Load a font and verify we succeeded or cause an out-of-band error to occur.
FONT* getFont(string path, int size)
	{
	import std.string : toStringz;
	ALLEGRO_FONT* f = al_load_font(toStringz(path), size, 0);
	assert(f != null, format("ERROR: Failed to load font [%s]!", path));
	return f;
	}

/// Load a bitmap and verify we succeeded or cause an out-of-band error to occur.
ALLEGRO_BITMAP* getBitmap(string path)
	{
	import std.string : toStringz;
	ALLEGRO_BITMAP* bmp = al_load_bitmap(toStringz(path));
	assert(bmp != null, format("ERROR: Failed to load bitmap [%s]!", path));
	return bmp;
	}

/// ported Gourand shading Allegro 5 functions from my old forum post
/// 	https://www.allegro.cc/forums/thread/615262
/// Four point shading:
void al_draw_gouraud_bitmap(ALLEGRO_BITMAP* bmp, float x, float y, COLOR tl, COLOR tr, COLOR bl, COLOR br)
	{
	ALLEGRO_VERTEX[4] vtx;
	float w = bmp.w;
	float h = bmp.h;

	vtx[0].x = x;
	vtx[0].y = y;
	vtx[0].z = 0;
	vtx[0].color = tl;
	vtx[0].u = 0;
	vtx[0].v = 0;

	vtx[1].x = x + w;
	vtx[1].y = y;
	vtx[1].z = 0;
	vtx[1].color = tr;
	vtx[1].u = w;
	vtx[1].v = 0;

	vtx[2].x = x + w;
	vtx[2].y = y + h;
	vtx[2].z = 0;
	vtx[2].color = br;
	vtx[2].u = w;
	vtx[2].v = h;

	vtx[3].x = x;
	vtx[3].y = y + h;
	vtx[3].z = 0;
	vtx[3].color = bl;
	vtx[3].u = 0;
	vtx[3].v = h;

	al_draw_prim(cast(void*)vtx, null, bmp, 0, vtx.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_FAN);
	}

/// Five points (includes center)
void al_draw_gouraud_bitmap_5pt(ALLEGRO_BITMAP* bmp, float x, float y, COLOR tl, COLOR tr, COLOR bl, COLOR br, COLOR mid)
	{
	ALLEGRO_VERTEX[6] vtx;
	float w = bmp.w;
	float h = bmp.h;

	//center
	vtx[0].x = x + w/2;
	vtx[0].y = y + h/2;
	vtx[0].z = 0;
	vtx[0].color = mid;
	vtx[0].u = w/2;
	vtx[0].v = h/2;

	vtx[1].x = x;
	vtx[1].y = y;
	vtx[1].z = 0;
	vtx[1].color = tl;
	vtx[1].u = 0;
	vtx[1].v = 0;

	vtx[2].x = x + w;
	vtx[2].y = y;
	vtx[2].z = 0;
	vtx[2].color = tr;
	vtx[2].u = w;
	vtx[2].v = 0;

	vtx[3].x = x + w;
	vtx[3].y = y + h;
	vtx[3].z = 0;
	vtx[3].color = br;
	vtx[3].u = w;
	vtx[3].v = h;

	vtx[4].x = x;
	vtx[4].y = y + h;
	vtx[4].z = 0;
	vtx[4].color = bl;
	vtx[4].u = 0;
	vtx[4].v = h;

	vtx[5].x = vtx[1].x; //end where we started.
	vtx[5].y = vtx[1].y;
	vtx[5].z = vtx[1].z;
	vtx[5].color = vtx[1].color;
	vtx[5].u = vtx[1].u;
	vtx[5].v = vtx[1].v;

	al_draw_prim(cast(void*)vtx, null, bmp, 0, vtx.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_FAN);
	}

/// al_draw_line_segment for pairs
void al_draw_line_segment(pair[] pairs, COLOR color, float thickness)
	{
	assert(pairs.length > 1);
	pair lp = pairs[0]; // initial p, also previous p ("last p")
	foreach(ref p; pairs)
		{
		al_draw_line(p.x, p.y, lp.x, lp.y, color, thickness);
		lp = p;
		}
	}
	
/// al_draw_line_segment for raw integers floats POD arrays
void al_draw_line_segment(T)(T[] x, T[] y, COLOR color, float thickness)
	{
	assert(x.length > 1);
	assert(y.length > 1);
	assert(x.length == y.length);

	for(int i = 1; i < x.length; i++) // note i = 1
		{
		al_draw_line(x[i], y[i], x[i-1], y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_line_segment(T)(T[] y, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(i, y[i], i-1, y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_scaled_line_segment(T)(pair xycoord, T[] y, float yScale, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(
			xycoord.x + i, 
			xycoord.y + y[i]*yScale, 
			xycoord.x + i-1, 
			xycoord.y + y[i-1]*yScale, 
			color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_scaled_indexed_line_segment(T)(pair xycoord, T[] y, float yScale, COLOR color, float thickness, int index, COLOR indexColor)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		if(i == index)
			{
			al_draw_line(
				xycoord.x + i, 
				xycoord.y + y[i]*yScale, 
				xycoord.x + i-1, 
				xycoord.y + y[i-1]*yScale, 
				indexColor, thickness*2);
			}else{
			al_draw_line(
				xycoord.x + i, 
				xycoord.y + y[i]*yScale, 
				xycoord.x + i-1, 
				xycoord.y + y[i-1]*yScale, 
				color, thickness);
			}
		}
	}
