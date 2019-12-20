#!/usr/bin/env python3

import libtmux

# server = libtmux.Server()
# session = server.get_by_id('$0')

# window = session.attached_window
# pane = window.split_window(attach=False)

# window = session.new_window(attach=False, window_name="test")
# pane = window.split_window(attach=False)

# pane.send_keys('echo hey', enter=False)

# print('\n'.join(pane.cmd('capture-pane', '-p').stdout))

# pane.select_pane()
# pane.enter()

def tmuxCreate():
	server = libtmux.Server()
	session = server.get_by_id('$0')

	names = ['htb','tools','burp']
	n = 2
	for x in names:
		window = session.new_window(attach=False, window_name=x)
		n = n + 1
		print(n)
		if n == 3:


		# session.kill_window(n)


	return




tmuxCreate()




# why python instead of bash?

# Python can use arguments like `--test1 -t1`... or pos `test1 test2`
# Bash can only do pos args

# I most likely don't need to use recursion to make python work with tmux

# Downfalls to python:
# I'm pretty much running all bash commands UNLESS I use nmap / ping / etc 
# libs




