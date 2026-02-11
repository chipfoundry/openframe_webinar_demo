# SPDX-FileCopyrightText: 2023 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

"""
Counter Test

Tests the 32-bit counter in openframe_example:
- Verifies counter is incrementing on clock cycles
- Monitors counter output on GPIOs 2-5 (lower 4 bits) and GPIOs 22-37 (bits 4-19)
"""

from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb
from cocotb.triggers import ClockCycles


@cocotb.test()
@report_test
async def counter_test(dut):
    """Test the 32-bit counter in OpenFrame example.
    
    The counter:
    - Uses GPIO 38 as clock input
    - Uses resetb_l for reset
    - Outputs counter[3:0] on GPIOs 2-5
    - Outputs counter[19:4] on GPIOs 22-37
    """
    env = await test_configure(dut)
    
    cocotb.log.info("[TEST] ========================================")
    cocotb.log.info("[TEST] Counter Test")
    cocotb.log.info("[TEST] ========================================")
    cocotb.log.info(f"[TEST] Active GPIOs: {env.active_gpios_num}")
    
    # Wait for reset to complete
    await ClockCycles(env.clk, 10)
    
    # Read initial counter value (GPIOs 2-5 have counter[3:0])
    initial_low = env.monitor_gpio_range((5, 2))
    cocotb.log.info(f"[TEST] Initial counter[3:0]: {initial_low:04b} ({initial_low})")
    
    # Read higher bits (GPIOs 22-37 have counter[19:4])
    initial_high = env.monitor_gpio_range((37, 22))
    cocotb.log.info(f"[TEST] Initial counter[19:4]: {initial_high:016b} ({initial_high})")
    
    # Combine to get counter[19:0]
    initial_value = (initial_high << 4) | initial_low
    cocotb.log.info(f"[TEST] Initial counter[19:0]: {initial_value}")
    
    # Wait for counter to increment
    num_cycles = 20
    cocotb.log.info(f"[TEST] Waiting {num_cycles} clock cycles...")
    await ClockCycles(env.clk, num_cycles)
    
    # Read counter value after waiting
    final_low = env.monitor_gpio_range((5, 2))
    final_high = env.monitor_gpio_range((37, 22))
    final_value = (final_high << 4) | final_low
    
    cocotb.log.info(f"[TEST] Final counter[3:0]: {final_low:04b} ({final_low})")
    cocotb.log.info(f"[TEST] Final counter[19:4]: {final_high:016b} ({final_high})")
    cocotb.log.info(f"[TEST] Final counter[19:0]: {final_value}")
    
    # Calculate expected value
    expected_value = (initial_value + num_cycles) & 0xFFFFF  # 20-bit mask
    
    # Verify counter incremented correctly
    assert final_value == expected_value, \
        f"Counter mismatch: expected {expected_value}, got {final_value}"
    
    cocotb.log.info(f"[TEST] Counter incremented correctly: {initial_value} + {num_cycles} = {final_value}")
    
    # Additional test: verify counter continues incrementing
    cocotb.log.info("[TEST] ----------------------------------------")
    cocotb.log.info("[TEST] Verifying continuous increment...")
    
    prev_value = final_value
    for i in range(5):
        await ClockCycles(env.clk, 10)
        low = env.monitor_gpio_range((5, 2))
        high = env.monitor_gpio_range((37, 22))
        current_value = (high << 4) | low
        expected = (prev_value + 10) & 0xFFFFF
        
        assert current_value == expected, \
            f"Iteration {i}: expected {expected}, got {current_value}"
        
        cocotb.log.info(f"[TEST] Iteration {i}: {prev_value} + 10 = {current_value}")
        prev_value = current_value
    
    cocotb.log.info("[TEST] ========================================")
    cocotb.log.info("[TEST] Counter test PASSED!")
