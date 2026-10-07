// Bayesian updating -- the same check as the Python, in Rust.  No crates.
// A new coin shows h = 7 heads in n = 10 flips.  theta is its unknown chance of
// heads.  Roads to the posterior: 11 candidate coins (Bayes' rule on a list),
// the exact integral by expanding the polynomial, a 4,000-cell grid, and a
// seeded simulation that keeps only the imaginary coins that also show 7 of 10.
const N: i64 = 10;
const H: i64 = 7;
const T: i64 = N - H;
fn comb(n: i64, k: i64) -> i64 { (0..k).fold(1, |c, j| c * (n - j) / (j + 1)) }
fn lik(th: f64, h: i64, t: i64) -> f64 { comb(h + t, h) as f64 * th.powi(h as i32) * (1.0 - th).powi(t as i32) }

#[derive(Clone, Copy)]
struct Fr { n: i128, d: i128 }                    // exact fractions, always reduced
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn add(a: Fr, b: Fr) -> Fr { fr(a.n * b.d + b.n * a.d, a.d * b.d) }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n * b.n, a.d * b.d) }
fn div(a: Fr, b: Fr) -> Fr { fr(a.n * b.d, a.d * b.n) }
fn pw(a: Fr, k: i64) -> Fr { (0..k).fold(fr(1, 1), |p, _| mul(p, a)) }
fn fl(a: Fr) -> f64 { a.n as f64 / a.d as f64 }
fn show(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

// exact integral of theta^shift * theta^h (1-theta)^t from lo to hi, term by term
fn integ(h: i64, t: i64, lo: Fr, hi: Fr, shift: i64) -> Fr {
    let mut s = fr(0, 1);
    for k in 0..=t {
        let p = h + k + shift + 1;
        let c = fr((comb(t, k) * if k % 2 == 0 { 1 } else { -1 }) as i128, p as i128);
        s = add(s, mul(c, add(pw(hi, p), mul(fr(-1, 1), pw(lo, p)))));
    }
    s
}

struct SplitMix64 { s: u64 }                      // small generator, same in Python
impl SplitMix64 {
    fn unif(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

// a fine grid, any prior, log scale so 1,000 flips do not underflow
fn grid(logprior: &dyn Fn(f64) -> f64, h: i64, t: i64, cells: usize, lo: f64, hi: f64) -> (f64, f64, f64, f64) {
    let w = (hi - lo) / cells as f64;
    let th: Vec<f64> = (0..cells).map(|i| lo + (i as f64 + 0.5) * w).collect();
    let lw: Vec<f64> = th.iter().map(|&x| logprior(x) + h as f64 * x.ln() + t as f64 * (1.0 - x).ln()).collect();
    let top = lw.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let wt: Vec<f64> = lw.iter().map(|v| (v - top).exp()).collect();
    let z: f64 = wt.iter().sum();
    let mean = th.iter().zip(&wt).map(|(x, v)| x * v).sum::<f64>() / z;
    let sd = (th.iter().zip(&wt).map(|(x, v)| (x - mean).powi(2) * v).sum::<f64>() / z).sqrt();
    let gt = th.iter().zip(&wt).filter(|(x, _)| **x > 0.5).map(|(_, v)| v).sum::<f64>() / z;
    (mean, sd, gt, z * w * top.exp())
}

fn lnf(m: i64) -> f64 { (2..=m).map(|j| (j as f64).ln()).sum() }
fn exact_mean(a: i64, h: i64, t: i64) -> f64 {    // ratio of two integrals a!b!/(a+b+1)!
    (lnf(a + h + 1) + lnf(a + t) - lnf(2 * a + h + t + 2) - lnf(a + h) - lnf(a + t) + lnf(2 * a + h + t + 1)).exp()
}

fn main() {
    // road 1: eleven candidate coins, prior 1/11 each, Bayes' rule on a list
    let cand: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    let joint: Vec<f64> = cand.iter().map(|&c| lik(c, H, T) / 11.0).collect();
    let ev11: f64 = joint.iter().sum();
    let post11: Vec<f64> = joint.iter().map(|j| j / ev11).collect();
    println!("coin: h = {} heads in n = {} flips; candidates 0.0 to 1.0, prior 1/11 each", H, N);
    for i in 0..11 {
        println!("list  theta={:.1}  likelihood={:.6}  prior*lik={:.6}  posterior={:.4}", cand[i], lik(cand[i], H, T), joint[i], post11[i]);
    }
    let m11: f64 = cand.iter().zip(&post11).map(|(c, p)| c * p).sum();
    let g11: f64 = cand.iter().zip(&post11).filter(|(c, _)| **c > 0.5).map(|(_, p)| p).sum();
    println!("list  evidence={:.6}  mean={:.4}  P(theta>0.5)={:.4}", ev11, m11, g11);

    // road 2: exact, expanding theta^7 (1-theta)^3 and integrating term by term
    let (z0, one, half) = (fr(0, 1), fr(1, 1), fr(1, 2));
    let area = integ(H, T, z0, one, 0);
    let ev_exact = mul(fr(comb(N, H) as i128, 1), area);
    let mean_exact = div(integ(H, T, z0, one, 1), area);
    let gt_exact = div(integ(H, T, half, one, 0), area);
    let sq_exact = div(integ(H, T, z0, one, 2), area);
    let sd_exact = (fl(sq_exact) - fl(mean_exact).powi(2)).sqrt();
    println!("exact area of theta^7(1-theta)^3 = {}; evidence = {} = {:.6}", show(area), show(ev_exact), fl(ev_exact));
    println!("exact posterior = {} theta^7 (1-theta)^3; mean = {} = {:.4}; sd = {:.4}; P(theta>0.5) = {} = {:.4}",
             show(div(one, area)), show(mean_exact), fl(mean_exact), sd_exact, show(gt_exact), fl(gt_exact));
    let fair: i64 = (H..=N).map(|j| comb(N, j)).sum();
    println!("exact I(8,3) = {}; a fair coin shows 7 or more heads in 10 with chance {}/1024 = {:.4}", show(integ(H, T, z0, one, 1)), fair, fair as f64 / 1024.0);

    // road 3: the grid
    let flat = |_x: f64| 0.0;
    let (gm, gsd, ggt, garea) = grid(&flat, H, T, 4000, 0.0, 1.0);
    println!("grid  4000 cells: area = {:.8} (1/1320 = {:.8}); mean = {:.4}; sd = {:.4}; P(theta>0.5) = {:.4}", garea, 1.0 / 1320.0, gm, gsd, ggt);

    // road 4: simulate, keep the coins whose 10 flips show 7 heads
    let (mut rng, draws) = (SplitMix64 { s: 20260929 }, 200000);
    let mut kept: Vec<f64> = Vec::new();
    for _ in 0..draws {
        let th = rng.unif();
        let heads = (0..N).filter(|_| rng.unif() < th).count() as i64;
        if heads == H { kept.push(th) }
    }
    let k = kept.len() as f64;
    let acc = k / draws as f64;
    let acc_se = (acc * (1.0 - acc) / draws as f64).sqrt();
    let sm = kept.iter().sum::<f64>() / k;
    let ssd = (kept.iter().map(|x| (x - sm).powi(2)).sum::<f64>() / (k - 1.0)).sqrt();
    let sg = kept.iter().filter(|&&x| x > 0.5).count() as f64 / k;
    println!("sim   seed 20260929, {} coins, {} show 7 heads: evidence {:.4} (se {:.4})", draws, kept.len(), acc, acc_se);
    println!("sim   mean {:.4} (se {:.4}); sd {:.4}; P(theta>0.5) {:.4} (se {:.4})", sm, ssd / k.sqrt(), ssd, sg, (sg * (1.0 - sg) / k).sqrt());

    // staged: one flip at a time, renormalising after each
    let (th, mut st): (Vec<f64>, Vec<f64>) = ((0..4000).map(|i| (i as f64 + 0.5) / 4000.0).collect(), Vec::new());
    for (name, heads_first) in [("heads first", true), ("tails first", false)] {
        let seq: Vec<bool> = if heads_first { [vec![true; 7], vec![false; 3]].concat() } else { [vec![false; 3], vec![true; 7]].concat() };
        let mut wt = vec![1.0f64; 4000];
        for f in seq {
            wt = wt.iter().zip(&th).map(|(v, x)| v * if f { *x } else { 1.0 - x }).collect();
            let z: f64 = wt.iter().sum();
            wt = wt.iter().map(|v| v / z).collect();   // today's posterior is tomorrow's prior
        }
        st.push(th.iter().zip(&wt).map(|(x, v)| x * v).sum::<f64>());
        println!("staged {}, renormalised after every flip: mean = {:.4}", name, st[st.len() - 1]);
    }

    // figure: posterior density at theta = 0, 0.1, ..., 1
    let dens: Vec<String> = (0..11).map(|i| format!("{:.2}", fl(div(one, area)) * (i as f64 / 10.0).powi(7) * (1.0 - i as f64 / 10.0).powi(3))).collect();
    println!("figure, flat prior density 1.00 at every theta; posterior density 1320 theta^7 (1-theta)^3: {}", dens.join(", "));

    // the prior washes out: flat versus a sceptic, f proportional to (theta(1-theta))^10
    let sceptic = |x: f64| 10.0 * (x * (1.0 - x)).ln();
    println!("sceptic prior density at 0.5: {:.2}; prior sd {:.4}", 21.0 * comb(20, 10) as f64 * 0.25f64.powi(10), (0.25f64 / 23.0).sqrt());
    let (mut fl_row, mut sc_row) = (Vec::new(), Vec::new());
    for n in [0i64, 10, 30, 100, 300, 1000] {
        let h = 7 * n / 10;
        let (ef, es) = (exact_mean(0, h, n - h), exact_mean(10, h, n - h));
        let (gf, gs) = (grid(&flat, h, n - h, 4000, 0.0, 1.0).0, grid(&sceptic, h, n - h, 4000, 0.0, 1.0).0);
        fl_row.push(gf); sc_row.push(gs);
        println!("washout n={:4} h={:3}: flat exact {:.4} grid {:.4}; sceptic exact {:.4} grid {:.4}; gap {:.4}", n, h, ef, gf, es, gs, (ef - es).abs());
    }
    let j = |r: &Vec<f64>| r.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(", ");
    println!("figure, washout means flat: {}", j(&fl_row));
    println!("figure, washout means sceptic: {}", j(&sc_row));

    // what breaks
    println!("break 1, no division by the evidence: area under prior*lik = {:.4}; P(theta>0.5) read off it = {:.4}, not {:.4}",
             fl(ev_exact), fl(mul(ev_exact, gt_exact)), fl(gt_exact));
    let tm = grid(&flat, 700, 300, 4000, 0.4, 0.6).0;
    println!("break 2, prior zero outside 0.4 to 0.6, then 700 heads in 1000: mean = {:.4}, not {:.4}", tm, grid(&flat, 700, 300, 4000, 0.0, 1.0).0);
    let (dm, dsd, _, _) = grid(&flat, 2 * H, 2 * T, 4000, 0.0, 1.0);
    println!("break 3, the same 10 flips fed in twice: mean = {:.4}, sd = {:.4}; honest sd = {:.4}", dm, dsd, gsd);
    println!("break 4, likelihood at 0.7 read as a chance: {:.4}; its area over theta = {:.4}, not 1", lik(0.7, H, T), fl(ev_exact));

    // try changing
    let (am, _, ag, _) = grid(&flat, 10, 0, 4000, 0.0, 1.0);
    println!("try: 10 heads in 10, mean = {:.4}, P(theta>0.5) = {:.4}; 70 of 100, sd = {:.4}; prior 0.4 to 0.6 with 10 flips, mean = {:.4}",
             am, ag, grid(&flat, 70, 30, 4000, 0.0, 1.0).1, grid(&flat, H, T, 4000, 0.4, 0.6).0);

    assert!(area.n == 1 && area.d == 1320 && (garea - fl(area)).abs() < 1e-9);         // exact; grid area vs exact
    assert!((gm - fl(mean_exact)).abs() < 1e-6 && (ggt - fl(gt_exact)).abs() < 1e-6);   // grid vs exact
    assert!((sm - fl(mean_exact)).abs() < 4.0 * ssd / k.sqrt() && (acc - 1.0 / 11.0).abs() < 4.0 * acc_se);
    assert!((m11 - fl(mean_exact)).abs() < 0.01);                                     // 11 coins already close
    assert!([0i64, 10, 30, 100, 300, 1000].iter().zip(&fl_row).all(|(&n, f)| (exact_mean(0, 7 * n / 10, n - 7 * n / 10) - f).abs() < 1e-6));
    assert!((dm - exact_mean(0, 2 * H, 2 * T)).abs() < 1e-6);                          // double count
    assert!((tm - (0.6 - 1.0 / (700.0 / 0.6 - 300.0 / 0.4))).abs() < 5e-4 && st.iter().all(|s| (s - gm).abs() < 1e-9));
    assert!((sc_row[1] - exact_mean(10, H, T)).abs() < 1e-6 && (sc_row[5] - exact_mean(10, 700, 300)).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
