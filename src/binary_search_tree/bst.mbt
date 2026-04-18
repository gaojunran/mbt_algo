struct Node {
  mut val: Int
  mut left: Node?
  mut right: Node?
} derive(ToJson)

struct BST {
  mut root: Node?
} derive(ToJson)

fn BST::new() -> Self {
  BST::{root: None}
}

///|
fn BST::insert(self : Self, val : Int) -> Unit {
  fn insert_node(root : Node?, val : Int) -> Node? {
    match root {
      None => Some(Node::{ val, left: None, right: None })
      Some(node) => {
        if val < node.val {
          node.left = insert_node(node.left, val)
        } else if val > node.val {
          node.right = insert_node(node.right, val)
        }
        // val == node.val: duplicate key, do nothing
        root
      }
    }
  }
  self.root = insert_node(self.root, val)
}

///|
fn BST::insert2(self : Self, val : Int) -> Unit {
  let new_node = Node::{ val, left: None, right: None }
  for current = self.root, parent = None {
    match current {
      Some(node) =>
        if val < node.val {
          continue node.left, current
        } else if val > node.val {
          continue node.right, current
        } else {
          // duplicate key, do nothing
          break
        }
      None => {
        match parent {
          None => self.root = Some(new_node) // tree was empty
          Some(p) =>
            if val < p.val {
              p.left = Some(new_node)
            } else {
              p.right = Some(new_node)
            }
        }
        break
      }
    }
  }
}

///|
fn BST::search(self : Self, val : Int) -> Bool {
  fn search_node(root : Node?, val : Int) -> Bool {
    match root {
      None => false
      Some(node) => {
        if val == node.val {
          true
        } else if val < node.val {
          search_node(node.left, val)
        } else {
          search_node(node.right, val)
        }
      }
    }
  }
  search_node(self.root, val)
}

///|
fn BST::inorder(self : Self) -> Array[Int] {
  fn inorder_node(root : Node?, acc : Array[Int]) -> Array[Int] {
    match root {
      None => acc
      Some(node) => {
        let acc = inorder_node(node.left, acc)
        acc.push(node.val)
        inorder_node(node.right, acc)
      }
    }
  }
  inorder_node(self.root, [])
}

fn BST::preorder(self : Self) -> Array[Int] {
  fn preorder_node(root : Node?, acc : Array[Int]) -> Array[Int] {
    match root {
      None => acc
      Some(node) => {
        acc.push(node.val)
        let acc = preorder_node(node.left, acc)
        preorder_node(node.right, acc)
      }
    }
  }
  preorder_node(self.root, [])
}

fn BST::postorder(self : Self) -> Array[Int] {
  fn postorder_node(root : Node?, acc : Array[Int]) -> Array[Int] {
    match root {
      None => acc
      Some(node) => {
        let acc = postorder_node(node.left, acc)
        let acc = postorder_node(node.right, acc)
        acc..push(node.val)
      }
    }
  }
  postorder_node(self.root, [])
}

fn find_min(node : Node) -> Node {
  match node.left {
    None => node
    Some(left) => find_min(left)
  }
}

fn find_max(node : Node) -> Node {
  match node.right {
    None => node
    Some(right) => find_max(right)
  }
}

///|
fn BST::delete(self : Self, val : Int) -> Unit {
  fn delete_node(root : Node?, val : Int) -> Node? {
    match root {
      None => None
      Some(node) =>
        if val < node.val {
          node.left = delete_node(node.left, val)
          root
        } else if val > node.val {
          node.right = delete_node(node.right, val)
          root
        } else { // equal
          match (node.left, node.right) {
            (None, None) => None
            (Some(left), None) => Some(left)
            (None, Some(right)) => Some(right)
            (Some(_), Some(right)) => {
              // 有右子树时，后继一定在右子树里，具体来说是右子树里最小的节点
              let min = find_min(right)
              // 用中序后继替换当前节点
              node.val = min.val
              // 把这个替换的节点删掉
              node.right = delete_node(node.right, min.val)
              root
            }
          }
        }
    }
  }
  self.root = delete_node(self.root, val)
}


///|
test "insert" {
  let bst = BST::new()
  bst.insert2(3)
  bst.insert2(1)
  bst.insert2(4)
  bst.insert2(2)
  json_inspect(bst, content={
    "root": {
      "val": 3,
      "left": { "val": 1, "right": { "val": 2 } },
      "right": { "val": 4 },
    },
  })
  assert_eq(bst.search(1), true)
  json_inspect(bst.inorder(), content=[1, 2, 3, 4])
  json_inspect(bst.preorder(), content=[3, 1, 2, 4])
  json_inspect(bst.postorder(), content=[2, 1, 4, 3])

  bst.delete(3)
  json_inspect(bst, content={
    "root": { "val": 4, "left": { "val": 1, "right": { "val": 2 } } },
  })
  json_inspect(bst.inorder(), content=[1, 2, 4])
}
