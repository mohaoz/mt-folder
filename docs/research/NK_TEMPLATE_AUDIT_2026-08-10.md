# `/home/mohao/nk` 模板筛选记录

日期：2026-08-10

本轮排除 `Geometry Textbook.cpp`，按“稳定接口、跨题复用、可独立检查”筛选。

## 本轮吸收

- `6/Full Alphabet.cpp`：抽出 Z 函数，并补成同时支持跨串 LCP 的 exKMP；
- `2/Hyperspace Pairing.cpp`：抽出 Gray Code 与逆变换。

## 此前已经吸收

- `3/Not Aqre 2.cpp`：矩阵快速幂；
- `1/P1967 [NOIP 2013 提高组] 货车运输.cpp`：Kruskal 重构树；
- `2/b.cpp`：线性基。

## 暂不吸收

- `3/Uphill Duel.cpp`：有提炼成通用博弈图逆推的价值，但要先确定环上局面的
  平局语义与接口；
- `1/Fish Eating.cpp`：带路径条件的在线合并树与题目语义耦合较强；
- `3/Bitmask.cpp`：维护相邻二进制位对的做法依赖具体操作和询问；
- `5/Sequence（Mex Version）.cpp`：循环检测依赖双哈希，仍有碰撞且接口不稳定；
- `5/Koishi and Function.cpp`：最小质因子分解会让现有 primitive 线性筛承担
  额外状态和职责，不合并；
- `2/Lazy Shuffling.cpp`、`6/Full Alphabet.cpp`：前驱掩码拓扑序计数属于
  状压 DP；按仓库边界，DP 不进入模板库；
- 其余文件主要是完整题解、构造、暴力核验或未完成代码，不作为模板搬运。
