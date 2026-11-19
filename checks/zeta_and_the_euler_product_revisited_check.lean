-- Zeta of a complex variable: for real σ > 1 the value ζ(σ) is real and lies strictly between 1/(σ − 1) and σ/(σ − 1), for complex s with Re s > 1 the size of ζ(s) lies between ζ(2σ)/ζ(σ) and ζ(σ), and near s = 1 the log derivative −ζ′/ζ(s) equals 1/(s − 1) − γ up to an error of size O(s − 1).
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.Harmonic.ZetaAsymp
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.EulerProduct.DirichletLSeries

set_option autoImplicit false

open Complex Filter Topology Asymptotics

/-- Mean value step: for real m > 0 and σ > 1 the difference m^(1−σ) − (m+1)^(1−σ) lies strictly
between (σ − 1)(m+1)^(−σ) and (σ − 1) m^(−σ). -/
lemma zeta_mvt_aux (σ : ℝ) (hσ : 1 < σ) (m : ℝ) (hm : 0 < m) :
    (σ - 1) * (m + 1) ^ (-σ) < m ^ (1 - σ) - (m + 1) ^ (1 - σ) ∧
      m ^ (1 - σ) - (m + 1) ^ (1 - σ) < (σ - 1) * m ^ (-σ) := by
  obtain ⟨c, ⟨hc1, hc2⟩, hc⟩ := exists_hasDerivAt_eq_slope (fun x : ℝ => x ^ (1 - σ))
    (fun x : ℝ => (1 - σ) * x ^ (1 - σ - 1)) (by linarith : m < m + 1)
    (ContinuousOn.rpow_const continuousOn_id
      (fun x hx => Or.inl (ne_of_gt (lt_of_lt_of_le hm hx.1))))
    (fun x hx => Real.hasDerivAt_rpow_const (Or.inl (ne_of_gt (lt_trans hm hx.1))))
  have hcpos : 0 < c := lt_trans hm hc1
  have e1 : (1 : ℝ) - σ - 1 = -σ := by ring
  rw [e1, show m + 1 - m = (1 : ℝ) by ring, div_one] at hc
  have key : m ^ (1 - σ) - (m + 1) ^ (1 - σ) = (σ - 1) * c ^ (-σ) := by
    linarith
  have hneg : -σ < 0 := by linarith
  have i1 : c ^ (-σ) < m ^ (-σ) := Real.rpow_lt_rpow_of_neg hm hc1 hneg
  have i2 : (m + 1) ^ (-σ) < c ^ (-σ) := Real.rpow_lt_rpow_of_neg hcpos hc2 hneg
  have hs1 : 0 < σ - 1 := by linarith
  rw [key]
  exact ⟨mul_lt_mul_of_pos_left i2 hs1, mul_lt_mul_of_pos_left i1 hs1⟩

/-- Telescoping: the differences (n+1)^(1−σ) − (n+2)^(1−σ) sum to 1. -/
lemma zeta_telescope_aux (σ : ℝ) (hσ : 1 < σ) :
    HasSum (fun n : ℕ => ((n : ℝ) + 1) ^ (1 - σ) - ((n : ℝ) + 1 + 1) ^ (1 - σ)) 1 := by
  rw [hasSum_iff_tendsto_nat_of_nonneg]
  · have hsum : ∀ N : ℕ, ∑ i ∈ Finset.range N,
        (((i : ℝ) + 1) ^ (1 - σ) - ((i : ℝ) + 1 + 1) ^ (1 - σ)) = 1 - ((N : ℝ) + 1) ^ (1 - σ) := by
      intro N
      induction N with
      | zero => simp
      | succ N ih =>
        rw [Finset.sum_range_succ, ih]
        push_cast
        ring
    simp_rw [hsum]
    have h0 : Tendsto (fun N : ℕ => ((N : ℝ) + 1) ^ (1 - σ)) atTop (𝓝 0) := by
      have := (tendsto_rpow_neg_atTop (by linarith : 0 < σ - 1)).comp
        (tendsto_atTop_add_const_right _ 1 tendsto_natCast_atTop_atTop)
      simpa [Function.comp_def, neg_sub] using this
    simpa using (tendsto_const_nhds (x := (1 : ℝ))).sub h0
  · intro n
    have := (zeta_mvt_aux σ hσ ((n : ℝ) + 1) (by positivity)).1
    have : 0 < (σ - 1) * ((n : ℝ) + 1 + 1) ^ (-σ) := by
      have : 0 < σ - 1 := by linarith
      positivity
    linarith

/-- For a natural number p and real x, p^(−x) taken in ℂ is the real number p^(−x). -/
lemma prime_cpow_neg_ofReal (p : ℕ) (x : ℝ) :
    (p : ℂ) ^ (-(x : ℂ)) = (((p : ℝ) ^ (-x) : ℝ) : ℂ) := by
  rw [Complex.ofReal_cpow (by positivity)]
  push_cast
  rfl

/-- For a prime p and real x > 0, the size of 1 − p^(−x) is 1 − p^(−x). -/
lemma norm_one_sub_prime_cpow_ofReal (p : ℕ) (hp : p.Prime) (x : ℝ) (hx : 0 < x) :
    ‖1 - (p : ℂ) ^ (-(x : ℂ))‖ = 1 - (p : ℝ) ^ (-x) := by
  have h1 : (p : ℝ) ^ (-x) < 1 :=
    Real.rpow_lt_one_of_one_lt_of_neg (by exact_mod_cast hp.one_lt) (by linarith)
  rw [prime_cpow_neg_ofReal, ← Complex.ofReal_one, ← Complex.ofReal_sub, Complex.norm_real,
    Real.norm_of_nonneg (by linarith)]

/-- The size of p^(−s) is p^(−Re s). -/
lemma norm_prime_cpow_neg (p : ℕ) (hp : p.Prime) (s : ℂ) :
    ‖(p : ℂ) ^ (-s)‖ = (p : ℝ) ^ (-s.re) := by
  rw [norm_natCast_cpow_of_pos hp.pos]
  simp

/-- Upper bound for one Euler factor. -/
lemma euler_factor_le (p : ℕ) (hp : p.Prime) (s : ℂ) (hs : 1 < s.re) :
    ‖(1 - (p : ℂ) ^ (-s))⁻¹‖ ≤ ‖(1 - (p : ℂ) ^ (-((s.re : ℝ) : ℂ)))⁻¹‖ := by
  have ha : (p : ℝ) ^ (-s.re) < 1 :=
    Real.rpow_lt_one_of_one_lt_of_neg (by exact_mod_cast hp.one_lt) (by linarith)
  rw [norm_inv, norm_inv, norm_one_sub_prime_cpow_ofReal p hp _ (by linarith)]
  apply inv_anti₀ (by linarith)
  have := norm_sub_norm_le (1 : ℂ) ((p : ℂ) ^ (-s))
  rw [norm_one, norm_prime_cpow_neg p hp] at this
  exact this

/-- Lower bound for one Euler factor. -/
lemma euler_factor_ge (p : ℕ) (hp : p.Prime) (s : ℂ) (hs : 1 < s.re) :
    ‖(1 - (p : ℂ) ^ (-(((2 * s.re : ℝ)) : ℂ)))⁻¹‖ / ‖(1 - (p : ℂ) ^ (-((s.re : ℝ) : ℂ)))⁻¹‖
      ≤ ‖(1 - (p : ℂ) ^ (-s))⁻¹‖ := by
  set a := (p : ℝ) ^ (-s.re) with ha_def
  have ha : a < 1 :=
    Real.rpow_lt_one_of_one_lt_of_neg (by exact_mod_cast hp.one_lt) (by linarith)
  have ha0 : 0 < a := Real.rpow_pos_of_pos (by exact_mod_cast hp.pos) _
  have h2 : (p : ℝ) ^ (-(2 * s.re)) = a ^ 2 := by
    rw [ha_def, ← Real.rpow_natCast, ← Real.rpow_mul (by positivity)]
    congr 1
    push_cast
    ring
  rw [norm_inv, norm_inv, norm_inv, norm_one_sub_prime_cpow_ofReal p hp _ (by linarith),
    norm_one_sub_prime_cpow_ofReal p hp _ (by linarith), h2, ← ha_def]
  have e : (1 - a ^ 2)⁻¹ / (1 - a)⁻¹ = (1 + a)⁻¹ := by
    have h1 : 1 - a ≠ 0 := by linarith
    have h3 : 1 + a ≠ 0 := by linarith
    have h4 : 1 - a ^ 2 = (1 - a) * (1 + a) := by ring
    rw [h4]
    field_simp
  rw [e]
  have hpos : 0 < ‖1 - (p : ℂ) ^ (-s)‖ := by
    have := norm_sub_norm_le (1 : ℂ) ((p : ℂ) ^ (-s))
    rw [norm_one, norm_prime_cpow_neg p hp, ← ha_def] at this
    linarith
  apply inv_anti₀ hpos
  have := norm_sub_le (1 : ℂ) ((p : ℂ) ^ (-s))
  rw [norm_one, norm_prime_cpow_neg p hp, ← ha_def] at this
  exact this

/-- For real x > 1, the size of ζ(x) is its real part. -/
lemma norm_riemannZeta_ofReal (x : ℝ) (hx : 1 < x) :
    ‖riemannZeta (x : ℂ)‖ = (riemannZeta (x : ℂ)).re := by
  have him := riemannZeta_im_eq_zero_of_one_lt hx
  have hre := riemannZeta_re_pos_of_one_lt hx
  have e : riemannZeta (x : ℂ) = (((riemannZeta (x : ℂ)).re : ℝ) : ℂ) :=
    Complex.ext (by simp) (by simp [him])
  rw [e, Complex.norm_real, Real.norm_of_nonneg hre.le, Complex.ofReal_re]

/-- The bracket on the real axis: for every real σ > 1, zeta at σ is a real number that lies
strictly above 1/(σ − 1) and strictly below σ/(σ − 1). -/
theorem zeta_between_inv_sub_one_and_div_sub_one (σ : ℝ) (hσ : 1 < σ) :
    ∃ x : ℝ, riemannZeta (σ : ℂ) = x ∧ 1 / (σ - 1) < x ∧ x < σ / (σ - 1) := by
  have hs1 : 0 < σ - 1 := by linarith
  have hsum : Summable (fun n : ℕ => 1 / ((n : ℝ) + 1) ^ σ) := by
    exact_mod_cast (summable_nat_add_iff 1).mpr (Real.summable_one_div_nat_rpow.mpr hσ)
  have htel := (zeta_telescope_aux σ hσ).div_const (σ - 1)
  have hterm : ∀ m : ℝ, 0 < m → 1 / m ^ σ = m ^ (-σ) := by
    intro m hm; rw [Real.rpow_neg hm.le, one_div]
  have lo : ∀ n : ℕ, (((n : ℝ) + 1) ^ (1 - σ) - ((n : ℝ) + 1 + 1) ^ (1 - σ)) / (σ - 1)
      < 1 / ((n : ℝ) + 1) ^ σ := by
    intro n
    rw [hterm _ (by positivity), div_lt_iff₀ hs1]
    nlinarith [(zeta_mvt_aux σ hσ ((n : ℝ) + 1) (by positivity)).2]
  have hi : ∀ n : ℕ, 1 / (((n + 1 : ℕ) : ℝ) + 1) ^ σ
      < (((n : ℝ) + 1) ^ (1 - σ) - ((n : ℝ) + 1 + 1) ^ (1 - σ)) / (σ - 1) := by
    intro n
    rw [hterm _ (by positivity), lt_div_iff₀ hs1]
    push_cast
    nlinarith [(zeta_mvt_aux σ hσ ((n : ℝ) + 1) (by positivity)).1]
  refine ⟨∑' n : ℕ, 1 / ((n : ℝ) + 1) ^ σ, ?_, ?_, ?_⟩
  · rw [zeta_eq_tsum_one_div_nat_add_one_cpow (by simpa using hσ), Complex.ofReal_tsum]
    congr 1 with n
    rw [Complex.ofReal_div, Complex.ofReal_one, Complex.ofReal_cpow (by positivity)]
    push_cast
    rfl
  · have := hasSum_lt (f := fun n : ℕ =>
        (((n : ℝ) + 1) ^ (1 - σ) - ((n : ℝ) + 1 + 1) ^ (1 - σ)) / (σ - 1))
      (g := fun n : ℕ => 1 / ((n : ℝ) + 1) ^ σ) (i := 0) (fun n => (lo n).le) (lo 0)
      htel hsum.hasSum
    simpa using this
  · rw [hsum.tsum_eq_zero_add]
    have hsum' : Summable (fun n : ℕ => 1 / (((n + 1 : ℕ) : ℝ) + 1) ^ σ) :=
      (summable_nat_add_iff 1).mpr hsum
    have := hasSum_lt (g := fun n : ℕ =>
        (((n : ℝ) + 1) ^ (1 - σ) - ((n : ℝ) + 1 + 1) ^ (1 - σ)) / (σ - 1))
      (f := fun n : ℕ => 1 / (((n + 1 : ℕ) : ℝ) + 1) ^ σ) (i := 0) (fun n => (hi n).le) (hi 0)
      hsum'.hasSum htel
    have e : σ / (σ - 1) = 1 + 1 / (σ - 1) := by field_simp; ring
    rw [e]
    simp only [Nat.cast_zero, zero_add, Real.one_rpow, div_one]
    linarith

/-- Off the real axis zeta is never far from its real value: for complex s with real part
σ > 1, the size of ζ(s) is at least ζ(2σ)/ζ(σ) and at most ζ(σ). The floor is positive, so
ζ(s) is never 0 there. -/
theorem norm_zeta_between_ratio_and_zeta_re (s : ℂ) (hs : 1 < s.re) :
    (riemannZeta (2 * s.re : ℝ)).re / (riemannZeta (s.re : ℝ)).re ≤ ‖riemannZeta s‖ ∧
      ‖riemannZeta s‖ ≤ (riemannZeta (s.re : ℝ)).re := by
  have h1 : 1 < ((s.re : ℝ) : ℂ).re := by simpa using hs
  have h2 : 1 < ((2 * s.re : ℝ) : ℂ).re := by simp; linarith
  have Es := (riemannZeta_eulerProduct hs).norm
  have E1 := (riemannZeta_eulerProduct h1).norm
  have E2 := (riemannZeta_eulerProduct h2).norm
  rw [← norm_riemannZeta_ofReal _ hs, ← norm_riemannZeta_ofReal _ (by linarith)]
  constructor
  · refine le_of_tendsto_of_tendsto' (E2.div E1 (norm_ne_zero_iff.mpr
      (riemannZeta_ne_zero_of_one_lt_re h1))) Es (fun n => ?_)
    simp only [Pi.div_apply]
    rw [norm_prod, norm_prod, norm_prod, ← Finset.prod_div_distrib]
    exact Finset.prod_le_prod₀ (fun _ _ => by positivity)
      (fun p hp => euler_factor_ge p (Nat.prime_of_mem_primesBelow hp) s hs)
  · refine le_of_tendsto_of_tendsto' Es E1 (fun n => ?_)
    rw [norm_prod, norm_prod]
    exact Finset.prod_le_prod₀ (fun _ _ => norm_nonneg _)
      (fun p hp => euler_factor_le p (Nat.prime_of_mem_primesBelow hp) s hs)

/-- The log derivative near the pole: as s tends to 1 (with s ≠ 1),
−ζ′(s)/ζ(s) = 1/(s − 1) − γ + O(s − 1), where γ is Euler's constant. -/
theorem neg_log_deriv_zeta_sub_inv_add_gamma_isBigO :
    (fun s : ℂ => -(deriv riemannZeta s / riemannZeta s)
        - (1 / (s - 1) - (Real.eulerMascheroniConstant : ℂ)))
      =O[𝓝[≠] 1] (fun s : ℂ => s - 1) := by
  refine log_deriv_riemannZeta_add_inv_sub_sub_isBigO.neg_left.congr'
    (Eventually.of_forall fun s => ?_) EventuallyEq.rfl
  simp only [one_div]
  ring

-- The card's bracket at σ = 11/10 (that is, 1.1): ζ(1.1) lies between 10 and 11.
example : (1 : ℚ) / (11 / 10 - 1) = 10 ∧ (11 / 10 : ℚ) / (11 / 10 - 1) = 11 := by norm_num

-- The bracket at σ = 101/100 (that is, 1.01): ζ(1.01) lies between 100 and 101.
example : (1 : ℚ) / (101 / 100 - 1) = 100 ∧ (101 / 100 : ℚ) / (101 / 100 - 1) = 101 := by
  norm_num

-- The floor and ceiling of the bracket stay exactly 1 apart.
example (σ : ℚ) (hσ : 1 < σ) : σ / (σ - 1) - 1 / (σ - 1) = 1 := by
  have h : σ - 1 ≠ 0 := by linarith
  field_simp

-- The 168 primes up to 1,000 used in the card's partial Euler product.
example : Nat.primeCounting 1000 = 168 := by decide +kernel

#print axioms zeta_mvt_aux
#print axioms zeta_telescope_aux
#print axioms prime_cpow_neg_ofReal
#print axioms norm_one_sub_prime_cpow_ofReal
#print axioms norm_prime_cpow_neg
#print axioms euler_factor_le
#print axioms euler_factor_ge
#print axioms norm_riemannZeta_ofReal
#print axioms zeta_between_inv_sub_one_and_div_sub_one
#print axioms norm_zeta_between_ratio_and_zeta_re
#print axioms neg_log_deriv_zeta_sub_inv_add_gamma_isBigO
