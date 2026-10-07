// The volatility surface: assemble quotes, interpolate total variance against
// log-moneyness, test butterflies and calendars, repair a bad point. std only.
use std::f64::consts::PI;

const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; // house spot, rate, dividend yield
const TS: [f64; 3] = [0.25, 0.5, 1.0];
const TL: [&str; 3] = ["0.25", "0.5", "1.0"];
const QUOTES: [[f64; 9]; 3] = [
    [28.61, 24.77, 21.61, 19.05, 17.00, 15.39, 14.17, 13.28, 12.69], // implied vols, %
    [27.43, 24.38, 21.84, 19.73, 18.00, 16.59, 15.47, 14.60, 13.95],
    [27.79, 25.33, 23.24, 21.48, 20.00, 18.76, 17.74, 16.90, 16.22],
];

fn ks() -> Vec<f64> { (0..9).map(|i| 80.0 + 5.0 * i as f64).collect() }

fn ncdf(x: f64) -> f64 { // normal CDF, Marsaglia's series
    if x.abs() > 8.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut n) = (x, x, 1.0);
    while t.abs() > 1e-17 { t *= x * x / (2.0 * n + 1.0); s += t; n += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn fwd(t: f64) -> f64 { S * ((R - Q) * t).exp() }

fn call(k: f64, t: f64, vol: f64) -> f64 { // Black-Scholes call, vol as a decimal
    let (f, v) = (fwd(t), vol * t.sqrt());
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    (-R * t).exp() * (f * ncdf(d1) - k * ncdf(d1 - v))
}

fn implied(price: f64, k: f64, t: f64) -> f64 { // bisection: price rises strictly with vol
    let (mut lo, mut hi) = (1e-4, 3.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if call(k, t, mid) < price { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn nodes(t: f64, vols: &[f64]) -> (Vec<f64>, Vec<f64>) { // (log-moneyness k, total variance w)
    (ks().iter().map(|k| (k / fwd(t)).ln()).collect(), vols.iter().map(|v| t * (v / 100.0).powi(2)).collect())
}

fn interp(k: &[f64], w: &[f64], x: f64) -> Option<f64> { // linear in k; None outside the range
    for i in 0..k.len() - 1 {
        if k[i] - 1e-12 <= x && x <= k[i + 1] + 1e-12 {
            return Some(w[i] + (w[i + 1] - w[i]) * (x - k[i]) / (k[i + 1] - k[i]));
        }
    }
    None
}

fn butterflies(t: f64, vols: &[f64]) -> Vec<f64> { // road 1: price of the 1-2-1 butterfly
    let c: Vec<f64> = ks().iter().zip(vols).map(|(k, v)| call(*k, t, v / 100.0)).collect();
    (1..8).map(|i| c[i - 1] - 2.0 * c[i] + c[i + 1]).collect()
}

fn durrleman(t: f64, vols: &[f64]) -> Vec<f64> { // road 2: density from w, w', w''
    let (k, ws) = nodes(t, vols);
    let kk = ks();
    (1..8).map(|i| {
        let (h1, h2, w) = (k[i] - k[i - 1], k[i + 1] - k[i], ws[i]);
        let w1 = -h2 * ws[i - 1] / (h1 * (h1 + h2)) + (h2 - h1) * w / (h1 * h2) + h1 * ws[i + 1] / (h2 * (h1 + h2));
        let w2 = 2.0 * (h2 * ws[i - 1] - (h1 + h2) * w + h1 * ws[i + 1]) / (h1 * h2 * (h1 + h2));
        let g = (1.0 - k[i] * w1 / (2.0 * w)).powi(2) - w1 * w1 / 4.0 * (1.0 / w + 0.25) + w2 / 2.0;
        let d2 = -k[i] / w.sqrt() - w.sqrt() / 2.0;
        g * (-0.5 * d2 * d2).exp() / (2.0 * PI).sqrt() / (kk[i] * w.sqrt())
    }).collect()
}

fn calendar(ts: f64, vs: &[f64], tl: f64, vl: &[f64]) -> Vec<[f64; 4]> {
    let ((a_k, a_w), (b_k, b_w)) = (nodes(ts, vs), nodes(tl, vl));
    let mut all: Vec<f64> = a_k.iter().chain(b_k.iter()).cloned().collect();
    all.sort_by(|x, y| x.partial_cmp(y).unwrap());
    all.dedup();
    let mut rows = Vec::new();
    for k in all {
        if let (Some(a), Some(b)) = (interp(&a_k, &a_w, k), interp(&b_k, &b_w, k)) {
            let cs = call(fwd(ts) * k.exp(), ts, (a / ts).sqrt()) / ((-R * ts).exp() * fwd(ts));
            let cl = call(fwd(tl) * k.exp(), tl, (b / tl).sqrt()) / ((-R * tl).exp() * fwd(tl));
            rows.push([k, b - a, cl - cs, (b / tl).sqrt() - (a / ts).sqrt()]);
        }
    }
    rows
}

fn f(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:8.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn minv(xs: &[f64]) -> f64 { xs.iter().cloned().fold(f64::INFINITY, f64::min) }

fn main() {
    let kk = ks();
    println!("strike        {}", f(&kk, 0));
    for j in 0..3 { println!("vol % T={:<4}   {}   forward {:.4}", TL[j], f(&QUOTES[j], 2), fwd(TS[j])); }
    let c1: Vec<f64> = kk.iter().zip(QUOTES[2].iter()).map(|(k, v)| call(*k, 1.0, v / 100.0)).collect();
    println!("call $ T=1.0   {}", f(&c1, 4));
    for j in 0..3 {
        let w: Vec<f64> = nodes(TS[j], &QUOTES[j]).1.iter().map(|w| 100.0 * w).collect();
        println!("w x100 T={:<4}  {}", TL[j], f(&w, 4));
    }
    for j in 0..3 { // butterfly test, clean surface, two roads
        let (b, d) = (butterflies(TS[j], &QUOTES[j]), durrleman(TS[j], &QUOTES[j]));
        let gap = b.iter().zip(&d).map(|(x, y)| (x * (R * TS[j]).exp() / 25.0 / y - 1.0).abs()).fold(0.0, f64::max);
        println!("clean T={:<4} min butterfly {:.4}  min density {:.5}  roads differ <= {:.1}%", TL[j], minv(&b), minv(&d), 100.0 * gap);
    }
    let mut dip = QUOTES[2].to_vec(); dip[4] = 18.0; // plant a dip at the 1-year 100 strike
    let (b, d) = (butterflies(1.0, &dip), durrleman(1.0, &dip));
    let dp: Vec<f64> = b.iter().map(|x| x * R.exp() / 25.0).collect();
    println!("dip   strikes   {}", f(&kk[1..8], 0));
    println!("dip   butterfly {}\ndip   dens price{}\ndip   dens w    {}", f(&b, 4), f(&dp, 5), f(&d, 5));
    let c: Vec<f64> = kk.iter().zip(&dip).map(|(k, v)| call(*k, 1.0, v / 100.0)).collect();
    let (lo, hi) = ((2.0 * c[3] - c[2]).max(2.0 * c[5] - c[6]), 0.5 * (c[3] + c[5]));
    let (vlo, vhi) = (implied(lo, 100.0, 1.0), implied(hi, 100.0, 1.0));
    let (k1, w1n) = nodes(1.0, &dip);
    let wfill = w1n[3] + (w1n[5] - w1n[3]) * (k1[4] - k1[3]) / (k1[5] - k1[3]);
    let vfill = 100.0 * wfill.sqrt();
    let mut fixed = dip.clone(); fixed[4] = vfill;
    println!("band price {:.4} to {:.4}  vol {:.4} to {:.4}  dipped price {:.4}", lo, hi, 100.0 * vlo, 100.0 * vhi, c[4]);
    let bf = butterflies(1.0, &fixed);
    println!("refill vol {:.4}  butterflies 95/100/105 after {:.4} {:.4} {:.4}", vfill, bf[2], bf[3], bf[4]);
    for (s, l) in [(0usize, 1usize), (1, 2)] { // calendar test, clean surface
        let rows = calendar(TS[s], &QUOTES[s], TS[l], &QUOTES[l]);
        let (gw, gp): (Vec<f64>, Vec<f64>) = (rows.iter().map(|x| x[1]).collect(), rows.iter().map(|x| x[2]).collect());
        println!("clean {}->{}: min w gap {:.5}  min price gap {:.5}  vol falls at {} of {} nodes",
                 TL[s], TL[l], minv(&gw), minv(&gp), rows.iter().filter(|x| x[3] < 0.0).count(), rows.len());
    }
    let lift: Vec<f64> = QUOTES[1].iter().map(|v| v + 10.0).collect(); // 6-month row keyed 10 high
    let rows = calendar(0.5, &lift, 1.0, &QUOTES[2]);
    let pick = |col: usize, by: usize| -> Vec<f64> { rows.iter().filter(|x| x[by] < 0.0).map(|x| x[col]).collect() };
    println!("lift  k       {}\nlift  w gap   {}\nlift  price gp{}", f(&pick(0, 1), 4), f(&pick(1, 1), 5), f(&pick(2, 2), 5));
    let up: Vec<bool> = (0..9).map(|i| 0.5 * lift[i].powi(2) > QUOTES[2][i].powi(2)).collect(); // wrong road
    let names: Vec<String> = (0..9).filter(|&i| up[i]).map(|i| format!("{:.0}", kk[i])).collect();
    println!("same-strike test flags {} of 9: {}", names.len(), names.join(" "));
    let fv = |w6: f64, w1: f64| (w1 - w6) / 0.5; // forward variance, 6 months to 1 year
    let (w6a, w1a, w6l) = (nodes(0.5, &QUOTES[1]).1[4], nodes(1.0, &QUOTES[2]).1[4], nodes(0.5, &lift).1[4]);
    let (n1k, n1w) = nodes(1.0, &QUOTES[2]);
    let same_k = fv(w6l, interp(&n1k, &n1w, (100.0 / fwd(0.5)).ln()).unwrap());
    println!("forward var 6m-1y clean {:.6} (vol {:.4})  lifted: same strike {:.6}  same k {:.6}",
             fv(w6a, w1a), 100.0 * fv(w6a, w1a).sqrt(), fv(w6l, w1a), same_k);
    let k9 = (100.0 / fwd(0.75)).ln(); // a 9-month vol at strike 100, between the rows
    let (n6k, n6w) = nodes(0.5, &QUOTES[1]);
    let (w6, w1) = (interp(&n6k, &n6w, k9).unwrap(), interp(&n1k, &n1w, k9).unwrap());
    let (w9, naive) = (w6 + (w1 - w6) * 0.5, 0.5 * (QUOTES[1][4] + QUOTES[2][4]));
    println!("9-month K=100: k {:.4}  w6 {:.5}  w1 {:.5}  vol {:.4}  naive vol {:.4}", k9, w6, w1, 100.0 * (w9 / 0.75).sqrt(), naive);
    let grid: Vec<f64> = (0..8).map(|i| -0.20 + 0.05 * i as f64).collect();
    println!("chart k       {}", f(&grid, 2));
    for (lab, t, v) in [("3m", 0.25, QUOTES[0].to_vec()), ("6m", 0.5, QUOTES[1].to_vec()), ("1y", 1.0, QUOTES[2].to_vec()), ("6m+10", 0.5, lift.clone())] {
        let (nk, nw) = nodes(t, &v);
        let row: Vec<f64> = grid.iter().map(|k| 100.0 * interp(&nk, &nw, *k).unwrap()).collect();
        println!("chart w {:<6}{}", lab, f(&row, 2));
    }
    for (lab, v) in [("clean", QUOTES[2].to_vec()), ("dip", dip.clone()), ("refill", fixed.clone())] {
        let row: Vec<f64> = butterflies(1.0, &v).iter().map(|x| 100.0 * x * R.exp() / 25.0).collect();
        println!("chart dens {:<7}{}", lab, f(&row, 2));
    }
    assert!((call(100.0, 1.0, 0.20) - 9.227005508154).abs() < 1e-9, "house call from the pilot card");
    assert!((fv(w6a, w1a).sqrt() - 0.2182).abs() < 5e-5, "house forward vol 21.82%");
    for j in 0..3 {
        let (b, d) = (butterflies(TS[j], &QUOTES[j]), durrleman(TS[j], &QUOTES[j]));
        assert!(minv(&b) > 0.0 && minv(&d) > 0.0, "clean slices pass");
        assert!(b.iter().zip(&d).all(|(x, y)| (x * (R * TS[j]).exp() / 25.0 / y - 1.0).abs() < 0.15), "two density roads agree");
    }
    let neg = |xs: &[f64]| -> Vec<usize> { (0..xs.len()).filter(|&i| xs[i] < 0.0).collect() };
    assert!(neg(&b) == neg(&d) && neg(&b) == vec![2, 4], "95 and 105");
    assert!(18.0 < 100.0 * vlo && 100.0 * vlo < 20.0 && 20.0 < vfill && vfill < 100.0 * vhi, "band holds clean and refill");
    for v in [vlo, vhi] { let mut e = dip.clone(); e[4] = 100.0 * v; assert!(minv(&butterflies(1.0, &e)[2..5]).abs() < 1e-9, "band edge: a butterfly hits 0"); }
    assert!(rows.iter().all(|x| (x[1] < 0.0) == (x[2] < 0.0)), "calendar: variance and price roads agree");
    assert!(pick(0, 1).len() == 9 && names.len() == 4, "same forward moneyness sees more than same strike");
    println!("ALL CHECKS PASS");
}
