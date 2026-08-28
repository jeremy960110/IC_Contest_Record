#Read All Files
read_verilog LCD_CTRL.v
current_design LCD_CTRL
link

#Setting Clock Constraints
source -echo -verbose LCD_CTRL.sdc

#Synthesis all design
compile -map_effort high -area_effort high
compile -map_effort high -area_effort high -inc

# ---> 必須把 change_names 移到 compile 之後，輸出檔案之前 <---
change_names -rules name_rule -hierarchy

#Write Output Files
write -format ddc     -hierarchy -output "LCD_CTRL_syn.ddc"
write_sdf LCD_CTRL_syn.sdf
write_file -format verilog -hierarchy -output LCD_CTRL_syn.v

#Reports
report_area > area.log
report_timing > timing.log
report_qor   >  LCD_CTRL_syn.qor
