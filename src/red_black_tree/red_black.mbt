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
fn is_left_child(node : Node) -> Bool {
  match node.parent {
    Some(p) => p.left is Some(left) && left.val == node.val
    None => false
  }
}

/// 获取兄弟节点
fn sibling(node : Node) -> Node? {
  match node.parent {
    Some(p) => if is_left_child(node) { p.right } else { p.left }
    None => None
  }
}

/// 获取祖父节点
fn grandparent(node : Node) -> Node? {
  match node.parent {
    Some(p) => p.parent
    None => None
  }
}

// ============================================================
// 插入
// ============================================================

fn RedBlackTree::insert(self : Self, val : Int) -> Unit {
  // 第一步：BST 插入，找到正确位置
  let z = Node::new(val)
  let mut current = self.root
  let mut parent : Node? = None
  while current is Some(node) {
    parent = current
    if val < node.val {
      current = node.left
    } else if val > node.val {
      current = node.right
    } else {
      return // 重复值，不插入
    }
  }
  z.parent = parent
  match parent {
    Some(p) => if val < p.val { p.left = Some(z) } else { p.right = Some(z) }
    None => ()
  }
  if parent is None {
    // 空树，z 就是根
    z.color = Black
    self.root = Some(z)
    return
  }
  // 如果父节点是黑色，不需要修复
  if color(z.parent) is Black {
    return
  }
  // 第二步：修复红红冲突
  self.fix_insert(z)
}

fn RedBlackTree::fix_insert(self : Self, z_ : Node) -> Unit {
  let mut z = z_
  // 循环条件：父节点存在且为红色
  while color(z.parent) is Red {
    let p = z.parent.unwrap()
    let g = grandparent(z).unwrap()
    if is_left_child(p) {
      // 父在祖父左侧
      let u = g.right // 叔叔
      if color(u) is Red {
        // Case 1：叔叔是红色 → 重新着色，向上传播
        p.color = Black
        u.unwrap().color = Black
        g.color = Red
        z = g
      } else {
        // Case 2：z 是右孩子（内拐）→ 先左旋转成外拐
        if !(is_left_child(z)) {
          z = p
          self.left_rotate(z)
        }
        // Case 3：z 是左孩子（外拐）→ 右旋 + 重新着色
        let p = z.parent.unwrap()
        let g = grandparent(z).unwrap()
        p.color = Black
        g.color = Red
        self.right_rotate(g)
      }
    } else {
      // 镜像：父在祖父右侧
      let u = g.left // 叔叔
      if color(u) is Red {
        // Case 1：叔叔是红色
        p.color = Black
        u.unwrap().color = Black
        g.color = Red
        z = g
      } else {
        // Case 2：z 是左孩子（内拐）→ 先右旋
        if is_left_child(z) {
          z = p
          self.right_rotate(z)
        }
        // Case 3：z 是右孩子（外拐）→ 左旋 + 重新着色
        let p = z.parent.unwrap()
        let g = grandparent(z).unwrap()
        p.color = Black
        g.color = Red
        self.left_rotate(g)
      }
    }
  }
  // 根节点强制为黑色
  self.root.unwrap().color = Black
}

// ============================================================
// 删除
// ============================================================

/// transplant：用子树 v 替换子树 u 在其父节点中的位置
fn RedBlackTree::transplant(self : Self, u : Node, v : Node?) -> Unit {
  match u.parent {
    None => self.root = v
    Some(p) =>
      if is_left_child(u) {
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
  let mut cur = node
  while cur.left is Some(left) {
    cur = left
  }
  cur
}

fn RedBlackTree::delete(self : Self, val : Int) -> Unit {
  // 第一步：BST 查找目标节点 z
  let mut current = self.root
  let mut found : Node? = None
  while current is Some(node) {
    if val < node.val {
      current = node.left
    } else if val > node.val {
      current = node.right
    } else {
      found = Some(node)
      break
    }
  }
  guard found is Some(z) else { return } // 没找到，直接返回

  let mut y_original_color = z.color
  let mut x : Node? = None
  let mut x_parent : Node? = None // 追踪 x 的父节点（x 为 None 时需要）

  match (z.left, z.right) {
    (None, _) => {
      x = z.right
      x_parent = z.parent
      self.transplant(z, z.right)
    }
    (_, None) => {
      x = z.left
      x_parent = z.parent
      self.transplant(z, z.left)
    }
    (Some(_), Some(right)) => {
      let y = find_min(right)
      y_original_color = y.color
      x = y.right
      if y.parent is Some(p) && p.val == z.val {
        // y 是 z 的直接右孩子
        x_parent = Some(y)
      } else {
        x_parent = y.parent
        self.transplant(y, y.right)
        y.right = z.right
        if y.right is Some(r) { r.parent = Some(y) }
      }
      self.transplant(z, Some(y))
      y.left = z.left
      if y.left is Some(l) { l.parent = Some(y) }
      y.color = z.color
    }
  }

  if y_original_color is Black {
    self.fix_delete(x, x_parent)
  }
}

/// fix_delete 接收 x（可能为 None）和 x_parent（x 为 None 时用于定位兄弟）
fn RedBlackTree::fix_delete(
  self : Self,
  x_ : Node?,
  x_parent_ : Node?
) -> Unit {
  let mut x = x_
  let mut x_parent = x_parent_
  // 循环：x 不是根 且 x 是黑色（双重黑需要修复）
  while color(x) is Black {
    // x 是根节点则退出
    match x {
      Some(xn) => if xn.parent is None { break }
      None => if x_parent is None { break }
    }
    let p = match x {
      Some(xn) => xn.parent.unwrap()
      None => x_parent.unwrap()
    }
    // 判断 x 是 p 的左孩子还是右孩子
    let x_is_left = match x {
      Some(xn) => is_left_child(xn)
      None => p.left is None // x 为 None 且 p.left 为 None → x 在左侧
    }
    if x_is_left {
      let mut w = p.right
      // Case 1：兄弟 w 是红色
      if color(w) is Red {
        w.unwrap().color = Black
        p.color = Red
        self.left_rotate(p)
        w = p.right
      }
      let wn = w.unwrap()
      if color(wn.left) is Black && color(wn.right) is Black {
        // Case 2：w 的两个孩子都黑 → w 染红，x 上移
        wn.color = Red
        x = Some(p)
        x_parent = p.parent
      } else {
        // Case 3：远侄子（右）黑 → 先右旋 w
        if color(wn.right) is Black {
          if wn.left is Some(wl) { wl.color = Black }
          wn.color = Red
          self.right_rotate(wn)
          w = p.right
        }
        // Case 4：远侄子（右）红 → 左旋父节点
        let wn = w.unwrap()
        wn.color = p.color
        p.color = Black
        if wn.right is Some(wr) { wr.color = Black }
        self.left_rotate(p)
        x = self.root
        x_parent = None
      }
    } else {
      // 镜像：x 是右孩子
      let mut w = p.left
      // Case 1
      if color(w) is Red {
        w.unwrap().color = Black
        p.color = Red
        self.right_rotate(p)
        w = p.left
      }
      let wn = w.unwrap()
      if color(wn.left) is Black && color(wn.right) is Black {
        // Case 2
        wn.color = Red
        x = Some(p)
        x_parent = p.parent
      } else {
        // Case 3：远侄子（左）黑
        if color(wn.left) is Black {
          if wn.right is Some(wr) { wr.color = Black }
          wn.color = Red
          self.left_rotate(wn)
          w = p.left
        }
        // Case 4
        let wn = w.unwrap()
        wn.color = p.color
        p.color = Black
        if wn.left is Some(wl) { wl.color = Black }
        self.right_rotate(p)
        x = self.root
        x_parent = None
      }
    }
  }
  if x is Some(xn) { xn.color = Black }
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

/// 校验性质 2：根节点是黑色
fn RedBlackTree::root_is_black(self : Self) -> Bool {
  color(self.root) is Black
}

/// 校验性质 4：没有连续红节点
fn no_red_red(node : Node?) -> Bool {
  guard node is Some(n) else { return true }
  if n.color is Red {
    if color(n.left) is Red || color(n.right) is Red {
      return false
    }
  }
  no_red_red(n.left) && no_red_red(n.right)
}

/// 校验性质 5：所有路径黑高一致，返回 -1 表示不一致
fn black_height(node : Node?) -> Int {
  guard node is Some(n) else { return 1 } // NIL 算 1 个黑节点
  let lh = black_height(n.left)
  let rh = black_height(n.right)
  if lh == -1 || rh == -1 || lh != rh {
    return -1
  }
  lh + (if n.color is Black { 1 } else { 0 })
}

/// 综合校验所有红黑树性质
fn RedBlackTree::verify(self : Self) -> Bool {
  self.root_is_black() && 
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

