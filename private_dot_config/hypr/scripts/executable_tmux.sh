#!/bin/bash

# 检查是否存在任何会话
if ! tmux list-sessions 2>/dev/null; then
	# 不存在则创建一个新的会话
	kitty tmux
else
	# 存在则附加到最近使用的会话
	kitty tmux attach -t $(tmux list-sessions -F "#{session_name}" | sort -n | tail -1)
fi
