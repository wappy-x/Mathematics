-- Mass gap: in a finite quantum system with a gap, correlations die at least as fast as exp(-gap * time), and their effective mass tends to the gap.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic

open Real Filter Topology

/-- The imaginary-time correlation of the card:
`C(τ) = ∑ₙ |cₙ|² e^{-(Eₙ - E₀) τ}`, where `Eₙ` are the energy levels,
`E 0` is the vacuum energy and `cₙ = ⟨n|𝒪|Ω⟩` are the observable's weights. -/
noncomputable def corr {N : ℕ} (E : Fin (N + 2) → ℝ) (c : Fin (N + 2) → ℂ) (τ : ℝ) : ℝ :=
  ∑ n, ‖c n‖ ^ 2 * Real.exp (-(E n - E 0) * τ)

/-- A gap makes correlations die exponentially. Let the energy levels be
`E₀ < E₁ ≤ E₂ ≤ …` with gap `Δ = E₁ - E₀`, and let the observable have its vacuum
part removed (`c₀ = 0`). Then for every imaginary time `τ ≥ 0`,
`C(τ) ≤ C(0) e^{-Δ τ}`. -/
theorem gap_bounds_correlation {N : ℕ} (E : Fin (N + 2) → ℝ) (hE : Monotone E)
    (hgap : E 0 < E 1) (c : Fin (N + 2) → ℂ) (hc : c 0 = 0) {τ : ℝ} (hτ : 0 ≤ τ) :
    corr E c τ ≤ corr E c 0 * Real.exp (-(E 1 - E 0) * τ) := by
  unfold corr
  rw [Finset.sum_mul]
  apply Finset.sum_le_sum
  intro n _
  simp only [mul_zero, Real.exp_zero, mul_one]
  by_cases hn : n = 0
  · subst hn; simp [hc]
  · have h1 : (1 : Fin (N + 2)) ≤ n := by
      exact Fin.one_le_of_ne_zero hn
    have hEn : E 1 ≤ E n := hE h1
    apply mul_le_mul_of_nonneg_left _ (by positivity)
    apply Real.exp_le_exp.mpr
    nlinarith

/-- Decay gives the gap back. With the same levels, if the observable reaches the
first excited level (`c₁ ≠ 0`), the effective mass `ln(C(τ)/C(τ+1))` tends to the
gap `Δ = E₁ - E₀` as `τ` grows. -/
theorem effective_mass_tendsto_gap {N : ℕ} (E : Fin (N + 2) → ℝ) (hE : Monotone E)
    (hgap : E 0 < E 1) (c : Fin (N + 2) → ℂ) (hc : c 0 = 0) (hc1 : c 1 ≠ 0) :
    Tendsto (fun τ : ℝ => Real.log (corr E c τ / corr E c (τ + 1))) atTop
      (𝓝 (E 1 - E 0)) := by
  set S : ℝ → ℝ := fun τ => ∑ n, ‖c n‖ ^ 2 * Real.exp (-(E n - E 1) * τ) with hS
  set A : ℝ := ∑ n, (if E n = E 1 then ‖c n‖ ^ 2 else 0) with hA
  have hterm : ∀ n : Fin (N + 2), Tendsto (fun τ : ℝ => ‖c n‖ ^ 2 * Real.exp (-(E n - E 1) * τ))
      atTop (𝓝 (if E n = E 1 then ‖c n‖ ^ 2 else 0)) := by
    intro n
    by_cases hn : n = 0
    · subst hn
      have : E 0 ≠ E 1 := ne_of_lt hgap
      simp [hc, this]
    · have h1 : (1 : Fin (N + 2)) ≤ n := by
        exact Fin.one_le_of_ne_zero hn
      have hEn : E 1 ≤ E n := hE h1
      by_cases heq : E n = E 1
      · simp [heq]
      · rw [ite_eq_right_iff.mpr (fun h => absurd h heq)]
        have hlt : 0 < E n - E 1 := by
          rcases lt_or_eq_of_le hEn with h | h
          · linarith
          · exact absurd h.symm heq
        have : Tendsto (fun τ : ℝ => Real.exp (-(E n - E 1) * τ)) atTop (𝓝 0) := by
          have h2 : Tendsto (fun τ : ℝ => -(E n - E 1) * τ) atTop atBot := by
            apply Tendsto.const_mul_atTop_of_neg (by linarith) tendsto_id
          exact Real.tendsto_exp_atBot.comp h2
        simpa using this.const_mul (‖c n‖ ^ 2)
  have hSlim : Tendsto S atTop (𝓝 A) := tendsto_finsetSum _ (fun n _ => hterm n)
  have hSlim1 : Tendsto (fun τ => S (τ + 1)) atTop (𝓝 A) :=
    hSlim.comp (tendsto_atTop_add_const_right _ 1 tendsto_id)
  have hApos : 0 < A := by
    have hle : (if E 1 = E 1 then ‖c 1‖ ^ 2 else 0) ≤ A := by
      apply Finset.single_le_sum (f := fun n => if E n = E 1 then ‖c n‖ ^ 2 else 0)
        (fun n _ => by split_ifs <;> positivity) (Finset.mem_univ 1)
    have : 0 < ‖c 1‖ ^ 2 := by positivity
    simp at hle
    linarith
  have hcorr : ∀ τ, corr E c τ = Real.exp (-(E 1 - E 0) * τ) * S τ := by
    intro τ
    unfold corr
    rw [hS, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro n _
    rw [mul_left_comm, ← Real.exp_add]
    congr 2
    ring
  have hratio : ∀ τ, corr E c τ / corr E c (τ + 1) = Real.exp (E 1 - E 0) * (S τ / S (τ + 1)) := by
    intro τ
    rw [hcorr, hcorr, mul_div_mul_comm, ← Real.exp_sub]
    congr 2
    ring
  have hlim : Tendsto (fun τ => corr E c τ / corr E c (τ + 1)) atTop
      (𝓝 (Real.exp (E 1 - E 0) * (A / A))) := by
    simp_rw [hratio]
    exact (hSlim.div hSlim1 (ne_of_gt hApos)).const_mul _
  rw [div_self (ne_of_gt hApos), mul_one] at hlim
  have := hlim.log (Real.exp_pos _).ne'
  simpa [Real.log_exp] using this

/-- The identity that makes the toy plaquette's matrix tridiagonal in the box basis
`sin(nθ)`: `2 cos θ sin(nθ) = sin((n+1)θ) + sin((n-1)θ)`. -/
theorem two_cos_mul_sin_eq_sin_add_sin (n θ : ℝ) :
    2 * Real.cos θ * Real.sin (n * θ) = Real.sin ((n + 1) * θ) + Real.sin ((n - 1) * θ) := by
  rw [show (n + 1) * θ = n * θ + θ by ring, show (n - 1) * θ = n * θ - θ by ring,
    Real.sin_add, Real.sin_sub]
  ring

-- The spin label j and the box label n = 2j + 1 give j(j+1) = (n² - 1)/4,
-- at j = 0, 1/2, 1 (n = 1, 2, 3).
example : (0 : ℚ) * (0 + 1) = ((2 * 0 + 1) ^ 2 - 1) / 4 := by norm_num
example : (1 / 2 : ℚ) * (1 / 2 + 1) = ((2 * (1 / 2) + 1) ^ 2 - 1) / 4 := by norm_num
example : (1 : ℚ) * (1 + 1) = ((2 * 1 + 1) ^ 2 - 1) / 4 := by norm_num
-- Strong coupling: the step from j = 0 to j = 1/2 is (g²/2)·(3/4) = 3g²/8; at g² = 16 it is 6.
example : (16 : ℚ) / 2 * ((1 / 2) * (1 / 2 + 1)) = 6 := by norm_num
-- Coulomb potential 1/r: from 1 fm to 2 fm it falls by a factor 2.
example : (1 / 1 : ℚ) / (1 / 2) = 2 := by norm_num

#print axioms gap_bounds_correlation
#print axioms effective_mass_tendsto_gap
#print axioms two_cos_mul_sin_eq_sin_add_sin
