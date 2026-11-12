// Adding a million numbers without losing the small ones -- the check behind the card.  std only.
// A tracker adds 0.1 m per tick, ten million ticks.  Plain, pairwise and Kahan sums meet the
// exact total of the stored 0.1 (whole numbers) and a range-by-range walk.
// Then a barometer stream: textbook one-pass variance against two-pass and Welford.
const U: f64 = 1.0 / 9007199254740992.0; // unit roundoff of a double, 2^-53
const U32: f64 = 1.0 / 16777216.0; // unit roundoff of a single, 2^-24
const N: usize = 10_000_000;

fn sci(x: f64, p: usize) -> String {
    format!("{:.*e}", p, x) // 1.610e-4, the same digits as Python
}
fn r64(v: f64) -> f64 { v }
fn r32(v: f64) -> f64 { v as f32 as f64 } // nearest single; a + or - of two singles rounds right
fn plain(xs: &[f64], r: fn(f64) -> f64) -> f64 { // left to right, one rounding per addition
    let mut t = 0.0;
    for &x in xs { t = r(t + x); }
    t
}
fn kahan(xs: &[f64], r: fn(f64) -> f64) -> f64 { // carry c, minus the part that fell off
    let (mut t, mut c) = (0.0f64, 0.0f64);
    for &x in xs {
        let y = r(x - c);
        let s = r(t + y);
        c = r(r(s - t) - y); // (s - t) is what got in; minus y leaves minus the loss
        t = s;
    }
    t
}
fn pairwise(xs: &[f64], r: fn(f64) -> f64) -> f64 { // add neighbours, then their sums, ...
    let mut a = xs.to_vec();
    while a.len() > 1 {
        let mut b: Vec<f64> = a.chunks_exact(2).map(|p| r(p[0] + p[1])).collect();
        if a.len() % 2 == 1 { b.push(a[a.len() - 1]); }
        a = b;
    }
    a[0]
}
fn walk(x: f64, n: usize, p: i32, r: fn(f64) -> f64) -> f64 { // second road to the plain total: inside
    let (mut k, mut t) = (1usize, x); // [2^E, 2^(E+1)) every step adds x rounded to the gap
    let mut e = ((x.to_bits() >> 52) & 0x7ff) as i32 - 1023;
    loop {
        let g = 2f64.powi(e - p);
        let a = (x / g).round_ties_even() * g;
        let steps = ((2f64.powi(e + 1) - t) / a).ceil() as usize;
        if k + steps > n { return t + (n - k) as f64 * a; }
        k += steps; t = r(t + (steps - 1) as f64 * a + x); e += 1; // the step into the next range rounds there
    }
}
fn err(t: f64, x: f64, n: usize) -> f64 { // true error, in whole units of 2^-60
    let s = 2f64.powi(60);
    ((t * s) as i128 - n as i128 * (x * s) as i128) as f64 / s
}
fn exact(x: f64, n: usize) -> f64 { (n as i128 * (x * 2f64.powi(60)) as i128) as f64 / 2f64.powi(60) }

fn main() {
    // ---- the tracker in double precision: ten million steps of 0.1 ----
    let x = 0.1f64;
    let xs = vec![x; N];
    let (tp, tk, tw) = (plain(&xs, r64), kahan(&xs, r64), pairwise(&xs, r64));
    let (ep, ek, ew) = (err(tp, x, N), err(tk, x, N), err(tw, x, N));
    let nf = N as f64;
    let total = nf * x;
    let l = (nf.log2()).ceil() as i32;
    let b_partial = U * x * (nf * (nf + 1.0) / 2.0 - 1.0);
    let b_plain = (nf - 1.0) * U / (1.0 - (nf - 1.0) * U) * total;
    let b_pair = l as f64 * U / (1.0 - l as f64 * U) * total;
    let b_kahan = 2.0 * U * total;
    let gap = 2f64.powi(-33);
    let s = 2f64.powi(60);
    println!("stored 0.1 minus 0.1,{}", sci(((x * s) as i128 * 10 - (1i128 << 60)) as f64 / s / 10.0, 3));
    println!("exact total of stored values minus 1e6,{}", sci(err(1e6, x, N) * -1.0, 3));
    println!("plain,{:.10},error,{},range walk,{:.10}", tp, sci(ep, 3), walk(x, N, 52, r64));
    println!("  bound u x sum of partial totals,{},ratio,{:.3}", sci(b_partial, 3), ep.abs() / b_partial);
    println!("  bound gamma_(n-1) x sum|x|,{},ratio,{:.3}", sci(b_plain, 3), ep.abs() / b_plain);
    println!("  each step from 524288 on adds 0.1 minus,{}", sci(x - ((2f64.powi(19) + x) - 2f64.powi(19)), 3));
    println!("pairwise,{:.10},error,{},levels,{}", tw, sci(ew, 3), l);
    println!("  bound gamma_{} x sum|x|,{},ratio,{:.3}", l, sci(b_pair, 3), ew.abs() / b_pair);
    println!("kahan,{:.10},error,{}", tk, sci(ek, 3));
    println!("  bound 2u x sum|x|,{},ratio,{:.3},n u^2 x sum|x|,{}", sci(b_kahan, 3), ek.abs() / b_kahan, sci(nf * U * U * total, 1));
    println!("gap near 1e6,{},half gap,{},u,{},u single,{}", sci(gap, 3), sci(gap / 2.0, 3), sci(U, 3), sci(U32, 3));
    assert!(walk(x, N, 52, r64) == tp); // two roads to the plain total, same bits
    assert!(ek.abs() <= gap / 2.0); // Kahan = exact total, rounded once
    assert!(ep.abs() < b_partial && ew.abs() < b_pair && ek.abs() < b_kahan);
    assert!(ep.abs() > 1e5 * ek.abs()); // plain is far worse than Kahan

    // ---- error against the number of ticks: the chart ----
    for k in 1..8 {
        let n = 10usize.pow(k);
        let ys = &xs[..n];
        let rel: Vec<f64> = [plain, pairwise, kahan].iter().map(|f| err(f(ys, r64), x, n).abs() / exact(x, n)).collect();
        let nn = n as f64;
        println!("chart,log10 n,{},log10 rel error plain,{:.2},pairwise,{:.2},kahan,{:.2},log10 (n-1)u,{:.2}",
            k, rel[0].log10(), rel[1].log10(), rel[2].log10(), ((nn - 1.0) * U).log10());
        assert!(rel[2] <= U && rel[1] <= l as f64 * U && rel[0] <= (nn - 1.0) * U / (1.0 - (nn - 1.0) * U));
    }

    // ---- the same tracker on a chip with 32-bit numbers ----
    let x32 = r32(0.1);
    let xs32 = vec![x32; N];
    let (sp, sk, sw) = (plain(&xs32, r32), kahan(&xs32, r32), pairwise(&xs32, r32));
    let e32 = err(sp, x32, N);
    println!("single 0.1,{:.12},exact total,{:.4}", x32, exact(x32, N));
    println!("single plain,{:.1},error,{:.4},percent,{:.2},range walk,{:.4}", sp, e32, 100.0 * e32 / 1e6, walk(x32, N, 23, r32));
    println!("single pairwise,{:.1},error,{:.4}", sw, err(sw, x32, N));
    println!("single kahan,{:.1},error,{:.4}", sk, err(sk, x32, N));
    for e in 15..21 {
        let p = 2f64.powi(e);
        let a = r32(p + x32) - p;
        println!("range,2^{},{},gap,{},step adds,{},off by,{:+.2}%", e, 1u64 << e, 2f64.powi(e - 23), a, 100.0 * (a - x32) / x32);
    }
    assert!(walk(x32, N, 23, r32) == sp && err(sk, x32, N).abs() <= 0.0625 / 2.0);
    assert!(err(sw, x32, N).abs() <= l as f64 * U32 * 1e6 && 80000.0 < e32 && e32 < (nf - 1.0) * U32 * 1.1e6);

    // ---- what breaks ----
    let bad = [1.0, 1e100, 1.0, -1e100];
    println!("kahan on 1 1e100 1 -1e100,{:.1},true sum,2,bound 2u x sum|x|,{}", kahan(&bad, r64), sci(2.0 * U * 2e100, 3));
    println!("flops per term,plain,1,pairwise,1,kahan,4,textbook,3,two-pass,4,welford,6");
    assert!(kahan(&bad, r64) == 0.0); // Kahan's bound is relative to sum |x|

    // ---- a mean and variance in one pass: barometer readings, 101325 Pa plus quarter steps ----
    let reading = |k: usize| 101325.0 + ((k % 25) as f64 - 12.0) * 0.25; // all exact
    let (mut s1, mut s2, mut mu, mut m) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
    for k in 0..N {
        let v = reading(k);
        s1 += v; s2 += v * v;
        let d = v - mu;
        mu += d / (k + 1) as f64;
        m += d * (v - mu);
    }
    let m2 = s1 / nf; // two-pass: the mean first, then squared distances
    let mut q = 0.0f64;
    for k in 0..N { let d = reading(k) - m2; q += d * d; }
    let quarters: Vec<i64> = (0..25).map(|k| 405300 + (k % 25) - 12).collect(); // readings x 4
    let qsum: i64 = quarters.iter().sum();
    assert!(qsum % 25 == 0);
    let qdev: i64 = quarters.iter().map(|v| (v - qsum / 25) * (v - qsum / 25)).sum();
    let exact_mean = (qsum / 25) as f64 / 4.0;
    let exact_var = qdev as f64 / 25.0 / 16.0;
    let closed = (2 * (1..13).map(|j: i64| j * j).sum::<i64>()) as f64 / (25.0 * 16.0);
    let kappa = (1.0 + exact_mean * exact_mean / exact_var).sqrt();
    let var_tb = (s2 - s1 * s1 / nf) / nf;
    println!("exact mean,{:.4},exact variance,{:.4},closed form,{:.4}", exact_mean, exact_var, closed);
    println!("kappa,{:.0},kappa^2,{}", kappa, sci(kappa * kappa, 3));
    for (name, val, b) in [("textbook", var_tb, nf * U * kappa * kappa), ("two-pass", q / nf, nf * U + (nf * U * kappa).powi(2)),
                           ("welford", m / nf, nf * U * kappa)] {
        let e = (val - exact_var) / exact_var; // true relative error; val - 3.25 is exact
        println!("{},{:.12},rel error,{},bound of order,{},ratio,{}", name, val, sci(e, 3), sci(b, 3), sci(e.abs() / b, 2));
    }
    println!("welford mean error,{},sample variance n-1,{:.10}", sci(mu - exact_mean, 3), m / (nf - 1.0));
    assert!(exact_var == closed && exact_var == 3.25);
    assert!((var_tb - 3.25).abs() > 0.1); // textbook: wrong in the first digit
    assert!((m / nf - 3.25).abs() < 3.25 * nf * U * kappa); // Welford: inside its bound
    assert!((q / nf - 3.25).abs() < 1e-9 && (m / nf - q / nf).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
