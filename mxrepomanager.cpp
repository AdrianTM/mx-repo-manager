/**********************************************************************
 *  mxrepomanager.cpp
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


#include "mxrepomanager.h"
#include "ui_mxrepomanager.h"

#include <QProcess>
#include <QRadioButton>
#include <QDebug>


mxrepomanager::mxrepomanager(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::mxrepomanager)
{
    ui->setupUi(this);
    version = getVersion("mx-repo-manager");
    this->setWindowTitle(tr("MX Repo Manager"));
    ui->buttonCancel->setEnabled(true);
    ui->buttonOK->setEnabled(true);
    refresh();
    int height = ui->listWidget->sizeHintForRow(0) * ui->listWidget->count();
    ui->listWidget->setMinimumHeight(height);
    this->adjustSize();
}

mxrepomanager::~mxrepomanager()
{
    delete ui;
}

// util function for getting bash command output and error code
Output mxrepomanager::runCmd(QString cmd)
{
    QProcess *proc = new QProcess();
    QEventLoop loop;
    proc->setReadChannelMode(QProcess::MergedChannels);
    proc->start("/bin/bash", QStringList() << "-c" << cmd);
    proc->waitForFinished();
    Output out = {proc->exitCode(), proc->readAll().trimmed()};
    delete proc;
    return out;
}


// refresh repo info
void mxrepomanager::refresh()
{
    displayRepos(readRepos());
    displayCurrent(getCurrentRepo());
}


// Get version of the program
QString mxrepomanager::getVersion(QString name)
{
    QString cmdstr = QString("dpkg -l %1 | awk 'NR==6 {print $3}'").arg(name);
    return runCmd(cmdstr).str;
}

// List available repos
QStringList mxrepomanager::readRepos()
{
    QString file_content;
    QStringList repos;
    file_content = runCmd("cat /usr/share/mx-repo-manager/repos.txt").str;
    repos = file_content.split("\n");
    repos.sort();
    return repos;
}

// List current repo
QString mxrepomanager::getCurrentRepo()
{
    return runCmd("grep -m1 '^deb.*/repo/ mx15 main non-free' /etc/apt/sources.list.d/mx.list | cut -d' ' -f2 | cut -d/ -f3").str;
}

// display available repos
void mxrepomanager::displayRepos(QStringList repos)
{
    ui->listWidget->clear();
    QStringListIterator repoIterator(repos);
    while (repoIterator.hasNext()) {
        QString repo = repoIterator.next();
        QListWidgetItem *it = new QListWidgetItem(ui->listWidget);
        ui->listWidget->setItemWidget(it, new QRadioButton(repo));
    }
}

// displays the current repo by selecting the item
void mxrepomanager::displayCurrent(QString repo)
{
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = (QRadioButton*)ui->listWidget->itemWidget(ui->listWidget->item(row));
        if (item->text().contains(repo)) {
            item->setChecked(true);
        }
    }
}

// set the selected repo
void mxrepomanager::setSelected()
{
    QString url;
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = (QRadioButton*)ui->listWidget->itemWidget(ui->listWidget->item(row));
        if (item->isChecked()) {
            url = item->text().section("http://", 1, -1, QString::SectionIncludeLeadingSep);
            replaceRepos(url);
        }
    }
}

// replaces the lines in the APT file
void mxrepomanager::replaceRepos(QString url)
{
    QString cmd_mx;
    QString cmd_antix = "true";
    QString mx_file = "/etc/apt/sources.list.d/mx.list";
    QString antix_file = "/etc/apt/sources.list.d/antix.list";
    QString repo_line_mx = "deb " + url + "/mx/repo/ mx15 main non-free";
    QString test_line_mx = "deb " + url + "/mx/testrepo/ mx15 test";
    cmd_mx = QString("sed -i 's;deb.*/repo/ mx15 main non-free;%1;' %2 && ").arg(repo_line_mx).arg(mx_file) +
            QString("sed -i 's;deb.*/testrepo/ mx15 test;%1;' %2").arg(test_line_mx).arg(mx_file);;
    // for antiX repos
    if (url != "http://mxrepo.com") {
        QString repo_line_antix = "deb " + url + "/antix/jessie/ jessie main";
        cmd_antix = QString("sed -i 's;deb.*/jessie/\\? jessie main;%1;' %2").arg(repo_line_antix).arg(antix_file);
    }
    if (runCmd(cmd_mx).exit_code == 0 && runCmd(cmd_antix).exit_code == 0) {
        QMessageBox::information(this, tr("Success"),
                                 tr("Your new selection will take effect the next time sources are updated."));
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not change the repo."));
    }

}

//// slots ////

// Submit button clicked
void mxrepomanager::on_buttonOK_clicked()
{
    setSelected();
    refresh();
}

// About button clicked
void mxrepomanager::on_buttonAbout_clicked()
{
    this->hide();
    QMessageBox msgBox(QMessageBox::NoIcon,
                       tr("About MX Repo Manager"), "<p align=\"center\"><b><h2>" +
                       tr("MX Repo Manager") + "</h2></b></p><p align=\"center\">" + tr("Version: ") + version + "</p><p align=\"center\"><h3>" +
                       tr("Program for choosing the default APT repository") +
                       "</h3></p><p align=\"center\"><a href=\"http://www.mepiscommunity.org/mx\">http://www.mepiscommunity.org/mx</a><br /></p><p align=\"center\">" +
                       tr("Copyright (c) MX Linux") + "<br /><br /></p>", 0, this);
    msgBox.addButton(tr("Cancel"), QMessageBox::AcceptRole); // because we want to display the buttons in reverse order we use counter-intuitive roles.
    msgBox.addButton(tr("License"), QMessageBox::RejectRole);
    if (msgBox.exec() == QMessageBox::RejectRole) {
        system("mx-viewer file:///usr/share/doc/mx-repo-manager/license.html '" + tr("MX Repo Manager").toUtf8() + " " + tr("License").toUtf8() + "'");
    }
    this->show();
}

// Help button clicked
void mxrepomanager::on_buttonHelp_clicked()
{
    this->hide();
    QString cmd = QString("mx-viewer http://mepiscommunity.org/wiki/help-files/help-mx-repo-manager '%1'").arg(tr("MX Repo Manager"));
    system(cmd.toUtf8());
    this->show();
}
