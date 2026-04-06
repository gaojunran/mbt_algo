struct Node {
  mut val: Int
  mut left: Node?
  mut right: Node?
  mut height: Int
}

fn Node::new(val: Int) -> Node {
  Node::{ val, left: None, right: None, height: 1 }
}

struct AVLTree {
  mut root: Node?
}

fn Node::update_height(self: Self) -> Unit{
  let left_height = self.left.map_or(0, (child) => child.height)
  let right_height = self.right.map_or(0, (child) => child.height)
  self.height = 1 + @cmp.maximum(left_height, right_height)
}

// balance factor = height(left) - height(right)
fn Node::bf(self: Self) -> Int {
  let left_height = self.left.map_or(0, (child) => child.height)
  let right_height = self.right.map_or(0, (child) => child.height)
  left_height - right_height
}

// 左旋：从父节点变成左子节点
fn Node::left_rotate(self: Self) -> Node {
  let child = self.right.unwrap()
  let grandchild = child.left
  child.left = Some(self)
  self.right = grandchild
  self.update_height()
  return child..update_height()
}

// 右旋：从父节点变成右子节点
fn Node::right_rotate(self: Self) -> Node {
  let child = self.left.unwrap()
  let grandchild = child.right
  child.right = Some(self)
  self.left = grandchild
  self.update_height()
  return child..update_height()
}

// 注意：平衡因子的值决定了子树是否存在，不需要任何判空代码
fn Node::rotate(self: Self) -> Node {
  let bf = self.bf()
  let left_bf = self.left.map_or(0, (child) => child.bf())
  let right_bf = self.right.map_or(0, (child) => child.bf())
  if bf > 1 {
    if left_bf < 0 {
      self.left = self.left.map(Node::left_rotate)
    }
    return self.right_rotate()
  } else if bf < -1 {
    if right_bf > 0 {
      self.right = self.right.map(Node::right_rotate)
    }
    return self.left_rotate()
  }
  self
}

///|
fn AVLTree::insert(self : Self, val : Int) -> Unit {
  fn insert_node(node : Node?, val : Int) -> Node {
    guard node is Some(node) else { return Node::new(val) }
    if val < node.val {
      node.left = Some(insert_node(node.left, val))
    } else if val > node.val {
      node.right = Some(insert_node(node.right, val))
    } else {
      return node // 特殊情况，直接返回
    }
    node.update_height()
    node.rotate()
  }
  self.root = Some(insert_node(self.root, val))
}

fn AVLTree::delete(self: Self, val: Int) -> Unit {
  fn find_min(node : Node) -> Node {
    // match node.left {
    //   None => node
    //   Some(left) => find_min(left)
    // }
    node.left.map_or(node, find_min)
  }

  fn delete_node(node: Node?, val: Int) -> Node? {
    guard node is Some(node) else { return None }
    let node = if val < node.val {
      node.left = delete_node(node.left, val)
      node
    } else if val > node.val {
      node.right = delete_node(node.right, val)
      node
    } else {
      // 找到要删除的节点
      match (node.left, node.right) {
        (None, None) => return None
        (Some(child), None) | (None, Some(child)) => child
        (Some(_), Some(right)) => {
          let min = find_min(right)
          node.val = min.val
          node.right = delete_node(node.right, min.val)
          node
        }
      }
    }
    node.update_height()
    Some(node.rotate())
  }
  self.root = delete_node(self.root, val)
}

fn AVLTree::new() -> Self {
  AVLTree::{ root: None }
}

fn AVLTree::search(self: Self, val: Int) -> Bool {
  fn search_node(node: Node?, val: Int) -> Bool {
    guard node is Some(node) else { return false }
    if val == node.val {
      true
    } else if val < node.val {
      search_node(node.left, val)
    } else {
      search_node(node.right, val)
    }
  }
  search_node(self.root, val)
}

fn AVLTree::inorder(self: Self) -> Array[Int] {
  fn inorder_node(node: Node?, acc: Array[Int]) -> Array[Int] {
    guard node is Some(node) else { return acc }
    let acc = inorder_node(node.left, acc)
    acc.push(node.val)
    inorder_node(node.right, acc)
  }
  inorder_node(self.root, [])
}

// Check if the tree satisfies AVL balance property
fn AVLTree::is_balanced(self: Self) -> Bool {
  fn check(node: Node?) -> Bool {
    guard node is Some(node) else { return true }
    let bf = node.bf()
    bf >= -1 && bf <= 1 && check(node.left) && check(node.right)
  }
  check(self.root)
}

test "avl_insert" {
  let tree = AVLTree::new()
  tree.insert(3)
  tree.insert(2)
  tree.insert(1) // triggers right rotation
  assert_eq(tree.inorder(), [1, 2, 3])
  assert_eq(tree.is_balanced(), true)
  // after rotation, root should be 2
  assert_eq(tree.root.unwrap().val, 2)
}

test "avl_insert_lr" {
  let tree = AVLTree::new()
  tree.insert(3)
  tree.insert(1)
  tree.insert(2) // triggers left-right rotation
  assert_eq(tree.inorder(), [1, 2, 3])
  assert_eq(tree.is_balanced(), true)
  assert_eq(tree.root.unwrap().val, 2)
}

test "avl_insert_rl" {
  let tree = AVLTree::new()
  tree.insert(1)
  tree.insert(3)
  tree.insert(2) // triggers right-left rotation
  assert_eq(tree.inorder(), [1, 2, 3])
  assert_eq(tree.is_balanced(), true)
  assert_eq(tree.root.unwrap().val, 2)
}

test "avl_insert_many" {
  let tree = AVLTree::new()
  // insert 1..7 in order, should still be balanced
  for i in 1..=7 {
    tree.insert(i)
  }
  assert_eq(tree.inorder(), [1, 2, 3, 4, 5, 6, 7])
  assert_eq(tree.is_balanced(), true)
  assert_eq(tree.search(4), true)
  assert_eq(tree.search(8), false)
}

test "avl_delete_leaf" {
  let tree = AVLTree::new()
  tree.insert(2)
  tree.insert(1)
  tree.insert(3)
  tree.delete(1)
  assert_eq(tree.inorder(), [2, 3])
  assert_eq(tree.is_balanced(), true)
}

test "avl_delete_node_with_one_child" {
  let tree = AVLTree::new()
  tree.insert(3)
  tree.insert(2)
  tree.insert(4)
  tree.insert(1)
  tree.delete(2) // node 2 has left child 1
  assert_eq(tree.inorder(), [1, 3, 4])
  assert_eq(tree.is_balanced(), true)
}

test "avl_delete_node_with_two_children" {
  let tree = AVLTree::new()
  for i in [5, 3, 7, 2, 4, 6, 8] {
    tree.insert(i)
  }
  tree.delete(5) // root, has two children
  assert_eq(tree.search(5), false)
  assert_eq(tree.inorder(), [2, 3, 4, 6, 7, 8])
  assert_eq(tree.is_balanced(), true)
}

test "avl_delete_triggers_rebalance" {
  let tree = AVLTree::new()
  tree.insert(5)
  tree.insert(3)
  tree.insert(8)
  tree.insert(7)
  tree.insert(9)
  // delete left child, causing right-heavy imbalance
  tree.delete(3)
  assert_eq(tree.inorder(), [5, 7, 8, 9])
  assert_eq(tree.is_balanced(), true)
}

test "avl_duplicate_insert" {
  let tree = AVLTree::new()
  tree.insert(1)
  tree.insert(1) // duplicate, should be ignored
  assert_eq(tree.inorder(), [1])
}

test "avl_delete_nonexistent" {
  let tree = AVLTree::new()
  tree.insert(1)
  tree.insert(2)
  tree.delete(99) // doesn't exist
  assert_eq(tree.inorder(), [1, 2])
  assert_eq(tree.is_balanced(), true)
}


