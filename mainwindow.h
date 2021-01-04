/**********************************************************************
 *  mainwindow.h
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


#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QDir>
#include <QListWidgetItem>
#include <QMessageBox>
#include <QNetworkAccessManager>
#include <QProgressDialog>
#include <QTimer>
#include <QTreeWidget>

#include "cmd.h"


namespace Ui {
class MainWindow;
}

class MainWindow : public QDialog
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    QString version;
    QString listMXurls;
    QList<QStringList> queued_changes;
    void centerWindow();
    void displayMXRepos(const QStringList &repos, const QString &filter);
    void displayAllRepos(const QFileInfoList &apt_files);
    void displaySelected(const QString &repo);
    void extractUrls(const QStringList &repos);
    void getCurrentRepo();
    void refresh();
    void replaceDebianRepos(QString url);
    void replaceRepos(const QString &url);
    void setProgressBar();
    void setSelected();
    QFileInfoList listAptFiles();
    QIcon getFlag(QString country);
    int getDebianVerNum();
    QString getDebianVerName(int ver);
    QStringList readMXRepos();
    QStringList loadAptFile(const QString &file);

private slots:
    void cancelOperation();
    void closeEvent(QCloseEvent *);
    void procDone();
    void procTime();
    void procStart();

    void on_buttonOk_clicked();
    void on_buttonAbout_clicked();
    void on_buttonHelp_clicked();
    void on_treeWidget_itemChanged(QTreeWidgetItem * item, int column);
    void on_treeWidgetDeb_itemChanged(QTreeWidgetItem * item, int column);
    void on_tabWidget_currentChanged();
    void on_pushFastestDebian_clicked();
    void on_pushFastestMX_clicked();
    void on_lineSearch_textChanged(const QString &arg1);
    void on_pb_restoreSources_clicked();

private:
    Ui::MainWindow *ui;
    Cmd *shell;
    QHash<QString, QIcon> flags;
    QProgressBar *bar;
    QProgressDialog *progress;
    QPushButton *progCancel;
    QString current_repo;
    QStringList repos;
    QTimer timer;

    QNetworkAccessManager manager;
    QNetworkReply* reply;
    bool checkRepo(const QString &repo);
    bool downloadFile(const QString &url, QFile &file);

};


#endif // MAINWINDOW_H

