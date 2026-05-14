#ifndef MYCLP_LIB_H
#define MYCLP_LIB_H

// 对外接口：运行CLP简单线性规划测试，返回结果字符串
extern "C" char* runClpTest();
// 释放内存（必须调用，防止泄漏）
extern "C" void freeString(char* str);

#endif