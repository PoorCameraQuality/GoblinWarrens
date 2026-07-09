@tool
extends ConfirmationDialog

const SCAN_RESULT_ROW = preload("res://addons/alicenzia/scenes/scan_result_row.tscn")
const WINDOW_MIN_Y := 80
const ROW_MIN_Y := 23.0

@onready var top_v_box_container: VBoxContainer = $TopVBoxContainer
@onready var row_list: VBoxContainer = %RowList
@onready var first_row: HBoxContainer = %FirstRow

func build_rows(scanned_license_data_array : Array[Dictionary]) -> Array[Control]:
	var new_rows : Array[Control]
	
	for row in row_list.get_children():
		if row != first_row:
			row.queue_free()
			
	
	top_v_box_container.size.y = ROW_MIN_Y
	self.size.y = WINDOW_MIN_Y
	
	for scanned_license_data in scanned_license_data_array:
		var new_row := SCAN_RESULT_ROW.instantiate()
		row_list.add_child(new_row)
		new_row.fill_row(scanned_license_data)
		new_rows.append(new_row)
	
	self.size.y = row_list.size.y
	
	return new_rows


func get_confirmed_licenses() -> Array[Dictionary]: # called from the main scene
	var confirmed_licenses : Array[Dictionary]
	
	for row in row_list.get_children():
		if row == first_row:
			continue
		if row.is_row_selected:
			confirmed_licenses.append(row.thisrow_license_data)
	
	return confirmed_licenses


func show_and_adjust():
	self.show()
	
	## doesn't work lol
	top_v_box_container.size.y = ROW_MIN_Y 
	self.size.y = WINDOW_MIN_Y
	#print(top_v_box_container.size.y)
