// Dynamic programming and the Bellman equation -- the same check as the Python, in Rust.  No
// crates.  A three-leg trip along a river: before each leg the car is on the north bank (0)
// or the south bank (1), and it stays on that bank's toll road (0) or takes the bridge first (1).
type Legs = Vec<[[u64; 2]; 2]>;          // toll[k][bank][choice], dollars
const MOVE: [&str; 2] = ["stay", "cross"];

type Table = (Vec<[u64; 2]>, Vec<[usize; 2]>, usize, Vec<[[u64; 2]; 2]>);  // values, plan, comparisons, candidates
fn backward(toll: &Legs) -> Table {       // road one: the Bellman equation, finish to start
    let n = toll.len();
    let (mut value, mut plan, mut comps, mut cand): Table =
        (vec![Default::default(); n + 1], vec![Default::default(); n], 0, vec![Default::default(); n]);
    for k in (0..n).rev() {
        for x in 0..2 {
            let a = [toll[k][x][0] + value[k + 1][x], toll[k][x][1] + value[k + 1][x ^ 1]];
            cand[k][x] = a;
            plan[k][x] = if a[0] <= a[1] { 0 } else { 1 };
            comps += 1;                          // one comparison
            value[k][x] = a[plan[k][x]];
        }
    }
    (value, plan, comps, cand)
}

fn brute(toll: &Legs, start: usize) -> (u64, Vec<u64>) {    // road two: price every whole route
    let n = toll.len();
    let mut costs = Vec::new();
    for code in 0..(1usize << n) {
        let (mut side, mut cost) = (start, 0);
        for k in 0..n {
            let c = code >> (n - 1 - k) & 1;
            (cost, side) = (cost + toll[k][side][c], side ^ c);
        }
        costs.push(cost);
    }
    (*costs.iter().min().unwrap(), costs)
}
fn join(v: &[u64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" + ") }

fn main() {
    let toll: Legs = Vec::from([[[11, 16], [14, 13]], [[19, 22], [12, 15]], [[21, 24], [19, 20]]]);
    let (value, plan, comps, cand) = backward(&toll);
    for (k, leg) in toll.iter().enumerate() {
        println!("leg {} tolls: north stay {}, cross {}; south stay {}, cross {}", k + 1, leg[0][0], leg[0][1], leg[1][0], leg[1][1]);
    }
    println!("V_3(N) = 0, V_3(S) = 0: nothing left to pay");
    for k in (0..3).rev() {
        let ([a, b], [c, d]) = (cand[k][0], cand[k][1]);
        println!("V_{}(N) = min({}, {}) = {}, V_{}(S) = min({}, {}) = {}; choose {} / {}",
                 k, a, b, value[k][0], k, c, d, value[k][1], MOVE[plan[k][0]], MOVE[plan[k][1]]);
    }
    let (mut side, mut gside, mut paid, mut moves, mut greedy) = (0usize, 0usize, Vec::new(), Vec::new(), 0);
    for (k, leg) in toll.iter().enumerate() {        // follow the plan; alongside, mistake 1
        let (c, g) = (plan[k][side], if leg[gside][0] <= leg[gside][1] { 0 } else { 1 });
        moves.push(MOVE[c]); paid.push(leg[side][c]); side ^= c;
        greedy += leg[gside][g]; gside ^= g;
    }
    let blind: Vec<u64> = toll.iter().map(|l| *l.iter().flatten().min().unwrap()).collect();  // mistake 2
    let ((best_n, costs_n), (best_s, _)) = (brute(&toll, 0), brute(&toll, 1));
    let walked: u64 = paid.iter().sum();
    println!("backward induction: {} comparisons; cheapest from N {}, from S {}", comps, value[0][0], value[0][1]);
    println!("plan from N: {}; tolls {} = {}", moves.join(", "), join(&paid), walked);
    println!("brute force from N: {} routes {:?}, {} comparisons, cheapest {}; from S {}", costs_n.len(), costs_n, costs_n.len() - 1, best_n, best_s);
    println!("mistake 1, cheapest toll each leg with no look ahead: {}", greedy);
    println!("mistake 2, cheapest toll per leg ignoring the bank: {} = {}, no such route", join(&blind), blind.iter().sum::<u64>());
    println!("drop 'costs add up', 15 dollar rebate for north stay, stay, stay: true cheapest {}, table on the bank still {}", best_n.min(costs_n[0] - 15), value[0][0]);
    let mut seed: u64 = 2026;                          // second case: home-made generator, tolls 5 to 29
    let mut rnd = || { seed = (seed * 1103515245 + 12345) % (1 << 31); 5 + seed % 25 };
    let big: Legs = (0..12).map(|_| { let (a, b, c, d) = (rnd(), rnd(), rnd(), rnd()); [[a, b], [c, d]] }).collect();
    let ((bv, _, bc, _), (bb, bcosts)) = (backward(&big), brute(&big, 0));
    println!("{} legs: backward {} comparisons, cheapest {}; brute force {} routes, cheapest {}", big.len(), bc, bv[0][0], bcosts.len(), bb);
    let r: Vec<String> = [3u32, 10, 30].iter().map(|&n| format!("n = {}: {} vs {}", n, 1u64 << n, 2 * n)).collect();
    println!("routes 2^n against comparisons 2n: {}", r.join("; "));
    let s: Vec<String> = [1u32, 3, 6].iter().map(|&d| format!("d = {}: {}", d, 10u64.pow(d))).collect();
    println!("states with d gauges of 10 levels: {}", s.join("; "));
    assert!(value[0][0] == best_n);                  // Bellman against every route, from the north bank
    assert!(value[0][1] == best_s);                  // and from the south bank
    assert!(walked == value[0][0]);                  // the plan's own tolls add up to the value
    assert!(bv[0][0] == bb);                         // 12 legs: 24 comparisons agree with 4096 routes
    println!("ALL CHECKS PASS");
}
