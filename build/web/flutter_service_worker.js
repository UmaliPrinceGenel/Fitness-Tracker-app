'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "1686c69e44ffc38855be0e44ff08c155",
"assets/AssetManifest.bin.json": "cd299264391047785708669949cb1b6c",
"assets/AssetManifest.json": "c4220f4fa07b00f3df974f3abd6555eb",
"assets/assets/abs.png": "a53d2e9e76d75506fbbc01b5df6026ea",
"assets/assets/album.jpg": "e2d2d6d547939c0eee7428bf4262e495",
"assets/assets/defaultVid.jpg": "d81a527bd172049052f13087b4f4aa93",
"assets/assets/default_picture.jpg": "777d95f2f957a91ebfd33932c892416d",
"assets/assets/figurines.png": "6fc8ce9ed23bb61d21bde0d4eb7b85eb",
"assets/assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Rowing_Machine_Intervals_.mp4": "92a51d9a2b0df5fcf493ae2793b9e366",
"assets/assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stair_Master_Climbing.mp4": "82ce90a52a3dae9977710fc9aa38835e",
"assets/assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Stationary_Bike_Sprints.mp4": "3248ffc0e21c0f1e2b6b239c49fe2b08",
"assets/assets/Fitness_Journey/Cardio/Workout_1_Gym_Machine_Intervals/Treadmill_Sprints.mp4": "501e087a38bdf1dede4bde98987be0d8",
"assets/assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Elliptical_Machine.mp4": "b8190f8b455a89a4d539be04fe0b315b",
"assets/assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Incline_Treadmill_Walk.mp4": "d9fa95b39fc48caeccb1d82d15336a9e",
"assets/assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Recumbent_Bike.mp4": "f252c45c6d7d97c671e540a361551c23",
"assets/assets/Fitness_Journey/Cardio/Workout_2_Steady-State_Cardio/Rowing_Machine_at_Moderate_Pace.mp4": "2491e557d835c579f2f4ae969902b0b7",
"assets/assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/High_Knees.mp4": "5e291ce800993d88c0f3ab3d50985b15",
"assets/assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jumping_Squats.mp4": "03dfdaed47dcf6575e506424b5c21997",
"assets/assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Jump_Rope.mp4": "0926dba102ef10a695aa3e258c9273e2",
"assets/assets/Fitness_Journey/Cardio/Workout_3_Bodyweight_Cardio_Blast/Skater_Jumps.mp4": "d6d737161db9c485b2e7d384a4f9772c",
"assets/assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Assault_Bike.mp4": "294942bdceca55858b09a8936999a0ae",
"assets/assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Brisk_Walking_Cooldown.mp4": "651dac3352a16270f84fdca1724b7263",
"assets/assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/Rowing_Machine_at_Moderate_Pace_.mp4": "f8ba9806ee88b5545445d61f41560899",
"assets/assets/Fitness_Journey/Cardio/Workout_4_Endurance_Cardio_Circuit/SkiErg_.mp4": "602df536164bd22fdd15dc58dcefa2fd",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Chest_Press.mp4": "169ed03901d10800a2f5cf6f6b60daff",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_1_Beginner_Machine_Circuit/Machine_Leg_Press.mp4": "f2c226b664548ed6dca11b634a902b98",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Bird_Dog.mp4": "e8f8d6f96ba98afc0e732e998d603d2f",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Cat_-_Cow_Stretch.mp4": "20d8440a879fabf27f3fec457f848271",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_2_Core_Stability_and_Mobility/Forearm_Plank.mp4": "312830f9d0adcf91592ad8550cac55f8",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Bodyweight_Squats.mp4": "32a970a8ac38759279aa702b8bbf0f66",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Light_Stationary_Bike.mp4": "da85e9cb463bbd884bbd234d7ba13388",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Standing_Stretch_Routine.mp4": "0404bfff91e5c75032366ba214bf72e0",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_3_Active_Recovery/Swiss_Ball_Crunch.mp4": "b62ed913111ea759c16d1725f85885e3",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Dumbbell_Bicep_Curls.mp4": "6dbe0deb6520acb2bb6be0d87f59eaf0",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Light_Dumbbell_Romanian_Deadlift_.mp4": "0d8a57cc8cb373d917b1f641c8972381",
"assets/assets/Fitness_Journey/General_Health_&_Wellness/Workout_4_Light_Free_Weights_Introduction/Triceps_Dumbbell_Kickbacks.mp4": "85ecf3f732c0c197eee5111e01dcfb57",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Box_Step_up.mp4": "91e7332e41f922460bc46e9b74b6a469",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Goblet_Squats.mp4": "180aabe1443c55dc24c3d14684fd6f19",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Walking_Lunge.mp4": "8b33c433adc14f88bd35b943b95a3e69",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_1_Lower_Body_Stamina/Wall_Sits.mp4": "daf8bce0fff5ef58d3aac1cc8233034f",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Inverted_Row.mp4": "922118c31df8597272a3aac58d4a1662",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_2_Upper_Body_Endurance/Light_Dumbbell_Shoulder_Press_.mp4": "ecedca8056c145f7961ee9894a42e0fa",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Jumping_Lunges_.mp4": "6a6f98e1eebe928944e8c3d04d7e5bef",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Kettlebell_Swings.mp4": "d07029ef7039466f70d7682d76b4a0d9",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/Lightweight_Barbell_Squats.mp4": "6cf499fa45e09beb15ad060d51289ab6",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_3_High-Rep_Full_Body_Challenge/TRX_Rows.mp4": "dbcb02632dc3d75468ec38c0fcf560b2",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Farmer%25E2%2580%2599s_Carries.mp4": "d6408ce4727863a42823978a5fc2f4c4",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Hollow_Body_Hold.mp4": "1ffd6bedbd0fb5325c68343374adf168",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Plank_Holds.mp4": "ecde0eb174e7305e6f5985e4069ee8de",
"assets/assets/Fitness_Journey/Muscular_Endurance/Workout_4_Core_and_Carry_Endurance/Suitcase_Carries.mp4": "e33dee615cb9dc3b1c14f6b03602e921",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Back_Squat.mp4": "73937036b7ec1f935ab8ff1caee528c1",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_1_The_Big_Three/Barbell_Conventional_Deadlift_.mp4": "4742faf30e42b10a4f2c4e834245cb8a",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Barbell_Overhead_Press.mp4": "da4e95a020c924d3f2f3071400aaffcb",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Close_Grip_Barbell_Bench_Press_.mp4": "93c11df3ce06bbc554f795bcc10e9049",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Dumbbell_Weighted_Dip.mp4": "fc087b365ad1eb205e58615248a61b61",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_2_Upper_Body_Push_Strength/Incline_Barbell_Press_.mp4": "ae3f8751a0fb40ca74edc57f3d6625b9",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Barbell_Pendlay_Rows_.mp4": "72a10e75e75aa08311b5c9aa1b848c70",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Heavy_Dumbbell_Shrugs.mp4": "e86996d9032256e2223936ebca3151f2",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_3_Upper_Body_Pull_Strength/Weighted_Pull-Ups.mp4": "13e46d13e57b9383132798a15356ba58",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Kettlebell_Swing.mp4": "ce540c108ff916c0fbbbea4704ece538",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Heavy_Medicine_Ball_Throws_.mp4": "259990853f4f9e5b69209d4c1ec6b04f",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Power_Cleans.mp4": "11ff8d4b1a736aa7b258854426ff1384",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_4_Explosive_Power/Push_Press.mp4": "6fcd545f391007e24863052c02edf579",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Good_Mornings.mp4": "214e94ace5a59100beb7d08cb8700dc2",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Barbell_Romanian_Deadlift_.mp4": "b3ccb8c79452a281fa50a550ec18c7ce",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Farmers_Walk.mp4": "fa4cee49afbb96470f12edcb1b83cc58",
"assets/assets/Fitness_Journey/Strength_&_Power/Workout_5_Posterior_Chain_Strength/Glute-Ham_Raises.mp4": "3fea0720f71b5c6533a67947dc820831",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Burpees.mp4": "cc62c4a244639d914c4c54004e561133",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Jumping_Jacks_.mp4": "a4be2de96c7544cc1f4b24f84eb44d82",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Kettlebell_Swings_.mp4": "b636a43802cb6dda9db39dff798d8f40",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_1_Full_Body_HIIT_Circuit/Mountain_Climbers.mp4": "32d27940f10087dfc27af7e427180ce5",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Alternating_Dumbbell_Lunges.mp4": "2c0871488da8b2e79ab3e5ee4c25d100",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Snatch_.mp4": "a693a8ba31607abf78b6c3db414cfd0a",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Dumbbell_Thrusters.mp4": "c609313693b53fef505bdac3afd01cde",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_2_Dumbbell_Fat_Burner/Renegade_Rows_.mp4": "a41c444ba8ab3f8d3bedcd75666fac75",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Battle_Ropes.mp4": "2d7e67aeaf3606f96b1403cf8d6fc122",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Box_Jumps.mp4": "333acabd81dd88eb3265d9137b107089",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Jump_Rope_.mp4": "b43403c3b9497a3591081306e752bbeb",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_3_Metabolic_Conditioning/Medicine_Ball_Slams_.mp4": "68fd1f2ef369300b7caf764a8cf08a9e",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Bear_Crawls_.mp4": "eeaca9248eb4eff39a084b788f63ad67",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/High_Knees_.mp4": "4a40a1f9989dd0db7fd68f5dec09e6f6",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Plank_Jacks_.mp4": "fee2401b72dfce11d36c07e79e3a509a",
"assets/assets/Fitness_Journey/Weight_Loss/Workout_4_Bodyweight_Calorie_Crusher/Squat_Jumps_.mp4": "2fc83a80eadca3b045922538d6223d69",
"assets/assets/google.png": "b1f3d10a7c3d9f33132c6da22e24add6",
"assets/assets/logo.jpg": "e2d2d6d547939c0eee7428bf4262e495",
"assets/assets/logo.txt": "0611f058494afa3807b262673294f717",
"assets/assets/mog.jpg": "a5284afe578f15e9ccf17cda701be935",
"assets/assets/thumbnails/Abs/abs_training_easy.png": "d51ed238f93659962c4dbb34e1e34dc8",
"assets/assets/thumbnails/Abs/abs_training_hard.png": "ccb5d80db0203a025b36ef204c2f7175",
"assets/assets/thumbnails/Abs/abs_training_medium.png": "1c15cdc5e9d511be6e576d68f1352fe2",
"assets/assets/thumbnails/Biceps/biceps_training_easy.png": "8225715787343651dce290a1414daedb",
"assets/assets/thumbnails/Biceps/biceps_training_hard.png": "5bf1c44ea97cc8cdb9e336d98334c640",
"assets/assets/thumbnails/Biceps/biceps_training_medium.png": "f5e820390aaa7d606070ab1faeed8489",
"assets/assets/thumbnails/Calves/calves_training_easy.png": "276356687e5344bd143556c802ddd216",
"assets/assets/thumbnails/Calves/calves_training_medium.png": "9d1e4cc269be64adcb9b8a37ac0f9368",
"assets/assets/thumbnails/Chest/chest_training_easy.png": "eb0af6c0f93d5fc07287a70395f5a9c8",
"assets/assets/thumbnails/Chest/chest_training_hard.png": "0683e77f7dfedeb1b079f9f33f543d48",
"assets/assets/thumbnails/Chest/chest_training_medium.png": "78448e08e741d3344cc42d98eba2fc2c",
"assets/assets/thumbnails/Forearms/forearms_training_medium.png": "e2fdab814e4e4bcad97a80db190bb018",
"assets/assets/thumbnails/Glutes%2520&%2520Hamstrings/glutes_hamstrings_training_easy.png": "6ed1c66be5cc07e162ee57c0f9998168",
"assets/assets/thumbnails/Glutes%2520&%2520Hamstrings/glutes_hamstrings_training_hard.png": "c0337ca8b04caf910c8215c8516f567c",
"assets/assets/thumbnails/Glutes%2520&%2520Hamstrings/glutes_hamstrings_training_medium.png": "679ed4f65cd85059813f2918e7d92d69",
"assets/assets/thumbnails/Journeys/journey_cardio_thumb.png": "78a8d1044b3bc2e36dd4c4675dec89f0",
"assets/assets/thumbnails/Journeys/journey_health_wellness_thumb.png": "f28fa5bed654a4e2014d4fd233c566cb",
"assets/assets/thumbnails/Journeys/journey_muscular_endurance_thumb.png": "a1d6f55624a85df04560b8a663bc37d9",
"assets/assets/thumbnails/Journeys/journey_strength_power_thumb.png": "f7a7b46c2253af447a750f4ce19c15d9",
"assets/assets/thumbnails/Journeys/journey_weight_loss_thumb.png": "d8917ce758f045cc2749722818609e10",
"assets/assets/thumbnails/Quads/quads_training_easy.png": "09e88c6b435283662ebf46aa7b45173f",
"assets/assets/thumbnails/Quads/quads_training_hard.png": "cf889174ec1acc52efc5fd5fca001be0",
"assets/assets/thumbnails/Quads/quads_training_medium.png": "003b477e574e5c064b0b39192d594249",
"assets/assets/thumbnails/Rotational%2520Core/rotational_core_training_easy.png": "92e85b5594dad4d3b6d5ed3c0ef0ad9b",
"assets/assets/thumbnails/Rotational%2520Core/rotational_core_training_hard.png": "d22ba20febf207760326fdaf53b4091f",
"assets/assets/thumbnails/Rotational%2520Core/rotational_core_training_medium.png": "9d663c0adfc47935fbfc41788c58f263",
"assets/assets/thumbnails/Shoulders/shoulders_training_easy.png": "c01611ba4592d593b45d885742281db0",
"assets/assets/thumbnails/Shoulders/shoulders_training_hard.png": "1f91b38e052f70d95a74bd1ed00f1af0",
"assets/assets/thumbnails/Shoulders/shoulders_training_medium.png": "69782924c62a511ecf7c8bee0c086728",
"assets/assets/thumbnails/Traps/traps_training_easy.png": "6830bd170acc8e0674fb45bb27e60d75",
"assets/assets/thumbnails/Traps/traps_training_hard.png": "b949877b02a458567ddb3edcfc624067",
"assets/assets/thumbnails/Triceps/triceps_training_easy.png": "58be2f5b30b50b6427841d46ab2c2f26",
"assets/assets/thumbnails/Triceps/triceps_training_hard.png": "427dd07ae33a5600ba99cf447021af98",
"assets/assets/thumbnails/Triceps/triceps_training_medium.png": "3a7e5f5b6eede1d9418030b033db490e",
"assets/assets/thumb_test.png": "0d88fdae7ce6e0d680ff1a6f92c53cfe",
"assets/assets/videos/Back/Lats/lat_pulldowns.mp4": "60c7454dfb1a774e5fc28158f5ac333a",
"assets/assets/videos/Back/Lats/pull_ups_chin_ups.mp4": "9d9c09059e884f42f5a67f592d910ce0",
"assets/assets/videos/Back/Lats/single_arm_dumbbell_rows.mp4": "b276855105097f3726f49ce35581a393",
"assets/assets/videos/Back/Mid-Back/barbell_rows.mp4": "3ae731e98d4e97eb46d882b646aea00d",
"assets/assets/videos/Back/Mid-Back/face_pulls_back.mp4": "7b7feb0fbf7fe08b5eb514474ab6173c",
"assets/assets/videos/Back/Mid-Back/seated_cable_rows.mp4": "82901a9d9d52392b95a6380359694b07",
"assets/assets/videos/Back/Mid-Back/t_bar_row_machine_row.mp4": "363be7f6fc91676c1976c10ad177073e",
"assets/assets/videos/Biceps/barbell_dumbbell_bicep_curls.mp4": "2eba12bf09fa5a706e292d976a0edf2d",
"assets/assets/videos/Biceps/ccncentration_curls.mp4": "fe3982ab4b7b3ab560e25b1701db25d4",
"assets/assets/videos/Biceps/hammer_curls.mp4": "d7a993cac089caa1413bb350ff3321d3",
"assets/assets/videos/Biceps/preacher_curls.mp4": "133099c8312f11d549b4ebe26037433c",
"assets/assets/videos/Calves/seated_calf_raises.mp4": "cdcb5111d4cc1de92ba653fd21874c9d",
"assets/assets/videos/Calves/standing_calf_raises.mp4": "7ba35e30d538fb732046c9e6e8f164f7",
"assets/assets/videos/Chest/barbel_bench_press.mp4": "81dc4b8809427b73af3f912f6027d221",
"assets/assets/videos/Chest/cable_crossover.mp4": "7c177bce0fd7978ca187486898ea9fc9",
"assets/assets/videos/Chest/decline_bench_press.mp4": "b6a4d990a5e64ccbf7bcf0496d4bd9fb",
"assets/assets/videos/Chest/dumbbell_bench_press.mp4": "7e07c777937f0f43b05c15a1d3e2ec15",
"assets/assets/videos/Chest/dumbbell_flyes.mp4": "5a759f85d35cad61544522a2170da2ac",
"assets/assets/videos/Chest/incline_bench_press.mp4": "b74d8d1c3f147c9cb5f44d1f94e95f57",
"assets/assets/videos/Chest/incline_dumbbell_bench_press.mp4": "a9c2838aeb502f6a2aa168260db9f0ec",
"assets/assets/videos/Chest/push_ups.mp4": "1075fec4fff40c60288d143d2611bdf7",
"assets/assets/videos/Forearms/wrist_curls_palms_up_down.mp4": "7173172dd16a2c85da3826e9022948ae",
"assets/assets/videos/Glutes%2520&%2520Hamstrings/barbell_deadlift_glutes.mp4": "abf3e859a097246b0a0859bdecb879b4",
"assets/assets/videos/Glutes%2520&%2520Hamstrings/glute_bridges_hip_thrusts.mp4": "06f8e156dda6f94c5b38a75a13a97302",
"assets/assets/videos/Glutes%2520&%2520Hamstrings/hip_thrusts.mp4": "0ef7553e253ab0590c02fa800796fa88",
"assets/assets/videos/Glutes%2520&%2520Hamstrings/lying_seated_leg_curls.mp4": "983e08bf598496298f7296d938a86551",
"assets/assets/videos/Glutes%2520&%2520Hamstrings/romanian_deadlifts_rdls.mp4": "4f6e8cb0b65ce0b2940e7ad55254b878",
"assets/assets/videos/Quads/barbell_forward_lunge.mp4": "dd78a22681adcd6fed09b650451cb428",
"assets/assets/videos/Quads/barbell_squat.mp4": "0abd8f543fb41a698a8294f2b27bf081",
"assets/assets/videos/Quads/leg_extensions.mp4": "b3b3c85a8310fc6bd0a9162cd832110f",
"assets/assets/videos/Quads/leg_press.mp4": "a62b919ea80309e2ff665271664cbd60",
"assets/assets/videos/Quads/lunges.mp4": "97491dedaf8a43265c243e531ec01600",
"assets/assets/videos/Rotational%2520-%2520Anti-Rotation%2520(Obliques-Deep%2520Core)/pallof_press.mp4": "a29f2acbe0c4a9c56ac37313dc12c849",
"assets/assets/videos/Rotational%2520-%2520Anti-Rotation%2520(Obliques-Deep%2520Core)/russian_twists.mp4": "a14225af43aa96eb6a39eb52c9d77b14",
"assets/assets/videos/Rotational%2520-%2520Anti-Rotation%2520(Obliques-Deep%2520Core)/side_plank.mp4": "25d3519b4e4dbb5800cf8988315cdbc8",
"assets/assets/videos/Rotational%2520-%2520Anti-Rotation%2520(Obliques-Deep%2520Core)/wood_chops.mp4": "3b09d60de7c14ecbbede1d84d0916f91",
"assets/assets/videos/Shoulder/Anterior/dumbbell_front_raises.mp4": "bc798c47a8f42d2f69c448d61e38d099",
"assets/assets/videos/Shoulder/Anterior/overhead_press.mp4": "015ddb4f680a2cdaa7f804d43d7d9500",
"assets/assets/videos/Shoulder/Anterior/standing_barbell_shoulder_press.mp4": "8a82ca093854651730991812f995e1c6",
"assets/assets/videos/Shoulder/Medial/barbell_upright_row.mp4": "f677ec7d1331e5ad89198bde6ced4d44",
"assets/assets/videos/Shoulder/Medial/cable_lateral_raises.mp4": "68641fc560a1733fb6d8ca3ce1e43850",
"assets/assets/videos/Shoulder/Medial/dumbbell_cable_lateral_raises.mp4": "fca70e0a581be3a35992dc09538828eb",
"assets/assets/videos/Shoulder/Medial/upright_rows.mp4": "fa8d81870526fcd429dc9319696e06a6",
"assets/assets/videos/Shoulder/Posterior/face_pulls_back.mp4": "d362df6db09e16e3544c1d955e25f35f",
"assets/assets/videos/Shoulder/Posterior/rear_delt_fly.mp4": "8671b03864478238ab2b9cca56e8f067",
"assets/assets/videos/Spinal%2520Flexion%2520(Rectus%2520Abdominis)/ab_wheel_rollouts.mp4": "771b37365db5f730c7301b9197781f78",
"assets/assets/videos/Spinal%2520Flexion%2520(Rectus%2520Abdominis)/cable_crunches.mp4": "22ce72c7129ad3749dc7f3d582847f4b",
"assets/assets/videos/Spinal%2520Flexion%2520(Rectus%2520Abdominis)/hanging_leg_raises.mp4": "7d5934f2faac2d11d63e4515c63cc59a",
"assets/assets/videos/Spinal%2520Flexion%2520(Rectus%2520Abdominis)/reverse_crunches.mp4": "6868e7c83461f9f9c3c6d223ca2e154b",
"assets/assets/videos/Traps/barbell_deadlift.mp4": "abf3e859a097246b0a0859bdecb879b4",
"assets/assets/videos/Traps/barbell_dumbbell_shrugs.mp4": "d5729b133e65f825e72e57429e706ff7",
"assets/assets/videos/Traps/rack_pulls.mp4": "058fb338932eb48c5f8fc4885cd0a73b",
"assets/assets/videos/Triceps/dumbbell_skull_crusher_opex_exercise_library.mp4": "af5fb289956769c3acee049505fa903b",
"assets/assets/videos/Triceps/overhead_tricep_extension.mp4": "7f6d87d5d0ace80504dc93c0263c969f",
"assets/assets/videos/Triceps/tricep_pushdowns.mp4": "61c20f69696453aac254fc6302690515",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "2d6594f8c640cab2c0f64b557ddcd014",
"assets/NOTICES": "03debc6d12bb056d0058c9ed272df001",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "d7d83bd9ee909f8a9b348f56ca7b68c6",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "754df9a2b7d45ba467b1de9a98ed15c5",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "2d30c9dadca8c67f56819de5f1abd477",
"/": "2d30c9dadca8c67f56819de5f1abd477",
"main.dart.js": "76f5f3b09ca6a4007cf5b9dfa842ca87",
"manifest.json": "84f4ca0c8768dc115c1b15f460c7746c",
"vercel.json": "0db7ccb3aff36e97aa469126e9e17f99",
"version.json": "0c019d6c4e61f3610fc2bbeebbedb20e",
"webllm_bridge.js": "206488d2de2e790a11df16227d41bb40",
"webllm_worker.js": "40e5c5e578c7f18def746316b53888f3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
