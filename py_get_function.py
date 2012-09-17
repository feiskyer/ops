#!/usr/bin/python

def get_info():
	import sys
	f=sys._getframe()
	return (f.f_back.f_code.co_name, f.f_back.f_lineno)

if __name__=='__main__':
	print get_info()
