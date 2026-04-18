

fn merge_sort(arr: Array[Int]) -> Unit {
  fn merge(arr: Array[Int], left: Int, mid: Int, right: Int) -> Unit {
    // Copy the two sub-arrays into temporary arrays
    let left_arr = Array::make(mid - left + 1, 0)
    let right_arr = Array::make(right - mid, 0)
    for i in 0..<left_arr.length() {
      left_arr[i] = arr[left + i]
    }
    for j in 0..<right_arr.length() {
      right_arr[j] = arr[mid + 1 + j]
    }
    // Merge the two temporary arrays back into arr[left..right]
    let mut i = 0
    let mut j = 0
    let mut k = left
    while i < left_arr.length() && j < right_arr.length() {
      if left_arr[i] <= right_arr[j] {
        arr[k] = left_arr[i]
        i = i + 1
      } else {
        arr[k] = right_arr[j]
        j = j + 1
      }
      k = k + 1
    }
    // Copy remaining elements
    while i < left_arr.length() {
      arr[k] = left_arr[i]
      i = i + 1
      k = k + 1
    }
    while j < right_arr.length() {
      arr[k] = right_arr[j]
      j = j + 1
      k = k + 1
    }
  }
  fn sort(arr: Array[Int], left: Int, right: Int) -> Unit {
    if left >= right {
      return;
    }
    let mid = (left + right) / 2;
    sort(arr, left, mid);
    sort(arr, mid + 1, right);
    merge(arr, left, mid, right);
  }
  sort(arr, 0, arr.length() - 1);
}

fn merge_sort2(arr: ArrayView[Int]) -> ArrayView[Int] {
  fn merge(left: ArrayView[Int], right: ArrayView[Int]) -> Array[Int] {
    match (left, right) {
      ([], []) => []
      ([], right) => right.to_array()
      (left, []) => left.to_array()
      ([.., x], [..ys, y]) if x <= y => {
        // y 是当前最大的，放到最后
        merge(left, ys)..push(y)
      }
      ([..xs, x], [.., _]) => {
        // x 是当前最大的，放到最后
        merge(xs, right)..push(x)
      }
    }
  }
  let len = arr.length();
  guard len > 1 else { return arr.to_array() }
  let mid = len / 2;
  let left = merge_sort2(arr[:mid]);
  let right = merge_sort2(arr[mid:]);
  merge(left, right);
}

///|
test "benchmark" {
  // Generate a large random array for benchmarking
  let rand = @random.Rand::new()
  let size = 1000
  let bench = @bench.Bench::new()
  bench.bench(
    name="merge_sort (imperative)",
    fn() {
      let arr = Array::makei(size, fn(_i) { rand.int() })
      merge_sort(arr)
      bench.keep(arr)
    },
    count=10,
  )
  bench.bench(
    name="merge_sort2 (functional)",
    fn() {
      let arr = Array::makei(size, fn(_i) { rand.int() })
      let result = merge_sort2(arr[:])
      bench.keep(result)
    },
    count=10,
  )
  println(bench.dump_summaries())
}
