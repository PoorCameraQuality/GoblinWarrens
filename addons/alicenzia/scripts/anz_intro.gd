@tool
extends AcceptDialog

@onready var guide_tab: TabContainer = %GuideTab
@onready var current_page_number: Label = %CurrentPageNumber


func _ready() -> void:
	set_unparent_when_invisible(true)
	_update_current_page_number()


func _on_prev_btn_pressed() -> void:
	var current_tab := guide_tab.current_tab
	if (current_tab - 1) != -1:
		guide_tab.set_current_tab(current_tab - 1)
		_update_current_tab_page()


func _on_next_btn_pressed() -> void:
	var current_tab := guide_tab.current_tab
	if (current_tab + 1) < guide_tab.get_tab_count():
		guide_tab.set_current_tab(current_tab + 1)
		_update_current_tab_page()


func _update_current_tab_page():
	if guide_tab.get_child_count() >= guide_tab.current_tab:
		var margin_cont := guide_tab.get_child(guide_tab.current_tab)
		if margin_cont.get_child_count() > 0 and margin_cont.get_child(0) is ScrollContainer:
			var scroll_cont : ScrollContainer = margin_cont.get_child(0)
			scroll_cont.set_v_scroll(0)
			
	_update_current_page_number()


func _update_current_page_number():
	current_page_number.text = "Page %d of %d" % [guide_tab.current_tab + 1, guide_tab.get_tab_count()]
