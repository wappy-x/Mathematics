-- Burgard-Kjaer: with one funding spread the funding term is linear and the adjustment's source splits into CVA, DVA, FCA and FBA pieces, each a rate times the clean price times the expected years both firms survive; with borrowing dearer than lending the funding term is kinked, so netting two trades costs less than funding them apart.
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real intervalIntegral

/-- The funding term `s_b U⁺ - s_l U⁻` of the Burgard-Kjaer equation.
With one spread (`s_b = s_l`) it is the straight line `s_b U`, so the equation is linear.
With borrowing dearer than lending (`s_l < s_b`) it has a kink at zero: the funding cost of two
positions held together is never more than the sum of their separate costs, and for some pairs
(a position the bank borrows for, plus one that brings in cash) it is strictly less, so
superposition fails and a portfolio's price is not the sum of its trades' prices. -/
theorem funding_term_linear_with_one_spread_subadditive_with_kink (sb sl : ℝ) :
    (sb = sl → ∀ x : ℝ, sb * x⁺ - sl * x⁻ = sb * x) ∧
    (sl < sb →
      (∀ x y : ℝ, sb * (x + y)⁺ - sl * (x + y)⁻ ≤ (sb * x⁺ - sl * x⁻) + (sb * y⁺ - sl * y⁻)) ∧
      ∃ x y : ℝ, sb * (x + y)⁺ - sl * (x + y)⁻ < (sb * x⁺ - sl * x⁻) + (sb * y⁺ - sl * y⁻)) := by
  have key : ∀ z : ℝ, z⁺ - z⁻ = z := fun z => posPart_sub_negPart z
  refine ⟨fun h x => ?_, fun h => ⟨fun x y => ?_, ⟨1, -1, ?_⟩⟩⟩
  · subst h
    have := key x
    linear_combination sb * this
  · have hpos : ∀ z : ℝ, 0 ≤ z⁺ := fun z => posPart_nonneg z
    have hle : ∀ z : ℝ, z ≤ z⁺ := fun z => le_posPart z
    have hsub : (x + y)⁺ ≤ x⁺ + y⁺ := by
      rcases le_total 0 (x + y) with hxy | hxy
      · rw [posPart_eq_self.mpr hxy]; linarith [hle x, hle y]
      · rw [posPart_eq_zero.mpr hxy]; linarith [hpos x, hpos y]
    have e1 := key (x + y)
    have e2 := key x
    have e3 := key y
    have n1 : (x + y)⁻ = (x + y)⁺ - (x + y) := by linarith [e1]
    have n2 : x⁻ = x⁺ - x := by linarith [e2]
    have n3 : y⁻ = y⁺ - y := by linarith [e3]
    rw [n1, n2, n3]
    nlinarith [mul_le_mul_of_nonneg_left hsub (le_of_lt (sub_pos.mpr h))]
  · have h1 : (1 : ℝ) + -1 = 0 := by norm_num
    rw [h1]
    simp
    linarith

/-- Step 4's split. Write the all-in value as `U = V - X`, with closeout amounts
`g_C = R_C V⁺ - V⁻` and `g_O = V⁺ - R_O V⁻`, and the spread `s` charged on the clean value `V`.
Then the right side of the equation is the CVA, DVA, FCA and FBA source
`h = (1 - R_C) λ_C V⁺ - (1 - R_O) λ_O V⁻ + s V⁺ - s V⁻`, minus both hazards times the
adjustment `X` (which becomes the extra discount rate `λ_C + λ_O`). -/
theorem adjustment_source_splits_into_cva_dva_fca_fba
    (V X U gC gO lamC lamO RC RO s : ℝ)
    (hU : U = V - X) (hgC : gC = RC * V⁺ - V⁻) (hgO : gO = V⁺ - RO * V⁻) :
    lamC * (U - gC) + lamO * (U - gO) + s * V
      = ((1 - RC) * lamC * V⁺ - (1 - RO) * lamO * V⁻ + s * V⁺ - s * V⁻)
        - (lamC + lamO) * X := by
  subst hU hgC hgO
  have := posPart_sub_negPart V
  linear_combination (-(lamC + lamO + s)) * this

/-- For a bought option the discounted exposure `E[D(t) V⁺]` equals the clean price `C₀` at every
date, so each piece `c ∫₀ᵀ W(t) E[D(t) V⁺] dt`, with both-alive weight `W(t) = e^{-λ t}`, is the
rate `c` times `C₀` times the expected years alive `A(λ) = (1 - e^{-λ T}) / λ`. -/
theorem bought_option_piece_eq_rate_mul_price_mul_years_alive
    (c C0 lam T : ℝ) (hlam : 0 < lam) :
    ∫ t in (0 : ℝ)..T, Real.exp (-lam * t) * (c * C0)
      = c * C0 * ((1 - Real.exp (-lam * T)) / lam) := by
  have hderiv : ∀ x ∈ Set.uIcc (0:ℝ) T,
      HasDerivAt (fun t => -(Real.exp (-lam * t)) / lam * (c * C0))
        (Real.exp (-lam * x) * (c * C0)) x := by
    intro x _
    have h1 : HasDerivAt (fun t => -lam * t) (-lam) x := by
      simpa using (hasDerivAt_id x).const_mul (-lam)
    have h2 := (h1.exp).neg.div_const lam |>.mul_const (c * C0)
    convert h2 using 1
    field_simp
  rw [integral_eq_sub_of_hasDerivAt hderiv (by
    apply Continuous.intervalIntegrable; fun_prop)]
  simp only [mul_zero, Real.exp_zero]
  field_simp
  ring

#print axioms funding_term_linear_with_one_spread_subadditive_with_kink
#print axioms adjustment_source_splits_into_cva_dva_fca_fba
#print axioms bought_option_piece_eq_rate_mul_price_mul_years_alive
