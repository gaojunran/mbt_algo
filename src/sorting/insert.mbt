fn insert_sort(arr: Array[Int]) -> Unit {
    for i in 0..<arr.length() {
      let key = arr[i];
      // 从这张牌左面开始，i 这个位置是一个空位，让左面比它大的牌依次往右移动，直到找到一个比它小的牌或者没有牌了
      let mut j = i - 1;
      while j >= 0 && arr[j] > key {
        arr[j + 1] = arr[j];
        j = j - 1;
      }
      arr[j + 1] = key;
    }
}

fn insert_sort2(arr: Array[Int]) -> Unit {
    for i in 1..<arr.length() {
      let key = arr[i];
      // j 表示这个空位
      let j = for j = i; j > 0 && arr[j - 1] > key; j = j - 1 {
        arr[j] = arr[j - 1];
      } nobreak { j }
      arr[j] = key;
    }
}

///|
test {
  let arr = [5, 2, 4, 6, 1, 3]
  insert_sort(arr)
  assert_eq(arr, [1, 2, 3, 4, 5, 6])
}



