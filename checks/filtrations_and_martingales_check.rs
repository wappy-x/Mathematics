// Filtrations and martingales -- the same check as the Python, in Rust.  No
// crates.  Exact fractions by hand on small integers.  Part 1: a poker night of
// three fair even-money hands, $100 to start, stakes $20, then $20 after a
// first win or $40 after a first loss, then $10: the filtration set by set and
// the forecast M_n = E[Y | F_n] by three roads.  Part 2: the loaded die rolled
// three times and its density process Z_n by three roads.  Part 3: SplitMix64
// poker nights, seed 2026.  Part 4: the mistakes, computed.
use std::collections::BTreeSet;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i64, d: i64 }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Fr { n: s * n / g, d: s * d / g } }
fn add(a: Fr, b: Fr) -> Fr { fr(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Fr, b: Fr) -> Fr { fr(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n * b.n, a.d * b.d) }
fn div(a: Fr, b: Fr) -> Fr { fr(a.n * b.d, a.d * b.n) }
fn int(k: i64) -> Fr { fr(k, 1) }
fn lt(a: Fr, b: Fr) -> bool { a.n * b.d < b.n * a.d }       // denominators kept positive
fn fl(a: Fr) -> f64 { a.n as f64 / a.d as f64 }
fn fmt(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}", fl(a)) } }
fn sum(v: impl Iterator<Item = Fr>) -> Fr { v.fold(int(0), add) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: Vec<String>) -> String { v.join(", ") }

type Hist = [bool; 3];                                   // true = a win; WWW first
fn hists() -> Vec<Hist> { (0..8).map(|i| [i & 4 == 0, i & 2 == 0, i & 1 == 0]).collect() }
fn forward(h: &Hist) -> Vec<Fr> {                        // road 3: add up the stakes
    let mut b = vec![int(100)];
    for n in 0..3 {
        let stake = if n == 0 { 20 } else if n == 2 { 10 } else if h[0] { 20 } else { 40 };
        let last = *b.last().unwrap();
        b.push(add(last, int(if h[n] { stake } else { -stake })));
    }
    b
}
fn cell_avg(hs: &[Hist], x: &[Fr], i: usize, n: usize) -> Fr {   // road 1: average over the cell
    let cell: Vec<usize> = (0..8).filter(|&j| hs[j][..n] == hs[i][..n]).collect();
    div(sum(cell.iter().map(|&j| x[j])), int(cell.len() as i64))
}
fn fold_back(hs: &[Hist], x: &[Fr]) -> Vec<Vec<Fr>> {  // road 2: two children at a time
    let mut out = vec![x.to_vec(); 4];
    for n in (0..3).rev() {
        let next = out[n + 1].clone();
        for i in 0..8 {
            let w = (0..8).find(|&j| hs[j][..n] == hs[i][..n] && hs[j][n]).unwrap();
            let l = (0..8).find(|&j| hs[j][..n] == hs[i][..n] && !hs[j][n]).unwrap();
            out[n][i] = div(add(next[w], next[l]), int(2));
        }
    }
    out
}
fn sigma(hs: &[Hist], n: usize) -> BTreeSet<u32> {     // F_n: every union of time-n cells
    let cells: Vec<u32> = (0..8).map(|i| (0..8).filter(|&j| hs[j][..n] == hs[i][..n]).map(|j| 1u32 << j).sum())
        .collect::<BTreeSet<u32>>().into_iter().collect();
    (0..1u32 << cells.len()).map(|s| (0..cells.len()).filter(|k| s >> k & 1 == 1).map(|k| cells[k]).sum()).collect()
}

struct Rng(u64);
impl Rng {                                               // SplitMix64; 53 bits into [0, 1)
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let hs = hists();
    let y: Vec<Fr> = hs.iter().map(|h| forward(h)[3]).collect();
    let ahead: Vec<Fr> = y.iter().map(|&v| int(lt(int(100), v) as i64)).collect();
    let m: Vec<Vec<Fr>> = (0..4).map(|n| (0..8).map(|i| cell_avg(&hs, &y, i, n)).collect()).collect();
    let a: Vec<Vec<Fr>> = (0..4).map(|n| (0..8).map(|i| cell_avg(&hs, &ahead, i, n)).collect()).collect();
    let (mb, ab) = (fold_back(&hs, &y), fold_back(&hs, &ahead));
    let fs: Vec<BTreeSet<u32>> = (0..4).map(|n| sigma(&hs, n)).collect();
    let nested = (0..3).all(|n| fs[n].is_subset(&fs[n + 1]));
    let closed = fs.iter().all(|s| s.iter().all(|&x| s.contains(&(255 ^ x)) && s.iter().all(|&z| s.contains(&(x | z)))));
    let adapted = |x: &[Fr], n: usize| x.iter().all(|&c| fs[n].contains(&(0..8).filter(|&j| x[j] == c).map(|j| 1u32 << j).sum()));
    let lab = |h: &Hist| h.iter().map(|&w| if w { 'W' } else { 'L' }).collect::<String>();
    println!("sets in F_0, F_1, F_2, F_3: {} | each inside the next: {} | closed: {}",
             join(fs.iter().map(|s| s.len().to_string()).collect()), yn(nested), yn(closed));
    println!("history | Y | M_0 M_1 M_2 M_3 | ahead forecast A_0 A_1 A_2 A_3");
    for i in 0..8 {
        println!("{} | {} | {} | {}", lab(&hs[i]), fmt(y[i]), (0..4).map(|n| fmt(m[n][i])).collect::<Vec<_>>().join(" "),
                 (0..4).map(|n| fmt(a[n][i])).collect::<Vec<_>>().join(" "));
    }
    let nodes: Vec<String> = (0..4).map(|n| {
        let mut v: Vec<i64> = m[n].iter().map(|x| x.n).collect::<BTreeSet<_>>().into_iter().collect();
        v.reverse();
        format!("{}: {}", n, join(v.iter().map(|k| k.to_string()).collect()))
    }).collect();
    println!("figure, nodes (hand: $): {}", nodes.join("; "));
    println!("figure, svg x = 50 + 90 x hand: {}", join((0..4).map(|k| (50 + 90 * k).to_string()).collect()));
    println!("figure, svg y = 220 - 1.4 x (bankroll - 20) for $150, $100, $30: {}",
             join([150, 100, 30].iter().map(|&v| fmt(sub(int(220), mul(fr(14, 10), int(v - 20))))).collect()));
    let mean8 = |x: &[Fr]| div(sum(x.iter().copied()), int(8));
    println!("E[M_n] for n = 0..3: {} | E[A_n]: {}", join(m.iter().map(|x| fmt(mean8(x))).collect()),
             join(a.iter().map(|x| fmt(mean8(x))).collect()));
    println!("adapted to F_n: M_n {} | M_(n+1), read at time n: {}", yn((0..4).all(|n| adapted(&m[n], n))),
             yn((0..3).any(|n| adapted(&m[n + 1], n))));

    let p1 = [fr(1, 6); 6];
    let q1 = [fr(1, 10), fr(1, 10), fr(1, 10), fr(1, 10), fr(2, 10), fr(4, 10)];
    let rate: Vec<Fr> = (0..6).map(|f| div(q1[f], p1[f])).collect();
    let ends = |pre: &[usize]| -> Vec<Vec<usize>> {
        let k = 3 - pre.len();
        (0..6usize.pow(k as u32)).map(|c| { let mut e = pre.to_vec(); let mut c = c;
            let mut tail = vec![0; k]; for t in (0..k).rev() { tail[t] = c % 6; c /= 6; } e.extend(tail); e }).collect()
    };
    let prob = |w: &[Fr], e: &[usize]| e.iter().fold(int(1), |s, &f| mul(s, w[f]));
    let z_prod = |pre: &[usize]| prob(&rate, pre);                                  // road B: rates multiplied
    let z_ratio = |pre: &[usize]| div(sum(ends(pre).iter().map(|e| prob(&q1, e))), sum(ends(pre).iter().map(|e| prob(&p1, e)))); // road A
    let z_cond = |pre: &[usize]| div(sum(ends(pre).iter().map(|e| z_prod(e))), int(ends(pre).len() as i64)); // road C
    let rolls = ends(&[]);
    let pre: BTreeSet<Vec<usize>> = rolls.iter().flat_map(|r| (0..4).map(move |n| r[..n].to_vec())).collect();
    println!("P per history: {} | loaded die Q: {} | rates dQ/dP: {}", fmt(fr(1, 8)),
             join(q1.iter().map(|&q| fmt(q)).collect()), join(rate.iter().map(|&r| fmt(r)).collect()));
    let roads_z = pre.iter().all(|p| z_ratio(p) == z_prod(p) && z_prod(p) == z_cond(p));
    let step_z = pre.iter().filter(|p| p.len() < 3).all(|p| div(sum((0..6).map(|f| { let mut e = p.clone(); e.push(f); z_prod(&e) })), int(6)) == z_prod(p));
    let ez: Vec<Fr> = (0..4).map(|n| div(sum(rolls.iter().map(|r| z_prod(&r[..n]))), int(216))).collect();
    println!("density process: {} cells; Q(cell)/P(cell) = product of rates = E_P[Z_3 | F_n]: {}", pre.len(), yn(roads_z));
    println!("one-step average of Z_(n+1) over the next roll is Z_n: {} | E_P[Z_n] for n = 0..3: {}", yn(step_z),
             join(ez.iter().map(|&z| fmt(z)).collect()));
    for (l, path) in [("6,6,6", [5, 5, 5]), ("6,1,5", [5, 0, 4]), ("1,1,1", [0, 0, 0])] {
        println!("figure, Z_n on rolls {}: {}", l, join((0..4).map(|n| format!("{:.2}", fl(z_prod(&path[..n])))).collect()));
    }
    let below = rolls.iter().filter(|r| lt(z_prod(r), int(1))).count();
    println!("rolls with Z_3 below 1: {} of 216 = {:.4} under P", below, below as f64 / 216.0);

    let n = 200000usize;
    let mut rng = Rng(2026);
    let (mut cnt, mut sm, mut sq, mut up) = ([0usize; 2], [0.0f64; 2], [0.0f64; 2], 0usize);
    for _ in 0..n {
        let h: Hist = [rng.uniform() < 0.5, rng.uniform() < 0.5, rng.uniform() < 0.5];
        let i = hs.iter().position(|g| *g == h).unwrap();
        let (v, k) = (fl(y[i]), if h[0] { 0 } else { 1 });
        cnt[k] += 1; sm[k] += v; sq[k] += v * v; if v > 100.0 { up += 1; }
    }
    let cm: Vec<f64> = (0..2).map(|k| sm[k] / cnt[k] as f64).collect();
    let se: Vec<f64> = (0..2).map(|k| ((sq[k] / cnt[k] as f64 - cm[k].powi(2)) / cnt[k] as f64).sqrt()).collect();
    let fa = up as f64 / n as f64;
    let sea = (fa * (1.0 - fa) / n as f64).sqrt();
    println!("draws, seed 2026: {} nights; mean Y after a first win {:.2} (s.e. {:.2}), after a first loss {:.2} (s.e. {:.2})",
             n, cm[0], se[0], cm[1], se[1]);
    println!("draws: share of nights finishing above $100 = {:.4} (s.e. {:.4})", fa, sea);

    let p = fr(45, 100);                                 // a house edge: a win has chance 0.45
    let eh: Vec<Fr> = (0..4).map(|k| sum(hs.iter().map(|h| mul(h.iter().fold(int(1), |s, &w| mul(s, if w { p } else { sub(int(1), p) })), forward(h)[k])))).collect();
    let by_stakes = add(int(100), mul(sub(mul(int(2), p), int(1)), add(add(int(30), mul(p, int(20))), mul(sub(int(1), p), int(40)))));
    let flip: Vec<Fr> = hs.iter().map(|h| sub(int(200), forward(h)[1])).collect();
    let flip_after_win = cell_avg(&hs, &flip, 0, 1);
    let one_roll = div(rate[5], int(36));
    println!("house edge 0.45: mean bankroll after 0..3 hands: {} | from the stakes: {}", join(eh.iter().map(|&e| fmt(e)).collect()), fmt(by_stakes));
    let n1: Vec<Fr> = hs.iter().map(|h| forward(h)[1]).collect(); println!("flip process: means {} | E[N_2 | F_1] after a first win = {}, not 120",
             join(vec![fmt(int(100)), fmt(mean8(&n1)), fmt(mean8(&flip))]), fmt(flip_after_win));
    println!("one-roll rate as Z_2: E_P[Z'_2 on 6 then 6] = {:.4}; Q(6 then 6) = {} | averaged under Q, E_Q[Z_1] = {}, not 1",
             fl(one_roll), fmt(mul(q1[5], q1[5])), fmt(sum((0..6).map(|f| mul(q1[f], rate[f])))));

    assert!((0..4).all(|k| (0..8).all(|i| m[k][i] == mb[k][i] && mb[k][i] == forward(&hs[i])[k]))); // three roads to M_n
    assert!((0..4).all(|k| (0..8).all(|i| a[k][i] == ab[k][i])));                // the ahead forecast, two roads
    assert!(fs.iter().enumerate().all(|(k, s)| s.len() == 1 << (1 << k)) && nested && closed
            && (0..4).all(|n| adapted(&m[n], n)) && !(0..3).any(|n| adapted(&m[n + 1], n)));
    assert!(roads_z && step_z && ez.iter().all(|&z| z == z_ratio(&[])));           // density, three roads
    assert!((cm[0] - 120.0).abs() < 4.0 * se[0] && (cm[1] - 80.0).abs() < 4.0 * se[1]); // draws against 120, 80
    assert!((fa - fl(a[0][0])).abs() < 4.0 * sea);                                // draws against 5/8
    assert!(eh[3] == by_stakes && flip_after_win != m[1][0]);                      // the mistakes are real
    println!("ALL CHECKS PASS");
}
