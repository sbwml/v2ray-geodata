# Loyalsoldier

OpenWrt 打包层，产出 `v2ray-geoip` 与 `v2ray-geosite` 两个包。在编译期从 [NetForgeCN/v2ray-rules-dat](https://github.com/NetForgeCN/v2ray-rules-dat) 的 latest release 下载 `geoip.dat` / `geosite.dat`，用配套的 `.sha256sum` 校验后安装到 `/usr/share/v2ray/`。仓库本身只有一份 `Makefile`，不存放规则数据。

上游基础：[sbwml/v2ray-geodata](https://github.com/sbwml/v2ray-geodata)。

## 产出包

| 包 | 内容 | 许可声明 |
|---|---|---|
| `v2ray-geoip` | `/usr/share/v2ray/geoip.dat` | CC-BY-SA-4.0 |
| `v2ray-geosite` | `/usr/share/v2ray/geosite.dat` | GPL-3.0 |

两个包都标记为 `PKGARCH:=all`，菜单位置 `Network → IP Addresses and Names`。

## 使用

挂成 feed 或直接克隆为一个包目录：

```bash
# 作为 feed
echo "src-git geodata https://github.com/NetForgeCN/Loyalsoldier.git;master" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig   # Network -> IP Addresses and Names -> v2ray-geoip / v2ray-geosite

# 或直接放进 package/
git clone https://github.com/NetForgeCN/Loyalsoldier.git package/v2ray-geodata
```

若构建树里已有官方 `openwrt/packages/net/v2ray-geodata`，先删除该源目录与 `package/feeds/*/v2ray-geodata` 链接，避免同名包冲突。NetForgeCN 的三个固件构建仓库都内置了这一步。

`Build/Compile` 会下载两个 `.dat` 并逐一比对 release 提供的 `.sha256sum`，校验不一致直接失败。更换数据源只需改 `Makefile` 里的 `GEOIP_URL` / `GEOSITE_URL`。

## 规则数据

`geoip.dat` / `geosite.dat` 由 [NetForgeCN/v2ray-rules-dat](https://github.com/NetForgeCN/v2ray-rules-dat) 生成：Loyalsoldier 全量规则集，另加反广告 / Cats-Team AdRules / neodevhost 列表。数据内容以那个仓库的 release 为准。

## 许可

GPL-3.0，见 [LICENSE](LICENSE)。规则数据按 [v2ray-rules-dat](https://github.com/NetForgeCN/v2ray-rules-dat) 的各上游来源许可分发。
