-- The L-function of a modular form: a cusp form whose Fricke flip sends it to plus or minus itself has an entire completed L-function, its Mellin transform, with the mirror Λ(s) = ε i^k Λ(k − s), and coefficients obeying the Hecke rules give the Euler product.
import Mathlib.NumberTheory.ModularForms.LFunction
import Mathlib.NumberTheory.ModularForms.CongruenceSubgroups
import Mathlib.NumberTheory.EulerProduct.Basic
import Mathlib.NumberTheory.LSeries.Basic
import Mathlib.Data.ZMod.Basic

open Complex CongruenceSubgroup
open UpperHalfPlane hiding I

set_option autoImplicit false

lemma natCast_pow_cpow_eq (p e : ℕ) (s : ℂ) : (((p ^ e : ℕ) : ℂ)) ^ s = ((p : ℂ) ^ s) ^ e := by
  induction e with
  | zero => simp
  | succ e ih => rw [pow_succ, Nat.cast_mul, natCast_mul_natCast_cpow, ih, pow_succ]

#print axioms natCast_pow_cpow_eq

lemma sqrt_natCast_cpow (N : ℕ) (hN : N ≠ 0) (w : ℂ) :
    ((Real.sqrt N : ℝ) : ℂ) ^ w = (N : ℂ) ^ (w / 2) := by
  have h1 : (0 : ℝ) < Real.sqrt N := Real.sqrt_pos.mpr (by positivity)
  rw [cpow_def_of_ne_zero (ofReal_ne_zero.mpr h1.ne'), cpow_def_of_ne_zero (by exact_mod_cast hN),
    ← ofReal_log h1.le, Real.log_sqrt (Nat.cast_nonneg _), ← ofReal_natCast,
    ← ofReal_log (Nat.cast_nonneg _)]
  push_cast
  ring_nf

#print axioms sqrt_natCast_cpow

/-- The card's main claim (Steps 2 to 5). Let `f` be a cusp form of weight `k ≥ 1` and level `N`
(a cusp form for `Γ₀(N)`) whose Fricke flip `z ↦ -1/(Nz)` sends it to `±` itself:
`f(-1/(Nz)) = ε N^(k/2) z^k f(z)` with `ε = ±1`. Then the completed L-function
`Λ(f, s) = N^(s/2) ∫₀^∞ f(iy) y^(s-1) dy` extends to a holomorphic function of every complex `s`,
and it satisfies the mirror `Λ(f, s) = w Λ(f, k - s)` with sign `w = ε i^k`. -/
theorem completed_L_function_entire_and_functional_equation
    (N : ℕ) [NeZero N] {k : ℤ} (hk : 0 < k)
    (f : CuspForm (Gamma0 N : Subgroup (GL (Fin 2) ℝ)) k) (ε : ℂ) (hε : ε = 1 ∨ ε = -1)
    (hfricke : ∀ z : ℍ,
      f (ofComplex (-1 / ((N : ℂ) * (z : ℂ)))) = ε * ((Real.sqrt N : ℝ) : ℂ) ^ k * (z : ℂ) ^ k * f z) :
    Differentiable ℂ (fun s : ℂ => (N : ℂ) ^ (s / 2) * mellin (fun y : ℝ => f (ofComplex (I * y))) s) ∧
    ∀ s : ℂ,
      (N : ℂ) ^ (s / 2) * mellin (fun y : ℝ => f (ofComplex (I * y))) s =
        ε * I ^ k * ((N : ℂ) ^ ((k - s) / 2) * mellin (fun y : ℝ => f (ofComplex (I * y))) (k - s)) := by
  have hN : N ≠ 0 := NeZero.ne N
  have hN0 : (N : ℂ) ≠ 0 := by exact_mod_cast hN
  set F : ℝ → ℂ := fun y : ℝ => f (ofComplex (I * y)) with hF
  have hdiff : Differentiable ℂ (mellin F) := by
    rw [hF, ← CuspForm.Λ_eq_mellin hk f]; exact CuspForm.differentiable_Λ hk f
  refine ⟨?_, ?_⟩
  · exact (Differentiable.const_cpow (by fun_prop) (Or.inl hN0)).mul hdiff
  set c : ℂ := ε * ((Real.sqrt N : ℝ) : ℂ) ^ k * I ^ k with hc
  have hkey : ∀ y : ℝ, 0 < y → F ((N * y)⁻¹) = (y : ℂ) ^ (k : ℂ) • (c * F y) := by
    intro y hy
    have hz : 0 < (I * (y : ℂ)).im := by simpa using hy
    have := hfricke (ofComplex (I * y))
    rw [ofComplex_apply_of_im_pos hz] at this
    have harg : (-1 / ((N : ℂ) * (I * (y : ℂ)))) = I * (((N * y)⁻¹ : ℝ) : ℂ) := by
      push_cast
      field_simp
      rw [I_sq]
      ring
    rw [harg] at this
    simp only [hF]
    rw [this, cpow_intCast, smul_eq_mul, hc, ofComplex_apply_of_im_pos hz]
    change _ * ((I * (y : ℂ)) ^ k) * _ = _
    rw [mul_zpow]
    ring
  -- the Mellin transform of `y ↦ F (1/(N y))`, computed two ways
  have h1 : ∀ s : ℂ, mellin (fun y : ℝ => F ((N * y)⁻¹)) s = (N : ℂ) ^ (-s) * mellin F (-s) := by
    intro s
    have hNpos : (0 : ℝ) < N := by exact_mod_cast Nat.pos_of_ne_zero hN
    rw [mellin_comp_mul_left (fun t => F t⁻¹) s hNpos, mellin_comp_inv, smul_eq_mul, ofReal_natCast]
  have h2 : ∀ s : ℂ, mellin (fun y : ℝ => F ((N * y)⁻¹)) s = c * mellin F (s + k) := by
    intro s
    rw [← smul_eq_mul, ← mellin_const_smul, ← mellin_cpow_smul]
    exact MeasureTheory.setIntegral_congr_fun measurableSet_Ioi (fun y hy => by
      simp only [hkey y hy, smul_eq_mul])
  intro s
  have hfe : (N : ℂ) ^ s * mellin F s = c * mellin F (k - s) := by
    have := (h1 (-s)).symm.trans (h2 (-s))
    rw [neg_neg, neg_add_eq_sub] at this
    exact this
  have hNk : ((Real.sqrt N : ℝ) : ℂ) ^ k = (N : ℂ) ^ (s / 2) * (N : ℂ) ^ ((k - s) / 2) := by
    rw [← cpow_intCast, sqrt_natCast_cpow N hN, ← cpow_add _ _ hN0]
    congr 1
    ring
  have hNs : (N : ℂ) ^ s = (N : ℂ) ^ (s / 2) * (N : ℂ) ^ (s / 2) := by
    rw [← cpow_add _ _ hN0]
    congr 1
    ring
  have hne : (N : ℂ) ^ (s / 2) ≠ 0 := cpow_ne_zero_iff.mpr (Or.inl hN0)
  apply mul_left_cancel₀ hne
  rw [hNs, hc, hNk] at hfe
  linear_combination hfe

/-- Step 2: where the series converges absolutely (`Re s > k/2 + 1`), the completed function
`N^(s/2) ∫₀^∞ f(iy) y^(s-1) dy` of a cusp form of weight `k ≥ 1` and level `N` equals
`(√N / 2π)^s Γ(s) L(f, s)`, where `L(f, s) = ∑ aₙ n^(-s)` is built from the coefficients `aₙ` of
the expansion `f = ∑ aₙ qⁿ`, `q = e^(2πiz)`. -/
theorem completed_L_function_eq_gamma_mul_dirichlet_series
    (N : ℕ) [NeZero N] {k : ℤ} (hk : 0 < k)
    (f : CuspForm (Gamma0 N : Subgroup (GL (Fin 2) ℝ)) k) {s : ℂ} (hs : (k : ℝ) / 2 + 1 < s.re) :
    Summable (fun n : ℕ => (qExpansion 1 f).coeff n / (n : ℂ) ^ s) ∧
    (N : ℂ) ^ (s / 2) * mellin (fun y : ℝ => f (ofComplex (I * y))) s =
      (((Real.sqrt N : ℝ) : ℂ) / (2 * (Real.pi : ℂ))) ^ s * Gamma s *
        ∑' n : ℕ, (qExpansion 1 f).coeff n / (n : ℂ) ^ s := by
  have hw : Subgroup.strictWidthInfty ((Gamma0 N : Subgroup (GL (Fin 2) ℝ))) = 1 :=
    Subgroup.strictWidthInfty_eq_one_of_T_mem (Gamma0_mem.mpr (by simp [ModularGroup.T]))
  have hL := CuspForm.hasSum_L hk f hs
  rw [hw] at hL
  simp only [ofReal_one, one_cpow, one_mul] at hL
  refine ⟨hL.summable, ?_⟩
  have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
  have hspos : 0 < s.re := by linarith
  have hs0 : s ≠ 0 := ne_zero_of_re_pos hspos
  rw [hL.tsum_eq, ← CuspForm.Λ_eq_mellin hk f, ModularForm.L_apply_of_ne_zero hk f hs0]
  have hN : N ≠ 0 := NeZero.ne N
  have h2pi : (2 * (Real.pi : ℂ)) = ((2 * Real.pi : ℝ) : ℂ) := by push_cast; ring
  have hpi0 : (0 : ℝ) < 2 * Real.pi := by positivity
  have hcp : ((2 * Real.pi : ℝ) : ℂ) ^ s ≠ 0 :=
    cpow_ne_zero_iff.mpr (Or.inl (ofReal_ne_zero.mpr hpi0.ne'))
  have hGam := Gamma_ne_zero_of_re_pos hspos
  rw [h2pi, div_cpow_ofReal_nonneg (Real.sqrt_nonneg _) hpi0.le, sqrt_natCast_cpow N hN,
    Gammaℂ_def, cpow_neg, ← h2pi]
  rw [← h2pi] at hcp
  field_simp

/-- Step 7: the Euler product. If the coefficients `aₙ` obey the Hecke rules of a normalised
eigenform of weight `k` and level `N` (`a₁ = 1`; `a_(mn) = a_m a_n` for coprime `m, n`;
`a_(p^(r+1)) = a_p a_(p^r) - p^(k-1) a_(p^(r-1))` for `p ∤ N`; `a_(p^r) = a_p^r` for `p ∣ N`),
then wherever `L(f, s) = ∑ aₙ n^(-s)` converges absolutely it is the product over primes of
`1/(1 - a_p p^(-s) + p^(k-1-2s))` for `p ∤ N` and `1/(1 - a_p p^(-s))` for `p ∣ N`. -/
theorem euler_product_of_hecke_rules
    (N : ℕ) (k : ℤ) (a : ℕ → ℂ) {s : ℂ}
    (h1 : a 1 = 1)
    (hmul : ∀ m n : ℕ, Nat.Coprime m n → a (m * n) = a m * a n)
    (hgood : ∀ p : ℕ, p.Prime → ¬ p ∣ N → ∀ r : ℕ,
      a (p ^ (r + 2)) = a p * a (p ^ (r + 1)) - (p : ℂ) ^ ((k : ℂ) - 1) * a (p ^ r))
    (hbad : ∀ p : ℕ, p.Prime → p ∣ N → ∀ r : ℕ, a (p ^ r) = a p ^ r)
    (hs : LSeriesSummable a s) :
    HasProd
      (fun p : Nat.Primes =>
        if (p : ℕ) ∣ N then (1 - a p * (p : ℂ) ^ (-s))⁻¹
        else (1 - a p * (p : ℂ) ^ (-s) + (p : ℂ) ^ ((k : ℂ) - 1 - 2 * s))⁻¹)
      (LSeries a s) := by
  have hf₁ : LSeries.term a s 1 = 1 := by simp [h1]
  have hm : ∀ {m n : ℕ}, Nat.Coprime m n →
      LSeries.term a s (m * n) = LSeries.term a s m * LSeries.term a s n := by
    intro m n hmn
    rcases Nat.eq_zero_or_pos m with rfl | hm0
    · simp
    rcases Nat.eq_zero_or_pos n with rfl | hn0
    · simp
    rw [LSeries.term_of_ne_zero (Nat.mul_ne_zero hm0.ne' hn0.ne'),
      LSeries.term_of_ne_zero hm0.ne', LSeries.term_of_ne_zero hn0.ne', hmul m n hmn,
      Nat.cast_mul, natCast_mul_natCast_cpow, mul_div_mul_comm]
  have hsum : Summable (‖LSeries.term a s ·‖) := summable_norm_iff.mpr hs
  have hE := EulerProduct.eulerProduct_hasProd hf₁ hm hsum (LSeries.term_zero a s)
  rw [show LSeries a s = ∑' n, LSeries.term a s n from rfl]
  convert hE using 1
  funext p
  have hp := p.prop
  have hp0 : (p : ℂ) ≠ 0 := by exact_mod_cast hp.ne_zero
  set x : ℂ := (p : ℂ) ^ (-s) with hx
  have hterm : ∀ e : ℕ, LSeries.term a s ((p : ℕ) ^ e) = a ((p : ℕ) ^ e) * x ^ e := by
    intro e
    rw [LSeries.term_of_ne_zero (pow_ne_zero _ hp.ne_zero), natCast_pow_cpow_eq, hx, cpow_neg,
      inv_pow, div_eq_mul_inv]
  have hb : Summable (fun e : ℕ => a ((p : ℕ) ^ e) * x ^ e) := by
    have := hs.comp_injective (Nat.pow_right_injective hp.two_le)
    simpa [Function.comp_def, hterm] using this
  simp_rw [hterm]
  split_ifs with hpN
  · have hgeo : ∀ e : ℕ, a ((p : ℕ) ^ e) * x ^ e = (a p * x) ^ e := by
      intro e; rw [hbad p hp hpN e, mul_pow]
    simp_rw [hgeo] at hb ⊢
    rw [tsum_geometric_of_norm_lt_one (summable_geometric_iff_norm_lt_one.mp hb)]
  · set S := ∑' e : ℕ, a ((p : ℕ) ^ e) * x ^ e with hS
    have hb1 : Summable (fun e : ℕ => a ((p : ℕ) ^ (e + 1)) * x ^ (e + 1)) :=
      (summable_nat_add_iff 1).mpr hb
    have hb2 : Summable (fun e : ℕ => a ((p : ℕ) ^ (e + 2)) * x ^ (e + 2)) :=
      (summable_nat_add_iff 2).mpr hb
    have hS1 : S = 1 + ∑' e : ℕ, a ((p : ℕ) ^ (e + 1)) * x ^ (e + 1) := by
      rw [hS, hb.tsum_eq_zero_add]; simp [h1]
    have hS2 : ∑' e : ℕ, a ((p : ℕ) ^ (e + 1)) * x ^ (e + 1) =
        a p * x + ∑' e : ℕ, a ((p : ℕ) ^ (e + 2)) * x ^ (e + 2) := by
      rw [hb1.tsum_eq_zero_add]; simp
    have hrec : ∀ e : ℕ, a ((p : ℕ) ^ (e + 2)) * x ^ (e + 2) =
        (a p * x) * (a ((p : ℕ) ^ (e + 1)) * x ^ (e + 1)) -
          ((p : ℂ) ^ ((k : ℂ) - 1) * x ^ 2) * (a ((p : ℕ) ^ e) * x ^ e) := by
      intro e; rw [hgood p hp hpN e]; ring
    have hS3 : ∑' e : ℕ, a ((p : ℕ) ^ (e + 2)) * x ^ (e + 2) =
        (a p * x) * (S - 1) - ((p : ℂ) ^ ((k : ℂ) - 1) * x ^ 2) * S := by
      simp_rw [hrec]
      have hT : ∑' e : ℕ, a ((p : ℕ) ^ (e + 1)) * x ^ (e + 1) = S - 1 := by rw [hS1]; ring
      rw [(hb1.mul_left _).tsum_sub (hb.mul_left _), tsum_mul_left, tsum_mul_left, hT]
    have hpow : (p : ℂ) ^ ((k : ℂ) - 1 - 2 * s) = (p : ℂ) ^ ((k : ℂ) - 1) * x ^ 2 := by
      rw [hx, show (k : ℂ) - 1 - 2 * s = ((k : ℂ) - 1) + (-s + -s) by ring,
        cpow_add _ _ hp0, cpow_add _ _ hp0, sq]
    rw [hpow]
    symm
    apply eq_inv_of_mul_eq_one_left
    linear_combination hS1 + hS2 + hS3

/-! The card's whole-number worked examples, for `f = q ∏ (1 - qⁿ)² (1 - q¹¹ⁿ)²` of level 11
and the curve `y² + y = x³ - x²`. -/

-- The product multiplied out to `q¹³`: `a₁, …, a₁₃ = 1, -2, -1, 2, 1, 2, -2, 0, -2, -2, 1, -2, 4`.
example :
    ([1, 1, 11, 11, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12].foldl
      (fun (c : List ℤ) (st : ℕ) =>
        (List.range 13).map (fun i => c.getD i 0 - if st ≤ i then c.getD (i - st) 0 else 0))
      (1 :: List.replicate 12 0)) = [1, -2, -1, 2, 1, 2, -2, 0, -2, -2, 1, -2, 4] := by
  decide

-- Points of the curve mod p, the point `O` included, and `a_p = p + 1 - #E(F_p)`.
example : (Finset.univ.filter (fun xy : ZMod 2 × ZMod 2 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 5 := by decide
example : (Finset.univ.filter (fun xy : ZMod 3 × ZMod 3 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 5 := by decide
example : (Finset.univ.filter (fun xy : ZMod 5 × ZMod 5 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 5 := by decide
example : (Finset.univ.filter (fun xy : ZMod 7 × ZMod 7 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 10 := by decide
example : (Finset.univ.filter (fun xy : ZMod 11 × ZMod 11 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 11 := by decide
example : (Finset.univ.filter (fun xy : ZMod 13 × ZMod 13 =>
    xy.2 ^ 2 + xy.2 = xy.1 ^ 3 - xy.1 ^ 2)).card + 1 = 10 := by decide
example : ((2 + 1 - 5 : ℤ), (3 + 1 - 5 : ℤ), (5 + 1 - 5 : ℤ), (7 + 1 - 10 : ℤ), (13 + 1 - 10 : ℤ))
    = (-2, -1, 1, -2, 4) := by decide

-- The Euler factor at 2, `1/(1 + 2X + 2X²)`, as a series: `e_(r+2) = -2 e_(r+1) - 2 e_r`.
example :
    ((List.range 9).foldl (fun (e : List ℤ) _ => e ++ [-2 * e.getD (e.length - 1) 0 - 2 * e.getD (e.length - 2) 0])
      [1, -2]) = [1, -2, 2, 0, -4, 8, -8, 0, 16, -32, 32] := by
  decide

-- `a₄ = a₂² - 2 = 2`, and the good-prime factor at 11 would wrongly predict `a₁₂₁ = 1 - 11 = -10`.
example : ((-2 : ℤ) ^ 2 - 2, (1 : ℤ) ^ 2 - 11) = (2, -10) := by decide

-- The Euler factor at 2 at `s = 2`: `1/(1 + 2/4 + 2/16) = 8/13`.
example : (1 : ℚ) / (1 + 2 / 4 + 2 / 16) = 8 / 13 := by norm_num

-- The sign at level 11: `ε = -1`, `k = 2`, so `w = ε i² = +1`.
example : (-1 : ℂ) * I ^ (2 : ℤ) = 1 := by norm_num

-- The genus count `1 + μ/12 - ν₂/4 - ν₃/3 - ν_∞/2`: dimension 1 at level 11, 2 at level 22.
example : (1 + 12 / 12 - 0 / 4 - 0 / 3 - 2 / 2 : ℚ) = 1 ∧ (1 + 36 / 12 - 0 / 4 - 0 / 3 - 4 / 2 : ℚ) = 2 := by
  norm_num

#print axioms completed_L_function_entire_and_functional_equation
#print axioms completed_L_function_eq_gamma_mul_dirichlet_series
#print axioms euler_product_of_hecke_rules
