
import json
import re
import socket
import string
import sys
import urllib.request

baseURI = "http://deverlstokes.appspot.com/serverinfo"
machine = ""


def foo1():
    ipstr = None
    try:
        ipstr = socket.gethostbyname(socket.getfqdn())
    except:
        pass
    return ipstr
    
def foo2():
    ipstr = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("google.com", 80))
        ipstr = s.getsockname()[0]
        s.close()
    except:
        pass
    return ipstr



### def fetch1(url):
###    s = None
###    try:
###        f = urllib.urlopen(url)
###        s = f.read()
###        f.close()
###    except:
###        pass
###    return s



def fetch3(url):
    s = None
    try:
        with urllib.request.urlopen(url) as response:
            b = response.read()
            s = b.decode(encoding='UTF-8')
    except:
        pass
    return s



### sys.argv = [ "getipof.py", "shorttoground" ]


if len(sys.argv) > 1:
    machine = sys.argv[1]

    if machine != "":
        url = "%s%s" % (baseURI, ".json")
        s = fetch3(url)
        if s:
            o = json.loads(s)
            for e in o:
                if "name" in e:
                    if re.search(machine, e["name"], re.I):
                        if "ip" in e and len(e["ip"]) > 0:
                            print(e["ip"])
                            break

else:
    ipstr =  foo1()
    if not ipstr or ipstr == "127.0.0.1" or ipstr == "127.0.1.1":
        ipstr = foo2()
    print(ipstr)
