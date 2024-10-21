################################################################################
#
# go-bootstrap-stage1
#
################################################################################

# Use last C-based Go compiler: v1.4.x
# See https://golang.org/doc/install/source#bootstrapFromSource
GO_BOOTSTRAP_STAGE1_VERSION = 1.4-bootstrap-20171003
GO_BOOTSTRAP_STAGE1_SITE = https://dl.google.com/go
GO_BOOTSTRAP_STAGE1_SOURCE = go$(GO_BOOTSTRAP_STAGE1_VERSION).tar.gz

GO_BOOTSTRAP_STAGE1_LICENSE = BSD-3-Clause
GO_BOOTSTRAP_STAGE1_LICENSE_FILES = LICENSE

<<<<<<< HEAD
HOST_GO_BOOTSTRAP_STAGE1_ROOT = $(HOST_DIR)/lib/go-$(GO_BOOTSTRAP_STAGE1_VERSION)

# The go build system is not compatible with ccache, so use
# HOSTCC_NOCCACHE. See https://github.com/golang/go/issues/11685.
=======
# The toolchain is needed for HOSTCC_NOCACHE used to compile the Go compiler.
HOST_GO_BOOTSTRAP_STAGE1_DEPENDENCIES = toolchain

HOST_GO_BOOTSTRAP_STAGE1_ROOT = $(HOST_DIR)/lib/go-$(GO_BOOTSTRAP_STAGE1_VERSION)

# The go build system is not compatable with ccache, so use HOSTCC_NOCCACHE.
# See https://github.com/golang/go/issues/11685.
>>>>>>> 56066b2b90 (package/go-bootstrap: split into two stages: go1.4 and go1.19.5)
HOST_GO_BOOTSTRAP_STAGE1_MAKE_ENV = \
	GOOS=linux \
	GOROOT_FINAL="$(HOST_GO_BOOTSTRAP_STAGE1_ROOT)" \
	GOROOT="$(@D)" \
	GOBIN="$(@D)/bin" \
	CC=$(HOSTCC_NOCCACHE) \
	CGO_ENABLED=0

define HOST_GO_BOOTSTRAP_STAGE1_BUILD_CMDS
	cd $(@D)/src && $(HOST_GO_BOOTSTRAP_STAGE1_MAKE_ENV) ./make.bash
endef

define HOST_GO_BOOTSTRAP_STAGE1_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/go $(HOST_GO_BOOTSTRAP_STAGE1_ROOT)/bin/go
	$(INSTALL) -D -m 0755 $(@D)/bin/gofmt $(HOST_GO_BOOTSTRAP_STAGE1_ROOT)/bin/gofmt

	cp -a $(@D)/lib $(HOST_GO_BOOTSTRAP_STAGE1_ROOT)/
	cp -a $(@D)/pkg $(HOST_GO_BOOTSTRAP_STAGE1_ROOT)/

<<<<<<< HEAD
	# The Go sources must be installed to the host/ tree for the Go stdlib.
=======
	# https://golang.org/issue/2775
>>>>>>> 56066b2b90 (package/go-bootstrap: split into two stages: go1.4 and go1.19.5)
	cp -a $(@D)/src $(HOST_GO_BOOTSTRAP_STAGE1_ROOT)/
endef

$(eval $(host-generic-package))
