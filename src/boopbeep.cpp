// Written by Harrison DiAmbrosio
// hdiambrosio@gmail.com
// https://eggbert.xyz

#include <SDL2/SDL.h>
#include <SDL2/SDL_error.h>
#include <SDL2/SDL_mixer.h>

#include <SDL2/SDL_rwops.h>
#include <cstddef>
#include <vector>
#include <iostream>
#include <string>
#include <map>

/**
* std::string get_file_extension(const std::string& file_path);
* @param file_path: The file path to the sound file
* @return The file extension or a std::string of length 0
*/
std::string get_file_extension(const std::string& file_path);

/* 
* std::string get_file_name(const std::string& file_path);
* @param file_path: The file path to the sound file
* @return The filename or a std::string of length 0
*/
std::string get_file_name(const std::string& file_path);

/*
* int load_sound(const std::string& trigger_name, const std::string& file_path, 
* 			   std::map<const std::string, const Mix_Chunk*>& sound_map);
* @param trigger_name: name of trigger for sound
* @param file_path: absolute path to file
* @param sound_map: sound_map to append new sound to
* @return -1 upon failure and 0 on success
*/
int load_sound(const std::string& trigger_name, const std::string& file_path, 
			   std::map<std::string, Mix_Chunk*>& sound_map);

/*
* int play_sound(std::string& trigger_name, std::map<std::string, Mix_Chunk*> sound_map);
* @param trigger_name: name of sound to play
* @param sound_map: sound map to pull sound chunk from
*/
int play_sound(const std::string& trigger_name, std::map<std::string, Mix_Chunk*>& sound_map);

/*
* std::vector<std::string> string_split(std::string str, const std::string& delimeter);
* Splits strings
*/
std::vector<std::string> string_split(std::string str, const std::string& delimeter);

// TODO: CLI options to specify starting sound and allocating channels

const std::string ARG_DELIM = " ";
const int STARTING_VOLUME = MIX_MAX_VOLUME;
const int AUDIO_CHANNELS = 64;

int main(void) {
	SDL_Init(SDL_INIT_AUDIO);
	if(Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 16) == -1) {
		std::cerr << "SDL2 failed to initialize!: " << SDL_GetError() << "\n";
		return 1;
	}

	Mix_Init(MIX_INIT_MP3 | MIX_INIT_FLAC | MIX_INIT_OGG | MIX_INIT_OPUS | MIX_INIT_MID | MIX_INIT_MOD);

	Mix_Volume(-1, STARTING_VOLUME);
	Mix_AllocateChannels(AUDIO_CHANNELS);

	std::map<std::string, Mix_Chunk*> sound_map;

	while(true) {
		std::string request;
		std::cout << "\n\nReady to read: \n";
		std::getline(std::cin, request);
		if(request.empty()) continue;

		const std::vector<std::string> arguments = string_split(request, ARG_DELIM);
		const std::string command = arguments.at(0);

		std::cout << "Arguments: ";
		for(std::string arg : arguments) {
			std::cout << "\"" << arg << "\", ";
		}
		std::cout << "\nCommand: \"" << command << "\"\n";

		if(command == "load_sound") {
			// load_sound {trigger_name} {audio_file_path}
			std::cout << "Executing load_sound()\n";
			if(arguments.size() < 3) {
				std::cerr << "Call to \"load_file\" not followed by enough arguments: " << SDL_GetError() << "\n";
			} else {
				std::cout << "load_sound " << arguments.at(1) << ", " << arguments.at(2) << "\n";
				load_sound(arguments.at(1), arguments.at(2), sound_map);
			}
		} else if(command == "play_sound") {
			// play_sound {trigger_name}
			if(arguments.size() < 2) {
				std::cerr << "Call to \"play_sound\" not followed by enough arguments: " << SDL_GetError() << "\n";
			} else {
				play_sound(arguments.at(1), sound_map);
			}
		} else if(command == "set_master_volume") {
		} else if(command == "set_sound_volume") {
		} else if(command == "quit") {
			break;	
		} else {
			std::cerr << "Unrecognized command \"" << command << "\"\n";
			break;
		}
	}

	// Mix_FreeChunk(chest_open);

	// Free all audio chunks
	for(auto it = sound_map.begin(); it != sound_map.end(); it++) {
		Mix_FreeChunk(it->second);
	}

	Mix_CloseAudio();
	return 0;
}

std::string get_file_extension(const std::string& file_path) {
	const std::size_t dot_extension(file_path.find_last_of('.'));
	if(dot_extension != std::string::npos) {
		return file_path.substr(dot_extension);
	}
	return "";
}

std::string get_file_name(const std::string& file_path) {
	if(file_path.empty()) return "";

	const char file_path_delim = file_path.at(0) == '/' ? '/' : '\\';
	const std::size_t file_name_start(file_path.find_last_of(file_path_delim));
	const std::size_t file_name_end(file_path.find_last_of('.'));

	if(file_name_end == std::string::npos || file_name_start == std::string::npos) {
		return file_path.substr(file_name_start + 1, file_name_end);
	}

	return "";
}

int load_sound(const std::string& trigger_name, const std::string& file_path, 
			   std::map<std::string, Mix_Chunk*>& sound_map) {
	std::cout << "Loading sound: " << file_path << "...\n";
	if(file_path.empty()) {
		std::cerr << "Empty file path when trying to load an audio file:" << SDL_GetError() << "\n";
		return -1;
	}

	const std::string file_extension(get_file_extension(file_path));
	if(file_extension.empty()) {
		std::cerr << "No file extension spesified when trying to load \"" << file_path << "\": " << SDL_GetError() << "\n";
		return -1;
	}

	SDL_RWops* rw = SDL_RWFromFile(file_path.c_str(), "rb");
	if(!rw) {
		std::cerr << "Failed to open audio file \"" << file_path << "\": " << SDL_GetError() << "\n";
		return -1;
	}

	Mix_Chunk* sound_chunk = Mix_LoadWAV_RW(rw, 1);
	if(!sound_chunk) {
		std::cerr << "Failed to convert audio file \"" << file_path << "\" to WAV: " << SDL_GetError() << "\n";
		return -1;
	}

	sound_map.insert(std::make_pair(trigger_name, sound_chunk));

	return 0;
}

int play_sound(const std::string& trigger_name, std::map<std::string, Mix_Chunk*>& sound_map) {
	std::cout << "Playing sound \"" << trigger_name << "\"...\n";
	if(trigger_name.empty()) {
		std::cerr << "Cannot play sound of empty trigger name: " << SDL_GetError() << "\n";
		return -1;
	}

	try {
		Mix_PlayChannel(-1, sound_map.at(trigger_name), 0);
	} catch(std::out_of_range err) {
		return -1;
	}
	return 0;
}

std::vector<std::string> string_split(std::string str, const std::string& delimeter) {
	std::vector<std::string> out;
	std::size_t pos = 0;
	std::string token;

	while ((pos = str.find(delimeter)) != std::string::npos) {
		token = str.substr(0, pos);
		out.emplace_back(token);
		str.erase(0, pos + delimeter.length());
	}

	out.emplace_back(str);
	return out;
}
