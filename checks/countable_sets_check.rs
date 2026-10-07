// Countable sets -- the same check as countable_sets_check.py, in Rust.  No crates.  The
// hotel desk queues the integers 0, 1, -1, 2, -2, ..., then the positive fractions off the
// grid of top over bottom, walked along the diagonals, repeats skipped.  Rooms found twice.
use std::collections::HashSet;
fn hcf(mut a: i64, mut b: i64) -> i64 { while b != 0 { let t = a % b; a = b; b = t; } a }
fn guests(n: i64) -> Vec<i64> { (1..=n).map(|r| if r == 1 { 0 } else if r % 2 == 0 { r / 2 } else { (1 - r) / 2 }).collect() }
fn room_of(k: i64) -> i64 { if k == 0 { 1 } else if k > 0 { 2 * k } else { 1 - 2 * k } }
fn queue(rooms: usize, skip: bool) -> Vec<String> {   // 0 first, then the diagonals
    let mut q = vec![String::from("0")];
    for h in 2..rooms + 2 { for t in 1..h { if !skip || hcf(t as i64, (h - t) as i64) == 1 {
        q.push(format!("{}/{}", t, h - t)); } } }
    q.truncate(rooms); q
}
fn room_by_counting(top: i64, bottom: i64) -> i64 {   // second road: count the earlier diagonals
    let mut n = 1;
    for h in 2..top + bottom { for t in 1..h { if hcf(t, h - t) == 1 { n += 1; } } }
    for t in 1..=top { if hcf(t, top + bottom - t) == 1 { n += 1; } }
    n
}
fn at(q: &[String], f: &str) -> usize { q.iter().position(|x| x == f).unwrap() + 1 }
fn main() {
    let (ints, fracs) = (guests(9), queue(10, true));
    let (kept, nozero, long) = (queue(7, false), queue(4, true)[1..].to_vec(), queue(60, true));
    let grid: Vec<String> = (1..4).map(|t| (1..4).map(|b| format!("{}/{}", t, b)).collect::<Vec<_>>().join(" ")).collect();
    let show = |v: &[i64]| v.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(" ");
    println!("integer queue, rooms 1 to 9    {}", show(&ints));
    println!("those integers, read back      {}", show(&ints.iter().map(|k| room_of(*k)).collect::<Vec<_>>()));
    println!("grid rows 1 to 3               {}", grid.join(" | "));
    println!("fraction queue, rooms 1 to 10  {}", fracs.join(" "));
    println!("1/2 is in room {} and 2/1 in room {}, both agreed by counting the diagonals", at(&fracs, "1/2"), at(&fracs, "2/1"));
    println!("repeats left in, 2/2 takes room {}; the 0 dropped, 1/2 takes room {} and 2/1 room {}", at(&kept, "2/2"), at(&nozero, "1/2"), at(&nozero, "2/1"));
    let distinct: HashSet<&String> = long.iter().collect();
    println!("the first 60 rooms hold {} different guests", distinct.len());
    assert!(ints == vec![0, 1, -1, 2, -2, 3, -3, 4, -4] && (1..=9i64).eq(ints.iter().map(|k| room_of(*k))));
    assert!(fracs == vec!["0", "1/1", "1/2", "2/1", "1/3", "3/1", "1/4", "2/3", "3/2", "4/1"] && kept[5] == "2/2");
    assert!(distinct.len() == 60 && long.iter().enumerate().skip(1).all(|(i, f)| { let p: Vec<i64> =
        f.split('/').map(|x| x.parse().unwrap()).collect(); room_by_counting(p[0], p[1]) == i as i64 + 1 }));
    println!("ALL CHECKS PASS");
}
