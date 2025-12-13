# 线段树 (SegTree)

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）

关于初始数组 `vector<T>`：

- 若 `T` \\(\neq\\) `S`，则必须保证 `S` 存在可由 `T` 构造的构造函数。

```cpp
{{ #include ../../code/ds/segtree.hpp:SegTree }}
```
