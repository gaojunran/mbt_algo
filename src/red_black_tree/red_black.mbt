struct Node {
  val: Int
  mut left: Node?
  mut right: Node?
  mut color: Color
  mut parent: Node?
}

enum Color {
  Red
  Black
}

struct RedBlackTree {
  mut root: Node?
}

// 与 AVL 树不同：旋转时必须维护每个受影响节点（b, x, y）的 parent 指针
// 旋转本身不改变颜色 —— 颜色调整由 fix_insert / fix_delete 负责

fn RedBlackTree::left_rotate(self : Self, x : Node) -> Unit {
  let y = x.right.unwrap()
  x.right = y.left
  if x.right is Some(b) { b.parent = Some(x) }
  y.parent = x.parent
  match x.parent {
    Some(p) =>
      if p.left is Some(left) && left.val == x.val {
        p.left = Some(y)
      } else {
        p.right = Some(y)
      }
    None => self.root = Some(y) // x 是根节点
  }
  y.left = Some(x)
  x.parent = Some(y)
}

fn RedBlackTree::right_rotate(self : Self, y : Node) -> Unit {
  let x = y.left.unwrap()
  y.left = x.right
  if y.left is Some(b) { b.parent = Some(y) }
  x.parent = y.parent
  // 让 p 或 self.root 指向 x
  match y.parent {
    Some(p) =>
      if p.left is Some(left) && left.val == y.val {
        p.left = Some(x)
      } else {
        p.right = Some(x)
      }
    None => self.root = Some(x) // y 是根节点
  }
  x.right = Some(y)
  y.parent = Some(x)
}

// ============================================================
// 辅助函数
// ============================================================

fn Node::new(val : Int) -> Node {
  // 新节点默认红色，无父无子
  Node::{ val, left: None, right: None, color: Red, parent: None }
}

fn RedBlackTree::new() -> RedBlackTree {
  RedBlackTree::{ root: None }
}

/// 获取节点颜色，None 视为黑色（NIL 是黑色）
fn color(node : Node?) -> Color {
  match node {
    Some(n) => n.color
    None => Black
  }
}

/// 判断 node 是否是其父节点的左孩子
fn Node::is_left_child(self : Self) -> Bool {
  match self.parent {
    Some(p) => p.left is Some(left) && left.val == self.val
    None => false
  }
  // self.parent.map_or(false, p => p.left.map_or(false, left => left.val == self.val))
}

/// 判断 self 是否是给定 parent 的右孩子
fn Node::is_right_child_of(self : Self, parent : Node) -> Bool {
  parent.right is Some(right) && right.val == self.val
}

/// 获取兄弟节点
// fn sibling(node : Node) -> Node? {
//   match node.parent {
//     Some(p) => if is_left_child(node) { p.right } else { p.left }
//     None => None
//   }
// }

fn Node::grandparent(self : Self) -> Node? {
  self.parent.map_or(None, p => p.parent)
}

// ============================================================
// 插入
// ============================================================

fn RedBlackTree::insert(self : Self, val : Int) -> Unit {
  // 第一步：BST 插入，找到正确位置
  let z = Node::new(val)
  let parent = for current = self.root, parent = None; current is Some(node) {
    if val < node.val {
      continue node.left, Some(node)
    } else if val > node.val {
      continue node.right, Some(node)
    } else {
      return // 没必要插入重复值
    }
  } nobreak { parent }
  z.parent = parent
  match parent {
    Some(p) => if val < p.val { p.left = Some(z) } else { p.right = Some(z) }
    None => {
      // 空树，z 就是根
      z.color = Black
      self.root = Some(z)
      return
    }
  }
  match color(z.parent) {
    Black => return // 父节点是黑色，不需要修复
    Red => self.fix_insert(z) // 父节点是红色，可能违反性质 4，需要修复
  }
}

fn RedBlackTree::fix_insert(self : Self, z : Node) -> Unit {
  // 用状态循环推进 z，避免可变变量
  for z = z; color(z.parent) is Red {
    let p = z.parent.unwrap()
    // 祖父节点一定存在：因为根节点是黑色，红色节点不可能是根，所以父节点必然有祖父节点
    let g = z.grandparent().unwrap()
    if p.is_left_child() {
      // 父在祖父左侧
      let u = g.right // 叔叔
      if color(u) is Red {
        // Case 1：叔叔是红色 → 重新着色，向上传播
        p.color = Black
        u.unwrap().color = Black
        g.color = Red
        continue g
      }

      // Case 2：z 是右孩子（内拐）→ 先左旋转成外拐
      let pivot = if !z.is_left_child() {
        self.left_rotate(p)
        p
      } else {
        z
      }

      // Case 3：z 是左孩子（外拐）→ 右旋 + 重新着色
      let p2 = pivot.parent.unwrap()
      let g2 = pivot.grandparent().unwrap()
      p2.color = Black
      g2.color = Red
      self.right_rotate(g2)
      continue pivot
    } else {
      // 镜像：父在祖父右侧
      // 镜像这部分和上面完全对称
      let u = g.left // 叔叔
      if color(u) is Red {
        // Case 1：叔叔是红色
        p.color = Black
        u.unwrap().color = Black
        g.color = Red
        continue g
      }

      // Case 2：z 是左孩子（内拐）→ 先右旋
      let pivot = if z.is_left_child() {
        self.right_rotate(p)
        p
      } else {
        z
      }

      // Case 3：z 是右孩子（外拐）→ 左旋 + 重新着色
      let p2 = pivot.parent.unwrap()
      let g2 = pivot.grandparent().unwrap()
      p2.color = Black
      g2.color = Red
      self.left_rotate(g2)
      continue pivot
    }
  }

  // 根节点强制为黑色
  self.root.unwrap().color = Black
}

// ============================================================
// 删除
// ============================================================

/// transplant：用子树 v 替换子树 u 在其父节点中的位置，u 直接丢弃
fn RedBlackTree::transplant(self : Self, u : Node, v : Node?) -> Unit {
  match u.parent {
    None => self.root = v
    Some(p) =>
      if u.is_left_child() {
        p.left = v
      } else {
        p.right = v
      }
  }
  if v is Some(v) {
    v.parent = u.parent
  }
}

/// 找子树中的最小节点
fn find_min(node : Node) -> Node {
  // let mut cur = node
  // while cur.left is Some(left) {
  //   cur = left
  // }
  // cur
  node.left.map_or(node, find_min)
}

fn RedBlackTree::delete(self : Self, val : Int) -> Unit {
  // 第一步：BST 查找目标节点 z
  let z = for current = self.root; current is Some(node) {
    if val < node.val {
      continue node.left
    } else if val > node.val {
      continue node.right
    } else {
      break node
    }
  } nobreak { return } // 没找到，直接返回

  // 返回 (被删除节点颜色, x, x_parent)
  let (y_original_color, x, x_parent) = match (z.left, z.right) {
    (None, _) => {
      self.transplant(z, z.right)
      (z.color, z.right, z.parent)
    }
    (_, None) => {
      self.transplant(z, z.left)
      (z.color, z.left, z.parent)
    }
    (Some(_), Some(right)) => {
      let y = find_min(right)
      let y_original_color = y.color
      let x = y.right 
      let x_parent = if y.is_right_child_of(z) {
        Some(y)
      } else {
        // y 不是 z 的直接右孩子
        let parent = y.parent
        // y 只可能有右孩子，先把 y 从原位置摘掉
        self.transplant(y, y.right)
        // 再把 z 的右子树挂到 y 上，并修复 parent 指针
        y.right = z.right
        if y.right is Some(r) { r.parent = Some(y) }
        parent
      }
      self.transplant(z, Some(y))
      // 注意：不需要管右子树，现在已经是对的了
      y.left = z.left
      if y.left is Some(l) { l.parent = Some(y) }
      y.color = z.color
      (y_original_color, x, x_parent)
    }
  }

  if y_original_color is Black {
    self.fix_delete(x, x_parent)
  }
}

/// fix_delete 接收 x（可能为 None）和 x_parent（x 为 None 时用于定位兄弟）
/// 要考虑 NIL
fn RedBlackTree::fix_delete(
  self : Self,
  x : Node?,
  x_parent : Node?
) -> Unit {
  let final_x = for x = x, x_parent = x_parent; color(x) is Black {
    // x 有实体时取 xn.parent；x=None 时退回 x_parent
    let parent = x.map_or(x_parent, xn => xn.parent)
    // x 到达根后停止
    let p = match parent {
      Some(p) => p
      None => break x
    }
    // 判断 x 是 p 的左孩子还是右孩子
    // x 为 None 且 p.left 为 None → x 在左侧
    let x_is_left = x.map_or(p.left is None, Node::is_left_child)

    if x_is_left {
      let w0 = match p.right {
        Some(w) => w
        None => continue Some(p), p.parent
      }
      // Case 1：x 的兄弟 w 是红色 → 交换颜色 + 左旋父节点
      if w0.color is Red {
        w0.color = Black
        p.color = Red
        self.left_rotate(p)
      }
      let wn1 = match p.right {
        Some(w) => w
        None => continue Some(p), p.parent
      }
      if color(wn1.left) is Black && color(wn1.right) is Black {
        // Case 2：w 的两个孩子都黑 → w 染红，x 上移
        wn1.color = Red
        continue Some(p), p.parent
      }

      // Case 3：远侄子（右）黑 → 先右旋 w
      let wn2 = if color(wn1.right) is Black {
        if wn1.left is Some(wl) { wl.color = Black }
        wn1.color = Red
        self.right_rotate(wn1)
        match p.right {
          Some(w) => w
          None => continue Some(p), p.parent
        }
      } else {
        wn1
      }

      // Case 4：远侄子（右）红 → 左旋父节点
      wn2.color = p.color
      p.color = Black
      if wn2.right is Some(wr) { wr.color = Black }
      self.left_rotate(p)
      continue self.root, None
    } else {
      let w0 = match p.left {
        Some(w) => w
        None => continue Some(p), p.parent
      }
      // 镜像：x 是右孩子
      if w0.color is Red {
        w0.color = Black
        p.color = Red
        self.right_rotate(p)
      }
      let wn1 = match p.left {
        Some(w) => w
        None => continue Some(p), p.parent
      }
      if color(wn1.left) is Black && color(wn1.right) is Black {
        // Case 2
        wn1.color = Red
        continue Some(p), p.parent
      }

      // Case 3：远侄子（左）黑
      let wn2 = if color(wn1.left) is Black {
        if wn1.right is Some(wr) { wr.color = Black }
        wn1.color = Red
        self.left_rotate(wn1)
        match p.left {
          Some(w) => w
          None => continue Some(p), p.parent
        }
      } else {
        wn1
      }

      // Case 4
      wn2.color = p.color
      p.color = Black
      if wn2.left is Some(wl) { wl.color = Black }
      self.right_rotate(p)
      continue self.root, None
    }

    
  } nobreak { x }

  if final_x is Some(xn) { xn.color = Black }
}

// ============================================================
// 查找 / 遍历 / 校验
// ============================================================

fn RedBlackTree::search(self : Self, val : Int) -> Bool {
  let mut current = self.root
  while current is Some(node) {
    if val == node.val {
      return true
    } else if val < node.val {
      current = node.left
    } else {
      current = node.right
    }
  }
  false
}

fn RedBlackTree::inorder(self : Self) -> Array[Int] {
  fn walk(node : Node?, acc : Array[Int]) -> Unit {
    guard node is Some(n) else { return }
    walk(n.left, acc)
    acc.push(n.val)
    walk(n.right, acc)
  }

  let result : Array[Int] = []
  walk(self.root, result)
  result
}

/// 校验性质 4：没有连续红节点
fn no_red_red(node : Node?) -> Bool {
  guard node is Some(n) else { return true }
  if n.color is Red && (color(n.left) is Red || color(n.right) is Red) {
    return false
  }
  no_red_red(n.left) && no_red_red(n.right)
}

/// 校验性质 5：所有路径黑高一致，返回 -1 表示不一致
/// 从任意节点出发，到所有叶子 NIL 的路径上，黑节点数量必须相同。
fn black_height(node : Node?) -> Int {
  guard node is Some(n) else { return 1 } // NIL 算 1 个黑节点
  let lh = black_height(n.left)
  let rh = black_height(n.right)
  // 左子树违规 || 右子树违规 || 当前层级违规
  if lh == -1 || rh == -1 || lh != rh {
    return -1
  }
  lh + (if n.color is Black { 1 } else { 0 })
}

/// 综合校验所有红黑树性质
fn RedBlackTree::verify(self : Self) -> Bool {
  color(self.root) is Black && 
    no_red_red(self.root) && 
    black_height(self.root) != -1
}

// ============================================================
// 测试
// ============================================================

test "rb_insert_basic" {
  let tree = RedBlackTree::new()
  tree.insert(3)
  tree.insert(2)
  tree.insert(1)
  assert_eq(tree.inorder(), [1, 2, 3])
  assert_eq(tree.verify(), true)
}

test "rb_insert_ascending" {
  let tree = RedBlackTree::new()
  for i in 1..=7 {
    tree.insert(i)
  }
  assert_eq(tree.inorder(), [1, 2, 3, 4, 5, 6, 7])
  assert_eq(tree.verify(), true)
}

test "rb_insert_descending" {
  let tree = RedBlackTree::new()
  for i = 7; i >= 1; i = i - 1 {
    tree.insert(i)
  }
  assert_eq(tree.inorder(), [1, 2, 3, 4, 5, 6, 7])
  assert_eq(tree.verify(), true)
}

test "rb_insert_duplicate" {
  let tree = RedBlackTree::new()
  tree.insert(1)
  tree.insert(1)
  assert_eq(tree.inorder(), [1])
  assert_eq(tree.verify(), true)
}

test "rb_search" {
  let tree = RedBlackTree::new()
  for i in [5, 3, 7, 2, 4, 6, 8] {
    tree.insert(i)
  }
  assert_eq(tree.search(4), true)
  assert_eq(tree.search(9), false)
}

test "rb_delete_leaf" {
  let tree = RedBlackTree::new()
  tree.insert(2)
  tree.insert(1)
  tree.insert(3)
  tree.delete(1)
  assert_eq(tree.inorder(), [2, 3])
  assert_eq(tree.verify(), true)
}

test "rb_delete_node_with_one_child" {
  let tree = RedBlackTree::new()
  for i in [5, 3, 7, 2, 4] {
    tree.insert(i)
  }
  tree.delete(3)
  assert_eq(tree.search(3), false)
  assert_eq(tree.verify(), true)
}

test "rb_delete_node_with_two_children" {
  let tree = RedBlackTree::new()
  for i in [5, 3, 7, 2, 4, 6, 8] {
    tree.insert(i)
  }
  tree.delete(5) // 删除根节点
  assert_eq(tree.search(5), false)
  assert_eq(tree.inorder(), [2, 3, 4, 6, 7, 8])
  assert_eq(tree.verify(), true)
}

test "rb_delete_root" {
  let tree = RedBlackTree::new()
  tree.insert(1)
  tree.delete(1)
  assert_eq(tree.inorder(), [])
  assert_eq(tree.verify(), true)
}

test "rb_delete_nonexistent" {
  let tree = RedBlackTree::new()
  tree.insert(1)
  tree.insert(2)
  tree.delete(99)
  assert_eq(tree.inorder(), [1, 2])
  assert_eq(tree.verify(), true)
}

test "rb_insert_delete_many" {
  let tree = RedBlackTree::new()
  // 插入 1..15
  for i in 1..=15 {
    tree.insert(i)
  }
  assert_eq(tree.verify(), true)
  // 逐个删除奇数
  for i in [1, 3, 5, 7, 9, 11, 13, 15] {
    tree.delete(i)
    assert_eq(tree.verify(), true)
  }
  assert_eq(tree.inorder(), [2, 4, 6, 8, 10, 12, 14])
  // 再删除偶数
  for i in [2, 4, 6, 8, 10, 12, 14] {
    tree.delete(i)
    assert_eq(tree.verify(), true)
  }
  assert_eq(tree.inorder(), [])
}

