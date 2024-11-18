#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限运行此脚本"
  exit 1
fi

echo "更新包列表..."
sudo apt update

if ! command -v go &> /dev/null; then
  echo "安装Go语言..."
  wget https://golang.org/dl/go1.23.0.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
  source ~/.profile
else
  GO_VERSION=$(go version | awk '{print $3}')
  if [ "$GO_VERSION" != "go1.23" ]; then
    echo "更新Go语言到1.23版本..."
    sudo rm -rf /usr/local/go
    wget https://golang.org/dl/go1.23.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    source ~/.profile
  else
    echo "Go语言已是1.23版本，跳过更新步骤"
  fi
fi

if ! command -v make &> /dev/null; then
  echo "安装Make..."
  sudo apt install -y make
else
  echo "Make已安装，跳过安装步骤"
fi

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

if ! command -v pm2 &> /dev/null; then
  echo "全局安装pm2..."
  sudo npm install pm2 -g
else
  echo "pm2已安装，跳过安装步骤"
fi

if [ ! -d "masa-oracle" ]; then
  echo "克隆masa-oracle仓库..."
  git clone https://github.com/masa-finance/masa-oracle.git
else
  echo "masa-oracle仓库已存在，跳过克隆步骤"
fi

cd masa-oracle

cd contracts
if [ ! -d "node_modules" ]; then
  echo "安装contracts依赖..."
  npm install
else
  echo "contracts依赖已安装，跳过安装步骤"
fi

cd ..

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

  echo "填写推特用户名密码："
  read -p "Twitter用户名: " twitter_username
  read -sp "Twitter密码: " twitter_password
  echo

  echo "TWITTER_ACCOUNTS=${twitter_username}:${twitter_password}" >> .env

  cat <<EOF >> .env
USER_AGENTS="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36,Mozilla/5.0 (Macintosh; Intel Mac OS X 14.7; rv:131.0) Gecko/20100101 Firefox/131.0"
EOF
else
  echo ".env文件已存在，跳过创建步骤"
fi

echo "编译项目..."
make build

echo "运行项目..."
make run
