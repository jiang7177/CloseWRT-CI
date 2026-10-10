#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
#添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" {} +

WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
if [ -f "$WIFI_FILE" ]; then
	#修改WIFI名称
	sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
	#修改WIFI加密
	sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
	#修改WIFI密码
	sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#强制切换firewall3：defconfig后清理被依赖拉回的firewall4及fw4专属组件
make defconfig -j$(nproc)
sed -i 's/^CONFIG_PACKAGE_firewall4=.*/# CONFIG_PACKAGE_firewall4 is not set/' .config
sed -i 's/^CONFIG_PACKAGE_kmod-nft-tproxy=.*/# CONFIG_PACKAGE_kmod-nft-tproxy is not set/' .config
sed -i 's/^CONFIG_PACKAGE_dnsmasq_full_nftset=.*/# CONFIG_PACKAGE_dnsmasq_full_nftset is not set/' .config
echo "CONFIG_PACKAGE_dnsmasq_full_ipset=y" >> .config
make defconfig -j$(nproc)
