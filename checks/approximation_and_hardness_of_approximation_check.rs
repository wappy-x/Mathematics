// Approximation and its limits -- the check behind the card.  std only.
// A care home's week has 8 shifts, lengths in hours; a staff member works at
// most CAP = 40.  Fewest staff covering every shift is bin packing.  Three roads
// to the exact answer, then the gap reduction.
const WEEK: [u64; 8] = [12, 12, 12, 10, 10, 10, 8, 6];
const NOSPLIT: [u64; 7] = [12, 12, 12, 12, 12, 10, 10];
const CAP: u64 = 40;

fn first_fit(shifts: &[u64], cap: u64) -> Vec<Vec<u64>> {
    let mut rows: Vec<Vec<u64>> = Vec::new(); // each shift to the first person with room
    for &s in shifts {
        match rows.iter_mut().find(|r| r.iter().sum::<u64>() + s <= cap) {
            Some(r) => r.push(s),
            None => rows.push(vec![s]),
        }
    }
    rows
}

fn ffd(shifts: &[u64], cap: u64) -> Vec<Vec<u64>> {
    let mut v = shifts.to_vec(); // first fit, longest shift first
    v.sort_by(|a, b| b.cmp(a));
    first_fit(&v, cap)
}

fn fewest_exact(xs: &[u64], cap: u64) -> usize {
    let n = xs.len(); // road 1: best plan over every group of shifts
    let full = (1usize << n) - 1;
    let mut tot = vec![0u64; full + 1];
    for m in 1..=full {
        let low = m & m.wrapping_neg();
        tot[m] = tot[m ^ low] + xs[low.trailing_zeros() as usize];
    }
    let mut best = vec![n + 1; full + 1];
    best[0] = 0;
    for m in 1..=full {
        let low = m & m.wrapping_neg();
        let rest = m ^ low;
        let mut sub = rest;
        loop {
            let g = sub | low; // every group holding the lowest shift left
            if tot[g] <= cap && best[m ^ g] + 1 < best[m] {
                best[m] = best[m ^ g] + 1;
            }
            if sub == 0 { break; }
            sub = (sub - 1) & rest;
        }
    }
    best[full]
}

fn split_by_subsets(xs: &[u64]) -> Option<Vec<u64>> {
    let t: u64 = xs.iter().sum(); // road 2: try all 2^n groups for exactly half
    for m in 0..(1usize << xs.len()) {
        let g: Vec<u64> = (0..xs.len()).filter(|i| m >> i & 1 == 1).map(|i| xs[i]).collect();
        if 2 * g.iter().sum::<u64>() == t { return Some(g); }
    }
    None
}

fn split_by_table(xs: &[u64]) -> (bool, u64) {
    let t: u64 = xs.iter().sum(); // road 3: which totals can a group reach?
    if t % 2 == 1 { return (false, 0); }
    let h = (t / 2) as usize;
    let (mut reach, mut cells) = (vec![false; h + 1], 0u64);
    reach[0] = true;
    for &x in xs {
        let x = x as usize;
        let mut s = h;
        while s >= x && s >= 1 {
            cells += 1;
            reach[s] = reach[s] || reach[s - x];
            s -= 1;
        }
    }
    (reach[h], cells)
}

fn ffd_ceiling(k: usize) -> usize { (11 * k + 6) / 9 } // proved ceiling on FFD's staff

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn draw(state: &mut u64, n: usize, lo: u64, hi: u64) -> Vec<u64> {
    (0..n).map(|_| lo + splitmix(state) % (hi - lo + 1)).collect()
}

fn join(v: &[u64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn ceil_div(a: u64, b: u64) -> u64 { (a + b - 1) / b }

fn main() {
    let rows = ffd(&WEEK, CAP);
    let opt = fewest_exact(&WEEK, CAP);
    let half = split_by_subsets(&WEEK).unwrap();
    let (yes, cells) = split_by_table(&WEEK);
    let total: u64 = WEEK.iter().sum();
    println!("week, hours {} total {}", join(&WEEK), total);
    println!("floor: total / cap, rounded up {}", ceil_div(total, CAP));
    let loads: Vec<u64> = rows.iter().map(|r| r.iter().sum()).collect();
    println!("FFD staff loads {} -> staff {}", join(&loads), rows.len());
    for (i, r) in rows.iter().enumerate() { println!("  FFD person {} {}", i + 1, join(r)); }
    let mut other = WEEK.to_vec();
    for x in &half { let p = other.iter().position(|y| y == x).unwrap(); other.remove(p); }
    println!("exact fewest, all groups {}", opt);
    println!("split by all 256 subsets {} | {}", join(&half), join(&other));
    println!("split by table {} cells {}", py(yes), cells);
    assert!(opt == 2 && yes && 2 * half.iter().sum::<u64>() == total && rows.len() == 3 && loads == vec![36, 38, 6]);
    assert!(ffd(&[12, 12, 12, 10, 10, 10, 8, 4], CAP).len() == 2); // a 4h shift fills 36 to exactly 40
    assert!(rows.len() <= 2 * opt && rows.len() <= ffd_ceiling(opt));
    println!("FFD/fewest {:.3} First Fit ceiling 2*OPT {} FFD ceiling {}",
             rows.len() as f64 / opt as f64, 2 * opt, ffd_ceiling(opt));
    assert!((1..=1000).all(|k| 2 * ffd_ceiling(k) <= 3 * k));
    println!("FFD ceiling <= 1.5*OPT for OPT 1 to 1000: True");
    let raw: Vec<String> = [1.0f64, 2.0, 3.0].iter().map(|k| format!("{:.3}", (11.0 * k + 6.0) / 9.0)).collect();
    println!("FFD ceiling before rounding down, OPT 1 2 3: {} | 1.5*OPT 1.5 3.0 4.5", raw.join(" "));
    let (n_opt, n_yes) = (fewest_exact(&NOSPLIT, CAP), split_by_subsets(&NOSPLIT));
    let n_cells = split_by_table(&NOSPLIT);
    let ntot: u64 = NOSPLIT.iter().sum();
    println!("no-split week {} total {}", join(&NOSPLIT), ntot);
    println!("  floor {} exact fewest {} FFD {} split {} {}", ceil_div(ntot, CAP), n_opt,
             ffd(&NOSPLIT, CAP).len(), py(n_yes.is_some()), py(n_cells.0));
    assert!(n_opt == 3 && n_yes.is_none() && !n_cells.0);
    let mut state: u64 = 2026;
    let mut seen = [0u32; 2];
    for _ in 0..300 { // gap reduction: numbers -> rota with cap = half the total
        let mut xs = draw(&mut state, 7, 1, 30);
        let s: u64 = xs.iter().sum();
        xs[6] += s % 2;
        let t: u64 = xs.iter().sum();
        let k = fewest_exact(&xs, t / 2);
        let (by_table, by_subsets) = (split_by_table(&xs).0, split_by_subsets(&xs).is_some());
        assert!(by_table == by_subsets && (k == 2) == by_table && k >= 2);
        seen[by_table as usize] += 1;
    }
    println!("reduction, 300 number lists: yes -> fewest 2: {} no -> fewest >= 3: {}", seen[1], seen[0]);
    let (mut worst_ff, mut worst_ffd, mut ffd_miss) = (0.0f64, 0.0f64, 0);
    for _ in 0..400 { // random weeks: the ratios proved, against the exact fewest
        let xs = draw(&mut state, 8, 4, 12);
        let (k, a, b) = (fewest_exact(&xs, CAP), first_fit(&xs, CAP).len(), ffd(&xs, CAP).len());
        assert!(a <= 2 * k && b <= ffd_ceiling(k) && b >= k);
        worst_ff = worst_ff.max(a as f64 / k as f64);
        worst_ffd = worst_ffd.max(b as f64 / k as f64);
        if b > k { ffd_miss += 1; }
    }
    println!("400 random weeks: worst First Fit {:.3} worst FFD {:.3} FFD above fewest {}",
             worst_ff, worst_ffd, ffd_miss);
    let ten: Vec<u64> = (0..10).flat_map(|_| WEEK.iter().copied()).collect();
    let big = ffd(&ten, CAP);
    let plan: Vec<Vec<u64>> = (0..20).map(|i| if i % 2 == 0 { half.clone() } else { other.clone() }).collect();
    let mut a: Vec<u64> = plan.iter().flatten().copied().collect();
    let mut b = ten.clone(); a.sort(); b.sort();
    assert!(a == b && plan.iter().all(|r| r.iter().sum::<u64>() <= CAP));
    println!("ten weeks: floor {} split plan {} FFD {} ratio {:.3} FFD ceiling {}", total * 10 / CAP,
             plan.len(), big.len(), big.len() as f64 / plan.len() as f64, ffd_ceiling(plan.len()));
    let h30: f64 = (1..=30).map(|j| 1.0 / j as f64).sum();
    println!("set cover, 30 shifts: H(30) {:.3} ln 30 {:.3} vertex cover floor sqrt 2 {:.3}",
             h30, 30f64.ln(), 2f64.sqrt());
    let tries: [(&str, Vec<u64>, u64); 3] = [("try 6h -> 4h", vec![12, 12, 12, 10, 10, 10, 8, 4], CAP),
        ("try cap 41", WEEK.to_vec(), 41), ("try 12h -> 11h", vec![11, 12, 12, 10, 10, 10, 8, 6], CAP)];
    for (name, xs, cap) in tries.iter() {
        println!("{} total {} exact fewest {} FFD {}", name, xs.iter().sum::<u64>(),
                 fewest_exact(xs, *cap), ffd(xs, *cap).len());
    }
    println!("ALL CHECKS PASS");
}
