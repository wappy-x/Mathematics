// Operator topologies: the check behind the card.  Rust std only, no crates.
// The delay S (one sample later) and the advance S* (drop the first sample),
// its adjoint, on lists of samples.  The finite rehearsal is the clip
// (3, 1, 4, 1, 5); the infinite case is the fading tail u_k = 1/k, held to
// K terms plus its remainder.  Roads: tail sums against pi^2/6 minus partial
// sums; lag readings summed directly against H_n / n; Cauchy-Schwarz bounds;
// cut matrices against the endless list; exact integer probes for the net;
// switched-off copies against Goldstine's all-ones limit.
use std::f64::consts::PI;

fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |s, (x, y)| s + x * y) }
fn delay(u: &[f64], n: usize) -> Vec<f64> { let mut v = vec![0.0; n]; v.extend_from_slice(u); v } // S^n, endless
fn advance(u: &[f64], n: usize) -> Vec<f64> { u[n.min(u.len())..].to_vec() } // S*^n: drop n samples
fn cut_adv(v: &[f64], n: usize) -> Vec<f64> { let mut w = advance(v, n); w.resize(v.len(), 0.0); w } // cut to N
fn cut_del(v: &[f64], n: usize) -> Vec<f64> { let mut w = delay(v, n); w.truncate(v.len()); w }
fn opnorm(f: &dyn Fn(&[f64]) -> Vec<f64>, ft: &dyn Fn(&[f64]) -> Vec<f64>, n: usize) -> f64 {
    let mut x: Vec<f64> = (0..n).map(|i| 1.0 + 0.1 * i as f64).collect(); // power iteration on f^T f
    for _ in 0..60 {
        let y = ft(&f(&x)); let s = dot(&y, &y).sqrt();
        if s == 0.0 { return 0.0; }
        x = y.iter().map(|v| v / s).collect();
    }
    let fx = f(&x); dot(&fx, &fx).sqrt()
}
fn row(xs: &[f64], w: usize, d: usize) -> String { xs.iter().map(|v| format!("{:w$.d$}", v, w = w, d = d)).collect::<Vec<_>>().join(" ") }
fn rem(k: f64) -> f64 { 1.0 / k - 1.0 / (2.0 * k * k) + 1.0 / (6.0 * k * k * k) } // Euler-Maclaurin estimate of sum of 1/k^2 past K

fn main() {
    println!("1. the clip u = (3, 1, 4, 1, 5) on the endless list");
    let u = vec![3.0, 1.0, 4.0, 1.0, 5.0];
    let adv: Vec<f64> = (0..6).map(|n| { let a = advance(&u, n); dot(&a, &a) }).collect();
    let dl: Vec<f64> = (0..6).map(|n| { let a = delay(&u, n); dot(&a, &a) }).collect();
    let lag: Vec<f64> = (0..6).map(|n| dot(&u, &delay(&u, n))).collect();
    println!("   n             {}", (0..6).map(|n| format!("{:4}", n)).collect::<Vec<_>>().join(" "));
    println!("   energy S*^n u {}", row(&adv, 4, 0));
    println!("   energy S^n u  {}", row(&dl, 4, 0));
    println!("   <u, S^n u>    {}", row(&lag, 4, 0));
    assert!(adv == vec![52.0, 43.0, 42.0, 26.0, 25.0, 0.0] && dl == vec![52.0; 6]);
    assert!(lag == (0..6).map(|n| dot(&advance(&u, n), &u)).collect::<Vec<_>>()); // <u, S^n u> = <S*^n u, u>
    let far: Vec<f64> = [5usize, 50].iter().map(|&n| {
        let mut a = delay(&u, n); a.resize(5 + 2 * n, 0.0); let b = delay(&u, 2 * n);
        a.iter().zip(&b).map(|(x, y)| (x - y) * (x - y)).sum::<f64>().sqrt()
    }).collect();
    println!("   |S^n u - S^2n u| at n = 5, 50: {:.4} {:.4}; sqrt(2 x 52) = {:.4}", far[0], far[1], 104f64.sqrt());
    assert!(far.iter().all(|d| (d - 104f64.sqrt()).abs() < 1e-12));
    let wit = [1usize, 10, 1000].iter().all(|&n| { let mut e = vec![0.0; n]; e.push(1.0); advance(&e, n) == vec![1.0] });
    println!("   S*^n e_(n+1) = e_1 at n = 1, 10, 1000: {}, so |S*^n| = 1", if wit { "True" } else { "False" });
    assert!(wit); // the click past the cut survives
    let g: Vec<f64> = (1..7).map(|n| opnorm(&|v: &[f64]| cut_adv(v, n), &|v: &[f64]| cut_del(v, n), 5)).collect();
    println!("   cut to N = 5: |S*^n|, n = 1..6: {}", row(&g, 0, 4));
    assert!(g[..4].iter().all(|v| (v - 1.0).abs() < 1e-9) && g[4] == 0.0 && g[5] == 0.0);
    let back = [1usize, 10, 1000].iter().all(|&n| advance(&delay(&u, n), n) == u);
    println!("   S*^n S^n u = u at n = 1, 10, 1000: {}, energy 52 at every n", if back { "True" } else { "False" });
    assert!(back); // advance after delay gives u back

    println!("2. the fading tail u_k = 1/k, K = 200000 terms plus remainder");
    let kk: u64 = 200000;
    let z = PI * PI / 6.0;
    let ns: [u64; 10] = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];
    println!("   |u| = pi/sqrt(6) = {:.6}", z.sqrt());
    println!("      n  |S*^n u|  |S^n u|  <u,S^n u>  bound |S*^n u||u|");
    let (mut st, mut wk, mut ls) = (Vec::new(), Vec::new(), Vec::new());
    let tail: Vec<f64> = (1..kk + 1).map(|k| 1.0 / k as f64).collect(); // the tail u, K terms
    for &n in &ns {
        let direct = (n + 1..kk + 1).map(|k| 1.0 / ((k * k) as f64)).sum::<f64>() + rem(kk as f64);
        let viaz = z - (1..n + 1).map(|k| 1.0 / ((k * k) as f64)).sum::<f64>();
        assert!((direct - viaz).abs() < 1e-12); // road 1: two tail sums
        let lagd: f64 = (1..kk + 1).map(|k| 1.0 / ((k * (k + n)) as f64)).sum();
        let hn = (1..n + 1).map(|k| 1.0 / k as f64).sum::<f64>() / n as f64;
        assert!(0.0 < hn - lagd && hn - lagd < 1.0 / kk as f64); // road 2: H_n / n
        let s = viaz.sqrt();
        assert!(hn <= s * z.sqrt()); // road 3: Cauchy-Schwarz
        let d = delay(&tail, n as usize); let ln = (dot(&d, &d) + rem(kk as f64)).sqrt(); // |S^n u|, on the delayed list
        assert!((ln - z.sqrt()).abs() < 1e-12); // the delay keeps the length pi/sqrt(6)
        st.push(s); wk.push(hn); ls.push(ln);
        println!("   {:4}  {:.6}  {:.6}  {:.6}   {:.6}", n, s, ln, hn, s * z.sqrt());
    }
    assert!(st.iter().zip(&ns).all(|(s, &n)| (s * (n as f64).sqrt() - 1.0).abs() < 0.6)); // tail like 1/sqrt(n)
    println!("   chart n         {}", ns.iter().map(|n| format!("{:5}", n)).collect::<Vec<_>>().join(" "));
    println!("   chart strong    {}", row(&st, 0, 3));
    println!("   chart length    {}", row(&ls, 0, 3));
    println!("   chart weak      {}", row(&wk, 0, 3));

    println!("3. a net with no sequence: T_mn v = v_1 (e_m + m e_n), probed by w = u = (1/k)");
    for q in [10u64, 100, 1000] { // eps = 1/q
        let m = 2 * q + 1; let n = 2 * m * q + 1; // 1/m < eps/2, m/n < eps/2
        let (num, den) = (n + m * m, m * n); // 1/m + m/n, exactly
        assert!(num * q < den); // reading below eps
        println!("   eps 1/{:<4}: m {:5}, n {:8}, reading {:.5} x eps, |T_mn| = {:.3}",
            q, m, n, (num * q) as f64 / den as f64, ((1 + m * m) as f64).sqrt());
    }

    println!("4. Goldstine: x_n = (1, .., 1, 0, ..) in the ball of c0, read by y in l1");
    println!("      n  sum 2^-k  sum 1/k^2  sup-distance to all-ones");
    for n in [1i32, 2, 5, 10, 100, 1000] {
        let r1: f64 = (1..n + 1).map(|k| 2f64.powi(-k)).sum();
        let r2: f64 = (1..n + 1).map(|k| 1.0 / ((k as i64 * k as i64) as f64)).sum();
        let nf = n as f64;
        assert!((r1 - (1.0 - 2f64.powi(-n))).abs() < 1e-15 && ((z - r2) - (1.0 / nf - 1.0 / (2.0 * nf * nf))).abs() < 0.2 / (nf * nf * nf));
        println!("   {:4}  {:.6}  {:.6}   1", n, r1, r2);
    }
    println!("   limits: 1.000000 and pi^2/6 = {:.6}; all-ones is in l-infinity, not in c0", z);

    println!("5. what breaks");
    let b9 = advance(&delay(&u, 9), 9); let energy9 = dot(&b9, &b9);
    println!("   strong limit 0 taken as norm limit: |S*^1000| = {:.4}, not 0", opnorm(&|v: &[f64]| cut_adv(v, 1000), &|v: &[f64]| cut_del(v, 1000), 1001));
    println!("   weak limit 0 taken as strong limit: |S^1000 u| = {:.4}, not 0", ls[ls.len() - 1]);
    println!("   limit of the product as product of limits: S*^9 S^9 u has energy {:.0}, not 0", energy9);
    assert!(b9 == u && energy9 == 52.0); // weak limits do not multiply
    println!("   cut matrix trusted: N = 5 gives |S*^5| = {:.0}; the endless list gives 1", g[4]);

    println!("ALL CHECKS PASS");
}
