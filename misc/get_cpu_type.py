#!/usr/bin/python
from xen.xm.XenAPI import Session

session=Session('http://localhost:9363/')
try:
	session.login_with_password('', '')
	xenapi=session.xenapi
	host=xenapi.host.get_all()[0]
	hostcpu=xenapi.host_cpu.get_all()[0]
	print "CPU_NUM	CPU_MODEL"
	print xenapi.host_cpu.get_number(hostcpu),xenapi.host_cpu.get_modelname(hostcpu)
	
finally:
	session.xenapi.session.logout()
