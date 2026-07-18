#include <iostream>
#include <utility>
#include <vector>

#include <mtf/graph/dijkstra.hpp>

int main() {
    std::vector graph(5, std::vector<std::pair<int, int>>{});
    graph[1].emplace_back(2, 5);
    graph[1].emplace_back(3, 2);
    graph[3].emplace_back(2, 1);
    graph[2].emplace_back(4, 3);
    graph[3].emplace_back(4, 10);

    const auto distance = mtf::dijkstra(graph, 4, 1);
    std::cout << distance[4] << '\n';
}
