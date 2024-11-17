#!/bin/bash

# 检查并切换到root用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限运行此脚本"
  exit 1
fi

# 更新包列表
echo "更新包列表..."
sudo apt update

# 检查并安装Go语言
if ! command -v go &> /dev/null; then
  echo "安装Go语言..."
  sudo apt install -y golang-go
else
  echo "Go语言已安装，跳过安装步骤"
fi

# 检查并安装Make
if ! command -v make &> /dev/null; then
  echo "安装Make..."
  sudo apt install -y make
else
  echo "Make已安装，跳过安装步骤"
fi

# 检查并安装Node.js和npm
if ! command -v node &> /dev/null; then
  echo "安装Node.js..."
  sudo apt install -y nodejs
else
  echo "Node.js已安装，跳过安装步骤"
fi

if ! command -v npm &> /dev/null; then
  echo "安装npm..."
  sudo apt install -y npm
else
  echo "npm已安装，跳过安装步骤"
fi

# 检查并全局安装pm2
if ! command -v pm2 &> /dev/null; then
  echo "全局安装pm2..."
  sudo npm install pm2 -g
else
  echo "pm2已安装，跳过安装步骤"
fi

# 克隆masa-oracle仓库
if [ ! -d "masa-oracle" ]; then
  echo "克隆masa-oracle仓库..."
  git clone https://github.com/masa-finance/masa-oracle.git
else
  echo "masa-oracle仓库已存在，跳过克隆步骤"
fi

# 进入masa-oracle目录
cd masa-oracle

# 进入contracts目录并安装依赖
cd contracts
if [ ! -d "node_modules" ]; then
  echo "安装contracts依赖..."
  npm install
else
  echo "contracts依赖已安装，跳过安装步骤"
fi

# 回到项目根目录
cd ..

# 创建.env文件
if [ ! -f ".env" ]; then
  cat <<EOF > .env
BOOTNODES=/ip4/52.6.77.89/udp/4001/quic-v1/p2p/16Uiu2HAmBcNRvvXMxyj45fCMAmTKD4bkXu92Wtv4hpzRiTQNLTsL,/ip4/3.213.117.85/udp/4001/quic-v1/p2p/16Uiu2HAm7KfNcv3QBPRjANctYjcDnUvcog26QeJnhDN9nazHz9Wi,/ip4/52.20.183.116/udp/4001/quic-v1/p2p/16Uiu2HAm9Nkz9kEMnL1YqPTtXZHQZ1E9rhquwSqKNsUViqTojLZt
RPC_URL=https://ethereum-sepolia.publicnode.com
ENV=test
FILE_PATH=.
VALIDATOR=false
PORT=8080
API_ENABLED=true
TWITTER_SCRAPER=true
EOF

  # 提示用户输入Twitter用户名和密码
  echo "填写推特用户名密码："
  read -p "Twitter用户名: " twitter_username
  read -sp "Twitter密码: " twitter_password
  echo

  # 将用户输入的Twitter用户名和密码添加到.env文件
  echo "TWITTER_ACCOUNTS=${twitter_username}:${twitter_password}" >> .env

  # 添加User Agents到.env文件
  cat <<EOF >> .env
USER_AGENTS="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36,Mozilla/5.0 (Macintosh; Intel Mac OS X 14.7; rv:131.0) Gecko/20100101 Firefox/131.0"
EOF
else
  echo ".env文件已存在，跳过创建步骤"
fi

# 编译项目
echo "编译项目..."
make build

# 运行项目
echo "运行项目..."
make run
