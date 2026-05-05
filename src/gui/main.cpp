#include <QApplication>
#include <QMainWindow>
#include <QLabel>
#include <QVBoxLayout>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    // 主窗口
    QMainWindow w;
    w.setWindowTitle("Qt GUI 程序");
    w.resize(400, 200);

    // 布局
    QWidget *central = new QWidget(&w);
    QVBoxLayout *layout = new QVBoxLayout(central);
    QLabel *label = new QLabel("✅ Qt GUI 运行成功！\nQt 版本: " QT_VERSION_STR);
    label->setAlignment(Qt::AlignCenter);
    layout->addWidget(label);

    w.setCentralWidget(central);
    w.show();

    return a.exec();
}