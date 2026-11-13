-- GARCH: inside the GARCH(1,1) model, the k-day variance forecast is the long-run level ω/(1 − α − β) plus (α + β)^(k−1) times tomorrow's gap from it, the average variance settles at that level, and the squares' autocorrelations are ρ₁ then (α + β)^(k−1) ρ₁.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.Probability.Process.Filtration
import Mathlib.Analysis.SpecificLimits.Basic

open MeasureTheory Filter Topology

/-- **The forecast is pulled home geometrically (Step 3).** Day `s`'s return is `r s`; the
information known at the close of day `s` is `ℱ s`. The variance `h (s+1)` of the next return
is the expected squared move given everything known up to day `s`, and tomorrow's variance
follows the GARCH(1,1) rule `h (s+1) = ω + α r_s² + β h_s`. With a positive constant,
non-negative weights and persistence `φ = α + β` below 1, the forecast made at the close of
day `t` for the variance `k ≥ 1` days ahead is
`E[h (t+k) | day t] = h̄ + φ^(k−1) (h (t+1) − h̄)`, where `h̄ = ω / (1 − φ)` is the long-run
variance. -/
theorem garch_variance_forecast {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω}
    [IsProbabilityMeasure μ] (ℱ : Filtration ℕ m0)
    (ω α β : ℝ) (hω : 0 < ω) (hα : 0 ≤ α) (hβ : 0 ≤ β) (hφ : α + β < 1)
    (r h : ℕ → Ω → ℝ)
    (hr : ∀ s, Integrable (fun x => r s x ^ 2) μ)
    (hcond : ∀ s, μ[fun x => r (s + 1) x ^ 2 | ℱ s] =ᵐ[μ] h (s + 1))
    (hrule : ∀ s x, h (s + 1) x = ω + α * r s x ^ 2 + β * h s x)
    (t k : ℕ) (hk : 1 ≤ k) :
    μ[h (t + k) | ℱ t] =ᵐ[μ]
      fun x => ω / (1 - (α + β)) + (α + β) ^ (k - 1) * (h (t + 1) x - ω / (1 - (α + β))) := by
  have hne : (1 - (α + β)) ≠ 0 := by linarith
  have hint : ∀ s, Integrable (h (s + 1)) μ := fun s => integrable_condExp.congr (hcond s)
  have key : ∀ i, μ[fun x => r (t + i + 1) x ^ 2 | ℱ t] =ᵐ[μ] μ[h (t + i + 1) | ℱ t] := by
    intro i
    have hle : ℱ t ≤ ℱ (t + i) := ℱ.mono (by omega)
    exact (condExp_condExp_of_le hle (ℱ.le (t + i))).symm.trans (condExp_congr_ae (hcond (t + i)))
  have P : ∀ i, μ[h (t + i + 1) | ℱ t] =ᵐ[μ]
      fun x => ω / (1 - (α + β)) + (α + β) ^ i * (h (t + 1) x - ω / (1 - (α + β))) := by
    intro i
    induction i with
    | zero =>
      have e1 : μ[h (t + 0 + 1) | ℱ t] =ᵐ[μ] μ[μ[fun x => r (t + 1) x ^ 2 | ℱ t] | ℱ t] :=
        condExp_congr_ae (hcond t).symm
      rw [condExp_of_stronglyMeasurable (ℱ.le t) stronglyMeasurable_condExp integrable_condExp] at e1
      refine (e1.trans (hcond t)).mono fun x hx => ?_
      rw [hx]; simp
    | succ i ih =>
      have hfun : h (t + (i + 1) + 1) = (fun _ => ω) +
          (α • (fun x => r (t + i + 1) x ^ 2) + β • h (t + i + 1)) := by
        funext x
        rw [show t + (i + 1) + 1 = (t + i + 1) + 1 by omega, hrule]
        simp [smul_eq_mul]; ring
      rw [hfun]
      have e1 := condExp_add (integrable_const ω)
        (((hr (t + i + 1)).smul α).add ((hint (t + i)).smul β)) (ℱ t)
      have e2 := condExp_add ((hr (t + i + 1)).smul α) ((hint (t + i)).smul β) (ℱ t) (μ := μ)
      have e3 := condExp_smul (μ := μ) α (fun x => r (t + i + 1) x ^ 2) (ℱ t)
      have e4 := condExp_smul (μ := μ) β (h (t + i + 1)) (ℱ t)
      rw [condExp_const (ℱ.le t)] at e1
      filter_upwards [e1, e2, e3, e4, key i, ih] with x h1 h2 h3 h4 h5 h6
      rw [h1, Pi.add_apply, h2, Pi.add_apply, h3, h4, Pi.smul_apply, Pi.smul_apply, h5, h6,
        smul_eq_mul, smul_eq_mul]
      field_simp
      ring
  obtain ⟨i, rfl⟩ : ∃ i, k = i + 1 := ⟨k - 1, by omega⟩
  simpa [← add_assoc] using P i

/-- **The variance has a long-run level (Step 2).** In the same model, with a positive
constant, non-negative weights and persistence `α + β` below 1, the average variance
`E[h s]` over all histories settles, as `s` grows, at the long-run level
`h̄ = ω / (1 − (α + β))`. -/
theorem garch_long_run_variance {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω}
    [IsProbabilityMeasure μ] (ℱ : Filtration ℕ m0)
    (ω α β : ℝ) (hω : 0 < ω) (hα : 0 ≤ α) (hβ : 0 ≤ β) (hφ : α + β < 1)
    (r h : ℕ → Ω → ℝ)
    (hr : ∀ s, Integrable (fun x => r s x ^ 2) μ)
    (hcond : ∀ s, μ[fun x => r (s + 1) x ^ 2 | ℱ s] =ᵐ[μ] h (s + 1))
    (hrule : ∀ s x, h (s + 1) x = ω + α * r s x ^ 2 + β * h s x) :
    Tendsto (fun s => ∫ x, h s x ∂μ) atTop (𝓝 (ω / (1 - (α + β)))) := by
  have hne : (1 - (α + β)) ≠ 0 := by linarith
  have hint : ∀ s, Integrable (h (s + 1)) μ := fun s => integrable_condExp.congr (hcond s)
  have hI : ∀ s, ∫ x, h (s + 1) x ∂μ = ∫ x, r (s + 1) x ^ 2 ∂μ := by
    intro s
    rw [← integral_congr_ae (hcond s), integral_condExp (ℱ.le s)]
  have hrec : ∀ n, ∫ x, h (n + 2) x ∂μ = ω + (α + β) * ∫ x, h (n + 1) x ∂μ := by
    intro n
    have : (fun x => h (n + 2) x) = fun x => (ω + α * r (n + 1) x ^ 2) + β * h (n + 1) x :=
      funext fun x => hrule (n + 1) x
    have i1 : Integrable (fun x => ω + α * r (n + 1) x ^ 2) μ :=
      (integrable_const ω).add ((hr (n + 1)).const_mul α)
    have i2 : Integrable (fun x => β * h (n + 1) x) μ := (hint n).const_mul β
    have i3 : Integrable (fun x => α * r (n + 1) x ^ 2) μ := (hr (n + 1)).const_mul α
    rw [this, integral_add i1 i2, integral_add (integrable_const ω) i3,
      integral_const_mul, integral_const_mul, ← hI n]
    simp; ring
  set c := ω / (1 - (α + β))
  have hform : ∀ n, ∫ x, h (n + 1) x ∂μ = c + (α + β) ^ n * (∫ x, h 1 x ∂μ - c) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [hrec n, ih, pow_succ]
      simp only [c]
      field_simp
      ring
  rw [← tendsto_add_atTop_iff_nat 1]
  refine Tendsto.congr (fun n => (hform n).symm) ?_
  have hp : Tendsto (fun n : ℕ => (α + β) ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (by linarith) hφ
  simpa using (hp.mul_const (∫ x, h 1 x ∂μ - c)).const_add c

/-- **The autocorrelation of the squares (Step 4, detailed proof).** Let `φ = α + β`, with
non-negative weights and the finite-fourth-moment condition `3α² + 2αβ + β² < 1`. Let the
surprises have variance `s > 0`, and let `g k` be the covariance of the centred squares `k`
days apart. If the variance obeys `g 0 = φ² g 0 + s + β² s − 2φβ s`, lag one obeys
`g 1 = φ g 0 − β s`, and each later lag is `φ` times the one before, then for every `k ≥ 1`
the autocorrelation is `ρ_k = g k / g 0 = φ^(k−1) ρ₁` with
`ρ₁ = α (1 − αβ − β²) / (1 − 2αβ − β²)`. -/
theorem garch_squares_autocorrelation (α β s : ℝ) (hα : 0 ≤ α) (hβ : 0 ≤ β)
    (h4 : 3 * α ^ 2 + 2 * α * β + β ^ 2 < 1) (hs : 0 < s) (g : ℕ → ℝ)
    (hg0 : g 0 = (α + β) ^ 2 * g 0 + s + β ^ 2 * s - 2 * (α + β) * β * s)
    (hg1 : g 1 = (α + β) * g 0 - β * s)
    (hgk : ∀ k, 1 ≤ k → g (k + 1) = (α + β) * g k) :
    ∀ k, 1 ≤ k → g k / g 0
      = (α + β) ^ (k - 1) * (α * (1 - α * β - β ^ 2) / (1 - 2 * α * β - β ^ 2)) := by
  have hA : 0 < 1 - (α + β) ^ 2 := by nlinarith [sq_nonneg α]
  have hD : 0 < 1 - 2 * α * β - β ^ 2 := by nlinarith [sq_nonneg α, mul_nonneg hα hβ]
  have hG : g 0 = s * (1 - 2 * α * β - β ^ 2) / (1 - (α + β) ^ 2) := by
    field_simp; linarith
  have hG0 : g 0 ≠ 0 := by rw [hG]; positivity
  have hpow : ∀ i, g (i + 1) = (α + β) ^ i * g 1 := by
    intro i
    induction i with
    | zero => simp
    | succ i ih => rw [hgk (i + 1) (by omega), ih, pow_succ]; ring
  intro k hk
  obtain ⟨i, rfl⟩ : ∃ i, k = i + 1 := ⟨k - 1, by omega⟩
  rw [hpow, Nat.add_sub_cancel, hg1, mul_div_assoc]
  congr 1
  rw [hG]
  field_simp
  ring

-- Worked numbers, by hand, with the true rule ω = 0.05, α = 0.08, β = 0.90.
-- Long-run variance: 0.05 / (1 − 0.08 − 0.90) = 2.5.
example : (5 / 100 : ℚ) / (1 - 8 / 100 - 90 / 100) = 5 / 2 := by norm_num
-- The storm day's square: (−6) × (−6) = 36.
example : (-6 : ℤ) * (-6) = 36 := by norm_num
-- Tomorrow's variance: 0.05 + 0.08 × 36 + 0.90 × 2.5 = 5.18.
example : (5 / 100 : ℚ) + 8 / 100 * 36 + 90 / 100 * (5 / 2) = 518 / 100 := by norm_num
-- Persistence: 0.08 + 0.90 = 0.98.
example : (8 / 100 : ℚ) + 90 / 100 = 98 / 100 := by norm_num
-- Ten days ahead: 2.5 + 0.98^9 × (5.18 − 2.5) lies between 4.7343 and 4.7345 (card: 4.7344).
example : (47343 / 10000 : ℚ) < 5 / 2 + (98 / 100) ^ 9 * (518 / 100 - 5 / 2) ∧
    5 / 2 + (98 / 100 : ℚ) ^ 9 * (518 / 100 - 5 / 2) < 47345 / 10000 := by norm_num
-- The true settings meet the finite-fourth-moment condition, narrowly: 3α² + 2αβ + β² = 0.9732 < 1.
example : 3 * (8 / 100 : ℚ) ^ 2 + 2 * (8 / 100) * (90 / 100) + (90 / 100) ^ 2 = 9732 / 10000 := by
  norm_num

#print axioms garch_variance_forecast
#print axioms garch_long_run_variance
#print axioms garch_squares_autocorrelation
