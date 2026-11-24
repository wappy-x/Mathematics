// Feedback linearisation and sliding mode on the cart pendulum -- the check behind the card.
// std only.  Pole: g/l = 16 per s^2; cart moved by a force F; true cart mass M unknown.
const G: f64 = 9.81; const L: f64 = 0.613125; const MH: f64 = 2.0; // gravity, pole length, assumed mass
const LAM: f64 = 2.0; const ETA: f64 = 2.0; const PHI: f64 = 0.1;  // surface slope, reaching rate, layer
const TH0: f64 = 0.5; const DT: f64 = 0.001;                     // start lean rad; step and control period s
const W2: f64 = G / L;                                           // 16 per s^2
#[derive(Clone, Copy, PartialEq)] enum Kind { Fl, Smc, Bl }
type Row = (f64, f64, f64, f64, f64);                            // t, theta, omega, F, cart speed

fn lean_acc(th: f64, _om: f64, f: f64, m: f64) -> f64 { W2 * th.sin() - th.cos() * f / (m * L) }
fn gain(th: f64, om: f64, eta: f64) -> f64 { 0.2 * (W2 * th.sin() + LAM * om).abs() + 1.2 * eta }
fn law(kind: Kind, th: f64, om: f64, k: Option<f64>, eta: f64, phi: f64) -> f64 {
    let pre = MH * L / th.cos();
    if kind == Kind::Fl { let k = k.unwrap(); return pre * (W2 * th.sin() + k * th + k * om); }
    let s = om + LAM * th;
    let sw = if kind == Kind::Smc { if s > 0.0 { 1.0 } else { -1.0 } } else { (s / phi).min(1.0).max(-1.0) };
    let kk = match k { None => gain(th, om, eta), Some(v) => v };
    pre * (W2 * th.sin() + LAM * om + kk * sw)
}
fn run(kind: Kind, m: f64, k: Option<f64>, tend: f64, eta: f64, phi: f64, th0: f64) -> Vec<Row> {
    let (mut th, mut om, mut v, mut out) = (th0, 0.0f64, 0.0f64, Vec::new());
    for n in 0..((tend / DT).round() as usize) {
        let f = law(kind, th, om, k, eta, phi);
        out.push((n as f64 * DT, th, om, f, v));
        let d = |a: f64, b: f64| (b, lean_acc(a, b, f, m));
        let k1 = d(th, om); let k2 = d(th + DT / 2.0 * k1.0, om + DT / 2.0 * k1.1);
        let k3 = d(th + DT / 2.0 * k2.0, om + DT / 2.0 * k2.1); let k4 = d(th + DT * k3.0, om + DT * k3.1);
        th += DT / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0); om += DT / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        v += f / m * DT;
    }
    out.push((tend, th, om, law(kind, th, om, k, eta, phi), v));
    out
}
fn sm(kind: Kind, m: f64) -> Vec<Row> { run(kind, m, None, 4.0, ETA, PHI, TH0) }
fn settle(tr: &[Row]) -> f64 { tr.iter().filter(|x| x.1.abs() > 0.01).map(|x| x.0).fold(0.0, f64::max) }
fn reach(tr: &[Row], band: f64) -> usize {
    tr.iter().position(|x| { let s = x.2 + LAM * x.1; if band == 0.0 { s <= 0.0 } else { s.abs() <= band } }).unwrap()
}
fn svals(tr: &[Row]) -> Vec<f64> { tr.iter().map(|x| (x.2 + LAM * x.1).abs()).collect() }
fn smax(tr: &[Row]) -> f64 { svals(tr).into_iter().fold(0.0, f64::max) }
fn jumps(tr: &[Row]) -> usize { tr.windows(2).filter(|w| (w[0].3 - w[1].3).abs() > 1.0).count() }
fn peak(tr: &[Row]) -> f64 { tr.iter().map(|x| x.3.abs()).fold(0.0, f64::max) }

fn main() {
    println!("pole: g/l = {:.4} per s^2; assumed cart mass {:.1} kg, true 1.6 to 2.4 kg (+-20 %)", W2, MH);
    let (s0, g0) = (LAM * TH0, W2 * TH0.sin()); let k0 = gain(TH0, 0.0, ETA); let pre0 = MH * L / TH0.cos();
    println!("hand: s0 = 0 + 2 x 0.5 = {:.4} rad/s; 16 sin 0.5 = {:.4}; K0 = 0.2 x {:.4} + 2.4 = {:.4} rad/s^2", s0, g0, g0, k0);
    println!("hand: Mhat l / cos 0.5 = {:.4} kg m; F0 linearising {:.4} N, sliding {:.4} N", pre0, pre0 * (g0 + 4.0 * TH0), pre0 * (g0 + k0));
    let r = MH / 2.4;
    println!("hand: heavy cart r = 2/2.4 = {:.4}; s'(0) = {:.4} x {:.4} - {:.4} x {:.4} = {:.4} rad/s^2", r, 1.0 - r, g0, r, k0, (1.0 - r) * g0 - r * k0);
    println!("reaching-time bound |s0|/eta = {:.4} s", s0 / ETA);
    println!("start lean {:.1} rad = {:.2} deg; linearising loses upright when r < 16/(16+4) = {:.4}, M > {:.4} kg; layer lean bound Phi/lambda = {:.4} rad",
             TH0, TH0.to_degrees(), W2 / (W2 + 4.0), MH * (W2 + 4.0) / W2, PHI / LAM);

    // Road A for the gain: bisection on the true plant over a grid of states and masses, against the formula.
    let mut worst = 0.0f64;
    for i in -12..13 { for j in -10..11 {
        let (th, om) = (0.1 * i as f64, 0.5 * j as f64); let mut need = 0.0f64;
        for q in 0..21 { let m = 1.6 + 0.04 * q as f64;
            for sg in [1.0, -1.0] {
                let (mut lo, mut hi) = (0.0f64, 50.0f64);
                for _ in 0..60 {
                    let kk = (lo + hi) / 2.0;
                    let sdot = lean_acc(th, om, MH * L / th.cos() * (W2 * th.sin() + LAM * om + kk * sg), m) + LAM * om;
                    if sg * sdot > -ETA { lo = kk } else { hi = kk }
                }
                need = need.max(hi);
            } }
        worst = worst.max((need - gain(th, om, ETA)).abs());
    } }
    println!("gain road: bisection on the plant, 525 states x 21 masses, largest gap to formula {:.2e} rad/s^2", worst);
    assert!(worst < 1e-6);

    println!("linearising law (k = 4), lean after 1 s and settle time to 0.01 rad:");
    let exact = run(Kind::Fl, 2.0, Some(4.0), 4.0, ETA, PHI, TH0); let th1 = exact[1000].1;
    let pred = TH0 * (1.0 + 2.0 * 1.0) * (-2.0f64).exp();
    let tc = (0..100000).map(|k| k as f64 * 1e-4).find(|&t| TH0 * (1.0 + 2.0 * t) * (-2.0 * t).exp() < 0.01).unwrap(); // continuous design
    println!("  M 2.0 kg: theta(1 s) {:.4} rad, target 0.5 x 3 x e^-2 = {:.4}; settles {:.3} s (continuous design {:.3} s)", th1, pred, settle(&exact), tc);
    assert!((th1 - pred).abs() < 2e-3 && (settle(&exact) - tc).abs() < 0.02);
    for m in [1.6, 2.4, 2.6] {
        let rr = MH / m; let (b, c) = (4.0 * rr, 4.0 * rr - W2 * (1.0 - rr)); let disc = b * b - 4.0 * c;
        let roots = if disc >= 0.0 { format!("{:.4}, {:.4}", (-b - disc.sqrt()) / 2.0, (-b + disc.sqrt()) / 2.0) }
                    else { format!("{:.4} +- {:.4}j", -b / 2.0, (-disc).sqrt() / 2.0) };
        let tr = run(Kind::Fl, m, Some(4.0), 30.0, ETA, PHI, TH0); let last = tr[tr.len() - 1].1;
        let fate = if last.abs() > 0.01 { format!("never returns: leans {:.4} rad at 30 s", last) } else { format!("settles {:.3} s", settle(&tr)) };
        println!("  M {:.1} kg: r {:.4}, linear roots {} 1/s; {}", m, rr, roots, fate);
        if disc >= 0.0 && (-b + disc.sqrt()) / 2.0 > 0.0 { assert!(last.abs() > 0.1); }
        if m == 2.4 { assert!(settle(&tr) > 5.0 * settle(&exact)); }
    }

    println!("sliding law, sign switch (s0 = 1 rad/s, bound 0.5 s):");
    let mut heavy = Vec::new();
    for m in [1.6, 2.0, 2.4] {
        let tr = sm(Kind::Smc, m); let n = reach(&tr, 0.0); let tr_ = tr[n].0;
        assert!(tr_ <= s0 / ETA + DT);                                                   // road B: the bound ...
        assert!(svals(&tr[..n]).iter().zip(tr.iter()).all(|(sv, x)| *sv <= s0 - ETA * x.0 + 1e-3)); // ... all along
        let p = tr[n].1 * (-LAM * 1.0f64).exp();
        println!("  M {:.1} kg: reaches {:.3} s at theta {:.4} rad; 1 s later {:.4}, surface says {:.4}; |s| after <= {:.4}; force jumps >1 N in next 1 s: {}; settles {:.3} s",
                 m, tr_, tr[n].1, tr[n + 1000].1, p, smax(&tr[n..]), jumps(&tr[n..n + 1001]), settle(&tr));
        assert!((tr[n + 1000].1 - p).abs() < 2e-3);
        if m == 2.4 { assert!(tr_ >= s0 / ETA - 0.01); heavy = tr; }                   // the heavy cart uses the whole budget
    }
    let lay = sm(Kind::Bl, 2.4); let nb = reach(&lay, PHI);
    println!("boundary layer Phi {:.1} rad/s, M 2.4 kg: enters layer {:.3} s (bound (1 - 0.1)/2 = 0.450 s); |s| after <= {:.4}; force jumps >1 N: {}; settles {:.3} s",
             PHI, lay[nb].0, smax(&lay[nb..]), jumps(&lay[nb..]), settle(&lay));
    assert!((s0 - PHI) / ETA - 0.01 <= lay[nb].0 && lay[nb].0 <= (s0 - PHI) / ETA + DT && smax(&lay[nb..]) <= PHI && jumps(&lay[nb..]) == 0);
    let nom = sm(Kind::Smc, 2.0);
    println!("cart speed at 4 s, sliding run, M 2.0 kg: {:.4} m/s", nom[nom.len() - 1].4);
    println!("peak force, M 2.4 kg: linearising {:.4} N, sliding {:.4} N", peak(&run(Kind::Fl, 2.4, Some(4.0), 4.0, ETA, PHI, TH0)), peak(&heavy));

    for (m, k, lab) in [(2.6, None, "gain sized to 20 %, true mass +30 %"), (2.4, Some(ETA), "K = eta only, no uncertainty term")] {
        let tr = run(Kind::Smc, m, k, 4.0, ETA, PHI, TH0); let tb = tr[reach(&tr, 0.0)].0;
        println!("break, {}: M {:.1} kg reaches at {:.3} s, bound 0.5000 s", lab, m, tb);
        assert!(tb > s0 / ETA);
    }
    let tr = run(Kind::Smc, 2.4, None, 4.0, 4.0, PHI, TH0);
    println!("try eta 4, M 2.4 kg: reaches {:.3} s (bound 0.25), peak force {:.4} N", tr[reach(&tr, 0.0)].0, peak(&tr));
    let tr = run(Kind::Bl, 2.4, None, 4.0, ETA, 0.5, TH0);
    println!("try Phi 0.5, M 2.4 kg: settles {:.3} s, force jumps >1 N: {}", settle(&tr), jumps(&tr[1..]));
    let tr = run(Kind::Fl, 2.4, Some(8.0), 30.0, ETA, PHI, TH0);
    println!("try linearising k 8, M 2.4 kg: settles {:.3} s", settle(&tr));
    let tr = run(Kind::Smc, 2.4, None, 4.0, ETA, PHI, 1.0);
    println!("try start 1.0 rad, sliding M 2.4 kg: reaches {:.3} s (bound 1.0)", tr[reach(&tr, 0.0)].0);
    let line = |v: Vec<String>| v.join(" ");
    println!("chart, time s     {}", line((0..17).map(|i| format!("{:6.2}", i as f64 * 0.25)).collect()));
    let heavyfl = run(Kind::Fl, 2.4, Some(4.0), 4.0, ETA, PHI, TH0);
    for (lab, tr) in [("FL 2.0 kg ", &exact), ("FL 2.4 kg ", &heavyfl), ("SMC 2.4 kg", &heavy)] {
        println!("chart, {} {}", lab, line((0..17).map(|i| format!("{:6.3}", tr[i * 250].1)).collect()));
    }
    println!("chart2, time ms {}", line((0..21).map(|i| format!("{:5}", 1000 + i)).collect()));
    println!("chart2, sign N  {}", line((0..21).map(|i| format!("{:5.1}", heavy[1000 + i].3)).collect()));
    println!("chart2, layer N {}", line((0..21).map(|i| format!("{:5.1}", lay[1000 + i].3)).collect()));
    println!("ALL CHECKS PASS");
}
