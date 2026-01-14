#!/bin/bash

# android-proxy 安装脚本
# 使用方法: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sacowiw/scripts/HEAD/install.sh)"

set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 脚本仓库的原始 URL
REPO_RAW_URL="https://raw.githubusercontent.com/sacowiw/scripts/main"

echo -e "${GREEN}=== android-proxy 安装脚本 ===${NC}"
echo ""

# 1. 创建 ~/.scripts 目录
echo -e "${YELLOW}[1/4] 创建 ~/.scripts 目录...${NC}"
mkdir -p "$HOME/.scripts"
echo -e "${GREEN}✓ 目录创建成功${NC}"

# 2. 下载 android-proxy.sh
echo ""
echo -e "${YELLOW}[2/4] 下载 android-proxy.sh...${NC}"
SCRIPT_URL="${REPO_RAW_URL}/android-proxy.sh"
if curl -fsSL "$SCRIPT_URL" -o "$HOME/.scripts/android-proxy.sh"; then
    chmod +x "$HOME/.scripts/android-proxy.sh"
    echo -e "${GREEN}✓ 下载并设置执行权限成功${NC}"
else
    echo -e "${RED}✗ 下载失败，请检查网络连接${NC}"
    exit 1
fi

# 3. 配置环境变量到 ~/.zshrc
echo ""
echo -e "${YELLOW}[3/5] 配置环境变量...${NC}"
ZSHRC="$HOME/.zshrc"
EXPORT_LINE='export PATH="$HOME/.scripts:$PATH"'

# 检查是否已经配置
if grep -qF 'export PATH="$HOME/.scripts:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo -e "${GREEN}✓ 环境变量已配置，跳过${NC}"
else
    echo "" >> "$ZSHRC"
    echo "# android-proxy" >> "$ZSHRC"
    echo "$EXPORT_LINE" >> "$ZSHRC"
    echo -e "${GREEN}✓ 已添加到 ~/.zshrc${NC}"
fi

# 4. 配置别名
echo ""
echo -e "${YELLOW}[4/5] 配置别名...${NC}"
ALIAS_LINE="alias ap='android-proxy.sh'"

if grep -qF "alias ap='android-proxy.sh'" "$ZSHRC" 2>/dev/null; then
    echo -e "${GREEN}✓ 别名已配置，跳过${NC}"
else
    echo "alias ap='android-proxy.sh'" >> "$ZSHRC"
    echo -e "${GREEN}✓ 已添加 ap 别名${NC}"
fi

# 5. 完成提示
echo ""
echo -e "${GREEN}=== 安装完成！ ===${NC}"
echo ""
echo -e "使用说明："
echo -e "  ${YELLOW}source ~/.zshrc${NC}  # 重新加载配置"
echo -e "  ${YELLOW}ap enable 8888${NC}   # 开启代理（默认端口8888）"
echo -e "  ${YELLOW}ap disable${NC}        # 解除代理"
echo -e "  ${YELLOW}ap check${NC}          # 查看代理配置"
echo ""
echo -e "或者使用完整命令："
echo -e "  ${YELLOW}android-proxy.sh enable 8888${NC}"
echo ""
