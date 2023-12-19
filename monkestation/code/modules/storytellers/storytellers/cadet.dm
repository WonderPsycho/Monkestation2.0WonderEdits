/datum/storyteller/cadet
	name = "The Cadet"
	desc = "The Cadet will create mostly internal conflict around the station, and rarely any external threats."
	event_repetition_multiplier = 1
	point_gains_multipliers = list(
		EVENT_TRACK_MUNDANE = 1.2,
		EVENT_TRACK_MODERATE = 1.1,
		EVENT_TRACK_MAJOR = 0.9,
		EVENT_TRACK_ROLESET = 0.9,
		EVENT_TRACK_OBJECTIVES = 1
		)
	tag_multipliers = list(TAG_SECURITY = 0.2)
	weight = 3
