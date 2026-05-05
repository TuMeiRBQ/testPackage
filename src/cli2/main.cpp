#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    qDebug() << "========================";
    qDebug() << "CLI 2 | 独立控制台程序";
    qDebug() << "Qt Version:" << QT_VERSION_STR;
    qDebug() << "========================";

    return 0;
}