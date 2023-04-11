#!/usr/bin/env python3

import json

records = {}

with open('/dev/stdin', 'r') as file:
    try:
        while True:
            inp = json.loads(file.readline())

            msg_type = inp['Type']   # type: string
            serialno = None          # type: int

            match(inp['Type']):
                case 'NetIDM' | 'IDM':
                    serialno = inp['Message']['ERTSerialNumber']
                case 'SCM':
                    serialno = inp['Message']['ID']
                case other:
                    serialno = inp['Message']['EndpointID']
                
            try:
                records[serialno].append(inp)
            except KeyError:
                records[serialno] = [inp]
    except json.JSONDecodeError:
        pass


print(sorted(records.keys()))

