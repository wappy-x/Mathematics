// Doob-Meyer -- the check behind the card.  std only, no crates.
// House example: M_t = integral of W against W = (W_t^2 - t)/2, W a Brownian motion.
// Its bracket <M>_t = integral of W_s^2 ds, so E[M_1^2] = E<M>_1 = 1/2.
// Calls at 4 an hour: N_t - 4t is a martingale whose bracket is 4t.
// Road 1: the formulas, with the normal's moments by Simpson's rule.
// Road 2: Doob's recipe run exactly on a coin-toss tree, in whole numbers.
// Road 3: seeded simulation (SplitMix64 and Box-Muller, written out).
use std::f64::consts::PI;

struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 { // uniform on [0, 1), 53 bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine branch
        let (a, b) = (1.0 - self.u(), self.u());
        (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos()
    }
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let (n, mut s) = (2000, f(a) + f(b));
    let h = (b - a) / n as f64;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let (mut s, mut q) = (0.0, 0.0);
    for &x in xs { s += x; q += x * x; }
    let (n, m) = (xs.len() as f64, s / xs.len() as f64);
    (m, ((q - n * m * m) / (n - 1.0) / n).sqrt())
}

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

// Walk S (sum of +-1), W = S/sqrt(n), M = (S^2 - k)/(2n); work with 4n^2 M^2 = (S^2-k)^2.
fn tree(n: i128) -> (i128, i128, (i128, i128), (i128, i128)) {
    let z = |k: i128, s: i128| (s * s - k) * (s * s - k);
    let mut bad = 0;
    for k in 0..n {
        let mut s = -k;
        while s <= k {
            let recipe = z(k + 1, s + 1) + z(k + 1, s - 1) - 2 * z(k, s); // 2 x 4n^2 x trend step
            let dm = (s + 1) * (s + 1) - (k + 1) - (s * s - k);            // 2n x step of M
            if recipe != 8 * s * s || dm * dm != 4 * s * s { bad += 1; }  // trend = (dM)^2 = W^2 dt
            s += 2;
        }
    }
    let (mut c, mut ez) = (1i128, 0i128);
    for j in 0..=n { ez += c * z(n, 2 * j - n); c = c * (n - j) / (j + 1); }
    let mut ea = 0i128;
    for k in 0..n {
        let (mut c, mut sk) = (1i128, 0i128);
        for j in 0..=k { sk += c * (2 * j - k) * (2 * j - k); c = c * (k - j) / (j + 1); }
        ea += sk * (1i128 << (n - k)) * 4; // E[S_k^2]/n^2, scaled
    }
    let den = (1i128 << n) * 4 * n * n;
    let (g, h) = (gcd(ez, den), gcd(ea, den));
    (n * (n + 1) / 2, bad, (ez / g, den / g), (ea / h, den / h))
}

fn main() {
    // ---- road 1: formulas ----
    let phi = |z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt();
    let m2 = simpson(|z| z.powi(2) * phi(z), -12.0, 12.0);
    let m4 = simpson(|z| z.powi(4) * phi(z), -12.0, 12.0);
    println!("road 1: E[W_1^2] = {:.6}, E[W_1^4] = {:.6} (Simpson)", m2, m4);
    for t in [1.0f64, 2.0] {
        let em2 = (m4 * t * t - 2.0 * t * m2 * t + t * t) / 4.0; // E[(W_t^2 - t)^2]/4
        let ea = simpson(|s| m2 * s, 0.0, t);                    // E int_0^t W_s^2 ds
        println!("t = {:.0}: E[M_t^2] = {:.6}, E<M>_t = {:.6}", t, em2, ea);
        assert!((em2 - t * t / 2.0).abs() < 1e-9 && (ea - em2).abs() < 1e-9);
    }

    // ---- road 2: Doob's recipe on a coin-toss tree ----
    for n in [10i128, 100] {
        let (nodes, bad, ez, ea) = tree(n);
        println!("tree, {} steps: recipe = W^2 dt = (dM)^2 at {} of {} nodes", n, nodes - bad, nodes);
        println!("  E[M^2] = {}/{} = {:.6}, E[A] = {}/{}", ez.0, ez.1, ez.0 as f64 / ez.1 as f64, ea.0, ea.1);
        assert!(bad == 0 && ez == ea && ez.0 * 2 * n == ez.1 * (n - 1));
    }

    // ---- road 3: Brownian paths ----
    let (mut rng, p, n) = (Rng { s: 20261123 }, 4000usize, 200usize);
    let (dt, sq) = (1.0 / n as f64, (1.0 / n as f64).sqrt());
    let mut cols: Vec<Vec<f64>> = vec![Vec::new(); 5];
    for _ in 0..p {
        let (mut w, mut a, mut q, mut qw, mut iw, mut mprev) = (0.0f64, 0.0, 0.0, 0.0, 0.0, 0.0);
        for k in 0..n {
            let dw = sq * rng.normal();
            a += (w * w + (w + dw).powi(2)) / 2.0 * dt; // trapezoid for int W^2 ds
            iw += (w + w + dw) / 2.0 * dt;              // int W ds, the unsquared mistake
            w += dw; qw += dw * dw;
            let m = (w * w - (k + 1) as f64 * dt) / 2.0;
            q += (m - mprev).powi(2); mprev = m;
        }
        for (c, v) in cols.iter_mut().zip([mprev * mprev, a, q, iw, qw]) { c.push(v); }
    }
    let names = ["E[M_1^2]", "E<M>_1 = E int W^2 ds", "E[sum (dM)^2]", "mistake E int W ds", "mistake E[W]_1"];
    for ((name, c), want) in names.iter().zip(cols.iter()).zip([0.5, 0.5, 0.5, 0.0, 1.0]) {
        let (m, se) = mean_se(c);
        println!("sim {} paths x {} steps: {} = {:.4} +- {:.4}", p, n, name, m, se);
        assert!((m - want).abs() < 4.0 * se);
    }

    // one path, fine grid: the squared steps of M settle on int W^2 ds
    let (fine, mut rng, mut ws) = (20480usize, Rng { s: 7 }, vec![0.0f64]);
    for _ in 0..fine { let last = ws[ws.len() - 1]; ws.push(last + (1.0 / fine as f64).sqrt() * rng.normal()); }
    let ms: Vec<f64> = ws.iter().enumerate().map(|(i, w)| (w * w - i as f64 / fine as f64) / 2.0).collect();
    let mut br = vec![0.0f64];
    for i in 0..fine { let last = br[i]; br.push(last + (ws[i].powi(2) + ws[i + 1].powi(2)) / 2.0 / fine as f64); }
    println!("one path: W_1 = {:.4}, M_1 = {:.4}, <M>_1 = int W^2 ds = {:.4}", ws[fine], ms[fine], br[fine]);
    let mut qv = 0.0;
    for steps in [20usize, 320, 5120, 20480] {
        let j = fine / steps;
        qv = 0.0;
        for i in 0..steps { qv += (ms[(i + 1) * j] - ms[i * j]).powi(2); }
        println!("  sum of squared steps of M, {:5} steps: {:.4}", steps, qv);
    }
    assert!((qv - br[fine]).abs() < 0.05);
    let line = |v: &Vec<f64>, sq: bool| (0..21).map(|i| { let x = v[i * 1024]; format!("{:.3}", if sq { x * x } else { x }) }).collect::<Vec<_>>().join(", ");
    println!("chart M^2: {}", line(&ms, true));
    println!("chart <M>: {}", line(&br, false));

    // ---- calls at 4 an hour ----
    let lam = 4.0f64;
    let (mut pr, mut e2c, mut e2, mut p4) = ((-lam).exp(), 0.0f64, 0.0f64, 0.0f64);
    for k in 0..100 {
        e2c += pr * (k as f64 - lam).powi(2);
        e2 += pr * (k * k) as f64;
        if k == 4 { p4 = pr; }
        pr = pr * lam / (k + 1) as f64;
    }
    println!("Poisson sums: E[(N_1-4)^2] = {:.6}, E[N_1^2] = {:.6}, P(N_1 = 4) = {:.6}", e2c, e2, p4);
    assert!((e2c - lam).abs() < 1e-12 && (e2 - lam - lam * lam).abs() < 1e-12);
    for slots in [60.0f64, 3600.0] {
        let pp = lam / slots;
        let mut step = 0.0;
        for m in [-3.5f64, 0.0, 2.25] { // recipe one slot ahead, from the two outcomes
            step = pp * (m + 1.0 - pp).powi(2) + (1.0 - pp) * (m - pp).powi(2) - m * m;
            assert!((step - pp * (1.0 - pp)).abs() < 1e-12);
        }
        println!("{:.0} slots an hour: trend of (N - 4t)^2 over the hour = {:.6}", slots, slots * step);
    }
    let (mut rng, h) = (Rng { s: 20261124 }, 20000usize);
    let mut counts: Vec<f64> = Vec::new();
    for _ in 0..h {
        let (mut t, mut c) = (-(1.0 - rng.u()).ln() / lam, 0.0f64);
        while t <= 1.0 { c += 1.0; t -= (1.0 - rng.u()).ln() / lam; }
        counts.push(c);
    }
    println!("hour 1 of the simulation: N_1 = {}, so [M]_1 = {}; <M>_1 = 4", counts[0], counts[0]);
    let dev: Vec<f64> = counts.iter().map(|c| (c - lam).powi(2)).collect();
    let is4: Vec<f64> = counts.iter().map(|&c| if c == 4.0 { 1.0 } else { 0.0 }).collect();
    let sqr: Vec<f64> = counts.iter().map(|c| c * c).collect();
    for (name, xs, want) in [("E[N_1]", &counts, lam), ("E[(N_1-4)^2] = E<M>_1", &dev, lam),
                             ("P(N_1 = 4)", &is4, p4), ("mistake E[N_1^2]", &sqr, e2)] {
        let (m, se) = mean_se(xs);
        println!("sim {} hours: {} = {:.4} +- {:.4}", h, name, m, se);
        assert!((m - want).abs() < 4.0 * se);
    }
    println!("8-hour shift: <M>_8 = {:.0}, spread sqrt(32) = {:.6} calls", 8.0 * lam, (8.0 * lam).sqrt());
    println!("ALL CHECKS PASS");
}
