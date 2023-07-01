/obj/structure/cable/industrial
	name = "industrial grade power cable"
	cable_color = CABLE_COLOR_CYAN
	cable_tag = "industrial"

/obj/structure/cable/industrial/deconstruct(disassembled = TRUE)
	if(!do_after(usr, 2 SECONDS, src))
		return
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/item/stack/cable_coil/cable = new(drop_location(), 1)
		cable.set_cable_color(cable_color)
	qdel(src)

/obj/item/stack/cable_coil/industrial
	name = "coil of industrial cables"
	cable_color = CABLE_COLOR_CYAN
	color = CABLE_HEX_COLOR_CYAN
	merge_type = /obj/item/stack/cable_coil/industrial
	target_type = /obj/structure/cable/industrial
