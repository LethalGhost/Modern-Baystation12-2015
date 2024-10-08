/obj/item/device/assembly/prox_sensor
	name = "proximity sensor"
	desc = "Used for scanning and alerting when someone enters a certain proximity."
	icon_state = "prox"
	matter = list(DEFAULT_WALL_MATERIAL = 800, "glass" = 200, "waste" = 50)
	origin_tech = "magnets=1"

	wires = WIRE_PULSE

	secured = 0

	var/scanning = 0
	var/timing = 0
	var/time = 10

	var/range = 2

	proc
		toggle_scan()
		sense()


	activate()
		if(!..())	return 0//Cooldown check
		timing = !timing
		update_icon()
		return 0


	toggle_secure()
		secured = !secured
		if(secured)
			processing_objects.Add(src)
		else
			scanning = 0
			timing = 0
			processing_objects.Remove(src)
		update_icon()
		return secured


	HasProximity(atom/movable/AM as mob|obj)
		if (istype(AM, /obj/effect/beam))	return
		if (AM.move_speed < 12)	sense()
		return


	sense()
		var/turf/mainloc = get_turf(src)
//		if(scanning && cooldown <= 0)
//			mainloc.visible_message("\icon[src] *boop* *boop*", "*boop* *boop*")
		if((!holder && !secured)||(!scanning)||(cooldown > 0))
			return 0
		pulse(0)
		if(!holder)
			mainloc.visible_message("\icon[src] *beep* *beep*", "*beep* *beep*")
		cooldown = 2
		spawn(10)
			process_cooldown()
		return


	process()
		if(scanning)
			var/turf/mainloc = get_turf(src)
			for(var/mob/living/A in range(range,mainloc))
				if (A.move_speed < 12)
					sense()

		if(timing && (time >= 0))
			time--
		if(timing && time <= 0)
			timing = 0
			toggle_scan()
			time = 10
		return


	dropped()
		spawn(0)
			sense()


	toggle_scan()
		scanning = !scanning
		update_icon()
		return


	update_icon()
		overlays.Cut()
		attached_overlays = list()
		if(timing)
			overlays += "prox_timing"
			attached_overlays += "prox_timing"
		if(scanning)
			overlays += "prox_scanning"
			attached_overlays += "prox_scanning"
		if(holder)
			holder.update_icon()
		if(holder && istype(holder.loc,/obj/item/weapon/grenade/chem_grenade))
			var/obj/item/weapon/grenade/chem_grenade/grenade = holder.loc
			grenade.primed(scanning)
		return


	Move()
		..()
		sense()
		return


	interact(mob/user as mob)//TODO: Change this to the wires thingy
		var/second = time % 60
		var/minute = (time - second) / 60

		var/dat = "<TT><B>Proximity Sensor</B>\n"
		dat += "<A href='?src=\ref[src];toggle_arm=1'>[timing ? "Arming" : "Not Arming"]</A>  [minute]:[second]\n"

		dat += "<A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> "
		dat += "<A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>\n</TT>"
		dat += "<BR>Range: <A href='?src=\ref[src];range=-1'>-</A> [range] <A href='?src=\ref[src];range=1'>+</A>"
		dat += "<BR><A href='?src=\ref[src];scanning=1'>[scanning?"Armed":"Unarmed"]</A> (Movement sensor active when armed!)"
		dat += "<BR><BR><A href='?src=\ref[src];refresh=1'>Refresh</A>"
		dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
		user << browse(dat, "window=prox")
		onclose(user, "prox")


	Topic(href, href_list)
		if(href_list["close"])
			usr << browse(null, "window=prox")
			return ..()

		if(!..())
			return FALSE

		if(!usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
			usr << browse(null, "window=prox")
			onclose(usr, "prox")
			return FALSE

		if(href_list["scanning"])
			toggle_scan()

		if(href_list["toggle_arm"])
			timing = !timing
			update_icon()

		if(href_list["tp"])
			var/tp = text2num(href_list["tp"])
			time += tp
			time = min(max(round(time), 0), 600)

		if(href_list["range"])
			var/r = text2num(href_list["range"])
			range += r
			range = min(max(range, 1), 5)
		if(usr)
			attack_self(usr)

		return TRUE
