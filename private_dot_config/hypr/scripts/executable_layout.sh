#!/usr/bin/env bash

# 定义文本和配置文件
files=(
	"$HOME/.config/hypr/custom/monitors/multi.conf"
	"$HOME/.config/hypr/custom/monitors/single_external.conf"
	"$HOME/.config/hypr/custom/monitors/single_internal.conf"
	"$HOME/.config/hypr/custom/monitors/mirror.conf"
)
texts=(
	"扩展布局"
	"外接显示屏"
	"内置屏幕"
	"镜像布局"
)

# 初始化变量
selected_file="${files[0]}"
selected_text="${texts[0]}"
current_line=1
exit_loop=false

# 根据当前链接文件确定初始 current_line 值
for i in "${!files[@]}"; do
	if [ -f "${files[$i]}" ] && [ "$(readlink -f "${files[$i]}")" = "$(readlink -f "$HOME/.config/hypr/custom/monitors.conf")" ]; then
		current_line=$((i + 1))
		selected_file="${files[$i]}"
		selected_text="${texts[$i]}"
		break
	fi
done

# 如果没有匹配的链接文件，则默认选择第一个文件
if [ $current_line -eq 0 ]; then
	selected_file="${files[0]}"
	selected_text="${texts[0]}"
	current_line=1
fi

# 函数：显示菜单
function show_menu() {
	clear
	echo "请选择显示器布局："
	for i in "${!texts[@]}"; do
		if [ $((i + 1)) -eq $current_line ]; then
			echo -e "  > ${texts[$i]}"
		else
			echo -e "    ${texts[$i]}"
		fi
	done
}

# 函数：选择选项
function select_option() {
	local choice=$1
	case $choice in
	j | ''$'\e'[B)
		if [ $current_line -lt ${#texts[@]} ]; then
			((current_line++))
		fi
		;;
	k | ''$'\e'[A)
		if [ $current_line -gt 1 ]; then
			((current_line--))
		fi
		;;
	"")
		selected_file="${files[$((current_line - 1))]}"
		selected_text="${texts[$((current_line - 1))]}"
		exit_loop=true
		;;
	esac
}

# 函数：读取用户输入
function read_input() {
	read -s -n 1 key
	if [[ $key == "" ]]; then
		# 回车键
		select_option $key
		if [ "$selected_text" == "镜像布局" ]; then
			bash "$HOME/.config/hypr/scripts/swwwreload.sh"
		fi
		hyprctl reload
		clear
		# 显示结果
		if [ $? -eq 0 ]; then
			echo "布局已切换为：$selected_text"
		else
			echo "布局切换失败！"
		fi
	elif [[ $key == $'\e' ]]; then
		# 箭头键序列开始
		read -s -n 2 key
		select_option $key
	else
		select_option $key
	fi
}

# 主循环
while ! $exit_loop; do
	show_menu
	read_input
done

# 链接配置文件
ln -sf "$selected_file" "$HOME/.config/hypr/custom/monitors.conf"

hyprctl reload

killall ags ydotool
nohup ags >/dev/null 2>&1 &
sleep 1
