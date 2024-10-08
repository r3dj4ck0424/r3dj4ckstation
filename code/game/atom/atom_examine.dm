/atom
	/// If non-null, overrides a/an/some in all cases
	var/article
	/// Text that appears preceding the name in examine()
	var/examine_thats = "That's"

/mob/living/carbon/human
	examine_thats = "This is"

/mob/living/silicon/robot
	examine_thats = "This is"

/**
 * Called when a mob examines (shift click or verb) this atom
 *
 * Default behaviour is to get the name and icon of the object and its reagents where
 * the [TRANSPARENT] flag is set on the reagents holder
 *
 * Produces a signal [COMSIG_ATOM_EXAMINE]
 */
/atom/proc/examine(mob/user)
	. = list()
	. += get_name_chaser(user)
	if(desc)
		. += "<i>[desc]</i>"

	if(custom_materials)
		var/list/materials_list = list()
		for(var/custom_material in custom_materials)
			var/datum/material/current_material = GET_MATERIAL_REF(custom_material)
			materials_list += "[current_material.name]"
		. += "<u>It is made out of [english_list(materials_list)]</u>."

	if(reagents)
		var/user_sees_reagents = user.can_see_reagents()
		var/reagent_sigreturn = SEND_SIGNAL(src, COMSIG_ATOM_REAGENT_EXAMINE, user, ., user_sees_reagents)
		if(!(reagent_sigreturn & STOP_GENERIC_REAGENT_EXAMINE))
			if(reagents.flags & TRANSPARENT)
				if(reagents.total_volume)
					. += "It contains <b>[reagents.total_volume]</b> units of various reagents[user_sees_reagents ? ":" : "."]"
					if(user_sees_reagents || (reagent_sigreturn & ALLOW_GENERIC_REAGENT_EXAMINE)) //Show each individual reagent for detailed examination
						for(var/datum/reagent/current_reagent as anything in reagents.reagent_list)
							. += "&bull; [round(current_reagent.volume, CHEMICAL_VOLUME_ROUNDING)] units of [current_reagent.name]"
						if(reagents.is_reacting)
							. += span_warning("It is currently reacting!")
						. += span_notice("The solution's pH is [round(reagents.ph, 0.01)] and has a temperature of [reagents.chem_temp]K.")

				else
					. += "It contains:<br>Nothing."
			else if(reagents.flags & AMOUNT_VISIBLE)
				if(reagents.total_volume)
					. += span_notice("It has [reagents.total_volume] unit\s left.")
				else
					. += span_danger("It's empty.")

	SEND_SIGNAL(src, COMSIG_ATOM_EXAMINE, user, .)

/**
 * Called when a mob examines (shift click or verb) this atom twice (or more) within EXAMINE_MORE_WINDOW (default 1 second)
 *
 * This is where you can put extra information on something that may be superfluous or not important in critical gameplay
 * moments, while allowing people to manually double-examine to take a closer look
 *
 * Produces a signal [COMSIG_ATOM_EXAMINE_MORE]
 */
/atom/proc/examine_more(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/list)

	. = list()
	SEND_SIGNAL(src, COMSIG_ATOM_EXAMINE_MORE, user, .)
	SEND_SIGNAL(user, COMSIG_MOB_EXAMINING_MORE, src, .)

/**
 * Get the name of this object for examine
 *
 * You can override what is returned from this proc by registering to listen for the
 * [COMSIG_ATOM_GET_EXAMINE_NAME] signal
 */
/atom/proc/get_examine_name(mob/user)
	var/list/override = list(article, null, "<em>[get_visible_name()]</em>")
	SEND_SIGNAL(src, COMSIG_ATOM_GET_EXAMINE_NAME, user, override)

	if(!isnull(override[EXAMINE_POSITION_ARTICLE]))
		override -= null // IF there is no "before", don't try to join it
		return jointext(override, " ")
	if(!isnull(override[EXAMINE_POSITION_BEFORE]))
		override -= null // There is no article, don't try to join it
		return "\a [jointext(override, " ")]"
	return "\a [src]"

/mob/living/get_examine_name(mob/user)
	return get_visible_name()

/// Icon displayed in examine
/atom/proc/get_examine_icon(mob/user)
	return icon2html(src, user)

/**
 * Formats the atom's name into a string for use in examine (as the "title" of the atom)
 *
 * * user - the mob examining the atom
 * * thats - whether to include "That's", or similar (mobs use "This is") before the name
 */
/atom/proc/examine_title(mob/user, thats = FALSE)
	var/examine_icon = get_examine_icon(user)
	return "[examine_icon ? "[examine_icon] " : ""][thats ? "[examine_thats] ":""]<em>[get_examine_name(user)]</em>"

/**
 * Returns an extended list of examine strings for any contained ID cards.
 *
 * Arguments:
 * * user - The user who is doing the examining.
 */
/atom/proc/get_id_examine_strings(mob/user)
	. = list()

///Used to insert text after the name but before the description in examine()
/atom/proc/get_name_chaser(mob/user, list/name_chaser = list())
	return name_chaser

/// Used by mobs to determine the name for someone wearing a mask, or with a disfigured or missing face. By default just returns the atom's name. add_id_name will control whether or not we append "(as [id_name])".
/// force_real_name will always return real_name and add (as face_name/id_name) if it doesn't match their appearance
/atom/proc/get_visible_name(add_id_name, force_real_name)
	return name
