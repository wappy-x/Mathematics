// Homomorphisms and isomorphisms -- the same check as the Python, in Rust.  No
// crates.  The 24-hour clock is sent onto the 12-hour clock by f(x) = x mod 12,
// and the tile's four quarter turns are matched against the 4-clock.  Every
// number quoted on the card is printed here, and each answer is reached twice.
const DAY: i64 = 24;
const HALF: i64 = 12;
const QUARTERS: usize = 4;
const QUARTER: [usize; 4] = [1, 2, 3, 0];  // a quarter turn sends corners 0 1 2 3 here
fn add_then_send(a: i64, b: i64) -> i64 { ((a + b) % DAY) % HALF }        // road one
fn send_then_add(a: i64, b: i64) -> i64 { (a % HALF + b % HALF) % HALF }  // road two
fn after(p: &[usize], q: &[usize]) -> Vec<usize> { (0..QUARTERS).map(|i| p[q[i]]).collect() }
fn row<T: std::fmt::Display>(v: &[T]) -> String {
    let parts: Vec<String> = v.iter().map(|x| x.to_string()).collect();
    format!("[{}]", parts.join(", "))
}
fn agreeing_pairs(g: &dyn Fn(i64) -> i64, ring: i64) -> usize {  // pairs a map gets right
    let mut n = 0;
    for a in 0..DAY { for b in 0..DAY {
        if g((a + b) % DAY) == (g(a) + g(b)) % ring { n += 1; }
    } }
    n
}
fn turn_order(t: &[usize], home: &[usize]) -> usize {   // turns until the tile is home
    let (mut p, mut n) = (t.to_vec(), 1);
    while p != home { p = after(&p, t); n += 1; }
    n
}
fn unit_order(u: i64) -> usize {        // multiplications by u, mod 8, until back to 1
    let (mut v, mut n) = (u, 1);
    while v != 1 { v = v * u % 8; n += 1; }
    n
}
fn main() {
    let (mut road_one, mut road_two) = (Vec::new(), Vec::new());
    for a in 0..DAY { for b in 0..DAY {
        road_one.push(add_then_send(a, b));
        road_two.push(send_then_add(a, b));
    } }
    let pairs = road_one.len();
    let same = (0..pairs).filter(|&i| road_one[i] == road_two[i]).count();
    let kernel: Vec<i64> = (0..DAY).filter(|x| x % HALF == 0).collect();
    let shows_11: Vec<i64> = (0..DAY).filter(|x| x % HALF == 11).collect();
    let mut reached: Vec<i64> = (0..DAY).map(|x| x % HALF).collect();
    reached.sort(); reached.dedup();
    let shifted = agreeing_pairs(&|x| (x + 1) % HALF, HALF);
    let tenner = agreeing_pairs(&|x| x % 10, 10);
    let (half, id) = (after(&QUARTER, &QUARTER), (0..QUARTERS).collect::<Vec<usize>>());
    let turns: Vec<Vec<usize>> = vec![id, QUARTER.to_vec(), half.clone(), after(&half, &QUARTER)];
    let by_turning: Vec<Vec<usize>> = (0..QUARTERS).map(|a| (0..QUARTERS).map(|b| {
        let c = after(&turns[a], &turns[b]);
        turns.iter().position(|t| *t == c).unwrap()
    }).collect()).collect();
    let by_clock: Vec<Vec<usize>> = (0..QUARTERS)
        .map(|a| (0..QUARTERS).map(|b| (a + b) % QUARTERS).collect()).collect();
    let cells: usize = (0..QUARTERS)
        .map(|a| (0..QUARTERS).filter(|&b| by_turning[a][b] == by_clock[a][b]).count()).sum();
    let turn_orders: Vec<usize> = turns.iter().map(|t| turn_order(t, &turns[0])).collect();
    let unit_orders: Vec<usize> = [1, 3, 5, 7].iter().map(|&u| unit_order(u)).collect();
    let lists = |v: &Vec<Vec<usize>>| v.iter().map(|r| row(r)).collect::<Vec<String>>().join(" ");
    println!("the 24-hour clock onto the 12-hour clock, f(x) = x mod {}", HALF);
    println!("add then send against send then add: {} of {} pairs agree", same, pairs);
    println!("23 and 5: add first gives {}, send first gives {}", add_then_send(23, 5), send_then_add(23, 5));
    println!("kernel, the readings sent to 0: {}, size {}", row(&kernel), kernel.len());
    println!("the two 24-hour readings that both show 11: {}", row(&shows_11));
    println!("readings reached: {}, and {} / {} = {}", reached.len(), DAY, kernel.len(), DAY / kernel.len() as i64);
    println!("wrong map, shift by one, x -> (x + 1) mod 12: {} of {} pairs agree", shifted, pairs);
    println!("wrong map, onto a 10-clock, x -> x mod 10: {} of {} pairs agree", tenner, pairs);
    println!("the tile's four turns, where corners 0 1 2 3 land: {}", lists(&turns));
    println!("turn a then turn b, counted in quarter turns:      {}", lists(&by_turning));
    println!("a + b on the 4-clock:                              {}", lists(&by_clock));
    println!("the two tables agree in {} of 16 cells", cells);
    println!("quarter turns to get home, the four turns: {}", row(&turn_orders));
    println!("steps to get home, 1 3 5 7 multiplied mod 8: {}", row(&unit_orders));
    assert!(road_one == road_two && same == pairs);
    assert!(kernel == vec![0, 12] && shows_11 == vec![11, 23] && reached.len() as i64 == DAY / kernel.len() as i64);
    assert!(by_turning == by_clock && cells == 16);
    assert!(shifted == 0 && tenner == 300 && turn_orders == vec![1, 4, 2, 4] && unit_orders == vec![1, 2, 2, 2]);
    println!("ALL CHECKS PASS");
}
