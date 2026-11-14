-- CDS risk numbers: in the flat-hazard CDS model, with the hazard re-implied from the quote at every bump, CS01 at par equals the notional times the risky annuity, the recovery and rate sensitivities at par are zero, and on a flat curve the par spread is the same for every whole number of quarters, so roll-down is zero.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Finset Filter


/-- Helper: the flat-hazard risky annuity is positive. -/
theorem cds_annuity_pos (c δ : ℝ) (n : ℕ) (hn : 1 ≤ n) (hδ : 0 < δ) :
    0 < ∑ j ∈ Icc 1 n, δ * Real.exp (-c * (j * δ)) := by
  apply Finset.sum_pos
  · intro j _
    positivity
  · exact ⟨1, Finset.mem_Icc.mpr ⟨le_refl 1, hn⟩⟩

/-- Helper: geometric sum over `1, …, k`. -/
theorem cds_geom_Icc (q : ℝ) (k : ℕ) :
    (∑ j ∈ Icc 1 k, q ^ j) * (q - 1) = q ^ (k + 1) - q := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), add_mul, ih]
    ring

/-- Helper: the annuity as a geometric sum in `q = e^{-c δ}`. -/
theorem cds_annuity_geom (c δ : ℝ) (k : ℕ) :
    ∑ j ∈ Icc 1 k, δ * Real.exp (-c * (j * δ)) =
      δ * ∑ j ∈ Icc 1 k, Real.exp (-c * δ) ^ j := by
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [← Real.exp_nat_mul]
  congr 2
  ring

/-- CS01 at par is the notional times the risky annuity.
Flat-hazard model: premiums every `δ > 0` years at `t_j = j δ` for `j = 1, …, n` (`n ≥ 1`),
maturity `T = n δ`, riskless rate `r`, recovery `R`, flat hazard `λ`, combined rate `k = r + λ`.
The risky annuity is `A(λ) = ∑ δ e^{-k t_j}` and the protection leg is
`P(λ) = (1 - R) λ (1 - e^{-k T}) / k`; the par spread is `P / A`.
The desk turns each quoted spread `s` into a hazard `h s` with `P(h s) / A(h s) = s`
(for every quote near `s₀`), and the re-implied hazard moves continuously with the quote.
A position of notional `N` bought at the contract spread `s₀` is worth
`V(s) = N (P(h s) - s₀ A(h s))` when the market quotes `s`.
Then at par (market quote `= s₀`) the slope `dV/ds` is exactly `N × A(h s₀)`. -/
theorem cs01_at_par_eq_notional_mul_annuity
    (N r R δ s₀ : ℝ) (n : ℕ) (hn : 1 ≤ n) (hδ : 0 < δ)
    (A : ℝ → ℝ) (P : ℝ → ℝ)
    (hA : ∀ lam, A lam = ∑ j ∈ Icc 1 n, δ * Real.exp (-(r + lam) * (j * δ)))
    (hP : ∀ lam, P lam = (1 - R) * lam * (1 - Real.exp (-(r + lam) * (n * δ))) / (r + lam))
    (h : ℝ → ℝ) (hpar : ∀ᶠ s in nhds s₀, P (h s) / A (h s) = s)
    (hcont : ContinuousAt h s₀) :
    HasDerivAt (fun s => N * (P (h s) - s₀ * A (h s))) (N * A (h s₀)) s₀ := by
  have hApos : ∀ lam, 0 < A lam := fun lam => by
    rw [hA lam]; exact cds_annuity_pos (r + lam) δ n hn hδ
  have hAc : Continuous A := by
    have : A = fun lam => ∑ j ∈ Icc 1 n, δ * Real.exp (-(r + lam) * (j * δ)) := funext hA
    rw [this]; fun_prop
  have hAh : ContinuousAt (fun s => A (h s)) s₀ := hAc.continuousAt.comp hcont
  have heq : (fun s => N * (P (h s) - s₀ * A (h s))) =ᶠ[nhds s₀]
      fun s => N * ((s - s₀) * A (h s)) := by
    filter_upwards [hpar] with s hs
    have hne := (hApos (h s)).ne'
    rw [div_eq_iff hne] at hs
    rw [hs]; ring
  have hd : HasDerivAt (fun s => (s - s₀) * A (h s)) (A (h s₀)) s₀ := by
    rw [hasDerivAt_iff_tendsto_slope]
    have : Tendsto (fun s => A (h s)) (nhdsWithin s₀ {s₀}ᶜ) (nhds (A (h s₀))) :=
      hAh.tendsto.mono_left nhdsWithin_le_nhds
    refine this.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with s hs
    have hs' : s - s₀ ≠ 0 := sub_ne_zero.mpr hs
    rw [slope_def_field]
    field_simp
    ring
  exact (hd.const_mul N).congr_of_eventuallyEq heq

/-- Recovery sensitivity (Rec01) and rate sensitivity (IR01) are zero at par.
Same flat-hazard model, now with the annuity `A(r, λ) = ∑ δ e^{-(r+λ) t_j}` and the protection
leg `P(r, λ, R) = (1 - R) λ (1 - e^{-(r+λ) T}) / (r + λ)` written as functions of the rate and
recovery too. The market's quote is held at the contract spread `s₀` (the trade is at par).
When recovery moves to `x` near `R₀`, the hazard is re-implied as `g x` so the quote still fits;
when the rate moves to `y` near `r₀`, it is re-implied as `f y`. Then the position's value
`N (P - s₀ A)` has derivative exactly zero in recovery at `R₀` and in the rate at `r₀`. -/
theorem rec01_and_ir01_vanish_at_par
    (N δ s₀ r₀ R₀ : ℝ) (n : ℕ) (hn : 1 ≤ n) (hδ : 0 < δ)
    (A : ℝ → ℝ → ℝ) (P : ℝ → ℝ → ℝ → ℝ)
    (hA : ∀ r lam, A r lam = ∑ j ∈ Icc 1 n, δ * Real.exp (-(r + lam) * (j * δ)))
    (hP : ∀ r lam R,
      P r lam R = (1 - R) * lam * (1 - Real.exp (-(r + lam) * (n * δ))) / (r + lam))
    (g : ℝ → ℝ) (hg : ∀ᶠ x in nhds R₀, P r₀ (g x) x / A r₀ (g x) = s₀)
    (f : ℝ → ℝ) (hf : ∀ᶠ y in nhds r₀, P y (f y) R₀ / A y (f y) = s₀) :
    HasDerivAt (fun x => N * (P r₀ (g x) x - s₀ * A r₀ (g x))) 0 R₀ ∧
    HasDerivAt (fun y => N * (P y (f y) R₀ - s₀ * A y (f y))) 0 r₀ := by
  have hApos : ∀ r lam, 0 < A r lam := fun r lam => by
    rw [hA r lam]; exact cds_annuity_pos (r + lam) δ n hn hδ
  constructor
  · have heq : (fun x => N * (P r₀ (g x) x - s₀ * A r₀ (g x))) =ᶠ[nhds R₀] fun _ => 0 := by
      filter_upwards [hg] with x hx
      rw [div_eq_iff (hApos r₀ (g x)).ne'] at hx
      rw [hx]; ring
    exact (hasDerivAt_const R₀ (0 : ℝ)).congr_of_eventuallyEq heq
  · have heq : (fun y => N * (P y (f y) R₀ - s₀ * A y (f y))) =ᶠ[nhds r₀] fun _ => 0 := by
      filter_upwards [hf] with y hy
      rw [div_eq_iff (hApos y (f y)).ne'] at hy
      rw [hy]; ring
    exact (hasDerivAt_const r₀ (0 : ℝ)).congr_of_eventuallyEq heq

/-- On a flat curve there is no roll-down. With one flat hazard `λ`, rate `r` and recovery `R`,
a contract with `n ≥ 1` quarterly premiums (`δ > 0`, maturity `n δ`) and one with `m ≥ 1`
premiums have the same par spread `P / A`, because the maturity enters both legs only through
the shared factor `1 - e^{-(r+λ) T}`. So a contract bought at par for `n` quarters, once it has
`m` quarters left on the unchanged curve, is still worth exactly zero to the buyer. -/
theorem flat_curve_par_spread_same_for_every_maturity
    (N r lam R δ : ℝ) (n m : ℕ) (hn : 1 ≤ n) (hm : 1 ≤ m) (hδ : 0 < δ) :
    let A : ℕ → ℝ := fun k => ∑ j ∈ Icc 1 k, δ * Real.exp (-(r + lam) * (j * δ))
    let P : ℕ → ℝ := fun k =>
      (1 - R) * lam * (1 - Real.exp (-(r + lam) * (k * δ))) / (r + lam)
    P m / A m = P n / A n ∧ N * (P m - (P n / A n) * A m) = 0 := by
  intro A P
  have hApos : ∀ k, 1 ≤ k → 0 < A k := fun k hk => cds_annuity_pos (r + lam) δ k hk hδ
  set c := r + lam with hc
  set q := Real.exp (-c * δ) with hq
  have key : ∀ k, 1 ≤ k → P k / A k = (1 - R) * lam * (1 - q) / (c * δ * q) := by
    intro k hk
    by_cases hc0 : c = 0
    · simp [P, hc0, ← hc]
    · have hqpos : 0 < q := Real.exp_pos _
      have hq1 : q ≠ 1 := by
        intro h1
        rw [hq, Real.exp_eq_one_iff] at h1
        rcases mul_eq_zero.mp h1 with h | h
        · exact hc0 (neg_eq_zero.mp h)
        · exact hδ.ne' h
      have hAk : A k = δ * ∑ j ∈ Icc 1 k, q ^ j := cds_annuity_geom c δ k
      have hgeo := cds_geom_Icc q k
      have hPk : P k = (1 - R) * lam * (1 - q ^ k) / c := by
        simp only [P, ← hc]
        congr 3
        rw [← Real.exp_nat_mul]
        congr 1
        ring
      have hAne := (hApos k hk).ne'
      rw [div_eq_iff hAne, hPk, hAk]
      have hq1' : q - 1 ≠ 0 := sub_ne_zero.mpr hq1
      have hS : ∑ j ∈ Icc 1 k, q ^ j = (q ^ (k + 1) - q) / (q - 1) := by
        rw [eq_div_iff hq1', hgeo]
      rw [hS]
      field_simp
      ring
  have h1 : P m / A m = P n / A n := by rw [key m hm, key n hn]
  refine ⟨h1, ?_⟩
  rw [← h1, div_mul_cancel₀ _ (hApos m hm).ne']
  ring

-- Northwind: $10,000,000 notional, recovery 40%, five years of quarterly premiums.
-- Five years of quarters is n = 20 premium dates; a quarter later 19 are left, 4.75 years.
example : (5 : ℚ) / (1 / 4) = 20 ∧ (19 : ℚ) * (1 / 4) = 475 / 100 := by norm_num
-- Combined shrink rate k = r + λ = 0.05 + 0.02 = 0.07.
example : (5 : ℚ) / 100 + 2 / 100 = 7 / 100 := by norm_num
-- Jump-to-default on day one: (1 - R) N - V with V = 0 is $6,000,000.
example : (1 - (40 : ℚ) / 100) * 10000000 - 0 = 6000000 := by norm_num
-- Each point of recovery takes $100,000 off jump-to-default.
example : (10000000 : ℚ) * (1 / 100) = 100000 := by norm_num
-- An auction at 30% instead of 40%: jump-to-default is $1,000,000 bigger, $100,000 per point.
example : (1 - (30 : ℚ) / 100) * 10000000 - (1 - 40 / 100) * 10000000 = 10 * 100000 := by
  norm_num
-- The quick estimate: notional times years left times 1 bp is $5,000.
example : (10000000 : ℚ) * 5 * (1 / 10000) = 5000 := by norm_num

#print axioms cds_annuity_pos
#print axioms cds_geom_Icc
#print axioms cds_annuity_geom
#print axioms cs01_at_par_eq_notional_mul_annuity
#print axioms rec01_and_ir01_vanish_at_par
#print axioms flat_curve_par_spread_same_for_every_maturity
