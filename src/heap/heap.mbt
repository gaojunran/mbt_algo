///|
priv struct ArrayHeap {
  arr : Array[Int]
} derive(ToJson)

fn ArrayHeap::new(arr : Array[Int]) -> ArrayHeap {
  { arr, }
}

fn ArrayHeap::left(self: Self, i : Int) -> (Int, Int?) {
  (2 * i + 1, self.arr.get(2 * i + 1))
}

fn ArrayHeap::right(self: Self, i : Int) -> (Int, Int?) {
  (2 * i + 2, self.arr.get(2 * i + 2))
}

fn ArrayHeap::parent(self: Self, i : Int) -> (Int, Int?) {
  ((i - 1) / 2, self.arr.get((i - 1) / 2))
}

///|
// fn max(arr : Array[Int]) -> (Int, Int) {
//   for idx, val in arr; max = (0, arr[0]) {
//     if val > max.1 {
//       continue (idx, val)
//     }
//   } nobreak { max }
// }

fn max_idx(arr : Array[(Int, Int)]) -> Int {
  for cur in arr; max = arr[0] {
    if cur.1 > max.1 {
      continue cur
    }
  } nobreak { max.0 }
}



fn ArrayHeap::push(self : ArrayHeap, val : Int) -> Unit {
  self.arr.push(val)
  self.sift_up(self.arr.length() - 1)
}

fn ArrayHeap::peek(self : ArrayHeap) -> Int? {
  return self.arr.get(0)
}

///|
/// 保证这个节点比其父节点小
fn ArrayHeap::sift_up(self : ArrayHeap, i : Int) -> Unit {
  guard self.arr.get(i) is Some(_) else { return }
  for i = i {
    let parent = self.parent(i)
    guard parent.1 is Some(parent_val) && self.arr[i] > parent_val 
      else { break }
    self.arr.swap(i, parent.0)
    continue parent.0
  }
}

// 删除最大值，但不能直接删除根节点
// 只有最后一个节点可以直接删除
fn ArrayHeap::pop(self : ArrayHeap) -> Int? {
  let first = self.arr.get(0)
  guard first is Some(_) else { return None }
  self.arr.swap(0, self.arr.length() - 1)
  let _ = self.arr.pop()
  self.sift_down(0)
  return first
}

///|
/// 保证这个节点比其子节点大
fn ArrayHeap::sift_down(self : ArrayHeap, i : Int) -> Unit {
  guard self.arr.get(i) is Some(_) else { return }
  for i = i {
    let l = self.left(i)
    let r = self.right(i)
    let cur = (i, Some(self.arr[i]))
    // match x.1 { Some(val) => Some(val); None => None }
    let largest_idx = [l, r, cur].filter_map(x => {
        match x.1 {
          Some(val) => Some((x.0, val))
          None => None
        }
        // x.1.map(val => (x.0, val))
      }) |> max_idx
    if largest_idx == i {
      break
    }
    self.arr.swap(i, largest_idx)
    // 是上次最大的，现在已经不是最大的了，继续往下 sift
    continue largest_idx
  }
}

fn ArrayHeap::heapify(arr : Array[Int]) -> Self {
  let heap = ArrayHeap::new(arr)
  // 数组长度为 n，叶子节点的索引范围是 [n/2, n)，所以非叶子节点的索引范围是 [0, n/2)
  for i in (arr.length() / 2 - 1) >=.. 0 {
    heap.sift_down(i)
  }
  heap
}

fn heap_sort(arr : Array[Int]) -> Array[Int] {
  let heap = ArrayHeap::heapify(arr)
  // 可以不用 peek，在没有的时候 peek 和 pop 等价
  for res = []; heap.pop() is Some(val) {
    continue res..push(val)
  } nobreak { res }
}

///|
test {
  let heap = ArrayHeap::heapify([1, 3, 2])
  json_inspect(heap, content=({"arr":[3, 1, 2]}))
  assert_eq(heap.peek(), Some(3))
  let popped = heap.pop()
  assert_eq(popped, Some(3))
  json_inspect(heap, content=({"arr":[2,1]}))
  let arr = [5, 3, 8, 1, 2]
  let sorted = heap_sort(arr)
  assert_eq(sorted, [8, 5, 3, 2, 1])
}


