/**********************************************************************
 *  mxrepomanager.h
 **********************************************************************
 * Copyright (C) 2015 MX Authors
 *
 * Authors: Adrian
 *          MX Linux <http://mxlinux.org>
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
#include <QDir>
#include <QTreeWidget>
#include <QListWidgetItem>

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
    QList<QStringList> queued_changes;

    void buildFlags();
    void displayMXRepos(const QStringList &repos);
    void displayAllRepos(const QFileInfoList &apt_files);
    void displayCurrent(const QString &repo);
    void refresh();
    void replaceDebianRepos(const QString &url);
    void replaceRepos(const QString &url);
    void setSelected();
    Output runCmd(const QString &cmd);
    QFileInfoList listAptFiles();
    QString getCurrentRepo();
    QString getVersion(const QString &name);
    QStringList readMXRepos();
    QStringList loadAptFile(const QString &file);


private slots:
    void on_buttonOK_clicked();
    void on_buttonAbout_clicked();
    void on_buttonHelp_clicked();
    void on_treeWidget_itemChanged(QTreeWidgetItem * item, int column);
    void on_treeWidgetDeb_itemChanged(QTreeWidgetItem * item, int column);
    void on_tabWidget_currentChanged();
    void on_pushFastestDebian_clicked();


private:
    Ui::mxrepomanager *ui;
    QHash<QString, QIcon> flags;
};


#endif // MXREPOMANAGER_H

