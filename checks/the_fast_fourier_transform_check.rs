// The fast Fourier transform -- the same check as the Python, in Rust.  No crates.
// A handclap convolved with a room's echo, 4096 samples each, illustrative 16-bit integers.
// Road 1: the sum written out, in exact integers.  Road 2: the recursive radix-2 FFT, three
// transforms.  Road 3: the in-place FFT with bit reversal, both signals packed into one transform.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn signal(seed: u64, n: usize, power: u32) -> Vec<i64> { // SplitMix64 noise fading to nothing over n samples
    let (mut s, mut out) = (seed, Vec::new());
    for k in 0..n {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        let r = z ^ (z >> 31);
        let mag = (((r >> 1) % 32768) as u128 * ((n - k) as u128).pow(power) / (n as u128).pow(power)) as i64;
        out.push(if r & 1 == 1 { -mag } else { mag });
    }
    out
}
fn turn(k: usize, n: usize, sign: f64) -> C { // the twiddle w^k, straight from cos and sin; black_box stops
    let t = 2.0 * PI * k as f64 / n as f64;     // -O fusing them into one sincos call with other last bits
    c(std::hint::black_box(t).cos(), sign * std::hint::black_box(t).sin()) }
fn fft(x: &[C], sign: f64, repeated: bool, fl: &mut u64) -> Vec<C> { // road 2: halve, recurse, recombine
    let n = x.len();
    if n == 1 { return vec![x[0]]; }
    let half = |s: usize| x.iter().skip(s).step_by(2).cloned().collect::<Vec<C>>();
    let (ev, od) = (fft(&half(0), sign, repeated, fl), fft(&half(1), sign, repeated, fl));
    let (mut out, mut w, w1) = (vec![c(0.0, 0.0); n], c(1.0, 0.0), turn(1, n, sign));
    for k in 0..n / 2 {
        if !repeated { w = turn(k, n, sign); }
        let t = mul(w, od[k]);
        (out[k], out[k + n / 2]) = (add(ev[k], t), sub(ev[k], t));
        *fl += 10; // one complex multiply (6), two complex adds (4)
        if repeated { w = mul(w, w1); } // the mistake: w^(k+1) from w^k, error piles up
    }
    out
}
fn fft_inplace(x: &[C], sign: f64, fl: &mut u64) -> Vec<C> { // road 3: the library's loop, no recursion
    let (n, mut a, bits) = (x.len(), x.to_vec(), x.len().trailing_zeros());
    for i in 0..n { // move each sample to its bit-reversed slot
        let mut j = 0;
        for b in 0..bits { j = (j << 1) | ((i >> b) & 1); }
        if i < j { a.swap(i, j); }
    }
    let (tw, mut m): (Vec<C>, usize) = ((0..n / 2).map(|k| turn(k, n, sign)).collect(), 2);
    while m <= n {
        for s in (0..n).step_by(m) {
            for k in 0..m / 2 {
                let t = mul(tw[k * (n / m)], a[s + k + m / 2]);
                (a[s + k], a[s + k + m / 2]) = (add(a[s + k], t), sub(a[s + k], t));
                *fl += 10;
            }
        }
        m *= 2;
    }
    a
}
fn pad(x: &[i64], n: usize) -> Vec<C> { (0..n).map(|j| c(if j < x.len() { x[j] as f64 } else { 0.0 }, 0.0)).collect() }
fn conv_plain(a: &[i64], b: &[i64], n: usize, repeated: bool, fl: &mut u64) -> Vec<f64> { // three transforms, N products
    let (fa, fb) = (fft(&pad(a, n), -1.0, repeated, fl), fft(&pad(b, n), -1.0, repeated, fl));
    *fl += 6 * n as u64 + n as u64; // N complex products, then N divisions
    fft(&(0..n).map(|k| mul(fa[k], fb[k])).collect::<Vec<C>>(), 1.0, repeated, fl).iter().map(|v| v.re / n as f64).collect()
}
fn conv_packed(a: &[i64], b: &[i64], n: usize, fl: &mut u64) -> Vec<f64> { // a in the real part, b in the imaginary
    let (pa, pb, mut p) = (pad(a, n), pad(b, n), Vec::new());
    let z = fft_inplace(&(0..n).map(|j| c(pa[j].re, pb[j].re)).collect::<Vec<C>>(), -1.0, fl);
    for k in 0..n {
        let (pr, pi, qr, qi) = (z[k].re, z[k].im, z[(n - k) % n].re, -z[(n - k) % n].im);
        let fa = c((pr + qr) * 0.5, (pi + qi) * 0.5); // a's transform: 4 flops
        let fb = c((pi - qi) * 0.5, (qr - pr) * 0.5); // b's transform: 4 flops
        p.push(mul(fa, fb)); // their product: 6 flops
    }
    *fl += 14 * n as u64 + n as u64;
    fft_inplace(&p, 1.0, fl).iter().map(|v| v.re / n as f64).collect()
}
fn direct(a: &[i64], b: &[i64]) -> (Vec<i64>, u64, u64) { // road 1: the sum written out, exact integers
    let (mut top, mut cc, mut ml, mut ad) = (-1i64, vec![0i64; a.len() + b.len() - 1], 0u64, 0u64);
    for i in 0..a.len() {
        for j in 0..b.len() { cc[i + j] += a[i] * b[j]; }
        ml += b.len() as u64;
        ad += (top - i as i64 + 1).max(0) as u64; top = (i + b.len()) as i64 - 1; // outputs i..top held a term: adds
    }
    (cc, ml, ad)
}
fn route(n: u64) -> u64 { 15 * 2 * n * (2 * n).trailing_zeros() as u64 + 7 * 2 * n } // three transforms, N = 2n
fn plain_sum(n: u64) -> u64 { n * n + (n - 1) * (n - 1) }
fn sci(x: f64) -> String { // e-notation with a two-digit exponent, as Python prints it
    let s = format!("{:.2e}", x); let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn main() {
    let n = 4096usize; let (nn, lg) = (2 * n, (2 * n).trailing_zeros() as u64); // lg = log2 N, 13 here
    let (clap, room) = (signal(2026, n, 4), signal(1111, n, 2));
    let (cv, ml, ad) = direct(&clap, &room);
    let (mut f_plain, mut f_packed, mut junk) = (0u64, 0u64, 0u64);
    let (c2, c3) = (conv_plain(&clap, &room, nn, false, &mut f_plain), conv_packed(&clap, &room, nn, &mut f_packed));
    let err = |v: &Vec<f64>| (0..2 * n - 1).map(|j| (v[j] - cv[j] as f64).abs()).fold(0.0, f64::max);
    let (e2, e3) = (err(&c2), err(&c3));
    let exact = (0..cv.len()).all(|j| c2[j].round() as i64 == cv[j] && c3[j].round() as i64 == cv[j]);
    let big = cv.iter().map(|v| v.abs()).max().unwrap();
    let yn = |b: bool| if b { "yes" } else { "no" };
    let (nu, packed_formula) = (nn as u64, 10 * nn as u64 * lg + 15 * nn as u64);
    println!("signals: n = {}, padded N = {}; output {} samples, largest |c| = {}", n, nn, cv.len(), big);
    println!("road 1, the sum: {} multiplications ({} x {}) + {} additions ({} x {}) = {} flops", ml, n, n, ad, n - 1, n - 1, ml + ad);
    println!("road 2, three transforms: {} flops counted; 15 N log2 N + 7N = {} + {} = {}", f_plain, 3 * 5 * nu * lg, 7 * nu, route(n as u64));
    println!("road 3, packed: {} flops counted; 10 N log2 N + 15N = {}", f_packed, packed_formula);
    println!("saving in flops: {:.2} times (three transforms), {:.2} (packed)", (ml + ad) as f64 / f_plain as f64, (ml + ad) as f64 / f_packed as f64);
    println!("largest rounding error: road 2 {}, road 3 {}, rounding allows 0.5; exact: {}", sci(e2), sci(e3), yn(exact));
    let counted = |l: usize| { let mut f = 0u64; fft(&vec![c(0.0, 0.0); 1 << l], -1.0, false, &mut f); f };
    let ok_count = (1..14).all(|l| counted(l) == 5 * (1u64 << l) * l as u64);
    println!("one transform counted at N = 2 .. 8192 equals 5 N log2 N: {}", yn(ok_count));
    println!("per transform at N = {}: radix-2 {}; skipping the {} multiplications by w^0 = 1: {}; split-radix 4 N log2 N - 6N + 8: {}",
        nn, 5 * nu * lg, nu - 1, 5 * nu * lg - 6 * (nu - 1), 4 * nu * lg - 6 * nu + 8);
    // ---- by hand: (1 + 2x + 3x^2)(4 + 5x) through a 4-point transform ----
    let (ha, hb) = (fft(&pad(&[1, 2, 3], 4), -1.0, false, &mut junk), fft(&pad(&[4, 5], 4), -1.0, false, &mut junk));
    let hp: Vec<C> = (0..4).map(|k| mul(ha[k], hb[k])).collect();
    let hc: Vec<i64> = fft(&hp, 1.0, false, &mut junk).iter().map(|v| (v.re / 4.0).round() as i64).collect();
    let show = |v: &Vec<C>| v.iter().map(|z| format!("{:+}{:+}i", z.re.round() as i64, z.im.round() as i64)).collect::<Vec<_>>().join(" ");
    println!("by hand: A = {}; B = {}; A*B = {}", show(&ha), show(&hb), show(&hp));
    println!("by hand: c = {:?}, the sum gives {:?}", hc, &direct(&[1, 2, 3, 0], &[4, 5, 0, 0]).0[..4]);
    // ---- rounding: there and back, against the first-order bound 2 log2 N eta ----
    let (u, mu) = (2f64.powi(-53), 2.0 * 2f64.powi(-53));
    let eta = mu + 4.0 * u / (1.0 - 4.0 * u) * (2f64.sqrt() + mu); let mut rows = Vec::new();
    for l in [5usize, 7, 9, 11, 13] {
        let (nl, mut errs) = (1usize << l, Vec::new());
        let x = pad(&signal(7, nl, 0), nl);
        let nx = x.iter().fold(0.0, |s, v| s + v.re * v.re).sqrt();
        for rep in [false, true] {
            let y: Vec<C> = fft(&fft(&x, -1.0, rep, &mut junk), 1.0, rep, &mut junk).iter().map(|v| c(v.re / nl as f64, v.im / nl as f64)).collect();
            errs.push((0..nl).fold(0.0, |s, j| s + (y[j].re - x[j].re).powi(2) + y[j].im.powi(2)).sqrt() / nx);
        }
        let bound = 2.0 * l as f64 * eta;
        rows.push((errs[0], errs[1], bound));
        println!("there and back, N = {:>4}: error {}, bound {}, ratio {:.3}; repeated twiddles {}", nl, sci(errs[0]), sci(bound), errs[0] / bound, sci(errs[1]));
    }
    // ---- what breaks ----
    let c4 = conv_plain(&clap, &room, n, false, &mut junk); // no padding: N = 4096, the tail wraps round
    let wrap = (0..n).map(|j| (c4[j] - cv[j] as f64).abs()).fold(0.0, f64::max);
    let wrap_ok = (0..n).all(|j| c4[j].round() as i64 == cv[j] + if j + n < cv.len() { cv[j + n] } else { 0 });
    let e5 = err(&conv_plain(&clap, &room, nn, true, &mut junk)); // twiddles by repeated multiplication
    let cm = 3 * nu / 2 * lg + nu; // complex multiplications in road 2
    println!("break, no padding: largest error {:.0}; it is the tail wrapped onto the head: {}", wrap, yn(wrap_ok));
    println!("break, no 1/N: largest output {} instead of {}, {} times too big", big * nn as i64, big, nn);
    println!("break, repeated twiddles: largest error {} instead of {}, {:.0} times worse", sci(e5), sci(e2), e5 / e2);
    println!("break, complex multiplications counted as flops: {} against {}, claims {:.1} times", cm, n * n, (n * n) as f64 / cm as f64);
    // ---- the cost curve, and where the route wins ----
    let xs: Vec<u32> = (4..21).step_by(2).collect();
    let line = |f: &dyn Fn(u64) -> u64| xs.iter().map(|&l| format!("{:.2}", (f(1u64 << l) as f64).log10())).collect::<Vec<_>>().join(", ");
    println!("chart, log2 n: {:?}", xs);
    println!("chart, log10 flops, the sum: {}", line(&plain_sum));
    println!("chart, log10 flops, three transforms: {}", line(&route));
    let cross = (1..30).map(|l| 1u64 << l).find(|&m| route(m) < plain_sum(m)).unwrap();
    let two_h = (1..30).map(|l| 1u64 << l).find(|&m| plain_sum(m) >= 200 * route(m)).unwrap();
    println!("route first beats the sum at n = {}: {} against {}", cross, route(cross), plain_sum(cross));
    println!("saving first reaches 200 at n = {}: {:.1}; at n = 8192: {:.2}", two_h, plain_sum(two_h) as f64 / route(two_h) as f64, plain_sum(8192) as f64 / route(8192) as f64);
    assert!(ml + ad == plain_sum(n as u64) && f_plain == route(n as u64)); // counted flops against the formulas
    assert!(ok_count && f_packed == packed_formula);
    assert!(e2 < 0.5 && e3 < 0.5 && exact); // both transform roads hit the exact sum
    assert!(hc == vec![4, 13, 22, 15]);
    assert!(ha.iter().chain(hb.iter()).zip([(6.0, 0.0), (-2.0, -2.0), (2.0, 0.0), (-2.0, 2.0), (9.0, 0.0), (4.0, -5.0), (-1.0, 0.0), (4.0, 5.0)])
        .all(|(z, (r, i))| (z.re - r).hypot(z.im - i) < 1e-12)); // the hand spectra
    assert!(rows.iter().all(|r| r.0 < r.2) && rows[4].1 > 10.0 * rows[4].0);
    assert!(wrap_ok && wrap > 1e6 && e5 > 10.0 * e2);
    println!("ALL CHECKS PASS");
}
