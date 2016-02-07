/**********************************************************************
 *  mxrepomanager.h
 **********************************************************************
 * Copyright (C) 2015 MX Authors
 *
 * Authors: Adrian
 *          MX & MEPIS Community <http://forum.mepiscommunity.org>
 *
 * This file is part of mx-repo-manager.
 *
 * mx-repo-manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * mx-repo-manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with mx-repo-manager.  If not, see <http://www.gnu.org/licenses/>.
 **********************************************************************/


#ifndef MXREPOMANAGER_H
#define MXREPOMANAGER_H

#include <QMessageBox>

namespace Ui {
class mxrepomanager;
}

// struct for outputing both the exit code and the strings when running a command
struct Output {
    int exit_code;
    QString str;
};


class mxrepomanager : public QDialog
{
    Q_OBJECT

public:
    explicit mxrepomanager(QWidget *parent = 0);
    ~mxrepomanager();

    QString version;

    void displayRepos(QStringList repos);
    void displayCurrent(QString repo);
    void refresh();
    void replaceRepos(QString url);
    void setSelected();
    Output runCmd(QString cmd);
    QString getCurrentRepo();
    QString getVersion(QString name);    
    QStringList readRepos();

private slots:
    void on_buttonOK_clicked();
    void on_buttonAbout_clicked();
    void on_buttonHelp_clicked();

private:
    Ui::mxrepomanager *ui;
};


#endif // MXREPOMANAGER_H

