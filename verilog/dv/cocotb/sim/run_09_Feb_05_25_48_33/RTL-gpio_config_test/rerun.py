
import os
import shutil
import argparse

parser = argparse.ArgumentParser(description="Run cocotb tests")
parser.add_argument("-extend", help="extend the command")
args = parser.parse_args()

os.environ["CARAVEL_ROOT"] = "/home/marwan/webinar_demo/caravel"
os.environ["MCW_ROOT"] = ""

os.chdir("/home/marwan/webinar_demo/verilog/dv/cocotb")

command = "python3 /home/marwan/webinar_demo/venv-cocotb/bin/caravel_cocotb --openframe --CI -test gpio_config_test -tag run_09_Feb_05_25_48_33/RTL-gpio_config_test/rerun   -sim RTL -corner nom-t "
if args.extend is not None:
    command += f" {args.extend}"
os.system(command)

shutil.copyfile("/home/marwan/webinar_demo/verilog/dv/cocotb/sim/run_09_Feb_05_25_48_33/RTL-gpio_config_test/rerun.py", "/home/marwan/webinar_demo/verilog/dv/cocotb/sim/run_09_Feb_05_25_48_33/RTL-gpio_config_test/rerun/RTL-gpio_config_test/rerun.py")
