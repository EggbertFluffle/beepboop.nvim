// Written by Harrison DiAmbrosio
// hdiambrosio@gmail.com
// https://eggbert.xyz

#include <SDL3/SDL.h>
#include <SDL3/SDL_iostream.h>
#include <SDL3/SDL_oldnames.h>
#include <SDL3/SDL_stdinc.h>
#include <SDL3_mixer/SDL_mixer.h>

#include <cstdint>
#include <memory>
#include <cstddef>
#include <cstdlib>
#include <ctime>
#include <vector>
#include <iostream>
#include <string>
#include <unordered_map>

class Trigger {
	std::vector<std::shared_ptr<Mix_Chunk>> chunks;
	std::vector<std::shared_ptr<SDL_IOStream>> ios;

public:
	Mix_Chunk* const get_random_chunk() const {
		return chunks.at(rand() % chunks.size()).get();
	}

	void add_sound(Mix_Chunk* const & _chunk) {
		chunks.emplace_back(_chunk, SDL_free);
	}

	void add_sound(Mix_Chunk* const & _chunk, SDL_IOStream* const & _io) {
		chunks.emplace_back(_chunk, SDL_free);
		ios.emplace_back(_io, SDL_free);
	}

	void set_volume(const std::uint16_t& _volume) {
		for(const std::shared_ptr<Mix_Chunk>& chunk : chunks) {
			Mix_VolumeChunk(chunk.get(), _volume);
		}
	}
};

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
int load_sound(const std::string& trigger_name, const std::string& file_path, 
			   std::unordered_map<std::string, std::vector<std::shared_ptr<Mix_Chunk>>>& sound_map,
			   std::vector<SDL_IOStream*>& conversion_files);
* @param trigger_name: name of trigger for sound
* @param file_path: absolute path to file
* @param sound_map: sound_map to append new sound to
* @param conversion_files: List of files for converting other audio
* file formats into wav
* @return -1 upon failure and 0 on success
*/
int load_sound(const std::string& trigger_name, const std::string& file_path, 
			   std::unordered_map<std::string, Trigger>& sound_map);

/*
* int play_sound(std::string& trigger_name, std::unordered_map<std::string, std::shared_ptr<Mix_Chunk>> sound_map);
* @param trigger_name: name of sound to play
* @param sound_map: sound_map to pull sound chunk from
*/
int play_sound(const std::string& trigger_name, std::unordered_map<std::string, Trigger>& sound_map);

/*
* std::vector<std::string> string_split(std::string& source, const std::string& delimiter);
* Splits strings
*/
std::vector<std::string> string_split(std::string& source, const std::string& delimiter);

// TODO: CLI options to specify starting sound and allocating channels


const std::string ARG_DELIM = " ";
const int STARTING_VOLUME = MIX_MAX_VOLUME;
const int AUDIO_CHANNELS = 64;


int main(void) {
	SDL_Init(SDL_INIT_AUDIO);

	if(!Mix_OpenAudio(0, NULL)) {
		std::cerr << "SDL3 failed to initialize!: " << SDL_GetError() << "\n";
		return 1;
	}

	srand((unsigned)time(NULL));

	Mix_Init(MIX_INIT_MP3 | MIX_INIT_FLAC | MIX_INIT_OGG | MIX_INIT_OPUS | MIX_INIT_MID | MIX_INIT_MOD);
	Mix_Volume(-1, STARTING_VOLUME);
	Mix_AllocateChannels(AUDIO_CHANNELS);

	std::unordered_map<std::string, Trigger> sound_map;
	std::vector<SDL_IOStream*> conversion_files;
	conversion_files.reserve(64);
	bool quit = false;

	while(!quit || Mix_Playing(-1) != 0) {
		std::string request;

		if(!quit) std::getline(std::cin, request);

		if(request.empty()) continue;

		const std::vector<std::string> arguments = string_split(request, ARG_DELIM);
		const std::string command = arguments.at(0);

		if(command == "load_sound") {
			// load_sound {trigger_name} {audio_file_path}
			if(arguments.size() < 3) {
				std::cerr << "Call to \"load_file\" not followed by enough arguments\n";
			} else {
				load_sound(arguments.at(1), arguments.at(2), sound_map);
			}
		} else if(command == "play_sound") {
			// play_sound {trigger_name}
			if(arguments.size() < 2) {
				std::cerr << "Call to \"play_sound\" not followed by enough arguments\n";
			} else {
				play_sound(arguments.at(1), sound_map);
			}
		} else if(command == "set_master_volume") {
			if(arguments.size() < 2) {
				std::cerr << "Call to \"set_master_volume\" not followed by enough arguments\n";
			} else {
				int volume = std::stoi(arguments.at(1));
				Mix_MasterVolume(volume < 0 ? 0 : (volume > MIX_MAX_VOLUME ? MIX_MAX_VOLUME : volume));
			}
		} else if(command == "set_sound_volume") {
			if(arguments.size() < 3) {
				std::cerr << "Call to \"set_sound_volume\" not followed by enough arguments\n";
			} else {
				int volume = std::stoi(arguments.at(2));

				std::string trigger(arguments.at(1));

				sound_map.at(trigger).set_volume(volume < 0 ? 0 : (volume > MIX_MAX_VOLUME ? MIX_MAX_VOLUME : volume));
			}
		} else if(command == "quit") {
			quit = true;
		} else {
			std::cerr << "Unrecognized command \"" << command << "\"\n";
			break;
		}
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
			   std::unordered_map<std::string, Trigger>& sound_map) {
	if(file_path.empty()) {
		std::cerr << "Empty file path when trying to load an audio file:" << SDL_GetError() << "\n";
		return -1;
	}

	const std::string file_extension(get_file_extension(file_path));
	if(file_extension.empty()) {
		std::cerr << "No file extension spesified when trying to load \"" << file_path << "\": " << SDL_GetError() << "\n";
		return -1;
	}

	if(file_extension == "wav") {
		Mix_Chunk* const sound_chunk(Mix_LoadWAV(file_path.c_str()));
		if(sound_chunk == NULL) {
			std::cerr << "Failed to read \"" << file_path << "\": " << SDL_GetError() << "\n";
			return -1;
		}

		if(sound_chunk == NULL) {
			std::cerr << "Failed to load WAV: \"" << file_path << "\" " << SDL_GetError() << "\n";
			return -1;
		}
		
		if(sound_map.count(trigger_name) == 0) {
			sound_map.insert(std::make_pair(trigger_name, Trigger()));
		}
		sound_map.at(trigger_name).add_sound(sound_chunk);
	} else {
		SDL_IOStream* const io = SDL_IOFromFile(file_path.c_str(), "rb");
		if(io == NULL) {
			std::cerr << "Failed to open audio file \"" << file_path << "\": " << SDL_GetError() << "\n";
			return -1;
		}

		Mix_Chunk* const sound_chunk = Mix_LoadWAV_IO(io, 0);
		if(sound_chunk == NULL) {
			std::cerr << "Failed to convert audio file \"" << file_path << "\" to WAV: " << SDL_GetError() << "\n";
			return -1;
		}

		if(sound_map.count(trigger_name) == 0) {
			sound_map.insert(make_pair(trigger_name, Trigger()));
		}
		sound_map.at(trigger_name).add_sound(sound_chunk, io);
}


	return 0;
}

int play_sound(const std::string& trigger_name, std::unordered_map<std::string, Trigger>& sound_map) {
	if(trigger_name.empty()) {
		std::cerr << "Cannot play sound of empty trigger name: " << SDL_GetError() << "\n";
		return -1;
	}

	if(sound_map.count(trigger_name) == 0) {
		std::cerr << "Sound map does not contain defenition for trigger \"" << trigger_name << "\"\n";
		return -1;
	}

	Mix_PlayChannel(-1, sound_map.at(trigger_name).get_random_chunk(), 0);

	return 0;
}

std::vector<std::string> string_split(std::string& source, const std::string& delimiter) {
    std::vector<std::string> tokens;
	std::size_t pos = 0;
    std::string token;

    while ((pos = source.find(delimiter)) != std::string::npos) {
        token = source.substr(0, pos);
        tokens.push_back(token);
        source.erase(0, pos + delimiter.length());
    }
    tokens.push_back(source);

    return tokens;
}
