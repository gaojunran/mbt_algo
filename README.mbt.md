# gaojunran/mbt_algo

用 moonbit 语言练习算法。

每个源码文件夹中的 `GUIDE.md` 是由 LLM 生成的指导文档，使用如下的提示词生成：

```
我现在想学习手写 binary search tree，我希望你给我列出大概思路（需要实现什么，用什么实现）和注意事项，但不要教我具体如何实现。

输出到 `src/binary_search_tree/GUIDE.md` 中。
```

有些文件夹中有 `guides/`，是用 html 格式画的动画，方便我来学习算法的动态过程。提示词示例：

```
帮我做个 html 以动画的形式形象演示这几步。（引用 `GUIDE.md` 中不理解的部分）放到 src/red_black_tree/guides 这里。
```

## 目录（暂定）

- `binary_search_tree`
- `heap`
- `huffman_tree`
- `red_black_tree`
- `avl_tree`
- `spanning_tree`
- `single_source_shortest_paths`
- `kmp_algo`

## 有用的资源

1. [HyperSnips](https://marketplace.visualstudio.com/items?itemName=draivin.hsnips) - VSCode 插件，用于快速替换代码片段。对于手写代码时的重复结构很有帮助。
