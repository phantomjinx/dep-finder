# Copyright (C) 2021 Paul Richardson
# This file is part of dep-finder <https://github.com/phantomjinx/dep-finder>.
#
# dep-finder is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dep-finder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dep-finder.  If not, see <http://www.gnu.org/licenses/>.

NAME := dep-finder
VERSION := 0.0.1

PREFIX ?= /usr/local
BIN := $(PREFIX)/bin
LIB := $(PREFIX)/share/dep-finder/lib

install:
	@cp dep-finder $(BIN)
	@mkdir -p $(LIB) && cp -rf lib/* $(LIB)/
	@sed -i 's~LIB=.*~LIB=$(LIB)~' $(BIN)/dep-finder

uninstall:
	@rm -f $(BIN)/dep-finder
	@rm -rf $(LIB)
