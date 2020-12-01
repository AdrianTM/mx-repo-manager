/**********************************************************************
 *  mainwindow.cpp
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

#include "about.h"
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "version.h"

#include <QDebug>

#include <QDir>
#include <QMetaEnum>
#include <QRadioButton>
#include <QProgressBar>
#include <QTextEdit>

MainWindow::MainWindow(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::MainWindow)
{
    qDebug().noquote() << QCoreApplication::applicationName() << "version:" << VERSION;
    ui->setupUi(this);
    if (ui->buttonOk->icon().isNull()) {
        ui->buttonOk->setIcon(QIcon(":/icons/dialog-ok.svg"));
    }
    if (ui->pushFastestMX->icon().isNull()) {
        ui->pushFastestMX->setIcon(QIcon(":/icons/cursor-arrow.svg"));
    }
    if (ui->pushFastestDebian->icon().isNull()) {
        ui->pushFastestDebian->setIcon(QIcon(":/icons/cursor-arrow.svg"));
    }

    shell = new Cmd(this);

    connect(shell, &Cmd::started, this, &MainWindow::procStart);
    connect(shell, &Cmd::finished, this, &MainWindow::procDone);

    progress = new QProgressDialog(this);
    bar = new QProgressBar(progress);
    bar->setMaximum(100);
    progCancel = new QPushButton(tr("Cancel"));
    connect(progCancel, &QPushButton::clicked, this, &MainWindow::cancelOperation);
    progress->setWindowModality(Qt::WindowModal);
    progress->setWindowFlags(Qt::Dialog | Qt::CustomizeWindowHint | Qt::WindowTitleHint |Qt::WindowSystemMenuHint | Qt::WindowStaysOnTopHint);
    progress->setCancelButton(progCancel);
    progress->setLabelText(tr("Please wait..."));
    progress->setAutoClose(false);
    progress->setBar(bar);
    bar->setTextVisible(false);
    progress->reset();

    ui->buttonOk->setDisabled(true);

    this->setWindowTitle(tr("MX Repo Manager"));
    ui->tabWidget->setCurrentWidget(ui->tabMX);
    refresh();
    //int height = ui->listWidget->sizeHintForRow(0) * ui->listWidget->count();
    //ui->listWidget->setMinimumHeight(height);
    //this->adjustSize();
}

MainWindow::~MainWindow()
{
    delete ui;
}

// refresh repo info
void MainWindow::refresh()
{
    getCurrentRepo();
    displayMXRepos(readMXRepos(), QString());
    displayAllRepos(listAptFiles());
    ui->lineSearch->clear();
    ui->lineSearch->setFocus();
}

// replace default Debian repos
void MainWindow::replaceDebianRepos(QString url)
{
    QStringList files;
    QString cmd;

    // Debian list files that are present by default in MX
    files << "/etc/apt/sources.list.d/debian.list" << "/etc/apt/sources.list.d/debian-stable-updates.list";

    // make backup folder
    if (!QDir("/etc/apt/sources.list.d/backups").exists()) {
        QDir().mkdir("/etc/apt/sources.list.d/backups");
    }

    for (const QString &file : files) {
        QFileInfo fileinfo(file);

        // backup file
        cmd = "cp " + file + " /etc/apt/sources.list.d/backups/" + fileinfo.fileName() + ".$(date +%s)";
        shell->run(cmd);

        cmd = "sed -i 's;deb\\s.*/debian/*[^-];deb " + url + " ;' " + file ; // replace deb lines in file
        shell->run(cmd);
        cmd = "sed -i 's;deb-src\\s.*/debian/*[^-];deb-src " + url + ";' " + file; // replace deb-src lines in file
        shell->run(cmd);
        if (url == "https://deb.debian.org/debian/") {
            cmd = "sed -i 's;deb\\s*http://security.debian.org/;deb https://deb.debian.org/debian-security/;' " + file; // replace security.debian.org in file
            shell->run(cmd);
        }
    }
    QMessageBox::information(this, tr("Success"),
                             tr("Your new selection will take effect the next time sources are updated."));
}

// List available repos
QStringList MainWindow::readMXRepos()
{
    QFile file("/usr/share/mx-repo-list/repos.txt");
    if(!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Count not open file: " << file.fileName();
    }
    QString file_content = file.readAll().trimmed();
    file.close();

    QStringList file_content_list = file_content.split("\n");
    file_content_list.sort();

    // remove commented out lines
    QStringList repos;
    for (const QString &line : file_content_list) {
        if (!line.startsWith("#")) {
            repos << line;
        }
    }

    extractUrls(repos);
    this->repos = repos;
    return repos;
}

// List current repo
void MainWindow::getCurrentRepo()
{
    current_repo  = shell->getCmdOut("grep -m1 '^deb.*/repo/ ' /etc/apt/sources.list.d/mx.list | cut -d' ' -f2 | cut -d/ -f3");
}

QString MainWindow::getDebianVersion()
{
    return shell->getCmdOut("cat /etc/debian_version | cut -f1 -d'.'");
}

// display available repos
void MainWindow::displayMXRepos(const QStringList &repos, const QString &filter)
{
    ui->listWidget->clear();
    QStringListIterator repoIterator(repos);
    QIcon flag;
    while (repoIterator.hasNext()) {
        QString repo = repoIterator.next();
        if (!filter.isEmpty() && !repo.contains(filter, Qt::CaseInsensitive)) {
            continue;
        }
        QString country = repo.section("-", 0, 0).trimmed().section(",", 0, 0);
        QListWidgetItem *item = new QListWidgetItem(ui->listWidget);
        QRadioButton *button = new QRadioButton(repo);
        button->setIcon(getFlag(country));
        ui->listWidget->setItemWidget(item, button);
        if (repo.contains(current_repo)) {
            button->setChecked(true);
            ui->listWidget->scrollToItem(item);
        }
        connect(button, &QRadioButton::clicked, ui->buttonOk, &QPushButton::setEnabled);
    }
}

void MainWindow::displayAllRepos(const QFileInfoList &apt_files)
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

    for (const QFileInfo &file_info : apt_files) {
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
        // load file entries
        const QStringList entries = loadAptFile(file);

        for (const QString &item : entries) {
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

QStringList MainWindow::loadAptFile(const QString &file)
{
    QString entries = shell->getCmdOut("grep '^#*[ ]*deb' " + file);
    return entries.split("\n");
}

void MainWindow::cancelOperation()
{
    shell->halt();
    procDone();
}

// displays the current repo by selecting the item
void MainWindow::displaySelected(const QString &repo)
{
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = static_cast<QRadioButton*>(ui->listWidget->itemWidget(ui->listWidget->item(row)));
        if (item->text().contains(repo)) {
            item->setChecked(true);
            ui->listWidget->scrollToItem(ui->listWidget->item(row));
        }
    }
}

// extract the URLs from the list of repos that contain country names and description
void MainWindow::extractUrls(const QStringList &repos)
{
    for (const QString &line : repos) {
        QStringList linelist = line.split("-");
        linelist.removeAt(0);
        listMXurls += linelist.join("-").trimmed() + " ";
    }
}

// set the selected repo
void MainWindow::setSelected()
{
    QString url;
    for (int row = 0; row < ui->listWidget->count(); ++row) {
        QRadioButton *item = static_cast<QRadioButton*>(ui->listWidget->itemWidget(ui->listWidget->item(row)));
        if (item->isChecked()) {
            url = item->text().section(" - ", 1, 1).trimmed();
            replaceRepos(url);
        }
    }
}

void MainWindow::procTime()
{
    if (bar->value() == 100) {
        bar->reset();
    }
    bar->setValue(bar->value() + 1);
//    qApp->processEvents();
}

void MainWindow::procStart()
{
    bar->setValue(0);
    QApplication::setOverrideCursor(QCursor(Qt::BusyCursor));
    timer.start(100);
    connect(&timer, &QTimer::timeout, this, &MainWindow::procTime);
}

void MainWindow::procDone()
{
    bar->setValue(100);
    timer.stop();
    timer.disconnect();
    QApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));
}



// replaces the lines in the APT file
void MainWindow::replaceRepos(const QString &url)
{
    QString cmd_mx;
    QString cmd_antix;
    QString repo_line_antix;

    // get Debian version
    QString ver_num = getDebianVersion();
    QString ver_name;
    if (ver_num == "8") {
        ver_name = "jessie";
    } else if (ver_num == "9") {
        ver_name = "stretch";
    } else if (ver_num == "10") {
        ver_name = "buster";
   }

    // mx source files to be edited (mx.list and mx16.list for MX15/16)
    QString mx_file = "/etc/apt/sources.list.d/mx.list";
    if (QFile("/etc/apt/sources.list.d/mx16.list").exists()) {
        mx_file += " /etc/apt/sources.list.d/mx16.list";       // add mx16.list to the list if it exists
    }

    // for MX repos
    QString repo_line_mx = "deb " + url + "/mx/repo/ ";
    QString test_line_mx = "deb " + url + "/mx/testrepo/ ";
    cmd_mx = QString("sed -i 's;deb.*/repo/ ;%1;' %2 && ").arg(repo_line_mx).arg(mx_file) +
            QString("sed -i 's;deb.*/testrepo/ ;%1;' %2").arg(test_line_mx).arg(mx_file);

    if (ver_num.toInt() < 9) {
        // for antiX repos
        QString antix_file = "/etc/apt/sources.list.d/antix.list";
        if (url == "http://mxrepo.com") {
            repo_line_antix = "http://la.mxrepo.com/antix/" + ver_name + "/";
        } else {
            repo_line_antix = url + "/antix/" + ver_name + "/";
        }
        cmd_antix = QString("sed -i 's;https\\?://.*/" + ver_name + "/\\?;%1;' %2").arg(repo_line_antix).arg(antix_file);
    }

    // check if both replacement were successful
    if (shell->run(cmd_mx) && (ver_num.toInt() >= 9 || shell->run(cmd_antix))) {
        QMessageBox::information(this, tr("Success"),
                                 tr("Your new selection will take effect the next time sources are updated."));
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not change the repo."));
    }
}

QFileInfoList MainWindow::listAptFiles()
{
    QStringList apt_files;
    QFileInfoList list;
    QDir apt_dir("/etc/apt/sources.list.d");
    list << apt_dir.entryInfoList(QStringList("*.list"));
    QFile file("/etc/apt/sources.list");
    if (file.size() != 0 && shell->run("grep '^#*[ ]*deb' " + file.fileName(), true)) {
        list << file;
    }
    return list;
}


//// slots ////

// Submit button clicked
void MainWindow::on_buttonOk_clicked()
{
    if (queued_changes.size() > 0) {
        for (const QStringList &changes : queued_changes) {
            QString text, new_text, file_name;
            text = changes[0];
            new_text = changes[1];
            file_name = changes[2];
            QString cmd = QString("sed -i 's;%1;%2;g' %3").arg(text).arg(new_text).arg(file_name);
            shell->run(cmd);
        }
        queued_changes.clear();
    }
    setSelected();
    refresh();
}

// About button clicked
void MainWindow::on_buttonAbout_clicked()
{
    this->hide();
    displayAboutMsgBox(tr("About %1").arg(this->windowTitle()), "<p align=\"center\"><b><h2>" + this->windowTitle() +"</h2></b></p><p align=\"center\">" +
                       tr("Version: ") + VERSION + "</p><p align=\"center\"><h3>" +
                       tr("Program for choosing the default APT repository") +
                       "</h3></p><p align=\"center\"><a href=\"http://mxlinux.org\">http://mxlinux.org</a><br /></p><p align=\"center\">" +
                       tr("Copyright (c) MX Linux") + "<br /><br /></p>",
                       "/usr/share/doc/mx-repo-manager/license.html", tr("%1 License").arg(this->windowTitle()), true);
    this->show();
}

// Help button clicked
void MainWindow::on_buttonHelp_clicked()
{
    QLocale locale;
    QString lang = locale.bcp47Name();

    QString url = "/usr/share/doc/mx-repo-manager/help/mx-repo-manager.html";

    if (lang.startsWith("fr")) {
        url = "https://mxlinux.org/wiki/help-files/help-mx-gestionnaire-de-d%C3%A9p%C3%B4ts";
    }
    displayDoc(url, tr("%1 Help").arg(this->windowTitle()), true);
}

void MainWindow::on_treeWidget_itemChanged(QTreeWidgetItem * item, int column)
{
    ui->buttonOk->setEnabled(true);
    ui->treeWidget->blockSignals(true);
    if (item->text(column).contains("/mx/testrepo/") && item->checkState(column) == Qt::Checked) {
        QMessageBox::warning(this, tr("Warning"),
                             tr("You have selected MX Test Repo. It's not recommended to leave it enabled or to upgrade all the packages from it.") +"\n\n" +
                             tr("A safer option is to install packages individually with MX Package Installer."));
    }
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

void MainWindow::on_treeWidgetDeb_itemChanged(QTreeWidgetItem *item, int column)
{
    ui->buttonOk->setEnabled(true);
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

void MainWindow::on_tabWidget_currentChanged()
{
    if (ui->tabWidget->currentWidget() == ui->tabMX) {
        ui->label->setText(tr("Select the APT repository that you want to use:"));
    } else {
        ui->label->setText(tr("Select the APT repository and sources that you want to use:"));
    }
}

// Transform "country" name to 2-3 letter ISO 3166 country code and provide the QIcon for it
QIcon MainWindow::getFlag(QString country)
{
    QMetaObject metaObject = QLocale::staticMetaObject;
    QMetaEnum metaEnum = metaObject.enumerator(metaObject.indexOfEnumerator("Country"));
    // fix flag of the Netherlands               : QLocale::Netherlands
    if (country == "The Netherlands" ) { country = "Netherlands"; }
    // fix flag of the United States of America  : QLocale::UnitedStates
    if (country == "USA" )             { country = "UnitedStates"; }
    if (country == "Anycast" || country == "Any" || country == "World") {
        return QIcon("/usr/share/flags-common/any.png");
    }
    //QMetaEnum metaEnum = QMetaEnum::fromType<QLocale::Country>(); -- not in older Qt versions
    int index = metaEnum.keyToValue(country.remove(" ").toUtf8());
    QList<QLocale> locales = QLocale::matchingLocales(QLocale::AnyLanguage, QLocale::AnyScript, QLocale::Country(index));
    // qDebug() << "etFlag county: " << country << " locales: " << locales;
    if (locales.length() > 0) {
        QString short_name = locales.at(0).name().section("_", 1, 1).toLower();
        return QIcon("/usr/share/flags-common/" + short_name + ".png");
    }
    return QIcon();
}

// detect fastest Debian repo
void MainWindow::on_pushFastestDebian_clicked()
{
    QString repo;

    progress->show();
    QString tmpfile = shell->getCmdOut("mktemp -d /tmp/mx-repo-manager-XXXXXXXX") + "/sources.list";

    QString ver_num = getDebianVersion();
    QString ver_name;
    if (ver_num == "8") {
        ver_name = "jessie";
    } else if (ver_num == "9") {
        ver_name = "stretch";
    }

    QByteArray out;
    bool success = shell->run("netselect-apt " + ver_name + " -o " + tmpfile, out, false);
    progress->hide();

    if (!success) {
        QMessageBox::critical(this, tr("Error"),
                              tr("netselect-apt could not detect fastest repo."));
        return;
    }
    repo = shell->getCmdOut("set -o pipefail; grep -m1 '^deb ' " + tmpfile + "| cut -d' ' -f2");
    this->blockSignals(false);

    if (success && shell->run("wget --spider " + repo)) {
        replaceDebianRepos(repo);
        refresh();
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not detect fastest repo."));
    }
}

// detect and select the fastest MX repo
void MainWindow::on_pushFastestMX_clicked()
{
    progress->show();
    QByteArray out;
    bool success = shell->run("set -o pipefail; netselect -D -I " + listMXurls + "| tr -s ' ' | sed 's/^ //' | cut -d' ' -f2", out);
    qDebug() << listMXurls;
    qDebug() << "FASTEST " << success << out;
    progress->hide();
    if (success && !out.isEmpty()) {
        displaySelected(out);
        on_buttonOk_clicked();
    } else {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not detect fastest repo."));
    }
}

//void MainWindow::on_pushRedirector_clicked()
//{
//    replaceDebianRepos("https://deb.debian.org/debian/");
//    refresh();
//}

void MainWindow::on_lineSearch_textChanged(const QString &arg1)
{
    displayMXRepos(repos, arg1);
}

void MainWindow::on_pb_restoreSources_clicked()
{
    QString mx_version = shell->getCmdOut("grep -oP '(?<=DISTRIB_RELEASE=).*' /etc/lsb-release").left(2);

    if (mx_version.toInt() < 15) {
        QMessageBox::critical(this, tr("Error"),
                              tr("MX version not detected or out of range: ") + mx_version);
        return;
    }

    // create temp folder
    QString path = shell->getCmdOut("mktemp -d /tmp/mx-sources.XXXXXX");
    // download source files from
    QString cmd = QString("wget -q https://github.com/mx-linux/MX-%1_sources/archive/master.zip -P %2").arg(mx_version).arg(path);
    if (!shell->run(cmd.toUtf8())) {
        QMessageBox::critical(this, tr("Error"),
                              tr("Could not download original APT files."));
        return;
    }
    // extract master.zip to temp folder
    cmd = QString("unzip -q %1/master.zip -d %1/").arg(path);
    system(cmd.toUtf8());
    // move the files from the temporary directory to /etc/apt/sources.list.d/
    cmd = QString("mv -b %1/MX-*_sources-master/* /etc/apt/sources.list.d/").arg(path);
    system(cmd.toUtf8());
    // delete temp folder
    cmd = QString("rm -rf %1").arg(path);
    system(cmd.toUtf8());

    // for 64-bit OS check if user wants AHS repo
    if (mx_version.toInt() >= 19 && shell->getCmdOut("uname -m", true) == "x86_64") {
        if (QMessageBox::Yes == QMessageBox::question(this, tr("Enabling AHS"),
                              tr("Do you use AHS (Advanced Hardware Stack) repo?"))) {
            shell->run("sed -i '/^\\s*#*\\s*deb.*ahs\\s*/s/^#*\\s*//' /etc/apt/sources.list.d/mx.list", true);
        }
    }

    refresh();
    QMessageBox::information(this, tr("Success"),
                             tr("Original APT sources have been restored to the release status. User added source files in /etc/apt/sources.list.d/ have not been touched.") + "\n\n" +
                             tr("Your new selection will take effect the next time sources are updated."));
}
