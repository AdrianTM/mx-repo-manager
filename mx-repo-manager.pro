# **********************************************************************
# * Copyright (C) 2015 MX Authors
# *
# * Authors: Adrian
# *          MX & MEPIS Community <http://forum.mepiscommunity.org>
# *
# * This file is part of mx-repo-manager.
# *
# * mx-repo-manager is free software: you can redistribute it and/or modify
# * it under the terms of the GNU General Public License as published by
# * the Free Software Foundation, either version 3 of the License, or
# * (at your option) any later version.
# *
# * mx-repo-manager is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with mx-repo-manager.  If not, see <http://www.gnu.org/licenses/>.
# **********************************************************************/

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = mx-repo-manager
TEMPLATE = app


SOURCES += main.cpp\
        mxrepomanager.cpp

HEADERS  += mxrepomanager.h

FORMS    += mxrepomanager.ui

TRANSLATIONS += translations/mx-repo-manager_ca.ts \
                translations/mx-repo-manager_de.ts \
                translations/mx-repo-manager_el.ts \
                translations/mx-repo-manager_es.ts \
                translations/mx-repo-manager_fr.ts \
                translations/mx-repo-manager_it.ts \
                translations/mx-repo-manager_ja.ts \
                translations/mx-repo-manager_nl.ts \
                translations/mx-repo-manager_ro.ts \
                translations/mx-repo-manager_sv.ts


