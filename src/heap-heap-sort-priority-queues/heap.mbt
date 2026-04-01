///|
priv struct ArrayHeap {
  arr : Array[Int]
} derive(ToJson)

fn ArrayHeap::new() -> ArrayHeap {
  { arr: [] }
}

fn left_child(i : Int) -> Int {
  2 * i + 1
}

fn right_child(i : Int) -> Int {
  2 * i + 2
}

fn parent(i : Int) -> Int {
  (i - 1) / 2
}

fn max(arr : Array[Int]) -> Int {
  arr.fold(init=@int.MIN_VALUE, Int::max)
}

fn min(arr : Array[Int]) -> Int {
  arr.fold(init=@int.MAX_VALUE, Int::min)
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
  let mut i = i
  while i > 0 && self.arr[i] > self.arr[parent(i)] {
    self.arr.swap(i, parent(i))
    i = parent(i)
  }
}

/// 保证这个节点比其子节点大
fn ArrayHeap::sift_down(self : ArrayHeap, i : Int) -> Unit {
  let len = self.arr.length()
  let mut i = i
  while true {
    let left = left_child(i)
    let right = right_child(i)
    let mut largest = i
    if left < len && self.arr[left] > self.arr[largest] {
      largest = left
    }
    if right < len && self.arr[right] > self.arr[largest] {
      largest = right
    }
    if largest != i {
      self.arr.swap(i, largest)
      i = largest
    } else {
      break
    }
  }
}

///|
test {
  let heap = ArrayHeap::new()
  heap.push(1)
  heap.push(2)
  heap.push(3)
  json_inspect(heap, content={ "arr": [3, 1, 2] })
  assert_eq(heap.peek(), Some(3))
}


