struct Node {
  ch: Char?
  freq: Int
  left: Node?
  right: Node?
}

type FreqMap = Map[Char?, Int]
type CodeTable = Map[Char, String]

impl Eq for Node with equal(self, other) {
  self.freq == other.freq
}

impl Compare for Node with compare(self, other) {
  self.freq.compare(other.freq)
}

struct HuffmanTree {
  root: Node?
}

fn HuffmanTree::new() -> Self {
  { root: None }
}

fn get_freq_map(text: String) -> FreqMap {
  let freq_map = {}
  text.iter().each(ch => {
    freq_map.update(Some(ch), val => Some(val.unwrap_or(0) + 1))
  })
  freq_map
}

fn build_tree(freq_map: FreqMap) -> HuffmanTree {
  let heap = @priority_queue.new()

  for item in freq_map {
    let (ch, freq) = item
    heap.push(Node::{ ch, freq, left: None, right: None })
  }

  while heap.length() > 1 {
    let left = heap.pop().unwrap()
    let right = heap.pop().unwrap()
    let parent = Node::{ 
      ch: None,
      left: Some(left), 
      right: Some(right),
      freq: left.freq + right.freq
    } 
    heap.push(parent)
  }
  
  HuffmanTree::{ root: heap.pop() }
}

fn HuffmanTree::build_table(self: Self) -> CodeTable {
  let table = {}
  fn dfs(node: Node?, path: String) {
    guard node is Some(node) else { return }
    if node.ch is Some(ch) {
      table.set(ch, path)
    }
    dfs(node.left, path + "0")
    dfs(node.right, path + "1")
  }
  dfs(self.root, "")
  table
}

fn HuffmanTree::encode(self: Self, text: String) -> String {
  let table = self.build_table()
  text.iter().map(ch => table.get(ch).unwrap()).join("")
}

fn HuffmanTree::decode(self: Self, encoded: String) -> String {
  for bit in encoded; curr = self.root, result = "" {
    guard curr is Some(node) else { break result }
    let next = if bit == '0' { node.left } else { node.right }
    guard next is Some(next_node) else { break result }
    match next_node.ch {
      None => continue Some(next_node), result
      Some(ch) => continue self.root, result + ch.to_string()
    }
  } nobreak {
    result
  }
}

///|
test "encode and decode" {
  let texts = ["hello world", "huffman coding", "mbt is awesome"]
  for text in texts {
    let freq_map = get_freq_map(text)
    let tree = build_tree(freq_map)
    let encoded = tree.encode(text)
    let decoded = tree.decode(encoded)
    assert_eq(decoded, text)
  }
}
