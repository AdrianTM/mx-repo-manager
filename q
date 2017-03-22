[1mdiff --git a/debian/changelog b/debian/changelog[m
[1mindex 291d389..3e06610 100644[m
[1m--- a/debian/changelog[m
[1m+++ b/debian/changelog[m
[36m@@ -1,3 +1,9 @@[m
[32m+[m[32mmx-repo-manager (17.3mx16) mx; urgency=medium[m
[32m+[m
[32m+[m[32m  * select fastest Debian repo[m
[32m+[m
[32m+[m[32m -- Adrian <adrian@mxlinux.org>  Wed, 22 Mar 2017 16:47:13 -0400[m
[32m+[m
 mx-repo-manager (17.1mx16+1) mx; urgency=medium[m
 [m
   * added se repo, renamed fr, de repos[m
[1mdiff --git a/debian/control b/debian/control[m
[1mindex afca552..7c05bf3 100644[m
[1m--- a/debian/control[m
[1m+++ b/debian/control[m
[36m@@ -9,6 +9,6 @@[m [mVcs-Git: git://github.com/AdrianTM/mx-repo-manager[m
 [m
 Package: mx-repo-manager[m
 Architecture: any[m
[31m-Depends: ${misc:Depends}, ${shlibs:Depends}, mx-viewer[m
[32m+[m[32mDepends: ${misc:Depends}, ${shlibs:Depends}, mx-viewer, netselect-apt, menu, wget[m
 Description: MX Repo Manager[m
  MX Repo Manager is a tool used for choosing the default APT repository for MX Linux[m
[1mdiff --git a/mxrepomanager.cpp b/mxrepomanager.cpp[m
[1mindex a86a59e..561b725 100644[m
[1m--- a/mxrepomanager.cpp[m
[1m+++ b/mxrepomanager.cpp[m
[36m@@ -69,6 +69,29 @@[m [mvoid mxrepomanager::refresh()[m
     displayMXRepos(readMXRepos());[m
     displayCurrent(getCurrentRepo());[m
     displayAllRepos(listAptFiles());[m
[32m+[m[32m    QApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m// replace default Debian repos[m
[32m+[m[32mvoid mxrepomanager::replaceDebianRepos(QString url)[m
[32m+[m[32m{[m
[32m+[m[32m    QStringList files;[m
[32m+[m[32m    QString cmd;[m
[32m+[m
[32m+[m[32m    // Debian list files that are present by default in MX[m
[32m+[m[32m    files << "/etc/apt/sources.list.d/debian.list" << "/etc/apt/sources.list.d/debian-stable-updates.list";[m
[32m+[m[32m    foreach(QString file, files) {[m
[32m+[m[32m        // backup file[m
[32m+[m[32m        cmd = "cp " + file + " " + file + ".$(date +%s)";[m
[32m+[m[32m        system(cmd.toUtf8());[m
[32m+[m[32m        cmd = "sed -i 's;deb\\s.*/debian/;deb " + url + ";' " + file ; // replace deb lines in file[m
[32m+[m[32m        system(cmd.toUtf8());[m
[32m+[m[32m        cmd = "sed -i 's;deb-src\\s.*/debian/;deb-src " + url + ";' " + file; // replace deb-src lines in file[m
[32m+[m[32m        system(cmd.toUtf8());[m
[32m+[m[32m    }[m
[32m+[m[32m    QApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));[m
[32m+[m[32m    QMessageBox::information(this, tr("Success"),[m
[32m+[m[32m                             tr("Your new selection will take effect the next time sources are updated."));[m
 }[m
 [m
 [m
[36m@@ -121,42 +144,65 @@[m [mvoid mxrepomanager::displayMXRepos(QStringList repos)[m
 void mxrepomanager::displayAllRepos(QFileInfoList apt_files)[m
 {[m
     ui->treeWidget->clear();[m
[32m+[m[32m    ui->treeWidgetDeb->clear();[m
     ui->treeWidget->blockSignals(true);[m
[32m+[m[32m    ui->treeWidgetDeb->blockSignals(true);[m
[32m+[m
     QStringList columnNames;[m
     columnNames << tr("Lists") << tr("Sources (checked sources are enabled)");[m
     ui->treeWidget->setHeaderLabels(columnNames);[m
[32m+[m[32m    ui->treeWidgetDeb->setHeaderLabels(columnNames);[m
[32m+[m
     QTreeWidgetItem *topLevelItem;[m
[32m+[m[32m    QTreeWidgetItem *topLevelItemDeb;[m
     QFileInfo file_info;[m
     foreach (file_info, apt_files) {[m
         QString file_name = file_info.fileName();[m
         QString file = file_info.absoluteFilePath();[m
         topLevelItem = new QTreeWidgetItem;[m
         topLevelItem->setText(0, file_name);[m
[32m+[m[32m        topLevelItemDeb = new QTreeWidgetItem;[m
[32m+[m[32m        topLevelItemDeb->setText(0, file_name);[m
         ui->treeWidget->addTopLevelItem(topLevelItem);[m
[32m+[m[32m        if (file_name.contains("debian")) {[m
[32m+[m[32m            ui->treeWidgetDeb->addTopLevelItem(topLevelItemDeb);[m
[32m+[m[32m        }[m
         // topLevelItem look[m
         topLevelItem->setForeground(0, QBrush(Qt::darkGreen));[m
[32m+[m[32m        topLevelItemDeb->setForeground(0, QBrush(Qt::darkGreen));[m
         topLevelItem->setIcon(0, QIcon("/usr/share/mx-repo-manager/icons/folder.png"));[m
[32m+[m[32m        topLevelItemDeb->setIcon(0, QIcon("/usr/share/mx-repo-manager/icons/folder.png"));[m
         // load file entries[m
         QStringList entries = loadAptFile(file);[m
         QString item;[m
         foreach (item, entries) {[m
             // add entries as childItem to treeWidget[m
             QTreeWidgetItem *childItem = new QTreeWidgetItem(topLevelItem);[m
[32m+[m[32m            QTreeWidgetItem *childItemDeb = new QTreeWidgetItem(topLevelItemDeb);[m
             childItem->setText(1, item);[m
[32m+[m[32m            childItemDeb->setText(1, item);[m
             // add checkboxes[m
             childItem->setFlags(childItem->flags() | Qt::ItemIsUserCheckable);[m
[32m+[m[32m            childItemDeb->setFlags(childItem->flags() | Qt::ItemIsUserCheckable);[m
             if (item.startsWith("#")) {[m
                 childItem->setCheckState(1, Qt::Unchecked);[m
[32m+[m[32m                childItemDeb->setCheckState(1, Qt::Unchecked);[m
             } else {[m
                 childItem->setCheckState(1, Qt::Checked);[m
[32m+[m[32m                childItemDeb->setCheckState(1, Qt::Checked);[m
             }[m
         }[m
     }[m
     for (int i = 0; i < ui->treeWidget->columnCount(); i++) {[m
         ui->treeWidget->resizeColumnToContents(i);[m
     }[m
[32m+[m[32m    for (int i = 0; i < ui->treeWidgetDeb->columnCount(); i++) {[m
[32m+[m[32m        ui->treeWidgetDeb->resizeColumnToContents(i);[m
[32m+[m[32m    }[m
     ui->treeWidget->expandAll();[m
[31m-    ui->treeWidget->blockSignals(false);[m
[32m+[m[32m    ui->treeWidgetDeb->expandAll();[m
[32m+[m[32m    ui->treeWidget->blockSignals(false);[m[41m    [m
[32m+[m[32m    ui->treeWidgetDeb->blockSignals(false);[m
 }[m
 [m
 QStringList mxrepomanager::loadAptFile(QString file)[m
[36m@@ -309,6 +355,32 @@[m [mvoid mxrepomanager::on_treeWidget_itemChanged(QTreeWidgetItem * item, int column[m
     ui->treeWidget->blockSignals(false);[m
 }[m
 [m
[32m+[m[32mvoid mxrepomanager::on_treeWidgetDeb_itemChanged(QTreeWidgetItem *item, int column)[m
[32m+[m[32m{[m
[32m+[m[32m    ui->treeWidgetDeb->blockSignals(true);[m
[32m+[m[32m    QFile file;[m
[32m+[m[32m    QString new_text;[m
[32m+[m[32m    QString file_name = item->parent()->text(0);[m
[32m+[m[32m    QString text = item->text(column);[m
[32m+[m[32m    QStringList changes;[m
[32m+[m[32m    if (file_name == "sources.list") {[m
[32m+[m[32m        file.setFileName("/etc/apt/" + file_name);[m
[32m+[m[32m    } else {[m
[32m+[m[32m        file.setFileName("/etc/apt/sources.list.d/" + file_name);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (item->checkState(column) == Qt::Checked) {[m
[32m+[m[32m        new_text = text;[m
[32m+[m[32m        new_text.remove(QRegExp("#\\s*"));[m
[32m+[m[32m        item->setText(column, new_text);[m
[32m+[m[32m    } else {[m
[32m+[m[32m        new_text = "# " + text;[m
[32m+[m[32m        item->setText(column, new_text);[m
[32m+[m[32m    }[m
[32m+[m[32m    changes << text << new_text << file.fileName();[m
[32m+[m[32m    queued_changes << changes;[m
[32m+[m[32m    ui->treeWidgetDeb->blockSignals(false);[m
[32m+[m[32m}[m
[32m+[m
 void mxrepomanager::on_tabWidget_currentChanged()[m
 {[m
     if (ui->tabWidget->currentWidget() == ui->tabMX) {[m
[36m@@ -332,3 +404,24 @@[m [mvoid mxrepomanager::buildFlags()[m
     flags.insert("USA, Los Angeles", QIcon("/usr/share/mx-repo-manager/icons/us.png"));[m
     flags.insert("USA, Utah", QIcon("/usr/share/mx-repo-manager/icons/us.png"));    [m
 }[m
[32m+[m
[32m+[m[32m// detect fastest Debian repo[m
[32m+[m[32mvoid mxrepomanager::on_pushFastestDebian_clicked()[m
[32m+[m[32m{[m
[32m+[m[32m    QString repo;[m
[32m+[m
[32m+[m[32m    QApplication::setOverrideCursor(QCursor(Qt::WaitCursor));[m
[32m+[m[32m    this->blockSignals(true);[m
[32m+[m[32m    runCmd("netselect-apt jessie -o /tmp/mx-repo-manager-debian.list");[m
[32m+[m[32m    Output out = runCmd("grep -m 1 deb /tmp/mx-repo-manager-debian.list | cut -d ' ' -f 2");[m
[32m+[m[32m    if (out.exit_code == 0) {[m
[32m+[m[32m        repo = out.str;[m
[32m+[m[32m    }[m
[32m+[m[32m    // doublecheck if repo is valid[m
[32m+[m[32m    out = runCmd("wget --spider " + repo);[m
[32m+[m[32m    this->blockSignals(false);[m
[32m+[m[32m    if (out.exit_code == 0) {[m
[32m+[m[32m        replaceDebianRepos(repo);[m
[32m+[m[32m    }[m
[32m+[m[32m    refresh();[m
[32m+[m[32m}[m
[1mdiff --git a/mxrepomanager.h b/mxrepomanager.h[m
[1mindex 7f7d62e..01a8baf 100644[m
[1m--- a/mxrepomanager.h[m
[1m+++ b/mxrepomanager.h[m
[36m@@ -57,6 +57,7 @@[m [mpublic:[m
     void displayAllRepos(QFileInfoList apt_files);[m
     void displayCurrent(QString repo);[m
     void refresh();[m
[32m+[m[32m    void replaceDebianRepos(QString url);[m
     void replaceRepos(QString url);[m
     void setSelected();[m
     Output runCmd(QString cmd);[m
[36m@@ -72,7 +73,9 @@[m [mprivate slots:[m
     void on_buttonAbout_clicked();[m
     void on_buttonHelp_clicked();[m
     void on_treeWidget_itemChanged(QTreeWidgetItem * item, int column);[m
[32m+[m[32m    void on_treeWidgetDeb_itemChanged(QTreeWidgetItem * item, int column);[m
     void on_tabWidget_currentChanged();[m
[32m+[m[32m    void on_pushFastestDebian_clicked();[m
 [m
 private:[m
     Ui::mxrepomanager *ui;[m
[1mdiff --git a/mxrepomanager.ui b/mxrepomanager.ui[m
[1mindex ed9fb00..3a49b51 100644[m
[1m--- a/mxrepomanager.ui[m
[1m+++ b/mxrepomanager.ui[m
[36m@@ -52,11 +52,11 @@[m
    <item>[m
     <widget class="QTabWidget" name="tabWidget">[m
      <property name="currentIndex">[m
[31m-      <number>0</number>[m
[32m+[m[32m      <number>1</number>[m
      </property>[m
      <widget class="QWidget" name="tabMX">[m
       <attribute name="title">[m
[31m-       <string>Default repo</string>[m
[32m+[m[32m       <string>Default MX repo</string>[m
       </attribute>[m
       <layout class="QVBoxLayout" name="verticalLayout_2">[m
        <item>[m
[36m@@ -137,6 +137,55 @@[m
        </item>[m
       </layout>[m
      </widget>[m
[32m+[m[32m     <widget class="QWidget" name="tabDebian">[m
[32m+[m[32m      <attribute name="title">[m
[32m+[m[32m       <string>Debian repos</string>[m
[32m+[m[32m      </attribute>[m
[32m+[m[32m      <layout class="QGridLayout" name="gridLayout">[m
[32m+[m[32m       <item row="3" column="0">[m
[32m+[m[32m        <spacer name="horizontalSpacer">[m
[32m+[m[32m         <property name="orientation">[m
[32m+[m[32m          <enum>Qt::Horizontal</enum>[m
[32m+[m[32m         </property>[m
[32m+[m[32m         <property name="sizeHint" stdset="0">[m
[32m+[m[32m          <size>[m
[32m+[m[32m           <width>40</width>[m
[32m+[m[32m           <height>20</height>[m
[32m+[m[32m          </size>[m
[32m+[m[32m         </property>[m
[32m+[m[32m        </spacer>[m
[32m+[m[32m       </item>[m
[32m+[m[32m       <item row="3" column="1">[m
[32m+[m[32m        <widget class="QPushButton" name="pushFastestDebian">[m
[32m+[m[32m         <property name="text">[m
[32m+[m[32m          <string>Select fastest Debian repos for me</string>[m
[32m+[m[32m         </property>[m
[32m+[m[32m        </widget>[m
[32m+[m[32m       </item>[m
[32m+[m[32m       <item row="3" column="2">[m
[32m+[m[32m        <spacer name="horizontalSpacer_2">[m
[32m+[m[32m         <property name="orientation">[m
[32m+[m[32m          <enum>Qt::Horizontal</enum>[m
[32m+[m[32m         </property>[m
[32m+[m[32m         <property name="sizeHint" stdset="0">[m
[32m+[m[32m          <size>[m
[32m+[m[32m           <width>40</width>[m
[32m+[m[32m           <height>20</height>[m
[32m+[m[32m          </size>[m
[32m+[m[32m         </property>[m
[32m+[m[32m        </spacer>[m
[32m+[m[32m       </item>[m
[32m+[m[32m       <item row="0" column="0" colspan="3">[m
[32m+[m[32m        <widget class="QTreeWidget" name="treeWidgetDeb">[m
[32m+[m[32m         <column>[m
[32m+[m[32m          <property name="text">[m
[32m+[m[32m           <string notr="true">1</string>[m
[32m+[m[32m          </property>[m
[32m+[m[32m         </column>[m
[32m+[m[32m        </widget>[m
[32m+[m[32m       </item>[m
[32m+[m[32m      </layout>[m
[32m+[m[32m     </widget>[m
      <widget class="QWidget" name="tabAllRepos">[m
       <attribute name="title">[m
        <string>Individual sources</string>[m
[36m@@ -329,7 +378,7 @@[m
         </sizepolicy>[m
        </property>[m
        <property name="text">[m
[31m-        <string>Select</string>[m
[32m+[m[32m        <string>Apply</string>[m
        </property>[m
        <property name="icon">[m
         <iconset>[m
[1mdiff --git a/translations/mx-repo-manager_ca.ts b/translations/mx-repo-manager_ca.ts[m
[1mindex 021574d..d1f67de 100644[m
[1m--- a/translations/mx-repo-manager_ca.ts[m
[1m+++ b/translations/mx-repo-manager_ca.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Repo Manager</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Trieu el dipòsit d&apos;APT que voleu usar: </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Dipòsit per omissió </translation>[m
[32m+[m[32m        <translation type="vanished">Dipòsit per omissió </translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Fonts individuals </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Mostra l&apos;ajuda</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Ajuda </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Quant a aquesta aplicació </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Quant a...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Surt de l&apos;aplicació </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Tanca </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Selecciona</translation>[m
[32m+[m[32m        <translation type="vanished">Selecciona</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Llistes </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Fonts (les marcades són les habilitades) </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Èxit</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Aquesta tria serà efectiva la propera vegada que actualitzeu les fonts. </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>S&apos;ha produït un error</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>No s&apos;ha pogut canviar el dipòsit. </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Quant a MX Repo Manager </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versió: </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programa per triar els dipòsits d&apos;APT per omissió </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Cancel·la </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Llicència </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Trieu el dipòsit APT i les fonts que voleu usar: </translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_de.ts b/translations/mx-repo-manager_de.ts[m
[1mindex 93a89b7..2a044a2 100644[m
[1m--- a/translations/mx-repo-manager_de.ts[m
[1m+++ b/translations/mx-repo-manager_de.ts[m
[36m@@ -14,142 +14,162 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Repo Manager</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>[m
 Wählen Sie das APT-Repository, das Sie verwenden möchten:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Standard-Repository</translation>[m
[32m+[m[32m        <translation type="vanished">Standard-Repository</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Einzelquellen </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Hilfe anzeigen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Hilfe</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Infos zu diesem Programm</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Über...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Anwendung beenden</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Schließen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Auswählen</translation>[m
[32m+[m[32m        <translation type="vanished">Auswählen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Quellen (angehaktes Kästchen gleicht aktiviert)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Erfolg</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Ihre neue Auswahl wird wirksam wenn die Quellen nächstes Mal aktualisiert werden.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Fehler</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Unmöglich, das Repository zu ändern</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Über MX Repo Manager</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Version:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programm, um das Standard-Repository für APT zu wählen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Abbrechen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Lizenz</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Wählen Sie das APT-Repository und die Quellen, die Sie verwenden möchten:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_el.ts b/translations/mx-repo-manager_el.ts[m
[1mindex 239603d..f48c83f 100644[m
[1m--- a/translations/mx-repo-manager_el.ts[m
[1m+++ b/translations/mx-repo-manager_el.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Repo Manager</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Επιλέξτε την αποθήκη του APT που θέλετε να χρησιμοποιήσετε.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>repo προεπιλογής</translation>[m
[32m+[m[32m        <translation type="vanished">repo προεπιλογής</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Μεμονωμένες πηγές</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Δείτε Βοήθεια</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Βοήθεια </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Περί εφαρμογής.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Περί</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Κλείστε την εφαρμογή </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Κλείσιμο</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Επιλέξτε</translation>[m
[32m+[m[32m        <translation type="vanished">Επιλέξτε</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Κατάλογος</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Πηγές (ενεργοποιημένες ελεγχόμενες πηγές)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Επιτυχία!</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Η νέα επιλογή σας θα τεθεί σε ισχύ την επόμενη φορά που ενημερώνονται οι πηγές.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Σφάλμα</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Δεν ήταν δυνατή η αλλαγή.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Περί MX Repo Manager</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Έκδοση:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Πρόγραμμα για την επιλογή της προεπιλεγμένης αποθήκης του APT</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c)  MX Linux </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Ακύρωση</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Άδεια</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Επιλέξτε το APT repository και τις πηγές για χρήση:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_es.ts b/translations/mx-repo-manager_es.ts[m
[1mindex 9e171f9..3a64d63 100644[m
[1m--- a/translations/mx-repo-manager_es.ts[m
[1m+++ b/translations/mx-repo-manager_es.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Manejador de Repositorios</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Seleccione el repositorio APT que desea usar:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Repositorio por defecto</translation>[m
[32m+[m[32m        <translation type="vanished">Repositorio por defecto</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Recursos personales</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Mostrar la ayuda</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Ayuda</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Acerca de esta aplicación</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Acerca de...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Terminar aplicación</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Cerrar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Seleccione</translation>[m
[32m+[m[32m        <translation type="vanished">Seleccione</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listas</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Código fuente (el corregido esta activado)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Exito</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Su nueva selección será efectiva cuando se actualicen las fuentes de los repositorios.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Error</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>So se pudo cambiar el repositorio.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Acerca de MX Manejador de repositorios</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versión:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programa para escoger el repositorio APT predeterminado</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Cancelar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licencia</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Seleccione el repositorio APT y fuentes que desea utilizar:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_fr.ts b/translations/mx-repo-manager_fr.ts[m
[1mindex f3f801e..3790f55 100644[m
[1m--- a/translations/mx-repo-manager_fr.ts[m
[1m+++ b/translations/mx-repo-manager_fr.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Gestionnaire de dépôts</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Sélectionnez le dépôt APT que vous souhaitez utiliser:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Dépôt par défaut</translation>[m
[32m+[m[32m        <translation type="vanished">Dépôt par défaut</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Sources individuelles</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Afficher l&apos;aide</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Aide </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>A propos de cette application</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>A propos...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Quitter l&apos;application</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Fermer</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Sélectionner</translation>[m
[32m+[m[32m        <translation type="vanished">Sélectionner</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listes</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Sources (case cochée si déjà activée)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Succès</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Votre nouvelle sélection prendra effet la prochaine fois que les sources seront mises à jour.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Erreur</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Impossible de modifier le dépôt.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>A propos de MX Gestionnaire de dépôts</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Version: </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programme pour le choix du dépôt APT par défaut</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Annuler</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licence</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Sélectionnez le dépôt APT et les sources que vous souhaitez utiliser:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_it.ts b/translations/mx-repo-manager_it.ts[m
[1mindex adc7abf..c9e4531 100644[m
[1m--- a/translations/mx-repo-manager_it.ts[m
[1m+++ b/translations/mx-repo-manager_it.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Repo Manager</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Scegli il Repository di APT da utilizzare</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Repository di default</translation>[m
[32m+[m[32m        <translation type="vanished">Repository di default</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Fonti individuali</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Visualizza aiuto</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Aiuto</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Informazioni riguardo questa applicazione</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Info...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation> Chiudi l&apos;applicazione</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Chiudi</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Seleziona</translation>[m
[32m+[m[32m        <translation type="vanished">Seleziona</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Elenchi</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Fonti (le fonti vidimate sono abilitate)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Successo</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>La tua selezione avrà effetto col prossimo aggiornamento dei sorgenti</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Errore</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Repository non modificabile</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Informazioni su MX Repo Manager</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versione:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programma per selezionare il Repository di APT predefinito</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Annulla</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licenza</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Seleziona il repository di APT e le fonti che vuoi usare:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_ja.ts b/translations/mx-repo-manager_ja.ts[m
[1mindex ffffb83..20700ec 100644[m
[1m--- a/translations/mx-repo-manager_ja.ts[m
[1m+++ b/translations/mx-repo-manager_ja.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX リボジトリマネージャー</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>使用する APT リポジトリを選択して下さい:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>デフォルトリポジトリ</translation>[m
[32m+[m[32m        <translation type="vanished">デフォルトリポジトリ</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>個々のソース</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>ヘルプの表示</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>ヘルプ</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>このアプリケーションについて</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>About...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>アプリケーションの終了</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>閉じる</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Select</translation>[m
[32m+[m[32m        <translation type="vanished">Select</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>一覧</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>ソース (チェックが入ったソースが有効)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>完了</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>新たな選択はソースが更新された後に反映されます。</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>エラー</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>リボジトリを変更できませんでした。</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>MX レポジトリマネージャーについて</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Version: </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>デフォルト APT リポジトリを選択するプログラム</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>キャンセル</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>ライセンス</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>必要なAPTリポジトリとソースを選択して下さい:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_nl.ts b/translations/mx-repo-manager_nl.ts[m
[1mindex 5a764e9..8989392 100644[m
[1m--- a/translations/mx-repo-manager_nl.ts[m
[1m+++ b/translations/mx-repo-manager_nl.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Pakketbronbeheer</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Selecteer de APT pakketbron die u wilt gebruiken:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Standaard pakketbron</translation>[m
[32m+[m[32m        <translation type="vanished">Standaard pakketbron</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Individuele bronnen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Toon help</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Help</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Over deze toepassing</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Over...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Verlaat de applicatie</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Sluiten</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Selecteer</translation>[m
[32m+[m[32m        <translation type="vanished">Selecteer</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Lijsten</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Bronnen (aangevinkte bronnen zijn ingeschakeld)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Gelukt</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Uw nieuwe selectie zal de volgende keer dat de bronnen geupdate worden effectief worden.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Fout</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Kon de pakketbron niet wijzigen.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Over MX Pakketbronbeheer</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versie:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programma om de standaard APT pakketbron te kiezen</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Cancel</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licentie</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Selecteer de APT pakketbron en bronnen die u wilt gebruiken:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_pl.ts b/translations/mx-repo-manager_pl.ts[m
[1mindex 5b06c73..87feb49 100644[m
[1m--- a/translations/mx-repo-manager_pl.ts[m
[1m+++ b/translations/mx-repo-manager_pl.ts[m
[36m@@ -14,141 +14,153 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="59"/>[m
[31m-        <source>Default repo</source>[m
[32m+[m[32m        <source>Default MX repo</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Wyświetl pomoc</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Pomoc</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>O programie</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>O...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Zamknij apliikację</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Zamknij</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[31m-        <source>Select</source>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Sukces </translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Błąd</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Wersja:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Anuluj</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licencja</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_pt.ts b/translations/mx-repo-manager_pt.ts[m
[1mindex ccc47bd..0f40020 100644[m
[1m--- a/translations/mx-repo-manager_pt.ts[m
[1m+++ b/translations/mx-repo-manager_pt.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX_Gestor de Repositórios</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Seleccionar o repositório APT que pretende usar:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Repositório pré-definido</translation>[m
[32m+[m[32m        <translation type="vanished">Repositório pré-definido</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Origens individuais</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Mostrar a ajuda</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Ajuda</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Sobre esta aplicação</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Sobre...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Sair da aplicação</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Encerrar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Seleccionar</translation>[m
[32m+[m[32m        <translation type="vanished">Seleccionar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listas</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Origens (verifique que as origens estão activadas)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Sucesso</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>A sua nova escolha terá efeito na próxima vez que as origens forem atualizadas.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Erro</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Não foi possível alterar o repositório</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Sobre o MX_Gestor de Repositórios</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versão:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Programa para escolher o repositório APT pré-definido</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Cancelar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licença</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Seleccione o repositório APT e as origens que quer usar:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_ro.ts b/translations/mx-repo-manager_ro.ts[m
[1mindex cfb3fcf..8108022 100644[m
[1m--- a/translations/mx-repo-manager_ro.ts[m
[1m+++ b/translations/mx-repo-manager_ro.ts[m
[36m@@ -14,141 +14,153 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="59"/>[m
[31m-        <source>Default repo</source>[m
[32m+[m[32m        <source>Default MX repo</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Afișează ajutor</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Ajutor</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Informații despre program</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Despre...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Închidere</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[31m-        <source>Select</source>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Succes</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Eroare</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Versiune:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Anulează</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licență</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation type="unfinished"></translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_ru.ts b/translations/mx-repo-manager_ru.ts[m
[1mindex 10bf71f..c9855b3 100644[m
[1m--- a/translations/mx-repo-manager_ru.ts[m
[1m+++ b/translations/mx-repo-manager_ru.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Менеджер репозиториев</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Выберите APT репозиторий, который Вы хотите использовать:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Репозиторий по умолчанию</translation>[m
[32m+[m[32m        <translation type="vanished">Репозиторий по умолчанию</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Частные источники</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Показать справку</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Справка</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Об этом приложении</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>O...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Выйти из приложения</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Закрыть</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Выбор</translation>[m
[32m+[m[32m        <translation type="vanished">Выбор</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Списки</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Источники (отмеченные источники включены)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Успешно</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Ваш новый выбор вступит в силу при следующем обновлении.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Ошибка</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Не удалось изменить репозиторий.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Об  MX Менеджере репозиториев</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Версия:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Программа для выбора APT репозитория по умолчанию</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Авторское право (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Отмена</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Лицензия</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Выберите APT репозиторий и источники, которые Вы хотите использовать:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_sv.ts b/translations/mx-repo-manager_sv.ts[m
[1mindex 1c4def0..f711870 100644[m
[1m--- a/translations/mx-repo-manager_sv.ts[m
[1m+++ b/translations/mx-repo-manager_sv.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Repo Manager</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Välj det APT förråd du vill använda:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Standardförråd</translation>[m
[32m+[m[32m        <translation type="vanished">Standardförråd</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Individuella källor</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Visa hjälp</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Hjälp</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Om detta program</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Om...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Avsluta programmet</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Stäng</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Välj</translation>[m
[32m+[m[32m        <translation type="vanished">Välj</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listor</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Förråd (markerade förråd är aktiva)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Det lyckades</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Ditt nya val kommer att träda i kraft nästa gång förråden uppdateras.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Fel</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Kunde inte ändra förrådet</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>Om MX Repo Manager</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Version</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Program för att välja standard Apt förråd</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>Avbryt</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Licens</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Välj det APT-förråd och källor du vill använda:</translation>[m
     </message>[m
[1mdiff --git a/translations/mx-repo-manager_tr.ts b/translations/mx-repo-manager_tr.ts[m
[1mindex e078565..4e06aac 100644[m
[1m--- a/translations/mx-repo-manager_tr.ts[m
[1m+++ b/translations/mx-repo-manager_tr.ts[m
[36m@@ -14,141 +14,161 @@[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="17"/>[m
         <location filename="../mxrepomanager.cpp" line="41"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="281"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="327"/>[m
         <source>MX Repo Manager</source>[m
         <translation>MX Depo Yöneticisi</translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="32"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="315"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="387"/>[m
         <source>Select the APT repository that you want to use:</source>[m
         <translation>Kullanmak istediğiniz APT deposunu seçin:</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="59"/>[m
         <source>Default repo</source>[m
[31m-        <translation>Öntanımlı depo</translation>[m
[32m+[m[32m        <translation type="vanished">Öntanımlı depo</translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="59"/>[m
[32m+[m[32m        <source>Default MX repo</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
     </message>[m
     <message>[m
         <location filename="../mxrepomanager.ui" line="142"/>[m
[32m+[m[32m        <source>Debian repos</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="161"/>[m
[32m+[m[32m        <source>Select fastest Debian repos for me</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="191"/>[m
         <source>Individual sources</source>[m
         <translation>Bireysel kaynaklar</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="203"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="252"/>[m
         <source>Display help </source>[m
         <translation>Yardımı görüntüle</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="206"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="255"/>[m
         <source>Help</source>[m
         <translation>Yardım</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="213"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="262"/>[m
         <source>Alt+H</source>[m
         <translation>Alt+H</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="258"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="307"/>[m
         <source>About this application</source>[m
         <translation>Uygulama hakkında</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="261"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="310"/>[m
         <source>About...</source>[m
         <translation>Hakkında...</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="317"/>[m
         <source>Alt+B</source>[m
         <translation>Alt+B</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="284"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="333"/>[m
         <source>Quit application</source>[m
         <translation>Uygulamadan çık</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="287"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="336"/>[m
         <source>Close</source>[m
         <translation>Kapat</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="294"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="343"/>[m
         <source>Alt+N</source>[m
         <translation>Alt+N</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.ui" line="332"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.ui" line="381"/>[m
[32m+[m[32m        <source>Apply</source>[m
[32m+[m[32m        <translation type="unfinished"></translation>[m
[32m+[m[32m    </message>[m
[32m+[m[32m    <message>[m
         <source>Select</source>[m
[31m-        <translation>Seç</translation>[m
[32m+[m[32m        <translation type="vanished">Seç</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Lists</source>[m
         <translation>Listeler</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="126"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="152"/>[m
         <source>Sources (checked sources are enabled)</source>[m
         <translation>Kaynaklar ( Etkinleştirilmiş kaynaklar kontrol edildi)</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="215"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="93"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="261"/>[m
         <source>Success</source>[m
         <translation>Başarılı</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="216"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="94"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="262"/>[m
         <source>Your new selection will take effect the next time sources are updated.</source>[m
         <translation>Yeni seçiminiz, daha sonra güncellenmiş kaynakları etkileyecek.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="218"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="264"/>[m
         <source>Error</source>[m
         <translation>Hata</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="219"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="265"/>[m
         <source>Could not change the repo.</source>[m
         <translation>Depo değiştirilemedi.</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="264"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="310"/>[m
         <source>About MX Repo Manager</source>[m
         <translation>MX Depo Yöneticisi hakkında</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="265"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="311"/>[m
         <source>Version: </source>[m
         <translation>Sürüm</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="266"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="312"/>[m
         <source>Program for choosing the default APT repository</source>[m
         <translation>Öntanımlı APT seçimi için program</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="268"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="314"/>[m
         <source>Copyright (c) MX Linux</source>[m
         <translation>Copyright (c) MX Linux</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="269"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="315"/>[m
         <source>Cancel</source>[m
         <translation>İptal</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="270"/>[m
[31m-        <location filename="../mxrepomanager.cpp" line="272"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="316"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="318"/>[m
         <source>License</source>[m
         <translation>Ruhsat</translation>[m
     </message>[m
     <message>[m
[31m-        <location filename="../mxrepomanager.cpp" line="317"/>[m
[32m+[m[32m        <location filename="../mxrepomanager.cpp" line="389"/>[m
         <source>Select the APT repository and sources that you want to use:</source>[m
         <translation>Kullanmak istediğiniz kaynakları ve APT deposunu seçin:</translation>[m
     </message>[m
