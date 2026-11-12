-- Runge's phenomenon: Chebyshev nodes give the smallest possible node product on −1 to 1, that product is T_(n+1)/2^n, and the degree-20 bell 1/(1 + 25x²) has an exact interpolation error formula.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.RootsExtrema
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.Extremal
import Mathlib.Topology.Algebra.Polynomial

open Polynomial Real

theorem helper_T (n : ℕ) (x : ℝ) :
    ∏ j : Fin (n + 1), (x - Real.cos ((2 * ((j : ℕ) : ℝ) + 1) * π / (2 * ((n : ℝ) + 1))))
      = (Chebyshev.T ℝ ((n : ℤ) + 1)).eval x / 2 ^ n := by
  have hcast : ((n : ℤ) + 1) = ((n + 1 : ℕ) : ℤ) := by push_cast; ring
  rw [hcast]
  set P := Chebyshev.T ℝ ((n + 1 : ℕ) : ℤ) with hP
  have hroots := Polynomial.Chebyshev.roots_T_real (n + 1)
  have hnd := Polynomial.Chebyshev.roots_T_real_nodup (n + 1)
  have hinj : Set.InjOn (fun k : ℕ => cos ((2 * k + 1) * π / (2 * ((n + 1 : ℕ) : ℝ))))
      (Finset.range (n + 1)) := (Finset.range (n + 1)).nodup_map_iff_injOn.mp hnd
  have hcard : Multiset.card P.roots = P.natDegree := by
    rw [hP, hroots, Chebyshev.natDegree_T, Finset.card_val, Finset.card_image_of_injOn hinj,
      Finset.card_range, Int.natAbs_natCast]
  have key := C_leadingCoeff_mul_prod_multiset_X_sub_C hcard
  have hlc : P.leadingCoeff = 2 ^ n := by
    rw [hP, Chebyshev.leadingCoeff_T, Int.natAbs_natCast, Nat.add_sub_cancel]
  rw [← key, hlc, hP, hroots, eval_mul, eval_C]
  rw [Finset.image_val_of_injOn hinj]
  rw [Multiset.map_map, eval_multiset_prod, Multiset.map_map]
  simp only [Function.comp_def, eval_sub, eval_X, eval_C]
  rw [← Finset.prod_eq_multiset_prod, Fin.prod_univ_eq_prod_range
    (fun k : ℕ => x - cos ((2 * (k : ℝ) + 1) * π / (2 * ((n : ℝ) + 1))))]
  push_cast
  field_simp
  refine Finset.prod_congr rfl fun k _ => ?_
  ring_nf

#print axioms helper_T

/-- Chebyshev nodes keep the node product small, and no nodes do better: with the n + 1
Chebyshev nodes x_j = cos((2j + 1)π / (2(n + 1))), the node product
ω(x) = (x − x_0)⋯(x − x_n) never exceeds 2^(−n) in size on −1 to 1; and for any n + 1 nodes
whatever, the node product reaches at least 2^(−n) in size somewhere on −1 to 1. -/
theorem chebyshev_nodes_minimize_node_product (n : ℕ) :
    (∀ x ∈ Set.Icc (-1 : ℝ) 1,
      |∏ j : Fin (n + 1), (x - Real.cos ((2 * ((j : ℕ) : ℝ) + 1) * π / (2 * ((n : ℝ) + 1))))|
        ≤ 1 / 2 ^ n) ∧
    (∀ y : Fin (n + 1) → ℝ, ∃ x ∈ Set.Icc (-1 : ℝ) 1, 1 / 2 ^ n ≤ |∏ j, (x - y j)|) := by
  refine ⟨fun x hx => ?_, fun y => ?_⟩
  · rw [helper_T, abs_div, abs_of_pos (by positivity : (0:ℝ) < 2 ^ n)]
    apply div_le_div_of_nonneg_right _ (by positivity)
    exact Polynomial.Chebyshev.abs_eval_T_real_le_one _ (abs_le.mpr ⟨hx.1, hx.2⟩)
  · set Q : ℝ[X] := ∏ j, (X - C (y j)) with hQ
    have hQe : ∀ x, Q.eval x = ∏ j, (x - y j) := fun x => by
      simp [hQ, eval_prod]
    have hQm : Q.Monic := monic_prod_X_sub_C y Finset.univ
    have hQd : Q.natDegree = n + 1 := by
      rw [hQ, natDegree_prod_of_monic _ _ (fun j _ => monic_X_sub_C (y j))]
      simp
    by_contra! hlt
    obtain ⟨x0, hx0, hmax⟩ := isCompact_Icc.exists_isMaxOn
      (Set.nonempty_Icc.mpr (by norm_num : (-1:ℝ) ≤ 1))
      (Q.continuous.abs.continuousOn : ContinuousOn (fun x => |Q.eval x|) (Set.Icc (-1) 1))
    set M := |Q.eval x0|
    have hM : M < 1 / 2 ^ n := by
      have := hlt x0 hx0; rwa [← hQe] at this
    have hM0 : 0 ≤ M := abs_nonneg _
    set c := (M + 1 / 2 ^ n) / 2 with hc
    have hc0 : 0 < c := by positivity
    have hMc : M < c := by rw [hc]; linarith
    have hcn : c < 1 / 2 ^ n := by rw [hc]; linarith
    have hPdeg : (C (1 / c) * Q).degree ≤ ((n + 1 : ℕ) : WithBot ℕ) := by
      rw [degree_C_mul (by positivity), degree_eq_natDegree hQm.ne_zero, hQd]
    have hPbnd : ∀ x ∈ Set.Icc (-1:ℝ) 1, |(C (1 / c) * Q).eval x| ≤ 1 := by
      intro x hx
      rw [eval_mul, eval_C, abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / c)]
      have : |Q.eval x| ≤ M := hmax hx
      rw [one_div_mul_eq_div, div_le_one hc0]
      linarith
    have hle := Polynomial.Chebyshev.leadingCoeff_le_of_forall_abs_le_one hPdeg hPbnd
    rw [leadingCoeff_mul, leadingCoeff_C, hQm.leadingCoeff, mul_one, Nat.add_sub_cancel] at hle
    have : (2:ℝ) ^ n < 1 / c := by
      rw [lt_one_div (by positivity) hc0]; exact hcn
    linarith

/-- At the Chebyshev nodes the node product is a scaled Chebyshev polynomial:
ω(x) = T_(n+1)(x) / 2^n for every real x. -/
theorem chebyshev_node_product_eq_T (n : ℕ) (x : ℝ) :
    ∏ j : Fin (n + 1), (x - Real.cos ((2 * ((j : ℕ) : ℝ) + 1) * π / (2 * ((n : ℝ) + 1))))
      = (Chebyshev.T ℝ ((n : ℤ) + 1)).eval x / 2 ^ n := by
  rw [helper_T]

/-- The exact error formula for the bell f(x) = 1/(1 + 25x²): take 21 nodes placed
symmetrically about 0, namely 0 and ±x_k for ten distinct positive x_k, and let p be the
polynomial of degree at most 20 through f at all 21 nodes. Then
f(x) − p(x) = −x ω(x) / (P (x² + 0.04)), where ω(x) is the node product and
P = ∏ (x_k² + 0.04) over the ten positive nodes. -/
theorem runge_bell_exact_error (f : ℝ → ℝ) (hf : ∀ x, f x = 1 / (1 + 25 * x ^ 2))
    (s : Fin 10 → ℝ) (hs_pos : ∀ k, 0 < s k) (hs_inj : Function.Injective s)
    (p : ℝ[X]) (hp_deg : p.degree ≤ 20)
    (hp_zero : p.eval 0 = f 0)
    (hp_pos : ∀ k, p.eval (s k) = f (s k)) (hp_neg : ∀ k, p.eval (-s k) = f (-s k))
    (x : ℝ) :
    f x - p.eval x
      = -(x * (x * ∏ k, ((x - s k) * (x + s k))))
          / ((∏ k, (s k ^ 2 + 1 / 25)) * (x ^ 2 + 1 / 25)) := by
  set P : ℝ := ∏ k, (s k ^ 2 + 1 / 25) with hP
  have hP0 : 0 < P := Finset.prod_pos fun k _ => by positivity
  have hPc : ((P : ℝ) : ℂ) = ∏ k, (((s k : ℝ) : ℂ) ^ 2 + 1 / 25) := by
    rw [hP]; push_cast; rfl
  have hPc0 : ((P : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hP0.ne'
  set pc : ℂ[X] := p.map Complex.ofRealHom with hpc
  have hpce : ∀ z : ℝ, pc.eval (z : ℂ) = ((p.eval z : ℝ) : ℂ) := fun z =>
    eval_map_apply (p := p) (f := Complex.ofRealHom) z
  set W : ℂ[X] := X * ∏ k, ((X - C ((s k : ℝ) : ℂ)) * (X + C ((s k : ℝ) : ℂ))) with hW
  have hWe : ∀ z : ℂ, W.eval z = z * ∏ k, ((z - (s k : ℂ)) * (z + (s k : ℂ))) := fun z => by
    simp [hW, eval_prod]
  set R : ℂ[X] := (1 + 25 * X ^ 2) * pc - 1 - C (25 / ((P : ℝ) : ℂ)) * X * W with hR
  have hRe : ∀ z : ℂ, R.eval z = (1 + 25 * z ^ 2) * pc.eval z - 1
      - 25 / ((P : ℝ) : ℂ) * z * (z * ∏ k, ((z - (s k : ℂ)) * (z + (s k : ℂ)))) := fun z => by
    rw [hR, ← hWe]; simp
  -- degree bound
  have hpcd : pc.natDegree ≤ 20 := by
    rw [hpc]
    exact (natDegree_map_le).trans (natDegree_le_of_degree_le hp_deg)
  have hprodd : (∏ k : Fin 10, ((X - C ((s k : ℝ) : ℂ)) * (X + C ((s k : ℝ) : ℂ)))).natDegree
      ≤ 20 := by
    refine (natDegree_prod_le _ _).trans ?_
    have : ∀ k ∈ (Finset.univ : Finset (Fin 10)),
        ((X - C ((s k : ℝ) : ℂ)) * (X + C ((s k : ℝ) : ℂ))).natDegree ≤ 2 := fun k _ => by
      refine (natDegree_mul_le).trans ?_
      have h1 := natDegree_X_sub_C_le ((s k : ℝ) : ℂ)
      have h2 : (X + C ((s k : ℝ) : ℂ)).natDegree ≤ 1 := (natDegree_X_add_C _).le
      omega
    refine (Finset.sum_le_sum this).trans ?_
    simp
  have hRd : R.natDegree ≤ 22 := by
    rw [hR]
    refine (natDegree_sub_le _ _).trans (max_le ((natDegree_sub_le _ _).trans (max_le ?_ ?_)) ?_)
    · refine (natDegree_mul_le).trans ?_
      have : (1 + 25 * X ^ 2 : ℂ[X]).natDegree ≤ 2 := by compute_degree
      omega
    · simp
    · rw [hW]
      refine (natDegree_mul_le).trans ?_
      have : (C (25 / ((P : ℝ) : ℂ)) * X : ℂ[X]).natDegree ≤ 1 := by compute_degree
      have h2 := (natDegree_mul_le (p := (X : ℂ[X]))
        (q := ∏ k : Fin 10, ((X - C ((s k : ℝ) : ℂ)) * (X + C ((s k : ℝ) : ℂ)))))
      have : (X : ℂ[X]).natDegree ≤ 1 := natDegree_X_le
      omega
  -- the 23 roots
  let g : Option (Option (Option (Fin 10 ⊕ Fin 10))) → ℂ := fun o =>
    match o with
    | none => Complex.I / 5
    | some none => -Complex.I / 5
    | some (some none) => 0
    | some (some (some (Sum.inl k))) => ((s k : ℝ) : ℂ)
    | some (some (some (Sum.inr k))) => -((s k : ℝ) : ℂ)
  have hg : Function.Injective g := by
    rintro (_|_|_|(a|a)) (_|_|_|(b|b)) h <;>
      simp [g, Complex.ext_iff] at h ⊢ <;>
      first
      | (have := hs_pos a; have := hs_pos b; linarith)
      | (have := hs_pos a; linarith)
      | (have := hs_pos b; linarith)
      | exact hs_inj h
      | norm_num at h
  have hprodI : ∀ w : ℂ, w ^ 2 = -1 / 25 →
      ∏ k, ((w - (s k : ℂ)) * (w + (s k : ℂ))) = ((P : ℝ) : ℂ) := by
    intro w hw
    rw [Finset.prod_congr rfl (fun k _ => show (w - ((s k : ℝ) : ℂ)) * (w + ((s k : ℝ) : ℂ))
      = -(((s k : ℝ) : ℂ) ^ 2 + 1 / 25) by linear_combination hw), Finset.prod_neg, hPc]
    norm_num
  have hR0 : R = 0 := by
    refine eq_zero_of_natDegree_lt_card_of_eval_eq_zero R hg (fun i => ?_) (by simp; omega)
    rcases i with _|_|_|(k|k)
    · simp only [g]; rw [hRe]
      have hz : (Complex.I / 5) ^ 2 = -1 / 25 := by rw [div_pow, Complex.I_sq]; norm_num
      rw [hprodI _ hz, show 25 / ((P : ℝ) : ℂ) * (Complex.I / 5) * (Complex.I / 5 * ((P : ℝ) : ℂ))
        = 25 * (Complex.I / 5) ^ 2 by field_simp]
      linear_combination (25 * pc.eval (Complex.I / 5) - 25) * hz
    · simp only [g]; rw [hRe]
      have hz : (-Complex.I / 5) ^ 2 = -1 / 25 := by
        rw [div_pow, neg_sq, Complex.I_sq]; norm_num
      rw [hprodI _ hz, show 25 / ((P : ℝ) : ℂ) * (-Complex.I / 5) * (-Complex.I / 5 * ((P : ℝ) : ℂ))
        = 25 * (-Complex.I / 5) ^ 2 by field_simp]
      linear_combination (25 * pc.eval (-Complex.I / 5) - 25) * hz
    · simp only [g]; rw [hRe]
      have := hpce 0
      rw [Complex.ofReal_zero, hp_zero, hf] at this
      rw [this]; norm_num
    · simp only [g]; rw [hRe]
      rw [Finset.prod_eq_zero (Finset.mem_univ k) (by simp), hpce, hp_pos, hf]
      have : (1 : ℝ) + 25 * s k ^ 2 ≠ 0 := by positivity
      have h1 : (1 + 25 * s k ^ 2) * (1 / (1 + 25 * s k ^ 2)) - 1 = (0 : ℝ) := by
        rw [mul_one_div_cancel this]; ring
      rw [mul_zero, mul_zero, sub_zero]
      exact_mod_cast h1
    · simp only [g]; rw [hRe]
      rw [Finset.prod_eq_zero (Finset.mem_univ k) (by simp), ← Complex.ofReal_neg, hpce, hp_neg, hf]
      have : (1 : ℝ) + 25 * (-s k) ^ 2 ≠ 0 := by positivity
      have h1 : (1 + 25 * (-s k) ^ 2) * (1 / (1 + 25 * (-s k) ^ 2)) - 1 = (0 : ℝ) := by
        rw [mul_one_div_cancel this]; ring
      rw [mul_zero, mul_zero, sub_zero]
      exact_mod_cast h1
  have hx := hRe (x : ℂ)
  rw [hR0, eval_zero, hpce] at hx
  have hreal : (1 + 25 * x ^ 2) * p.eval x - 1
      - 25 / P * x * (x * ∏ k, ((x - s k) * (x + s k))) = 0 := by
    exact_mod_cast hx.symm
  have h25 : (1 : ℝ) + 25 * x ^ 2 ≠ 0 := by positivity
  have hE : p.eval x = (1 + 25 / P * x * (x * ∏ k, ((x - s k) * (x + s k)))) / (1 + 25 * x ^ 2) := by
    rw [eq_div_iff h25]; linarith
  rw [hf x, hE]
  have h25' : x ^ 2 + 1 / 25 ≠ 0 := by positivity
  field_simp
  ring

-- Cost per point at degree n = 20, from the card's Cost paragraph (flops).
-- Lagrange form: (n + 1)(4n + 2) = 1,722.
example : (20 + 1) * (4 * 20 + 2) = 1722 := by norm_num
-- Newton's form: 3n(n + 1)/2 = 630 once, then 3n = 60 per point.
example : 3 * 20 * (20 + 1) / 2 = 630 := by norm_num
example : 3 * 20 = 60 := by norm_num
-- Barycentric form: 5(n + 1) + 1 = 106.
example : 5 * (20 + 1) + 1 = 106 := by norm_num
-- Equal nodes for degree 20 on −1 to 1: the gap h = 2/20 = 1/10.
example : (2 : ℚ) / 20 = 1 / 10 := by norm_num

#print axioms chebyshev_nodes_minimize_node_product
#print axioms chebyshev_node_product_eq_T
#print axioms runge_bell_exact_error
