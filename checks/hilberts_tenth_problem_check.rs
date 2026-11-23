// Hilbert's tenth problem -- the check behind the card.  std only, no crates.
// It never tries to decide which equations have whole-number solutions: no
// program can.  It runs the three pieces of the proof that no program can.
// Part 1: x^3 + y^3 + z^3 = k, by a mod 9 proof, by search, and by checking
//         published record solutions by remainders.
// Part 2: a program that reads a machine and writes arithmetic conditions that
//         a few whole numbers pass exactly when they pack a halting run.
// Part 3: Pell's equation forcing an exponential: 2^10 read off a solution.
use std::collections::HashMap;
const B: i64 = 1000;

fn search(k: i64, cube: &HashMap<i64, i64>) -> Vec<(i64, i64, i64)> {
    let mut found = Vec::new(); // every x <= y <= z with |x|, |y|, |z| <= B
    for x in -B..=B {
        for y in x..=B {
            if let Some(&z) = cube.get(&(k - x * x * x - y * y * y)) { if z >= y { found.push((x, y, z)); } }
        }
    }
    found
}

#[derive(Clone, Copy)]
enum Ins { Inc(usize, usize), Dec(usize, usize, usize), Halt }
type Trace = Vec<(usize, [i128; 2])>;

fn run(prog: &[Ins], regs: [i128; 2], cap: usize) -> (Trace, bool) {
    let (mut line, mut regs, mut trace) = (0, regs, Vec::new());
    for _ in 0..=cap {
        trace.push((line, regs));
        match prog[line] {
            Ins::Halt => return (trace, true),
            Ins::Inc(r, j) => { regs[r] += 1; line = j; }
            Ins::Dec(r, j, k) => if regs[r] > 0 { regs[r] -= 1; line = j; } else { line = k; },
        }
    }
    (trace, false)
}

fn pack(prog: &[Ins], trace: &[(usize, [i128; 2])], q: i128) -> (u32, Vec<i128>, [i128; 2]) {
    let mut l = vec![0i128; prog.len()];
    let mut r = [0i128; 2];
    for (t, (ln, rg)) in trace.iter().enumerate() {
        let p = q.pow(t as u32);
        l[*ln] += p; r[0] += rg[0] * p; r[1] += rg[1] * p;
    }
    (trace.len() as u32, l, r)
}

fn conditions(prog: &[Ins], start: [i128; 2], s: u32, q: i128, l: &[i128], r: [i128; 2], fin: [i128; 2]) -> Vec<(String, bool)> {
    let (i_all, h) = ((q.pow(s) - 1) / (q - 1), q / 2);
    let mut out = vec![("one line per step".to_string(), l.iter().sum::<i128>() == i_all),
        ("starts at line 0".to_string(), l[0] % q == 1),
        ("halts at the last step only".to_string(), l[l.len() - 1] == q.pow(s - 1))];
    for i in 0..prog.len() { out.push((format!("L{} digits are 0 or 1", i), l[i] & i_all == l[i])); }
    let (mut inc, mut dec) = ([0i128; 2], [0i128; 2]);
    for (i, ins) in prog.iter().enumerate() {
        match *ins {
            Ins::Inc(rr, j) => {
                out.push((format!("line {} leads to {}", i, j), (q * l[i]) & l[j] == q * l[i]));
                inc[rr] += l[i];
            }
            Ins::Dec(rr, j, k) => {
                let nz = l[i] & (l[j] / q); // steps that took the nonzero branch
                out.push((format!("line {} leads to {} or {}", i, j, k), (q * l[i]) & (l[j] + l[k]) == q * l[i]));
                out.push((format!("line {} tests r{} for zero", i, rr), (r[rr] + (h - 1) * l[i]) & (h * l[i]) == h * nz));
                dec[rr] += nz;
            }
            Ins::Halt => {}
        }
    }
    for rr in 0..2 {
        out.push((format!("r{} digits below Q/2", rr), r[rr] & ((h - 1) * i_all) == r[rr]));
        out.push((format!("r{} steps forward", rr), r[rr] + q.pow(s) * fin[rr] == start[rr] + q * (r[rr] + inc[rr] - dec[rr])));
    }
    out
}

fn failing(c: &[(String, bool)]) -> Vec<String> { c.iter().filter(|x| !x.1).map(|x| x.0.clone()).collect() }

fn pell(a: i128, n: usize) -> (i128, i128) { // x_n + y_n root(a^2 - 1) = (a + root(a^2 - 1))^n
    let (mut x0, mut y0, mut x1, mut y1) = (1i128, 0i128, a, 1i128);
    for _ in 0..n { let (nx, ny) = (2 * a * x1 - x0, 2 * a * y1 - y0); x0 = x1; y0 = y1; x1 = nx; y1 = ny; }
    (x0, y0)
}

fn main() {
    println!("part 1: x^3 + y^3 + z^3 = k");
    let cube: HashMap<i64, i64> = (-B..=B).map(|c| (c * c * c, c)).collect();
    let mut res9: Vec<i64> = (0..9).map(|a| a * a * a % 9).collect();
    res9.sort(); res9.dedup(); let mut hit = [false; 9];
    for p in &res9 { for q in &res9 { for w in &res9 { hit[((p + q + w) % 9) as usize] = true; } } }
    let miss: Vec<i64> = (0..9).filter(|&r| !hit[r as usize]).collect(); assert!(miss == [4, 5], "the mod 9 table must rule out exactly 4 and 5");
    let j = |v: &[i64]| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ");
    println!("cubes mod 9 are only: {}   sums of three cubes mod 9 miss: {}", j(&res9), j(&miss));
    let mut none33 = false;
    for k in [3i64, 4, 6, 29, 33, 42] {
        let f = search(k, &cube);
        let out9 = miss.contains(&(k % 9));
        let tag = if out9 { "ruled out by mod 9" } else { "allowed by mod 9" };
        let best = match f.iter().min_by_key(|t| t.0.abs().max(t.1.abs()).max(t.2.abs())) {
            Some(t) => format!("{} {} {}", t.0, t.1, t.2), None => format!("none up to {}", B) };
        println!("k = {:>2}  {:<18}  triples found: {}  smallest: {}", k, tag, f.len(), best);
        assert!(!(out9 && !f.is_empty()), "search contradicts the mod 9 proof");
        if k == 33 { none33 = f.is_empty(); }
    }
    let record: [(i128, [i128; 3]); 2] = [(33, [8866128975287528, -8778405442862239, -2736111468807040]),
        (42, [-80538738812075974, 80435758145817515, 12602123297335631])];
    let mods: [i128; 3] = [1 << 62, (1 << 62) - 1, (1 << 62) - 3]; // pairwise coprime; product above 9 x 10^55
    for (k, v) in record.iter() {
        let r: Vec<i128> = mods.iter().map(|&m| {
            let c = |x: i128| { let (u, mu) = (x.rem_euclid(m) as u128, m as u128); (u * u % mu * u % mu) as i128 };
            (c(v[0]) + c(v[1]) + c(v[2]) - k).rem_euclid(m) }).collect();
        println!("{} = ({})^3 + ({})^3 + ({})^3   remainders of the difference: {} {} {}", k, v[0], v[1], v[2], r[0], r[1], r[2]);
        assert!(r == vec![0, 0, 0] && v.iter().all(|x| x.abs() < 100_000_000_000_000_000), "record solution fails");
    }

    println!("part 2: a machine run packed into whole numbers");
    let double = [Ins::Dec(0, 1, 3), Ins::Inc(1, 2), Ins::Inc(1, 0), Ins::Halt];
    let forever = [Ins::Inc(0, 0), Ins::Halt];
    let start = [3i128, 0]; // r0 = 3 in, r1 = 0
    let (tr, halted) = run(&double, start, 100);
    let (s, l, r) = pack(&double, &tr, 16);
    let fin = tr[tr.len() - 1].1;
    println!("double, r0 = {}: halts at step {} with r0 = {}, r1 = {}", start[0], s - 1, fin[0], fin[1]);
    let js = |v: Vec<String>| v.join(" ");
    println!("lines by step: {}", js(tr.iter().map(|t| t.0.to_string()).collect()));
    println!("r0 by step:    {}", js(tr.iter().map(|t| t.1[0].to_string()).collect()));
    println!("r1 by step:    {}", js(tr.iter().map(|t| t.1[1].to_string()).collect()));
    println!("base Q = 16, s = {} digits: L0 = {}, L3 = {}, R0 = {}, R1 = {}", s, l[0], l[3], r[0], r[1]);
    let good = conditions(&double, start, s, 16, &l, r, fin);
    println!("conditions written from the program: {}, holding: {}", good.len(), good.iter().filter(|x| x.1).count());
    for c in good.chunks(4) { println!("  {}", c.iter().map(|x| x.0.clone()).collect::<Vec<_>>().join("; ")); }
    assert!(good.iter().all(|x| x.1), "the true run must pass every condition");
    let bad = failing(&conditions(&double, start, s, 16, &l, r, [0, 7]));
    println!("claim r1 ends at 7, fails: {}", bad.join(", "));
    let (s8, l8, r8) = pack(&double, &tr, 8);
    let bad8 = failing(&conditions(&double, start, s8, 8, &l8, r8, fin));
    println!("base Q = 8, fails: {}", bad8.join(", "));
    assert!(bad == vec!["r1 steps forward"] && bad8 == vec!["r1 digits below Q/2"], "tampering must be caught");
    let (tf, hf) = run(&forever, [0, 0], 20);
    let mut fails = 0;
    for n in 1..=20 { // forever's first n steps, packed and tested
        let (sn, ln, rn) = pack(&forever, &tf[..n], 64);
        if !conditions(&forever, [0, 0], sn, 64, &ln, rn, tf[n - 1].1).iter().all(|x| x.1) { fails += 1; }
    }
    println!("forever: {}; packed runs of 1 to 20 steps that fail: {}", if hf { "halts" } else { "still running after 20 steps" }, fails);

    println!("part 3: Pell's equation x^2 - (a^2 - 1) y^2 = 1 forces powers");
    let (mut ys, mut x) = (Vec::new(), 1i128);
    for y in 0..=10000i128 { // brute force on a = 3: x^2 - 8y^2 = 1
        while x * x < 1 + 8 * y * y { x += 1; }
        if x * x == 1 + 8 * y * y { ys.push((x, y)); }
    }
    println!("a = 3, search y <= 10000: {}", js(ys.iter().map(|p| format!("({}, {})", p.0, p.1)).collect()));
    assert!(ys.iter().enumerate().all(|(n, p)| *p == pell(3, n)), "recurrence and search disagree");
    for (a, label) in [(300i128, "a = 300"), (100, "wrong: a = 100")] {
        let (x10, y10) = pell(a, 10); let m = 4 * a - 5;
        println!("{}: d = {}, y_10 = {}, y_10 mod {} = {}, (x_10 - {} y_10) mod {} = {}", label, a * a - 1, y10, a - 1, y10 % (a - 1), a - 2, m, (x10 - (a - 2) * y10).rem_euclid(m));
    }
    let mut p = 1i128; for _ in 0..10 { p *= 2; }
    println!("2^10 by repeated doubling: {}", p);
    let (x10, y10) = pell(300, 10);
    assert!((x10 - 298 * y10).rem_euclid(1195) == p, "Pell remainder must equal 2^10");
    for n in 0..12usize { for k in 1..6i128 {
        let (xn, yn) = pell(300, n);
        assert!((xn - (300 - k) * yn - k.pow(n as u32)).rem_euclid(600 * k - k * k - 1) == 0, "the Pell power congruence");
    } assert!(pell(300, n).1 % 299 == n as i128, "y_n remembers n"); }
    assert!(halted && !hf && none33 && fails == 20, "33 below 1000 and the capped forever machine");
    println!("ALL CHECKS PASS");
}
