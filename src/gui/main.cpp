#include <QApplication>
#include <QMainWindow>
#include <QLabel>
#include <QVBoxLayout>
#include "myclp_lib.h"  // 导入自定义静态库

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    // 主窗口
    QMainWindow w;
    w.setWindowTitle("Qt GUI + CLP 静态库测试");
    w.resize(500, 300);

    // 中央部件 + 布局
    QWidget *central = new QWidget(&w);
    QVBoxLayout *layout = new QVBoxLayout(central);

    // ========== 调用 CLP 静态库 ==========
    char* clp_result = runClpTest();
    QString info = QString("✅ Qt GUI 运行成功！\n")
                   + QString("Qt 版本: " QT_VERSION_STR "\n\n")
                   + QString("📦 CLP 静态库测试结果：\n")
                   + QString(clp_result);
    freeString(clp_result); // 释放内存

    // 显示结果
    QLabel *label = new QLabel(info);
    label->setAlignment(Qt::AlignCenter);
    layout->addWidget(label);

    w.setCentralWidget(central);
    w.show();

    return a.exec();
}