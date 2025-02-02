#!/bin/bash

# 输出颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # 无颜色

# 版权声明
show_banner() {
    echo -e "${PURPLE}"
    echo "=============================================="
    echo "        服务器性能测试脚本 v1.0"
    echo "=============================================="
    echo "作者: 大米"
    echo "项目地址: http://dmbbs.3mqkbf.top"
    echo "CDN推荐: 失控防御系统 https://www.scdn.io"
    echo "=============================================="
    echo -e "${NC}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装依赖包
install_packages() {
    echo -e "${YELLOW}正在安装所需软件包...${NC}"
    if command_exists apt-get; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y speedtest-cli curl wget sysbench fio
    elif command_exists yum; then
        sudo yum install -q -y epel-release
        sudo yum install -q -y speedtest-cli curl wget sysbench fio
    else
        echo -e "${RED}无法检测到包管理器。请手动安装 speedtest-cli、curl、wget、sysbench 和 fio。${NC}"
        exit 1
    fi
}

# 检查并安装必需软件包
check_and_install_requirements() {
    local missing_packages=()
    
    for cmd in speedtest-cli curl wget sysbench fio; do
        if ! command_exists "$cmd"; then
            missing_packages+=("$cmd")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo -e "${YELLOW}以下必需软件包缺失: ${missing_packages[*]}${NC}"
        echo -e "${YELLOW}正在自动安装缺失的软件包...${NC}"
        install_packages
    fi
}

# CPU 性能测试
test_cpu() {
    echo -e "\n${GREEN}正在进行 CPU 性能测试...${NC}"
    echo "----------------------------------------"
    
    # 获取CPU信息
    cpu_info=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ":" -f 2)
    cpu_cores=$(nproc)
    echo "CPU型号:$cpu_info"
    echo "CPU核心数: $cpu_cores"
    
    # 单线程测试
    echo -e "\n1. 单线程测试中..."
    single_thread=$(sysbench cpu --cpu-max-prime=20000 --threads=1 run | grep "events per second" | awk '{print $4}')
    echo "单线程性能: $single_thread 事件/秒"
    
    # 多线程测试
    echo -e "\n2. 多线程测试中..."
    multi_thread=$(sysbench cpu --cpu-max-prime=20000 --threads=$cpu_cores run | grep "events per second" | awk '{print $4}')
    echo "多线程性能: $multi_thread 事件/秒"
    
    # CPU压力测试 (30秒)
    echo -e "\n3. CPU压力测试 (30秒)..."
    stress_test=$(sysbench cpu --cpu-max-prime=20000 --threads=$cpu_cores --time=30 run | grep "events per second" | awk '{print $4}')
    echo "压力测试性能: $stress_test 事件/秒"
    
    # 计算CPU得分
    single_score=$(echo "scale=2; $single_thread / 2000 * 40" | bc)
    multi_score=$(echo "scale=2; $multi_thread / 5000 * 60" | bc)
    cpu_score=$(echo "scale=2; $single_score + $multi_score" | bc)
    
    if (( $(echo "$cpu_score > 100" | bc -l) )); then
        cpu_score=100
    fi
    
    echo -e "\n${BLUE}CPU性能得分详情:${NC}"
    echo "单线程得分 (40%权重): $single_score"
    echo "多线程得分 (60%权重): $multi_score"
    echo -e "${BLUE}最终CPU得分: $cpu_score${NC}"
    
    # CPU性能评级
    if (( $(echo "$cpu_score >= 90" | bc -l) )); then
        echo -e "CPU性能评级: ${GREEN}极致性能${NC}"
    elif (( $(echo "$cpu_score >= 80" | bc -l) )); then
        echo -e "CPU性能评级: ${BLUE}优秀${NC}"
    elif (( $(echo "$cpu_score >= 60" | bc -l) )); then
        echo -e "CPU性能评级: ${YELLOW}良好${NC}"
    else
        echo -e "CPU性能评级: ${RED}性能不足${NC}"
    fi
    echo "----------------------------------------"
}

# 内存性能测试
test_memory() {
    echo -e "\n${GREEN}正在进行内存性能测试...${NC}"
    echo "----------------------------------------"
    
    # 获取内存信息
    total_mem=$(free -m | grep "Mem:" | awk '{print $2}')
    echo "总内存大小: $total_mem MB"
    
    # 内存读写测试
    echo -e "\n1. 内存读写速度测试:"
    memory_rw=$(sysbench memory --memory-block-size=1K --memory-total-size=10G --memory-oper=write run)
    
    # 提取关键指标
    memory_speed=$(echo "$memory_rw" | grep "transferred" | awk '{print $4}')
    memory_latency=$(echo "$memory_rw" | grep "avg:" | awk '{print $2}')
    memory_ops=$(echo "$memory_rw" | grep "total operations:" | awk '{print $3}')
    
    # 显示详细结果
    echo "内存读写速度: $memory_speed MiB/秒"
    echo "内存访问延迟: $memory_latency 纳秒"
    echo "总操作次数: $memory_ops"
    
    # 计算内存得分
    speed_score=$(echo "scale=2; $memory_speed / 5000 * 60" | bc)
    latency_score=$(echo "scale=2; (1000 / $memory_latency) * 40" | bc)
    memory_score=$(echo "scale=2; $speed_score + $latency_score" | bc)
    
    if (( $(echo "$memory_score > 100" | bc -l) )); then
        memory_score=100
    fi
    
    # 显示得分明细
    echo -e "\n${BLUE}内存性能得分详情:${NC}"
    echo "读写速度得分 (60%权重): $speed_score"
    echo "访问延迟得分 (40%权重): $latency_score"
    echo -e "${BLUE}最终内存得分: $memory_score${NC}"
    
    # 内存性能评级
    if (( $(echo "$memory_score >= 90" | bc -l) )); then
        echo -e "内存性能评级: ${GREEN}极致性能${NC}"
    elif (( $(echo "$memory_score >= 80" | bc -l) )); then
        echo -e "内存性能评级: ${BLUE}优秀${NC}"
    elif (( $(echo "$memory_score >= 60" | bc -l) )); then
        echo -e "内存性能评级: ${YELLOW}良好${NC}"
    else
        echo -e "内存性能评级: ${RED}性能不足${NC}"
    fi
    echo "----------------------------------------"
}

# 磁盘 I/O 性能测试
test_disk_io() {
    echo -e "\n${GREEN}正在进行磁盘 I/O 性能测试...${NC}"
    echo "----------------------------------------"
    
    # 获取磁盘信息
    disk_info=$(df -h / | tail -n 1)
    disk_total=$(echo $disk_info | awk '{print $2}')
    disk_used=$(echo $disk_info | awk '{print $3}')
    disk_free=$(echo $disk_info | awk '{print $4}')
    echo "磁盘总容量: $disk_total"
    echo "已用空间: $disk_used"
    echo "可用空间: $disk_free"
    
    # 测试结果变量
    local seq_read_bw=0
    local seq_write_bw=0
    local rand_read_iops=0
    local rand_write_iops=0
    
    echo -e "\n1. 顺序读取测试:"
    seq_read_result=$(fio --name=seq_read --ioengine=libaio --rw=read --bs=1M --size=1G --numjobs=4 --runtime=30 --group_reporting)
    seq_read_bw=$(echo "$seq_read_result" | grep "bw=" | awk -F'[()]' '{print $2}' | grep -o '[0-9.]\+')
    echo "顺序读取速度: $seq_read_bw MB/s"
    
    echo -e "\n2. 顺序写入测试:"
    seq_write_result=$(fio --name=seq_write --ioengine=libaio --rw=write --bs=1M --size=1G --numjobs=4 --runtime=30 --group_reporting)
    seq_write_bw=$(echo "$seq_write_result" | grep "bw=" | awk -F'[()]' '{print $2}' | grep -o '[0-9.]\+')
    echo "顺序写入速度: $seq_write_bw MB/s"
    
    echo -e "\n3. 随机读取测试:"
    rand_read_result=$(fio --name=rand_read --ioengine=libaio --rw=randread --bs=4K --size=1G --numjobs=4 --runtime=30 --group_reporting)
    rand_read_iops=$(echo "$rand_read_result" | grep "IOPS=" | awk -F'=' '{print $2}' | awk '{print $1}')
    echo "随机读取IOPS: $rand_read_iops"
    
    echo -e "\n4. 随机写入测试:"
    rand_write_result=$(fio --name=rand_write --ioengine=libaio --rw=randwrite --bs=4K --size=1G --numjobs=4 --runtime=30 --group_reporting)
    rand_write_iops=$(echo "$rand_write_result" | grep "IOPS=" | awk -F'=' '{print $2}' | awk '{print $1}')
    echo "随机写入IOPS: $rand_write_iops"
    
    # 计算磁盘性能得分
    seq_score=$(echo "scale=2; ($seq_read_bw + $seq_write_bw) / 1000 * 40" | bc)
    iops_score=$(echo "scale=2; ($rand_read_iops + $rand_write_iops) / 10000 * 60" | bc)
    disk_score=$(echo "scale=2; $seq_score + $iops_score" | bc)
    
    if (( $(echo "$disk_score > 100" | bc -l) )); then
        disk_score=100
    fi
    
    echo -e "\n${BLUE}磁盘性能得分详情:${NC}"
    echo "顺序读写得分 (40%权重): $seq_score"
    echo "随机读写得分 (60%权重): $iops_score"
    echo -e "${BLUE}最终磁盘得分: $disk_score${NC}"
    
    # 磁盘性能评级
    if (( $(echo "$disk_score >= 90" | bc -l) )); then
        echo -e "磁盘性能评级: ${GREEN}极致性能${NC}"
    elif (( $(echo "$disk_score >= 80" | bc -l) )); then
        echo -e "磁盘性能评级: ${BLUE}优秀${NC}"
    elif (( $(echo "$disk_score >= 60" | bc -l) )); then
        echo -e "磁盘性能评级: ${YELLOW}良好${NC}"
    else
        echo -e "磁盘性能评级: ${RED}性能不足${NC}"
    fi
    echo "----------------------------------------"
}

# 网络性能测试
test_network() {
    echo -e "\n${GREEN}正在进行网络性能测试...${NC}"
    echo "----------------------------------------"
    
    # 获取网络接口信息
    network_info=$(ip -4 addr show | grep inet | grep -v "127.0.0.1" | awk '{print $2}')
    echo "网络地址: $network_info"
    
    # 进行速度测试
    echo -e "\n1. 网络速度测试:"
    network_result=$(speedtest-cli --simple)
    ping=$(echo "$network_result" | grep "Ping:" | awk '{print $2}')
    download=$(echo "$network_result" | grep "Download:" | awk '{print $2}')
    upload=$(echo "$network_result" | grep "Upload:" | awk '{print $2}')
    
    echo "延迟: $ping ms"
    echo "下载速度: $download Mbit/s"
    echo "上传速度: $upload Mbit/s"
    
    # 计算网络得分
    ping_score=$(echo "scale=2; (100 - $ping) / 100 * 30" | bc)
    download_score=$(echo "scale=2; $download / 100 * 40" | bc)
    upload_score=$(echo "scale=2; $upload / 50 * 30" | bc)
    network_score=$(echo "scale=2; $ping_score + $download_score + $upload_score" | bc)
    
    if (( $(echo "$network_score > 100" | bc -l) )); then
        network_score=100
    fi
    
    echo -e "\n${BLUE}网络性能得分详情:${NC}"
    echo "延迟得分 (30%权重): $ping_score"
    echo "下载速度得分 (40%权重): $download_score"
    echo "上传速度得分 (30%权重): $upload_score"
    echo -e "${BLUE}最终网络得分: $network_score${NC}"
    
    # 网络性能评级
    if (( $(echo "$network_score >= 90" | bc -l) )); then
        echo -e "网络性能评级: ${GREEN}极致性能${NC}"
    elif (( $(echo "$network_score >= 80" | bc -l) )); then
        echo -e "网络性能评级: ${BLUE}优秀${NC}"
    elif (( $(echo "$network_score >= 60" | bc -l) )); then
        echo -e "网络性能评级: ${YELLOW}良好${NC}"
    else
        echo -e "网络性能评级: ${RED}性能不足${NC}"
    fi
    echo "----------------------------------------"
}

# 计算总得分和评价
calculate_total_score() {
    total_score=$(echo "scale=2; ($cpu_score + $memory_score + $disk_score + $network_score) / 4" | bc)
    echo -e "\n${GREEN}============== 总体评分 ==============${NC}"
    echo -e "CPU 得分: $cpu_score"
    echo -e "内存得分: $memory_score"
    echo -e "磁盘得分: $disk_score"
    echo -e "网络得分: $network_score"
    echo -e "${GREEN}最终总得分: $total_score${NC}"
    
    if (( $(echo "$total_score >= 80" | bc -l) )); then
        echo -e "${GREEN}服务器质量评价: 优秀${NC}"
        echo "此服务器不是超开超售卖产品，给你买到优秀的了，牢弟"
    elif (( $(echo "$total_score >= 60" | bc -l) )); then
        echo -e "${YELLOW}服务器质量评价: 良好${NC}"
        echo "此服务器性能正常良好，放心食用坤坤"
    else
        echo -e "${RED}服务器质量评价: 垃圾${NC}"
        echo "此服务器性能非常差，存在超售超卖可能性，你可能买亏了"
    fi
    echo "========================================"
}

# 主程序
clear
show_banner
echo -e "${GREEN}=== 服务器性能测试 ===${NC}"
echo -e "${YELLOW}测试开始时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${YELLOW}服务器信息: $(uname -a)${NC}"

# 检查并安装依赖
check_and_install_requirements

# 运行测试
test_cpu
test_memory
test_disk_io
test_network

# 计算总得分和评价
calculate_total_score

echo -e "\n${GREEN}测试完成!${NC}"
echo -e "${YELLOW}测试结束时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
