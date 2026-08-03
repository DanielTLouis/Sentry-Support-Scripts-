"""
By Daniel 
Loop through to find connected devices on network 
"""

import subprocess as sub 

for i in range(0, 200):
    si = str(i)
    print(sub.run(["ping", str("10.10.9."+si), "-c", "3"]))
