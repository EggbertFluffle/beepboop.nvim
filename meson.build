project(
  'boopbeep', 
  'cpp', 
  default_options: [
    'default_library=static',
    'cpp_std=c++14'  # Adjust standard as needed
  ]
)

# Detect host system
host_system = host_machine.system()
host_cpu = host_machine.cpu_family()

# Architecture-specific settings
is_32bit = host_cpu == 'x86'
is_64bit = host_cpu == 'x86_64'
is_arm = host_cpu == 'aarch64' or host_cpu == 'arm64' or host_cpu == 'arm'
is_arm64 = host_cpu == 'aarch64' or host_cpu == 'arm64'
is_arm32 = host_cpu == 'arm'
is_apple_silicon = is_arm and host_system == 'darwin'
is_arm_linux = is_arm and host_system == 'linux'

# Platform-specific configurations
if host_system == 'windows'
  # Windows-specific configuration
  add_project_arguments('-DWINDOWS', language: 'cpp')
  if is_32bit
    add_project_arguments('-DX86', language: 'cpp')
  endif
elif host_system == 'darwin'
  # macOS-specific configuration
  add_project_arguments('-DMACOS', language: 'cpp')
  if is_apple_silicon
    add_project_arguments('-DARM64', language: 'cpp')
  endif
elif host_system == 'linux'
  # Linux-specific configuration
  add_project_arguments('-DLINUX', language: 'cpp')
  if is_arm_linux
    if is_arm64
      add_project_arguments('-DARM64', language: 'cpp')
    else
      add_project_arguments('-DARM', language: 'cpp')
    endif
  endif
  if is_32bit
    add_project_arguments('-DX86', language: 'cpp')
  endif
endif

# Dependencies - with platform-specific handling if needed
if host_system == 'windows'
  # Windows dependency handling
  sdl3_dep = dependency('sdl3', method: 'pkg-config')
  sdl3_mixer_dep = dependency('sdl3-mixer', method: 'pkg-config')
elif host_system == 'darwin' and is_apple_silicon
  # macOS Apple Silicon might need special handling
  sdl3_dep = dependency('sdl3')
  sdl3_mixer_dep = dependency('sdl3-mixer')
else
  # Linux and Intel macOS
  sdl3_dep = dependency('sdl3')
  sdl3_mixer_dep = dependency('sdl3-mixer')
endif

executable(
  'boopbeep', 
  ['src/boopbeep.cpp'],
  dependencies: [sdl3_dep, sdl3_mixer_dep],
  install: true
)
