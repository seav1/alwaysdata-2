#!/bin/bash
# ===========================================设置相关参数=============================================
# 设置文件下载路径
FLIE_PATH=${FLIE_PATH:-'./'}

#设置argo-token
TOK=${TOK:-'eyJhIjoiMzg2OGEzNjc2ZTkyZmUxMmY0NjM1YTU0ZmNhMDQ0NDMiLCJ0IjoiYjZjNTVhNmEtOTYxNy00MmU2LWJkZDItMTU3YWQ4ZGQ1MWE3IiwicyI6IlpXRXpNbU0wWm1VdE5XVTRNeTAwTTJZMExUZzNNVEV0TkRJeFpqRTVZMk5oTm1ZMiJ9'}

#设置哪吒
NEZHA_SERVER=${NEZHA_SERVER:-'data.seaw.gq'}
NEZHA_KEY=${NEZHA_KEY:-'rqd00afte5iJt0heY7'}

#哪吒其他默认参数，无需更改
NEZHA_PORT=${NEZHA_PORT:-'443'}
NEZHA_TLS=${NEZHA_TLS:-'1'}
TLS=${NEZHA_TLS:+'--tls'}

# ===========================================设置下载链接=============================================

# 设置x86_64-argo下载地址
 URL_CF=${URL_CF:-'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'}

# 设置x86_64-NEZHA下载地址
 URL_NEZHA=${URL_NEZHA:-'https://github.com/seav1/ArgoNodejs/raw/main/nezha-amd'}

# 设置x86_64-bot下载地址
 URL_BOT=${URL_BOT:-'https://seav-xr.hf.space/kano-6'}

# 设置arm-argo下载地址
 URL_CF2=${URL_CF2:-'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64'}

# 设置arm-NEZHA下载地址
 URL_NEZHA2=${URL_NEZHA2:-'https://github.com/seav1/ArgoNodejs/raw/main/nezha-arm'}

# 设置arm-bot下载地址
 URL_BOT2=${URL_BOT2:-'https://seav-xr.hf.space/kano-6-arm'}


# ===========================================下载相关文件=============================================
arch=$(uname -m)
if [[ $arch == "x86_64" ]]; then
# 下载argo
if [[ -n "${TOK}" ]]; then
[ ! -e ${FLIE_PATH}nginx.js ] && curl -sLJo ${FLIE_PATH}nginx.js ${URL_CF}
fi
# 下载nezha
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]]; then
[ ! -e ${FLIE_PATH}nezha.js ] && curl -sLJo ${FLIE_PATH}nezha.js ${URL_NEZHA}
fi
# 下载bot
if [[ -z "${BOT}" ]]; then
[ ! -e ${FLIE_PATH}bot.js ] && curl -sLJo ${FLIE_PATH}bot.js ${URL_BOT}
fi
else
# 下载argo
if [[ -n "${TOK}" ]]; then
[ ! -e ${FLIE_PATH}nginx.js ] && curl -sLJo ${FLIE_PATH}nginx.js ${URL_CF2}
fi
# 下载nezha
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]]; then
[ ! -e ${FLIE_PATH}nezha.js ] && curl -sLJo ${FLIE_PATH}nezha.js ${URL_NEZHA2}
fi
# 下载bot
if [[ -z "${BOT}" ]]; then
[ ! -e ${FLIE_PATH}bot.js ] && curl -sLJo ${FLIE_PATH}bot.js ${URL_BOT2}
fi
fi
# ===========================================运行程序=============================================
# 运行nezha
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" && -s "${FLIE_PATH}nezha.js" ]]; then
chmod +x ${FLIE_PATH}nezha.js
nohup ${FLIE_PATH}nezha.js -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} >/dev/null 2>&1 &
fi

# 运行bot
if [[ -z "${BOT}"  && -s "${FLIE_PATH}bot.js" ]]; then
chmod +x ${FLIE_PATH}bot.js
nohup ${FLIE_PATH}bot.js >/dev/null 2>&1 &
fi

# 运行argo
if [[ -n "${TOK}" && -s "${FLIE_PATH}nginx.js" ]]; then
chmod +x ${FLIE_PATH}nginx.js
TOK=$(echo ${TOK} | sed 's@cloudflared.exe service install ey@ey@g')
nohup ${FLIE_PATH}nginx.js tunnel --edge-ip-version auto run --token ${TOK} >/dev/null 2>&1 &
fi

# 运行serves
if [[ -s "./serves" ]]; then
chmod 777 ./serves
./serves
fi


# ===========================================显示系统信息=============================================
#===系统信息====
echo "----- 系统信息...----- ."
cat /proc/version

# ===========================================显示进程信息=============================================
if command -v ps -ef >/dev/null 2>&1; then
   fps='ps -ef'
elif command -v ss -nltp >/dev/null 2>&1; then
   fps='ss -nltp'
else
   fps='0'
fi
num=$(${fps} |grep -v "grep" |wc -l)
echo "$num"

if [ "$num" -ge  "4" ]; then
echo "----- 系统进程...----- ."
${fps} | sed 's@--token.*@--token ${TOK}@g;s@-s data.*@-s ${NEZHA_SERVER}@g;s@tunnel.*@tunnel@g'
fi
# ===========================================运行进程守护程序=============================================

# 检测bot
function check_bot(){
  count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 == $count ];then
  # count 为空
  echo "----- 检测到bot未运行，重启应用...----- ."
  nohup ${FLIE_PATH}bot.js >/dev/null 2>&1 &
else
  # count 不为空
  echo "bot is running......"
fi
}

# 检测nginx
function check_cf (){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 == $count ];then
  # count 为空
    echo "----- 检测到nginx未运行，重启应用...----- ."
     nohup ${FLIE_PATH}nginx.js tunnel --edge-ip-version auto run --token ${TOK} >/dev/null 2>&1 &
else
  # count 不为空
    echo "nginx is running......"
fi
}
# 检测nezha
function check_nezha(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 == $count ];then
  # count 为空
  echo "----- 检测到nezha未运行，重启应用...----- ."
nohup ${FLIE_PATH}nezha.js -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} >/dev/null 2>&1 &
else
  # count 不为空
  echo "nezha is running......" 
fi
}


# 循环调用检测进程
while true
do
if [ "$num" -ge  "4" ]; then
  [ -s ${FLIE_PATH}bot.js ] && check_bot ${FLIE_PATH}bot.js
  sleep 10
  [ -s ${FLIE_PATH}nginx.js ] && check_cf ${FLIE_PATH}nginx.js
  sleep 10
  [ -s ${FLIE_PATH}nezha.js ] && check_nezha ${FLIE_PATH}nezha.js
  sleep 10
  echo "完成一轮检测，60秒后进入下一轮检测"
  sleep 60
else 
  echo "App is running"
  sleep 666666
fi
done
