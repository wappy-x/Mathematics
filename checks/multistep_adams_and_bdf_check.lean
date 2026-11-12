-- Multistep methods: an explicit Adams method with a Lipschitz slope, local error at most C h^(p+1) per step and starting errors at most C₀ h^p stays within e^(L B T) (C₀ + T C) h^p of the true solution, and its weights, the areas under the Lagrange basis over the next step, integrate every polynomial of degree below k exactly.
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Topology.Algebra.Polynomial
import Mathlib.Tactic.NormNum

/-! Notation. An explicit `k`-step Adams method with step `h` and slope weights `β 0, …, β (k-1)`
steps `y_(m+1) = y_m + h (β_0 f_m + β_1 f_(m-1) + … + β_(k-1) f_(m-k+1))`, where `f_m = f (y_m)`.
In Lean the step that produces `y (n + k)` reads the slopes at `y (n + k - 1 - j)`, `j < k`.
`Y m` is the true solution at time `t_m = m h`; `B = ∑ |β_j|`; `T = N h` is the time of the run.
Time on the weight side is counted in steps: `s = 0` is now, `s = 1` one step on, and the stored
slope `j` sits at node `c j`. -/

open Polynomial Real

/-- The area over `[0, 1]` under a product of three linear factors. -/
lemma integral_three_linear (K₁ x₁ K₂ x₂ K₃ x₃ : ℝ) :
    ∫ s in (0 : ℝ)..1, K₁ * (s - x₁) * (K₂ * (s - x₂) * (K₃ * (s - x₃))) =
      K₁ * K₂ * K₃ * (1 / 4 - (x₁ + x₂ + x₃) / 3 + (x₁ * x₂ + x₁ * x₃ + x₂ * x₃) / 2
        - x₁ * x₂ * x₃) := by
  have hF : ∀ s ∈ Set.uIcc (0 : ℝ) 1, HasDerivAt
      (fun s : ℝ => K₁ * K₂ * K₃ * (s ^ 4 / 4 - (x₁ + x₂ + x₃) * s ^ 3 / 3
        + (x₁ * x₂ + x₁ * x₃ + x₂ * x₃) * s ^ 2 / 2 - x₁ * x₂ * x₃ * s))
      (K₁ * (s - x₁) * (K₂ * (s - x₂) * (K₃ * (s - x₃)))) s := by
    intro s _
    have := (((((hasDerivAt_pow 4 s).div_const 4).sub
      (((hasDerivAt_pow 3 s).const_mul (x₁ + x₂ + x₃)).div_const 3)).add
      (((hasDerivAt_pow 2 s).const_mul (x₁ * x₂ + x₁ * x₃ + x₂ * x₃)).div_const 2)).sub
      ((hasDerivAt_id s).const_mul (x₁ * x₂ * x₃))).const_mul (K₁ * K₂ * K₃)
    convert this using 1
    · funext s; simp [id]
    · simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF
    ((Continuous.intervalIntegrable (by fun_prop) _ _))]
  ring

#print axioms integral_three_linear

/-- The area under one Lagrange cubic, once the three other nodes are listed. -/
lemma integral_basis_four (v : Fin 4 → ℝ) (j a b c : Fin 4)
    (hset : Finset.univ.erase j = {a, b, c}) (ha : a ∉ ({b, c} : Finset (Fin 4)))
    (hb : b ∉ ({c} : Finset (Fin 4))) :
    ∫ s in (0 : ℝ)..1, (Lagrange.basis Finset.univ v j).eval s =
      (v j - v a)⁻¹ * (v j - v b)⁻¹ * (v j - v c)⁻¹ *
        (1 / 4 - (v a + v b + v c) / 3 + (v a * v b + v a * v c + v b * v c) / 2
          - v a * v b * v c) := by
  rw [Lagrange.basis, hset, Finset.prod_insert ha, Finset.prod_insert hb,
    Finset.prod_singleton]
  simp only [eval_mul, Lagrange.basisDivisor, eval_C, eval_sub, eval_X]
  exact integral_three_linear _ _ _ _ _ _

#print axioms integral_basis_four

/-- Step 4 of the card: every Adams method with local error `O(h^(p+1))` converges with order `p`.
Let the slope `f` have Lipschitz constant `L`. Let the true solution's values `Y m` miss the
method's step by at most `h · C h^p` (local error `h τ_n` with `|τ_n| ≤ C h^p`) at every step of a
run of `N` steps, and let the `k` starting values be accurate to `C₀ h^p`. Then every computed
value of the run is within `e^(L B T) (C₀ + T C) h^p` of the truth, with `B = ∑ |β_j|` and
`T = N h`: the global error is `O(h^p)`. -/
theorem adams_global_error_le
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (k : ℕ) (hk : 0 < k) (β : Fin k → ℝ) (f : E → E) (L : NNReal) (hf : LipschitzWith L f)
    (Y y : ℕ → E) (h C₀ C : ℝ) (p N : ℕ) (hh : 0 < h) (hC : 0 ≤ C)
    (hstep : ∀ n, y (n + k) = y (n + k - 1) + h • ∑ j : Fin k, β j • f (y (n + k - 1 - j)))
    (hlocal : ∀ n, n + k ≤ N →
      ‖Y (n + k) - Y (n + k - 1) - h • ∑ j : Fin k, β j • f (Y (n + k - 1 - j))‖
        ≤ h * (C * h ^ p))
    (hstart : ∀ m < k, ‖Y m - y m‖ ≤ C₀ * h ^ p) :
    ∀ m ≤ N, ‖Y m - y m‖ ≤
      exp ((L : ℝ) * (∑ j, |β j|) * (N * h)) * (C₀ + N * h * C) * h ^ p := by
  set B : ℝ := ∑ j, |β j| with hBdef
  have hB : 0 ≤ B := Finset.sum_nonneg (fun j _ => abs_nonneg (β j))
  have hL : (0 : ℝ) ≤ L := L.2
  have hhp : 0 < h ^ p := pow_pos hh p
  have hC₀ : 0 ≤ C₀ := by
    have h0 := hstart 0 hk
    have : 0 ≤ C₀ * h ^ p := le_trans (norm_nonneg _) h0
    exact nonneg_of_mul_nonneg_left this hhp
  set g : ℕ → ℝ := fun m => exp ((L : ℝ) * B * (m * h)) * (C₀ + m * h * C) * h ^ p with hgdef
  have hg0 : ∀ i, 0 ≤ g i := by
    intro i
    have : 0 ≤ C₀ + (i : ℝ) * h * C := by positivity
    positivity
  -- one-step growth of the bound
  have hgrow : ∀ i, g i * (1 + h * B * L) + h * (C * h ^ p) ≤ g (i + 1) := by
    intro i
    simp only [hgdef]
    push_cast
    set X := exp ((L : ℝ) * B * (i * h)) with hX
    have hX1 : 1 ≤ X := one_le_exp (by positivity)
    have hexp : exp ((L : ℝ) * B * ((i + 1) * h)) = X * exp ((L : ℝ) * B * h) := by
      rw [hX, ← exp_add]; ring_nf
    have hY1 : 1 + h * B * L ≤ exp ((L : ℝ) * B * h) := by
      have := add_one_le_exp ((L : ℝ) * B * h); linarith [show (L : ℝ) * B * h = h * B * L by ring]
    have hYge1 : 1 ≤ exp ((L : ℝ) * B * h) := one_le_exp (by positivity)
    rw [hexp]
    set D := C₀ + (i : ℝ) * h * C with hD
    have hD0 : 0 ≤ D := by positivity
    have e1 : (C₀ + ((i : ℝ) + 1) * h * C) = D + h * C := by rw [hD]; ring
    rw [e1]
    have hXD : 0 ≤ X * D * h ^ p := by positivity
    have hhC : 0 ≤ h * C * h ^ p := by positivity
    have a1 : X * D * h ^ p * (1 + h * B * L) ≤ X * D * h ^ p * exp ((L : ℝ) * B * h) :=
      mul_le_mul_of_nonneg_left hY1 hXD
    have a2 : h * C * h ^ p ≤ (X * exp ((L : ℝ) * B * h)) * (h * C * h ^ p) :=
      le_mul_of_one_le_left hhC (one_le_mul_of_one_le_of_one_le hX1 hYge1)
    nlinarith
  have hmono : Monotone g := by
    apply monotone_nat_of_le_succ
    intro i
    have := hgrow i
    have : 0 ≤ g i * (h * B * L) := by have := hg0 i; positivity
    have : 0 ≤ h * (C * h ^ p) := by positivity
    nlinarith
  have main : ∀ m, m ≤ N → ‖Y m - y m‖ ≤ g m := by
    intro m
    induction m using Nat.strong_induction_on with
    | _ m ih =>
      intro hmN
      by_cases hmk : m < k
      · refine le_trans (hstart m hmk) ?_
        show C₀ * h ^ p ≤ exp ((L : ℝ) * B * (m * h)) * (C₀ + m * h * C) * h ^ p
        have hE : 1 ≤ exp ((L : ℝ) * B * (m * h)) := one_le_exp (by positivity)
        have hmC : 0 ≤ (m : ℝ) * h * C := by positivity
        have hpos : 0 ≤ (C₀ + (m : ℝ) * h * C) * h ^ p := by positivity
        have h1 := mul_le_mul_of_nonneg_right hE hpos
        have h2 : C₀ * h ^ p ≤ (C₀ + (m : ℝ) * h * C) * h ^ p :=
          mul_le_mul_of_nonneg_right (by linarith) hhp.le
        nlinarith
      · push Not at hmk
        obtain ⟨n, rfl⟩ : ∃ n, m = n + k := ⟨m - k, by omega⟩
        set G := g (n + k - 1) with hG
        have hbound : ∀ i, i ≤ n + k - 1 → ‖Y i - y i‖ ≤ G := by
          intro i hi
          exact le_trans (ih i (by omega) (by omega)) (hmono hi)
        have hdecomp : Y (n + k) - y (n + k) =
            (Y (n + k) - Y (n + k - 1) - h • ∑ j : Fin k, β j • f (Y (n + k - 1 - j)))
            + (Y (n + k - 1) - y (n + k - 1))
            + h • ∑ j : Fin k, β j • (f (Y (n + k - 1 - j)) - f (y (n + k - 1 - j))) := by
          rw [hstep n]
          simp only [smul_sub, Finset.sum_sub_distrib]
          abel
        have hsum : ‖h • ∑ j : Fin k, β j • (f (Y (n + k - 1 - j)) - f (y (n + k - 1 - j)))‖
            ≤ h * (B * (L * G)) := by
          rw [norm_smul, Real.norm_eq_abs, abs_of_pos hh]
          refine mul_le_mul_of_nonneg_left ?_ hh.le
          refine le_trans (norm_sum_le _ _) ?_
          rw [hBdef, Finset.sum_mul]
          refine Finset.sum_le_sum (fun j _ => ?_)
          rw [norm_smul, Real.norm_eq_abs]
          refine mul_le_mul_of_nonneg_left ?_ (abs_nonneg _)
          refine le_trans (hf.norm_sub_le _ _) ?_
          exact mul_le_mul_of_nonneg_left (hbound _ (by omega)) hL
        have hloc := hlocal n hmN
        have hprev := hbound (n + k - 1) le_rfl
        have hgr := hgrow (n + k - 1)
        rw [show n + k - 1 + 1 = n + k by omega] at hgr
        rw [hdecomp]
        refine le_trans (norm_add_le _ _) ?_
        refine le_trans (add_le_add (norm_add_le _ _) le_rfl) ?_
        nlinarith
  intro m hm
  exact le_trans (main m hm) (hmono hm)

/-- Step 3 of the card: an Adams rule built by integrating the fit is exact for every polynomial
slope of degree below `k`. Take `k` distinct nodes `c j` and let `β_j` be the area under the
Lagrange basis polynomial `ℓ_j` (equal to 1 at node `j` and 0 at the other nodes) from `s = 0`
to `s = 1`. Then for every polynomial `P` of degree less than `k`,
`∫₀¹ P(s) ds = ∑ β_j P(c_j)`; with `P = s^q` these are the order conditions
`∑ β_j c_j^q = 1/(q+1)`. -/
theorem adams_weights_exact_for_polynomials
    (k : ℕ) (c : Fin k → ℝ) (hc : Function.Injective c) (P : ℝ[X]) (hP : P.degree < k) :
    ∫ s in (0 : ℝ)..1, P.eval s =
      ∑ j, (∫ s in (0 : ℝ)..1, (Lagrange.basis Finset.univ c j).eval s) * P.eval (c j) := by
  have hinj : Set.InjOn c (Finset.univ : Finset (Fin k)) := hc.injOn
  have hdeg : P.degree < (Finset.univ : Finset (Fin k)).card := by simpa using hP
  have hPeq := Lagrange.eq_interpolate hinj hdeg
  have hfun : (fun s => P.eval s) =
      fun s => ∑ j, P.eval (c j) * (Lagrange.basis Finset.univ c j).eval s := by
    funext s
    conv_lhs => rw [hPeq]
    simp [Lagrange.interpolate_apply, eval_finsetSum]
  rw [hfun, intervalIntegral.integral_finsetSum]
  · refine Finset.sum_congr rfl (fun j _ => ?_)
    rw [intervalIntegral.integral_const_mul, mul_comm]
  · intro j _
    exact (continuous_const.mul (Polynomial.continuous _)).intervalIntegrable _ _

/-- Steps 1 and 2 of the card: the areas under the four Lagrange basis cubics over the next step
are AB4's weights `55, −59, 37, −9` over 24 for the stored slopes at `s = 0, −1, −2, −3`, and
AM4's weights `9, 19, −5, 1` over 24 when the fit runs through `s = 1, 0, −1, −2`. -/
theorem ab4_and_am4_weights :
    (∀ j : Fin 4, ∫ s in (0 : ℝ)..1, (Lagrange.basis Finset.univ ![0, -1, -2, -3] j).eval s
        = ![55 / 24, -59 / 24, 37 / 24, -9 / 24] j) ∧
    (∀ j : Fin 4, ∫ s in (0 : ℝ)..1, (Lagrange.basis Finset.univ ![1, 0, -1, -2] j).eval s
        = ![9 / 24, 19 / 24, -5 / 24, 1 / 24] j) := by
  refine ⟨fun j => ?_, fun j => ?_⟩ <;> fin_cases j
  · refine (integral_basis_four _ 0 1 2 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 1 0 2 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 2 0 1 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 3 0 1 2 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 0 1 2 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 1 0 2 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 2 0 1 3 (by decide) (by decide) (by decide)).trans ?_; norm_num
  · refine (integral_basis_four _ 3 0 1 2 (by decide) (by decide) (by decide)).trans ?_; norm_num

/-! The card's worked numbers, in exact fractions. -/

-- AB4's weight on f_n: (1/6)(1/4 + 2 + 11/2 + 6) = 55/24, and the four weights add to 1.
example : (1 / 6 : ℚ) * (1 / 4 + 2 + 11 / 2 + 6) = 55 / 24 := by norm_num
example : ((55 - 59 + 37 - 9) / 24 : ℚ) = 1 := by norm_num

-- AB4's order conditions ∑ β_j c_j^q = 1/(q+1), q = 0..3, at c = 0, −1, −2, −3.
example : (55 / 24 - 59 / 24 + 37 / 24 - 9 / 24 : ℚ) = 1 ∧
    (55 / 24 * 0 - 59 / 24 * (-1) + 37 / 24 * (-2) - 9 / 24 * (-3) : ℚ) = 1 / 2 ∧
    (55 / 24 * 0 - 59 / 24 * (-1) ^ 2 + 37 / 24 * (-2) ^ 2 - 9 / 24 * (-3) ^ 2 : ℚ) = 1 / 3 ∧
    (55 / 24 * 0 - 59 / 24 * (-1) ^ 3 + 37 / 24 * (-2) ^ 3 - 9 / 24 * (-3) ^ 3 : ℚ) = 1 / 4 := by
  norm_num

-- AM4's order conditions, at c = 1, 0, −1, −2.
example : (9 / 24 + 19 / 24 - 5 / 24 + 1 / 24 : ℚ) = 1 ∧
    (9 / 24 * 1 + 19 / 24 * 0 - 5 / 24 * (-1) + 1 / 24 * (-2) : ℚ) = 1 / 2 ∧
    (9 / 24 * 1 + 19 / 24 * 0 - 5 / 24 * (-1) ^ 2 + 1 / 24 * (-2) ^ 2 : ℚ) = 1 / 3 ∧
    (9 / 24 * 1 + 19 / 24 * 0 - 5 / 24 * (-1) ^ 3 + 1 / 24 * (-2) ^ 3 : ℚ) = 1 / 4 := by
  norm_num

-- Error constants C = 1/5! − (1/4!) ∑ β_j c_j^4: AB4 251/720, AM4 −19/720; Milne factor 19/270.
example : (1 / 120 - 1 / 24 * ((-59 + 37 * 16 - 9 * 81) / 24) : ℚ) = 251 / 720 := by norm_num
example : (1 / 120 - 1 / 24 * ((9 - 5 + 16) / 24) : ℚ) = -19 / 720 := by norm_num
example : ((-19 / 720) / (-19 / 720 - 251 / 720) : ℚ) = 19 / 270 := by norm_num

-- BDF2: 3/2 Y(1) − 2 Y(0) + 1/2 Y(−1) = Y'(1) for Y = 1, s, s^2; ρ has roots 1 and 1/3.
example : (3 / 2 - 2 + 1 / 2 : ℚ) = 0 ∧ (3 / 2 * 1 - 2 * 0 + 1 / 2 * (-1) : ℚ) = 1 ∧
    (3 / 2 * 1 - 2 * 0 + 1 / 2 * 1 : ℚ) = 2 * 1 := by norm_num
example : (3 / 2 * 1 ^ 2 - 2 * 1 + 1 / 2 : ℚ) = 0 ∧
    (3 / 2 * (1 / 3) ^ 2 - 2 * (1 / 3) + 1 / 2 : ℚ) = 0 := by norm_num

-- Adams: ρ(ζ) = ζ^4 − ζ^3 has roots 1 and 0.
example : (1 : ℤ) ^ 4 - 1 ^ 3 = 0 ∧ (0 : ℤ) ^ 4 - 0 ^ 3 = 0 := by decide

-- What breaks: y_(n+1) + 4 y_n − 5 y_(n−1) = h (4 f_n + 2 f_(n−1)) has ρ roots 1 and −5,
-- meets the order conditions ∑ α_j c_j^q = q ∑ β_j c_j^(q−1) for q = 0..3 (order 3), and fails q = 4.
example : (1 : ℤ) ^ 2 + 4 * 1 - 5 = 0 ∧ (-5 : ℤ) ^ 2 + 4 * (-5) - 5 = 0 := by decide
example : (1 + 4 - 5 : ℤ) = 0 ∧
    (1 + 4 * 0 - 5 * (-1) : ℤ) = 1 * (4 + 2) ∧
    (1 + 4 * 0 - 5 * (-1) ^ 2 : ℤ) = 2 * (4 * 0 + 2 * (-1)) ∧
    (1 + 4 * 0 - 5 * (-1) ^ 3 : ℤ) = 3 * (4 * 0 + 2 * (-1) ^ 2) ∧
    (1 + 4 * 0 - 5 * (-1) ^ 4 : ℤ) ≠ 4 * (4 * 0 + 2 * (-1) ^ 3) := by decide

-- AB6's weights times 1440 add to 1440; halving the step divides an order-4 error by 2^4 = 16.
example : (4277 - 7923 + 9982 - 7298 + 2877 - 475 : ℤ) = 1440 := by decide
example : (2 : ℕ) ^ 4 = 16 := by decide

#print axioms adams_global_error_le
#print axioms adams_weights_exact_for_polynomials
#print axioms ab4_and_am4_weights
