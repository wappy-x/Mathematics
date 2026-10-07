// Hidden Markov models -- the same check as the Python, in Rust.  No crates.
// Same model, same week, same three roads (recursions in floats, all 243 weeks
// in exact integers, 300000 simulated weeks from SplitMix64, seed 2026), then
// the same 2000 simulated days.
const P: [[u64; 3]; 3] = [[7, 3, 0], [3, 3, 4], [2, 2, 6]]; // tenths: row = today
const NU: [u64; 3] = [5, 3, 2]; // tenths: Monday's weather, before any umbrella
const B: [u64; 3] = [1, 4, 8]; // tenths: chance of an umbrella in each weather
const OBS: [u64; 5] = [1, 1, 0, 0, 1];
const K: usize = 3; const WEEKS: usize = 300000; const LONG: usize = 2000; type Row = [f64; 3];
fn p(j: usize, i: usize) -> f64 { P[j][i] as f64 / 10.0 } fn nu(i: usize) -> f64 { NU[i] as f64 / 10.0 }
fn e(i: usize, y: u64) -> u64 { if y == 1 { B[i] } else { 10 - B[i] } }
fn b(i: usize, y: u64) -> f64 { e(i, y) as f64 / 10.0 }
fn word(path: &[usize]) -> String { path.iter().map(|&i| ['S', 'C', 'R'][i]).collect() }
fn lg(x: f64) -> f64 { if x > 0.0 { x.ln() } else { f64::NEG_INFINITY } }
fn argmax(v: &[f64]) -> usize { let mut k = 0; for i in 1..v.len() { if v[i] > v[k] { k = i } } k }
fn sum(v: &Row) -> f64 { v.iter().sum() }
fn se(f: f64, m: usize) -> f64 { (f * (1.0 - f) / m as f64).sqrt() }
fn row(v: &Row, d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
// ---- road 1: the recursions ----
fn forward(obs: &[u64]) -> Vec<Row> {             // alpha_n(i) = P(y_1..y_n, X_n = i)
    let mut a = vec![ [0.0; 3]];
    for i in 0..K { a[0][i] = nu(i) * b(i, obs[0]) }
    for &y in &obs[1..] {
        let (l, mut r) = (*a.last().unwrap(), [0.0; 3]);
        for i in 0..K { r[i] = (0..K).map(|j| l[j] * p(j, i)).sum::<f64>() * b(i, y) } a.push(r);
    }
    a
}
fn backward(obs: &[u64]) -> Vec<Row> {            // beta_n(i) = P(y_n+1..y_N | X_n = i)
    let mut be = vec![ [1.0; 3]];
    for &y in obs[1..].iter().rev() {
        let (nx, mut r) = (be[0], [0.0; 3]);
        for i in 0..K { r[i] = (0..K).map(|j| p(i, j) * b(j, y) * nx[j]).sum() } be.insert(0, r);
    }
    be
}
fn viterbi(obs: &[u64], f: fn(f64) -> f64, op: fn(f64, f64) -> f64) -> (Vec<Row>, Vec<[usize; 3]>, Vec<usize>) {
    let (mut d, mut back) = (vec![ [0.0; 3]], vec![]);
    for i in 0..K { d[0][i] = op(f(nu(i)), f(b(i, obs[0]))) }
    for &y in &obs[1..] {
        let l = *d.last().unwrap();
        let (mut r, mut arg) = ([0.0; 3], [0usize; 3]);
        for i in 0..K {
            let c: Vec<f64> = (0..K).map(|j| op(l[j], f(p(j, i)))).collect();
            arg[i] = argmax(&c);
            r[i] = op(c[arg[i]], f(b(i, y)));
        }
        d.push(r); back.push(arg);
    }
    let mut path = vec![argmax(d.last().unwrap())];
    for arg in back.iter().rev() { path.insert(0, arg[path[0]]) }
    (d, back, path)
}
// ---- road 3: simulation ----
struct Gen(u64);
impl Gen {
    fn draw(&mut self) -> u64 {                   // SplitMix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn tenth(&mut self) -> u64 { ((self.draw() >> 32) * 10) >> 32 }   // 0 to 9, each 1 in 10
    fn pick(&mut self, w: &[u64; 3]) -> usize {
        let mut u = self.tenth();
        for i in 0..K { if u < w[i] { return i } u -= w[i] }
        K - 1
    }
    fn run(&mut self, days: usize) -> (Vec<usize>, Vec<u64>) {
        let (mut x, mut xs, mut ys) = (self.pick(&NU), vec![], vec![]);
        for n in 0..days {
            if n > 0 { x = self.pick(&P[x]) }
            xs.push(x); ys.push(if self.tenth() < B[x] { 1 } else { 0 });
        }
        (xs, ys)
    }
}

fn main() {
    let (alpha, beta) = (forward(&OBS), backward(&OBS));
    let like = sum(&alpha[4]);
    let post: Vec<Row> = (0..5).map(|n| { let mut r = [0.0; 3]; for i in 0..K { r[i] = alpha[n][i] * beta[n][i] / like } r }).collect();
    let filt: Vec<Row> = alpha.iter().map(|r| { let s = sum(r); [r[0] / s, r[1] / s, r[2] / s] }).collect();
    let (delta, back, vpath) = viterbi(&OBS, |x| x, |u, v| u * v);
    let daywise: Vec<usize> = post.iter().map(|r| argmax(r)).collect();
    // ---- road 2: every weather week, exact integers in units of 10^-10 ----
    let weight = |path: &[usize], obs: &[u64]| -> u64 {
        let mut w = NU[path[0]] * e(path[0], obs[0]);
        for n in 1..obs.len() { w *= P[path[n - 1]][path[n]] * e(path[n], obs[n]) }
        w
    };
    let weeks: Vec<Vec<usize>> = (0..243usize).map(|c| (0..5).map(|n| (c / 3usize.pow(4 - n as u32)) % 3).collect()).collect();
    let ws: Vec<u64> = weeks.iter().map(|w| weight(w, &OBS)).collect();
    let total: u64 = ws.iter().sum();
    let mut best = 0; for c in 1..ws.len() { if ws[c] > ws[best] { best = c } }
    let mut sorted = ws.clone(); sorted.sort();
    let (mut gap, mut vok) = (0.0f64, 0usize);
    for n in 0..5 { for i in 0..K {
        let s: u64 = (0..weeks.len()).filter(|&c| weeks[c][n] == i).map(|c| ws[c]).sum();
        gap = gap.max((s as f64 / total as f64 - post[n][i]).abs());
        let m = weeks.iter().filter(|w| w[n] == i).map(|w| weight(&w[..n + 1], &OBS[..n + 1])).max().unwrap();
        if (m as f64 / 10f64.powi(2 * n as i32 + 2) - delta[n][i]).abs() < 1e-15 { vok += 1 }
    } }
    let mut g = Gen(2026);
    let (mut hits, mut vhits, mut rain_fri) = (0usize, 0usize, 0usize);
    for _ in 0..WEEKS {
        let (xs, ys) = g.run(5); if ys == OBS { hits += 1; vhits += (xs == vpath) as usize; rain_fri += (xs[4] == 2) as usize }
    }
    let (q, qv, qr) = (hits as f64 / WEEKS as f64, vhits as f64 / hits as f64, rain_fri as f64 / hits as f64);
    // ---- 2000 days: underflow, rescaling, logarithms ----
    let (xs, ys) = g.run(LONG);
    let plain = sum(forward(&ys).last().unwrap());
    let mut a = [0.0; 3]; for i in 0..K { a[i] = nu(i) * b(i, ys[0]) }
    let (mut loglik, mut scaled) = (0.0f64, vec![]);
    for n in 0..LONG {
        if n > 0 { let l = a; for i in 0..K { a[i] = (0..K).map(|j| l[j] * p(j, i)).sum::<f64>() * b(i, ys[n]) } }
        let c = sum(&a); loglik += c.ln(); for i in 0..K { a[i] /= c } scaled.push((a, c));
    }
    let mut la = [0.0; 3]; for i in 0..K { la[i] = lg(nu(i)) + lg(b(i, ys[0])) }
    let mx = |v: &Row| v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    for &y in &ys[1..] {
        let (l, m) = (la, mx(&la));
        for i in 0..K { la[i] = lg(b(i, y)) + m + (0..K).map(|j| (l[j] + lg(p(j, i)) - m).exp()).sum::<f64>().ln() }
    }
    let logroad = mx(&la) + la.iter().map(|v| (v - mx(&la)).exp()).sum::<f64>().ln();
    let (mut bh, mut dayw, mut sok) = ([1.0f64; 3], vec![0usize; LONG], 0usize);
    for n in (0..LONG).rev() {
        let gg: Vec<f64> = (0..K).map(|i| scaled[n].0[i] * bh[i]).collect();
        dayw[n] = argmax(&gg); if (gg.iter().sum::<f64>() - 1.0).abs() < 1e-9 { sok += 1 }
        let l = bh;
        for i in 0..K { bh[i] = (0..K).map(|j| p(i, j) * b(j, ys[n]) * l[j]).sum::<f64>() / scaled[n].1 }
    }
    let (_, _, lpath) = viterbi(&ys, lg, |u, v| u + v);
    let acc_v = (0..LONG).filter(|&n| lpath[n] == xs[n]).count() as f64 / LONG as f64;
    let acc_d = (0..LONG).filter(|&n| dayw[n] == xs[n]).count() as f64 / LONG as f64;
    let pts = |path: &[usize]| path.iter().enumerate().map(|(n, &s)| format!("({}, {})", 60 + 60 * n, 50 + 60 * s)).collect::<Vec<_>>().join(", ");
    println!("model: P = {:?} tenths; start {:?} tenths; umbrella chance {:?} tenths; week seen {:?}", P, NU, B, OBS);
    println!("road 1, forward alpha_n(S, C, R), then filter P(X_n = . | umbrellas to day n):");
    for n in 0..5 { println!("  day {}  {}   {}", n + 1, row(&alpha[n], 10), row(&filt[n], 4)) }
    println!("road 1, chance of this umbrella week, sum of alpha_5: {:.10}", like);
    println!("road 1, Viterbi delta_n(S, C, R) and best previous weather:");
    for n in 0..5 { println!("  day {}  {}   {}", n + 1, row(&delta[n], 10), if n > 0 { word(&back[n - 1]) } else { "---".to_string() }) }
    let top = mx(&delta[4]); let m1: f64 = (0..K).map(|i| nu(i) * b(i, 1)).sum(); // m1: umbrella chance from Monday's mix
    println!("road 1, Viterbi week {}, joint chance {:.10}, given the umbrellas {:.4}", word(&vpath), top, top / like);
    println!("road 1, smoothed P(X_n = S, C, R | whole week), forward times backward:");
    for n in 0..5 { println!("  day {}  {}", n + 1, row(&post[n], 4)) }
    println!("road 2, {} weeks, {} possible; exact chance {} / 10^10", weeks.len(), ws.iter().filter(|&&w| w > 0).count(), total);
    println!("road 2, most likely week {}, weight {} / 10^10; runner-up weight {}", word(&weeks[best]), ws[best], sorted[sorted.len() - 2]);
    println!("road 2, largest gap to road 1's smoothed table: {:.1e}; Viterbi table entries equal to the best enumerated path: {} of 15", gap, vok);
    println!("road 3, {} weeks, seed 2026: {} showed this umbrella week", WEEKS, hits);
    println!("  chance of the week   {:.5}  se {:.5}  (exact {:.5})", q, se(q, WEEKS), like);
    println!("  week was {}      {:.4}  se {:.4}  (exact {:.4})", word(&vpath), qv, se(qv, hits), top / like);
    println!("  Friday was rainy     {:.4}  se {:.4}  (exact {:.4})", qr, se(qr, hits), post[4][2]);
    println!("what breaks, best weather day by day: {}, exact weight {}", word(&daywise), weight(&daywise, &OBS));
    println!("what breaks, days treated as independent: {:.2}^3 x {:.2}^2 = {:.4}, not {:.4}", m1, 1.0 - m1, m1.powi(3) * (1.0 - m1).powi(2), like);
    println!("what breaks, {} days, plain forward products: {:?}", LONG, plain);
    println!("  log-likelihood, rescaled forward {:.6}; log-space forward {:.6}; rescaled forward x backward sums to 1 on {} of {} days", loglik, logroad, sok, LONG);
    println!("  about 10^{:.1}; paths 3^{} = 10^{:.1}; forward steps {}", loglik / 10f64.ln(), LONG, LONG as f64 * 3f64.ln() / 10f64.ln(), LONG * K * K);
    println!("  days right: Viterbi week {:.4}  se {:.4}; day by day {:.4}  se {:.4}", acc_v, se(acc_v, LONG), acc_d, se(acc_d, LONG));
    println!("figure, trellis x = 60 + 60(n-1), y = 50 (S), 110 (C), 170 (R); Viterbi [{}]; day by day [{}]", pts(&vpath), pts(&daywise));
    let rain = |t: &Vec<Row>| t.iter().map(|r| format!("{:.2}", r[2])).collect::<Vec<_>>().join(", ");
    println!("figure, rain filtered {}; rain smoothed {}", rain(&filt), rain(&post));
    assert!((like - total as f64 / 1e10).abs() < 1e-15);                  // forward against enumeration
    assert!(vpath == weeks[best] && vok == 15);                          // Viterbi table against enumeration
    assert!(gap < 1e-12);
    assert!((q - total as f64 / 1e10).abs() < 4.0 * se(q, WEEKS) && (qv - ws[best] as f64 / total as f64).abs() < 4.0 * se(qv, hits));
    assert!(weight(&daywise, &OBS) == 0 && plain == 0.0 && (loglik - logroad).abs() < 1e-8 && sok == LONG);
    println!("ALL CHECKS PASS");
}
