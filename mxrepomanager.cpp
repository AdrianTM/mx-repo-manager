/**********************************************************************
 *  mxrepomanager.cpp
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


#include "mxrepomanager.h"
#include "ui_mxrepomanager.h"

#include <QDebug>

#include <QDir>
#include <QProcess>
#include <QRadioButton>
#include <QProgressBar>


mxrepomanager::mxrepomanager(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::mxrepomanager)
{
    ui->setupUi(this);

    timer = new QTimer(this);
    progress = new QProgressDialog(this);
    bar = new QProgressBar(progress);
    progress->setWindowModality(Qt::WindowModal);
    progress->setWindowFlags(Qt::Dialog | Qt::CustomizeWindowHint | Qt::WindowTitleHint |Qt::WindowSystemMenuHint | Qt::WindowStaysOnTopHint);
    progress->setCancelButton(0);
    progress->setLabelText(tr("Please wait..."));
    progress->setAutoClose(false);
    progress->setBar(bar);
    bar->setTextVisible(false);

    ui->buttonOK->setDisabled(true);

    version = getVersion("mx-repo-manager");
    this->setWindowTitle(tr("MX Repo Manager"));
    ui->tabWidget->setCurrentWidget(ui->tabMX);
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
Output mxrepomanager::runCmd(const QString &cmd)
{
    QEventLoop loop;
    QProcess *proc = new QProcess(this);
    proc->setReadChannelMode(QProcess::MergedChannels);

    connect(timer, SIGNAL(timeout()), SLOT(procTime()));
    connect(proc, SIGNAL(started()), SLOT(procStart()));
    connect(proc, SIGNAL(finished(int)), SLOT(procDone(int)));

    connect(proc, SIGNAL(finished(int)), &loop, SLOT(quit()));
    proc->start("/bin/bash", QStringList() << "-c" << cmd);
    loop.exec();

    disconnect(timer, 0, 0, 0);
    disconnect(proc, 0, 0, 0);

    Output out = {proc->exitCode(), proc->readAll().trimmed()};
    delete proc;
    return out;
}

// refresh repo info
void mxrepomanager::refresh()
{
    displayMXRepos(readMXRepos());
    selectRepo(getCurrentRepo());
    displayAllRepos(listAptFiles());
}

// replace default Debian repos
void mxrepomanager::replaceDebianRepos(const QString &url)
{
    QStringList files;
    QString cmd;

    // Debian list files that are present by default in MX
    files << "/etc/apt/sources.list.d/debian.list" << "/etc/apt/sources.list.d/debian-stable-updates.list";

    // make backup folder
    if (!QDir("/etc/apt/sources.list.d/backups").exists()) {
        QDir().mkdir("/etc/apt/sources.list.d/backups");
    }

    foreach(QString file, files) {
        QFileInfo fileinfo(file);

        // backup file
        cmd = "cp " + file + " /etc/apt/sources.list.d/backups/" + fileinfo.fileName() + ".$(date +%s)";
        system(cmd.toUtf8());
        cmd = "sed -i 's;deb\\s.*/debian/;deb " + url + ";' " + file ; // replace deb lines in file
        system(cmd.toUtf8());
        cmd = "sed -i 's;deb-src\\s.*/debian/;deb-src " + url + ";' " + file; // replace deb-src lines in file
        system(cmd.toUtf8());
    }
    QMessageBox::information(this, tr("Success"),
                             tr("Your new selection will take effect the next time sources are updated."));
}


// Get version of the program
QString mxrepomanager::getVersion(const QString &name)
{
    QString cmdstr = QString("dpkg -l %1 | awk 'NR==6 {print $3}'").arg(name);
    return runCmd(cmdstr).str;
}

// List available repos
QStringList mxrepomanager::readMXRepos()
{
    QString file_content;
    QStringList repos;
    QFile file("/usr/share/mx-repo-manager/repos.txt");
    if(!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Count not open file: " << file.fileName();
    }
    file_content = file.readAll().trimmed();
    file.close();

    repos = file_content.split("\n");
    repos.sort();
    extractUrls(repos);
    return repos;
}

// List current repo
QString mxrepomanager::getCurrentRepo()
{
    return runCmd("grep -m1 '^deb.*/repo/ mx' /etc/apt/sources.list.d/mx.list | cut -d' ' -f2 | cut -d/ -f3").str;
}

QString mxrepomanager::getDebianVersion()
{
    return runCmd("cat /etc/debian_version | cut -f1 -d'.'").str;
}

// display available repos
void mxrepomanager::displayMXRepos(const QStringList &repos)
{
    ui->listWidget->clear();
    QStringListIterator repoIterator(repos);
    QIcon flag;
    while (repoIterator.hasNext()) {
        QString repo = repoIterator.next();
        QString country = repo.section("-", 0, 0).trimmed();
        QListWidgetItem *item = new QListWidgetItem(ui->listWidget);
        QRadioButton *button = new QRadioButton(repo);
        buildFlags();
        button->setIcon(flags.value(country));
        ui->listWidget->setItemWidget(item, button);
        connect(button, SIGNAL(clicked(bool)),ui->buttonOK, SLOT(setEnabled(bool)));
    }
}

void mxrepomanager::displayAllRepos(const QFileInfoList &apt_files)
{
    ui->treeWidget->clear();
    ui->treeWidgetDeb->clear();
    ui->treeWidget->blockSignals(true);
    ui->treeWidgetDeb->blockSignals(true);

    QStringList columnNames;
    columnNames << tr("Lists") << tr("Sources (checked sources are enabled)");
    ui->treeWidget->setHeaderLabels(columnNames);
    ui->treeWidgetDeb->setHeaderLabels(columnNames);

    QTreeWidgetItem *topLevelItem;
    QTreeWidgetItem *topLevelItemDeb;
    QFileInfo file_info;
    foreach (file_info, apt_files) {
        QString file_name = file_info.fileName();
        QString file = file_info.absoluteFilePath();
        topLevelItem = new QTreeWidgetItem;
        topLevelItem->setText(0, file_name);
        topLevelItemDeb = new QTreeWidgetItem;
        topLevelItemDeb->setText(0, file_name);
        ui->treeWidget->addTopLevelItem(topLevelItem);
        if (file_name.contains("debian")) {
            ui->treeWidgetDeb->addTopLevelItem(topLevelItemDeb);
        }
        // topLevelItem look
        topLevelItem->setForeground(0, QBrush(Qt::darkGreen));
        topLevelItemDeb->setForeground(0, QBrush(Qt::darkGreen));
        topLevelItem->setIcon(0, QIcon("/usr/share/mx-repo-manager/icons/folder.png"));
        topLevelItemDeb->setIcon(0, QIcon("/usr/share/mx-repo-manager/icons/folder.png"));
        // load file entries
        QStringList entries = loadAptFile(file);
        QString item;
        foreach (item, entries) {
            // add entries as childItem to treeWidget
            QTreeWidgetItem *childItem = new QTreeWidgetItem(topLevelItem);
            QTreeWidgetItem *childItemDeb = new QTreeWidgetItem(topLevelItemDeb);
            childItem->setText(1, item);
            childItemDeb->setText(1, item);
            // add checkboxes
            childItem->setFlags(childItem->flags() | Qt::ItemIsUserCheckable);
            childItemDeb->setFlags(childItem->flags() | Qt::ItemIsUserCheckable);
            if (item.startsWith("#")) {
                childItem->setCheckState(1, Qt::Unchecked);
                childItemDeb->setCheckState(1, Qt::Unchecked);
            } else {
                childItem->setCheckState(1, Qt::Checked);
                childItemDeb->setCheckState(1, Qt::Checked);
            }
        }
    }
    for (int i = 0; i < ui->treeWidget->columnCount(); i++) {
        ui->treeWidget->resizeColumnToContents(i);
    }
    for (int i = 0; i < ui->treeWidgetDeb->columnCount(); i++) {
        ui->treeWidgetDeb->resizeColumnToContents(i);
    }
    ui->treeWidget->expandAll();
    ui->treeWidgetDeb->expandAll();
    ui->treeWidget->blockSignals(false);
    ui->treeWidgetDeb->blockSignals(false);
}

QStringList mxrepomanager::loadAptFile(const QString &file)
{
    QString entries = runCmd("grep '^#*[ ]*deb' " + file).str;
    return entries.split("\n");
}

// displays the current repo by selecting the item
void mxrepomanager::selectRepo(const QString &repo)
{
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = (QRadioButton*)ui->listWidget->itemWidget(ui->listWidget->item(row));
        if (item->text().contains(repo)) {
            item->setChecked(true);
        }
    }
}

// extract the URLs from the list of repos that contain country names and description
void mxrepomanager::extractUrls(const QStringList &repos)
{
    foreach(QString line, repos) {
        QStringList linelist = line.split("-");
        listMXurls += linelist[1].trimmed() + " ";
    }
}

// set the selected repo
void mxrepomanager::setSelected()
{
    QString url;
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = (QRadioButton*)ui->listWidget->itemWidget(ui->listWidget->item(row));
        if (item->isChecked()) {
            url = item->text().section("http://", 1, 1, QString::SectionIncludeLeadingSep).trimmed();
            replaceRepos(url);
        }
    }
}


void mxrepomanager::procTime()
{
    if (bar->value() == 100) {
        bar->reset();
    }
    bar->setValue(bar->value() + 1);
    //qApp->processEvents();
}

void mxrepomanager::procStart()
{
    timer->start(100);
    bar->setValue(0);
    QApplication::setOverrideCursor(QCursor(Qt::BusyCursor));
}

void mxrepomanager::procDone(int)
{
    timer->stop();
    bar->setValue(100);
    QApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));
}

// replaces the lines in the APT file
void mxrepomanager::replaceRepos(const QString &url)
{
    QString cmd_mx;
    QString cmd_antix = "true";
    QString repo_line_antix;
    QString mx_file = "/etc/apt/sources.list.d/mx.list";
    if (QFile("/etc/apt/sources.list.d/mx16.list").exists()) {
        mx_file += " /etc/apt/sources.list.d/mx16.list";       // add mx16.list to the list if it exists
    }
    QString antix_file = "/etc/apt/sources.list.d/antix.list";
    QString repo_line_mx = "deb " + url + "/mx/repo/ mx";
    QString test_line_mx = "deb " + url + "/mx/testrepo/ mx";
    cmd_mx = QString("sed -i 's;deb.*/repo/ mx;%1;' %2 && ").arg(repo_line_mx).arg(mx_file) +
            QString("sed -i 's;deb.*/testrepo/ mx;%1;' %2").arg(test_line_mx).arg(mx_file);;
    // for antiX repos
    if (url == "http://mxrepo.com") {
        repo_line_antix = "deb http://antix.daveserver.info/jessie jessie main";
    } else {
        repo_line_antix = "deb " + url + "/antix/jessie/ jessie main";
    }
    cmd_antix = QString("sed -i 's;deb.*/jessie/\\? jessie main;%1;' %2").arg(repo_line_antix).arg(antix_file);
    if (runCmd(cmd_mx).exit_code == 0 && runCmd(cmd_antix).exit_code == 0) {
        QMessageBox::information(this, tr("Success"),
                                 tr("Your new selection will take effect the next time sources are updated."));
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not change the repo."));
    }
 //   qApp->quit();
}

QFileInfoList mxrepomanager::listAptFiles()
{
    QStringList apt_files;
    QFileInfoList list;
    QDir apt_dir("/etc/apt/sources.list.d");
    list << apt_dir.entryInfoList(QStringList("*.list"));
    QFile file("/etc/apt/sources.list");
    if (file.size() != 0) {
        list << file;
    }
    return list;
}


//// slots ////

// Submit button clicked
void mxrepomanager::on_buttonOK_clicked()
{
    if (queued_changes.size() > 0) {
        QStringList changes;
        foreach (changes, queued_changes) {
            QString text, new_text, file_name;
            text = changes[0];
            new_text = changes[1];
            file_name = changes[2];
            QString cmd = QString("sed -i 's;%1;%2;g' %3").arg(text).arg(new_text).arg(file_name);
            runCmd(cmd);
        }
        queued_changes.clear();
    }
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
                       "</h3></p><p align=\"center\"><a href=\"http://mxlinux.org\">http://mxlinux.org</a><br /></p><p align=\"center\">" +
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
    QString cmd = QString("mx-viewer https://mxlinux.org/wiki/help-files/help-mx-repo-manager '%1'").arg(tr("MX Repo Manager"));
    system(cmd.toUtf8());
    this->show();
}

void mxrepomanager::on_treeWidget_itemChanged(QTreeWidgetItem * item, int column)
{
    ui->buttonOK->setEnabled(true);
    ui->treeWidget->blockSignals(true);
    QFile file;
    QString new_text;
    QString file_name = item->parent()->text(0);
    QString text = item->text(column);
    QStringList changes;
    if (file_name == "sources.list") {
        file.setFileName("/etc/apt/" + file_name);
    } else {
        file.setFileName("/etc/apt/sources.list.d/" + file_name);
    }
    if (item->checkState(column) == Qt::Checked) {
        new_text = text;
        new_text.remove(QRegExp("#\\s*"));
        item->setText(column, new_text);
    } else {
        new_text = "# " + text;
        item->setText(column, new_text);
    }
    changes << text << new_text << file.fileName();
    queued_changes << changes;
    ui->treeWidget->blockSignals(false);
}

void mxrepomanager::on_treeWidgetDeb_itemChanged(QTreeWidgetItem *item, int column)
{
    ui->buttonOK->setEnabled(true);
    ui->treeWidgetDeb->blockSignals(true);
    QFile file;
    QString new_text;
    QString file_name = item->parent()->text(0);
    QString text = item->text(column);
    QStringList changes;
    if (file_name == "sources.list") {
        file.setFileName("/etc/apt/" + file_name);
    } else {
        file.setFileName("/etc/apt/sources.list.d/" + file_name);
    }
    if (item->checkState(column) == Qt::Checked) {
        new_text = text;
        new_text.remove(QRegExp("#\\s*"));
        item->setText(column, new_text);
    } else {
        new_text = "# " + text;
        item->setText(column, new_text);
    }
    changes << text << new_text << file.fileName();
    queued_changes << changes;
    ui->treeWidgetDeb->blockSignals(false);
}

void mxrepomanager::on_tabWidget_currentChanged()
{
    if (ui->tabWidget->currentWidget() == ui->tabMX) {
        ui->label->setText(tr("Select the APT repository that you want to use:"));
    } else {
        ui->label->setText(tr("Select the APT repository and sources that you want to use:"));
    }
}

// build the list of flags for the country name
void mxrepomanager::buildFlags()
{
    flags.insert("Crete", QIcon("/usr/share/mx-repo-manager/icons/gr.png"));
    flags.insert("Ecuador", QIcon("/usr/share/mx-repo-manager/icons/ec.png"));
    flags.insert("France", QIcon("/usr/share/mx-repo-manager/icons/fr.png"));
    flags.insert("Germany", QIcon("/usr/share/mx-repo-manager/icons/de.png"));
    flags.insert("New Zealand", QIcon("/usr/share/mx-repo-manager/icons/nz.png"));
    flags.insert("Sweden", QIcon("/usr/share/mx-repo-manager/icons/se.png"));
    flags.insert("The Netherlands", QIcon("/usr/share/mx-repo-manager/icons/nl.png"));
    flags.insert("Taiwan", QIcon("/usr/share/mx-repo-manager/icons/tw.png"));
    flags.insert("USA, Los Angeles", QIcon("/usr/share/mx-repo-manager/icons/us.png"));
    flags.insert("USA, Utah", QIcon("/usr/share/mx-repo-manager/icons/us.png"));
}

// detect fastest Debian repo
void mxrepomanager::on_pushFastestDebian_clicked()
{
    QString repo;

    progress->show();
    QString tmpfile = runCmd("mktemp -d /tmp/mx-repo-manager-XXXXXXXX").str + "/sources.list";

    QString ver_num = getDebianVersion();
    QString ver_name;
    if (ver_num == "8") {
        ver_name = "jessie";
    } else if (ver_name == "9") {
        ver_name = "stretch";
    }

    Output out = runCmd("netselect-apt " + ver_name + " -o " + tmpfile);
    progress->hide();

    if (out.exit_code != 0) {
        QMessageBox::critical(this, tr("Error"),
                              tr("netselect-apt could not detect fastest repo."));
        return;
    }
    out = runCmd("set -o pipefail; grep -m1 '^deb ' " + tmpfile + "| cut -d' ' -f2");
    repo = out.str;
    this->blockSignals(false);
    if (out.exit_code == 0 && runCmd("wget --spider " + repo).exit_code == 0) {
        replaceDebianRepos(repo);
        refresh();
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not detect fastest repo."));
    }
}

// detect and select the fastest MX repo
void mxrepomanager::on_pushFastestMX_clicked()
{
    progress->show();
    Output out = runCmd("set -o pipefail; netselect -D -I " + listMXurls + "| cut -d' ' -f4");
    progress->hide();
    if (out.exit_code == 0 && out.str !="") {
        selectRepo(out.str);
        on_buttonOK_clicked();
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not detect fastest repo."));
    }
}
