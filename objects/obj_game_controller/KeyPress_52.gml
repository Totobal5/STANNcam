/// @description Inserte aquí la descripción
run_stanncam_tests();

call_later(2, time_source_units_frames, function() {
    room_goto(room);
});