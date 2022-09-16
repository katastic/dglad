
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;
import allegro5.allegro_acodec;
/// audio setup

class audioSystem{}

bool setupAudio()
	{
	if (!al_init_acodec_addon()) assert(0, "al_init_acodec_addon failed!");
	if (!al_install_audio()) assert(0, "al_install_audio failed!");
	al_reserve_samples(32); //not sure how many
	auto sample = al_load_sample("./data/extra/snd/pixabay/karate-chop-6357.mp3");
	if(sample is null)assert(0, "null sample, file not found likely.");
	auto sample_inst = al_create_sample_instance(sample);
	if(sample_inst is null)assert(0, "null sample instance");
	al_set_sample_instance_playmode(sample_inst, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE/*ALLEGRO_PLAYMODE_LOOP*/);
	al_attach_sample_instance_to_mixer(sample_inst, al_get_default_mixer());
	al_play_sample_instance(sample_inst);
	return 0;
	}
