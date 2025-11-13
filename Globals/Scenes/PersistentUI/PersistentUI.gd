extends Control

##Autoload scene that is always loaded to provide smooth UI transitioning between levels and menus.

var _locked : bool = false ##Whether other scripts can currently call animation/transition functions. Set this to true when this autoload is using itself to transition between levels and such.

func _busy_error() -> void:
	GameLogger.printerr_as_autoload(self, "Cannot play animation, PersistentUI has been locked")


func show_loading_screen() -> void: ##Fade in the loading screen with tips. Can be used when a level is loading.
	GameLogger.print_verbose_as_autoload(self, "Fading in tips screen...")
	
	_locked = true
	await _fade_in_black()
	$LevelLoading.visible = true
	_fade_out_black()

func hide_loading_screen() -> void: ##Fade out the loading screen with tips.
	GameLogger.print_verbose_as_autoload(self, "Fading out tips screen...")
	
	await _fade_in_black()
	$LevelLoading.visible = false
	_fade_out_black()
	_locked = false



#is it ok to have the variables above the functions they are used in like this? I think it'd make everything more readable and organised like this, instead of putting everything at the top
var _fade_black_tween : Tween #only have one tween variable so that there can never be 2 tweens running on the overlay simulatenously.

func fade_in_black(fade_time : float = 0.2) -> void: ##Fade in the black overlay, completely obscuring everything.
	if _locked:
		_busy_error()
	else:
		await _fade_in_black(fade_time)
	
	return

func _fade_in_black(fade_time : float = 0.2) -> void: ##Function behind fade_in_black() that should only be called by PersistentUI.
	GameLogger.print_verbose_as_autoload(self, "Fading in black overlay...")
	
	_fade_black_tween = create_tween()
	_fade_black_tween.tween_property($BlackOverlay, "modulate:a", 1.0, fade_time)
	
	await _fade_black_tween.finished
	return #this combination of await and return makes this function an async function, which allows you to await the completion of this function using await.



func fade_out_black(fade_time : float = 0.2) -> void: ##Fade out the black overlay.
	if _locked:
		_busy_error()
	else:
		await _fade_out_black(fade_time)
	
	return

func _fade_out_black(fade_time : float = 0.2) -> void: ##Function behind fade_out_black() that should only be called by PersistentUI.
	GameLogger.print_verbose_as_autoload(self, "Fading out black overlay...")
	
	_fade_black_tween = create_tween()
	_fade_black_tween.tween_property($BlackOverlay, "modulate:a", 0.0, fade_time)
	
	await _fade_black_tween.finished
	return


func _ready() -> void:
	$LevelLoading.visible = false
	$BlackOverlay.modulate.a = 0.0
