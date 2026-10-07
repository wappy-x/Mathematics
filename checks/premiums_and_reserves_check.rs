// Premiums and reserves -- the check behind the card.  Rust std only.
// Policy: 20-year term insurance on a life aged 40.  $100,000 paid at the end of
// the year of death; a level premium due at the start of each year while alive;
// money earns 5% a year, continuously compounded.  Nothing imported knows the answer.
const S: f64 = 100000.0; // sum insured
const X: usize = 40; const N: usize = 20; const T: usize = 10; // issue age, term, reserve year
const R: f64 = 0.05; // rate
const MA: f64 = 0.00022; const MB: f64 = 2.7e-6; const MC: f64 = 1.124; // force: A + B c^age

fn q(age: usize) -> f64 {
    // chance of dying within the year: 1 - e^-(the force, added up over the year)
    1.0 - (-MA - MB * MC.powf(age as f64) * (MC - 1.0) / MC.ln()).exp()
}

// Road 1: add up the years.  Returns (A, a): insurance of $1 and annuity-due of $1 a year.
fn values(age: usize, n: usize, rate: f64, freeze: Option<usize>) -> (f64, f64) {
    let v = (-rate).exp();
    let (mut ins, mut ann, mut alive) = (0.0, 0.0, 1.0);
    for k in 0..n {
        let qk = q(freeze.unwrap_or(age + k));
        ann += v.powf(k as f64) * alive;
        ins += v.powf(k as f64 + 1.0) * alive * qk;
        alive *= 1.0 - qk;
    }
    (ins, ann)
}

fn premium(age: usize, n: usize, rate: f64) -> f64 {
    let (ins, ann) = values(age, n, rate, None);
    S * ins / ann
}

// Road 2: the recursion, run from the end of cover (reserve 0) back to the start.
fn backward(p: f64, age: usize, n: usize, rate: f64) -> Vec<f64> {
    let v = (-rate).exp();
    let mut vv = vec![0.0; n + 1];
    for t in (0..n).rev() {
        vv[t] = v * (q(age + t) * S + (1.0 - q(age + t)) * vv[t + 1]) - p;
    }
    vv
}

fn bisect_premium() -> f64 {
    // the premium at which the backward recursion lands on 0 at issue
    let (mut lo, mut hi) = (0.0, S);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if backward(mid, X, N, R)[0] > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

// Road 3: follow the office's 10,000 policies forward.  Fund per survivor = reserve.
fn cohort(p: f64) -> (Vec<f64>, Vec<f64>) {
    let (mut fund, mut l) = (0.0, 10000.0);
    let (mut per, mut alive) = (vec![], vec![]);
    for t in 0..N {
        per.push(fund / l); alive.push(l);
        let deaths = l * q(X + t);
        fund = (fund + l * p) * R.exp() - deaths * S;
        l -= deaths;
    }
    per.push(fund / l); alive.push(l);
    (per, alive)
}

struct Rng(u64);
impl Rng {
    // xorshift64*, written out, so Python and Rust draw the same numbers
    fn uniform(&mut self) -> f64 {
        let mut x = self.0;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.0 = x;
        (x.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0
    }
}

fn death_table(age: usize, n: usize) -> Vec<f64> {
    // chance of dying by the end of year k+1, k = 0..n-1
    let mut alive = 1.0;
    (0..n).map(|k| { alive *= 1.0 - q(age + k); 1.0 - alive }).collect()
}

fn row(lab: &str, val: String) { println!("{:<50}{}", lab, val); }

fn main() {
    let (p, p2) = (premium(X, N, R), bisect_premium());
    let (a40i, a40) = values(X, N, R, None);
    let (a50i, a50) = values(X + T, N - T, R, None);
    let v_pro = S * a50i - p * a50;
    let vr = backward(p, X, N, R);
    let (per, alive) = cohort(p);
    let v = (-R).exp();
    // Road 4: simulate 1,000,000 lives aged 50 and average the office's future loss on each.
    let cum50 = death_table(X + T, N - T);
    let loss: Vec<f64> = (0..N - T)
        .map(|k| S * v.powf(k as f64 + 1.0) - p * (0..=k).map(|j| v.powf(j as f64)).sum::<f64>())
        .collect();
    let mut rng = Rng(0x9E3779B97F4A7C15);
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..1000000 {
        let u = rng.uniform();
        let l = (0..N - T).find(|&k| u < cum50[k]).map_or(-p * a50, |k| loss[k]);
        tot += l; tot2 += l * l;
    }
    let mc = tot / 1e6; let se = ((tot2 / 1e6 - mc * mc) / 1e6).sqrt();
    // One simulated office: 10,000 lives aged 40, one draw each, run for ten years.
    let cum40 = death_table(X, T);
    let mut died = vec![0usize; T];
    for _ in 0..10000 {
        let u = rng.uniform();
        if let Some(k) = (0..T).find(|&k| u < cum40[k]) { died[k] += 1; }
    }
    let (mut fund, mut l) = (0.0, 10000usize);
    for t in 0..T {
        fund = (fund + l as f64 * p) * R.exp() - died[t] as f64 * S;
        l -= died[t];
    }
    let (lhs, rhs) = ((v_pro + p) * R.exp(), q(X + T) * S + (1.0 - q(X + T)) * vr[T + 1]);
    // What breaks
    let (a40fi, a40f) = values(X + T, N - T, R, Some(X));
    let (a50zi, a50z) = values(X + T, N - T, 0.0, None);
    let nat40 = v * q(X) * S;
    row("q(40), q(50), q(59)", format!("{:.7} {:.7} {:.7}", q(40), q(50), q(59)));
    row("A 40:20 per $1, a-due 40:20", format!("{:.6} {:.6}", a40i, a40));
    row("A 50:10 per $1, a-due 50:10", format!("{:.6} {:.6}", a50i, a50));
    row("v = e^-r, S times A 40:20", format!("{:.6} {:.6}", v, S * a40i));
    row("S times A 50:10", format!("{:.6}", S * a50i));
    row("P times a-due 50:10", format!("{:.6}", p * a50));
    row("1 premium by the sums", format!("{:.6}", p));
    row("2 premium by bisection", format!("{:.6}", p2));
    row("1 reserve at 10, prospective", format!("{:.6}", v_pro));
    row("2 reserve at 10, backward recursion", format!("{:.6}", vr[T]));
    row("3 reserve at 10, office fund per survivor", format!("{:.6}", per[T]));
    row("4 reserve at 10, simulated mean, std error", format!("{:.6} {:.6}", mc, se));
    row("size of reserve at 0 (recursion), at 20 (fund)", format!("{:.6} {:.6}", vr[0].abs(), per[N].abs()));
    row("step 10->11: (V10+P)e^r, q S + p V11", format!("{:.6} {:.6}", lhs, rhs));
    row("office: survivors at 10, fund at 10", format!("{:.4} {:.2}", alive[T], per[T] * alive[T]));
    row("simulated office: deaths by 10, fund per survivor", format!("{} {:.6}", died.iter().sum::<usize>(), fund / l as f64));
    row("expected deaths by 10", format!("{:.4}", 10000.0 - alive[T]));
    let top = (0..=N).fold(0, |b, t| if vr[t] > vr[b] { t } else { b });
    row("largest reserve: year, value", format!("{} {:.6}", top, vr[top]));
    for a in (0..=N).step_by(7) {
        let s: Vec<String> = (a..(a + 7).min(N + 1)).map(|t| format!("{:.2}", vr[t])).collect();
        println!("reserve  t={:2}.. {}", a, s.join(" "));
    }
    for a in (0..N).step_by(7) {
        let s: Vec<String> = (a..(a + 7).min(N)).map(|t| format!("{:.2}", v * q(X + t) * S)).collect();
        println!("yr cost  t={:2}.. {}", a, s.join(" "));
    }
    let brk = [("forgot the premium due at 10", v_pro + p), ("age-40 death rates at 50-59", S * a40fi - p * a40f),
        ("no interest in the reserve", S * a50zi - p * a50z),
        ("first year's cost as premium", nat40), ("  short at issue per policy", S * a40i - nat40 * a40)];
    for (lab, val) in brk.iter() { println!("break  {:<43}{:.6}", lab, val); }
    let (p50, p0) = (premium(50, N, R), premium(X, N, 0.0));
    let tries = [("sum insured $200,000: premium, reserve", 2.0 * p, 2.0 * v_pro),
        ("issue age 50: premium, reserve", p50, backward(p50, 50, N, R)[T]),
        ("rate 0%: premium, reserve", p0, backward(p0, X, N, 0.0)[T])];
    for (lab, a, b) in tries.iter() { println!("try    {:<43}{:.6} {:.6}", lab, a, b); }
    assert!((p - p2).abs() < 1e-6); // sums vs root finder on the recursion
    assert!((v_pro - vr[T]).abs() < 1e-6); // prospective vs recursion
    assert!((v_pro - per[T]).abs() < 1e-6); // prospective vs retrospective fund
    assert!((mc - v_pro).abs() < 4.0 * se); // simulation agrees within 4 standard errors
    assert!((lhs - rhs).abs() < 1e-6); // one step of the recursion, by hand
    assert!(vr[0].abs() < 1e-6); // equivalence: nothing owed at issue
    println!("All checks passed.");
}
