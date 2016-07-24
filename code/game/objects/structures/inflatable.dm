/obj/item/inflatable
	name = "inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_wall"
	w_class = 2

/obj/item/inflatable/attack_self(mob/user)
	playsound(loc, 'sound/items/zip.ogg', 75, 1)
	user << "<span class='notice'>You inflate [src].</span>"
	var/obj/structure/inflatable/R = new /obj/structure/inflatable(user.loc)
	transfer_fingerprints_to(R)
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/inflatable
	name = "inflatable wall"
	desc = "An inflated membrane. Do not puncture."
	density = 1
	anchored = 1
	opacity = 0

	icon = 'icons/obj/inflatable.dmi'
	icon_state = "wall"

	var/health = 50
	var/brokenpath = /obj/item/inflatable/torn

/obj/structure/inflatable/New(location)
	..()
	air_update_turf(1)

/obj/structure/inflatable/Destroy()
	air_update_turf(1)
	return ..()

/obj/structure/inflatable/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return 0

/obj/structure/inflatable/CanAtmosPass(turf/T)
	return !density

/obj/structure/inflatable/bullet_act(var/obj/item/projectile/Proj)
	health -= Proj.damage
	..()
	if(health <= 0)
		deflate(1)
	return

/obj/structure/inflatable/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
			return
		if(2)
			deflate(1)
			return
		if(3)
			if(prob(50))
				deflate(1)
				return

/obj/structure/inflatable/blob_act()
	deflate(1)

/obj/structure/inflatable/attack_hand(mob/user as mob)
	add_fingerprint(user)
	..()
	return

/obj/structure/inflatable/proc/attack_generic(mob/user as mob, damage = 0)	//used by attack_alien, attack_animal, and attack_slime
	health -= damage
	if(health <= 0)
		user.visible_message("<span class='danger'>[user] tears open [src]!</span>")
		deflate(1)
	else	//for nicer text~
		user.visible_message("<span class='danger'>[user] tears at [src]!</span>")

/obj/structure/inflatable/attack_alien(mob/user as mob)
	if(islarva(user))
		return
	attack_generic(user, 15)

/obj/structure/inflatable/attack_animal(mob/user as mob)
	if(!isanimal(user))
		return
	var/mob/living/simple_animal/M = user
	if(M.melee_damage_upper <= 0)
		return
	attack_generic(M, M.melee_damage_upper)

/obj/structure/inflatable/attack_slime(mob/user as mob)
	attack_generic(user, rand(10, 15))

/obj/structure/inflatable/attackby(obj/item/weapon/W as obj, mob/user as mob, params)
	user.changeNext_move(CLICK_CD_MELEE)
	if(!istype(W))
		return
	if(W.is_sharp())
		visible_message("<span class='danger'><b>[user] pierces [src] with [W]!</b></span>")
		deflate(1)
	if(W.damtype == BRUTE || W.damtype == BURN)
		hit(W.force)
		..()
	return

/obj/structure/inflatable/proc/hit(var/damage, var/sound_effect = 1)
	health = max(0, health - damage)
	if(sound_effect)
		playsound(loc, 'sound/effects/Glasshit.ogg', 75, 1)
	if(health <= 0)
		deflate(1)

/obj/structure/inflatable/AltClick()
	if(usr.stat || usr.restrained())
		return
	if(!Adjacent(usr))
		return
	deflate()

/obj/structure/inflatable/proc/deflate(var/violent=0)
	playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
	if(violent)
		visible_message("<span class='danger'>[src] rapidly deflates!</span>")
		var/obj/item/inflatable/torn/R = new /obj/item/inflatable/torn(loc)
		src.transfer_fingerprints_to(R)
		qdel(src)
	else
		visible_message("<span class='danger'>[src] slowly deflates.</span>")
		spawn(50)
			var/obj/item/inflatable/R = new /obj/item/inflatable(loc)
			src.transfer_fingerprints_to(R)
			qdel(src)

/obj/structure/inflatable/verb/hand_deflate()
	set name = "Deflate"
	set category = "Object"
	set src in oview(1)

	if(usr.stat || usr.restrained())
		return

	deflate()

/obj/item/inflatable/door
	name = "inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_door"

/obj/item/inflatable/door/attack_self(mob/user)
	playsound(loc, 'sound/items/zip.ogg', 75, 1)
	user << "<span class='notice'> You inflate [src].</span>"
	var/obj/structure/inflatable/door/R = new /obj/structure/inflatable/door(user.loc)
	src.transfer_fingerprints_to(R)
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/inflatable/door //Based on mineral door code
	name = "inflatable door"
	density = 1
	anchored = 1
	opacity = 0

	icon = 'icons/obj/inflatable.dmi'
	icon_state = "door_closed"

	var/state = 0 //closed, 1 == open
	var/isSwitchingStates = 0

/obj/structure/inflatable/door/attack_ai(mob/user as mob) //those aren't machinery, they're just big fucking slabs of a mineral
	if(isAI(user)) //so the AI can't open it
		return
	else if(isrobot(user)) //but cyborgs can
		if(get_dist(user,src) <= 1) //not remotely though
			return TryToSwitchState(user)

/obj/structure/inflatable/door/attack_hand(mob/user as mob)
	return TryToSwitchState(user)

/obj/structure/inflatable/door/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group)
		return state
	if(istype(mover, /obj/effect/beam))
		return !opacity
	return !density

/obj/structure/inflatable/door/CanAtmosPass(turf/T)
	return !density

/obj/structure/inflatable/door/proc/TryToSwitchState(atom/user)
	if(isSwitchingStates)
		return
	if(ismob(user))
		var/mob/M = user
		if(M.client)
			if(iscarbon(M))
				var/mob/living/carbon/C = M
				if(!C.handcuffed)
					SwitchState()
			else
				SwitchState()
	else if(istype(user, /obj/mecha))
		SwitchState()

/obj/structure/inflatable/door/proc/SwitchState()
	if(state)
		Close()
	else
		Open()
	air_update_turf(1)

/obj/structure/inflatable/door/proc/Open()
	isSwitchingStates = 1
	//playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 100, 1)
	flick("door_opening",src)
	sleep(10)
	density = 0
	opacity = 0
	state = 1
	update_icon()
	isSwitchingStates = 0

/obj/structure/inflatable/door/proc/Close()
	isSwitchingStates = 1
	//playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 100, 1)
	flick("door_closing",src)
	sleep(10)
	density = 1
	opacity = 0
	state = 0
	update_icon()
	isSwitchingStates = 0

/obj/structure/inflatable/door/update_icon()
	if(state)
		icon_state = "door_open"
	else
		icon_state = "door_closed"

/obj/structure/inflatable/door/deflate(var/violent=0)
	playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
	if(violent)
		visible_message("<span class='danger'>[src] rapidly deflates!</span>")
		var/obj/item/inflatable/door/torn/R = new /obj/item/inflatable/door/torn(loc)
		src.transfer_fingerprints_to(R)
		qdel(src)
	else
		visible_message("<span class='danger'>[src] slowly deflates.</span>")
		spawn(50)
			var/obj/item/inflatable/door/R = new /obj/item/inflatable/door(loc)
			src.transfer_fingerprints_to(R)
			qdel(src)
	air_update_turf(1)

/obj/item/inflatable/torn
	name = "torn inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_wall_torn"

/obj/item/inflatable/torn/attack_self(mob/user)
	user << "<span class='warning'>The inflatable wall is too torn to be inflated, fix it with something!</span>"
	add_fingerprint(user)

/obj/item/inflatable/torn/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/ducttape))
		var/obj/item/stack/ducttape/T = I
		if(T.amount < 2)
			user << "<span class='danger'>There is not enough tape!</span>"
			return
		user << "<span class='notice'>You begin fixing the [src]!</span>"
		playsound(user, 'sound/items/ducttape1.ogg', 50, 1)
		if(do_mob(user, src, 20))
			user << "<span class='notice'>You fix the [src] using the ducttape!</span>"
			T.use(2)
			new /obj/item/inflatable(user.loc)
			qdel(src)

/obj/item/inflatable/door/torn
	name = "torn inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_door_torn"

/obj/item/inflatable/door/torn/attack_self(mob/user)
	user << "<span class='warning'>The inflatable door is too torn to be inflated, fix it with something!</span>"
	add_fingerprint(user)


/obj/item/inflatable/door/torn/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/ducttape))
		var/obj/item/stack/ducttape/T = I
		if(T.amount < 2)
			user << "<span class='danger'>There is not enough tape!</span>"
			return
		user << "<span class='notice'>You begin fixing the [src]!</span>"
		playsound(user, 'sound/items/ducttape1.ogg', 50, 1)
		if(do_mob(user, src, 25))
			user << "<span class='notice'>You fix the [src] using the ducttape!</span>"
			T.use(2)
			new /obj/item/inflatable/door(user.loc)
			qdel(src)

/obj/item/weapon/storage/inflatable
	name = "inflatable barrier box"
	desc = "Contains inflatable walls and doors."
	icon_state = "inf"
	item_state = "syringe_kit"
	max_combined_w_class = 21
	w_class = 3

/obj/item/weapon/storage/inflatable/New()
	..()
	for(var/i = 0, i < 8, i ++)
		new /obj/item/inflatable/door(src)
	for(var/i = 0, i < 16, i ++)
		new /obj/item/inflatable(src)

/obj/item/inflatable/suicide_act(mob/living/user)
	visible_message(user, "<span class='danger'>[user] starts shoving the [src] up his ass! It looks like hes going to pull the cord, oh shit!</span>")
	playsound(user.loc, 'sound/machines/hiss.ogg', 75, 1)
	new type(user.loc)
	user.gib()
	return BRUTELOSS