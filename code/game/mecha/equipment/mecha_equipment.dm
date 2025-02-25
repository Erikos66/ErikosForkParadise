//DO NOT ADD MECHA PARTS TO THE GAME WITH THE DEFAULT "SPRITE ME" SPRITE!
//I'm annoyed I even have to tell you this! SPRITE FIRST, then commit.

/obj/item/mecha_parts/mecha_equipment
	name = "mecha equipment"
	icon = 'icons/mecha/mecha_equipment.dmi'
	icon_state = "mecha_equip"
	force = 5
	origin_tech = "materials=2;engineering=2"
	max_integrity = 300
	var/equip_cooldown = 0
	var/equip_ready = 1
	var/energy_drain = 0
	var/obj/mecha/chassis = null
	var/range = MECHA_MELEE //bitflags
	var/salvageable = 1
	var/selectable = 1	// Set to 0 for passive equipment such as mining scanner or armor plates
	var/harmful = FALSE //Controls if equipment can be used to attack by a pacifist.


/obj/item/mecha_parts/mecha_equipment/proc/update_chassis_page()
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","eq_list",chassis.get_equipment_list())
		send_byjax(chassis.occupant,"exosuit.browser","equipment_menu",chassis.get_equipment_menu(),"dropdowns")
		return

/obj/item/mecha_parts/mecha_equipment/proc/update_equip_info()
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",get_equip_info())

/obj/item/mecha_parts/mecha_equipment/Destroy()//missiles detonating, teleporter creating singularity?
	if(chassis)
		chassis.occupant_message("<span class='danger'>[src] is destroyed!</span>")
		chassis.log_append_to_last("[src] is destroyed.",1)
		SEND_SOUND(chassis.occupant, sound(get_destroy_sound(), volume = 50))
		detach(chassis)
	return ..()


/obj/item/mecha_parts/mecha_equipment/proc/get_destroy_sound()
	return chassis.critdestrsound

/obj/item/mecha_parts/mecha_equipment/proc/get_equip_info()
	if(!chassis)
		return
	var/txt = "<span style=\"color:[equip_ready?"#0f0":"#f00"];\">*</span>&nbsp;"
	if(chassis.selected == src)
		txt += "<b>[name]</b>"
	else if(selectable)
		txt += "<a href='byond://?src=[chassis.UID()];select_equip=\ref[src]'>[name]</a>"
	else
		txt += "[name]"

	return txt

/obj/item/mecha_parts/mecha_equipment/proc/is_ranged()//add a distance restricted equipment. Why not?
	return range & MECHA_RANGED

/obj/item/mecha_parts/mecha_equipment/proc/is_melee()
	return range & MECHA_MELEE

/obj/item/mecha_parts/mecha_equipment/proc/action_checks(atom/target)
	if(!target)
		return FALSE
	if(!chassis)
		return FALSE
	if(!equip_ready)
		return FALSE
	if(energy_drain && !chassis.has_charge(energy_drain))
		return FALSE
	return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/action(atom/target)
	return

/obj/item/mecha_parts/mecha_equipment/proc/start_cooldown()
	set_ready_state(0)
	chassis.use_power(energy_drain)
	addtimer(CALLBACK(src, PROC_REF(set_ready_state), 1), equip_cooldown)

/obj/item/mecha_parts/mecha_equipment/proc/do_after_cooldown(atom/target)
	if(!chassis)
		return FALSE
	var/C = chassis.loc
	set_ready_state(0)
	chassis.use_power(energy_drain)
	. = do_after(chassis.occupant, equip_cooldown, target = target)
	set_ready_state(1)
	if(!chassis || 	chassis.loc != C || src != chassis.selected || !(get_dir(chassis, target) & chassis.dir))
		return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/do_after_mecha(atom/target, delay)
	if(!chassis)
		return FALSE
	var/C = chassis.loc
	. = do_after(chassis.occupant, delay, target = target)
	if(!chassis || 	chassis.loc != C || src != chassis.selected || !(get_dir(chassis, target) & chassis.dir))
		return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/can_attach(obj/mecha/M)
	if(istype(M))
		if(length(M.equipment)<M.max_equip)
			return TRUE
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/attach(obj/mecha/M)
	M.equipment += src
	chassis = M
	loc = M
	M.log_message("[src] initialized.")
	if(!M.selected)
		M.selected = src
	update_chassis_page()
	if(M.occupant)
		give_targeted_action()

/obj/item/mecha_parts/mecha_equipment/proc/give_targeted_action()
	if(!selectable)
		return
	var/datum/action/innate/mecha/select_module/select_action = new()
	select_action.Grant(chassis.occupant, chassis, src)
	chassis.select_actions[src] = select_action

/obj/item/mecha_parts/mecha_equipment/proc/detach(atom/moveto = null)
	moveto = moveto || get_turf(chassis)
	if(Move(moveto))
		chassis.equipment -= src
		if(chassis.selected == src)
			chassis.selected = null
		update_chassis_page()
		remove_targeted_action()
		chassis.log_message("[src] removed from equipment.")
		chassis = null
		set_ready_state(1)

/obj/item/mecha_parts/mecha_equipment/proc/remove_targeted_action()
	if(!selectable)
		return
	if(chassis.select_actions[src])
		var/datum/action/innate/mecha/select_module/select_action = chassis.select_actions[src]
		select_action.Remove(chassis.occupant)

/obj/item/mecha_parts/mecha_equipment/Topic(href,href_list)
	if(!chassis)
		return TRUE
	if(usr != chassis.occupant)
		return TRUE
	if(href_list["detach"])
		detach()


/obj/item/mecha_parts/mecha_equipment/proc/set_ready_state(state)
	equip_ready = state
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())

/obj/item/mecha_parts/mecha_equipment/proc/occupant_message(message)
	if(chassis)
		chassis.occupant_message("[bicon(src)] [message]")

/obj/item/mecha_parts/mecha_equipment/proc/log_message(message)
	if(chassis)
		chassis.log_message("<i>[src]:</i> [message]")
