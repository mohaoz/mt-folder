#import "../../template.typ": snippet, web-only

== 异或 Trie
维护非负整数可重集，支持插入、删除和查询与 `x` 异或的最大值。

- 默认考虑 `[30, 0]` 位；
- 删除前需要保证元素存在；
- 查询前需要保证集合非空；
- 单次操作复杂度均为 `O(31)`。

#let xor-trie = ```cpp
struct XorTrie {
    std::vector<std::array<int, 2>> ch;
    std::vector<int> cnt;
    int tot = 1;

    XorTrie(int n) : ch(n * 32), cnt(n * 32) {}

    void Insert(int x) {
        int u = 1;
        cnt[u]++;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            if (not ch[u][c]) {
                ch[u][c] = ++tot;
            }
            u = ch[u][c];
            cnt[u]++;
        }
    }

    void Erase(int x) {
        int u = 1;
        cnt[u]--;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            u = ch[u][c];
            cnt[u]--;
        }
    }

    auto Query(int x) {
        int res = 0;
        int u = 1;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            int v = ch[u][c ^ 1];
            if (v and cnt[v] > 0) {
                u = v;
                res |= (1 << i);
            } else {
                u = ch[u][c];
            }
        }
        return res;
    }
};
```

#snippet(xor-trie)
