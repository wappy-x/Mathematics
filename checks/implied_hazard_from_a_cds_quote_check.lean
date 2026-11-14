-- Implied hazard from one CDS quote: for recovery below 100% and a positive quote, exactly one flat hazard makes the quarterly-premium par spread equal the quote, the spread has the closed form with maturity cancelled, and with rates at or above zero that hazard lies between zero and the credit triangle's seed.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real Finset

/-- The risky annuity `A(λ) = ∑_{j=1}^{n} δ e^{-(r+λ) j δ}`: today's value of one unit a year of
premium, paid at the `n` quarter ends `δ, 2δ, …, nδ` while the name survives, with a flat
riskless rate `r` and a flat hazard `lam`. -/
noncomputable def riskyAnnuity (r δ : ℝ) (n : ℕ) (lam : ℝ) : ℝ :=
  ∑ j ∈ Finset.Icc 1 n, δ * Real.exp (-(r + lam) * ((j : ℝ) * δ))

/-- The protection leg `P(λ) = (1-R) ∫_0^T λ e^{-λt} e^{-rt} dt`: today's value of the loss
`1 - R` paid at the moment of default, for a flat hazard `lam` and a flat rate `r`. -/
noncomputable def protectionLeg (R r T lam : ℝ) : ℝ :=
  (1 - R) * ∫ t in (0 : ℝ)..T, lam * Real.exp (-lam * t) * Real.exp (-r * t)

/-- The par spread `s_par(λ) = P(λ) / A(λ)` of an `n`-premium contract with premiums every `δ`
years, maturity `T = n δ`, recovery `R` and flat rate `r`. -/
noncomputable def parSpread (R r δ : ℝ) (n : ℕ) (lam : ℝ) : ℝ :=
  protectionLeg R r ((n : ℝ) * δ) lam / riskyAnnuity r δ n lam


/-- Helper: integral of `exp (c t)` for `c ≠ 0`. -/
lemma ih_integral_exp_mul (c a b : ℝ) (hc : c ≠ 0) :
    ∫ t in a..b, Real.exp (c * t) = (Real.exp (c * b) - Real.exp (c * a)) / c := by
  rw [intervalIntegral.integral_comp_mul_left (fun t => Real.exp t) hc, integral_exp, smul_eq_mul]
  field_simp

/-- Helper: telescoping geometric sum. -/
lemma ih_geom (q : ℝ) (n : ℕ) :
    (1 - q) * ∑ j ∈ Finset.Icc 1 n, q ^ j = q * (1 - q ^ n) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]
    ring

/-- Helper: the timing factor `G x = ∫_0^1 e^{x u} du` is positive. -/
lemma ih_G_pos (x : ℝ) : 0 < ∫ u in (0 : ℝ)..1, Real.exp (x * u) := by
  apply intervalIntegral.intervalIntegral_pos_of_pos_on
  · exact (by fun_prop : Continuous fun u : ℝ => Real.exp (x * u)).intervalIntegrable _ _
  · intro u _; exact Real.exp_pos _
  · norm_num

/-- Helper: `G x ≥ 1` for `x ≥ 0`. -/
lemma ih_G_ge_one (x : ℝ) (hx : 0 ≤ x) : 1 ≤ ∫ u in (0 : ℝ)..1, Real.exp (x * u) := by
  have h : ∫ u in (0 : ℝ)..1, (1 : ℝ) ≤ ∫ u in (0 : ℝ)..1, Real.exp (x * u) := by
    apply intervalIntegral.integral_mono_on (by norm_num)
    · exact intervalIntegrable_const
    · exact (by fun_prop : Continuous fun u : ℝ => Real.exp (x * u)).intervalIntegrable _ _
    · intro u hu
      exact Real.one_le_exp (mul_nonneg hx hu.1)
  simpa using h

/-- Helper: `G` is monotone. -/
lemma ih_G_mono (x y : ℝ) (hxy : x ≤ y) :
    ∫ u in (0 : ℝ)..1, Real.exp (x * u) ≤ ∫ u in (0 : ℝ)..1, Real.exp (y * u) := by
  apply intervalIntegral.integral_mono_on (by norm_num)
  · exact (by fun_prop : Continuous fun u : ℝ => Real.exp (x * u)).intervalIntegrable _ _
  · exact (by fun_prop : Continuous fun u : ℝ => Real.exp (y * u)).intervalIntegrable _ _
  · intro u hu
    exact Real.exp_le_exp.mpr (mul_le_mul_of_nonneg_right hxy hu.1)

/-- Helper: `G` is continuous. -/
lemma ih_G_cont : Continuous fun x : ℝ => ∫ u in (0 : ℝ)..1, Real.exp (x * u) :=
  intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
    (f := fun x u : ℝ => Real.exp (x * u)) (by fun_prop) 0 1

/-- Helper: the closed form of the par spread. -/
lemma ih_closed_form (R r δ lam : ℝ) (n : ℕ) (hδ : 0 < δ) (hn : 0 < n) :
    parSpread R r δ n lam
      = (1 - R) * lam * ∫ u in (0 : ℝ)..1, Real.exp ((r + lam) * δ * u) := by
  set k := r + lam with hk
  set q := Real.exp (-k * δ) with hq
  have hP : protectionLeg R r ((n : ℝ) * δ) lam
      = (1 - R) * (lam * ∫ t in (0 : ℝ)..((n : ℝ) * δ), Real.exp ((-k) * t)) := by
    unfold protectionLeg
    congr 1
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro t _
    simp only
    rw [mul_assoc, ← Real.exp_add]
    congr 2
    ring
  have hA : riskyAnnuity r δ n lam = δ * ∑ j ∈ Finset.Icc 1 n, q ^ j := by
    unfold riskyAnnuity
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro j _
    rw [hq, ← Real.exp_nat_mul]
    congr 2
    ring
  have hqpos : 0 < q := Real.exp_pos _
  have hS : 0 < ∑ j ∈ Finset.Icc 1 n, q ^ j := by
    apply Finset.sum_pos (fun j _ => pow_pos hqpos j)
    exact ⟨1, Finset.mem_Icc.mpr ⟨le_refl 1, hn⟩⟩
  have hApos : 0 < riskyAnnuity r δ n lam := by rw [hA]; positivity
  unfold parSpread
  rw [div_eq_iff hApos.ne', hP, hA]
  by_cases hk0 : k = 0
  · have hq1 : q = 1 := by rw [hq, hk0]; simp
    simp only [hk0, neg_zero, zero_mul, Real.exp_zero, hq1, one_pow]
    simp
    ring
  · have hkd : k * δ ≠ 0 := mul_ne_zero hk0 hδ.ne'
    have hG : ∫ u in (0 : ℝ)..1, Real.exp (k * δ * u) = (Real.exp (k * δ) - 1) / (k * δ) := by
      rw [ih_integral_exp_mul _ _ _ hkd]; simp
    have hI : ∫ t in (0 : ℝ)..((n : ℝ) * δ), Real.exp ((-k) * t) = (q ^ n - 1) / (-k) := by
      rw [ih_integral_exp_mul _ _ _ (neg_ne_zero.mpr hk0), hq, ← Real.exp_nat_mul]
      congr 2
      · ring_nf
      · simp
    have hinv : Real.exp (k * δ) = q⁻¹ := by
      rw [hq, ← Real.exp_neg]; ring_nf
    rw [hG, hI, hinv]
    have hgeom := ih_geom q n
    field_simp
    linear_combination (-(1 - R) * lam) * hgeom

/-- Helper: the par spread is strictly increasing in the hazard on `[0, ∞)`. -/
lemma ih_strictMonoOn (R r δ : ℝ) (n : ℕ) (hR : R < 1) (hδ : 0 < δ) (hn : 0 < n) :
    StrictMonoOn (parSpread R r δ n) (Set.Ici 0) := by
  intro a ha b hb hab
  simp only [Set.mem_Ici] at ha hb
  rw [ih_closed_form _ _ _ _ _ hδ hn, ih_closed_form _ _ _ _ _ hδ hn]
  have hGa := ih_G_pos ((r + a) * δ)
  have hmono := ih_G_mono ((r + a) * δ) ((r + b) * δ)
    (mul_le_mul_of_nonneg_right (by linarith) hδ.le)
  have h1R : 0 < 1 - R := by linarith
  calc (1 - R) * a * ∫ u in (0 : ℝ)..1, Real.exp ((r + a) * δ * u)
      < (1 - R) * b * ∫ u in (0 : ℝ)..1, Real.exp ((r + a) * δ * u) := by
        apply mul_lt_mul_of_pos_right _ hGa
        exact mul_lt_mul_of_pos_left hab h1R
    _ ≤ (1 - R) * b * ∫ u in (0 : ℝ)..1, Real.exp ((r + b) * δ * u) := by
        apply mul_le_mul_of_nonneg_left hmono
        exact mul_nonneg h1R.le (by linarith)

/-- Helper: the par spread is continuous in the hazard. -/
lemma ih_continuous (R r δ : ℝ) (n : ℕ) (hδ : 0 < δ) (hn : 0 < n) :
    Continuous (parSpread R r δ n) := by
  have h : parSpread R r δ n
      = fun lam => (1 - R) * lam * ∫ u in (0 : ℝ)..1, Real.exp ((r + lam) * δ * u) := by
    funext lam; exact ih_closed_form _ _ _ _ _ hδ hn
  rw [h]
  exact (continuous_const.mul continuous_id).mul
    (ih_G_cont.comp ((continuous_const.add continuous_id).mul continuous_const))

/-- **One quote, one hazard.** With recovery below 100% and a positive quoted spread, there is
exactly one flat hazard `λ ≥ 0` whose par spread (quarterly premiums in arrears, nothing accrued
on default, loss paid at default, flat discount rate) equals the quote. -/
theorem implied_hazard_exists_unique (R r δ s : ℝ) (n : ℕ)
    (hR : R < 1) (hs : 0 < s) (hδ : 0 < δ) (hn : 0 < n) :
    ∃! lam : ℝ, 0 ≤ lam ∧ parSpread R r δ n lam = s := by
  have h1R : 0 < 1 - R := by linarith
  set M := s / (1 - R) + |r| with hM
  have hM0 : 0 ≤ M := by positivity
  have hf0 : parSpread R r δ n 0 = 0 := by
    rw [ih_closed_form _ _ _ _ _ hδ hn]; ring
  have hfM : s ≤ parSpread R r δ n M := by
    rw [ih_closed_form _ _ _ _ _ hδ hn]
    have hx : 0 ≤ (r + M) * δ := mul_nonneg (by have := neg_abs_le r; have := div_nonneg hs.le h1R.le; linarith) hδ.le
    have hG := ih_G_ge_one _ hx
    have hsM : s ≤ (1 - R) * M := by
      have : (1 - R) * (s / (1 - R)) = s := by field_simp
      nlinarith [abs_nonneg r]
    calc s ≤ (1 - R) * M := hsM
      _ = (1 - R) * M * 1 := by ring
      _ ≤ _ := mul_le_mul_of_nonneg_left hG (mul_nonneg h1R.le hM0)
  obtain ⟨lam, hlam, hval⟩ := intermediate_value_Icc hM0
    (ih_continuous R r δ n hδ hn).continuousOn ⟨by rw [hf0]; exact hs.le, hfM⟩
  refine ⟨lam, ⟨hlam.1, hval⟩, ?_⟩
  rintro y ⟨hy, hyv⟩
  exact (ih_strictMonoOn R r δ n hR hδ hn).injOn hy hlam.1 (hyv.trans hval.symm)

/-- **The closed form, where maturity cancels.** On a flat curve the par spread is the loss share
times the hazard times the timing factor `g(x) = ∫_0^1 e^{x u} du = (e^x - 1)/x`, with
`x = (r + λ) δ`; the number of premiums `n` (so the maturity) does not appear. -/
theorem parSpread_closed_form (R r δ lam : ℝ) (n : ℕ) (hδ : 0 < δ) (hn : 0 < n) :
    parSpread R r δ n lam
      = (1 - R) * lam * ∫ u in (0 : ℝ)..1, Real.exp ((r + lam) * δ * u) := by
  exact ih_closed_form R r δ lam n hδ hn

/-- **The bracket.** With rates at or above zero, recovery below 100% and a positive quote, the
implied hazard lies between zero and the credit triangle's seed `s / (1 - R)`, so a bracketed
search on `[0, s/(1-R)]` always finds it. -/
theorem implied_hazard_le_triangle_seed (R r δ s lam : ℝ) (n : ℕ)
    (hR : R < 1) (hs : 0 < s) (hδ : 0 < δ) (hn : 0 < n) (hr : 0 ≤ r)
    (hlam : 0 ≤ lam) (hpar : parSpread R r δ n lam = s) :
    lam ≤ s / (1 - R) := by
  have h1R : 0 < 1 - R := by linarith
  rw [ih_closed_form _ _ _ _ _ hδ hn] at hpar
  have hG := ih_G_ge_one ((r + lam) * δ) (mul_nonneg (by linarith) hδ.le)
  rw [le_div_iff₀ h1R]
  have : (1 - R) * lam * 1 ≤ (1 - R) * lam * ∫ u in (0 : ℝ)..1, Real.exp ((r + lam) * δ * u) :=
    mul_le_mul_of_nonneg_left hG (mul_nonneg h1R.le hlam)
  linarith

-- 300 bp on 10 million dollars is 300,000 dollars a year, 75,000 a quarter.
example : 10000000 * 300 / 10000 = 300000 := by norm_num
example : 300000 / 4 = 75000 := by norm_num
-- The triangle's seed: 3% / (1 - 40%) = 5%.
example : ((3 : ℚ) / 100) / (1 - 40 / 100) = 5 / 100 := by norm_num
-- One quarter's decay at the seed: x = (5% + 5%) × 1/4 = 1/40.
example : ((5 : ℚ) / 100 + 5 / 100) * (1 / 4) = 1 / 40 := by norm_num
-- Twelve halvings cut the bracket 4,096 times.
example : (2 : ℕ) ^ 12 = 4096 := by norm_num
-- Five years of quarterly premiums is 20 premium dates.
example : (5 : ℕ) * 4 = 20 := by norm_num

#print axioms ih_integral_exp_mul
#print axioms ih_geom
#print axioms ih_G_pos
#print axioms ih_G_ge_one
#print axioms ih_G_mono
#print axioms ih_G_cont
#print axioms ih_closed_form
#print axioms ih_strictMonoOn
#print axioms ih_continuous
#print axioms implied_hazard_exists_unique
#print axioms parSpread_closed_form
#print axioms implied_hazard_le_triangle_seed
