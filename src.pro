# **********************************************************************
# * Copyright (C) 2016 MX Authors
# *
# * Authors: Adrian
# *          MX Linux <http://mxlinux.org>
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

CONFIG   += c++11

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = mx-repo-manager
TEMPLATE = app


SOURCES += main.cpp\
    mainwindow.cpp

HEADERS  += mainwindow.h \
    version.h

FORMS    += mainwindow.ui

TRANSLATIONS += translations/mx-repo-manager_am.ts \
                translations/mx-repo-manager_ar.ts \
                translations/mx-repo-manager_bg.ts \
                translations/mx-repo-manager_ca.ts \
                translations/mx-repo-manager_cs.ts \
                translations/mx-repo-manager_da.ts \
                translations/mx-repo-manager_de.ts \
                translations/mx-repo-manager_el.ts \
                translations/mx-repo-manager_es.ts \
                translations/mx-repo-manager_et.ts \
                translations/mx-repo-manager_eu.ts \
                translations/mx-repo-manager_fa.ts \
                translations/mx-repo-manager_fi.ts \
                translations/mx-repo-manager_fr.ts \
                translations/mx-repo-manager_he_IL.ts \
                translations/mx-repo-manager_hi.ts \
                translations/mx-repo-manager_hr.ts \
                translations/mx-repo-manager_hu.ts \
                translations/mx-repo-manager_id.ts \
                translations/mx-repo-manager_is.ts \
                translations/mx-repo-manager_it.ts \
                translations/mx-repo-manager_ja.ts \
                translations/mx-repo-manager_ja_JP.ts \
                translations/mx-repo-manager_kk.ts \
                translations/mx-repo-manager_ko.ts \
                translations/mx-repo-manager_lt.ts \
                translations/mx-repo-manager_mk.ts \
                translations/mx-repo-manager_nb.ts \
                translations/mx-repo-manager_nl.ts \
                translations/mx-repo-manager_pl.ts \
                translations/mx-repo-manager_pt.ts \
                translations/mx-repo-manager_pt_BR.ts \
                translations/mx-repo-manager_ro.ts \
                translations/mx-repo-manager_ru.ts \
                translations/mx-repo-manager_sk.ts \
                translations/mx-repo-manager_sl.ts \
                translations/mx-repo-manager_sq.ts \
                translations/mx-repo-manager_sr.ts \
                translations/mx-repo-manager_sv.ts \
                translations/mx-repo-manager_tr.ts \
                translations/mx-repo-manager_uk.ts \
                translations/mx-repo-manager_zh_CN.ts \
                translations/mx-repo-manager_zh_TW.ts

RESOURCES += \
    images.qrc


unix:!macx: LIBS += -lcmd
