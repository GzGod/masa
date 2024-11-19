#!/bin/bash

# 安装路径
MASA_ORACLE_PATH="$HOME/masa-oracle"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

apt install make sudo curl -y

# 主菜单
function main_menu() {
    clear
    echo "╔═╗╔═╦╗─╔╦═══╦═══╦═══╦═══╗" 
    echo "╚╗╚╝╔╣║─║║╔══╣╔═╗║╔═╗║╔═╗║" 
    echo "─╚╗╔╝║║─║║╚══╣║─╚╣║─║║║─║║"     
    echo "─╔╝╚╗║║─║║╔══╣║╔═╣╚═╝║║─║║"
    echo "╔╝╔╗╚╣╚═╝║╚══╣╚╩═║╔═╗║╚═╝║"
    echo "╚═╝╚═╩═══╩═══╩═══╩╝─╚╩═══╝"
    echo "我的推特：推特雪糕战神@Hy78516012" 
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看日志"
    echo "3. 退出"
    echo "4. 获取节点ID"
    read -p "请输入选项（1-4）: " OPTION
    case $OPTION in
        1) install_masa_oracle ;;
        2) view_logs ;;
        3) echo "退出脚本." ; exit 0 ;;
        4) input_multiaddress ;;
        *) echo "无效选项。" ; exit 1 ;;
    esac
}

# 检查并安装 Go
function install_go() {
    echo "更新软件包列表..."
    sudo apt update

    if command -v go > /dev/null 2>&1; then
        echo "Go 已安装，版本: $(go version)"
        GO_VERSION=$(go version | awk '{print $3}' | cut -d. -f1-2)  # 获取主版本和次版本
        if [ "$(printf '%s\n' "1.23.0" "$GO_VERSION" | sort -V | head -n1)" == "1.23.0" ]; then
            echo "Go 版本符合要求: $GO_VERSION"
        else
            echo "Go 版本不符合要求，正在重新安装..."
            sudo rm -rf /usr/local/go
            curl -L https://go.dev/dl/go1.23.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        fi
    else
        echo "Go 未安装，正在安装..."
        curl -L https://go.dev/dl/go1.23.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    fi

    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    source $HOME/.bash_profile
    go version
}

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装，版本: $(node -v)"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装，版本: $(npm -v)"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装，版本: $(pm2 -v)"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 检查并安装 Git
function install_git() {
    if command -v git > /dev/null 2>&1; then
        echo "Git 已安装，版本: $(git --version)"
    else
        echo "Git 未安装，正在安装..."
        sudo apt install -y git
    fi
}

# 克隆 Masa Oracle 合约
function clone_masa_oracle() {
    echo "克隆 Masa Oracle 合约..."
    git clone -b v0.8.6  https://github.com/masa-finance/masa-oracle.git "$MASA_ORACLE_PATH"
    cd "$MASA_ORACLE_PATH/contracts" || exit
    echo "安装 npm 依赖..."
    npm install
}

# 创建 .env 文件
function create_env_file() {
    echo "创建 .env 文件..."
    
    # 让用户输入推特账号和密码
    read -p "请输入推特账号（格式：username:password）: " TWITTER_ACCOUNTS

    cat <<EOL > "$MASA_ORACLE_PATH/.env"
BOOTNODES=/ip4/52.6.77.89/udp/4001/quic-v1/p2p/16Uiu2HAmBcNRvvXMxyj45fCMAmTKD4bkXu92Wtv4hpzRiTQNLTsL,/ip4/3.213.117.85/udp/4001/quic-v1/p2p/16Uiu2HAm7KfNcv3QBPRjANctYjcDnUvcog26QeJnhDN9nazHz9Wi,/ip4/52.20.183.116/udp/4001/quic-v1/p2p/16Uiu2HAm9Nkz9kEMnL1YqPTtXZHQZ1E9rhquwSqKNsUViqTojLZt
RPC_URL=https://ethereum-sepolia.publicnode.com/
ENV=test
FILE_PATH=.
VALIDATOR=false
PORT=8080
TWITTER_ACCOUNTS=$TWITTER_ACCOUNTS
TWITTER_SCRAPER=true
USER_AGENTS="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36,Mozilla/5.0 (Macintosh; Intel Mac OS X 14.7; rv:131.0) Gecko/20100101 Firefox/131.0"
WEB_SCRAPER=true
API_ENABLED=true
EOL
}

# 打包
function build() {
    echo "编译程序..."
    cd "$MASA_ORACLE_PATH" || exit
    make build
}

# 运行节点并获取钱包地址
function run_node() {
    echo "启动节点..."
    
    # 在后台运行 make run，并将输出重定向到日志文件
    make run > "masa_output.log" 2>&1 & 
    NODE_PID=$!  # 获取后台进程的 PID
    echo "节点已启动，PID: $NODE_PID"
    
    # 循环检查日志文件，直到找到公钥
    while true; do
        # 检查日志文件中是否包含公钥
        PUBLIC_KEY=$(grep "Public Key:" "masa_output.log" | awk '{print $NF}' | tail -n 1)
        
        if [ -n "$PUBLIC_KEY" ]; then
            echo "您的钱包地址是: $PUBLIC_KEY"
            break  # 找到公钥后退出循环
        fi
        
        echo "正在等待公钥生成..."
        sleep 5  # 每 5 秒检查一次
    done

    # 停止节点
    kill $NODE_PID  # 停止后台进程
    echo "节点已停止。"
}

# Faucet 步骤
function faucet() {
    echo "在执行 Faucet 请求之前，请确保您已将 Sepolia ETH 测试币转入钱包地址。"
    read -p "请确认您已转账0.1ETH 并输入 'yes' 继续执行 Faucet 请求: " CONFIRM
    if [ "$CONFIRM" == "yes" ]; then
        echo "请求 Faucet..."
        cd "$MASA_ORACLE_PATH" || exit
        make faucet
    else
        echo "已取消 Faucet 请求。"
    fi
}

# 质押步骤
function stake() {
    echo "进行 Stake..."
    cd "$MASA_ORACLE_PATH" || exit
    make stake
}

# 重新启动节点
function restart_node() {
    echo "重新启动节点..."
    pm2 start make --name masa -- run
}

# 查看日志
function view_logs() {
    echo "查看 PM2 日志..."
    pm2 logs masa
}

# 获取地址
function input_multiaddress() {

MULTIADDRESS=$(grep "Multiaddress:" "/root/masa-oracle/masa_output.log" | awk '{print $NF}' | tail -n 1)
echo "Multiaddress 是: $MULTIADDRESS"

}

# 主安装函数
function install_masa_oracle() {
    install_go
    install_nodejs_and_npm
    install_pm2
    install_git
    clone_masa_oracle
    create_env_file
    build
    run_node
    faucet
    stake
    restart_node
    echo "Masa Oracle 安装和配置完成！"
}

# 显示主菜单
main_menu
