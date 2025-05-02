################################################################################
#
# aardvark-dns
#
################################################################################

# When updating the version here, also update netavark in lockstep
AARDVARK_DNS_VERSION = v1.14.0
AARDVARK_DNS_SITE = $(call github,containers,aardvark-dns,$(AARDVARK_DNS_VERSION))

AARDVARK_DNS_LICENSE = Apache-2.0
AARDVARK_DNS_LICENSE_FILES = LICENSE

$(eval $(cargo-package))
