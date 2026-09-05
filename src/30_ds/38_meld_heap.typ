#import "../../template.typ": snippet, web-only

== 可并堆
`pb_ds` 配对堆，免手写左偏树。

- 需要在 `#define int long long` 之前引入
  `<ext/pb_ds/priority_queue.hpp>`；
- 默认大根堆；需要小根堆时，把别名中的 `std::less<int>` 改为
  `std::greater<int>`；
- `push` 返回 `point_iterator` 句柄，句柄在 `join` 之后仍然有效，
  可用于 `modify(it, v)` 与 `erase(it)`；
- `a.join(b)` 把 `b` 并入 `a` 并清空 `b`，均摊 $O(1)$；
  `pop` 均摊 $O(log n)$；
- 按集合合并时常配 DSU：以 DSU 的 `sz` 决定 `join` 方向，
  堆下标始终用 `Find` 后的代表元。

#let meld-heap = ```cpp
#include <ext/pb_ds/priority_queue.hpp>

using Heap = __gnu_pbds::priority_queue<
    int, std::less<int>, __gnu_pbds::pairing_heap_tag>;

// Heap h;
// auto it = h.push(x);                 稳定句柄
// h.modify(it, v), h.erase(it);
// a.join(b);                           b 被清空
```

#snippet(meld-heap)
