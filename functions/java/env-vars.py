import json

config = sys.stdin.read()
j = json.loads(config)

all = ""
for var in j["EnvVars"]:
    all += var + " "

print(all)