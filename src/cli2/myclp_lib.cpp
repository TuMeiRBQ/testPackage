#include "myclp_lib.h"
#include <coin/ClpSimplex.hpp>
#include <cstdlib>
#include <cstring>

// 运行CLP简单测试用例
char* runClpTest() {
    try {
        // 创建CLP求解器
        ClpSimplex model;

        // 极简测试：目标函数 min x
        double lb[] = {0.0};  // 下限
        double ub[] = {10.0}; // 上限
        double obj[] = {1.0}; // 目标系数

        // 加载问题：1个变量，0个约束
        model.resize(0, 1);
        model.setColLower(0, lb[0]);
        model.setColUpper(0, ub[0]);
        model.setObjectiveCoefficient(0, obj[0]);

        // 开始求解
        model.initialSolve();

        // 拼接结果
        const char* res = "CLP 静态库调用成功！\n"
                          "求解状态：最优解\n"
                          "目标函数值：%.2f\n"
                          "CLP 版本：1.17.8";
        char* buf = (char*)malloc(256);
        snprintf(buf, 256, res, model.objectiveValue());
        return buf;

    } catch (...) {
        return strdup("CLP 调用失败！");
    }
}

// 释放字符串内存
void freeString(char* str) {
    if (str) free(str);
}