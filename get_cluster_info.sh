#!/bin/bash

# 设置默认的用户名和密码为空
sddc_user=""
sddc_passwd=""
xms_user=""
xms_passwd=""
sddc_input=false
xms_input=false

# 紫色的ANSI转义序列
purple='\033[35m'
# 重置ANSI转义序列
reset='\033[0m'

# 1. 获取集群版本
get_version(){
    # 执行获取集群版本信息命令，并使用jq解析JSON输出
    output=$(sddc-cli version | jq '.module.sds.version, .version')

    # 提取sds和最后的version
    echo -e "${purple}集群版本信息：${reset}"
    sds_version=$(echo "$output" | sed -n '1p')
    last_version=$(echo "$output" | sed -n '$p')
    echo "SDS版本: $sds_version"
    echo "SDDC版本: $last_version"
}


# 2. 获取集群核心组件leader
get_serviceLeader(){
    # 执行集群组件leader信息命令，并使用awk提取名称和对应的IP，并删除空行
    output=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" cluster-topology list | awk -F "|" '/[[:digit:]]/ {gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if ($3 != "" && $5 != "") {print $3, $5}}' | awk NF)
    # 在输出结果的顶部添加一行标题，然后输出结果
    output="  service      leader\n$output"
    echo -e "${purple}集群组件leader信息：${reset}\n$output"
}


# 3. 查询CPU型号和架构
get_cpu_info(){
    echo -e "${purple}当前主机CPU型号和架构：${reset}"
    lscpu | grep "Model name\|Architecture"
}


# 4. 查询OS信息
get_OS_info(){
    echo -e "${purple}OS信息：${reset}"
    num_processors=$(grep -c processor /proc/cpuinfo)
    kernel_version=$(uname -r)
    echo "逻辑CPU数量：$num_processors"
    echo "内核版本：$kernel_version"
}

# 5. 查询可用内存
get_memory_info(){
    echo -e "${purple}总内存：${reset}"
    total_memory=$(free -h | awk 'NR==2{print $2}')
    echo "total：$total_memory"
    echo -e "${purple}可用内存：${reset}"
    available_memory=$(free -h | awk 'NR==2{print $7}')
    echo "available：$available_memory"
}

# 6. 查看磁盘信息
get_disk_info() {
  echo -e "${purple}磁盘信息：${reset}"
  disk_info=$(xms-cli --user "$xms_user" -p "$xms_passwd" disk list)
  if [[ -z $disk_info ]]; then
    echo "未查询到有效磁盘信息"
  else
    echo "$disk_info"
  fi
}

# 7. 查看存储池信息
get_pool_info() {
  echo -e "${purple}存储池信息：${reset}"
  pool_info=$(xms-cli --user "$xms_user" -p "$xms_passwd" pool list)
  if [[ -z $pool_info ]]; then
    echo "未查询到有效存储池信息"
  else
    echo "$pool_info"
  fi
}

# 8. 获取集群节点相关服务信息
get_node_info(){
    echo -e "${purple}集群节点信息：${reset}"
    # 执行命令并将输出保存到变量中
    output=$(sddc-cli -n $sddc_user -p $sddc_passwd node list)
    # 获取每个节点的ID
    ids=$(echo "$output" | awk -F "|" 'NR>2 {print $2}' | sed 's/ //g')
    # 循环遍历每个节点的ID
    for id in $ids; do
        # 执行命令并将输出保存到变量中
        node_output=$(sddc-cli -n $sddc_user -p $sddc_passwd node show $id)
        # 使用grep查找需要的字段，并限制每个字段只匹配一次
        admin_ip=$(echo "$node_output" | grep -m 1 "admin_ip" | awk -F "|" '{print $3}' | sed 's/ //g')
        iommu_configured=$(echo "$node_output" | grep -m 1 "iommu_configured" | awk -F "|" '{print $3}' | sed 's/ //g')
        iommu_enabled=$(echo "$node_output" | grep -m 1 "iommu_enabled" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_admin_controller=$(echo "$node_output" | grep -m 1 "role_admin_controller" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_admin_metrics=$(echo "$node_output" | grep -m 1 "role_admin_metrics" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_agent=$(echo "$node_output" | grep -m 1 "role_agent" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_compute_vm=$(echo "$node_output" | grep -m 1 "role_compute_vm" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_storage_admin=$(echo "$node_output" | grep -m 1 "role_storage_admin" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_storage_monitor=$(echo "$node_output" | grep -m 1 "role_storage_monitor" | awk -F "|" '{print $3}' | sed 's/ //g')
        role_storage_server=$(echo "$node_output" | grep -m 1 "role_storage_server" | awk -F "|" '{print $3}' | sed 's/ //g')
        storage_fenced=$(echo "$node_output" | grep -m 1 "storage_fenced" | awk -F "|" '{print $3}' | sed 's/ //g')
        storage_fenced_epoch=$(echo "$node_output" | grep -m 1 "^| storage_fenced_epoch\s*|" | grep -w "storage_fenced_epoch" | awk -F "|" '{print $3}' | sed 's/ //g')
        up=$(echo "$node_output" | grep -m 1 "^| up\s*|" | grep -w "up" | awk -F "|" '{print $3}' | sed 's/ //g')
        # 输出结果
        echo "Node ID: $id"
        echo "admin_ip: $admin_ip"
        echo "iommu_configured: $iommu_configured"
        echo "iommu_enabled: $iommu_enabled"
        echo "role_admin_controller: $role_admin_controller"
        echo "role_admin_metrics: $role_admin_metrics"
        echo "role_agent: $role_agent"
        echo "role_compute_vm: $role_compute_vm"
        echo "role_storage_admin: $role_storage_admin"
        echo "role_storage_monitor: $role_storage_monitor"
        echo "role_storage_server: $role_storage_server"
        echo "storage_fenced: $storage_fenced"
        echo "storage_fenced_epoch: $storage_fenced_epoch"
        echo "up: $up"
        echo "------------------------"
    done
}

# 9. 查询NUMA信息
get_NUMA_info(){
    echo -e "${purple}NUMA信息：${reset}"
    if command -v numactl &> /dev/null; then
      numactl -H
    else
      echo "当前系统没有配置NUMA"
    fi
}

# 10. 查询IOMMU配置信息
get_IOMMU_info() {
    # 查看IOMMU是否配置
    args=$(grubby --info=DEFAULT | grep ^args)
    # 查询IOMMU是否生效
    IOMMU_info=$(ls /sys/class/iommu 2>/dev/null)

    echo -e "${purple}IOMMU信息：${reset}"

    if [[ -z "$args" ]]; then
      echo "系统没有配置IOMMU"
    else
      echo "$args"

      # 提取intel_iommu的值
      iommu_status=$(echo "$args" | awk -F 'intel_iommu=' '{print $2}' | awk '{print $1}')

      if [[ "$iommu_status" == "on" ]]; then
        if [[ -n "$IOMMU_info" ]]; then
          echo "系统配置了IOMMU，并且已生效"
          echo "$IOMMU_info"
        else
          echo "系统配置了IOMMU，但未生效"
        fi
      else
        echo "系统没有配置IOMMU"
        echo "$args"
      fi
    fi
}

# 11. 查询GPU信息
get_GPU_info(){
    echo -e "${purple}GPU信息：${reset}"
    gpu_info=$(lspci -D -mm -d 10de::0300)
    if [[ -n "$gpu_info" ]]; then
      echo "$gpu_info"
    else
      echo "没有GPU"
    fi
}

# 15. 查询NVME信息
get_NVME_info(){
    NVME_info=$(lspci -D -mm -d ::0108)
    if [[ -n "$NVME_info" ]]; then
        echo -e "${purple}NVME 信息：${reset}"
        echo "$NVME_info"
    else
        echo "当前系统内无NVME信息"
    fi
}

# 12. 查询集群网络信息
get_net_info(){
    echo -e "${purple}集群网络信息：${reset}"
    # 查询集群网段分配信息
    inventory_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" setting show | grep inventory)
    echo -e "集群网段信息：\n$inventory_info"
    # 查询集群网卡信息
    nic_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" nic list)
    echo -e "集群网卡信息：\n$nic_info"
    # 查询集群桥接网络信息
    br_net_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" br-net list)
    echo -e "集群桥接网络信息：\n$br_net_info"

}

# 13. 查询外部存储池信息
get_extPool_info(){
    # 检查外部存储池集群信息
    echo -e "${purple}外部存储池集群信息：${reset}"
    ext_sds_cluster_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" ext-sds-cluster list)
    if [[ -n "$ext_sds_cluster_info" ]]; then
      echo "$ext_sds_cluster_info"
    else
      echo "没有外部存储池集群信息"
    fi
    # 检查外部存储池pool池信息
    echo "外部存储池pool池信息："
    ext_sds_pool_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" ext-sds-pool list)
    if [[ -n "$ext_sds_pool_info" ]]; then
      echo "$ext_sds_pool_info"
    else
      echo "没有外部存储池pool池信息"
    fi

    # 检查外部存储池配置信息
    echo "外部存储池配置信息："
    ext_sds_conf_info=$(sddc-cli -n "$sddc_user" -p "$sddc_passwd" ext-sds-conf list)
    if [[ -n "$ext_sds_conf_info" ]]; then
      echo "$ext_sds_conf_info"
    else
      echo "没有外部存储池配置信息"
    fi
}

# 14. 查询虚拟机信息
get_VM_info(){
    # 查询虚拟机信息
    echo -e "${purple}集群内部虚拟机信息：${reset}"
    # 获取虚拟机列表
    output=$(sddc-cli -n $sddc_user -p $sddc_passwd vm list)
    # 获取每个虚拟机的ID
    ids=$(echo "$output" | awk -F "|" 'NR>2 {print $2}' | sed 's/ //g')
    # 循环遍历每个虚拟机的ID
    for id in $ids; do
      # 执行命令并将输出保存到变量中
      vm_output=$(sddc-cli -n $sddc_user -p $sddc_passwd vm show $id)
      # 使用grep查找需要的字段，并限制每个字段只匹配一次
      name=$(echo "$vm_output" | grep -m 1 "name" | awk -F "|" '{print $3}' | sed 's/ //g')
      ip_addresses=$(echo "$vm_output" | grep -m 1 "ip_addresses" | awk -F "|" '{print $3}' | sed 's/ //g')
      arch=$(echo "$vm_output" | grep -m 1 "arch" | awk -F "|" '{print $3}' | sed 's/ //g')
      bios=$(echo "$vm_output" | grep -m 1 "bios" | awk -F "|" '{print $3}' | sed 's/ //g')
      os_name=$(echo "$vm_output" | grep -m 1 "os_name" | awk -F "|" '{print $3}' | sed 's/ //g')
      power_state=$(echo "$vm_output" | grep -m 1 "power_state" | awk -F "|" '{print $3}' | sed 's/ //g')
      # 输出结果
      echo "虚拟机 ID: $id"
      echo "name: $name"
      echo "ip_addresses: $ip_addresses"
      echo "arch: $arch"
      echo "bios: $bios"
      echo "os_name: $os_name"
      echo "power_state: $power_state"
    done
}

# 执行查询操作
query_operation() {
    # 根据用户选择执行对应的操作
    case $choice in
        1)
            get_version
            ;;
        2)
            get_serviceLeader
            ;;
        3)
            get_cpu_info
            ;;
        4)
            get_OS_info
            ;;
        5)
            get_memory_info
            ;;
        6)
            get_disk_info
            ;;
        7)
            get_pool_info
            ;;
        8)
            get_node_info
            ;;
        9)
            get_NUMA_info
            ;;
        10)
            get_IOMMU_info
            ;;
        11)
            get_GPU_info
            ;;
        12)
            get_net_info
            ;;
        13)
            get_external_pool_info
            ;;
        14)
            get_vm_info
            ;;
        15)
            get_NVME_info
            ;;
        all)
            # 执行所有操作
            get_version
            get_serviceLeader
            get_cpu_info
            get_OS_info
            get_memory_info
            get_disk_info
            get_pool_info
            get_node_info
            get_NUMA_info
            get_IOMMU_info
            get_GPU_info
            get_net_info
            get_external_pool_info
            get_vm_info
            get_NVME_info
            ;;
    esac
}

# menu 输出操作菜单
print_menu(){
    echo -e "\n"
    echo -e "${purple}请选择操作：${reset}"
    echo -e "${purple}==========================${reset}"
    echo -e "${purple}| 编号  |       操作    ${reset}"
    echo -e "${purple}==========================${reset}"
    echo -e "|  0    |  退出            "
    echo -e "|  1    |  查询集群版本            "
    echo -e "|  2    |  查询组件 leader          "
    echo -e "|  3    |  查询 CPU 架构            "
    echo -e "|  4    |  查询操作系统信息        "
    echo -e "|  5    |  查询内存信息           "
    echo -e "|  6    |  查询磁盘信息             "
    echo -e "|  7    |  查询存储池信息           "
    echo -e "|  8    |  查询集群节点信息        "
    echo -e "|  9    |  查询 NUMA 信息           "
    echo -e "|  10   |  查询 IOMMU 信息          "
    echo -e "|  11   |  查询 GPU 信息            "
    echo -e "|  12   |  查询集群网络信息        "
    echo -e "|  13   |  查询外部存储池信息       "
    echo -e "|  14   |  查询虚拟机信息           "
    echo -e "|  15   |  查询 NVME 信息         "
    echo -e "|  all  |  查询所有                "
    echo -e "${purple}============================"
}

# 循环执行脚本，直到用户选择退出
while true; do
    # 输出操作菜单
    print_menu
    read -p "请输入操作编号: " choice
    echo

    # 根据用户选择执行对应的操作
    case $choice in
        0)
            break
            ;;
        1|3|4|5|9|10|11|13|15)
            # 不需要输入用户名和密码
            query_operation
            ;;
        2|8|12|14)
            # 需要输入sddc用户名和密码
            if [[ $sddc_input == false ]]; then
                read -p "请输入sddc用户名: " sddc_user
                read -s -p "请输入sddc密码: " sddc_passwd
                echo
                sddc_input=true
            fi
            query_operation
            ;;
        6|7)
            # 需要输入xms用户名和密码
            if [[ $xms_input == false ]]; then
                read -p "请输入xms用户名: " xms_user
                read -s -p "请输入xms密码: " xms_passwd
                echo
                xms_input=true
            fi
            query_operation
            ;;
        all)
            # 判断是否已经输入过sddc和xms密码
            if [[ $sddc_input == false || $xms_input == false ]]; then
                read -p "请输入sddc用户名: " sddc_user
                read -s -p "请输入sddc密码: " sddc_passwd
                echo
                read -p "请输入xms用户名: " xms_user
                read -s -p "请输入xms密码: " xms_passwd
                echo
                sddc_input=true
                xms_input=true
            fi
            query_operation
            ;;
        *)
            echo "无效的操作编号，请重新输入"
            ;;
    esac
done
