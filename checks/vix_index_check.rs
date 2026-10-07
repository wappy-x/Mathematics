// The VIX recipe on the house index: Cboe's discrete strip, two expiries, 30-day blend.
// Roads: 1 the exchange's discrete sum, 2 a fine Simpson integral of the strip, 3 the
// density read off call prices (second difference) averaged against the log payoff.
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; // index level, rate, dividend yield
const N1: f64 = 23.0; const N2: f64 = 37.0; const N30: f64 = 30.0; const N365: f64 = 365.0;
const CUT: f64 = 0.001; // an option worth under a tenth of a cent has a zero bid
const PI: f64 = std::f64::consts::PI;

fn ncdf(x: f64) -> f64 { // normal CDF by Marsaglia's series, no library
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut n) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { n += 2.0; t *= x * x / n; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn flat(_k: f64) -> f64 { 0.20 }
fn skew(k: f64) -> f64 { (0.0325 + 0.15 * (-0.7 * k + (k * k + 0.0025).sqrt())).sqrt() } // 20% at k = 0
type Vol = fn(f64) -> f64;
fn fwd(t: f64) -> f64 { S * ((R - Q) * t).exp() }
fn price(k: f64, t: f64, vol: Vol, call: bool) -> f64 { // Black-Scholes on the forward
    let f = fwd(t); let sd = vol((k / f).ln()) * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * sd * sd) / sd; let d2 = d1 - sd;
    if call { (-R * t).exp() * (f * ncdf(d1) - k * ncdf(d2)) } else { (-R * t).exp() * (k * ncdf(-d2) - f * ncdf(-d1)) }
}
fn listed(wide: bool) -> Vec<f64> { // $0.10 apart from 80 to 120 and $0.50 outside; or $5 everywhere
    if wide { return (0..49).map(|i| 10.0 + 5.0 * i as f64).collect(); }
    let mut v: Vec<f64> = (0..140).map(|i| 10.0 + 0.5 * i as f64).collect();
    v.extend((0..400).map(|i| (800 + i) as f64 / 10.0));
    v.extend((0..261).map(|i| 120.0 + 0.5 * i as f64));
    v
}
struct Cb { f: f64, k0: f64, n: usize, lo: f64, hi: f64, strip: f64, corr: f64, var: f64 }
fn cboe(t: f64, vol: Vol, ks: &[f64], fix: bool, cut: f64, itm: bool) -> Cb {
    let c: Vec<f64> = ks.iter().map(|&k| price(k, t, vol, true)).collect();
    let p: Vec<f64> = ks.iter().map(|&k| price(k, t, vol, false)).collect();
    let mut j = 0; // where call and put are closest
    for i in 1..ks.len() { if (c[i] - p[i]).abs() < (c[j] - p[j]).abs() { j = i; } }
    let f = ks[j] + (R * t).exp() * (c[j] - p[j]); // parity gives the forward
    let i0 = (0..ks.len()).filter(|&i| ks[i] <= f).max().unwrap(); let k0 = ks[i0];
    let mut used = vec![i0];
    for step in [-1i64, 1] { // walk outward; stop after two zero bids in a row
        let (mut i, mut zeros) = (i0 as i64 + step, 0);
        while i >= 0 && (i as usize) < ks.len() && zeros < 2 {
            let u = i as usize;
            if (if step < 0 { p[u] } else { c[u] }) < cut { zeros += 1; } else { zeros = 0; used.push(u); }
            i += step;
        }
    }
    used.sort(); let m = used.len(); let mut total = 0.0;
    for (n, &i) in used.iter().enumerate() {
        let k = ks[i];
        let qv = if k > k0 || (itm && k < k0) { c[i] } else if k < k0 { p[i] } else { 0.5 * (p[i] + c[i]) };
        let lo = ks[used[n.saturating_sub(1)]]; let hi = ks[used[(n + 1).min(m - 1)]];
        let dk = (hi - lo) / (if n > 0 && n < m - 1 { 2.0 } else { 1.0 });
        total += dk / (k * k) * (R * t).exp() * qv;
    }
    let corr = (f / k0 - 1.0).powi(2) / t;
    Cb { f, k0, n: m, lo: ks[used[0]], hi: ks[used[m - 1]], strip: 2.0 * total / t, corr,
         var: 2.0 * total / t - if fix { corr } else { 0.0 } }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn strip_integral(t: f64, vol: Vol) -> f64 { // (2 e^{rT}/T) * integral of Q(K)/K^2, K = F e^u
    let f = fwd(t);
    let put = |u: f64| price(f * u.exp(), t, vol, false) * (-u).exp() / f;
    let call = |u: f64| price(f * u.exp(), t, vol, true) * (-u).exp() / f;
    2.0 * (R * t).exp() / t * (simpson(&put, -3.0, 0.0, 3000) + simpson(&call, 0.0, 3.0, 3000))
}
fn density_road(t: f64, vol: Vol) -> (f64, usize) { // q(K) = e^{rT} C''(K)
    let f = fwd(t);
    let g = |u: f64| {
        let k = f * u.exp(); let h = 2e-4 * k;
        let dens = (R * t).exp() * (price(k + h, t, vol, true) - 2.0 * price(k, t, vol, true)
            + price(k - h, t, vol, true)) / (h * h);
        dens * (k / f - 1.0 - u) * k // dK = K du
    };
    let bad = (1..460).filter(|&i| { let k = 20.0 + 0.5 * i as f64;
        price(k - 0.5, t, vol, true) - 2.0 * price(k, t, vol, true) + price(k + 0.5, t, vol, true) < -1e-12 }).count();
    (2.0 / t * simpson(&g, -3.0, 3.0, 6000), bad)
}
fn vix(v1: f64, v2: f64, by_vol: bool) -> f64 { // interpolate in total variance to 30 days
    let (t1, t2) = (N1 / N365, N2 / N365); let w1 = (N2 - N30) / (N2 - N1);
    if by_vol { return 100.0 * (w1 * v1.sqrt() + (1.0 - w1) * v2.sqrt()); }
    100.0 * ((t1 * v1 * w1 + t2 * v2 * (1.0 - w1)) * N365 / N30).sqrt()
}
fn broke(vol: Vol, wide: bool, fix: bool, cut: f64, itm: bool) -> f64 {
    let ks = listed(wide);
    vix(cboe(N1 / N365, vol, &ks, fix, cut, itm).var, cboe(N2 / N365, vol, &ks, fix, cut, itm).var, false)
}
fn main() {
    let (t1, t2) = (N1 / N365, N2 / N365); let ks = listed(false);
    let surfaces: [(&str, Vol); 2] = [("flat", flat), ("skew", skew)];
    let mut names = vec![]; let mut rows: Vec<Vec<f64>> = vec![];
    for (name, vol) in surfaces.iter() {
        for (t, lab) in [(t1, "23d"), (t2, "37d")] {
            let c = cboe(t, *vol, &ks, true, CUT, false); let (d, bad) = density_road(t, *vol);
            names.push(format!("{} {}", name, lab));
            rows.push(vec![t, c.f, fwd(t), c.k0, c.n as f64, c.lo, c.hi, c.strip, c.corr, c.var,
                           strip_integral(t, *vol), d, bad as f64]);
        }
    }
    let labels = ["years to expiry T", "forward by parity", "forward S e^(r-q)T", "K0, strike below F", "strikes used",
        "lowest strike used", "highest strike used", "strip term (2/T) sum", "correction (F/K0-1)^2/T", "1 Cboe variance",
        "2 Simpson strip variance", "3 density road variance", "negative butterflies"];
    let mut line = format!("{:<26}", "house index, per expiry");
    for n in &names { line += &format!("{:>11}", n); }
    println!("{}", line);
    for (i, lab) in labels.iter().enumerate() {
        let mut line = format!("{:<26}", lab);
        for v in &rows { line += &if i == 4 || i == 12 { format!("{:>11.0}", v[i]) } else { format!("{:>11.6}", v[i]) }; }
        println!("{}", line);
    }
    let mut vx = vec![];
    for s in 0..2 {
        let (a, b) = (&rows[2 * s], &rows[2 * s + 1]);
        vx.push([vix(a[9], b[9], false), vix(a[10], b[10], false), vix(a[11], b[11], false)]);
    }
    let w1 = (N2 - N30) / (N2 - N1);
    println!();
    println!("weights on 23d and 37d: {:.2} and {:.2}", w1, (N30 - N1) / (N2 - N1));
    for s in 0..2 {
        let (p1, p2) = (t1 * rows[2 * s][9] * w1, t2 * rows[2 * s + 1][9] * (1.0 - w1));
        let nm = surfaces[s].0;
        println!("{} blend: 23d part {:.6}  37d part {:.6}  times 365/30 {:.6}", nm, p1, p2, (p1 + p2) * N365 / N30);
        println!("{} VIX: 1 Cboe {:.4}   2 Simpson {:.4}   3 density {:.4}", nm, vx[s][0], vx[s][1], vx[s][2]);
    }
    println!("at-the-money vol on both surfaces: {:.4}   30-day forward {:.4}", 100.0 * skew(0.0), fwd(N30 / N365));
    println!();
    println!("wrong: in-the-money calls below K0, flat {:.4}", broke(flat, false, true, CUT, true));
    println!("wrong: strikes $5 apart, flat            {:.4}", broke(flat, true, true, CUT, false));
    println!("wrong: strikes $5 apart, skew            {:.4}", broke(skew, true, true, CUT, false));
    println!("wrong: blend vols not variances, skew    {:.4}", vix(rows[2][9], rows[3][9], true));
    println!("wrong: 23-day strip alone, skew          {:.4}", 100.0 * rows[2][9].sqrt());
    println!("try: keep near-zero bids too, skew       {:.4}", broke(skew, false, true, 0.0, false));
    println!("try: drop the (F/K0-1)^2 term, flat      {:.4}", broke(flat, false, false, CUT, false));
    println!();
    let chart: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let f30 = fwd(N30 / N365);
    let mut l1 = String::from("chart, strike           "); let mut l2 = String::from("chart, skew vol %, 30d  ");
    for (i, &k) in chart.iter().enumerate() {
        let sep = if i == 0 { "" } else { " " };
        l1 += &format!("{}{:6.0}", sep, k); l2 += &format!("{}{:6.2}", sep, 100.0 * skew((k / f30).ln()));
    }
    println!("{}", l1); println!("{}", l2);
    for (name, vol) in surfaces.iter() {
        let f = fwd(t1); let mut l = format!("chart, {} weight x1e4 ", name);
        for (i, &k) in chart.iter().enumerate() {
            let w = 2.0 * (R * t1).exp() / t1 * price(k, t1, *vol, k > f) / (k * k) * 1e4;
            l += &format!("{}{:6.2}", if i == 0 { "" } else { " " }, w);
        }
        println!("{}", l);
    }
    assert!((rows[0][1] - rows[0][2]).abs() < 1e-9, "parity forward must equal S e^(r-q)T");
    assert!((rows[1][10] - 0.04).abs() < 1e-7, "Simpson strip on a flat 20% surface must give 0.04");
    assert!((rows[2][10] - rows[2][11]).abs() < 1e-6, "23-day strip integral vs density road");
    assert!((rows[3][10] - rows[3][11]).abs() < 1e-6, "37-day strip integral vs density road");
    assert!((vx[0][0] - 20.0).abs() < 0.005, "Cboe recipe on the flat surface must print 20.00");
    assert!((vx[1][0] - vx[1][1]).abs() < 0.01, "discrete recipe within a hundredth of the integral");
    assert!(vx[1][0] > 100.0 * skew(0.0) + 0.5, "skew must lift the VIX above the at-the-money vol");
    let odd: Vec<f64> = (1..300).map(|i| 0.4 + i as f64).collect();
    let e = |fix: bool| (cboe(t1, flat, &odd, fix, CUT, false).var - rows[0][10]).abs();
    assert!(e(true) < e(false) / 3.0, "on $1 strikes with K0 = 99.40 the (F/K0-1)^2 term must cut the error");
    println!("ALL CHECKS PASS");
}
