// Measurable functions -- the same check as the Python, in Rust.  No crates.
// Exact arithmetic by hand: every weight and threshold is a whole number of
// units of 1/2000 kg.  Four parcels on a belt scale weigh 1.3, 1.8, 2.2 and
// 3.6 kg.  Part 1 lists every sigma-algebra on four parcels and tests
// measurability three ways against a count by formula.  Part 2 asks the weight
// questions of the full record and of a log of rounded readings.  Part 3
// checks the preimage formulas on the line at exact rational points.
const N: usize = 4;
const FULL: usize = 15;
const U: i64 = 2000; // units per kg

fn show(m: usize) -> String {
    let v: Vec<String> = (0..N).filter(|i| m >> i & 1 == 1).map(|i| format!("p{}", i + 1)).collect();
    format!("{{{}}}", v.join(", "))
}
fn kg(u: i64) -> String {
    let s = format!("{:.3}", u as f64 / U as f64);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn pre(f: &[i64], test: impl Fn(i64) -> bool) -> usize { // preimage, as a bit mask
    (0..N).filter(|&i| test(f[i])).map(|i| 1 << i).sum()
}
fn rnd(x: i64) -> i64 { (x + U / 2).div_euclid(U) } // nearest whole kg, halves round up
fn ceil_kg(a: i64) -> i64 { -((-a).div_euclid(U)) } // whole kg at or above a
fn has(fam: usize, a: usize) -> bool { fam >> a & 1 == 1 }
fn mem(fam: usize) -> Vec<usize> { (0..16).filter(|&a| has(fam, a)).collect() }

fn is_sigma(fam: usize) -> bool {
    let ms = mem(fam);
    has(fam, 0) && ms.iter().all(|&a| has(fam, FULL ^ a)) && ms.iter().all(|&a| ms.iter().all(|&b| has(fam, a | b)))
}
fn close(gens: &[usize]) -> usize { // complements and unions until nothing changes
    let mut fam: usize = 1 | 1 << FULL;
    for &g in gens { fam |= 1 << g }
    loop {
        let mut new = fam;
        for a in mem(fam) {
            new |= 1 << (FULL ^ a);
            for b in mem(fam) { new |= 1 << (a | b) }
        }
        if new == fam { return fam }
        fam = new;
    }
}
fn atoms(fam: usize) -> Vec<usize> { // the smallest member holding each parcel
    let mut out = vec![];
    for i in 0..N {
        let mut at = FULL;
        for a in mem(fam) { if a >> i & 1 == 1 { at &= a } }
        if !out.contains(&at) { out.push(at) }
    }
    out
}
fn by_definition(f: &[i64], fam: usize) -> bool { // every set of values
    let mut vals = f.to_vec();
    vals.sort();
    vals.dedup();
    (0..1usize << vals.len()).all(|s| {
        let chosen: Vec<i64> = (0..vals.len()).filter(|j| s >> j & 1 == 1).map(|j| vals[j]).collect();
        has(fam, pre(f, |v| chosen.contains(&v)))
    })
}
fn by_threshold(f: &[i64], fam: usize, grid: &[i64]) -> bool { // only "below a?"
    grid.iter().all(|&a| has(fam, pre(f, |v| v < a)))
}
fn by_atoms(f: &[i64], fam: usize) -> bool { // constant on every atom
    atoms(fam).iter().all(|&at| {
        let v: Vec<i64> = (0..N).filter(|i| at >> i & 1 == 1).map(|i| f[i]).collect();
        v.iter().all(|&x| x == v[0])
    })
}

fn main() {
    // ---- part 1: every sigma-algebra on four parcels, every map to 1, 2 or 3 kg ----
    let sigmas: Vec<usize> = (0..1usize << 16).filter(|&f| is_sigma(f)).collect();
    let mut maps: Vec<Vec<i64>> = vec![];
    for n in 0..81 { maps.push(vec![n / 27 % 3 + 1, n / 9 % 3 + 1, n / 3 % 3 + 1, n % 3 + 1].iter().map(|v| v * U).collect()) }
    let grid: Vec<i64> = (-2..18).map(|k| k * U / 4).collect();
    let count = |t: &dyn Fn(&[i64], usize) -> bool| -> usize {
        sigmas.iter().map(|&s| maps.iter().filter(|f| t(f, s)).count()).sum()
    };
    let c_def = count(&|f, s| by_definition(f, s));
    let c_thr = count(&|f, s| by_threshold(f, s, &grid));
    let c_atm = count(&|f, s| by_atoms(f, s));
    let mut st: Vec<Vec<i64>> = vec![vec![1]]; // Stirling numbers: S(n, k) = k S(n-1, k) + S(n-1, k-1)
    for n in 1..=N {
        let mut row = vec![0i64];
        for k in 1..=n { row.push(k as i64 * if k < n { st[n - 1][k] } else { 0 } + st[n - 1][k - 1]) }
        st.push(row);
    }
    let bell: i64 = st[N].iter().sum();
    println!("four parcels: {} families searched, sigma-algebras {}, Stirling sum {}, maps {}", 1 << 16, sigmas.len(), bell, maps.len());
    println!("atoms k | sigma-algebras | Stirling S(4,k) | measurable maps to {{1,2,3}} in each");
    for k in 1..=N {
        let with_k: Vec<usize> = sigmas.iter().copied().filter(|&s| atoms(s).len() == k).collect();
        let mut per: Vec<usize> = with_k.iter().map(|&s| maps.iter().filter(|f| by_definition(f, s)).count()).collect();
        per.sort();
        per.dedup();
        println!("      {} | {:14} | {:15} | {:?} (3^{} = {})", k, with_k.len(), st[N][k], per, k, 3i64.pow(k as u32));
    }
    let stir: i64 = (1..=N).map(|k| st[N][k] * 3i64.pow(k as u32)).sum();
    println!("measurable (sigma-algebra, map) pairs: definition {}, threshold {}, atoms {}, formula {}", c_def, c_thr, c_atm, stir);

    // ---- part 2: the belt scale, the full record and the rounded log ----
    let w: Vec<i64> = vec![2600, 3600, 4400, 7200];
    let r: Vec<i64> = w.iter().map(|&x| rnd(x)).collect();
    let fw: Vec<i64> = w.iter().map(|&x| x.div_euclid(U)).collect();
    let log = close(&(0..6).map(|a| pre(&r, |v| v < a)).collect::<Vec<_>>());
    let flog = close(&(0..6).map(|a| pre(&fw, |v| v < a)).collect::<Vec<_>>());
    let full = (1usize << 16) - 1;
    let r_units: Vec<i64> = r.iter().map(|v| v * U).collect();
    let ws: Vec<String> = (0..N).map(|i| format!("p{} {}", i + 1, kg(w[i]))).collect();
    println!("full record: {} sets; weights {} kg; rounded readings {:?}", mem(full).len(), ws.join(", "), r);
    let at: Vec<String> = atoms(log).iter().map(|&a| show(a)).collect();
    println!("rounded log: {} sets, atoms {}; a sigma-algebra: {}", mem(log).len(), at.join(" | "), yn(sigmas.contains(&log)));
    for a in [3000i64, 4000, 5000] {
        let q = pre(&w, |v| v < a);
        println!("question 'under {} kg': parcels {}; full record {}; rounded log {}", kg(a), show(q), yn(has(full, q)), yn(has(log, q)));
    }
    println!("W measurable for the full record: {}; for the rounded log: {}", yn(by_threshold(&w, full, &grid)), yn(by_threshold(&w, log, &grid)));
    println!("R measurable for the full record: {}; for the rounded log: {}", yn(by_threshold(&r_units, full, &grid)), yn(by_threshold(&r_units, log, &grid)));
    let agree = grid.iter().filter(|&&a| pre(&r_units, |v| v < a) == pre(&w, |v| v < ceil_kg(a) * U - U / 2)).count();
    println!("{{R < 2}} = {}, and {{W < 1.5}} = {}; {{R < a}} = {{W < ceil(a) - 0.5}} at {} of {} thresholds",
             show(pre(&r, |v| v < 2)), show(pre(&w, |v| v < 3000)), agree, grid.len());
    let stg: Vec<String> = [1i64, 10, 1000].iter().map(|n| show(pre(&w, |v| v < 4400 + U / n))).collect();
    let eq = pre(&w, |v| v <= 4400) & (FULL ^ pre(&w, |v| v < 4400));
    println!("{{W < 2.2 + 1/n}} at n = 1, 10, 1000: {}; {{W = 2.2}} = {}", stg.join(", "), show(eq));
    let ind = (0..16usize).filter(|&a| {
        let f: Vec<i64> = (0..N).map(|i| (a >> i & 1) as i64 * U).collect();
        by_threshold(&f, log, &grid) == has(log, a)
    }).count();
    println!("indicator of A measurable for the log exactly when A is in it: {} of 16 sets, {} measurable", ind, mem(log).len());

    // ---- part 3: preimages on the line, at exact rational points ----
    let mut xs: Vec<i64> = (-16..81).map(|k| k * U / 16).collect();
    for k in -1..5i64 { for e in [-2i64, 2] { xs.push((2 * k + 1) * U / 2 + e) } }
    let ts: Vec<i64> = (-8..33).map(|k| k * U / 8).collect();
    let (mut r_ok, mut d_ok) = (0, 0);
    for &x in &xs {
        for &a in &ts {
            if (rnd(x) * U < a) == (x < ceil_kg(a) * U - U / 2) { r_ok += 1 }
            if ((x - 2 * U).abs() < a) == (a > 0 && 2 * U - a < x && x < 2 * U + a) { d_ok += 1 }
        }
    }
    println!("line: {} points x {} thresholds = {} pairs", xs.len(), ts.len(), xs.len() * ts.len());
    println!("  round(x) < a  iff  x < ceil(a) - 0.5          : {} pairs agree", r_ok);
    println!("  |x - 2| < a   iff  2 - a < x < 2 + a (a > 0)  : {} pairs agree", d_ok);
    println!("  round jumps at 1.5: {} at 1.499, {} at 1.5; still {{round < 2}} = (-inf, 1.5)", rnd(2998), rnd(3000));

    // ---- what breaks ----
    let fl_ok = (1..5i64).all(|a| has(flog, pre(&w, |v| v < a * U)));
    println!("break 1, floor log, whole thresholds only: {{W < 1}}..{{W < 4}} all in it: {}; {{W < 1.5}} = {} in it: {}",
             yn(fl_ok), show(pre(&w, |v| v < 3000)), yn(has(flog, pre(&w, |v| v < 3000))));
    println!("break 2, W against the rounded log: {{W < 2}} = {} settled: {}", show(pre(&w, |v| v < 4000)), yn(has(log, pre(&w, |v| v < 4000))));
    println!("break 3, 'jumps, so not measurable': {{round < 2}} is the ray below {}, a Borel set", kg(ceil_kg(4000) * U - U / 2));
    let px = |u: i64| -> String { (40 + 70 * u / U).to_string() }; // every value here is a whole pixel
    let ends: Vec<String> = (0..4i64).map(|k| px((2 * k + 1) * U / 2)).collect();
    let lev: Vec<String> = (1..5i64).map(|v| (200 - 40 * v).to_string()).collect();
    let pw: Vec<String> = w.iter().map(|&u| px(u)).collect();
    println!("figure, x = 40 + 70 w, y = 200 - 40 v; step ends {}; levels 1-4 at {}; parcels at {}", ends.join(", "), lev.join(", "), pw.join(", "));
    assert!(sigmas.len() as i64 == bell && bell == 15); // search against Stirling/Bell
    assert!(c_def == c_thr && c_thr == c_atm && c_atm as i64 == stir && stir == 309); // three tests and a formula
    assert!(r_ok == xs.len() * ts.len() && d_ok == r_ok && agree == grid.len()); // preimage formulas
    assert!(!has(log, pre(&w, |v| v < 4000)) && has(log, pre(&w, |v| v < 5000)) && ind == 16);
    assert!(by_threshold(&r_units, log, &grid) && !by_threshold(&w, log, &grid)); // R settled by the log, W not
    println!("ALL CHECKS PASS");
}
