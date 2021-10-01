#!/usr/bin/python3
import re
import subprocess
import os
import time
import sys

if __name__ == "__main__":
    hostname = os.environ['HOSTNAME']
    results = []
    results = subprocess.check_output(['ss','-ltupH']).decode('utf-8').split('\n')
    for result in results:
        #print(result)
        res = re.search(r"^(?P<Protocol>\w+)\s{1,}(?P<State>\w+)\s{1,}(?P<RecvQ>.+?)\s{1,}(?P<SendQ>.+?)\s{1,}(?P<LocalIP>.+?)\s{1,}(?P<DestIP>.+?)\s{1,}(?P<Process>.+)",result)
        if res:
            #print("%s,%s"%(res.group('Protocol'),res.group('State')))
            print(f"{hostname},{res.group('Protocol')},{res.group('LocalIP')},{res.group('DestIP')},{res.group('State')},,{res.group('Process').replace(',','|')}")