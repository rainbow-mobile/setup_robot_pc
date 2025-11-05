#include "mainwindow.h"
#include <QApplication>
#include <QMessageBox>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QDebug>
#include <QTextStream>
#include <QIODevice>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , process(nullptr)
    , isInstalled(false)
    , isRunning(false)
{
    // AppImage 실행 디렉토리 찾기
    QString appPath = QApplication::applicationFilePath();
    QFileInfo appInfo(appPath);
    QDir appDir = appInfo.absoluteDir();
    
    // AppImage 실행 시 내부 디렉토리 사용
    if (appPath.contains(".AppImage"))
    {
        // AppImage 내부 경로: ~/.local/share/docker_manager_appimage 또는 실행 파일 위치
        QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
        installDir = homeDir + "/.local/share/docker_manager_appimage";
        scriptDir = installDir + "/scripts";
    }
    else
    {
        // 개발 모드: 실행 파일과 같은 디렉토리
        installDir = appDir.absolutePath() + "/../install";
        scriptDir = appDir.absolutePath() + "/../scripts";
    }
    
    QDir().mkpath(installDir);
    QDir().mkpath(scriptDir);
    
    setupUI();
    
    // 초기 상태 확인
    checkDockerInstalled();
    checkDockerImage();
    
    process = new QProcess(this);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &MainWindow::onProcessFinished);
    connect(process, &QProcess::readyReadStandardOutput,
            this, &MainWindow::onProcessReadyRead);
    connect(process, &QProcess::readyReadStandardError,
            this, &MainWindow::onProcessReadyRead);
}

MainWindow::~MainWindow()
{
    if (process && process->state() == QProcess::Running)
    {
        process->kill();
        process->waitForFinished();
    }
}

void MainWindow::setupUI()
{
    setWindowTitle("Docker SLAMNAV2 Manager");
    setMinimumSize(800, 600);
    
    QWidget *centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);
    
    QVBoxLayout *mainLayout = new QVBoxLayout(centralWidget);
    
    // 버튼 영역
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    
    installButton = new QPushButton("Install", this);
    removeButton = new QPushButton("Remove", this);
    runButton = new QPushButton("Run", this);
    runButton->setEnabled(false);
    saveButton = new QPushButton("Save", this);
    saveButton->setEnabled(false);
    exitButton = new QPushButton("Exit", this);
    
    buttonLayout->addWidget(installButton);
    buttonLayout->addWidget(removeButton);
    buttonLayout->addWidget(runButton);
    buttonLayout->addWidget(saveButton);
    buttonLayout->addWidget(exitButton);
    buttonLayout->addStretch();
    
    mainLayout->addLayout(buttonLayout);
    
    // Run 옵션 영역
    setupRunOptions();
    mainLayout->addWidget(runOptionsGroup);
    
    // 로그 영역
    QLabel *logLabel = new QLabel("Log:", this);
    mainLayout->addWidget(logLabel);
    
    logText = new QTextEdit(this);
    logText->setReadOnly(true);
    logText->setMaximumHeight(200);
    mainLayout->addWidget(logText);
    
    // 시그널 연결
    connect(installButton, &QPushButton::clicked, this, &MainWindow::onInstallClicked);
    connect(removeButton, &QPushButton::clicked, this, &MainWindow::onRemoveClicked);
    connect(runButton, &QPushButton::clicked, this, &MainWindow::onRunClicked);
    connect(saveButton, &QPushButton::clicked, this, &MainWindow::onSaveClicked);
    connect(exitButton, &QPushButton::clicked, this, &MainWindow::onExitClicked);
    
    appendLog("Docker SLAMNAV2 Manager 시작됨");
    
    // Docker 설치 확인 후 이미지 목록 새로고침
    if (checkDockerInstalled())
    {
        refreshDockerImages();
    }
}

void MainWindow::setupRunOptions()
{
    runOptionsGroup = new QGroupBox("Run Options", this);
    QVBoxLayout *optionsLayout = new QVBoxLayout(runOptionsGroup);
    
    enableGuiCheckbox = new QCheckBox("Enable GUI (X11 forwarding)", this);
    enableGuiCheckbox->setChecked(true);
    optionsLayout->addWidget(enableGuiCheckbox);
    
    enableVolumeCheckbox = new QCheckBox("Mount Volume", this);
    optionsLayout->addWidget(enableVolumeCheckbox);
    
    QHBoxLayout *volumeLayout = new QHBoxLayout();
    volumeLayout->addWidget(new QLabel("Host Path:", this));
    volumeHostPath = new QLineEdit("/home/rainbow/docker_logs", this);
    volumeLayout->addWidget(volumeHostPath);
    volumeLayout->addWidget(new QLabel("Container Path:", this));
    volumeContainerPath = new QLineEdit("/home/rainbow/slamnav2/logs", this);
    volumeLayout->addWidget(volumeContainerPath);
    optionsLayout->addLayout(volumeLayout);
    
    // Docker 이미지 선택
    QHBoxLayout *imageLayout = new QHBoxLayout();
    imageLayout->addWidget(new QLabel("Docker Image:", this));
    imageComboBox = new QComboBox(this);
    imageComboBox->setEditable(true);  // 직접 입력도 가능하도록
    imageComboBox->setInsertPolicy(QComboBox::NoInsert);
    imageComboBox->lineEdit()->setPlaceholderText("rb_slamnav2_image_gui:latest");
    imageLayout->addWidget(imageComboBox);
    
    refreshImagesButton = new QPushButton("새로고침", this);
    refreshImagesButton->setMaximumWidth(80);
    imageLayout->addWidget(refreshImagesButton);
    
    loadImageButton = new QPushButton("불러오기", this);
    loadImageButton->setMaximumWidth(80);
    imageLayout->addWidget(loadImageButton);
    
    optionsLayout->addLayout(imageLayout);
    
    // 이미지 선택 시 시그널 연결
    connect(refreshImagesButton, &QPushButton::clicked, this, &MainWindow::onRefreshImagesClicked);
    connect(loadImageButton, &QPushButton::clicked, this, &MainWindow::onLoadImageClicked);
    connect(imageComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged), 
            this, &MainWindow::onImageSelected);
    
    QHBoxLayout *containerLayout = new QHBoxLayout();
    containerLayout->addWidget(new QLabel("Container Name:", this));
    containerNameEdit = new QLineEdit("rb_slamnav2_gui", this);
    containerLayout->addWidget(containerNameEdit);
    optionsLayout->addLayout(containerLayout);
}

bool MainWindow::checkDockerInstalled()
{
    QProcess checkProcess;
    checkProcess.start("docker", QStringList() << "--version");
    checkProcess.waitForFinished();
    
    if (checkProcess.exitCode() == 0)
    {
        appendLog("✓ Docker가 설치되어 있습니다.");
        isInstalled = true;
        enableRunButton(true);
        return true;
    }
    else
    {
        appendLog("✗ Docker가 설치되어 있지 않습니다.");
        isInstalled = false;
        enableRunButton(false);
        return false;
    }
}

bool MainWindow::checkDockerImage()
{
    if (!isInstalled) return false;
    
    QString imageName = imageComboBox->currentText();
    if (imageName.isEmpty())
        imageName = imageComboBox->lineEdit()->placeholderText();
    
    QProcess checkProcess;
    checkProcess.start("docker", QStringList() << "images" << "-q" << imageName);
    checkProcess.waitForFinished();
    
    QString output = checkProcess.readAllStandardOutput().trimmed();
    if (!output.isEmpty())
    {
        appendLog(QString("✓ Docker 이미지 '%1'가 존재합니다.").arg(imageName));
        return true;
    }
    else
    {
        appendLog(QString("✗ Docker 이미지 '%1'가 없습니다. 'Install'을 실행하세요.").arg(imageName));
        return false;
    }
}

void MainWindow::refreshDockerImages()
{
    if (!isInstalled)
    {
        appendLog("Docker가 설치되어 있지 않습니다.");
        return;
    }
    
    appendLog("Docker 이미지 목록 새로고침 중...");
    imageComboBox->clear();
    
    QProcess listProcess;
    listProcess.start("docker", QStringList() << "images" << "--format" << "{{.Repository}}:{{.Tag}}");
    listProcess.waitForFinished();
    
    QString output = listProcess.readAllStandardOutput();
    QStringList images = output.split('\n', Qt::SkipEmptyParts);
    
    if (images.isEmpty())
    {
        appendLog("설치된 Docker 이미지가 없습니다.");
        imageComboBox->addItem("(이미지 없음)");
        imageComboBox->setEnabled(false);
    }
    else
    {
        // 이미지 목록 정렬 및 중복 제거
        images.removeDuplicates();
        images.sort();
        
        for (const QString &image : images)
        {
            if (!image.isEmpty())
            {
                imageComboBox->addItem(image);
            }
        }
        
        appendLog(QString("✓ %1개의 Docker 이미지를 찾았습니다.").arg(images.size()));
        
        // 기본 이미지 선택
        int defaultIndex = imageComboBox->findText("rb_slamnav2_image_gui:latest", Qt::MatchExactly);
        if (defaultIndex >= 0)
        {
            imageComboBox->setCurrentIndex(defaultIndex);
        }
        else if (imageComboBox->count() > 0)
        {
            imageComboBox->setCurrentIndex(0);
        }
        
        imageComboBox->setEnabled(true);
    }
}

void MainWindow::onRefreshImagesClicked()
{
    refreshDockerImages();
}

void MainWindow::onLoadImageClicked()
{
    if (!isInstalled)
    {
        QMessageBox::warning(this, "오류", "Docker가 설치되어 있지 않습니다. Install을 먼저 실행하세요.");
        return;
    }
    
    // 파일 선택 대화상자
    QString fileName = QFileDialog::getOpenFileName(
        this,
        "Docker 이미지 파일 선택",
        QDir::homePath(),
        "Docker 이미지 파일 (*.tar *.tar.gz *.tar.bz2);;모든 파일 (*.*)"
    );
    
    if (fileName.isEmpty())
    {
        return;
    }
    
    QFileInfo fileInfo(fileName);
    if (!fileInfo.exists())
    {
        QMessageBox::warning(this, "오류", "선택한 파일이 존재하지 않습니다.");
        return;
    }
    
    int ret = QMessageBox::question(this, "이미지 로드", 
                                    QString("다음 파일에서 Docker 이미지를 로드하시겠습니까?\n\n%1").arg(fileName),
                                    QMessageBox::Yes | QMessageBox::No);
    if (ret != QMessageBox::Yes)
        return;
    
    appendLog(QString("=== Docker 이미지 로드 시작: %1 ===").arg(fileName));
    loadImageButton->setEnabled(false);
    refreshImagesButton->setEnabled(false);
    
    // docker load 명령 실행
    QProcess *loadProcess = new QProcess(this);
    loadProcess->setProcessChannelMode(QProcess::MergedChannels);
    
    connect(loadProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, loadProcess, fileName](int exitCode, QProcess::ExitStatus exitStatus) {
                if (exitStatus == QProcess::CrashExit)
                {
                    appendLog("오류: 이미지 로드 프로세스가 비정상 종료되었습니다.");
                }
                else
                {
                    if (exitCode == 0)
                    {
                        appendLog("✓ Docker 이미지 로드가 성공적으로 완료되었습니다.");
                        // 이미지 목록 새로고침
                        refreshDockerImages();
                    }
                    else
                    {
                        appendLog(QString("✗ Docker 이미지 로드가 실패했습니다. (종료 코드: %1)").arg(exitCode));
                    }
                }
                
                loadImageButton->setEnabled(true);
                refreshImagesButton->setEnabled(true);
                loadProcess->deleteLater();
            });
    
    connect(loadProcess, &QProcess::readyReadStandardOutput,
            [this, loadProcess]() {
                QString output = loadProcess->readAllStandardOutput();
                if (!output.isEmpty())
                    appendLog(output.trimmed());
            });
    
    connect(loadProcess, &QProcess::readyReadStandardError,
            [this, loadProcess]() {
                QString error = loadProcess->readAllStandardError();
                if (!error.isEmpty())
                    appendLog("ERROR: " + error.trimmed());
            });
    
    appendLog(QString("docker load 명령 실행: %1").arg(fileName));
    loadProcess->start("docker", QStringList() << "load" << "-i" << fileName);
    
    if (!loadProcess->waitForStarted())
    {
        appendLog("오류: docker load 명령을 시작할 수 없습니다.");
        loadImageButton->setEnabled(true);
        refreshImagesButton->setEnabled(true);
        loadProcess->deleteLater();
    }
}

void MainWindow::onImageSelected(int index)
{
    if (index >= 0 && imageComboBox->count() > 0)
    {
        QString selectedImage = imageComboBox->itemText(index);
        if (!selectedImage.isEmpty() && selectedImage != "(이미지 없음)")
        {
            appendLog(QString("이미지 선택: %1").arg(selectedImage));
            checkDockerImage();
        }
    }
}

void MainWindow::onInstallClicked()
{
    if (isRunning)
    {
        QMessageBox::warning(this, "경고", "컨테이너가 실행 중입니다. 먼저 중지하세요.");
        return;
    }
    
    int ret = QMessageBox::question(this, "Install", 
                                    "Docker와 필요한 환경을 설치하시겠습니까?",
                                    QMessageBox::Yes | QMessageBox::No);
    if (ret != QMessageBox::Yes)
        return;
    
    appendLog("=== Install 시작 ===");
    installButton->setEnabled(false);
    
    // Docker 설치 스크립트 찾기
    QString installScript = scriptDir + "/install_docker.sh";
    
    // AppImage 내부 스크립트 경로 확인
    if (!QFileInfo::exists(installScript))
    {
        // AppImage 내부 리소스에서 찾기
        QString appPath = QApplication::applicationFilePath();
        QFileInfo appInfo(appPath);
        QDir appDir = appInfo.absoluteDir();
        
        // AppImage 실행 시: AppImage 내부 경로 또는 상대 경로
        QStringList possiblePaths = {
            appDir.absolutePath() + "/scripts/install_docker.sh",
            appDir.absolutePath() + "/../scripts/install_docker.sh",
            "/tmp/docker_manager_appimage/scripts/install_docker.sh"
        };
        
        for (const QString &path : possiblePaths)
        {
            if (QFileInfo::exists(path))
            {
                installScript = path;
                break;
            }
        }
        
        // 여전히 없으면 기본 설치 스크립트 사용 (get.docker.com)
        if (!QFileInfo::exists(installScript))
        {
            appendLog("설치 스크립트를 찾을 수 없습니다. Docker 공식 설치 방법을 사용합니다.");
            // 스크립트를 임시로 생성
            installScript = "/tmp/install_docker_temp.sh";
            QFile scriptFile(installScript);
            if (scriptFile.open(QIODevice::WriteOnly | QIODevice::Text))
            {
                QTextStream out(&scriptFile);
                out << "#!/bin/bash\n";
                out << "set -e\n";
                out << "if ! command -v docker &> /dev/null; then\n";
                out << "    echo 'Docker 설치 중...'\n";
                out << "    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh\n";
                out << "    sudo sh /tmp/get-docker.sh\n";
                out << "    rm /tmp/get-docker.sh\n";
                out << "    echo 'Docker 설치 완료'\n";
                out << "else\n";
                out << "    echo 'Docker가 이미 설치되어 있습니다.'\n";
                out << "fi\n";
                scriptFile.close();
                QFile::setPermissions(installScript, QFile::ReadUser | QFile::WriteUser | QFile::ExeUser);
            }
        }
    }
    
    appendLog(QString("스크립트 실행: %1").arg(installScript));
    process->start("bash", QStringList() << installScript);
}

void MainWindow::onRemoveClicked()
{
    int ret = QMessageBox::question(this, "Remove", 
                                    "설치된 모든 항목(Docker, 이미지, 컨테이너)을 삭제하시겠습니까?",
                                    QMessageBox::Yes | QMessageBox::No);
    if (ret != QMessageBox::Yes)
        return;
    
    appendLog("=== Remove 시작 ===");
    removeButton->setEnabled(false);
    
    // 컨테이너 중지 및 삭제
    if (isRunning)
    {
        QString containerName = containerNameEdit->text();
        process->start("docker", QStringList() << "stop" << containerName);
        process->waitForFinished();
        process->start("docker", QStringList() << "rm" << containerName);
        process->waitForFinished();
    }
    
    // 제거 스크립트 찾기
    QString removeScript = scriptDir + "/remove_all.sh";
    
    // AppImage 내부 스크립트 경로 확인
    if (!QFileInfo::exists(removeScript))
    {
        QString appPath = QApplication::applicationFilePath();
        QFileInfo appInfo(appPath);
        QDir appDir = appInfo.absoluteDir();
        
        QStringList possiblePaths = {
            appDir.absolutePath() + "/scripts/remove_all.sh",
            appDir.absolutePath() + "/../scripts/remove_all.sh",
            "/tmp/docker_manager_appimage/scripts/remove_all.sh"
        };
        
        for (const QString &path : possiblePaths)
        {
            if (QFileInfo::exists(path))
            {
                removeScript = path;
                break;
            }
        }
        
        // 여전히 없으면 인라인 스크립트 생성
        if (!QFileInfo::exists(removeScript))
        {
            removeScript = "/tmp/remove_all_temp.sh";
            QFile scriptFile(removeScript);
            if (scriptFile.open(QIODevice::WriteOnly | QIODevice::Text))
            {
                QTextStream out(&scriptFile);
                out << "#!/bin/bash\n";
                out << "set -e\n";
                out << "echo '컨테이너 중지 및 삭제 중...'\n";
                out << "docker ps -aq | xargs -r docker rm -f 2>/dev/null || true\n";
                out << "echo '이미지 삭제 중...'\n";
                out << "docker images -q | xargs -r docker rmi -f 2>/dev/null || true\n";
                out << "echo '볼륨 삭제 중...'\n";
                out << "docker volume prune -f 2>/dev/null || true\n";
                out << "echo '네트워크 삭제 중...'\n";
                out << "docker network prune -f 2>/dev/null || true\n";
                out << "echo '설치 디렉토리 삭제 중...'\n";
                out << "rm -rf " << installDir << " 2>/dev/null || true\n";
                out << "echo 'Remove 완료'\n";
                scriptFile.close();
                QFile::setPermissions(removeScript, QFile::ReadUser | QFile::WriteUser | QFile::ExeUser);
            }
        }
    }
    
    appendLog(QString("스크립트 실행: %1").arg(removeScript));
    process->start("bash", QStringList() << removeScript);
}

void MainWindow::onRunClicked()
{
    if (isRunning)
    {
        int ret = QMessageBox::question(this, "중지", 
                                        "실행 중인 컨테이너를 중지하시겠습니까?",
                                        QMessageBox::Yes | QMessageBox::No);
        if (ret == QMessageBox::Yes)
        {
            QString containerName = containerNameEdit->text();
            process->start("docker", QStringList() << "stop" << containerName);
            process->waitForFinished();
            isRunning = false;
            runButton->setText("Run");
            saveButton->setEnabled(false);  // 컨테이너 중지 시 Save 버튼 비활성화
            appendLog("컨테이너가 중지되었습니다.");
        }
        return;
    }
    
    if (!checkDockerInstalled())
    {
        QMessageBox::warning(this, "오류", "Docker가 설치되어 있지 않습니다. Install을 먼저 실행하세요.");
        return;
    }
    
    QString imageName = imageComboBox->currentText();
    if (imageName.isEmpty() || imageName == "(이미지 없음)")
    {
        imageName = imageComboBox->lineEdit()->text();
        if (imageName.isEmpty())
        {
            imageName = imageComboBox->lineEdit()->placeholderText();
        }
    }
    
    if (imageName.isEmpty())
    {
        QMessageBox::warning(this, "오류", "Docker 이미지를 선택하거나 입력하세요.");
        return;
    }
    
    QString containerName = containerNameEdit->text();
    
    appendLog(QString("=== Docker 컨테이너 실행 시작: %1 ===").arg(containerName));
    runButton->setEnabled(false);
    
    // Docker run 명령 구성
    QStringList dockerArgs;
    dockerArgs << "run" << "-it" << "--name" << containerName;
    
    // GUI 옵션
    if (enableGuiCheckbox->isChecked())
    {
        QString display = QString::fromLocal8Bit(qgetenv("DISPLAY"));
        if (display.isEmpty())
            display = ":0";
        dockerArgs << "-e" << QString("DISPLAY=%1").arg(display);
        dockerArgs << "-e" << "QT_X11_NO_MITSHM=1";
        dockerArgs << "-v" << "/tmp/.X11-unix:/tmp/.X11-unix";
    }
    
    // 볼륨 마운트
    if (enableVolumeCheckbox->isChecked())
    {
        QString hostPath = volumeHostPath->text();
        QString containerPath = volumeContainerPath->text();
        dockerArgs << "-v" << QString("%1:%2").arg(hostPath, containerPath);
    }
    
    dockerArgs << imageName;
    
    appendLog(QString("명령: docker %1").arg(dockerArgs.join(" ")));
    
    process->start("docker", dockerArgs);
    isRunning = true;
    runButton->setText("Stop");
    runButton->setEnabled(true);
    saveButton->setEnabled(true);  // 컨테이너 실행 중이면 Save 버튼 활성화
}

void MainWindow::onSaveClicked()
{
    if (!isInstalled)
    {
        QMessageBox::warning(this, "오류", "Docker가 설치되어 있지 않습니다.");
        return;
    }
    
    QString containerName = containerNameEdit->text();
    
    // 컨테이너가 실행 중인지 확인
    QProcess checkProcess;
    checkProcess.start("docker", QStringList() << "ps" << "-a" << "--filter" << QString("name=%1").arg(containerName) << "--format" << "{{.Names}}");
    checkProcess.waitForFinished();
    
    QString containerStatus = checkProcess.readAllStandardOutput().trimmed();
    if (containerStatus.isEmpty() || !containerStatus.contains(containerName))
    {
        QMessageBox::warning(this, "오류", 
                           QString("컨테이너 '%1'를 찾을 수 없습니다.\n먼저 컨테이너를 실행하세요.").arg(containerName));
        return;
    }
    
    // 저장할 파일 경로 선택
    QString defaultFileName = QString("%1_%2.tar")
        .arg(containerName)
        .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));
    
    QString fileName = QFileDialog::getSaveFileName(
        this,
        "Docker 이미지 저장",
        QDir::homePath() + "/" + defaultFileName,
        "Docker 이미지 파일 (*.tar);;압축 파일 (*.tar.gz);;모든 파일 (*.*)"
    );
    
    if (fileName.isEmpty())
    {
        return;
    }
    
    // 파일 확장자 확인 및 추가
    QFileInfo fileInfo(fileName);
    QString suffix = fileInfo.suffix().toLower();
    if (suffix != "tar" && suffix != "gz")
    {
        fileName += ".tar";
    }
    
    int ret = QMessageBox::question(this, "이미지 저장", 
                                    QString("컨테이너 '%1'를 이미지로 저장하시겠습니까?\n\n저장 경로: %2").arg(containerName, fileName),
                                    QMessageBox::Yes | QMessageBox::No);
    if (ret != QMessageBox::Yes)
        return;
    
    appendLog(QString("=== Docker 컨테이너 저장 시작: %1 ===").arg(containerName));
    saveButton->setEnabled(false);
    runButton->setEnabled(false);
    
    // 1단계: 컨테이너를 이미지로 커밋
    QString commitImageName = QString("%1_commit:%2")
        .arg(containerName)
        .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));
    
    appendLog(QString("컨테이너를 이미지로 커밋 중: %1").arg(commitImageName));
    
    QProcess *commitProcess = new QProcess(this);
    commitProcess->setProcessChannelMode(QProcess::MergedChannels);
    
    connect(commitProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, commitProcess, containerName, commitImageName, fileName](int exitCode, QProcess::ExitStatus exitStatus) {
                if (exitStatus == QProcess::CrashExit)
                {
                    appendLog("오류: 커밋 프로세스가 비정상 종료되었습니다.");
                    saveButton->setEnabled(true);
                    runButton->setEnabled(true);
                    commitProcess->deleteLater();
                    return;
                }
                
                if (exitCode == 0)
                {
                    appendLog("✓ 컨테이너 커밋 완료");
                    
                    // 2단계: 이미지를 tar 파일로 저장
                    appendLog(QString("이미지를 파일로 저장 중: %1").arg(fileName));
                    
                    QProcess *saveProcess = new QProcess(this);
                    saveProcess->setProcessChannelMode(QProcess::MergedChannels);
                    
                    connect(saveProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                            [this, saveProcess, commitImageName, fileName](int exitCode, QProcess::ExitStatus exitStatus) {
                                if (exitStatus == QProcess::CrashExit)
                                {
                                    appendLog("오류: 저장 프로세스가 비정상 종료되었습니다.");
                                }
                                else
                                {
                                    if (exitCode == 0)
                                    {
                                        appendLog(QString("✓ Docker 이미지 저장 완료: %1").arg(fileName));
                                        QMessageBox::information(this, "저장 완료", 
                                                               QString("이미지가 성공적으로 저장되었습니다:\n%1").arg(fileName));
                                        
                                        // 임시 커밋 이미지 삭제
                                        QProcess *cleanupProcess = new QProcess(this);
                                        cleanupProcess->start("docker", QStringList() << "rmi" << commitImageName);
                                        cleanupProcess->waitForFinished();
                                        cleanupProcess->deleteLater();
                                    }
                                    else
                                    {
                                        appendLog(QString("✗ Docker 이미지 저장 실패 (종료 코드: %1)").arg(exitCode));
                                        QMessageBox::warning(this, "저장 실패", 
                                                           QString("이미지 저장에 실패했습니다.\n종료 코드: %1").arg(exitCode));
                                    }
                                }
                                
                                saveButton->setEnabled(true);
                                runButton->setEnabled(true);
                                saveProcess->deleteLater();
                            });
                    
                    connect(saveProcess, &QProcess::readyReadStandardOutput,
                            [this, saveProcess]() {
                                QString output = saveProcess->readAllStandardOutput();
                                if (!output.isEmpty())
                                    appendLog(output.trimmed());
                            });
                    
                    connect(saveProcess, &QProcess::readyReadStandardError,
                            [this, saveProcess]() {
                                QString error = saveProcess->readAllStandardError();
                                if (!error.isEmpty())
                                    appendLog("ERROR: " + error.trimmed());
                            });
                    
                    saveProcess->start("docker", QStringList() << "save" << "-o" << fileName << commitImageName);
                    
                    if (!saveProcess->waitForStarted())
                    {
                        appendLog("오류: docker save 명령을 시작할 수 없습니다.");
                        saveButton->setEnabled(true);
                        runButton->setEnabled(true);
                        saveProcess->deleteLater();
                    }
                }
                else
                {
                    appendLog(QString("✗ 컨테이너 커밋 실패 (종료 코드: %1)").arg(exitCode));
                    QMessageBox::warning(this, "커밋 실패", 
                                       QString("컨테이너 커밋에 실패했습니다.\n종료 코드: %1").arg(exitCode));
                    saveButton->setEnabled(true);
                    runButton->setEnabled(true);
                }
                
                commitProcess->deleteLater();
            });
    
    connect(commitProcess, &QProcess::readyReadStandardOutput,
            [this, commitProcess]() {
                QString output = commitProcess->readAllStandardOutput();
                if (!output.isEmpty())
                    appendLog(output.trimmed());
            });
    
    connect(commitProcess, &QProcess::readyReadStandardError,
            [this, commitProcess]() {
                QString error = commitProcess->readAllStandardError();
                if (!error.isEmpty())
                    appendLog("ERROR: " + error.trimmed());
            });
    
    commitProcess->start("docker", QStringList() << "commit" << containerName << commitImageName);
    
    if (!commitProcess->waitForStarted())
    {
        appendLog("오류: docker commit 명령을 시작할 수 없습니다.");
        saveButton->setEnabled(true);
        runButton->setEnabled(true);
        commitProcess->deleteLater();
    }
}

void MainWindow::onExitClicked()
{
    if (isRunning)
    {
        int ret = QMessageBox::question(this, "종료", 
                                        "실행 중인 컨테이너가 있습니다. 종료하시겠습니까?",
                                        QMessageBox::Yes | QMessageBox::No);
        if (ret == QMessageBox::Yes)
        {
            QString containerName = containerNameEdit->text();
            QProcess stopProcess;
            stopProcess.start("docker", QStringList() << "stop" << containerName);
            stopProcess.waitForFinished();
        }
    }
    
    QApplication::quit();
}

void MainWindow::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    if (exitStatus == QProcess::CrashExit)
    {
        appendLog("오류: 프로세스가 비정상 종료되었습니다.");
    }
    else
    {
        if (exitCode == 0)
        {
            appendLog("✓ 작업이 성공적으로 완료되었습니다.");
        }
        else
        {
            appendLog(QString("✗ 작업이 실패했습니다. (종료 코드: %1)").arg(exitCode));
        }
    }
    
    // 버튼 상태 복원
    installButton->setEnabled(true);
    removeButton->setEnabled(true);
    
    // 상태 재확인
    if (checkDockerInstalled())
    {
        refreshDockerImages();
    }
}

void MainWindow::onProcessReadyRead()
{
    QString output = process->readAllStandardOutput();
    QString error = process->readAllStandardError();
    
    if (!output.isEmpty())
        appendLog(output);
    if (!error.isEmpty())
        appendLog("ERROR: " + error);
}

void MainWindow::appendLog(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss");
    logText->append(QString("[%1] %2").arg(timestamp, message));
}

void MainWindow::enableRunButton(bool enabled)
{
    if (!isRunning)
    {
        runButton->setEnabled(enabled && isInstalled);
    }
}

