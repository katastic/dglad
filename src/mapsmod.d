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

import std.stdio;
import std.math;
import std.random : uniform;
import std.algorithm : remove;
import std.file;
import std.conv;
import std.json;

/+
	isPassable			- people movement
	isShotPassable		- projectile movement (can't walk on water, but can shoot over it)
	[isFlyPassable?]	- ghosts, faeries, etc. Could also use shotpassable for anything bullets can fly over.

	we could allow "swimmable" which is just half speed water. also can apply to mud.
+/

/// Tile metadata but using hardcoded functions
/// Tree tiles for elf tree walking ability:
bool isForestTile(ushort tileType)
	{
	foreach(i; [9]) // temp, since we don't have tree tiles atm 
		if(tileType == i) return true;
	return false;
	}

/// Tile metadata but using hardcoded functions
/// Is tile drawn before blood layer (true), or after (false).
bool isBackLayer(ushort tileType)
	{
	foreach(i; [0, 1, 2]) 
		if(tileType == i) return true;
	return false;
	}

/// Tile metadata but using hardcoded functions
bool isShotPassableTile(ushort tileType)
	{
	foreach(i; [0, 1, 2, 3, 4, 5, 6])
		if(tileType == i) return true;
	return false;
	}

/// Tile metadata but using hardcoded functions
bool isPassableTile(ushort tileType)
	{
	foreach(i; [0, 1, 2, 4, 5])
		if(tileType == i) return true;
	return false;
	}

class map_t
	{
	immutable uint MAX_WIDTH = 256;
	immutable uint MAX_HEIGHT = 256;
	uint width = 64;
	uint height = 64;
	
	tile[MAX_HEIGHT][MAX_WIDTH] isPassable;
	tile[MAX_HEIGHT][MAX_WIDTH] bmpIndex;
	BITMAP* [] bmps;
//	ALLEGRO_BITMAP* [height][width] bmp;
	
	BITMAP*[] backgrounds;
	float[] parallaxScale; // reduce scrolling distance for each layer
	
	this()
		{
		bmps ~= g.grass_bmp; // 0 passable, note zero is empty/not used/blank so ignore this file for now
		bmps ~= g.grass_bmp; // 1 passable
		bmps ~= g.stone_bmp; // 2 passable
		bmps ~= g.water_bmp; // !3 passable
		bmps ~= g.wood_bmp;  // 4 passable
		bmps ~= g.reinforced_wall_bmp; // 5 passable (dark bg wall)
		bmps ~= g.lava_bmp;  // !6 passable
		bmps ~= g.wall_bmp;  // 7 !passable
		bmps ~= g.wall2_bmp; // 8 !passable
		bmps ~= g.wall3_bmp; // 9 !passable
				
		backgrounds ~= getBitmap("./data/parallax1.png");
		parallaxScale ~= .75;
		
		backgrounds ~= getBitmap("./data/parallax2.png");
		parallaxScale ~= .5;
		
		for(int j = 0; j < height; j++)
			for(int i = 0; i < width; i++)
				{
				bmpIndex[i][j] = 0;
//				bmp[i][j] = g.grass_bmp;
				isPassable[i][j] = true;
				}
		for(int i = 0; i < width; i++)
			{
			bmpIndex[i][height-1] = 1;
			isPassable[i][height-1] = false;
//			bmp[i][height-1] = g.stone_bmp;
			}
		for(int i = 0; i < width; i++)
			{
			if(percent(5))
				{
				isPassable[i][height-2] = false;
//				bmp[i][height-2] = g.stone_bmp;
				bmpIndex[i][height-2] = 1;
				}
			}	
		//writeln(data);
		}	

	//https://forum.dlang.org/post/t3ljgm$16du$1@digitalmars.com
	//big 'ol wtf case.
	void rawWriteValue(T)(File file, T value)
		{
		file.rawWrite((&value)[0..1]); // should this be 0..3?
		}

	JSONValue map_in_json_format;

	void save(string path="./data/maps/map.map")
		{
		writeln("save map");
		File f = File(path, "w");
		
		map_in_json_format = JSONValue(["width": 0, "height": 0]);
		map_in_json_format.object["width"] = width;
		map_in_json_format.object["height"] = height;
		map_in_json_format.object["bmpIndex"] = JSONValue( bmpIndex ); 
		map_in_json_format.object["isPassable"] = JSONValue( isPassable ); 

		f.write(map_in_json_format.toJSON(false));
		f.close();
		}

	void load(string path="./data/maps/map.map")
		{
		writeln("load map");
		string str = std.file.readText(path);
		//writeln(str);
		map_in_json_format = parseJSON(str);
		//writeln(map_in_json_format);

		auto t = map_in_json_format;

		writeln();
		writeln(t.object["width"]);
	
		width = to!int(t.object["width"].integer);
		height = to!int(t.object["height"].integer);
		writeln(width, " by ", height);
	
		foreach(size_t j, ref r; t.object["bmpIndex"].array)
			{
			foreach(size_t i, ref val; r.array)
				{
				bmpIndex[j][i] = to!ushort(val.integer); //"integer" outs long. lulbbq.
				}
			}
		foreach(size_t j, ref r; t.object["isPassable"].array)
			{
			foreach(size_t i, ref val; r.array)
				{
				isPassable[j][i] = to!ushort(val.integer); //"integer" outs long. lulbbq.
				}
			}
		}
	
	void drawTiles(viewport v, bool drawBackLayer)
		{
		for(int j = 0; j < height; j++)
			for(int i = 0; i < width; i++)
				{
			//	writeln(i, " ",j);
				auto val = bmpIndex[i][j];
				if(isBackLayer(val) != drawBackLayer) continue;
				
//				if(val == 0) continue;
				if(val+1 > bmps.length) continue; // avoiding val > length-1 because if (unsigned)length=0-1 = overflow not -1 . I might just disable the warning.
//				al_draw_bitmap(bmps[bmpIndex[i][j]], i*32 + v.x - v.ox, j*32 + v.y - v.oy, 0);
				if(!g.useLighting)
					{
					drawBitmap(bmps[val], vpair(i*32, j*32), 0);
				}else{
					// trick like the secret of mana idea. we could have "walls" sit on a "higher" layer (for blood map)
					// but also draw them brighter as if light is hitting and reflecting off them more to us
					drawTintedBitmap(bmps[val], getShadeTint(g.world.units[0].pos, pair(i * TILE_W, j * TILE_H)), vpair(i*32, j*32), 0);
					}
				}
		}
		
	void drawParallax(viewport v)
		{
		foreach(size_t i, b; backgrounds)
			al_draw_tinted_bitmap(backgrounds[i], COLOR(1,1,1,1), v.x - v.ox*parallaxScale[i], v.y - v.oy*parallaxScale[i], 0);
		}
		
	void drawBackLayer(viewport v)
		{
//		drawParallax(v);
		drawTiles(v, true);
		}

	void drawFrontLayer(viewport v)
		{
		drawTiles(v, false);
		}
		
	void onTick()
		{
		}
	}
	
