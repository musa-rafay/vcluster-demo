#!/usr/bin/env python3
import yaml, os, re

def bump(ver):
    m = re.match(r'(\d+)\.(\d+)', ver)
    return f"{m.group(1)}.{int(m.group(2))+1}"

file = 'stable-builds.yml'
builds = yaml.safe_load(open(file)) if os.path.exists(file) else {}
for svc in ['alpha', 'bravo']:
    builds[svc] = bump(builds.get(svc, '1.0'))
yaml.safe_dump(builds, open(file, 'w'))
print("stable-builds.yml ->", builds)
