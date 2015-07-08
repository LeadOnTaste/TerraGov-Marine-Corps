//Xenomorph General Procs And Functions - Colonial Marines

//First, dealing with alt-clicking vents.
/mob/living/carbon/Xenomorph/ClickOn(atom/A, params)
	var/list/modifiers = params2list(params)

	if(modifiers["alt"] && istype(A,/obj/machinery/atmospherics/unary/vent_pump))
		var/verb_path = /mob/living/carbon/Xenomorph/proc/vent_crawl
		if(verb_path in inherent_verbs)
			if(check_state())
				src.handle_ventcrawl(A)
			return
	else
		..()

//Send a message to all xenos. Mostly used in the deathgasp display
proc/xeno_message(var/message = null, var/size = 3)
	if(!message)
		return

	if(ticker && ticker.mode.aliens.len) //Send to only xenos in our gamemode list. This is faster than scanning all mobs
		for(var/datum/mind/L in ticker.mode.aliens)
			var/mob/living/carbon/Xenomorph/M = L.current
			if(M && istype(M) && !M.stat && M.client) //Only living and connected xenos
				M << "\red <font size=[size]> [message]</font>"


//Adds stuff to your "Status" pane -- Specific castes can have their own, like carrier hugger count
//Those are dealt with in their caste files.
/mob/living/carbon/Xenomorph/Stat()
	..()
	if(jelly)
		stat(null, "Jelly Progress: [jellyGrow]/[jellyMax]")

	if(maxplasma > 0)
		stat(null, "Plasma: [storedplasma]/[maxplasma]")

//A simple handler for checking your state. Used in pretty much all the procs.
/mob/living/carbon/Xenomorph/proc/check_state()
	if(!istype(src,/mob/living/carbon/Xenomorph) || isnull(src)) //somehow
		return 0

	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		src << "You cannot do this in your current state."
		return 0

	return 1

//Checks your plasma levels, removes them accordingly, and gives a handy message.
/mob/living/carbon/Xenomorph/proc/check_plasma(var/value)
	if(stat)
		src << "\red Can't do this while unconcious."
		return 0

	if(value > 0)
		if(storedplasma < value)
			src << "\red Insufficient plasma. You require [value] but have only [storedplasma]."
			return 0

		storedplasma -= value
//		adjustToxLoss(-value) //Is this even used at all anymore??
		return 1
	else
		return 1 //If plasma cost is 0 just go ahead and do it


//Check if you can plant on groundmap turfs.
//Does NOT return a message, just a 0 or 1.
/mob/living/carbon/Xenomorph/proc/is_weedable(turf/T)
	if(isnull(T) || !isturf(T)) return 0
	if(istype(T,/turf/space)) return 0
	if(istype(T,/turf/simulated/floor/gm/grass) || istype(T,/turf/simulated/floor/gm/dirtgrassborder) || istype(T,/turf/simulated/floor/gm/river) || istype(T,/turf/simulated/floor/gm/coast)) return 0
	return 1

//Strip all inherent xeno verbs from your caste. Used in evolution.
/mob/living/carbon/Xenomorph/proc/remove_inherent_verbs()
	if(inherent_verbs)
		for(var/verb_path in inherent_verbs)
			verbs -= verb_path
	return

//Add all your inherent caste verbs and procs. Used in evolution.
/mob/living/carbon/Xenomorph/proc/add_inherent_verbs()
	if(inherent_verbs)
		for(var/verb_path in inherent_verbs)
			verbs |= verb_path
	return


	return

/* OBSOLETE -- This is handled in Life() now
/mob/living/carbon/Xenomorph/proc/growJelly()//Grows the delicious Jelly 08FEB2015
	spawn while (1)
		if(jelly)
			if(jellyGrow<jellyMax)
				jellyGrow++
			sleep(10)

/mob/living/carbon/Xenomorph/proc/canEvolve()//Determines if they alien can evolve 08FEB2015
	if(!jelly)
		return 0
	if(jellyGrow < jellyMax)
		return 0
	return 1
*/
//Adds or removes a delay to movement based on your caste. If speed = 0 then it shouldn't do much.
//Runners are -2, -4 is BLINDLINGLY FAST, +2 is fat-level
/mob/living/carbon/Xenomorph/movement_delay()
	var/tally = 0

	tally = speed

	if (istype(loc, /turf/space)) return -1 // It's hard to be slowed down in space by... anything

	if(istype(loc,/turf/simulated/floor/gm/river)) //Rivers slow you down
		tally += 1.3

	if(src.pulling)  //Dragging stuff slows you down a bit.
		tally += 1.5

	return (tally)

//These don't do much currently. Or anything? Only around for legacy code.
/mob/living/carbon/Xenomorph/restrained()
	return 0

/mob/living/carbon/Xenomorph/can_use_vents()
	return 1

/mob/living/carbon/Xenomorph/proc/update_progression()
	return

/mob/living/carbon/Xenomorph/show_inv(mob/user as mob)
	return

/obj/item/projectile/energy/neuro
	name = "neuro"
	icon_state = "neurotoxin"
	damage = 1
	damage_type = TOX
	weaken = 3

/obj/item/projectile/energy/neuro/strong
	damage = 5
	weaken = 6
	eyeblur = 1

/obj/item/projectile/energy/neuro/strongest
	damage = 10
	weaken = 9
	eyeblur = 3


//Xeno-style acids
//Ideally we'll consolidate all the "effect" objects here
//Also need to change the icons
/obj/effect/xenomorph
	name = "alien thing"
	desc = "You shouldn't be seeing this."
	icon = 'icons/Xeno/effects.dmi'

//Medium-strength acid
/obj/effect/xenomorph/acid
	name = "acid"
	desc = "Burbling corrossive stuff. I wouldn't want to touch it."
	icon_state = "acid"
	density = 0
	opacity = 0
	anchored = 1
	layer = 5 //Should be on top of most things

	var/atom/target
	var/ticks = 0
	var/target_strength = 0
	var/acid_strength = 100 //100% speed, normal

//Sentinel weakest acid
/obj/effect/xenomorph/acid/weak
	name = "weak acid"
	acid_strength = 250 //250% normal speed

//Superacid
/obj/effect/xenomorph/acid/strong
	name = "strong acid"
	target_strength = 20 //20% normal speed

/obj/effect/xenomorph/acid/New(loc, target)
	..(loc)
	src.target = target

	if(isturf(target)) // Turf take twice as long to take down.
		target_strength = 8
	else
		target_strength = 4
	tick()

/obj/effect/xenomorph/acid/proc/tick()
	if(!target)
		del(src)

	if(!src) //Woops, abort
		return

	var/tick_timer = rand(200,300) * acid_strength / 100 //Acid strength is just a percentage of time between ticks

	ticks += 1

	if(ticks >= target_strength)

		for(var/mob/O in hearers(src, null))
			O.show_message("\green <B>[src.target] collapses under its own weight into a puddle of goop and undigested debris!</B>", 1)

		if(istype(target, /turf/simulated/wall)) // I hate turf code.
			var/turf/simulated/wall/W = target
			W.dismantle_wall(1)
		else
			if(target.contents) //Hopefully won't auto-delete things inside melted stuff..
				for(var/mob/S in target)
					if(S in target.contents && !isnull(target.loc))
						S.loc = target.loc

			if(istype(target,/turf)) //We don't want space tiles appearing everywhere... but this sucks!
				var/turf/T = target
				T.ChangeTurf(/turf/simulated/floor/plating)
			else
				del(target)
		del(src)
		return

	switch(target_strength - ticks)
		if(6)
			visible_message("\green <B>[src.target] is holding up against the acid!</B>")
		if(4)
			visible_message("\green <B>[src.target]\s structure is being melted by the acid!</B>")
		if(2)
			visible_message("\green <B>[src.target] is struggling to withstand the acid!</B>")
		if(0 to 1)
			visible_message("\green <B>[src.target] begins to crumble under the acid!</B>")
	spawn(tick_timer)
		tick()

//This deals with "throwing" xenos -- ravagers, hunters, and runners in particular. Everyone else defaults to normal
//Pounce, charge both use throw_at, so we need extra code to do stuff rather than just push people aside.
/mob/living/carbon/Xenomorph/throw_impact(atom/hit_atom, var/speed)

	if(!charge_type || stat || !usedPounce) //0: No special charge. 1: pounce, 2: claw. Can add new ones here. Check if alive.
		..()
		return

	if(isobj(hit_atom)) //Deal with smacking into dense objects. This overwrites normal throw code.
		var/obj/O = hit_atom
		if(!O.density) //Not a dense object? Doesn't matter then, pass over it.
			..()
			return

		if(!O.anchored)
			step(O,src.dir) //Not anchored? Knock the object back a bit. Ie. canisters.

		if(istype(src,/mob/living/carbon/Xenomorph/Ravager)) //Ravagers destroy tables.
			if(istype(O,/obj/structure/table) || istype(O,/obj/structure/rack) || istype(O,/obj/structure/barricade/wooden))
				var/obj/structure/S = O
				visible_message("<span class='danger'>[src] plows straight through the [S.name]!</span>")
				S.destroy()

		if(!istype(O,/obj/structure/table)) // new - xeno charge ignore tables
			O.hitby(src,speed)
			if(O.density)
				src << "Bonk!" //heheh. Smacking into dense objects stuns you slightly.
				src.Weaken(2)
		return

	if(ismob(hit_atom)) //Hit a mob! This overwrites normal throw code.
		var/mob/living/carbon/V = hit_atom
		if(istype(V) && !V.stat && !istype(V,/mob/living/carbon/Xenomorph)) //We totally ignore other xenos. LIKE GREASED WEASELS
			if(istype(V,/mob/living/carbon/human) && charge_type != 2)
				var/mob/living/carbon/human/H = V //Human shield block.
				if((H.r_hand && istype(H.r_hand, /obj/item/weapon/shield/riot)) || (H.l_hand && istype(H.l_hand, /obj/item/weapon/shield/riot)))
					if (prob(45))	// If the human has riot shield in his hand,  65% chance
						src.Weaken(3) //Stun the fucker instead
						visible_message("\red <B> \The [src] bounces off [H]'s shield!</B>")
						src.throwing = 0
						return

			if(charge_type == 2) //Ravagers get a free attack if they charge into someone. This will tackle if disarm is set instead
				V.attack_alien(src)
				V.Weaken(1)
				src.throwing = 0

			if(charge_type == 1) //Runner/hunter pounce.
				visible_message("\red \The [src] pounces on [V]!","You pounce on [V]!")
				V.Weaken(4)
				src.canmove = 0
				src.frozen = 1
				src.loc = V.loc
				src.throwing = 0 //Stop the movement
				playsound(src.loc, 'sound/voice/shriek1.ogg', 50, 1)
				spawn(22)
					src.frozen = 0
		return

	if(isturf(hit_atom))
		var/turf/T = hit_atom
		if(T.density)
			src << "Bonk!" //ouchie
			src.Weaken(2)

	..() //Do the rest normally - mostly turfs.
	return

//Deal with armor deflection.
/mob/living/carbon/Xenomorph/bullet_act(var/obj/item/projectile/Proj) //wrapper
	if(Proj && istype(Proj) )
		var/dmg = Proj.damage
		if(istype(Proj,/obj/item/projectile/bullet/m56)) dmg += 10 //Smartgun hits weak points easier.
		if(prob(armor_deflection - dmg))
			visible_message("\blue The [src]'s thick exoskeleton deflects \the [Proj]!","\blue Your thick exoskeleton deflected \the [Proj]!")
			return -1
	..(Proj) //Do normal stuff

//Bleuugh
/mob/living/carbon/Xenomorph/proc/empty_gut()
	if(stomach_contents.len)
		for(var/S in src.stomach_contents)
			if(S)
				stomach_contents.Remove(S)
				S:loc = get_turf(src)

	if(contents.len) //Get rid of anything that may be stuck inside us as well
		for(var/A in src.contents)
			if(A)
				src.contents.Remove(A)
				A:loc = get_turf(src)

	return

/mob/living/carbon/Xenomorph/verb/toggle_darkness()
	set name = "Toggle Darkvision"
	set category = "Alien"

	if (see_invisible == SEE_INVISIBLE_LEVEL_TWO)
		see_invisible = SEE_INVISIBLE_OBSERVER_NOLIGHTING
	else
		see_invisible = SEE_INVISIBLE_LEVEL_TWO

