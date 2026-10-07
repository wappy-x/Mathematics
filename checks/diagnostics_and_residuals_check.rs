// Diagnostics and residuals -- the same check as the Python, in Rust.  No crates.
// Nine house sales, one of them a mansion: which sale is steering the line?
// Road 1: the leverage formulas.  Road 2: brute force -- nudge a price, or delete a sale,
// and refit.  Road 3: a seeded simulation of 50 sales whose spread grows with size.
const AREA: [f64; 9] = [80.0, 100.0, 110.0, 120.0, 140.0, 150.0, 170.0, 190.0, 600.0];
const PRICE: [f64; 9] = [350.0, 390.0, 450.0, 440.0, 530.0, 540.0, 610.0, 650.0, 1400.0];
const N: usize = 9;
const P: f64 = 2.0;
const M: usize = 8;

fn mean(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 }

fn fit(x: &[f64], y: &[f64]) -> (f64, f64) {                    // least squares line
    let (mx, my) = (mean(x), mean(y));
    let sxx: f64 = x.iter().map(|a| (a - mx) * (a - mx)).sum();
    let b = x.iter().zip(y).map(|(a, c)| (a - mx) * (c - my)).sum::<f64>() / sxx;
    (my - b * mx, b)
}

fn resid(x: &[f64], y: &[f64], a: f64, b: f64) -> Vec<f64> {
    x.iter().zip(y).map(|(v, c)| c - (a + b * v)).collect()
}

fn drop(v: &[f64], i: usize) -> Vec<f64> { [&v[..i], &v[i + 1..]].concat() }

struct Rng(u64);
impl Rng {                                                        // SplitMix64
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn normal(&mut self) -> f64 {
        let u1 = self.unif();
        let u2 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let (a, b) = fit(&AREA, &PRICE);
    let e = resid(&AREA, &PRICE, a, b);
    let s = (e.iter().map(|r| r * r).sum::<f64>() / (N as f64 - P)).sqrt();
    let mx = mean(&AREA);
    let sxx: f64 = AREA.iter().map(|v| (v - mx) * (v - mx)).sum();
    let h: Vec<f64> = AREA.iter().map(|v| 1.0 / N as f64 + (v - mx) * (v - mx) / sxx).collect();
    let mut h_nudge = vec![0.0; N];
    for i in 0..N {                                               // road 2: lift one price by 1, refit
        let mut y2 = PRICE.to_vec();
        y2[i] += 1.0;
        let (a2, b2) = fit(&AREA, &y2);
        h_nudge[i] = (a2 + b2 * AREA[i]) - (a + b * AREA[i]);
    }
    let r: Vec<f64> = (0..N).map(|i| e[i] / (s * (1.0 - h[i]).sqrt())).collect();
    let (mut t_f, mut t_r, mut d_f, mut d_r, mut del_f, mut del_r) = (vec![], vec![], vec![], vec![], vec![], vec![]);
    let nf = N as f64;
    for i in 0..N {
        let s_i2 = ((nf - P) * s * s - e[i] * e[i] / (1.0 - h[i])) / (nf - P - 1.0);
        t_f.push(e[i] / (s_i2.sqrt() * (1.0 - h[i]).sqrt()));      // road 1: external, by formula
        d_f.push(r[i] * r[i] * h[i] / (P * (1.0 - h[i])));         // road 1: Cook's distance
        del_f.push(e[i] / (1.0 - h[i]));                           // road 1: deletion residual
        let (xa, ya) = (drop(&AREA, i), drop(&PRICE, i));          // road 2: delete the sale, refit
        let (ai, bi) = fit(&xa, &ya);
        let ei = resid(&xa, &ya, ai, bi);
        let si = (ei.iter().map(|q| q * q).sum::<f64>() / (nf - 1.0 - P)).sqrt();
        del_r.push(PRICE[i] - (ai + bi * AREA[i]));
        let mi = mean(&xa);
        let sxx_i: f64 = xa.iter().map(|v| (v - mi) * (v - mi)).sum();
        t_r.push(del_r[i] / (si * (1.0 + 1.0 / (nf - 1.0) + (AREA[i] - mi).powi(2) / sxx_i).sqrt()));
        d_r.push(AREA.iter().map(|v| (a + b * v - ai - bi * v).powi(2)).sum::<f64>() / (P * s * s));
    }
    let name = |i: usize| if i == M { "mansion".to_string() } else { format!("{:>7}", i + 1) };
    println!("house   area  price  fitted  resid  leverage  lev by nudge");
    for i in 0..N {
        println!("{}{:>6}{:>7}{:>8.1}{:>7.1}{:>10.3}{:>14.3}", name(i), AREA[i], PRICE[i], a + b * AREA[i], e[i], h[i], h_nudge[i]);
    }
    println!("house   studentized  external  ext by refit   Cook's D  D by refit");
    for i in 0..N {
        println!("{}{:>13.2}{:>10.2}{:>14.2}{:>11.3}{:>12.3}", name(i), r[i], t_f[i], t_r[i], d_f[i], d_r[i]);
    }
    let (a0, b0) = fit(&AREA[..M], &PRICE[..M]);
    let e0 = resid(&AREA[..M], &PRICE[..M], a0, b0);
    let s0 = (e0.iter().map(|q| q * q).sum::<f64>() / (M as f64 - P)).sqrt();
    let m0 = mean(&AREA[..M]);
    let sxx0: f64 = AREA[..M].iter().map(|v| (v - m0) * (v - m0)).sum();
    println!("fit with the mansion:    intercept {:.2}, slope {:.4} (SE {:.4}), i.e. ${:.0} per m2; s = {:.2}",
             a, b, s / sxx.sqrt(), b * 1000.0, s);
    println!("fit without the mansion: intercept {:.2}, slope {:.4} (SE {:.4}), i.e. ${:.0} per m2; s = {:.2}",
             a0, b0, s0 / sxx0.sqrt(), b0 * 1000.0, s0);
    let dm = AREA[M] - mx;
    println!("mansion by hand: 1/N {:.4}; area - mean {:.2}; squared {:.1}; over Sxx {:.4}; leverage {:.4}",
             1.0 / nf, dm, dm * dm, dm * dm / sxx, h[M]);
    println!("mansion by hand: 1 - h {:.4}; root {:.3} (house 1: {:.3}); s x root {:.2}; r squared {:.2}",
             1.0 - h[M], (1.0 - h[M]).sqrt(), (1.0 - h[0]).sqrt(), s * (1.0 - h[M]).sqrt(), r[M] * r[M]);
    let zero = e.iter().sum::<f64>().abs() < 1e-9 && AREA.iter().zip(&e).map(|(v, q)| v * q).sum::<f64>().abs() < 1e-9;
    println!("mean area {:.2}; Sxx {:.2}; residuals and area x residual both sum to 0: {}; sum of leverages {:.4}",
             mx, sxx, if zero { "yes" } else { "no" }, h.iter().sum::<f64>());
    println!("flag lines: leverage above 2P/N = {:.3}; Cook's D above 1", 2.0 * P / nf);
    println!("mansion's deletion residual: formula {:.1}, refit {:.1}; line without it predicts {:.1} for 600 m2",
             del_f[M], del_r[M], a0 + b0 * 600.0);
    let rank = (0..N).filter(|&i| e[i].abs() > e[M].abs()).count() + 1;
    println!("mistake, raw residual: mansion's |residual| {:.1} ranks {} of {} by size", e[M].abs(), rank, N);
    println!("mistake, one line for all: a 150 m2 house priced {:.1} with the mansion, {:.1} without", a + b * 150.0, a0 + b0 * 150.0);
    println!("mistake, extrapolating: 600 m2 predicted {:.1}, sold {}", a0 + b0 * 600.0, PRICE[M]);
    let sx = |v: f64| 40.0 + 0.45 * v;                            // figure 1: price against area
    let sy = |p: f64| 210.0 - 0.09 * p;
    let pts: Vec<String> = (0..N).map(|i| format!("({:.1},{:.1})", sx(AREA[i]), sy(PRICE[i]))).collect();
    println!("figure, houses {}", pts.join(" "));
    println!("figure, line with mansion ({:.1},{:.1}) ({:.1},{:.1}); without ({:.1},{:.1}) ({:.1},{:.1})",
             sx(60.0), sy(a + b * 60.0), sx(620.0), sy(a + b * 620.0), sx(60.0), sy(a0 + b0 * 60.0), sx(620.0), sy(a0 + b0 * 620.0));
    let pts: Vec<String> = (0..N).map(|i| format!("({:.1},{:.1})", 40.0 + 0.25 * (a + b * AREA[i] - 300.0), 120.0 - 2.0 * e[i])).collect();
    println!("figure, residual plot {}", pts.join(" "));

    let mut rng = Rng(20260928);                                  // road 3: SplitMix64, seed 20260928
    let (sales, reps) = (50usize, 4000usize);
    let xs: Vec<f64> = (0..sales).map(|_| 60.0 + 180.0 * rng.unif()).collect();
    let xm = mean(&xs);
    let sxx50: f64 = xs.iter().map(|v| (v - xm) * (v - xm)).sum();
    println!("simulation: {} sales, areas 60 to 240 m2, true price 120 + 2.8 x area, {} runs, seed 20260928; \
              spread 40, or 40 x (area/150)^2", sales, reps);
    for (label, funnel) in [("even spread", false), ("funnel", true)] {
        let sd = |v: f64| if funnel { 40.0 * (v / 150.0).powi(2) } else { 40.0 };
        let exact = xs.iter().map(|&v| (v - xm).powi(2) * sd(v).powi(2)).sum::<f64>().sqrt() / sxx50;
        let (mut slopes, mut ses, mut hits, mut small, mut big) = (vec![], vec![], 0usize, 0.0, 0.0);
        for _ in 0..reps {
            let ys: Vec<f64> = xs.iter().map(|&v| 120.0 + 2.8 * v + sd(v) * rng.normal()).collect();
            let (a5, b5) = fit(&xs, &ys);
            let e5 = resid(&xs, &ys, a5, b5);
            let se = (e5.iter().map(|q| q * q).sum::<f64>() / (sales as f64 - P) / sxx50).sqrt();
            slopes.push(b5); ses.push(se);
            if (b5 - 2.8).abs() <= 2.0 * se { hits += 1 }
            small += xs.iter().zip(&e5).filter(|(v, _)| **v < 120.0).map(|(_, q)| q.abs()).sum::<f64>() / reps as f64;
            big += xs.iter().zip(&e5).filter(|(v, _)| **v >= 180.0).map(|(_, q)| q.abs()).sum::<f64>() / reps as f64;
        }
        let rf = reps as f64;
        let sm = slopes.iter().sum::<f64>() / rf;
        let sim = (slopes.iter().map(|q| (q - sm).powi(2)).sum::<f64>() / (rf - 1.0)).sqrt();
        let cover = hits as f64 / rf;
        let mse = ses.iter().sum::<f64>() / rf;
        let nsm = xs.iter().filter(|v| **v < 120.0).count() as f64;
        let nbg = xs.iter().filter(|v| **v >= 180.0).count() as f64;
        println!("{}: slope mean {:.4}; true SD exact {:.4}, simulated {:.4} (+/- {:.4}); textbook SE {:.4}",
                 label, sm, exact, sim, sim / (2.0 * (rf - 1.0)).sqrt(), mse);
        println!("{}: b +/- 2 SE covers 2.8 in {:.4} (+/- {:.4}); mean |resid| below 120 m2 {:.1}, 180 m2 and up {:.1}",
                 label, cover, (cover * (1.0 - cover) / rf).sqrt(), small / nsm, big / nbg);
        assert!((sim - exact).abs() < 4.0 * sim / (2.0 * (rf - 1.0)).sqrt());   // simulation agrees with the exact spread
        if funnel { assert!(cover < 0.93 && mse < 0.9 * exact) }
    }
    assert!((0..N).all(|i| (h[i] - h_nudge[i]).abs() < 1e-9));   // leverage: formula = nudge-and-refit
    assert!((h.iter().sum::<f64>() - P).abs() < 1e-12);            // leverages add up to the line's 2 numbers
    assert!((0..N).all(|i| (d_f[i] - d_r[i]).abs() < 1e-9 * (1.0 + d_r[i])));   // Cook's D: formula = deletion
    assert!((0..N).all(|i| (t_f[i] - t_r[i]).abs() < 1e-9 && (del_f[i] - del_r[i]).abs() < 1e-9));
    println!("ALL CHECKS PASS");
}
