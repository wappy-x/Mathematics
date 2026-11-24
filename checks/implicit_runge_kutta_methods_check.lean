-- Implicit Runge-Kutta: the two-stage Gauss and Radau IIA tableaux give stability functions of size at most 1 on the closed left half-plane, Radau IIA's tends to 0 and Gauss's to 1 far out on the negative axis, and an algebraically stable method never moves two solutions of a contractive problem apart.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.RingTheory.Polynomial.ShiftedLegendre
import Mathlib.Tactic

open Matrix Filter Topology

/-! The card's notation.
* An `s`-stage Runge-Kutta method is a Butcher tableau: a matrix `A`, weights `b` and nodes `c`.
* Its stability function is `R(z) = 1 + z bᵀ (I - zA)⁻¹ 𝟙`, with `𝟙` the column of ones; one step
  multiplies `y` by `R(z)` on the test equation `y' = λ y`, where `z = hλ`. The inverse is Mathlib's
  matrix inverse.
* The two-stage Gauss tableau has `A = [[1/4, 1/4 - √3/6], [1/4 + √3/6, 1/4]]`, `b = (1/2, 1/2)`.
* The two-stage Radau IIA tableau has `A = [[5/12, -1/12], [3/4, 1/4]]`, `b = (3/4, 1/4)`.
* The algebraic stability matrix is `𝓜 = BA + AᵀB - bbᵀ`, with `B` the diagonal matrix of weights;
  "no negative eigenvalue" for this symmetric matrix is Mathlib's `Matrix.PosSemidef`. -/

/-- The stability function `R(z) = 1 + z bᵀ (I - zA)⁻¹ 𝟙` of a tableau with matrix `A` and
weights `b`. -/
noncomputable def rkStab {s : ℕ} (A : Matrix (Fin s) (Fin s) ℂ) (b : Fin s → ℂ) (z : ℂ) : ℂ :=
  1 + z * (b ⬝ᵥ ((1 - z • A)⁻¹ *ᵥ fun _ => 1))

/-- The two-stage Gauss tableau's matrix, from collocation at `1/2 ∓ √3/6`. -/
noncomputable def gaussA : Matrix (Fin 2) (Fin 2) ℂ :=
  !![1 / 4, 1 / 4 - (Real.sqrt 3 : ℂ) / 6; 1 / 4 + (Real.sqrt 3 : ℂ) / 6, 1 / 4]

/-- The two-stage Gauss weights. -/
noncomputable def gaussB : Fin 2 → ℂ := ![1 / 2, 1 / 2]

/-- The two-stage Radau IIA tableau's matrix, from collocation at `1/3` and `1`. -/
noncomputable def radauA : Matrix (Fin 2) (Fin 2) ℂ := !![5 / 12, -1 / 12; 3 / 4, 1 / 4]

/-- The two-stage Radau IIA weights. -/
noncomputable def radauB : Fin 2 → ℂ := ![3 / 4, 1 / 4]

lemma rkStab_two (A : Matrix (Fin 2) (Fin 2) ℂ) (b : Fin 2 → ℂ) (z : ℂ)
    (hd : (1 - z * A 0 0) * (1 - z * A 1 1) - z ^ 2 * (A 0 1 * A 1 0) ≠ 0) :
    rkStab A b z * ((1 - z * A 0 0) * (1 - z * A 1 1) - z ^ 2 * (A 0 1 * A 1 0)) =
      ((1 - z * A 0 0) * (1 - z * A 1 1) - z ^ 2 * (A 0 1 * A 1 0)) +
      z * (b 0 * ((1 - z * A 1 1) + z * A 0 1) + b 1 * (z * A 1 0 + (1 - z * A 0 0))) := by
  have hdet : (1 - z • A).det = (1 - z * A 0 0) * (1 - z * A 1 1) - z ^ 2 * (A 0 1 * A 1 0) := by
    rw [det_fin_two]; simp; ring
  unfold rkStab
  rw [inv_def, hdet, Ring.inverse_eq_inv', adjugate_fin_two]
  generalize (1 - z * A 0 0) * (1 - z * A 1 1) - z ^ 2 * (A 0 1 * A 1 0) = d at hd ⊢
  simp [dotProduct, mulVec, Fin.sum_univ_two]
  field_simp

lemma gauss_stab_mul (z : ℂ) (h : 1 - z / 2 + z ^ 2 / 12 ≠ 0) :
    rkStab gaussA gaussB z * (1 - z / 2 + z ^ 2 / 12) = 1 + z / 2 + z ^ 2 / 12 := by
  have hs : ((Real.sqrt 3 : ℝ) : ℂ) ^ 2 = 3 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  have hd : (1 - z * gaussA 0 0) * (1 - z * gaussA 1 1) - z ^ 2 * (gaussA 0 1 * gaussA 1 0)
      = 1 - z / 2 + z ^ 2 / 12 := by
    simp [gaussA]; linear_combination (z ^ 2 / 36) * hs
  have := rkStab_two gaussA gaussB z (hd ▸ h)
  rw [hd] at this
  rw [this]; simp [gaussA, gaussB]; ring

lemma radau_stab_mul (z : ℂ) (h : 1 - 2 * z / 3 + z ^ 2 / 6 ≠ 0) :
    rkStab radauA radauB z * (1 - 2 * z / 3 + z ^ 2 / 6) = 1 + z / 3 := by
  have hd : (1 - z * radauA 0 0) * (1 - z * radauA 1 1) - z ^ 2 * (radauA 0 1 * radauA 1 0)
      = 1 - 2 * z / 3 + z ^ 2 / 6 := by
    simp [radauA]; ring
  have := rkStab_two radauA radauB z (hd ▸ h)
  rw [hd] at this
  rw [this]; simp [radauA, radauB]; ring

lemma norm_le_one_of_mul {R d n : ℂ} (hd : d ≠ 0) (h : R * d = n) (hn : Complex.normSq n ≤ Complex.normSq d) :
    ‖R‖ ≤ 1 := by
  have h1 : ‖n‖ ≤ ‖d‖ := by
    have : ‖n‖ ^ 2 ≤ ‖d‖ ^ 2 := by rw [Complex.sq_norm, Complex.sq_norm]; exact hn
    nlinarith [norm_nonneg n, norm_nonneg d]
  have h2 : 0 < ‖d‖ := norm_pos_iff.mpr hd
  rw [← h, norm_mul] at h1
  nlinarith [norm_nonneg R]

lemma radau_real (x : ℝ) :
    rkStab radauA radauB (x : ℂ) = (((1 + x / 3) / (1 - 2 * x / 3 + x ^ 2 / 6) : ℝ) : ℂ) := by
  have hpos : (0 : ℝ) < 1 - 2 * x / 3 + x ^ 2 / 6 := by nlinarith [sq_nonneg (x - 2)]
  have hne : (1 - 2 * (x : ℂ) / 3 + (x : ℂ) ^ 2 / 6) ≠ 0 := by
    exact_mod_cast hpos.ne'
  have := radau_stab_mul (x : ℂ) hne
  push_cast
  rw [eq_div_iff hne, this]

lemma gauss_real (x : ℝ) :
    rkStab gaussA gaussB (x : ℂ) = (((1 + x / 2 + x ^ 2 / 12) / (1 - x / 2 + x ^ 2 / 12) : ℝ) : ℂ) := by
  have hpos : (0 : ℝ) < 1 - x / 2 + x ^ 2 / 12 := by nlinarith [sq_nonneg (x - 3)]
  have hne : (1 - (x : ℂ) / 2 + (x : ℂ) ^ 2 / 12) ≠ 0 := by
    exact_mod_cast hpos.ne'
  have := gauss_stab_mul (x : ℂ) hne
  push_cast
  rw [eq_div_iff hne, this]

lemma quad_form_nonneg {s n : ℕ} (M : Matrix (Fin s) (Fin s) ℝ) (hM : M.PosSemidef)
    (D : Fin s → EuclideanSpace ℝ (Fin n)) :
    0 ≤ ∑ i, ∑ j, M i j * inner ℝ (D i) (D j) := by
  have hk : ∀ k : Fin n, (0 : ℝ) ≤ ∑ i : Fin s, ∑ j : Fin s, M i j * ((D i k : ℝ) * (D j k : ℝ)) := by
    intro k
    have := hM.dotProduct_mulVec_nonneg (fun i => D i k)
    simp only [star_trivial, dotProduct, mulVec, Finset.mul_sum] at this
    refine this.trans_eq ?_
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    ring
  have : ∑ i, ∑ j, M i j * inner ℝ (D i) (D j) = ∑ k : Fin n, ∑ i : Fin s, ∑ j : Fin s, M i j * ((D i k : ℝ) * (D j k : ℝ)) := by
    calc ∑ i, ∑ j, M i j * inner ℝ (D i) (D j)
        = ∑ i : Fin s, ∑ j : Fin s, ∑ k : Fin n, M i j * ((D i k : ℝ) * (D j k : ℝ)) := by
          refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
          rw [PiLp.inner_apply, Finset.mul_sum]
          refine Finset.sum_congr rfl fun k _ => ?_
          rw [real_inner_eq_re_inner]; simp only [RCLike.inner_apply, conj_trivial, RCLike.re_to_real]
          ring
      _ = ∑ i : Fin s, ∑ k : Fin n, ∑ j : Fin s, M i j * ((D i k : ℝ) * (D j k : ℝ)) :=
          Finset.sum_congr rfl fun i _ => Finset.sum_comm
      _ = _ := Finset.sum_comm
  rw [this]
  exact Finset.sum_nonneg fun k _ => hk k

/-- Step 4 of the card: the two-stage Gauss and Radau IIA methods are A-stable. For every `z`
in the closed left half-plane, one step on `y' = λ y` with `z = hλ` multiplies `y` by a factor
`R(z)` of size at most 1. -/
theorem gauss_and_radau_two_stage_A_stable (z : ℂ) (hz : z.re ≤ 0) :
    ‖rkStab gaussA gaussB z‖ ≤ 1 ∧ ‖rkStab radauA radauB z‖ ≤ 1 := by
  obtain ⟨x, y⟩ := z
  simp only at hz
  have hG : (1 - (⟨x, y⟩ : ℂ) / 2 + (⟨x, y⟩ : ℂ) ^ 2 / 12) ≠ 0 := by
    intro h0
    have h1 := congrArg Complex.re h0
    have h2 := congrArg Complex.im h0
    simp [pow_two] at h1 h2
    nlinarith [sq_nonneg y, sq_nonneg x]
  have hR : (1 - 2 * (⟨x, y⟩ : ℂ) / 3 + (⟨x, y⟩ : ℂ) ^ 2 / 6) ≠ 0 := by
    intro h0
    have h1 := congrArg Complex.re h0
    have h2 := congrArg Complex.im h0
    simp [pow_two] at h1 h2
    nlinarith [sq_nonneg y, sq_nonneg x]
  refine ⟨norm_le_one_of_mul hG (gauss_stab_mul _ hG) ?_,
    norm_le_one_of_mul hR (radau_stab_mul _ hR) ?_⟩
  · simp [Complex.normSq_apply, pow_two]
    nlinarith [sq_nonneg y, sq_nonneg x, mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg x),
      mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg y)]
  · simp [Complex.normSq_apply, pow_two]
    nlinarith [sq_nonneg y, sq_nonneg x, mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg x),
      mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg y), sq_nonneg (x * y), sq_nonneg (x ^ 2 - y ^ 2),
      mul_nonneg (mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg x)) (sq_nonneg x),
      mul_nonneg (mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg y)) (sq_nonneg x),
      mul_nonneg (mul_nonneg (neg_nonneg.mpr hz) (sq_nonneg y)) (sq_nonneg y)]

/-- Step 4 of the card, far out on the negative axis: Radau IIA's factor `R(z)` tends to 0 as
`z → -∞` (so, with A-stability, it is L-stable), while Gauss's tends to 1, so Gauss keeps a fast
part alive. -/
theorem radau_tends_to_zero_and_gauss_to_one :
    Tendsto (fun x : ℝ => rkStab radauA radauB (x : ℂ)) atBot (𝓝 0) ∧
    Tendsto (fun x : ℝ => rkStab gaussA gaussB (x : ℂ)) atBot (𝓝 1) := by
  have ht : Tendsto (fun x : ℝ => x⁻¹) atBot (𝓝 0) := tendsto_inv_atBot_zero
  have hneg : ∀ᶠ x : ℝ in atBot, x < 0 := eventually_lt_atBot 0
  constructor
  · have hg : Tendsto (fun x : ℝ => (x⁻¹ ^ 2 + x⁻¹ / 3) / (x⁻¹ ^ 2 - 2 * x⁻¹ / 3 + 1 / 6)) atBot
        (𝓝 (((0 : ℝ) ^ 2 + 0 / 3) / (0 ^ 2 - 2 * 0 / 3 + 1 / 6))) :=
      ((ht.pow 2).add (ht.div_const 3)).div
        (((ht.pow 2).sub ((ht.const_mul 2).div_const 3)).add tendsto_const_nhds) (by norm_num)
    have hr : Tendsto (fun x : ℝ => (1 + x / 3) / (1 - 2 * x / 3 + x ^ 2 / 6)) atBot (𝓝 0) := by
      refine (hg.congr' ?_).trans (by norm_num)
      filter_upwards [hneg] with x hx
      have hx0 : x ≠ 0 := hx.ne
      have hpos : (0 : ℝ) < 1 - 2 * x / 3 + x ^ 2 / 6 := by nlinarith [sq_nonneg (x - 2)]
      field_simp
    have h2 := (Complex.continuous_ofReal.tendsto 0).comp hr
    rw [Complex.ofReal_zero] at h2
    exact h2.congr fun x => (radau_real x).symm
  · have hg : Tendsto (fun x : ℝ => (x⁻¹ ^ 2 + x⁻¹ / 2 + 1 / 12) / (x⁻¹ ^ 2 - x⁻¹ / 2 + 1 / 12)) atBot
        (𝓝 (((0 : ℝ) ^ 2 + 0 / 2 + 1 / 12) / (0 ^ 2 - 0 / 2 + 1 / 12))) :=
      (((ht.pow 2).add (ht.div_const 2)).add tendsto_const_nhds).div
        (((ht.pow 2).sub (ht.div_const 2)).add tendsto_const_nhds) (by norm_num)
    have hr : Tendsto (fun x : ℝ => (1 + x / 2 + x ^ 2 / 12) / (1 - x / 2 + x ^ 2 / 12)) atBot (𝓝 1) := by
      refine (hg.congr' ?_).trans (by norm_num)
      filter_upwards [hneg] with x hx
      have hx0 : x ≠ 0 := hx.ne
      have hpos : (0 : ℝ) < 1 - x / 2 + x ^ 2 / 12 := by nlinarith [sq_nonneg (x - 3)]
      field_simp
    have h2 := (Complex.continuous_ofReal.tendsto 1).comp hr
    rw [Complex.ofReal_one] at h2
    exact h2.congr fun x => (gauss_real x).symm

/-- Step 5 of the card: algebraic stability gives B-stability. Take an `s`-stage tableau with
every weight `bᵢ ≥ 0` and `𝓜 = BA + AᵀB - bbᵀ` positive semidefinite, a step `h ≥ 0`, and a
contractive rate law, `⟨f(t, u) - f(t, v), u - v⟩ ≤ 0`. Run one step from `y` and from `w`, with
stages solving `Yᵢ = y + h Σⱼ aᵢⱼ f(t + cⱼh, Yⱼ)` and likewise for `W`. Then the two new values are
no farther apart than `y` and `w` were. -/
theorem algebraically_stable_step_contracts {s n : ℕ} (A : Matrix (Fin s) (Fin s) ℝ)
    (b c : Fin s → ℝ) (hb : ∀ i, 0 ≤ b i)
    (hM : (diagonal b * A + Aᵀ * diagonal b - vecMulVec b b).PosSemidef)
    (f : ℝ → EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (hf : ∀ t u v, inner ℝ (f t u - f t v) (u - v) ≤ 0)
    (t h : ℝ) (hh : 0 ≤ h) (y w : EuclideanSpace ℝ (Fin n))
    (Y W : Fin s → EuclideanSpace ℝ (Fin n))
    (hY : ∀ i, Y i = y + h • ∑ j, A i j • f (t + c j * h) (Y j))
    (hW : ∀ i, W i = w + h • ∑ j, A i j • f (t + c j * h) (W j)) :
    ‖(y + h • ∑ i, b i • f (t + c i * h) (Y i)) - (w + h • ∑ i, b i • f (t + c i * h) (W i))‖
      ≤ ‖y - w‖ := by
  set D : Fin s → EuclideanSpace ℝ (Fin n) :=
    fun i => f (t + c i * h) (Y i) - f (t + c i * h) (W i) with hD
  set e := y - w with he
  have hdiff : (y + h • ∑ i, b i • f (t + c i * h) (Y i)) - (w + h • ∑ i, b i • f (t + c i * h) (W i))
      = e + h • ∑ i, b i • D i := by
    simp only [hD, he, smul_sub, Finset.sum_sub_distrib]; abel
  have hYW : ∀ i, Y i - W i = e + h • ∑ j, A i j • D j := by
    intro i
    rw [hY i, hW i]
    simp only [hD, he, smul_sub, Finset.sum_sub_distrib]; abel
  set G : Fin s → Fin s → ℝ := fun i j => inner ℝ (D i) (D j) with hG
  have hGs : ∀ i j, G j i = G i j := fun i j => real_inner_comm _ _
  set P := ∑ i, b i * inner ℝ (D i) (Y i - W i) with hP
  set T1 := ∑ i, ∑ j, b i * A i j * G i j with hT1
  set T2 := ∑ i, ∑ j, b i * b j * G i j with hT2
  have hPle : P ≤ 0 :=
    Finset.sum_nonpos fun i _ => mul_nonpos_of_nonneg_of_nonpos (hb i) (hf _ _ _)
  have hQ : 0 ≤ 2 * T1 - T2 := by
    have := quad_form_nonneg _ hM D
    refine this.trans_eq ?_
    have hswap : ∑ i, ∑ j, A j i * b j * G i j = T1 := by
      rw [hT1, Finset.sum_comm]
      refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
      rw [hGs]; ring
    rw [two_mul]
    nth_rw 2 [← hswap]
    rw [hT1, hT2, ← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun j _ => ?_
    simp [diagonal, Matrix.mul_apply, vecMulVec, hG]
    ring
  have hinner_e : inner ℝ e (∑ i, b i • D i) = P - h * T1 := by
    have : ∀ i, inner ℝ e (D i) = inner ℝ (D i) (Y i - W i) - h * ∑ j, A i j * G i j := by
      intro i
      rw [hYW i, inner_add_right, inner_smul_right, inner_sum, real_inner_comm]
      simp only [real_inner_smul_right, hG]
      ring
    rw [inner_sum]
    simp only [real_inner_smul_right, this, hP, hT1, mul_sub, Finset.sum_sub_distrib, Finset.mul_sum]
    congr 1
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    ring
  have hnormS : ‖∑ i, b i • D i‖ ^ 2 = T2 := by
    rw [← real_inner_self_eq_norm_sq, sum_inner]
    simp only [real_inner_smul_left, inner_sum, real_inner_smul_right, hT2, hG]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    ring
  have key : ‖e + h • ∑ i, b i • D i‖ ^ 2 = ‖e‖ ^ 2 + 2 * h * P - h ^ 2 * (2 * T1 - T2) := by
    rw [norm_add_sq_real, inner_smul_right, hinner_e, norm_smul, mul_pow, hnormS,
      Real.norm_eq_abs, sq_abs]
    ring
  rw [hdiff]
  have hsq : ‖e + h • ∑ i, b i • D i‖ ^ 2 ≤ ‖e‖ ^ 2 := by
    rw [key]
    nlinarith [mul_nonpos_of_nonneg_of_nonpos hh hPle, mul_nonneg (sq_nonneg h) hQ]
  nlinarith [norm_nonneg e, norm_nonneg (e + h • ∑ i, b i • D i)]

-- The Gauss nodes are the zeros of the shifted Legendre polynomial 1 - 6x + 6x² (Mathlib's P₂).
example : (Polynomial.shiftedLegendre 2).coeff 0 = 1 ∧ (Polynomial.shiftedLegendre 2).coeff 1 = -6 ∧
    (Polynomial.shiftedLegendre 2).coeff 2 = 6 := by
  simp [Polynomial.shiftedLegendre, Finset.sum_range_succ, Polynomial.coeff_X_pow,
    Polynomial.coeff_one]
  decide

-- Radau nodes: (6x² - 6x + 1) - (2x - 1) = 2(3x - 1)(x - 1), zero at 1/3 and 1.
example (x : ℚ) : (6 * x ^ 2 - 6 * x + 1) - (2 * x - 1) = 2 * (3 * x - 1) * (x - 1) := by ring

-- Radau a₁₁: the integral of (τ - 1)/(1/3 - 1) from 0 to 1/3 is (3/2)(1/3 - 1/18) = 5/12.
example : (3 / 2 : ℚ) * (1 / 3 - 1 / 18) = 5 / 12 := by norm_num

-- Gauss R(-100) = (1 - 50 + 2500/3)/(1 + 50 + 2500/3) = 2353/2653.
example : ((1 : ℚ) + (-100) / 2 + (-100) ^ 2 / 12) / (1 - (-100) / 2 + (-100) ^ 2 / 12) = 2353 / 2653 := by
  norm_num

-- Radau R(-100) = (1 - 100/3)/(1 + 200/3 + 10000/6) = -97/5203.
example : ((1 : ℚ) + (-100) / 3) / (1 - 2 * (-100) / 3 + (-100) ^ 2 / 6) = -97 / 5203 := by norm_num

-- The same Radau R(-100) from the tableau, 1 + z bᵀ(I - zA)⁻¹𝟙 by Cramer's rule.
example : let z : ℚ := -100
    let m11 := 1 - z * (5 / 12); let m12 := -z * (-1 / 12); let m21 := -z * (3 / 4)
    let m22 := 1 - z * (1 / 4)
    1 + z * ((3 / 4) * (m22 - m12) + (1 / 4) * (m11 - m21)) / (m11 * m22 - m12 * m21) = -97 / 5203 := by
  norm_num

-- Radau IIA's algebraic stability matrix BA + AᵀB - bbᵀ is [[1/16, -1/16], [-1/16, 1/16]].
example : (3 / 4 : ℚ) * (5 / 12) + (3 / 4) * (5 / 12) - (3 / 4) * (3 / 4) = 1 / 16 ∧
    (3 / 4 : ℚ) * (-1 / 12) + (1 / 4) * (3 / 4) - (3 / 4) * (1 / 4) = -1 / 16 ∧
    (1 / 4 : ℚ) * (1 / 4) + (1 / 4) * (1 / 4) - (1 / 4) * (1 / 4) = 1 / 16 := by norm_num

-- Gauss's off-diagonal entry of BA + AᵀB - bbᵀ is 0 (all its entries are 0).
example : (1 / 2 : ℝ) * (1 / 4 - Real.sqrt 3 / 6) + (1 / 2) * (1 / 4 + Real.sqrt 3 / 6)
    - (1 / 2) * (1 / 2) = 0 := by ring

-- The fold's Radau bound on the imaginary axis: |D|² - |N|² = y⁴/36.
example (y : ℚ) : ((1 - y ^ 2 / 6) ^ 2 + (2 * y / 3) ^ 2) - (1 + (y / 3) ^ 2) = y ^ 4 / 36 := by ring

#print axioms rkStab_two
#print axioms gauss_stab_mul
#print axioms radau_stab_mul
#print axioms norm_le_one_of_mul
#print axioms radau_real
#print axioms gauss_real
#print axioms quad_form_nonneg
#print axioms gauss_and_radau_two_stage_A_stable
#print axioms radau_tends_to_zero_and_gauss_to_one
#print axioms algebraically_stable_step_contracts
