#pragma once

#include <vector>
#include <array>

// ANCHOR: XorTrie
struct XorTrie {
    std::vector<std::array<int, 2>> ch;
    int tot = 1;

    XorTrie(int n) : ch(n * 32) {}

    void insert(int x) {
        for (int i = 30, u = 1; i >= 0; i--) {
            int c = (x >> i) & 1;
            if (not ch[u][c]) {
                ch[u][c] = ++tot;
            }
            u = ch[u][c];
        }
    }

    int query(int x) {
        int res = 0;
        for (int i = 30, u = 1; i >= 0; i--) {
            int c = (x >> i) & 1;
            if (ch[u][c ^ 1]) {
                u = ch[u][c ^ 1];
                res |= (1 << i);
            } else {
                u = ch[u][c];
            }
        }
        return res;
    }
};
// ANCHOR_END: XorTrie
