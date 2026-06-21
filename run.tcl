set src_files [glob -nocomplain src/*.v]
set tb_files [glob -nocomplain tb/tb_top.v]

set all_files [concat $src_files $tb_files]

eval exec iverilog -o core_out $all_files

set sim_output [exec vvp core_out]

puts $sim_output