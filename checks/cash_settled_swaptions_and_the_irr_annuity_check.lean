-- Cash-settled swaptions: the IRR annuity equals n at a zero rate, is positive, falls as the swap rate rises and bends upward; the linear terminal swap rate model reprices today's bond; and payer minus receiver misses the forward swap by a zero-volatility part, a tilt and a bend term, the last two zero when the rate cannot move.
import Mathlib

open Real Finset MeasureTheory

/-! `n` yearly fixed payments. The IRR annuity `a(S) = ∑_{i=1}^{n} (1 + S)^{-i}` discounts each
payment at the swap rate `S` itself. In the code the sum runs over `i ∈ range n`, standing for the
payments `i + 1 = 1, …, n`. `m` is the cash annuity counted in true annuities, `F` the forward swap
rate and `K` the strike; a law `μ` of the swap rate on the expiry date stands for the annuity
measure's weights. -/

/-- The IRR annuity `a(S)`. -/
noncomputable def irrAnnuity (n : ℕ) (S : ℝ) : ℝ := ∑ i ∈ range n, ((1 + S) ^ (i + 1))⁻¹

/-- At a zero rate every payment is worth a dollar, so the IRR annuity is `n`. -/
theorem irrAnnuity_at_zero (n : ℕ) : irrAnnuity n 0 = n := by simp [irrAnnuity]

/-- For any rate above `-100` percent the IRR annuity is positive. -/
theorem irrAnnuity_pos (n : ℕ) (hn : 0 < n) (S : ℝ) (hS : -1 < S) : 0 < irrAnnuity n S := by
  have h : 0 < 1 + S := by linarith
  exact sum_pos (fun i _ ↦ by positivity) (nonempty_range_iff.mpr hn.ne')

/-- The IRR annuity falls as the swap rate rises. -/
theorem irrAnnuity_strictAnti (n : ℕ) (hn : 0 < n) :
    StrictAntiOn (irrAnnuity n) (Set.Ioi (-1)) := by
  intro x hx y hy hxy
  have hx' : 0 < 1 + x := by simp only [Set.mem_Ioi] at hx; linarith
  have hy' : 0 < 1 + y := by linarith
  apply sum_lt_sum_of_nonempty (nonempty_range_iff.mpr hn.ne')
  intro i _
  rw [inv_lt_inv₀ (by positivity) (by positivity)]
  exact pow_lt_pow_left₀ (by linarith) hx'.le (by omega)

/-- Its slope: `a'(S) = -∑_{i=1}^{n} i (1 + S)^{-(i+1)}`, the formula the checks compare with
nudges. -/
theorem hasDerivAt_irrAnnuity (n : ℕ) (S : ℝ) (hS : -1 < S) :
    HasDerivAt (irrAnnuity n) (∑ i ∈ range n, -((i:ℝ) + 1) * ((1 + S) ^ (i + 2))⁻¹) S := by
  have h : 0 < 1 + S := by linarith
  have hsum : HasDerivAt (fun y ↦ ∑ i ∈ range n, ((1 + y) ^ (i + 1))⁻¹)
      (∑ i ∈ range n, -((i:ℝ) + 1) * ((1 + S) ^ (i + 2))⁻¹) S := by
    apply HasDerivAt.fun_sum
    intro i _
    have hp : HasDerivAt (fun y ↦ (1 + y) ^ (i + 1)) (((i + 1 : ℕ) : ℝ) * (1 + S) ^ (i + 1 - 1) * 1) S :=
      ((hasDerivAt_id S).const_add 1).pow (i + 1)
    convert hp.inv (by positivity) using 1
    simp only [Nat.add_sub_cancel, mul_one]
    push_cast
    field_simp
    ring
  exact hsum

/-- Each payment's value `(1 + S)^{-(i+1)}` bends upward in the rate. -/
lemma payment_strictConvexOn (i : ℕ) :
    StrictConvexOn ℝ (Set.Ioi (-1)) (fun S : ℝ ↦ ((1 + S) ^ (i + 1))⁻¹) := by
  have h := (strictConvexOn_zpow (m := -((i:ℤ) + 1)) (by omega) (by omega)).translate_right 1
  have hs : ((fun z : ℝ ↦ 1 + z) ⁻¹' Set.Ioi 0) = Set.Ioi (-1) := by
    ext z; simp only [Set.mem_preimage, Set.mem_Ioi]; constructor <;> intro hz <;> linarith
  have hf : ((fun x : ℝ ↦ x ^ (-((i:ℤ) + 1))) ∘ fun z ↦ 1 + z)
      = fun S : ℝ ↦ ((1 + S) ^ (i + 1))⁻¹ := by
    funext S
    simp only [Function.comp]
    rw [show -((i:ℤ) + 1) = -((i + 1 : ℕ) : ℤ) by push_cast; ring, zpow_neg, zpow_natCast]
  rw [hs, hf] at h
  exact h

/-- The IRR annuity bends upward: it is strictly convex in the swap rate. -/
theorem irrAnnuity_strictConvexOn (n : ℕ) (hn : 0 < n) :
    StrictConvexOn ℝ (Set.Ioi (-1)) (irrAnnuity n) := by
  have hstep : ∀ k, irrAnnuity (k + 1) = irrAnnuity k + fun S ↦ ((1 + S) ^ (k + 1))⁻¹ := by
    intro k; funext S; simp [irrAnnuity, sum_range_succ]
  have hc : ∀ k, ConvexOn ℝ (Set.Ioi (-1)) (irrAnnuity k) := by
    intro k
    induction k with
    | zero =>
      have h0 : irrAnnuity 0 = fun _ ↦ (0:ℝ) := by funext S; simp [irrAnnuity]
      rw [h0]; exact convexOn_const 0 (convex_Ioi _)
    | succ j ih => rw [hstep]; exact ih.add (payment_strictConvexOn j).convexOn
  obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
  rw [hstep]
  exact (hc k).add_strictConvexOn (payment_strictConvexOn k)

/-- For any rate, a payer's payoff minus a receiver's is the swap's payoff: `(s - K)⁺ - (K - s)⁺ = s - K`. -/
theorem payer_minus_receiver (s K : ℝ) : max (s - K) 0 - max (K - s) 0 = s - K := by
  rcases le_total s K with h | h
  · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring

/-- The linear terminal swap rate model `1/A_T = α₀ + b S_T`, with `α₀ = 1/n` and slope
`b = (D(T)/A - α₀)/F`, reprices today's bond: for any law of the swap rate averaging `F`,
`A × E[α₀ + b S_T] = D(T)`. -/
theorem tsr_reprices_bond (μ : Measure ℝ) [IsProbabilityMeasure μ] (hint : Integrable id μ)
    (n : ℕ) (hn : 0 < n) (A D F : ℝ) (hA : 0 < A) (hF : F ≠ 0) (hmean : ∫ s, s ∂μ = F) :
    A * ∫ s, (1 / (n:ℝ) + (D / A - 1 / n) / F * s) ∂μ = D := by
  have hn' : (n:ℝ) ≠ 0 := by positivity
  have hi : Integrable (fun s : ℝ ↦ (D / A - 1 / n) / F * s) μ := hint.const_mul _
  rw [integral_add (integrable_const _) hi, integral_const, integral_const_mul, hmean]
  simp only [probReal_univ, one_smul]
  field_simp
  ring

/-- Payer minus receiver misses the forward swap by three pieces: the zero-volatility part
`(m(F) - 1)(F - K)`, the tilt `E[m(S)(S - F)]` and the bend term `(F - K)(E[m] - m(F))`.
It holds for any law of the swap rate and any multiplier `m`. -/
theorem gap_split (μ : Measure ℝ) (m : ℝ → ℝ) (F K : ℝ) (hm : Integrable m μ)
    (hms : Integrable (fun s ↦ m s * s) μ) :
    (∫ s, m s * (s - K) ∂μ) - (F - K)
      = (m F - 1) * (F - K) + (∫ s, m s * (s - F) ∂μ) + (F - K) * ((∫ s, m s ∂μ) - m F) := by
  have e : ∀ c, ∫ s, m s * (s - c) ∂μ = (∫ s, m s * s ∂μ) - c * ∫ s, m s ∂μ := by
    intro c
    have : (fun s ↦ m s * (s - c)) = fun s ↦ m s * s - c * m s := by funext s; ring
    rw [this, integral_sub hms (hm.const_mul c), integral_const_mul]
  rw [e K, e F]
  ring

/-- If the rate cannot move, its law is the single point `F`; the tilt and the bend term are
both zero, and the whole gap is the zero-volatility part. -/
theorem no_volatility_no_tilt_or_bend (m : ℝ → ℝ) (F K : ℝ) :
    (∫ s, m s * (s - F) ∂(Measure.dirac F)) = 0 ∧
      (F - K) * ((∫ s, m s ∂(Measure.dirac F)) - m F) = 0 := by
  simp

/-- A straight-line multiplier `m(s) = c₀ + c₁ s` already has a tilt: for a law averaging `F`,
the tilt is `c₁` times the variance of the swap rate. No hump is needed. -/
theorem linear_multiplier_tilt (μ : Measure ℝ) [IsProbabilityMeasure μ] (c₀ c₁ F : ℝ)
    (h1 : Integrable id μ) (h2 : Integrable (fun s ↦ s ^ 2) μ) (hmean : ∫ s, s ∂μ = F) :
    ∫ s, (c₀ + c₁ * s) * (s - F) ∂μ = c₁ * ∫ s, (s - F) ^ 2 ∂μ := by
  have ha : (fun s ↦ (c₀ + c₁ * s) * (s - F))
      = fun s ↦ (c₁ * s ^ 2 + (c₀ - c₁ * F) * s) - c₀ * F := by funext s; ring
  have hb : (fun s ↦ (s - F) ^ 2) = fun s ↦ (s ^ 2 - 2 * F * s) + F ^ 2 := by funext s; ring
  have i1 : Integrable (fun s ↦ c₁ * s ^ 2) μ := h2.const_mul _
  have i2 : Integrable (fun s ↦ (c₀ - c₁ * F) * s) μ := h1.const_mul _
  have i3 : Integrable (fun s ↦ 2 * F * s) μ := h1.const_mul _
  have i12 : Integrable (fun s ↦ c₁ * s ^ 2 + (c₀ - c₁ * F) * s) μ := i1.add i2
  have i23 : Integrable (fun s ↦ s ^ 2 - 2 * F * s) μ := h2.sub i3
  have m1 : ∫ s, (c₀ - c₁ * F) * s ∂μ = (c₀ - c₁ * F) * F := by rw [integral_const_mul, hmean]
  have m2 : ∫ s, 2 * F * s ∂μ = 2 * F * F := by rw [integral_const_mul, hmean]
  have m3 : ∫ s, c₁ * s ^ 2 ∂μ = c₁ * ∫ s, s ^ 2 ∂μ := integral_const_mul _ _
  rw [ha, hb, integral_sub i12 (integrable_const _), integral_add i1 i2,
    integral_add i23 (integrable_const _), integral_sub h2 i3, m1, m2, m3]
  simp only [integral_const, probReal_univ, one_smul]
  ring

/-! The card's curve: one-year forward rates 5.0, 4.6, 4.3, 4.1, 4.0 and 3.9 percent. -/

/-- The model's slope `b = (D(1)/A - 1/5)/F` rounds to 0.632347, the IRR annuity at the forward
`a(F)` to 4.427700, and the multiplier `m(F) = a(F) (α₀ + b F) = a(F) D(1)/A` to 1.002957. -/
theorem example_curve_numbers :
    let d1 : ℚ := 1 / (105 / 100)
    let d2 := d1 / (1046 / 1000)
    let d3 := d2 / (1043 / 1000)
    let d4 := d3 / (1041 / 1000)
    let d5 := d4 / (1040 / 1000)
    let d6 := d5 / (1039 / 1000)
    let A := d2 + d3 + d4 + d5 + d6
    let F := (d1 - d6) / A
    let b := (d1 / A - 1 / 5) / F
    let aF := ∑ i ∈ range 5, ((1 + F) ^ (i + 1))⁻¹
    |b - 632347 / 10 ^ 6| < 5 / 10 ^ 7 ∧ |aF - 4427700 / 10 ^ 6| < 5 / 10 ^ 7 ∧
      |aF * (1 / 5 + b * F) - 1002957 / 10 ^ 6| < 5 / 10 ^ 7 := by
  intro d1 d2 d3 d4 d5 d6 A F b aF
  simp only [d1, d2, d3, d4, d5, d6, A, F, b, aF, sum_range_succ, sum_range_zero]
  refine ⟨?_, ?_, ?_⟩ <;> rw [abs_sub_lt_iff] <;> constructor <;> norm_num

#print axioms irrAnnuity_at_zero
#print axioms irrAnnuity_pos
#print axioms irrAnnuity_strictAnti
#print axioms hasDerivAt_irrAnnuity
#print axioms payment_strictConvexOn
#print axioms irrAnnuity_strictConvexOn
#print axioms payer_minus_receiver
#print axioms tsr_reprices_bond
#print axioms gap_split
#print axioms no_volatility_no_tilt_or_bend
#print axioms linear_multiplier_tilt
#print axioms example_curve_numbers
