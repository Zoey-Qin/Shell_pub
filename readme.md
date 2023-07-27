# v1
## 1. 执行 download
- 已当天日期命名的文件夹创建包
- 会先判断当前工作空间内有没有以当前日期命名的文件夹，有就不下载当天的包，直接进行清理；没有的话就创建文件夹，然后下载当天的包到这个文件夹
- 下载后解压并
- 进行 sha 256校验：通过就继续后面的 stage，否则直接以失败退出

## 2. 执行 clean
- 采用 expect 进行交互，模拟输入两次 "y"，表示确认清理
- 创建文件保存清理过程的输出，路径在 `/xhere/logs/cleanup_output_$today.txt`，today 即为当日日期

## 3. 执行 configuration
- 判断 `/opt/` 下有没有 sddc、sds 文件，有的话说明清理其实并没有成功，也会强制失败；没有则继续
- 将提前准备好的 `bootstrap.conf.yaml` 文件替换掉下载的包里的同名文件

## 4. 执行 install
- 执行部署脚本 `./bootstrap.sh`
