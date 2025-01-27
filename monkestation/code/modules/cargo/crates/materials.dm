/datum/supply_pack/materials/random_materials
	name = "Contracted Materials"
	desc = "No Miners? We'll contract the work and send you the materials! Contains a random assortment of processed materials."
	cost = CARGO_CRATE_VALUE * 6
	contains = list()

/datum/supply_pack/materials/random_materials/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 5)
		var/item = pick(
			prob(200);
				/obj/item/stack/sheet/iron/fifty,
			prob(100);
				/obj/item/stack/sheet/glass/fifty,
			prob(50);
				/obj/item/stack/sheet/plastic/fifty,
			prob(50);
				/obj/item/stack/sheet/mineral/plasma/twenty,
			prob(20);
				/obj/item/stack/sheet/plasteel/twenty,
			prob(20);
				/obj/item/stack/sheet/mineral/titanium/twenty,
			prob(10);
				/obj/item/stack/sheet/mineral/silver/twenty,
			prob(10);
				/obj/item/stack/sheet/mineral/gold/five,
			prob(5);
				/obj/item/stack/sheet/mineral/diamond/five,
			prob(5);
				/obj/item/stack/sheet/bluespace_crystal/five,
			prob(5);
				/obj/item/stack/sheet/mineral/uranium/five
		)
		new item(C)


/datum/supply_pack/materials/glass250
	name = "250 Glass sheets"
	desc = "Bulk glass for your greenhouse needs!"
	cost = CARGO_CRATE_VALUE * 6
	contains = list(/obj/item/stack/sheet/glass/fifty = 5)

/datum/supply_pack/materials/iron250
	name = "250 Iron sheets"
	desc = "For times 50 just isn't enough."
	cost = CARGO_CRATE_VALUE * 6
	contains = list(/obj/item/stack/sheet/iron/fifty = 5)
