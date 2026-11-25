#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-geodata
PKG_VERSION:=$(shell date "+%Y.%m.%d")
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/v2ray-geodata/default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  URL:=https://www.v2fly.org
  PKGARCH:=all
endef

define Package/v2ray-geoip
  $(call Package/v2ray-geodata/default)
  TITLE:=GeoIP List for V2Ray
  LICENSE:=CC-BY-SA-4.0
endef

define Package/v2ray-geosite
  $(call Package/v2ray-geodata/default)
  TITLE:=Geosite List for V2Ray
  LICENSE:=GPL-3.0
endef

GEOIP_URL:=https://github.com/NetForgeCN/v2ray-rules-dat/releases/latest/download/geoip.dat
GEOSITE_URL:=https://github.com/NetForgeCN/v2ray-rules-dat/releases/latest/download/geosite.dat

# HTTPS only (including redirects), fail on HTTP/TLS errors, bounded time and
# size, with retries. Each URL is downloaded exactly once per build.
CURL_FLAGS:=--fail --silent --show-error --proto '=https' --proto-redir '=https' --location --max-redirs 5 --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 --max-filesize 67108864

define Build/Compile
	( \
		set -eu; \
		cd "$(PKG_BUILD_DIR)"; \
		sha256_of() { \
			if command -v sha256sum >/dev/null 2>&1; then \
				sha256sum "$$1" | awk '{print $$1}'; \
			elif command -v shasum >/dev/null 2>&1; then \
				shasum -a 256 "$$1" | awk '{print $$1}'; \
			else \
				openssl dgst -sha256 "$$1" | awk '{print $$NF}'; \
			fi; \
		}; \
		fetch() { \
			url="$$1"; dest="$$2"; tmp="$${dest}.part"; \
			trap 'rm -f "$$tmp"' EXIT HUP INT TERM; \
			curl $(CURL_FLAGS) "$$url" -o "$$tmp"; \
			size=$$(wc -c < "$$tmp" | tr -d '[:space:]'); \
			[ "$$size" -ge 16 ] || { echo "empty download: $$url" >&2; return 1; }; \
			[ "$$size" -le 67108864 ] || { echo "oversized download: $$url" >&2; return 1; }; \
			if head -c 512 "$$tmp" | grep -Eqi '<(!doctype|html|head|body)|<error|access denied|too many requests'; then \
				echo "download looks like an HTML/error page: $$url" >&2; return 1; \
			fi; \
			mv -f "$$tmp" "$$dest"; \
		}; \
		verify() { \
			dest="$$1"; sumfile="$$2"; name="$$3"; \
			expected=$$(awk -v want="$$name" ' \
				NF == 1 { print $$1; n++; next } \
				NF == 2 { if ($$2 != want && $$2 != "./" want) exit 1; print $$1; n++; next } \
				{ exit 1 } \
				END { if (n != 1) exit 1 } \
			' "$$sumfile") || { echo "malformed checksum file for $$name" >&2; return 1; }; \
			case "$$expected" in \
				''|*[!0-9a-fA-F]*) echo "malformed checksum for $$name" >&2; return 1 ;; \
			esac; \
			[ "$${#expected}" -eq 64 ] || { echo "malformed checksum for $$name" >&2; return 1; }; \
			actual=$$(sha256_of "$$dest"); \
			[ "$$actual" = "$$expected" ] || { echo "SHA-256 mismatch for $$name" >&2; return 1; }; \
			echo "verified $$name ($$actual)"; \
		}; \
		fetch "$(GEOIP_URL)" geoip.dat; \
		fetch "$(GEOIP_URL).sha256sum" geoip.dat.sha256sum; \
		verify geoip.dat geoip.dat.sha256sum geoip.dat; \
		fetch "$(GEOSITE_URL)" geosite.dat; \
		fetch "$(GEOSITE_URL).sha256sum" geosite.dat.sha256sum; \
		verify geosite.dat geosite.dat.sha256sum geosite.dat; \
	)
endef

define Package/v2ray-geoip/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geoip.dat $(1)/usr/share/v2ray/geoip.dat
endef

define Package/v2ray-geosite/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geosite.dat $(1)/usr/share/v2ray/geosite.dat
endef

$(eval $(call BuildPackage,v2ray-geoip))
$(eval $(call BuildPackage,v2ray-geosite))
