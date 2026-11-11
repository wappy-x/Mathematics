// Orbits and the Kepler problem -- the check behind the card.  std only, no crates.
// A satellite in a 300 km circular orbit is raised to geostationary by two burns.
// Road 1: the conic-orbit formulas (Kepler's three laws, vis-viva).
// Road 2: Newton's inverse-square law stepped forward in time by RK4, burn by burn.
// Road 3 (the slow spiral): the same integrator with a small steady push.
use std::f64::consts::PI;

const MU: f64 = 3.986004418e14; // GM of Earth, m^3/s^2      (IERS Conventions 2010, Table 1.1)
const RE: f64 = 6378136.6; //      equatorial radius, m      (Table 1.1)
const J2: f64 = 1.0826359e-3; //   Earth's flattening term   (Table 1.1)
const OMEGA: f64 = 7.292115e-5; // Earth's spin, rad/s       (Table 1.2)
type S = [f64; 4];

fn vis_viva(r: f64, a: f64) -> f64 { (MU * (2.0 / r - 1.0 / a)).sqrt() }
fn kepler_r(t: f64) -> f64 { (MU * t * t / (4.0 * PI * PI)).powf(1.0 / 3.0) } // Kepler III
fn period(a: f64) -> f64 { 2.0 * PI * (a.powf(3.0) / MU).sqrt() }
fn hohmann(r1: f64, r2: f64) -> (f64, f64) {
    let at = (r1 + r2) / 2.0;
    (vis_viva(r1, at) - (MU / r1).sqrt(), (MU / r2).sqrt() - vis_viva(r2, at))
}
fn deriv(s: &S, push: f64) -> S {
    let (x, y, vx, vy) = (s[0], s[1], s[2], s[3]);
    let r3 = (x * x + y * y).powf(1.5);
    let v = (vx * vx + vy * vy).sqrt();
    [vx, vy, -MU * x / r3 + push * vx / v, -MU * y / r3 + push * vy / v]
}
fn step(s: &S, k: &S, f: f64) -> S { [s[0] + f * k[0], s[1] + f * k[1], s[2] + f * k[2], s[3] + f * k[3]] }
fn rk4(s: &S, dt: f64, push: f64) -> S {
    let k1 = deriv(s, push);
    let k2 = deriv(&step(s, &k1, dt / 2.0), push);
    let k3 = deriv(&step(s, &k2, dt / 2.0), push);
    let k4 = deriv(&step(s, &k3, dt), push);
    let mut o = [0.0; 4];
    for i in 0..4 { o[i] = s[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    o
}
fn rad(s: &S) -> f64 { (s[0].powf(2.0) + s[1].powf(2.0)).sqrt() }
fn spd(s: &S) -> f64 { (s[2].powf(2.0) + s[3].powf(2.0)).sqrt() }
fn out(label: &str, val: f64, unit: &str, d: usize) { println!("{:<44}{:>12.*} {}", label, d, val, unit); }

fn main() {
    // ---- road 1: the formulas ----
    let tday = 2.0 * PI / OMEGA;
    let (r1, r2) = (RE + 300e3, kepler_r(tday));
    let (v1, v2) = ((MU / r1).sqrt(), (MU / r2).sqrt());
    let (at, et) = ((r1 + r2) / 2.0, (r2 - r1) / (r2 + r1));
    let (vp, va) = (vis_viva(r1, at), vis_viva(r2, at));
    let (dv1, dv2) = hohmann(r1, r2);
    let h = r1 * vp;
    let p = h * h / MU;
    let three_burn_best = |a: f64, b: f64| (2f64.sqrt() - 1.0) * ((MU / a).sqrt() + (MU / b).sqrt());
    let (mut lo, mut hi) = (2.0f64, 50.0f64); // the size ratio r2/r1 where three burns start to beat two
    for _ in 0..60 {
        let (mid, d) = ((lo + hi) / 2.0, hohmann(r1, (lo + hi) / 2.0 * r1));
        if d.0 + d.1 < three_burn_best(r1, mid * r1) { lo = mid } else { hi = mid }
    }

    // ---- road 2: integrate Newton's law from burn 1 until r stops growing ----
    let mut s: S = [r1, 0.0, 0.0, vp];
    let (mut t, dt, mut conic_err, mut area, mut dist) = (0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64);
    let mut hours: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    loop {
        let n = rk4(&s, dt, 0.0);
        if n[0] * n[2] + n[1] * n[3] < 0.0 {
            let (a0, b0) = (s[0] * s[2] + s[1] * s[3], n[0] * n[2] + n[1] * n[3]);
            let frac = a0 / (a0 - b0);
            s = rk4(&s, frac * dt, 0.0);
            t += frac * dt;
            break;
        }
        area += 0.5 * (s[0] * s[3] - s[1] * s[2]) * dt;
        dist += (spd(&s) + spd(&n)) / 2.0 * dt;
        s = n;
        t += dt;
        conic_err = conic_err.max((rad(&s) - p / (1.0 + et * s[1].atan2(s[0]).cos())).abs());
        if (t.round() as i64) % 3600 == 0 {
            hours.push((t, rad(&s), spd(&s), area, dist));
            area = 0.0;
            dist = 0.0;
        }
    }
    let (ap_r, ap_v, t_coast) = (rad(&s), spd(&s), t);

    let k = (ap_v + dv2) / ap_v; // burn 2
    s = [s[0], s[1], s[2] * k, s[3] * k];
    let (mut ang, mut last, mut rmin, mut rmax) = (0.0f64, s[1].atan2(s[0]), 1e99f64, 0.0f64);
    let (mut t, dt) = (0.0f64, 10.0f64);
    while ang < 2.0 * PI {
        s = rk4(&s, dt, 0.0);
        t += dt;
        let a = s[1].atan2(s[0]);
        let d = a - last;
        ang += if d < -PI { d + 2.0 * PI } else { d };
        last = a;
        rmin = rmin.min(rad(&s));
        rmax = rmax.max(rad(&s));
    }
    let geo_t = t - (ang - 2.0 * PI) / ((MU / rad(&s)).sqrt() / rad(&s));

    let spiral = |push: f64, dt: f64| -> (f64, f64) {
        let (mut s, mut t): (S, f64) = ([r1, 0.0, 0.0, v1], 0.0);
        while spd(&s).powf(2.0) / 2.0 - MU / rad(&s) < -MU / (2.0 * r2) {
            s = rk4(&s, dt, push);
            t += dt;
        }
        (push * t, t)
    };
    let (sp_dv, sp_t) = spiral(0.02, 10.0);
    let (sp2_dv, _) = spiral(0.2, 1.0);

    out("sidereal day, 2 pi / omega", tday, "s", 2);
    out("r1, 300 km orbit", r1 / 1e3, "km", 2); out("r2, geostationary (Kepler III)", r2 / 1e3, "km", 2);
    out("r2 altitude", (r2 - RE) / 1e3, "km", 2);
    out("v1, circular speed low", v1, "m/s", 2); out("v2, circular speed high", v2, "m/s", 2);
    out("low orbit period", period(r1) / 60.0, "min", 2);
    out("transfer a", at / 1e3, "km", 2); out("transfer e", et, "-", 4);
    out("h = r1 vp", h / 1e9, "1e9 m^2/s", 4); out("p = h^2/MU", p / 1e3, "km", 2);
    out("1 formula  vp, perigee speed (vis-viva)", vp, "m/s", 2);
    out("1 formula  va, apogee speed (vis-viva)", va, "m/s", 2);
    out("1 formula  burn 1", dv1, "m/s", 2); out("1 formula  burn 2", dv2, "m/s", 2);
    out("1 formula  total", dv1 + dv2, "m/s", 2); out("1 formula  coast, half a period", period(at) / 2.0 / 3600.0, "h", 3);
    out("r2 / r1, size ratio of the two circles", r2 / r1, "-", 2);
    out("  three burns can win only above ratio", lo, "-", 2);
    out("2 simulate apogee radius", ap_r / 1e3, "km", 2); out("2 simulate apogee speed", ap_v, "m/s", 2);
    out("2 simulate coast time", t_coast / 3600.0, "h", 3);
    out("2 simulate worst gap from the conic", conic_err, "m", 4);
    out("2 simulate after burn 2, r wanders by", rmax - rmin, "m", 2);
    out("2 simulate lap time after burn 2", geo_t, "s", 2);
    for &(t, r, v, a, d) in &hours {
        println!("coast,{:.0} h,alt {:.0} km,speed {:.2} km/s,area {:.2} 1e12 m^2,distance {:.0} km",
                 t / 3600.0, (r - RE) / 1e3, v / 1e3, a / 1e12, d / 1e3);
    }
    println!("coast,{:.2} h,alt {:.0} km,speed {:.2} km/s", t_coast / 3600.0, (ap_r - RE) / 1e3, ap_v / 1e3);
    out("area per hour, h x 3600 / 2", h * 1800.0 / 1e12, "1e12 m^2", 2);
    out("3 spiral, push 0.02 m/s^2: speed gained", sp_dv, "m/s", 2); out("3 spiral time", sp_t / 86400.0, "days", 2);
    out("  spiral rule v1 - v2", v1 - v2, "m/s", 2); out("  spiral, push 0.2 m/s^2", sp2_dv, "m/s", 2);
    let node = (1.5 * 2.0 * PI / period(r1) * J2 * (RE / r1).powf(2.0) * 28.5f64.to_radians().cos()).to_degrees() * 86400.0;
    out("J2 drift of the orbit plane, 28.5 deg", node, "deg/day", 2);
    out("wrong: altitude as r in sqrt(MU/r)", (MU / 300e3).sqrt(), "m/s", 2);
    let rw = kepler_r(86400.0);
    out("wrong: 86400 s day, radius", rw / 1e3, "km", 2); out("  drift west", 360.0 * (86400.0 / tday - 1.0), "deg/day", 3);
    let ab = -MU / (2.0 * ((v1 - (v1 - v2)).powf(2.0) / 2.0 - MU / r1));
    out("wrong: brake by v1 - v2, lowest r", (2.0 * ab - r1) / 1e3, "km", 2);
    out("wrong: skip burn 2, period", period(at) / 3600.0, "h", 2);
    let (d5, g) = (hohmann(RE + 500e3, r2), hohmann(r1, kepler_r(tday / 2.0)));
    out("try: 500 km start, total", d5.0 + d5.1, "m/s", 2); out("try: to GPS height, radius", kepler_r(tday / 2.0) / 1e3, "km", 2);
    out("try: to GPS height, total", g.0 + g.1, "m/s", 2);
    println!("figure,scale 200 km/unit,earth {:.2},low {:.2},geo {:.2},ellipse centre {:.2},a {:.2},b {:.2}",
             RE / 2e5, r1 / 2e5, r2 / 2e5, (r1 - r2) / 4e5, at / 2e5, (r1 * r2).sqrt() / 2e5);

    assert!((ap_r - r2).abs() < 50.0); //                simulated apogee lands on the GEO radius
    assert!((ap_v - va).abs() < 0.01); //                simulated apogee speed = vis-viva
    assert!((t_coast - period(at) / 2.0).abs() < 0.5); // coast time = Kepler III half period
    assert!(conic_err < 1.0); //                         the path is r = p / (1 + e cos theta)
    assert!((geo_t - tday).abs() < 30.0); //             after burn 2, one lap per sidereal day
    assert!(rmax - rmin < 200.0); //                     ... and the orbit is a circle
    assert!(hours.iter().all(|x| (x.3 - h * 1800.0).abs() / (h * 1800.0) < 1e-6)); // equal areas
    assert!((sp_dv - (v1 - v2)).abs() / (v1 - v2) < 0.01); //                        spiral rule
    assert!(r2 / r1 < lo && dv1 + dv2 < three_burn_best(r1, r2)); //                   two burns win here
    println!("ALL CHECKS PASS");
}
