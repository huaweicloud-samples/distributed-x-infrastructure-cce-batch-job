import os
import sys

mission = os.environ.get("MISSION-MARS", "unknown")
test = os.environ.get("TEST", "unknown")

print("You have landed on the planet Mars!")
print(f"Mission: {mission}")
print(f"Test: {test}")
sys.stdout.flush()
