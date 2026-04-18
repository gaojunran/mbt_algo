// 如果 bst 里存了 parent，就可以在 O(1) 时间内找到一个节点的前驱和后继
struct Node2 {
  val: Int
  mut left: Node2?
  mut right: Node2?
  parent: Node2?  // 只有 root 节点没有 parent
}

struct BST2 {
  mut root: Node2?
}

fn BST2::new() -> Self {
  BST2::{ root: None }
}

fn BST2::insert(self : Self, val : Int) -> Unit {
  fn insert_node(root : Node2?, val : Int, parent : Node2?) -> Node2 {
    match root {
      None => Node2::{ val, left: None, right: None, parent }
      Some(node) =>
        if val < node.val {
          node.left = Some(insert_node(node.left, val, Some(node)))
          node
        } else if val > node.val {
          node.right = Some(insert_node(node.right, val, Some(node)))
          node
        } else { // equal
          node
        }
    }
  }
  self.root = Some(insert_node(self.root, val, None))
}

fn find_min2(node : Node2) -> Node2 {
  match node.left {
    None => node
    Some(left) => find_min2(left)
  }
}

fn find_max2(node : Node2) -> Node2 {
  match node.right {
    None => node
    Some(right) => find_max2(right)
  }
}

// 重要推论：比 x 大的节点，要么在 x 的右子树里，要么在 x 的祖先节点方向
// 具体地，要找 x 的后继，要么是右子树里最小的节点，要么是找第一个使得当前节点在其左子树中的那个祖先
fn Node2::successor(self : Self) -> Node2? {
  match self.right {
    Some(right) => Some(find_min2(right))
    None =>
      for current = self, parent = self.parent {
        guard parent is Some(p) else { break None }
        // 换言之，逐层向上，找第一对父子关系是「左子树」的节点
        if p.left is Some(left) && left.val == current.val {
          break Some(p) // current 是 p 的左子树，p 就是后继
        } else {
          continue p, p.parent // current 是右子树，继续向上查找
        }
    }
  }
}

fn Node2::predecessor(self : Self) -> Node2? {
  match self.left {
    Some(left) => Some(find_max2(left))
    None =>
      for current = self, parent = self.parent {
        guard parent is Some(p) else { break None }
        // 换言之，逐层向上，找第一对父子关系是「右子树」的节点
        if p.right is Some(right) && right.val == current.val {
          break Some(p) // current 是 p 的右子树，p 就是前驱
        } else {
          continue p, p.parent // current 是左子树，继续向上查找
        }
    }
  }
}

///|
test "successor" {
  let bst = BST2::new()
  bst.insert(3)
  bst.insert(1)
  bst.insert(4)
  bst.insert(2)
  assert_eq(bst.root.unwrap().successor().unwrap().val, 4)
  assert_eq(bst.root.unwrap().left.unwrap().successor().unwrap().val, 2)
}

///|
test "predecessor" {
  let bst = BST2::new()
  bst.insert(3)
  bst.insert(1)
  bst.insert(4)
  bst.insert(2)
  assert_eq(bst.root.unwrap().predecessor().unwrap().val, 2)
  assert_eq(bst.root.unwrap().right.unwrap().predecessor().unwrap().val, 3)
}
