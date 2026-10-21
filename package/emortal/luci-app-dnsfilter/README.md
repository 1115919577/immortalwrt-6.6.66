基于 [small_5](https://github.com/small-5) 的 luci-app-adblock-plus 修改

# 基于DNS的广告过滤 for OpenWrt
## 功能

- 支持 AdGuardHome/Host/DNSMASQ/Domain 格式的规则订阅

- 规则自动识别, 自动去重, 定时更新

- 自定义黑白名单

- IP 黑名单通过 firewall4 / nftables 拦截

## 编译说明

本app依赖于```dnsmasq-full```，与OpenWrt默认的```dnsmasq```冲突，所以编译时请确保已经取消勾选```base-system -> dnsmasq```

当前版本已适配 OpenWrt 24.10 的 firewall4 / nftables，IP 黑名单使用独立的 ```table inet dnsfilter```，不再依赖 firewall3、iptables 或 ipset。
