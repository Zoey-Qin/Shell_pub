#!/usr/bin/expect

# 获取当前日期
set today [clock format [clock seconds] -format "%Y-%m-%d"]

# 构建日志文件路径
set log_file_path "/xhere/logs/cleanup_output_$today.txt"

# 将输出重定向到日志文件
log_file $log_file_path

# 启用调试模式
exp_internal 1

# 执行cluster-cleanup.sh
spawn sh /opt/sddc/installer/ansible_workspace/bins/cluster-cleanup.sh -y

# 等待第一次输入
expect "DO YOU WANT TO CONTINUE WITH THE OPERATION? (y/n)"

# 发送y并等待第二次输入
send "y\r"
expect "ARE YOU ABSOLUTELY SURE YOU WANT TO CONTINUE? (y/n)"

# 发送y并等待执行完成
send "y\r"
expect eof

# 等待子进程结束
wait

# 输出提示信息
puts "clean over"