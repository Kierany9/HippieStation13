/obj/effect/proc_holder/changeling/adrenaline
	name = "Adrenaline Sacs"
	desc = "We evolve additional sacs of adrenaline throughout our body."
	helptext = "Removes all stuns instantly and adds a short-term reduction in further stuns. Can be used while unconscious. Continued use poisons the body."
	chemical_cost = 30
	evopoints_cost = 4
	req_dna = 3 //Tier 2
	req_human = 1
	req_stat = UNCONSCIOUS

//Recover from stuns.
/obj/effect/proc_holder/changeling/adrenaline/sting_action(mob/living/user)
	user << "<span class='notice'>Energy rushes through us.[user.lying ? " We arise." : ""]</span>"
	user.stat = 0
	user.SetParalysis(0)
	user.SetStunned(0)
	user.SetWeakened(0)
	user.lying = 0
	user.update_canmove()
	user.reagents.add_reagent("changelingAdrenaline", 10)
	user.reagents.add_reagent("changelingAdrenaline2", 2) //For a really quick burst of speed
	user.adjustStaminaLoss(-75)
	feedback_add_details("changeling_powers","UNS")
	return 1

/datum/reagent/medicine/changelingAdrenaline
	name = "Adrenaline"
	id = "changelingAdrenaline"
	description = "Reduces stun times. Also deals toxin damage at high amounts."
	color = "#C8A5DC"
	overdose_threshold = 30
	stun_threshold = 4

/datum/reagent/medicine/changelingAdrenaline/on_mob_life(mob/living/M as mob)
	if(!(M.stunned || M.weakened || M.paralysis))
		stun_timer++
		metabolization_rate = REAGENTS_METABOLISM
		M.adjustStaminaLoss(-1)
	else
		metabolization_rate = 2 * REAGENTS_METABOLISM
		M.adjustStaminaLoss(6) //Actually 4, humans regenerate 2 per tick
	if(stun_timer >= stun_threshold && (M.stunned || M.weakened || M.paralysis))
		for(var/datum/reagent/R in M.reagents.reagent_list)
			R.stun_timer = 0
		M.AdjustParalysis(-3)
		M.AdjustStunned(-4)
		M.AdjustWeakened(-4)
	..()
	return

/datum/reagent/medicine/changelingAdrenaline/overdose_process(mob/living/M as mob)
	M.adjustToxLoss(1)
	..()
	return

/datum/reagent/medicine/changelingAdrenaline2
	name = "Adrenaline"
	id = "changelingAdrenaline2"
	description = "Drastically increases movement speed."
	color = "#C8A5DC"
	metabolization_rate = 1
	speedboost = VERY_FAST

/datum/reagent/medicine/changelingAdrenaline2/on_mob_life(mob/living/M as mob)
	M.adjustToxLoss(2)
	..()
	return
