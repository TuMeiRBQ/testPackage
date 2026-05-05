#include <QCoreApplication>
#include <QDebug>
#include <curl/curl.h>

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    // Qt 测试
    qDebug() << "========================";
    qDebug() << "Qt Version:" << QT_VERSION_STR;
    qDebug() << "========================";

    // 第三方动态库 libcurl 测试
    CURL *curl = curl_easy_init();
    if (curl) {
        qDebug() << "✅ libcurl 动态库加载成功！";
        qDebug() << "✅ CURL Version:" << curl_version();
        curl_easy_cleanup(curl);
    } else {
        qDebug() << "❌ 加载失败！";
    }

    return 0;
}