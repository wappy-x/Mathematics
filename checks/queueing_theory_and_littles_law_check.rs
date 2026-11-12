// Queues and Little's law -- the check behind the card.  std only, no crates.
// One till: 55 customers an hour arrive, the till serves 60 an hour when busy.
// Time is in hours, waits printed in minutes.  Roads: closed forms (M/M/1,
// Erlang C, fixed service time); the cut equations solved state by state; the
// arrival's-eye view (wait = L / mu); and seeded simulations (SplitMix64) with
// batch standard errors, where Little's law is checked by sweeping the count
// of people in the shop over time.
const LAM: f64 = 55.0;
const MU: f64 = 60.0;
const SEED: u64 = 20261111;

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn expo(&mut self, rate: f64) -> f64 { -(1.0 - self.uniform()).ln() / rate }
}

fn fact(k: usize) -> f64 { (1..=k).fold(1.0, |acc, i| acc * i as f64) }

// closed form: (chance of waiting, Wq in hours)
fn erlang_c(lam: f64, mu: f64, c: usize) -> (f64, f64) {
    let a = lam / mu;
    let top = a.powf(c as f64) / fact(c) / (1.0 - a / c as f64);
    let mut below = 0.0;
    for k in 0..c { below += a.powf(k as f64) / fact(k); }
    let pw = top / (below + top);
    (pw, pw / (c as f64 * mu - lam))
}

// lam * p[n] = min(n+1, c) * mu * p[n+1], then normalise; returns (p, L, Lq)
fn cuts(lam: f64, mu: f64, c: usize) -> (Vec<f64>, f64, f64) {
    let mut p = vec![1.0];
    for n in 0..6000 { let last = p[n]; p.push(last * lam / ((n + 1).min(c) as f64 * mu)); }
    let s: f64 = p.iter().sum();
    let p: Vec<f64> = p.iter().map(|x| x / s).collect();
    let mut l = 0.0;
    for (n, x) in p.iter().enumerate() { l += n as f64 * x; }
    let mut lq = 0.0;
    for n in c..p.len() { lq += (n - c) as f64 * p[n]; }
    (p, l, lq)
}

fn simulate(lam: f64, mu: f64, c: usize, n: usize, rng: &mut SplitMix64, fixed: bool)
    -> (f64, f64, Vec<f64>, Vec<f64>) {
    let batches = 20;
    let (mut free, mut t, mut arr, mut dep, mut means, mut acc) = (vec![0.0; c], 0.0, vec![], vec![], vec![], 0.0);
    for i in 0..n {
        t += rng.expo(lam);
        let s = if fixed { 1.0 / mu } else { rng.expo(mu) };
        let mut k = 0;
        for j in 1..c { if free[j] < free[k] { k = j; } }   // first till to come free
        let start = t.max(free[k]);
        free[k] = start + s;
        arr.push(t); dep.push(start + s); acc += start - t;
        if (i + 1) % (n / batches) == 0 { means.push(acc / (n / batches) as f64); acc = 0.0; }
    }
    let m = means.iter().sum::<f64>() / batches as f64;
    let mut v = 0.0;
    for x in &means { v += (x - m) * (x - m); }
    let se = (v / (batches - 1) as f64 / batches as f64).sqrt();
    (m, se, arr, dep)
}

// time-average of the number in the shop, counted event by event; returns (L, lam_hat, W_hat)
fn sweep(arr: &[f64], dep: &[f64]) -> (f64, f64, f64) {
    let t_end = arr[arr.len() - 1];
    let (mut i, mut j, mut num, mut last, mut area) = (0, 0, 0i64, 0.0, 0.0);
    while i < arr.len() || (j < dep.len() && dep[j] <= t_end) {
        let (tm, step);
        if i < arr.len() && arr[i] <= dep[j] { tm = arr[i]; step = 1; i += 1; } else { tm = dep[j]; step = -1; j += 1; }
        area += num as f64 * (tm - last); num += step; last = tm;
    }
    let mut w = 0.0;
    for (a, d) in arr.iter().zip(dep) { w += d - a; }
    (area / t_end, arr.len() as f64 / t_end, w / arr.len() as f64)
}

fn mins(h: f64) -> f64 { 60.0 * h }

fn main() {
    let rho = LAM / MU;
    let (l, wq) = (rho / (1.0 - rho), rho / (MU - LAM));
    let w = 1.0 / (MU - LAM);
    let (p1, l1, lq1) = cuts(LAM, MU, 1);
    println!("one till: busy {:.4}, idle {:.1} min an hour, spare rate {:.0} an hour", rho, mins(1.0 - rho), MU - LAM);
    println!("formula: L {:.3}, Lq {:.3}, W {:.2} min, Wq {:.2} min, service {:.2} min", l, rho * rho / (1.0 - rho), mins(w), mins(wq), mins(1.0 / MU));
    println!("cut equations: P(empty) {:.4}, L {:.3}, Lq {:.3}, Wq = Lq/lam {:.2} min", p1[0], l1, lq1, mins(lq1 / LAM));
    println!("arrival's view: Wq = L/mu {:.2} min; server alone: lam x service = {:.4}", mins(l / MU), LAM / MU);
    assert!((l1 - l).abs() < 1e-9 && (lq1 / LAM - wq).abs() < 1e-12 && (l / MU - wq).abs() < 1e-12);
    assert!((p1[0] - (1.0 - rho)).abs() < 1e-12 && (l1 - lq1 - rho).abs() < 1e-9); // Little on the till itself
    println!("figure, arrivals an hour, Wq M/M/1 min, Wq fixed service min");
    for lam in [30.0, 36.0, 42.0, 48.0, 51.0, 54.0, 55.0, 57.0, 58.0, 59.0] {
        let r = lam / MU;
        println!("figure, {}, {:.2}, {:.2}", lam, mins(r / (MU - lam)), mins(r / (2.0 * (MU - lam))));
    }
    let loads: Vec<String> = [50.0, 55.0, 56.0].iter().map(|x: &f64| format!("{:.2}", mins(x / MU / (MU - x)))).collect();
    println!("Wq at 50, 55, 56 an hour: {} min", loads.join(", "));
    let rows = [(format!("one till, {:.0} an hour", LAM), LAM, 1), (format!("two tills, {:.0} an hour", LAM), LAM, 2),
                (format!("two tills, {:.0} an hour", 2.0 * LAM), 2.0 * LAM, 2)];
    for (name, lam, c) in rows {
        let (pw, wqc) = erlang_c(lam, MU, c);
        let (p, _lc, lq) = cuts(lam, MU, c);
        let pw2: f64 = p[c..].iter().sum();
        println!("{}: each till busy {:.4}, P(wait) {:.4} (cuts {:.4}), Wq {:.2} min (cuts {:.2}), Lq {:.3}",
                 name, lam / (c as f64 * MU), pw, pw2, mins(wqc), mins(lq / lam), lam * wqc);
        assert!((pw - pw2).abs() < 1e-9 && (wqc - lq / lam).abs() < 1e-12);
    }
    let split_wq = (LAM / 2.0 / MU) / (MU - LAM / 2.0);
    println!("two tills, separate lines, {:.1} an hour each: Wq {:.2} min", LAM / 2.0, mins(split_wq));
    let (a, top) = (LAM / MU, (LAM / MU).powf(2.0) / 2.0 / (1.0 - LAM / MU / 2.0));
    println!("Erlang C by hand, two tills at {:.0}: top {:.4}, bottom {:.4}, spare rate {:.0} an hour, Wq {:.0} seconds",
             LAM, top, 1.0 + a + top, 2.0 * MU - LAM, 60.0 * mins(erlang_c(LAM, MU, 2).1));
    let mut rng = SplitMix64 { s: SEED };
    let n = 1_000_000;
    let runs = [(format!("M/M/1 at {:.0}", LAM), LAM, 1, false, wq),
                (format!("fixed {:.2}-minute service at {:.0}", mins(1.0 / MU), LAM), LAM, 1, true, wq / 2.0),
                (format!("M/M/2 at {:.0}", 2.0 * LAM), 2.0 * LAM, 2, false, erlang_c(2.0 * LAM, MU, 2).1)];
    for (name, lam, c, fixed, want) in runs {
        let (m, se, arr, dep) = simulate(lam, MU, c, n, &mut rng, fixed);
        println!("simulated {}: Wq {:.2} min, s.e. {:.2}, formula {:.2}", name, mins(m), mins(se), mins(want));
        assert!((m - want).abs() < 4.0 * se);
        if c == 1 {
            let (ls, lam_hat, w_hat) = sweep(&arr, &dep);
            println!("  Little: L by sweep {:.3}; lam x W = {:.3} x {:.2} min = {:.3}", ls, lam_hat, mins(w_hat), lam_hat * w_hat);
            assert!((ls - lam_hat * w_hat).abs() < 0.01 * ls);
        }
    }
    println!("plugging 62 an hour into rho/(1 - rho): L = {:.1}", (62.0 / MU) / (1.0 - 62.0 / MU));
    let days = 400;
    let mut ends = [[0.0f64; 9]; 2];
    for (idx, lam) in [55.0f64, 62.0].iter().enumerate() {
        for _ in 0..days {
            let (mut t, mut free, mut arr, mut dep) = (0.0, 0.0f64, vec![], vec![]);
            loop {
                t += rng.expo(*lam);
                if t > 8.0 { break; }
                free = t.max(free) + rng.expo(MU);
                arr.push(t); dep.push(free);
            }
            for (a, d) in arr.iter().zip(&dep) {
                for h in 1..9 {
                    let hf = h as f64;
                    if *a <= hf && hf < *d { ends[idx][h] += 1.0 / days as f64; }
                }
            }
        }
        let row: Vec<String> = ends[idx][1..].iter().map(|x| format!("{:.1}", x)).collect();
        println!("from empty, mean in shop at hours 1..8, {:.0} an hour: {}", lam, row.join(" "));
    }
    assert!(ends[1][8] > ends[1][4] + 4.0 && ends[1][8] > ends[0][8] + 8.0 && ends[0][8] < l);
    println!("30 vans, 2.5-hour loop: Little gives {:.0} departures an hour", 30.0 / 2.5);
    let (pw3, wq3) = erlang_c(LAM, MU, 3);                // the Try changing box, without editing
    println!("try: LAM 58 -> Wq {:.2} min; MU 66 -> Wq {:.2} min, and 62 an hour has long-run L {:.1}",
             mins(58.0 / MU / (MU - 58.0)), mins(LAM / 66.0 / (66.0 - LAM)), (62.0 / 66.0) / (1.0 - 62.0 / 66.0));
    println!("try: three tills at {:.0} -> P(wait) {:.4}, Wq {:.2} min ({:.1} seconds)", LAM, pw3, mins(wq3), 60.0 * mins(wq3));
    println!("ALL CHECKS PASS");
}
