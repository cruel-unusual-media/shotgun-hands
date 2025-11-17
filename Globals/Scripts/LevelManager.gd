extends Node

##Autoload that is used to load levels. Uses SceneManager under the hood.

var loaded_level : Level

func launch_level(level_name : String) -> void: ##Loads and initializes the level with the specified name.
	var _path : String = DefaultPaths.level_scenes_path + level_name + ".tscn"
	
	await PersistentUI.show_loading_screen()
	
	ResourceLoader.load_threaded_request(_path) #request for level scene to get loaded. Doing it like this instead of load() allows us to poll the loading progress.
	
	var _progress_fac : Array[float] #to be passed along to PersistentUI. This is an array so that the variable gets passed as a reference, not by value, which allows ResourceLoader to update the value here.
	while (ResourceLoader.load_threaded_get_status(_path, _progress_fac) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS):
		PersistentUI.set_level_loading_screen_progress(_progress_fac[0])
		await get_tree().create_timer(0.01).timeout
	
	PersistentUI.set_level_loading_screen_progress(1.0) #make sure that the progress counter is set to 100%
	
	match ResourceLoader.load_threaded_get_status(_path):
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			GameLogger.printerr_as_autoload(self, "Level " + _path + " could not be loaded.")
			return
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			GameLogger.printerr_as_autoload(self, "Level " + _path + " is not a valid resource.")
			return
		
		#the only option left is ThreadLoadStatus.THREAD_LOAD_LOADED, which means success
	
	var _level_scene : PackedScene = ResourceLoader.load_threaded_get(_path)
	get_tree().change_scene_to_packed(_level_scene)
	loaded_level = get_tree().current_scene
	
	PersistentUI.finish_loading_level()
	
	GameLogger.print_as_autoload(self, "Loaded level \"" + level_name + "\" (" + _path + "), initializing...")
	
	loaded_level.initialize_level()
