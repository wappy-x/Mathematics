-- Optimal filters: a fit whose weighted error alternates with equal peaks is best, the Chebyshev polynomial grows fastest beyond 1, and this gives the Chebyshev order rule.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.Extremal
import Mathlib.Analysis.SpecialFunctions.Arcosh
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Algebra.Polynomial

open Polynomial Polynomial.Chebyshev Real

/-- A real polynomial that changes sign strictly between `a < b` has a root strictly inside. -/
theorem poly_root_of_sign_change (f : ℝ[X]) {a b : ℝ} (hab : a < b)
    (hf : f.eval a * f.eval b < 0) : ∃ c ∈ Set.Ioo a b, f.eval c = 0 := by
  have hcont : ContinuousOn (fun t => f.eval t) (Set.Icc a b) :=
    f.continuous.continuousOn
  rcases lt_or_gt_of_ne (show f.eval a ≠ 0 by rintro h; simp [h] at hf) with ha | ha
  · have hb : 0 < f.eval b := by nlinarith
    obtain ⟨c, hc, hc0⟩ := intermediate_value_Ioo hab.le hcont ⟨ha, hb⟩
    exact ⟨c, hc, hc0⟩
  · have hb : f.eval b < 0 := by nlinarith
    obtain ⟨c, hc, hc0⟩ := intermediate_value_Ioo' hab.le hcont ⟨hb, ha⟩
    exact ⟨c, hc, hc0⟩

#print axioms poly_root_of_sign_change

/-- The alternation theorem, in the direction the card proves. Let `P` be a polynomial of
degree at most `M` in `x = cos ω`, fitted to `target` on the bands `S` with a positive weight
`W`. If the weighted error `W (target - P)` is at most `δ > 0` in size everywhere on `S`, and
equals `+δ, -δ, +δ, …` at `M + 2` points `x₀ > x₁ > … > x_{M+1}` of `S`, then no polynomial
`Q` of degree at most `M` does better: its weighted error reaches size `δ` somewhere on `S`. -/
theorem equiripple_alternation_is_minimax {M : ℕ} (S : Set ℝ) (W target : ℝ → ℝ)
    (hW : ∀ y ∈ S, 0 < W y) (P : ℝ[X]) (hP : P.natDegree ≤ M)
    (x : Fin (M + 2) → ℝ) (hx : StrictAnti x) (hxS : ∀ i, x i ∈ S)
    (δ : ℝ) (hδ : 0 < δ)
    (hmax : ∀ y ∈ S, |W y * (target y - P.eval y)| ≤ δ)
    (halt : ∀ i : Fin (M + 2), W (x i) * (target (x i) - P.eval (x i)) = (-1) ^ (i : ℕ) * δ) :
    ∀ Q : ℝ[X], Q.natDegree ≤ M → ∃ y ∈ S, δ ≤ |W y * (target y - Q.eval y)| := by
  intro Q hQ
  by_contra hcon
  push Not at hcon
  set D : ℝ[X] := P - Q with hDdef
  have hs : ∀ i : Fin (M + 2), (-1 : ℝ) ^ (i : ℕ) * D.eval (x i) < 0 := by
    intro i
    have hq := hcon (x i) (hxS i)
    have hw := hW (x i) (hxS i)
    have e := halt i
    have key : W (x i) * ((-1 : ℝ) ^ (i : ℕ) * D.eval (x i)) =
        (-1 : ℝ) ^ (i : ℕ) * (W (x i) * (target (x i) - Q.eval (x i))) -
        (-1 : ℝ) ^ (i : ℕ) * (W (x i) * (target (x i) - P.eval (x i))) := by
      simp only [hDdef, eval_sub]; ring
    rw [e] at key
    rw [abs_lt] at hq
    by_contra hc
    push Not at hc
    have hnn := mul_nonneg hw.le hc
    rcases neg_one_pow_eq_or ℝ (i : ℕ) with h1 | h1 <;> rw [h1] at key <;> nlinarith
  have hroot : ∀ j : Fin (M + 1), ∃ c ∈ Set.Ioo (x j.succ) (x (Fin.castSucc j)), D.eval c = 0 := by
    intro j
    apply poly_root_of_sign_change D (hx Fin.castSucc_lt_succ)
    have h1 := hs (Fin.castSucc j)
    have h2 := hs j.succ
    simp only [Fin.val_castSucc, Fin.val_succ] at h1 h2
    rcases neg_one_pow_eq_or ℝ (j : ℕ) with h | h <;>
      simp only [pow_succ, h] at h1 h2 <;> nlinarith
  choose c hc hc0 using hroot
  have hcanti : StrictAnti c := by
    intro j k hjk
    have hle : j.succ ≤ Fin.castSucc k := by
      rw [Fin.le_def]; simp only [Fin.val_succ, Fin.val_castSucc]; exact hjk
    have := hx.antitone hle
    exact lt_trans (lt_of_lt_of_le (hc k).2 this) (hc j).1
  have hD0 : D = 0 := by
    apply eq_zero_of_natDegree_lt_card_of_eval_eq_zero D hcanti.injective hc0
    rw [Fintype.card_fin]
    show (P - Q).natDegree < M + 1
    have := natDegree_sub_le P Q
    omega
  have h0 := hs 0
  rw [hD0] at h0
  simp at h0

/-- Nothing bounded by one on [-1, 1] grows faster than the Chebyshev polynomial: if `p` has
degree at most `N` and `|p| ≤ 1` on `[-1, 1]`, then `p(x₀) ≤ T_N(x₀)` at every `x₀ > 1`. -/
theorem chebyshev_grows_fastest_beyond_one {N : ℕ} (p : ℝ[X]) (hp : p.natDegree ≤ N)
    (hbound : ∀ x ∈ Set.Icc (-1 : ℝ) 1, |p.eval x| ≤ 1) {x₀ : ℝ} (hx₀ : 1 < x₀) :
    p.eval x₀ ≤ (T ℝ N).eval x₀ := by
  have := eval_iterate_derivative_le_of_forall_abs_le_one (k := 0) hx₀.le
    (degree_le_of_natDegree_le hp) hbound
  simpa using this

/-- The Chebyshev type I order rule. With ripple size `ε > 0`, stopband cut `A` dB,
discrimination `D = √(10^(A/10) - 1) / ε ≥ 1` and warped edge ratio `r > 1`, an order-`N`
Chebyshev filter meets the stopband at its edge, `1 + ε² T_N(r)² ≥ 10^(A/10)`, exactly when
`N ≥ arcosh D / arcosh r`. -/
theorem chebyshev_order_rule (N : ℕ) {ε A D r : ℝ} (hε : 0 < ε)
    (hD : D = Real.sqrt ((10 : ℝ) ^ (A / 10) - 1) / ε) (hD1 : 1 ≤ D) (hr : 1 < r) :
    (10 : ℝ) ^ (A / 10) ≤ 1 + ε ^ 2 * ((T ℝ N).eval r) ^ 2 ↔ arcosh D / arcosh r ≤ N := by
  set K : ℝ := (10 : ℝ) ^ (A / 10) with hKdef
  have hsq : ε ≤ Real.sqrt (K - 1) := by
    rw [hD, le_div_iff₀ hε] at hD1; linarith
  have hK : 0 < K - 1 := Real.sqrt_pos.mp (lt_of_lt_of_le hε hsq)
  have hD2 : D ^ 2 * ε ^ 2 = K - 1 := by
    rw [hD, div_pow, Real.sq_sqrt hK.le]; field_simp
  set θ := arcosh r with hθdef
  have hθ : 0 < θ := arcosh_pos hr
  have hTr : (T ℝ N).eval r = cosh (N * θ) := by
    conv_lhs => rw [← cosh_arcosh hr.le]
    rw [T_real_cosh]; push_cast; rfl
  rw [hTr]
  have hNθ : 0 ≤ (N : ℝ) * θ := by positivity
  have hc1 : 1 ≤ cosh ((N : ℝ) * θ) := one_le_cosh _
  have hε2 : 0 < ε ^ 2 := by positivity
  have hD0 : 0 < D := by linarith
  calc K ≤ 1 + ε ^ 2 * cosh ((N : ℝ) * θ) ^ 2
        ↔ D ^ 2 ≤ cosh ((N : ℝ) * θ) ^ 2 := by
          constructor
          · intro h; nlinarith
          · intro h; nlinarith
    _ ↔ D ≤ cosh ((N : ℝ) * θ) := pow_le_pow_iff_left₀ hD0.le (by linarith) two_ne_zero
    _ ↔ arcosh D ≤ arcosh (cosh ((N : ℝ) * θ)) :=
          (arcosh_le_arcosh hD0 (by linarith)).symm
    _ ↔ arcosh D ≤ (N : ℝ) * θ := by rw [arcosh_cosh hNθ]
    _ ↔ arcosh D / θ ≤ N := by rw [div_le_iff₀ hθ]

-- A symmetric FIR's gain is a polynomial in x = cos ω: cos 2ω = 2x² - 1 is T₂.
example : (T ℝ 2 : ℝ[X]) = 2 * X ^ 2 - 1 := by norm_num [T_two]

-- Multiplies per reading, 2N + 1: Butterworth order 5, Chebyshev order 4, elliptic order 3.
example : 2 * 5 + 1 = 11 ∧ 2 * 4 + 1 = 9 ∧ 2 * 3 + 1 = 7 := by decide

-- 37 taps: M = (37 - 1)/2 = 18, so the certificate needs M + 2 = 20 alternations.
example : (37 - 1) / 2 = 18 ∧ (37 - 1) / 2 + 2 = 20 := by decide

-- 36 taps: a polynomial of degree 36/2 - 1 = 17, so 17 + 2 = 19 alternations.
example : 36 / 2 - 1 = 17 ∧ 36 / 2 - 1 + 2 = 19 := by decide

#print axioms equiripple_alternation_is_minimax
#print axioms chebyshev_grows_fastest_beyond_one
#print axioms chebyshev_order_rule
