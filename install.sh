#!/usr/bin/expect -f

# 获取并转到当前日期文件夹
set date [exec date +%m-%d]
cd "${date}"

# 进行安装
spawn ./bootstrap.sh

# 检测是否出现等待服务创建的提示
while true {
  expect {
    "Waiting services to be created" {
      puts "waiting server"
      sleep 10
      send "\x03" ;# 发送 ctrl+c
      sleep 5
      send "c\r"
    }
    "Output login info" {
      puts "deploy successful"
    }
    eof {
      break
    }
  }
}
