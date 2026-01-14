#!/bin/bash
# lfs
# 定义颜色常量（用于美化输出）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# 1. 获取本机局域网IP（macOS专用）
get_local_ip() {
    # 优先获取en0（无线网卡）的IP，若为空则取en1（有线网卡）
    LOCAL_IP=$(ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}' | head -n1)
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig en1 | grep inet | grep -v inet6 | awk '{print $2}' | head -n1)
    fi
    
    if [ -z "$LOCAL_IP" ]; then
        echo -e "${RED}错误：未找到本机局域网IP，请检查网络连接！${NC}"
        exit 1
    fi
    echo "$LOCAL_IP"
}

# 选择设备（支持多设备）
select_device() {
    local devices=()
    local models=()
    local device_count=0
    
    # 先获取所有设备序列号
    while IFS= read -r serial; do
        [ -z "$serial" ] && continue
        devices+=("$serial")
        ((device_count++))
    done < <(adb devices | grep -v "List" | awk '{if ($2 == "device") print $1}')
    
    # 检查是否有设备
    if [ "$device_count" -eq 0 ]; then
        echo -e "${RED}错误：未找到已连接的Android设备！${NC}" >&2
        exit 1
    fi
    
    # 只有一台设备，直接返回
    if [ "$device_count" -eq 1 ]; then
        echo "${devices[0]}"
        return 0
    fi
    
    # 获取每个设备的型号
    for serial in "${devices[@]}"; do
        local model=$(adb -s "$serial" shell getprop ro.product.model 2>/dev/null </dev/null | tr -d '\r\n')
        [ -z "$model" ] && model="Unknown"
        models+=("$model")
    done
    
    # 多台设备，显示选择列表（输出到stderr）
    echo -e "${YELLOW}检测到 ${device_count} 台设备，请选择：${NC}" >&2
    
    for i in "${!devices[@]}"; do
        local idx=$((i+1))
        echo -e "  ${GREEN}${idx})${NC} ${devices[$i]} (${models[$i]})" >&2
    done
    
    echo "" >&2
    echo -n "请输入设备编号 (1-${device_count}): " >&2
    read choice
    
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$device_count" ]; then
        echo -e "${RED}无效选择！${NC}" >&2
        exit 1
    fi
    
    echo "${devices[$((choice-1))]}"
}

# 2. 开启安卓代理（默认端口8888，可自定义）
enable_proxy() {
    local PORT=${1:-8888}
    local IP=$(get_local_ip)
    local DEVICE=$(select_device)
    
    echo -e "${YELLOW}正在为设备 ${DEVICE} 设置代理：${IP}:${PORT}${NC}"
    
    # 执行ADB命令设置全局代理（与CodeLocator逻辑一致）
    adb -s "$DEVICE" shell settings put global http_proxy "${IP}:${PORT}"
    adb -s "$DEVICE" shell settings put global global_http_proxy_host "${IP}"
    adb -s "$DEVICE" shell settings put global global_http_proxy_port "${PORT}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}代理开启成功！代理地址：${IP}:${PORT}${NC}"
    else
        echo -e "${RED}代理开启失败！请检查ADB连接和设备权限${NC}"
        exit 1
    fi
}

# 3. 解除安卓代理
disable_proxy() {
    local DEVICE=$(select_device)
    
    echo -e "${YELLOW}正在解除设备 ${DEVICE} 的代理...${NC}"
    
    # 清空代理配置（与CodeLocator逻辑一致）
    adb -s "$DEVICE" shell settings put global http_proxy :0
    adb -s "$DEVICE" shell settings delete global http_proxy
    adb -s "$DEVICE" shell settings delete global global_http_proxy_host
    adb -s "$DEVICE" shell settings delete global global_http_proxy_port
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}代理已成功解除！${NC}"
    else
        echo -e "${RED}代理解除失败！请检查ADB连接和设备权限${NC}"
        exit 1
    fi
}

# 4. 查看安卓设备当前代理配置
check_proxy() {
    local DEVICE=$(select_device)
    
    echo -e "${YELLOW}正在查询设备 ${DEVICE} 代理配置...${NC}"
    
    # 读取全局代理配置
    PROXY_CONFIG=$(adb -s "$DEVICE" shell settings list global | grep -E 'http_proxy|global_http_proxy')
    
    if [ -z "$PROXY_CONFIG" ]; then
        echo -e "${GREEN}当前设备未配置任何代理！${NC}"
    else
        echo -e "${GREEN}当前代理配置：${NC}"
        echo "$PROXY_CONFIG" | awk -F'=' '{printf "  %-25s %s\n", $1, $2}'
    fi
}

# 脚本入口：解析命令参数
case "$1" in
    enable)
        enable_proxy "$2"
        ;;
    disable)
        disable_proxy
        ;;
    check)
        check_proxy
        ;;
    *)
        echo -e "${RED}使用说明：${NC}"
        echo "  $0 enable [端口]   - 开启代理（默认端口8888，如Charles默认端口）"
        echo "  $0 disable         - 解除代理"
        echo "  $0 check           - 查看当前代理配置"
        echo -e "${YELLOW}示例：${NC}"
        echo "  $0 enable 8888     # 开启代理，端口8888"
        echo "  $0 disable         # 解除代理"
        echo "  $0 check           # 查看代理配置"
        echo -e "\n${YELLOW}提示：多设备时可选择设备${NC}"
        exit 1
        ;;
esac

exit 0