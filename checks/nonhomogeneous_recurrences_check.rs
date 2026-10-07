// Recurrences with a driving term -- the same check as the Python, in Rust.  No
// crates.  Two rules that add an outside amount at every step: the Tower of
// Hanoi, h(n) = 2 h(n-1) + 1 with h(0) = 0, and a savings account at 1% a month
// taking a deposit of 10n dollars in month n.  Every answer is reached at least
// twice: forward from the seed, and from the closed form that undetermined
// coefficients builds.  The Hanoi moves are also actually made, on three pegs.
const DISCS: i64 = 6;
const MONTHS: i64 = 12;
const RATE: f64 = 1.01;
fn moves(n: i64, src: usize, dst: usize, spare: usize) -> Vec<(i64, usize, usize)> {
    if n == 0 { return Vec::new() }                   // the recursion, written out as moves
    let mut out = moves(n - 1, src, spare, dst);
    out.push((n, src, dst)); out.extend(moves(n - 1, spare, dst, src));
    out
}
fn rebuilt(n: i64) -> bool {                          // make those moves on three real pegs
    let mut pegs: Vec<Vec<i64>> = vec![(1..=n).rev().collect(), Vec::new(), Vec::new()];
    for (disc, src, dst) in moves(n, 0, 2, 1) {
        if pegs[src].last() != Some(&disc) { return false }
        if let Some(&top) = pegs[dst].last() { if top < disc { return false } }
        let d = pegs[src].pop().unwrap(); pegs[dst].push(d)
    }
    pegs[2] == (1..=n).rev().collect::<Vec<i64>>()
}
fn forward_i(c: i64, drive: &dyn Fn(i64) -> i64, seed: i64, last: i64) -> Vec<i64> {
    let (mut out, mut a) = (Vec::new(), seed);        // a(n) = c a(n-1) + drive(n), stepped
    for n in 1..=last { a = c * a + drive(n); out.push(a) }
    out
}
fn forward_f(c: f64, drive: &dyn Fn(i64) -> f64, seed: f64, last: i64) -> Vec<f64> {
    let (mut out, mut a) = (Vec::new(), seed);
    for n in 1..=last { a = c * a + drive(n); out.push(a) }
    out
}
fn row(name: &str, vals: &[String]) {
    let mut line = format!("{:<36}", name);
    for v in vals { line.push_str(&format!("{:>7}", v)) }
    println!("{}", line);
}
fn cash(vals: &[f64]) -> Vec<String> { vals.iter().map(|v| format!("{:.2}", v)).collect() }
fn ints(vals: &[i64]) -> Vec<String> { vals.iter().map(|v| v.to_string()).collect() }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let (ns, ms): (Vec<i64>, Vec<i64>) = ((1..=DISCS).collect(), (1..=MONTHS).collect());
    let fwd_h = forward_i(2, &|_n| 1, 0, DISCS);
    let closed_h: Vec<i64> = ns.iter().map(|&n| 2i64.pow(n as u32) - 1).collect();
    let made: Vec<i64> = ns.iter().map(|&n| moves(n, 0, 2, 1).len() as i64).collect();
    let fwd_s = forward_f(RATE, &|n| 10.0 * n as f64, 0.0, MONTHS);
    let closed_s: Vec<f64> = ms.iter().map(|&n| 101000.0 * RATE.powf(n as f64) - 1000.0 * n as f64 - 101000.0).collect();
    let grown: Vec<f64> = ms.iter().map(|&n| (1..=n).map(|k| 10.0 * k as f64 * RATE.powf((n - k) as f64)).sum()).collect();
    let flat: Vec<i64> = ms.iter().map(|&n| 5 * n * (n + 1)).collect();
    let (geo_f, geo_c) = (forward_i(2, &|n| 3i64.pow(n as u32), 0, 5), (1i64..6).map(|n| 3i64.pow(n as u32 + 1) - 3 * 2i64.pow(n as u32)).collect::<Vec<i64>>());
    let (res_f, res_c) = (forward_i(2, &|n| 2i64.pow(n as u32), 0, 5), (1i64..6).map(|n| n * 2i64.pow(n as u32)).collect::<Vec<i64>>());
    println!("Tower of Hanoi, h(n) = 2 h(n-1) + 1, h(0) = 0; closed form 2^n - 1");
    row("discs n", &ints(&ns));
    row("forward, one step at a time", &ints(&fwd_h));
    row("from the closed form", &ints(&closed_h));
    row("moves the recursion actually makes", &ints(&made));
    println!("six discs: {} moves, every move legal and the tower rebuilt: {}", closed_h[5], yn(rebuilt(DISCS)));
    println!("Savings at 1% a month, s(n) = 1.01 s(n-1) + 10n, s(0) = 0; closed form 101000 x 1.01^n - 1000n - 101000");
    row("month n", &ints(&ms));
    row("forward, month by month", &cash(&fwd_s));
    row("from the closed form", &cash(&closed_s));
    row("each deposit grown, added up", &cash(&grown));
    row("at 0% instead, 5n(n+1)", &cash(&flat.iter().map(|&v| v as f64).collect::<Vec<f64>>()));
    println!("after twelve months {:.2}: deposits {:.2} and interest {:.2}", fwd_s[11], flat[11] as f64, fwd_s[11] - flat[11] as f64);
    println!("t(n) = 2 t(n-1) + 3^n: forward {:?}, closed form 3^(n+1) - 3 x 2^n {:?}, same: {}", geo_f, geo_c, yn(geo_f == geo_c));
    println!("t(n) = 2 t(n-1) + 2^n: forward {:?}, closed form n x 2^n {:?}, same: {}", res_f, res_c, yn(res_f == res_c));
    println!("mistake 1, the particular part alone: {} moves for six discs, not {}", (1.0 / (1.0 - 2.0)) as i64, closed_h[5]);
    println!("mistake 2, the added 1 dropped: A x 2^n fitted at one disc gives {:.0}, not {}", fwd_h[0] as f64 / 2.0 * 2f64.powf(DISCS as f64), closed_h[5]);
    println!("mistake 3, a constant guess where c = 1: B = B + 1 has no solution, and a(6) = {}", forward_i(1, &|_n| 1, 0, DISCS)[5]);
    println!("mistake 4, resonance with a plain geometric guess: {} at n = 5, not {}", forward_i(2, &|_n| 0, 0, 5)[4], res_c[4]);
    assert!(made == fwd_h && fwd_h == closed_h);
    assert!(cash(&fwd_s) == cash(&closed_s) && cash(&closed_s) == cash(&grown));
    assert!(geo_f == geo_c && res_f == res_c);
    assert!(rebuilt(DISCS) && flat == ms.iter().map(|&n| (1..=n).map(|k| 10 * k).sum::<i64>()).collect::<Vec<i64>>());
    println!("ALL CHECKS PASS");
}
