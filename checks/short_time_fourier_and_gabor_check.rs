// Short-time Fourier transform and the Gabor transform -- the check behind the card.  Rust std only.
// The same illustrative bird call, windows and roads as the Python; the output is identical.
use std::f64::consts::PI;

const FS: usize = 16000; const N: usize = 10 * FS;         // samples per second; ten seconds
const F0: f64 = 2000.0; const C: f64 = 200.0;                // start pitch Hz, climb Hz/s

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Cx {
    fn add(self, o: Cx) -> Cx { Cx { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: Cx) -> Cx { Cx { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: Cx) -> Cx { Cx { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn pow2(self) -> f64 { self.re.powf(2.0) + self.im.powf(2.0) }
}

fn tot<I: Iterator<Item = f64>>(vs: I) -> f64 { let mut s = 0.0; for v in vs { s += v; } s }

fn fft(mut a: Vec<Cx>, sign: f64) -> Vec<Cx> {   // radix-2 FFT; sign=+1 runs it backwards (no 1/M)
    let (n, mut j) = (a.len(), 0usize);
    for i in 1..n {
        let mut b = n >> 1;
        while j & b != 0 { j ^= b; b >>= 1; }
        j |= b;
        if i < j { a.swap(i, j); }
    }
    let mut size = 2;
    while size <= n {
        let h = size / 2;
        let tw: Vec<Cx> = (0..h).map(|k| Cx { re: (2.0 * PI * k as f64 / size as f64).cos(),
            im: sign * (2.0 * PI * k as f64 / size as f64).sin() }).collect();
        for s in (0..n).step_by(size) {
            for k in 0..h {
                let (u, v) = (a[s + k], a[s + k + h].mul(tw[k]));
                a[s + k] = u.add(v); a[s + k + h] = u.sub(v);
            }
        }
        size *= 2;
    }
    a
}

fn window(sig: f64) -> (i64, Vec<f64>) {         // Gaussian: |w|^2 has standard deviation sig s
    let h = (6.0 * sig * FS as f64).ceil() as i64;   // cut where w = e^-9 = 0.00012
    (h, (-h..=h).map(|k| (-(k as f64 / FS as f64).powf(2.0) / (4.0 * sig * sig)).exp()).collect())
}

fn column(x: &[f64], n0: i64, w: &[f64], h: i64, m: usize) -> Vec<Cx> {
    let mut buf = vec![Cx { re: 0.0, im: 0.0 }; m];
    for k in -h..=h {
        let idx = (n0 + k).rem_euclid(N as i64) as usize;
        buf[k.rem_euclid(m as i64) as usize] = Cx { re: x[idx] * w[(k + h) as usize], im: 0.0 };
    }
    fft(buf, -1.0)
}

fn ridge(x: &[f64], sig: f64) -> (f64, f64) {    // road 1: centre and spread of one column's power
    let m = 16384usize;
    let (h, w) = window(sig); let col = column(x, (5.0 * FS as f64).round() as i64, &w, h, m);
    let p: Vec<f64> = col[..m / 2].iter().map(|v| v.pow2()).collect();
    let f: Vec<f64> = (0..m / 2).map(|k| (k * FS) as f64 / m as f64).collect();
    let pw = tot(p.iter().cloned());
    let mu = tot(p.iter().zip(&f).map(|(p, x)| p * x)) / pw;
    (mu, (tot(p.iter().zip(&f).map(|(p, x)| p * (x - mu).powf(2.0))) / pw).sqrt())
}

fn spreads(sig: f64, w: &[f64], h: i64) -> (f64, f64) {   // road 2: the window's spreads, in time only
    let e = tot(w.iter().map(|v| v * v));
    let dt = (tot((-h..=h).map(|k| (k as f64 / FS as f64).powf(2.0) * w[(k + h) as usize].powf(2.0))) / e).sqrt();
    let slope: Vec<f64> = (-h..=h).map(|k| -(k as f64 / FS as f64) / (2.0 * sig * sig) * w[(k + h) as usize]).collect();
    (dt, (tot(slope.iter().map(|s| s * s)) / e).sqrt() / (2.0 * PI))
}

fn g_range(w: &[f64], h: i64, a: usize) -> (f64, f64, usize) {   // shifted |w|^2: lowest, highest
    let mut g = vec![0.0f64; a]; for k in -h..=h { g[k.rem_euclid(a as i64) as usize] += w[(k + h) as usize].powf(2.0); }
    let (lo, hi) = (g.iter().cloned().fold(f64::INFINITY, f64::min), g.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    (lo, hi, g.iter().filter(|v| **v == 0.0).count())
}

fn poisson_ratio(s: f64, a: f64) -> f64 {        // road 2 for B/A: Poisson summation of the bells
    let q: Vec<f64> = (1..30).map(|k| (-2.0 * PI * PI * k as f64 * k as f64 * (s / a).powf(2.0)).exp()).collect();
    (1.0 + 2.0 * tot(q.iter().cloned()))
        / (1.0 + 2.0 * tot(q.iter().enumerate().map(|(i, x)| if i % 2 == 0 { -x } else { *x })))
}

fn show(name: &str, vs: &[f64], d: usize) {
    let mut s = format!("{:<44}", name);
    for v in vs { s += &format!(" {:>12.*}", d, v); } println!("{}", s);
}

fn main() {
    let fsf = FS as f64;
    let x: Vec<f64> = (0..N).map(|n| (2.0 * PI * (F0 * n as f64 / fsf + 0.5 * C * (n as f64 / fsf).powf(2.0))).cos()).collect();

    // ---- choosing the window: the ridge at 5 s, where the call is at 3000 Hz ----
    let (sst, floor) = (1.0 / (4.0 * PI * C).sqrt(), (C / (2.0 * PI)).sqrt());
    show("best window spread sigma* (ms)", &[1000.0 * sst], 4);
    show("floor sqrt(c / 2 pi) (Hz)", &[floor], 4);
    println!("sigma (ms) | dt_w (ms) | dxi_w (Hz) | c dt_w (Hz) | ridge: formula, measured | centre (Hz)");
    let sigs = [0.0025, 0.005, 0.010, sst, 0.040, 0.080];
    let mut r = vec![0.0; sigs.len()];
    for (i, &sig) in sigs.iter().enumerate() {
        let (h, w) = window(sig);
        let (dt, dx) = spreads(sig, &w, h);
        let (mu, rr) = ridge(&x, sig); r[i] = rr;
        let form = (dx * dx + (C * dt).powf(2.0)).sqrt();
        println!("chart, {:6.2} {:9.4} {:9.4} {:9.4} {:9.4} {:9.4} {:10.2}", 1000.0 * sig, 1000.0 * dt, dx, C * dt, form, rr, mu);
        assert!((dt - sig).abs() < 1e-6 * sig && (dx - 1.0 / (4.0 * PI * sig)).abs() < 1e-6 * dx);
        assert!((rr - form).abs() < 1e-3 * form && (mu - 3000.0).abs() < 0.01);
    }
    assert!(r.iter().all(|v| *v >= r[3]) && (r[3] - floor).abs() < 1e-3 * floor);
    show("Gaussian at sigma*: dt_w * dxi_w", &[sst * (1.0 / (4.0 * PI * sst)), 1.0 / (4.0 * PI)], 6);
    show("breaks: too short, 2.5 ms: ridge Hz, x best", &[r[0], r[0] / r[3]], 4); show("breaks: too long, 80 ms: ridge Hz, x best", &[r[5], r[5] / r[3]], 4);
    let s2 = sst / 2f64.sqrt();
    show("breaks: sigma put on w, not |w|^2 (Hz)", &[((1.0 / (4.0 * PI * s2)).powf(2.0) + (C * s2).powf(2.0)).sqrt()], 4);
    show("try: climb x4: sigma* ms; ridge, pitch Hz", &[1000.0 / (16.0 * PI * C).sqrt(), (4.0 * C / (2.0 * PI)).sqrt(), F0 + 4.0 * C * 5.0], 4);

    // ---- the energy identity, by brute force over every column of the call ----
    let (hh, ww) = window(sst);
    let (m, a) = (4096usize, 320usize);
    assert!(2 * hh as usize + 1 <= m && N % a == 0);
    let (gmin, gmax, _) = g_range(&ww, hh, a);
    let e = tot(x.iter().map(|v| v * v));
    let (mut total, mut rebuilt) = (0.0, vec![0.0f64; 320]);
    for mi in 0..N / a {
        let c0 = (mi * a) as i64;
        let col = column(&x, c0, &ww, hh, m);
        total += tot(col.iter().map(|v| v.pow2()));
        if (c0 - 80160).abs() <= hh + 160 {
            let back = fft(col, 1.0);
            for n in 80000i64..80320 {
                if (n - c0).abs() <= hh {
                    rebuilt[(n - 80000) as usize] += ww[(n - c0 + hh) as usize] * back[(n - c0).rem_euclid(m as i64) as usize].re / m as f64;
                }
            }
        }
    }
    let mut g = vec![0.0f64; a]; for k in -hh..=hh { g[k.rem_euclid(a as i64) as usize] += ww[(k + hh) as usize].powf(2.0); }
    let law = m as f64 * tot((0..N).map(|n| x[n].powf(2.0) * g[n % a]));
    show("double sum of |X|^2 over 500 x 4096", &[total], 0);
    show("M * sum x^2 G (painless law)", &[law], 0);
    assert!((total - law).abs() < 1e-9 * law);
    let err = (80000..80320usize).map(|n| (rebuilt[n - 80000] / g[n % a] - x[n]).abs()).fold(0.0, f64::max);
    show("rebuild error, 320 samples near 5 s", &[err], 12);
    assert!(err < 1e-9);
    let (fe, we) = (e / fsf, (2.0 * PI).sqrt() * sst);
    show("||f||^2 (V^2 s), ||w||^2 (s), product", &[fe, we, fe * we], 6);
    let integral = total * a as f64 / (FS * FS * m) as f64;
    show("double sum as an integral (V^2 s^2); gap", &[integral, integral - fe * we], 10);
    assert!((integral - fe * we).abs() < 1e-6);
    show("G: lowest, highest; b (Hz); ab", &[gmin, gmax, fsf / m as f64, a as f64 / m as f64], 6);
    show("frame sum (V^2 s^2); A = B = G / b (s)", &[total / (FS * FS) as f64, gmin * m as f64 / fsf], 6);

    // ---- frame bounds as the hop grows: direct sum against Poisson summation ----
    println!("hop (ms) | redundancy M/a | B/A direct | B/A Poisson | samples never seen per hop");
    for hop in [160usize, 320, 640, 960, 1280, 4000] {
        let (lo, hi, zeros) = g_range(&ww, hh, hop);
        let ms = 1000.0 * hop as f64 / fsf;
        if lo == 0.0 {
            println!("bars, {:5.0} {:8.3} {:>12} {:>12} {:6}", ms, m as f64 / hop as f64, "none", "-", zeros);
            continue;
        }
        let pr = poisson_ratio(sst * fsf, hop as f64);
        println!("bars, {:5.0} {:8.3} {:12.6} {:12.6} {:6}", ms, m as f64 / hop as f64, hi / lo, pr, zeros);
        assert!((hi / lo - pr).abs() < 1e-6 * pr);
    }
    show("cut window: support (ms), samples; 1/b (ms)", &[1000.0 * (2 * hh + 1) as f64 / fsf, (2 * hh + 1) as f64, 1000.0 * m as f64 / fsf], 1);
    show("cut window: height at the cut, e^-9", &[ww[0], (-9.0f64).exp()], 6);
    show("breaks: M 128, hop 160: numbers, samples, ab", &[(128 * N / 160) as f64, N as f64, 160.0 / 128.0], 2); println!("ALL CHECKS PASS");
}
