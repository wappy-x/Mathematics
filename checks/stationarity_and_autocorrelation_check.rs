// Stationarity and autocorrelation -- the same check as the Python, in Rust, std only.
// Monthly airline passengers, thousands, Jan 1949 to Dec 1960 (Box and Jenkins, Series G).
// Roads: r(h) by lag products and via the spectrum; exact covariances of three small
// models by listing every outcome; 2,000 seeded pure-noise series for the band.
use std::f64::consts::PI;

const DATA: [f64; 144] = [112., 118., 132., 129., 121., 135., 148., 148., 136., 119., 104., 118.,
    115., 126., 141., 135., 125., 149., 170., 170., 158., 133., 114., 140.,
    145., 150., 178., 163., 172., 178., 199., 199., 184., 162., 146., 166.,
    171., 180., 193., 181., 183., 218., 230., 242., 209., 191., 172., 194.,
    196., 196., 236., 235., 229., 243., 264., 272., 237., 211., 180., 201.,
    204., 188., 235., 227., 234., 264., 302., 293., 259., 229., 203., 229.,
    242., 233., 267., 269., 270., 315., 364., 347., 312., 274., 237., 278.,
    284., 277., 317., 313., 318., 374., 413., 405., 355., 306., 271., 306.,
    315., 301., 356., 348., 355., 422., 465., 467., 404., 347., 305., 336.,
    340., 318., 362., 348., 363., 435., 491., 505., 404., 359., 310., 337.,
    360., 342., 406., 396., 420., 472., 548., 559., 463., 407., 362., 405.,
    417., 391., 419., 461., 472., 535., 622., 606., 508., 461., 390., 432.];
const N: usize = 144; const LAGS: usize = 24; const SERIES: usize = 2000; const SEED: u64 = 20260929;
fn mean(xs: &[f64]) -> f64 { xs.iter().sum::<f64>() / xs.len() as f64 }
fn acov(xs: &[f64], h: usize, divisor: f64) -> f64 { // c(h): lag products about the mean
    let m = mean(xs);
    (0..xs.len() - h).map(|t| (xs[t] - m) * (xs[t + h] - m)).sum::<f64>() / divisor
}
fn acf(xs: &[f64], lags: usize) -> Vec<f64> { // road 1: r(h) = c(h) / c(0)
    let n = xs.len() as f64;
    (0..=lags).map(|h| acov(xs, h, n) / acov(xs, 0, n)).collect()
}
fn acf_spectral(xs: &[f64], lags: usize) -> Vec<f64> { // road 2: periodogram, then back
    let (n, m) = (xs.len(), mean(xs));
    let big = 2 * n; // zero padding stops the wrap-round
    let power: Vec<f64> = (0..big).map(|k| {
        let (mut re, mut im) = (0.0, 0.0);
        for t in 0..n {
            let a = 2.0 * PI * (k * t) as f64 / big as f64;
            re += (xs[t] - m) * a.cos();
            im -= (xs[t] - m) * a.sin();
        }
        re * re + im * im
    }).collect();
    let c: Vec<f64> = (0..=lags).map(|h| (0..big)
        .map(|k| power[k] * (2.0 * PI * (k * h) as f64 / big as f64).cos()).sum::<f64>() / big as f64).collect();
    c.iter().map(|v| v / c[0]).collect()
}
fn sd(xs: &[f64]) -> f64 { acov(xs, 0, xs.len() as f64).sqrt() }
fn splitmix64(s: u64) -> (u64, u64) { // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn row(label: &str, vals: &[f64], dp: usize) {
    let v: Vec<String> = vals.iter().map(|x| format!("{:.*}", dp, x)).collect();
    println!("{} {}", label, v.join(" "));
}
fn main() {
    let (band, nf) = (1.96 / (N as f64).sqrt(), N as f64);
    for yr in [1949usize, 1954, 1960] { row(&format!("figure, {} by month:", yr), &DATA[12 * (yr - 1949)..12 * (yr - 1948)], 0); }
    let (y49, y60) = (&DATA[0..12], &DATA[132..144]);
    row("year mean, 1949 and 1960:", &[mean(y49), mean(y60)], 2);
    row("year sd, 1949 and 1960:", &[sd(y49), sd(y60)], 2);
    let m49 = mean(y49);
    row("hand, 1949: mean, sum sq dev, sum lag-1 products, r(1):", &[m49,
        y49.iter().map(|v| (v - m49).powi(2)).sum::<f64>(),
        (0..11).map(|t| (y49[t] - m49) * (y49[t + 1] - m49)).sum::<f64>(), acf(y49, 1)[1]], 4);

    // ---- trend, season and noise, on logs: y = level(month) + b t + noise ----
    let y: Vec<f64> = DATA.iter().map(|v| v.ln()).collect();
    let tbar: Vec<f64> = (0..12).map(|m| m as f64 + 66.0).collect();
    let ybar: Vec<f64> = (0..12).map(|m| (0..12).map(|k| y[12 * k + m]).sum::<f64>() / 12.0).collect();
    let sxx = (0..N).map(|t| (t as f64 - tbar[t % 12]).powi(2)).sum::<f64>();
    let b = (0..N).map(|t| (t as f64 - tbar[t % 12]) * (y[t] - ybar[t % 12])).sum::<f64>() / sxx; // each month vs itself
    let lev: Vec<f64> = (0..12).map(|m| ybar[m] - b * tbar[m]).collect();
    let noise: Vec<f64> = (0..N).map(|t| y[t] - lev[t % 12] - b * t as f64).collect();
    let avg = mean(&lev);
    row("trend: growth per year, July factor, November factor:",
        &[(12.0 * b).exp() - 1.0, (lev[6] - avg).exp(), (lev[10] - avg).exp()], 4);
    let mut normal_eq = (0..N).map(|t| t as f64 * noise[t]).sum::<f64>().abs();
    for m in 0..12 { normal_eq = normal_eq.max((0..12).map(|k| noise[12 * k + m]).sum::<f64>().abs()); }
    row("noise sd, 1949-54 and 1955-60:", &[sd(&noise[..72]), sd(&noise[72..])], 4);
    let cn: Vec<f64> = (0..=LAGS).map(|h| acov(&noise, h, nf)).collect(); // standard errors: Var(sum a_t noise_t)
    let se_of = |a: &[f64]| -> f64 { (0..N).flat_map(|i| (0..N).map(move |j| (i, j))).filter(|&(i, j)| i.abs_diff(j) <= LAGS)
        .map(|(i, j)| a[i] * a[j] * cn[i.abs_diff(j)]).sum::<f64>().sqrt() };
    let wb: Vec<f64> = (0..N).map(|t| (t as f64 - tbar[t % 12]) / sxx).collect(); // error of b = sum of wb_t noise_t
    let sea: Vec<Vec<f64>> = [6usize, 10].iter().map(|&m| (0..N).map(|t| (if t % 12 == m { 1.0 / 12.0 } else { 0.0 })
        - 1.0 / nf - (tbar[m] - 71.5) * wb[t]).collect()).collect();
    let (g, fjul, fnov) = (12.0 * (12.0 * b).exp(), (lev[6] - avg).exp(), (lev[10] - avg).exp()); // growth's slope, factors
    row("trend se with memory: growth, July, November; growth se if independent:",
        &[g * se_of(&wb), fjul * se_of(&sea[0]), fnov * se_of(&sea[1]), g * (cn[0] / sxx).sqrt()], 4);

    // ---- the correlograms, two roads each ----
    let (raw1, raw2) = (acf(&DATA, LAGS), acf_spectral(&DATA, LAGS));
    let (noi1, noi2) = (acf(&noise, LAGS), acf_spectral(&noise, LAGS));
    let pick = |r: &Vec<f64>| -> Vec<f64> { [1, 2, 3, 6, 12, 24].iter().map(|&h| r[h]).collect() };
    for (name, r1, r2) in [("raw", &raw1, &raw2), ("noise", &noi1, &noi2)] {
        row(&format!("{} r(h), h = 1 2 3 6 12 24, lag products:", name), &pick(r1), 4);
        row(&format!("{} r(h), h = 1 2 3 6 12 24, spectrum and back:", name), &pick(r2), 4);
        row(&format!("figure, {} r(h) for h = 1..24:", name), &r1[1..], 2);
    }
    row("band, +-1.96/sqrt(144):", &[band, -band], 4);
    row("figure, band:", &[band, -band], 2);
    let last_out = (1..=LAGS).filter(|&h| noi1[h].abs() > band).max().unwrap();

    // ---- three small models, every outcome listed: 64 equally likely sign patterns ----
    let names = ["lingering shock", "shared offset", "random walk"];
    let model = |k: usize, c: f64, z: &[f64]| -> Vec<f64> {
        (1..5).map(|t| match k { 0 => z[t] + 0.5 * z[t - 1], 1 => c + z[t], _ => z[1..=t].iter().sum() }).collect()
    };
    let mut cov = [[[0.0f64; 4]; 4]; 3];
    let mut avg4 = 0.0;
    for code in 0..64u32 {
        let s: Vec<f64> = (0..6).map(|i| if code >> i & 1 == 1 { 1.0 } else { -1.0 }).collect();
        for k in 0..3 {
            let p = model(k, s[0], &s[1..]);
            for i in 0..4 { for j in 0..4 { cov[k][i][j] += p[i] * p[j] / 64.0; } }
            if k == 1 { avg4 += p.iter().sum::<f64>().powi(2) / 64.0 / 16.0; }
        }
    }
    for k in 0..3 {
        let v: Vec<f64> = (0..3).flat_map(|g| (0..4 - g).map(move |t| (t, t + g))).map(|(i, j)| cov[k][i][j]).collect();
        row(&format!("{}: Cov at gap 0, 1, 2 from t = 1:", names[k]), &v, 2);
    }
    row("shared offset, variance of the average of 4, and if independent:", &[avg4, 2.0 / 4.0], 2);

    // ---- 2,000 pure-noise series of 144, uniform on (-1, 1) ----
    let (mut s, mut r1s, mut any_out) = (SEED, Vec::new(), 0usize);
    for _ in 0..SERIES {
        let mut xs = Vec::with_capacity(N);
        for _ in 0..N {
            let (s2, z) = splitmix64(s); s = s2;
            xs.push((z >> 11) as f64 * 2f64.powi(-52) - 1.0);
        }
        let r = acf(&xs, LAGS);
        r1s.push(r[1]);
        if r[1..].iter().any(|v| v.abs() > band) { any_out += 1; }
    }
    let sf = SERIES as f64;
    let mean_r1 = mean(&r1s);
    let sd_r1 = (r1s.iter().map(|v| (v - mean_r1).powi(2)).sum::<f64>() / (sf - 1.0)).sqrt();
    let (out1, anyf) = (r1s.iter().filter(|v| v.abs() > band).count() as f64 / sf, any_out as f64 / sf);
    row("pure noise: mean r(1), its se; theory -1/n:", &[mean_r1, sd_r1 / sf.sqrt(), -1.0 / nf], 4);
    row("pure noise: sd of r(1); theory 1/sqrt(n):", &[sd_r1, 1.0 / nf.sqrt()], 4);
    row("pure noise: share with r(1) outside band, its se:", &[out1, (out1 * (1.0 - out1) / sf).sqrt()], 4);
    row("pure noise: share with any of 24 lags outside, its se:", &[anyf, (anyf * (1.0 - anyf) / sf).sqrt()], 4);
    let (s2, z) = splitmix64(s); s = s2; // one shared-offset record: c, then c + e_t
    let mut off = vec![(z >> 63) as f64 * 2.0 - 1.0];
    for _ in 0..10 * N { let (s2, z) = splitmix64(s); s = s2; off.push(off[0] + (z >> 63) as f64 * 2.0 - 1.0); }
    let one = acf(&off[1..], 12);
    row("shared offset, one record of 1,440: r(1), r(12); true rho:", &[one[1], one[12], 0.5], 4);
    // ---- what breaks, and try changing ----
    let c0 = acov(&DATA, 0, nf);
    let wrong: Vec<f64> = [100usize, 120].iter().map(|&h| acov(&DATA, h, (N - h) as f64) / c0).collect();
    row("wrong: divide by n - h, raw r(h) at h = 100 and 120:", &wrong, 4);
    let slope = (0..N).map(|u| (u as f64 - 71.5) * y[u]).sum::<f64>() / (0..N).map(|u| (u as f64 - 71.5).powi(2)).sum::<f64>();
    let line: Vec<f64> = (0..N).map(|t| y[t] - (mean(&y) + (t as f64 - 71.5) * slope)).collect();
    let lr = acf(&line, 12);
    row("try: trend only removed, r(h) at h = 1 6 12:", &[lr[1], lr[6], lr[12]], 4);
    row("band for 12 months, 36 and 1,440:", &[1.96 / 12f64.sqrt(), 1.96 / 6.0, 1.96 / 1440f64.sqrt()], 4);
    println!("noise: last lag of 24 outside the band: {}", last_out);

    let gap = raw1.iter().chain(&noi1).zip(raw2.iter().chain(&noi2)).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max);
    assert!(gap < 1e-9); // two roads, one correlogram
    assert!(normal_eq < 1e-9); // noise is least-squares residual
    assert!(cov[0][0][0] == 1.25 && cov[0][0][1] == 0.5 && cov[0][0][2] == 0.0 && cov[0][2][3] == 0.5);
    assert!(cov[1][1][3] == 1.0 && cov[2][3][3] == 4.0 && avg4 == 1.25);
    assert!((sd_r1 - 1.0 / nf.sqrt()).abs() < 0.004 && (out1 - 0.05).abs() < 4.0 * (0.05 * 0.95 / sf).sqrt());
    assert!(raw1.iter().chain(&noi1).all(|v| v.abs() <= 1.0) && wrong[0] < -1.0);
    assert!(one[1].abs().max(one[12].abs()) < 4.0 / (10.0 * nf).sqrt()); // one record cannot see its offset
    println!("ALL CHECKS PASS");
}
