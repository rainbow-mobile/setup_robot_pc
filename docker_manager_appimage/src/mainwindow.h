#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QPushButton>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QCheckBox>
#include <QLineEdit>
#include <QSpinBox>
#include <QLabel>
#include <QComboBox>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QFileDialog>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onInstallClicked();
    void onRemoveClicked();
    void onRunClicked();
    void onSaveClicked();
    void onExitClicked();
    void onRefreshImagesClicked();
    void onLoadImageClicked();
    void onImageSelected(int index);
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessReadyRead();

private:
    void setupUI();
    void setupRunOptions();
    bool checkDockerInstalled();
    bool checkDockerImage();
    void refreshDockerImages();
    void appendLog(const QString &message);
    void enableRunButton(bool enabled);
    
    // UI Components
    QPushButton *installButton;
    QPushButton *removeButton;
    QPushButton *runButton;
    QPushButton *saveButton;
    QPushButton *exitButton;
    QTextEdit *logText;
    
    // Run options
    QGroupBox *runOptionsGroup;
    QCheckBox *enableGuiCheckbox;
    QCheckBox *enableVolumeCheckbox;
    QLineEdit *volumeHostPath;
    QLineEdit *volumeContainerPath;
    QComboBox *imageComboBox;
    QPushButton *refreshImagesButton;
    QPushButton *loadImageButton;
    QLineEdit *containerNameEdit;
    
    // Process
    QProcess *process;
    
    // State
    bool isInstalled;
    bool isRunning;
    QString installDir;
    QString scriptDir;
};

#endif // MAINWINDOW_H

