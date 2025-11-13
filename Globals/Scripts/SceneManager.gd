extends Node

##Autoload that is used to load levels and menu's.

func launch_level(level_scene_path : StringName) -> void:
	pass

func switch_to_menu_scene(menu_scene_path : String) -> void:
	GameLogger.print_as_autoload(self, "Loading scene from path \"" + menu_scene_path + "\" ...")
	
	await PersistentUI.fade_in_black()
	get_tree().change_scene_to_file(menu_scene_path)
	

func switch_to_menu(menu_scene : GlobalEnums.Menus) -> void:
	var _name_to_use : String
	
	
	match menu_scene: #using enums to indicate scenes allows us to simply change the strings in this script instead of in every other script when refactoring 
		GlobalEnums.Menus.MAIN:
			_name_to_use = "main_menu"
		GlobalEnums.Menus.SETTINGS:
			_name_to_use = "settings"
		GlobalEnums.Menus.LEVEL_SELECTION:
			_name_to_use = "level_selection"
	
	
	GameLogger.print_as_autoload(self, "Loading scene \"" + _name_to_use + "\"...")
	
	await PersistentUI.fade_in_black()
	get_tree().change_scene_to_file(DefaultPaths.menu_scenes_path + _name_to_use + ".tscn")
	PersistentUI.fade_out_black()
	
