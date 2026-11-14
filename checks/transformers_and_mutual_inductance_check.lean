-- Transformers: when two coils share one changing flux, voltage divides by the turns ratio, current multiplies by it, and the load is seen scaled by its square.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Complex

/-- The ideal transformer rule. Every turn of both coils links the same flux, whose rate of
change has phasor `dΦ`, so `V₁ = N₁ dΦ` and `V₂ = N₂ dΦ`. With no net magnetising
ampere-turns (`N₁ I₁ = N₂ I₂`) and a load `V₂ = Z_L I₂`, as long as the flux is changing:
the voltage ratio is `N₁/N₂`, the current ratio is `N₂/N₁`, and the input impedance
`V₁/I₁` is `(N₁/N₂)² Z_L`. -/
theorem ideal_transformer_ratios (N₁ N₂ : ℕ) (dΦ V₁ V₂ I₁ I₂ Z_L : ℂ)
    (hN₁ : 0 < N₁) (hN₂ : 0 < N₂) (hΦ : dΦ ≠ 0)
    (hV₁ : V₁ = N₁ * dΦ) (hV₂ : V₂ = N₂ * dΦ)
    (hI : (N₁ : ℂ) * I₁ = N₂ * I₂)
    (hload : V₂ = Z_L * I₂) :
    V₁ / V₂ = (N₁ : ℂ) / N₂ ∧ I₁ / I₂ = (N₂ : ℂ) / N₁ ∧
      V₁ / I₁ = ((N₁ : ℂ) / N₂) ^ 2 * Z_L := by
  have h1 : (N₁ : ℂ) ≠ 0 := by exact_mod_cast hN₁.ne'
  have h2 : (N₂ : ℂ) ≠ 0 := by exact_mod_cast hN₂.ne'
  have hV2 : V₂ ≠ 0 := by rw [hV₂]; exact mul_ne_zero h2 hΦ
  have hI2 : I₂ ≠ 0 := by
    intro h; apply hV2; rw [hload, h, mul_zero]
  have hI1 : I₁ ≠ 0 := by
    intro h; rw [h, mul_zero] at hI
    exact mul_ne_zero h2 hI2 hI.symm
  refine ⟨?_, ?_, ?_⟩
  · rw [hV₁, hV₂]; field_simp
  · rw [div_eq_div_iff hI2 h1]; linear_combination hI
  · rw [div_eq_iff hI1]
    have hZ : Z_L = N₂ * dΦ / I₂ := by rw [eq_div_iff hI2, ← hV₂, hload]
    have hI1' : I₁ = N₂ * I₂ / N₁ := by rw [eq_div_iff h1, ← hI]; ring
    rw [hZ, hV₁, hI1']
    field_simp

/-- The voltage rule holds at every instant, for any wave shape: if each turn of both coils
sees the same flux `Φ(t)`, so `v₁ = N₁ Φ'` and `v₂ = N₂ Φ'`, then at any instant where the
flux is changing, `v₁/v₂ = N₁/N₂`. -/
theorem voltage_ratio_every_instant (N₁ N₂ : ℕ) (Φ v₁ v₂ : ℝ → ℝ)
    (hv₁ : ∀ t, v₁ t = N₁ * deriv Φ t) (hv₂ : ∀ t, v₂ t = N₂ * deriv Φ t)
    (t : ℝ) (ht : deriv Φ t ≠ 0) :
    v₁ t / v₂ t = (N₁ : ℝ) / N₂ := by
  rw [hv₁, hv₂, mul_div_mul_right _ _ ht]

/-- Coupled coils with perfect coupling (`k = 1`, so `M = √(L₁ L₂)`) and `L₂ = L₁/n²`.
With `V₁ = jωL₁ I₁ − jωM I₂`, `V₂ = jωM I₁ − jωL₂ I₂` and the load `V₂ = Z_L I₂`:
the secondary voltage is exactly `V₁/n` whatever `L₁` is, and the input impedance is
`jωL₁ + (ωM)²/(Z_L + jωL₂)`, which equals `n² Z_L` in parallel with `jωL₁`. -/
theorem coupled_coils_perfect_coupling (ω L₁ L₂ M n : ℝ) (V₁ V₂ I₁ I₂ Z_L : ℂ)
    (hω : 0 < ω) (hL₁ : 0 < L₁) (hn : 0 < n)
    (hL₂ : L₂ = L₁ / n ^ 2) (hM : M = Real.sqrt (L₁ * L₂))
    (h₁ : V₁ = I * ω * L₁ * I₁ - I * ω * M * I₂)
    (h₂ : V₂ = I * ω * M * I₁ - I * ω * L₂ * I₂)
    (hload : V₂ = Z_L * I₂) (hI₁ : I₁ ≠ 0) :
    V₂ = V₁ / n ∧
      V₁ / I₁ = I * ω * L₁ + ((ω * M : ℝ) : ℂ) ^ 2 / (Z_L + I * ω * L₂) ∧
      V₁ / I₁ = (I * ω * L₁) * ((n : ℂ) ^ 2 * Z_L) / ((n : ℂ) ^ 2 * Z_L + I * ω * L₁) := by
  have hMr : M = L₁ / n := by
    rw [hM, hL₂, show L₁ * (L₁ / n ^ 2) = (L₁ / n) ^ 2 by ring]
    exact Real.sqrt_sq (div_pos hL₁ hn).le
  have hnc : (n : ℂ) ≠ 0 := by exact_mod_cast hn.ne'
  have hωc : (ω : ℂ) ≠ 0 := by exact_mod_cast hω.ne'
  have hL1c : (L₁ : ℂ) ≠ 0 := by exact_mod_cast hL₁.ne'
  have hMc : (M : ℂ) = L₁ / n := by rw [hMr]; push_cast; rfl
  have hL2c : (L₂ : ℂ) = L₁ / n ^ 2 := by rw [hL₂]; push_cast; rfl
  have hD : Z_L + I * ω * L₂ ≠ 0 := by
    intro hD
    have : I * ω * M * I₁ = 0 := by linear_combination -h₂ + hload + I₂ * hD
    rw [hMc] at this
    simp [hnc, hωc, hL1c, hI₁, I_ne_zero] at this
  have hI2 : I₂ = I * ω * M * I₁ / (Z_L + I * ω * L₂) := by
    rw [eq_div_iff hD]; linear_combination -(hload) + h₂
  have hD2 : (n : ℂ) ^ 2 * Z_L + I * ω * L₁ ≠ 0 := by
    have : (n : ℂ) ^ 2 * Z_L + I * ω * L₁ = n ^ 2 * (Z_L + I * ω * L₂) := by
      rw [hL2c]; field_simp
    rw [this]; exact mul_ne_zero (pow_ne_zero _ hnc) hD
  refine ⟨?_, ?_, ?_⟩
  · rw [eq_div_iff hnc, h₁, h₂, hMc, hL2c]; field_simp
  · rw [div_eq_iff hI₁, h₁, hI2]
    push_cast
    field_simp
    ring_nf
    rw [I_sq]
    ring
  · rw [div_eq_iff hI₁, h₁, hI2, hMc]
    rw [hL2c] at hD ⊢
    field_simp
    ring_nf

-- The doorbell: 230 V on 1,150 turns gives 12 V on 60 turns.
example : (230 : ℚ) * 60 / 1150 = 12 := by norm_num
-- 5 turns per volt, so 0.2 V per turn.
example : (1150 : ℚ) / 230 = 5 ∧ (230 : ℚ) / 1150 = 1 / 5 := by norm_num
-- The chime's impedance 6 + 8j has size 10, so it draws 12/10 = 1.2 A.
example : (6 : ℕ) ^ 2 + 8 ^ 2 = 10 ^ 2 := by decide
example : (12 : ℚ) / 10 = 6 / 5 := by norm_num
-- Chime power 1.2² × 6 = 8.64 W and volt-amperes 12 × 1.2 = 14.4 VA.
example : ((6 : ℚ) / 5) ^ 2 * 6 = 216 / 25 ∧ (12 : ℚ) * (6 / 5) = 72 / 5 := by norm_num
-- Ideal primary current 1.2 × 60/1150 A, and 230 V times it is again 14.4 VA.
example : (6 : ℚ) / 5 * 60 / 1150 = 36 / 575 ∧ (230 : ℚ) * (36 / 575) = 72 / 5 := by norm_num
-- Ideal input impedance n² Z_L with n = 1150/60: (13225/36)(6 + 8j) = 13225/6 + (26450/9) j.
example : ((1150 : ℂ) / 60) ^ 2 * (6 + 8 * I) = 13225 / 6 + 26450 / 9 * I := by
  apply Complex.ext <;> simp <;> norm_num
-- Its size: (13225/36) × 10 = 66125/18 Ω (about 3,673.61 Ω).
example : (1150 / 60 : ℚ) ^ 2 * 10 = 66125 / 18 := by norm_num
-- Mistakes: ratio upside down gives 230 × 1150/60 V; reflecting by n gives 10 × 1150/60 Ω;
-- I₁ = n I₂ gives 23 A and 230 × 23 = 5,290 VA.
example : (230 : ℚ) * (1150 / 60) = 13225 / 3 ∧ (10 : ℚ) * (1150 / 60) = 575 / 3 ∧
    (1150 : ℚ) / 60 * (6 / 5) = 23 ∧ (230 : ℚ) * 23 = 5290 := by norm_num

#print axioms ideal_transformer_ratios
#print axioms voltage_ratio_every_instant
#print axioms coupled_coils_perfect_coupling
