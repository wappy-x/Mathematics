-- The credit triangle: with a flat hazard and continuous premiums the par spread of a credit default swap is exactly (1 - R) times the hazard, quarter-end premiums raise it by a timing factor whose error is small and signed, and a rising hazard curve puts it at or below the calendar-average triangle.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib

open Real

lemma ct_exp_taylor_upper (x : ℝ) (hx : 0 < x) :
    exp x - 1 - x - x ^ 2 / 2 < x ^ 3 * exp x / 6 := by
  let m : ℝ → ℝ := fun y => y ^ 3 / 6 - 1 + exp (-y) * (1 + y + y ^ 2 / 2)
  have hd : ∀ y, HasDerivAt m (y ^ 2 / 2 * (1 - exp (-y))) y := by
    intro y
    have h1 : HasDerivAt (fun y : ℝ => exp (-y)) (exp (-y) * (-1)) y :=
      (hasDerivAt_neg y).exp
    have h2 : HasDerivAt (fun y : ℝ => 1 + y + y ^ 2 / 2) (0 + 1 + (2 * y ^ 1 * 1) / 2) y := by
      have := ((hasDerivAt_id' y).const_add 1).add ((hasDerivAt_pow 2 y).div_const 2)
      convert this using 1
      push_cast; ring
    have h3 : HasDerivAt (fun y : ℝ => y ^ 3 / 6) ((3 * y ^ 2 * 1) / 6) y := by
      convert (hasDerivAt_pow 3 y).div_const 6 using 1
      push_cast; ring
    have := (h3.sub_const 1).add (h1.mul h2)
    convert this using 1
    ring
  have hmono : StrictMonoOn m (Set.Ici 0) := by
    apply strictMonoOn_of_deriv_pos (convex_Ici 0)
    · exact fun y _ => (hd y).continuousAt.continuousWithinAt
    · intro y hy
      rw [interior_Ici] at hy
      rw [(hd y).deriv]
      have hy' : (0:ℝ) < y := hy
      have : exp (-y) < 1 := by rw [exp_lt_one_iff]; linarith
      have : 0 < y ^ 2 := by positivity
      nlinarith
  have hm : m 0 < m x := hmono (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr hx.le) hx
  simp only [m] at hm
  norm_num at hm
  have hex : exp x * exp (-x) = 1 := by rw [← exp_add]; simp
  have hpos : 0 < exp x := exp_pos x
  nlinarith [hex, hpos]

lemma ct_exp_taylor_lower (x : ℝ) (hx : 0 < x) :
    1 + x + x ^ 2 / 2 < exp x := by
  have h := sum_le_exp_of_nonneg hx.le 4
  simp [Finset.sum_range_succ, Nat.factorial] at h
  have : 0 < x ^ 3 := by positivity
  nlinarith

lemma ct_geom (q : ℝ) (n : ℕ) :
    (∑ j ∈ Finset.Icc 1 n, q ^ j) * (1 - q) = q * (1 - q ^ n) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), add_mul, ih]
    ring

lemma ct_chebyshev (f g : ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (hf : MonotoneOn f (Set.Icc 0 T)) (hg : AntitoneOn g (Set.Icc 0 T))
    (hfi : IntervalIntegrable f MeasureTheory.volume 0 T)
    (hgi : IntervalIntegrable g MeasureTheory.volume 0 T)
    (hfgi : IntervalIntegrable (fun t => f t * g t) MeasureTheory.volume 0 T) :
    T * (∫ t in (0)..T, f t * g t) ≤ (∫ t in (0)..T, f t) * ∫ t in (0)..T, g t := by
  have hpt : ∀ s ∈ Set.Icc 0 T, ∀ t ∈ Set.Icc 0 T,
      f t * g t + f s * g s ≤ f t * g s + g t * f s := by
    intro s hs t ht
    rcases le_total s t with h | h
    · have h1 := hf hs ht h; have h2 := hg hs ht h; nlinarith
    · have h1 := hf ht hs h; have h2 := hg ht hs h; nlinarith
  have hinner : ∀ t ∈ Set.Icc 0 T, T * (f t * g t) + (∫ s in (0)..T, f s * g s) ≤
      f t * (∫ s in (0)..T, g s) + g t * ∫ s in (0)..T, f s := by
    intro t ht
    have h := intervalIntegral.integral_mono_on hT
      ((intervalIntegrable_const (c := f t * g t)).add hfgi)
      ((hgi.const_mul (f t)).add (hfi.const_mul (g t)))
      (fun s hs => hpt s hs t ht)
    rw [intervalIntegral.integral_add intervalIntegrable_const hfgi,
      intervalIntegral.integral_add (hgi.const_mul (f t)) (hfi.const_mul (g t)),
      intervalIntegral.integral_const, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul] at h
    simpa [smul_eq_mul] using h
  have h := intervalIntegral.integral_mono_on hT
    ((hfgi.const_mul T).add (intervalIntegrable_const (c := ∫ s in (0)..T, f s * g s)))
    ((hfi.mul_const (∫ s in (0)..T, g s)).add (hgi.mul_const (∫ s in (0)..T, f s)))
    (fun t ht => by have := hinner t ht; linarith)
  rw [intervalIntegral.integral_add (hfgi.const_mul T) intervalIntegrable_const,
    intervalIntegral.integral_add (hfi.mul_const _) (hgi.mul_const _),
    intervalIntegral.integral_const, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_mul_const, intervalIntegral.integral_mul_const] at h
  simp only [smul_eq_mul, sub_zero] at h
  nlinarith

#print axioms ct_exp_taylor_upper
#print axioms ct_exp_taylor_lower
#print axioms ct_geom
#print axioms ct_chebyshev

/-- The credit triangle, exact form. With a flat hazard `lam`, a recovery `R` below 1 paid at
the default date, premiums paid continuously over a tenor `T > 0`, and discount factor
`e^(-r t)` times survival `e^(-lam t)` as the weight on each date, a spread `s` balances the
premium leg against the protection leg exactly when `s = (1 - R) * lam`. -/
theorem par_spread_eq_loss_times_hazard (T r lam R s : ℝ) (hT : 0 < T) (hR : R < 1) :
    s * ∫ t in (0)..T, exp (-r * t) * exp (-lam * t) =
        (1 - R) * ∫ t in (0)..T, lam * (exp (-r * t) * exp (-lam * t)) ↔
      s = (1 - R) * lam := by
  have hI : 0 < ∫ t in (0)..T, exp (-r * t) * exp (-lam * t) := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · exact (by fun_prop : Continuous fun t => exp (-r * t) * exp (-lam * t)).intervalIntegrable _ _
    · intro t _; positivity
    · exact hT
  rw [intervalIntegral.integral_const_mul]
  constructor
  · intro h
    apply mul_right_cancel₀ hI.ne'
    rw [h]; ring
  · intro h; rw [h]; ring

/-- Quarter-end premiums. With `n ≥ 1` premium dates `j * δ`, each paying `s * δ` if the name
is still alive, a flat hazard `lam > 0`, a riskless rate `r ≥ 0` and recovery `R < 1`, the
spread `s` that balances the dated premium leg against the continuous protection leg over
`[0, n δ]` is the triangle times the timing factor `(e^x - 1)/x`, with `x = (r + lam) δ`.
The rule of thumb `(1 - R) lam (1 + x/2)` reads strictly low, by less than
`(1 - R) lam x^2 e^x / 6`. -/
theorem dated_spread_eq_triangle_times_timing_factor (n : ℕ) (δ r lam R s x : ℝ)
    (hn : 0 < n) (hδ : 0 < δ) (hr : 0 ≤ r) (hlam : 0 < lam) (hR : R < 1)
    (hx : x = (r + lam) * δ)
    (hs : s * ∑ j ∈ Finset.Icc 1 n, δ * exp (-(r + lam) * ((j : ℝ) * δ)) =
      (1 - R) * ∫ t in (0)..((n : ℝ) * δ), lam * exp (-(r + lam) * t)) :
    s = (1 - R) * lam * ((exp x - 1) / x) ∧
      0 < s - (1 - R) * lam * (1 + x / 2) ∧
      s - (1 - R) * lam * (1 + x / 2) < (1 - R) * lam * (x ^ 2 * exp x / 6) := by
  have ha0 : 0 < r + lam := by linarith
  have hx0 : 0 < x := by rw [hx]; positivity
  have hq1 : exp (-x) < 1 := by rw [exp_lt_one_iff]; linarith
  have hq0 : 0 < exp (-x) := exp_pos _
  have hQ1 : exp (-x) ^ n < 1 := pow_lt_one₀ hq0.le hq1 hn.ne'
  have hqE : exp (-x) * exp x = 1 := by rw [← exp_add]; simp
  have hterm : ∀ j : ℕ, δ * exp (-(r + lam) * ((j : ℝ) * δ)) = δ * exp (-x) ^ j := by
    intro j; rw [← exp_nat_mul]; congr 2; rw [hx]; ring
  have hsum : ∑ j ∈ Finset.Icc 1 n, δ * exp (-(r + lam) * ((j : ℝ) * δ)) =
      δ * ∑ j ∈ Finset.Icc 1 n, exp (-x) ^ j := by
    rw [Finset.mul_sum]; exact Finset.sum_congr rfl (fun j _ => hterm j)
  have hint : (r + lam) * ∫ t in (0)..((n : ℝ) * δ), lam * exp (-(r + lam) * t) =
      lam * (1 - exp (-x) ^ n) := by
    have hderiv : ∀ t ∈ Set.uIcc 0 ((n : ℝ) * δ),
        HasDerivAt (fun t => -lam / (r + lam) * exp (-(r + lam) * t))
          (lam * exp (-(r + lam) * t)) t := by
      intro t _
      have := ((hasDerivAt_id' t).const_mul (-(r + lam))).exp.const_mul (-lam / (r + lam))
      convert this using 1
      field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv
      ((by fun_prop : Continuous fun t => lam * exp (-(r + lam) * t)).intervalIntegrable _ _)]
    have hpow : exp (-(r + lam) * ((n : ℝ) * δ)) = exp (-x) ^ n := by
      rw [← exp_nat_mul]; congr 1; rw [hx]; ring
    rw [hpow]
    simp only [mul_zero, exp_zero, mul_one]
    field_simp
    ring
  rw [hsum] at hs
  have hG := ct_geom (exp (-x)) n
  set S := ∑ j ∈ Finset.Icc 1 n, exp (-x) ^ j
  set q := exp (-x)
  set Q := q ^ n
  set I := ∫ t in (0)..((n : ℝ) * δ), lam * exp (-(r + lam) * t)
  have h1 : s * x * q * (1 - Q) = (1 - R) * lam * (1 - q) * (1 - Q) := by
    rw [hx]
    linear_combination (r + lam) * (1 - q) * hs + (1 - R) * (1 - q) * hint
      - s * (r + lam) * δ * hG
  have h2 : s * x * q = (1 - R) * lam * (1 - q) :=
    mul_right_cancel₀ (by linarith : (1 - Q) ≠ 0) h1
  have key : s * x = (1 - R) * lam * (exp x - 1) := by
    linear_combination exp x * h2 - (s * x + (1 - R) * lam) * hqE
  have hs' : s = (1 - R) * lam * ((exp x - 1) / x) := by
    rw [mul_div_assoc', eq_div_iff hx0.ne']; exact key
  have hdiff : s - (1 - R) * lam * (1 + x / 2) =
      (1 - R) * lam * ((exp x - 1 - x - x ^ 2 / 2) / x) := by
    rw [hs']; field_simp; ring
  have hc : 0 < (1 - R) * lam := mul_pos (by linarith) hlam
  refine ⟨hs', ?_, ?_⟩
  · rw [hdiff]
    have := ct_exp_taylor_lower x hx0
    apply mul_pos hc
    apply div_pos _ hx0
    linarith
  · rw [hdiff]
    apply mul_lt_mul_of_pos_left _ hc
    rw [div_lt_iff₀ hx0]
    have := ct_exp_taylor_upper x hx0
    linarith

/-- A rising hazard. If the hazard `lam t` is nonnegative and never falls on `[0, T]`, the
rate `r` is at least 0 and recovery `R` is below 1, then the continuous-premium spread,
`(1 - R)` times the average of the hazard weighted by `w t = e^(-r t) S(t)` with survival
`S(t) = exp (-∫₀ᵗ lam)`, is at most the triangle on the calendar average,
`(1 - R) * (1/T) ∫₀ᵀ lam`. -/
theorem rising_hazard_spread_le_calendar_triangle (T r R : ℝ) (lam : ℝ → ℝ)
    (hT : 0 < T) (hr : 0 ≤ r) (hR : R < 1)
    (hlam0 : ∀ t ∈ Set.Icc 0 T, 0 ≤ lam t) (hmono : MonotoneOn lam (Set.Icc 0 T)) :
    (1 - R) * ((∫ t in (0)..T, lam t * (exp (-r * t) * exp (-∫ u in (0)..t, lam u))) /
        ∫ t in (0)..T, exp (-r * t) * exp (-∫ u in (0)..t, lam u)) ≤
      (1 - R) * ((∫ t in (0)..T, lam t) / T) := by
  have hIcc : Set.uIcc 0 T = Set.Icc 0 T := Set.uIcc_of_le hT.le
  have hsub : ∀ a ∈ Set.Icc 0 T, ∀ b ∈ Set.Icc 0 T,
      IntervalIntegrable lam MeasureTheory.volume a b :=
    fun a ha b hb => (hmono.mono (Set.uIcc_subset_Icc ha hb)).intervalIntegrable
  have h0 : (0 : ℝ) ∈ Set.Icc 0 T := ⟨le_rfl, hT.le⟩
  have hTm : T ∈ Set.Icc 0 T := ⟨hT.le, le_rfl⟩
  have hli : IntervalIntegrable lam MeasureTheory.volume 0 T := hsub 0 h0 T hTm
  have hΛc : ContinuousOn (fun t => ∫ u in (0)..t, lam u) (Set.Icc 0 T) := by
    rw [← hIcc]
    exact intervalIntegral.continuousOn_primitive_interval' hli Set.left_mem_uIcc
  have hwc : ContinuousOn (fun t => exp (-r * t) * exp (-∫ u in (0)..t, lam u)) (Set.Icc 0 T) :=
    ((by fun_prop : Continuous fun t : ℝ => exp (-r * t)).continuousOn).mul
      (Real.continuous_exp.comp_continuousOn hΛc.neg)
  have hwi : IntervalIntegrable (fun t => exp (-r * t) * exp (-∫ u in (0)..t, lam u))
      MeasureTheory.volume 0 T := by
    apply ContinuousOn.intervalIntegrable; rw [hIcc]; exact hwc
  have hlwi : IntervalIntegrable (fun t => lam t * (exp (-r * t) * exp (-∫ u in (0)..t, lam u)))
      MeasureTheory.volume 0 T := by
    apply hli.mul_continuousOn; rw [hIcc]; exact hwc
  have hanti : AntitoneOn (fun t => exp (-r * t) * exp (-∫ u in (0)..t, lam u)) (Set.Icc 0 T) := by
    intro s hs t ht hst
    have hΛ : (∫ u in (0)..s, lam u) ≤ ∫ u in (0)..t, lam u := by
      have hd := intervalIntegral.integral_interval_sub_left (hsub 0 h0 t ht) (hsub 0 h0 s hs)
      have hnn : 0 ≤ ∫ u in s..t, lam u :=
        intervalIntegral.integral_nonneg hst (fun u hu => hlam0 u ⟨hs.1.trans hu.1, hu.2.trans ht.2⟩)
      linarith
    have e1 : exp (-r * t) ≤ exp (-r * s) := by
      rw [exp_le_exp]; nlinarith
    have e2 : exp (-∫ u in (0)..t, lam u) ≤ exp (-∫ u in (0)..s, lam u) := by
      rw [exp_le_exp]; linarith
    exact mul_le_mul e1 e2 (exp_pos _).le (exp_pos _).le
  have hA : 0 < ∫ t in (0)..T, exp (-r * t) * exp (-∫ u in (0)..t, lam u) :=
    intervalIntegral.intervalIntegral_pos_of_pos_on hwi (fun t _ => by positivity) hT
  have hcheb := ct_chebyshev lam (fun t => exp (-r * t) * exp (-∫ u in (0)..t, lam u)) T hT.le
    hmono hanti hli hwi hlwi
  apply mul_le_mul_of_nonneg_left _ (by linarith)
  rw [div_le_div_iff₀ hA hT]
  linarith

-- Northwind: loss 1 - 0.40 = 0.60, triangle 0.60 × 0.02 = 0.012 = 120 bp.
example : (1 - (2 / 5 : ℚ)) * (1 / 50) = 120 / 10000 := by norm_num
-- Yearly premium on $10 million at the triangle spread: $120,000.
example : (120 / 10000 : ℚ) * 10000000 = 120000 := by norm_num
-- Timing term x = (0.05 + 0.02) × 0.25 = 0.0175, and x/2 = 0.875%.
example : ((1 / 20 + 1 / 50 : ℚ) * (1 / 4)) = 175 / 10000 ∧ (175 / 10000 : ℚ) / 2 = 875 / 100000 := by
  norm_num
-- Backwards: a 300 bp quote at 40% recovery seeds a 5% hazard.
example : (300 / 10000 : ℚ) / (1 - 2 / 5) = 5 / 100 := by norm_num
-- Backwards: 120 bp with a 2% hazard gives 40% recovery.
example : 1 - (120 / 10000 : ℚ) / (2 / 100) = 2 / 5 := by norm_num
-- Seed timing term at 5%: x/2 = (0.05 + 0.05) × 0.25 / 2 = 1.25%.
example : (1 / 20 + 1 / 20 : ℚ) * (1 / 4) / 2 = 125 / 10000 := by norm_num
-- Rising curve 1% then 3%: calendar average 2.2%, calendar triangle 132 bp.
example : (2 * (1 / 100) + 3 * (3 / 100) : ℚ) / 5 = 22 / 1000 ∧
    (3 / 5 : ℚ) * (22 / 1000) = 132 / 10000 := by norm_num
-- Falling curve 3% then 1%: calendar triangle 108 bp.
example : (3 / 5 : ℚ) * ((2 * (3 / 100) + 3 * (1 / 100)) / 5) = 108 / 10000 := by norm_num
-- What breaks: R in place of 1 - R gives 80 bp; 300 bp divided by R gives 7.5%; 5 × 2% = 10%.
example : (2 / 5 : ℚ) * (2 / 100) = 80 / 10000 ∧ (300 / 10000 : ℚ) / (2 / 5) = 75 / 1000 ∧
    5 * (2 / 100 : ℚ) = 10 / 100 := by norm_num

#print axioms par_spread_eq_loss_times_hazard
#print axioms dated_spread_eq_triangle_times_timing_factor
#print axioms rising_hazard_spread_le_calendar_triangle
