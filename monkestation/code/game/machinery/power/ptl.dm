#define MINIMUM_POWER 1 MW
/obj/machinery/power/transmission_laser
	name = "power transmission laser"
	desc = "Sends power over a giant laser beam to an NT power processing facility."

	icon = 'goon/icons/obj/pt_laser.dmi'
	icon_state = "ptl"

	max_integrity = 10000

	density = TRUE
	anchored = TRUE

	///3x3 tiles
	bound_width = 96
	bound_height = 96

	///variables go below here
	///the terminal this is connected to
	var/obj/machinery/power/terminal/terminal = null
	///the range we have this basically determines how far the beam goes its redone on creation so its set to a small number here
	var/range = 5
	///amount of power we are outputting
	var/output_level = 0
	///the total capacity of the laser
	var/capacity = INFINITY
	///our current charge
	var/charge = 0
	///should we try to input charge paired with the var below to check if its fully inputing
	var/input_attempt = TRUE
	///are we currently inputting
	var/inputting = TRUE
	///the amount of charge coming in from the inputs last tick
	var/input_available = 0
	///have we been switched on?
	var/turned_on = FALSE
	///are we attempting to fire the laser currently?
	var/firing = FALSE
	///are we selling the power or just sending it into the ether
	var/selling_power = FALSE
	///how much we have earned in total
	var/total_earnings = 0
	///the amount of money we haven't sent to cargo yet
	var/unsent_earnings = 0
	///we need to create a list of all lasers we are creating so we can delete them in the end
	var/list/laser_effects = list()
	///list of all blocking turfs or objects
	var/list/blocked_objects = list()

/obj/machinery/power/transmission_laser/Initialize(mapload)
	. = ..()

	range = get_dist(get_step(get_front_turf(), dir), get_edge_target_turf(get_front_turf(), dir))
	var/turf/back_turf = get_step(get_back_turf(), turn(dir, 180))
	terminal = locate(/obj/machinery/power/terminal) in back_turf

	if(!terminal)
		machine_stat |= BROKEN
		return
	terminal.master = src
	update_appearance()

/obj/machinery/power/transmission_laser/Destroy()
	. = ..()
	if(length(laser_effects))
		destroy_lasers()
	blocked_objects = null
/obj/machinery/power/transmission_laser/proc/get_back_turf()
	//this is weird as i believe byond sets the bottom left corner as the source corner like
	// x-x-x
	// x-x-x
	// o-x-x
	//which would mean finding the true back turf would require centering than taking a step in the inverse direction
	var/turf/center = locate(x + 1, y + 1, z)
	if(!center)///what
		return
	var/inverse_direction = turn(dir, 180)
	return get_step(center, inverse_direction)

/obj/machinery/power/transmission_laser/proc/get_front_turf()
	//this is weird as i believe byond sets the bottom left corner as the source corner like
	// x-x-x
	// x-x-x
	// o-x-x
	//which would mean finding the true front turf would require centering than taking a step in the primary direction
	var/turf/center = locate(x + 1, y + 1, z)
	if(!center)///what
		return
	return get_step(center, dir)

/obj/machinery/power/transmission_laser/examine(mob/user)
	. = ..()
	. += span_notice("Laser currently has [unsent_earnings] unsent credits.")
	. += span_notice("Laser has generated [total_earnings] credits.")
///appearance changes are here

/obj/machinery/power/transmission_laser/update_overlays()
	. = ..()
	if((machine_stat & BROKEN) || !charge)
		. += "unpowered"
		return
	if(input_available > 0)
		. += "green_light"
		. += emissive_appearance(icon, "green_light", src)
	if(turned_on)
		. += "red_light"
		. += emissive_appearance(icon, "red_light", src)
		if(firing)
			. +="firing"
			. += emissive_appearance(icon, "firing", src)

	var/charge_level = return_charge()
	if(charge_level == 6)
		. += "charge_full"
		. += emissive_appearance(icon, "charge_full", src)
	else if(charge_level > 0)
		. += "charge_[charge_level]"
		. += emissive_appearance(icon, "charge_[charge_level]", src)

///returns the charge level from [0 to 6]
/obj/machinery/power/transmission_laser/proc/return_charge()
	if(!output_level)
		return 0
	return min(round((charge / abs(output_level)) * 6), 6)

/obj/machinery/power/transmission_laser/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(user.istate & ISTATE_SECONDARY)
		return
	turned_on = !turned_on
	to_chat(user, span_notice("You turn the [src] [turned_on ? "On" : "Off"]."))
	update_appearance()

/obj/machinery/power/transmission_laser/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	firing = !firing
	to_chat(user, span_notice("You turn the firing mode on the [src] to [turned_on ? "On" : "Off"]."))
	update_appearance()
	if(length(laser_effects) && !firing)
		addtimer(CALLBACK(src, PROC_REF(destroy_lasers)), 5 SECONDS)

/obj/machinery/power/transmission_laser/process()
	if((machine_stat & BROKEN) || !turned_on)
		return

	var/last_disp = return_charge()
	var/last_chrg = inputting
	var/last_fire = firing

	if(terminal && input_attempt)
		input_available = terminal.surplus()

		if(inputting)
			if(input_available > 0)
				terminal.add_load(input_available)
				charge += input_available
			else
				inputting = FALSE
		else
			if(input_attempt && input_available > 0)
				inputting = TRUE
	else
		inputting = FALSE

	if(charge < MINIMUM_POWER)
		firing = FALSE
		output_level = 0
		destroy_lasers()

	if(charge > MINIMUM_POWER && firing)
		output_level = max(clamp((charge * 0.2) + MINIMUM_POWER, 0, charge), MINIMUM_POWER)
		if(!length(laser_effects))
			setup_lasers()
		if(length(blocked_objects))
			var/atom/listed_atom = blocked_objects[1]
			if(prob(max((abs(output_level) * 0.1) / 500 KW, 1))) ///increased by a single % per 500 KW
				listed_atom.visible_message(span_danger("[listed_atom] is melted away by the [src]!"))
				blocked_objects -= listed_atom
				qdel(listed_atom)
		else
			sell_power(output_level)

		charge -= output_level

	if(last_disp != return_charge() || last_chrg != inputting || last_fire != firing)
		update_appearance()

////selling defines are here
#define MINIMUM_BAR 25
#define PROCESS_CAP 5000 - MINIMUM_BAR

#define A1_CURVE 70

/obj/machinery/power/transmission_laser/proc/sell_power(power_amount)
	var/mw_power = power_amount * 0.000001

	var/generated_cash = (2 * mw_power * PROCESS_CAP) / (2 * mw_power + PROCESS_CAP * A1_CURVE)
	generated_cash += (4 * mw_power * MINIMUM_BAR) / (4 * mw_power + MINIMUM_BAR)
	generated_cash = round(generated_cash)

	total_earnings += generated_cash
	generated_cash += unsent_earnings
	unsent_earnings = generated_cash

	var/datum/bank_account/department/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/datum/bank_account/department/engineer = SSeconomy.get_dep_account(ACCOUNT_ENG)

	///the other 25% will be sent to engineers in the future but for now its stored inside
	var/cargo_cut = generated_cash * 0.25
	var/engineering_cut = generated_cash * 0.5

	engineer.adjust_money(engineering_cut, "Transmission Laser Payout")
	unsent_earnings -= engineering_cut
	cargo.adjust_money(cargo_cut, "Transmission Laser Payout")
	unsent_earnings -= cargo_cut

#undef A1_CURVE
#undef PROCESS_CAP
#undef MINIMUM_BAR

/obj/machinery/power/transmission_laser/proc/setup_lasers()
	///this is why we set the range we did
	var/turf/last_step = get_step(get_front_turf(), dir)
	for(var/num = 1 to range + 1)
		var/obj/effect/transmission_beam/new_beam = new(last_step)
		new_beam.host = src
		new_beam.dir = dir
		laser_effects += new_beam

		last_step = get_step(last_step, dir)

/obj/machinery/power/transmission_laser/proc/destroy_lasers()
	if(firing) // this is incase we turn the laser back on manually
		return
	for(var/obj/effect/transmission_beam/listed_beam as anything in laser_effects)
		laser_effects -= listed_beam
		qdel(listed_beam)

///this is called every time something enters our beams
/obj/machinery/power/transmission_laser/proc/atom_entered_beam(obj/effect/transmission_beam/triggered, atom/movable/arrived)
	var/mw_power = charge * 0.000001
	if(mw_power < 25)
		if(isliving(arrived))
			var/mob/living/arrived_living = arrived
			arrived_living.adjustFireLoss(-mw_power * 15)
	else
		if(mw_power < 50)
			if(isliving(arrived))
				var/mob/living/arrived_living = arrived
				arrived_living.gib(FALSE)
		else
			if(isliving(arrived))
				var/mob/living/arrived_living = arrived
				explosion(arrived_living, 3, 2, 2)
				arrived_living.gib(FALSE)


/obj/effect/transmission_beam
	name = ""
	icon = 'goon/icons/obj/power.dmi'
	icon_state = "ptl_beam"

	///used to deal with atoms stepping on us while firing
	var/obj/machinery/power/transmission_laser/host

/obj/effect/transmission_beam/Initialize(mapload, obj/machinery/power/transmission_laser/creator)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	update_appearance()

/obj/effect/transmission_beam/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_ENTERED)

/obj/effect/transmission_beam/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "ptl_beam", src)

/obj/effect/transmission_beam/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	host.atom_entered_beam(src, arrived)
