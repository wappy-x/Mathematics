-- Gradient descent: on the average squared miss of a weighted sum, gradient descent reaches the best weights from every start exactly when every curvature λ of the bowl has 0 < ηλ < 2, each step multiplies the error along a curvature-λ direction by 1 − ηλ, and the gradient of a uniformly random batch averages to the full gradient.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Data.Finset.Powerset
import Mathlib

open Filter Topology Matrix

theorem gd_G_add {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ)
    (G : (Fin p → ℝ) → Fin p → ℝ)
    (hG : ∀ θ, G θ = (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i)
    (H : Matrix (Fin p) (Fin p) ℝ) (hH : H = (2 / n : ℝ) • ∑ i, vecMulVec (x i) (x i))
    (θ d : Fin p → ℝ) : G (θ + d) = G θ + H *ᵥ d := by
  rw [hG, hG, hH, smul_mulVec, sum_mulVec, ← smul_add, ← Finset.sum_add_distrib]
  congr 1
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [vecMulVec_mulVec, op_smul_eq_smul, add_dotProduct, dotProduct_comm (x i) d,
    show θ ⬝ᵥ x i + d ⬝ᵥ x i - y i = (θ ⬝ᵥ x i - y i) + d ⬝ᵥ x i by ring, add_smul]

#print axioms gd_G_add

theorem gd_R_add {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ)
    (R : (Fin p → ℝ) → ℝ) (hR : ∀ θ, R θ = (1 / n : ℝ) * ∑ i, (θ ⬝ᵥ x i - y i) ^ 2)
    (G : (Fin p → ℝ) → Fin p → ℝ)
    (hG : ∀ θ, G θ = (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i)
    (H : Matrix (Fin p) (Fin p) ℝ) (hH : H = (2 / n : ℝ) • ∑ i, vecMulVec (x i) (x i))
    (θ d : Fin p → ℝ) :
    R (θ + d) = R θ + G θ ⬝ᵥ d + (1 / 2) * (d ⬝ᵥ H *ᵥ d) := by
  rw [hR, hR, hG, hH, smul_mulVec, sum_mulVec, smul_dotProduct, dotProduct_smul,
    sum_dotProduct, dotProduct_sum]
  simp only [vecMulVec_mulVec, op_smul_eq_smul, smul_dotProduct, dotProduct_smul,
    add_dotProduct, smul_eq_mul, Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [dotProduct_comm (x i) d]
  ring

#print axioms gd_R_add

theorem gd_G_best {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ)
    (R : (Fin p → ℝ) → ℝ) (hR : ∀ θ, R θ = (1 / n : ℝ) * ∑ i, (θ ⬝ᵥ x i - y i) ^ 2)
    (G : (Fin p → ℝ) → Fin p → ℝ)
    (hG : ∀ θ, G θ = (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i)
    (H : Matrix (Fin p) (Fin p) ℝ) (hH : H = (2 / n : ℝ) • ∑ i, vecMulVec (x i) (x i))
    (θs : Fin p → ℝ) (hbest : ∀ θ, R θs ≤ R θ) : G θs = 0 := by
  set d := G θs
  set a := d ⬝ᵥ d
  set b := (1 / 2 : ℝ) * (d ⬝ᵥ H *ᵥ d)
  have key : ∀ t : ℝ, 0 ≤ t * a + t ^ 2 * b := by
    intro t
    have h := hbest (θs + t • d)
    rw [gd_R_add x y R hR G hG H hH] at h
    simp only [dotProduct_smul, smul_dotProduct, mulVec_smul, smul_eq_mul] at h
    have : 0 ≤ t * (d ⬝ᵥ d) + 1 / 2 * (t * (t * (d ⬝ᵥ H *ᵥ d))) := by linarith
    simp only [a, b]; nlinarith
  have ha : 0 ≤ a := Finset.sum_nonneg fun i _ => mul_self_nonneg _
  have ha0 : a = 0 := by
    by_contra hne
    have hapos : 0 < a := lt_of_le_of_ne ha (Ne.symm hne)
    set c := |b| + 1 with hc
    have hcpos : 0 < c := by positivity
    have hbc : b < c := by have := le_abs_self b; linarith
    have h := key (-a / c)
    have h2 : 0 ≤ c ^ 2 * ((-a / c) * a + (-a / c) ^ 2 * b) := mul_nonneg (by positivity) h
    have h3 : c ^ 2 * ((-a / c) * a + (-a / c) ^ 2 * b) = a ^ 2 * (b - c) := by
      field_simp; ring
    rw [h3] at h2
    have : a ^ 2 * (b - c) < 0 := mul_neg_of_pos_of_neg (by positivity) (by linarith)
    linarith
  exact dotProduct_self_eq_zero.mp ha0

#print axioms gd_G_best

theorem gd_update_dotProduct {p : ℕ} (θ w : Fin p → ℝ) (j : Fin p) (s : ℝ) :
    Function.update θ j s ⬝ᵥ w = θ ⬝ᵥ w + (s - θ j) * w j := by
  classical
  have : Function.update θ j s = θ + (s - θ j) • Pi.single j 1 := by
    ext k
    by_cases hk : k = j
    · subst hk; simp
    · simp [hk]
  rw [this, add_dotProduct, smul_dotProduct, single_one_dotProduct, smul_eq_mul]

#print axioms gd_update_dotProduct

/-- **The step limit: gradient descent settles exactly when the step is under 2 over the
steepest curvature.** There are `n` orders; order `i` has a list of `p` numbers `x i` (the bias
is the number that is always 1) and a value `y i`. The weights `θ` predict `θ · x i`. The risk is
the average squared miss `R θ = (1/n) Σ (θ · x i − y i)²`, its gradient is
`G θ = (2/n) Σ (θ · x i − y i) x i`, and its Hessian (the table of second rates) is
`H = (2/n) Σ x i x iᵀ`. Suppose the risk is a bowl with one bottom (`H` positive definite) and
`θs` are the best weights. Gradient descent repeats `θ ← θ − η G θ`. It reaches the best weights
from every start exactly when `0 < ηλ < 2` for every curvature `λ` of the bowl (every stretch
factor of `H`), that is, exactly when `0 < η < 2 / λ_max`. -/
theorem gradient_descent_converges_iff_step_below_limit {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ)
    (R : (Fin p → ℝ) → ℝ) (hR : ∀ θ, R θ = (1 / n : ℝ) * ∑ i, (θ ⬝ᵥ x i - y i) ^ 2)
    (G : (Fin p → ℝ) → Fin p → ℝ)
    (hG : ∀ θ, G θ = (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i)
    (H : Matrix (Fin p) (Fin p) ℝ) (hH : H = (2 / n : ℝ) • ∑ i, vecMulVec (x i) (x i))
    (hbowl : H.PosDef) (θs : Fin p → ℝ) (hbest : ∀ θ, R θs ≤ R θ) (η : ℝ) :
    (∀ θ : ℕ → Fin p → ℝ, (∀ t, θ (t + 1) = θ t - η • G (θ t)) →
        Tendsto θ atTop (𝓝 θs)) ↔
      ∀ (l : ℝ) (v : Fin p → ℝ), v ≠ 0 → H *ᵥ v = l • v → 0 < η * l ∧ η * l < 2 := by
  have hG0 := gd_G_best x y R hR G hG H hH θs hbest
  have hGe : ∀ θ, G θ = H *ᵥ (θ - θs) := by
    intro θ
    have e : θ = θs + (θ - θs) := by abel
    conv_lhs => rw [e]
    rw [gd_G_add x y G hG H hH, hG0, zero_add]
  constructor
  · intro h l v hv0 hHv
    set r := 1 - η * l with hr
    have hseq : ∀ t, (fun t : ℕ => θs + r ^ t • v) (t + 1) =
        (fun t : ℕ => θs + r ^ t • v) t - η • G ((fun t : ℕ => θs + r ^ t • v) t) := by
      intro t
      simp only
      rw [hGe, add_sub_cancel_left, mulVec_smul, hHv, pow_succ, hr]
      module
    have hlim := (h (fun t => θs + r ^ t • v) hseq).sub_const θs
    simp only [add_sub_cancel_left, sub_self] at hlim
    obtain ⟨j, hj⟩ := Function.ne_iff.mp hv0
    have hj : v j ≠ 0 := hj
    have hj' := (tendsto_pi_nhds.1 hlim j).mul_const (v j)⁻¹
    simp only [Pi.smul_apply, smul_eq_mul, Pi.zero_apply, zero_mul] at hj'
    have hpow : Tendsto (fun t : ℕ => r ^ t) atTop (𝓝 0) := by
      refine hj'.congr fun t => ?_
      field_simp
    rw [tendsto_pow_atTop_nhds_zero_iff, abs_lt] at hpow
    constructor <;> linarith [hpow.1, hpow.2]
  · intro h θ hθ
    classical
    have hS := hbowl.isHermitian
    set b := hS.eigenvectorBasis
    set ev := hS.eigenvalues
    set c : Fin p → ℝ := fun k => b.repr (WithLp.toLp 2 (θ 0 - θs)) k
    have hdec : θ 0 - θs = ∑ k, c k • ⇑(b k) := by
      have := congrArg WithLp.ofLp (b.sum_repr (WithLp.toLp 2 (θ 0 - θs)))
      rw [WithLp.ofLp_sum] at this
      simp only [WithLp.ofLp_smul] at this
      exact this.symm
    have hform : ∀ t, θ t = θs + ∑ k, ((1 - η * ev k) ^ t * c k) • ⇑(b k) := by
      intro t
      induction t with
      | zero =>
        simp only [pow_zero, one_mul]
        rw [← hdec]; abel
      | succ t ih =>
        rw [hθ, hGe, ih, add_sub_cancel_left, mulVec_sum, add_sub_assoc, Finset.smul_sum,
          ← Finset.sum_sub_distrib]
        congr 1
        refine Finset.sum_congr rfl fun k _ => ?_
        rw [mulVec_smul, hS.mulVec_eigenvectorBasis, pow_succ]
        module
    have hconv : ∀ k, Tendsto (fun t : ℕ => (1 - η * ev k) ^ t) atTop (𝓝 0) := by
      intro k
      have hne : (⇑(b k) : Fin p → ℝ) ≠ 0 := by
        intro h0
        apply b.orthonormal.ne_zero k
        have := congrArg (WithLp.toLp 2) h0
        simpa using this
      obtain ⟨h1, h2⟩ := h (ev k) _ hne (hS.mulVec_eigenvectorBasis k)
      rw [tendsto_pow_atTop_nhds_zero_iff, abs_lt]
      constructor <;> linarith
    have hlim : Tendsto (fun t => θs + ∑ k, ((1 - η * ev k) ^ t * c k) • ⇑(b k)) atTop
        (𝓝 (θs + ∑ k : Fin p, ((0 : ℝ) * c k) • ⇑(b k))) :=
      tendsto_const_nhds.add (tendsto_finsetSum _ fun k _ =>
        ((hconv k).mul_const (c k)).smul_const _)
    simp only [zero_mul, zero_smul, Finset.sum_const_zero, add_zero] at hlim
    exact hlim.congr fun t => (hform t).symm

/-- **Why it works: the slope formula, the exact bowl, and the shrink factor per step.** Same
setting, with `θs` the best weights (no other hypothesis). Then:
the rate of the risk with respect to weight `j` is `G θ j`, twice the average of each order's
miss times its number `j` (the chain rule, Step 1);
the risk is exactly the lowest risk plus half of `eᵀ H e`, and the gradient is `H e`, where
`e = θ − θs` is the distance from the best weights (Step 2);
and if the walk starts at `θs + c v` with `v` a direction of curvature `λ` (`H v = λ v`), then
after `t` steps it is at `θs + (1 − ηλ)ᵗ c v`, and its excess risk has been multiplied by
`(1 − ηλ)^(2t)`. -/
theorem gradient_step_shrinks_each_direction {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ)
    (R : (Fin p → ℝ) → ℝ) (hR : ∀ θ, R θ = (1 / n : ℝ) * ∑ i, (θ ⬝ᵥ x i - y i) ^ 2)
    (G : (Fin p → ℝ) → Fin p → ℝ)
    (hG : ∀ θ, G θ = (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i)
    (H : Matrix (Fin p) (Fin p) ℝ) (hH : H = (2 / n : ℝ) • ∑ i, vecMulVec (x i) (x i))
    (θs : Fin p → ℝ) (hbest : ∀ θ, R θs ≤ R θ) :
    (∀ (θ : Fin p → ℝ) (j : Fin p),
        HasDerivAt (fun s => R (Function.update θ j s)) (G θ j) (θ j)) ∧
      (∀ θ, R θ = R θs + (1 / 2) * ((θ - θs) ⬝ᵥ H *ᵥ (θ - θs)) ∧ G θ = H *ᵥ (θ - θs)) ∧
      ∀ (η l c : ℝ) (v : Fin p → ℝ) (θ : ℕ → Fin p → ℝ), H *ᵥ v = l • v →
        θ 0 = θs + c • v → (∀ t, θ (t + 1) = θ t - η • G (θ t)) →
        ∀ t, θ t = θs + ((1 - η * l) ^ t * c) • v ∧
          R (θ t) - R θs = (1 - η * l) ^ (2 * t) * (R (θ 0) - R θs) := by
  have hG0 := gd_G_best x y R hR G hG H hH θs hbest
  have hid : ∀ θ, R θ = R θs + (1 / 2) * ((θ - θs) ⬝ᵥ H *ᵥ (θ - θs)) ∧
      G θ = H *ᵥ (θ - θs) := by
    intro θ
    have e : θ = θs + (θ - θs) := by abel
    constructor
    · conv_lhs => rw [e]
      rw [gd_R_add x y R hR G hG H hH, hG0, zero_dotProduct, add_zero]
    · conv_lhs => rw [e]
      rw [gd_G_add x y G hG H hH, hG0, zero_add]
  refine ⟨?_, hid, ?_⟩
  · intro θ j
    have hf : (fun s => R (Function.update θ j s)) = fun s =>
        (1 / n : ℝ) * ∑ i, ((θ ⬝ᵥ x i - y i) + (s - θ j) * x i j) ^ 2 := by
      funext s
      rw [hR]
      congr 1
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [gd_update_dotProduct]; ring
    rw [hf]
    have hd : ∀ i ∈ (Finset.univ : Finset (Fin n)), HasDerivAt
        (fun s => ((θ ⬝ᵥ x i - y i) + (s - θ j) * x i j) ^ 2)
        (((2 : ℕ) : ℝ) * ((θ ⬝ᵥ x i - y i) + (θ j - θ j) * x i j) ^ (2 - 1) * (1 * x i j))
        (θ j) := fun i _ =>
      ((((hasDerivAt_id (θ j)).sub_const (θ j)).mul_const (x i j)).const_add
        (θ ⬝ᵥ x i - y i)).pow 2
    refine ((HasDerivAt.fun_sum hd).const_mul (1 / n : ℝ)).congr_deriv ?_
    rw [hG]
    simp only [Pi.smul_apply, Finset.sum_apply, smul_eq_mul, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [sub_self]; push_cast; ring
  · intro η l c v θ hv h0 hstep
    have hpos : ∀ t, θ t = θs + ((1 - η * l) ^ t * c) • v := by
      intro t
      induction t with
      | zero => simp [h0]
      | succ t ih =>
        rw [hstep, (hid _).2, ih, add_sub_cancel_left, mulVec_smul, hv, pow_succ]
        module
    have hrisk : ∀ t, R (θ t) - R θs = (1 / 2) * ((1 - η * l) ^ t * c) ^ 2 * (v ⬝ᵥ H *ᵥ v) := by
      intro t
      rw [(hid _).1, hpos, add_sub_cancel_left]
      simp only [add_sub_cancel_left, mulVec_smul, dotProduct_smul, smul_dotProduct, smul_eq_mul]
      ring
    intro t
    refine ⟨hpos t, ?_⟩
    rw [hrisk, hrisk, mul_comm 2 t, pow_mul]
    ring

/-- **A random batch is an honest stand-in.** Same orders and weights `θ`. A batch is a set `S`
of `B` orders, with `0 < B ≤ n`, and its gradient is the same slope formula averaged over the
batch only: `(1/B) Σ_{i ∈ S} 2 (θ · x i − y i) x i`. Averaged over every possible batch of `B`
orders, each equally likely, the batch gradient is exactly the full gradient
`(2/n) Σ (θ · x i − y i) x i`. -/
theorem minibatch_gradient_is_unbiased {n p : ℕ}
    (x : Fin n → Fin p → ℝ) (y : Fin n → ℝ) (θ : Fin p → ℝ) (B : ℕ)
    (hB : 0 < B) (hBn : B ≤ n) :
    ((n.choose B : ℝ))⁻¹ • ∑ S ∈ (Finset.univ : Finset (Fin n)).powersetCard B,
        ((B : ℝ))⁻¹ • ∑ i ∈ S, (2 * (θ ⬝ᵥ x i - y i)) • x i =
      (2 / n : ℝ) • ∑ i, (θ ⬝ᵥ x i - y i) • x i := by
  classical
  set f : Fin n → Fin p → ℝ := fun i => (2 * (θ ⬝ᵥ x i - y i)) • x i with hf
  have hswap : ∑ S ∈ (Finset.univ : Finset (Fin n)).powersetCard B, ∑ i ∈ S, f i =
      ∑ i, (((Finset.univ : Finset (Fin n)).powersetCard B).filter (fun S => {i} ⊆ S)).card • f i := by
    calc ∑ S ∈ (Finset.univ : Finset (Fin n)).powersetCard B, ∑ i ∈ S, f i
        = ∑ S ∈ (Finset.univ : Finset (Fin n)).powersetCard B, ∑ i, if i ∈ S then f i else 0 := by
          refine Finset.sum_congr rfl fun S _ => ?_
          rw [← Finset.sum_filter]; congr 1; ext i; simp
      _ = ∑ i, ∑ S ∈ (Finset.univ : Finset (Fin n)).powersetCard B, if i ∈ S then f i else 0 :=
          Finset.sum_comm
      _ = _ := by
          refine Finset.sum_congr rfl fun i _ => ?_
          rw [← Finset.sum_filter, Finset.sum_const]
          simp only [Finset.singleton_subset_iff]
  have hcard : ∀ i : Fin n,
      (((Finset.univ : Finset (Fin n)).powersetCard B).filter (fun S => {i} ⊆ S)).card =
        Nat.choose (n - 1) (B - 1) := by
    intro i
    rw [Finset.card_filter_powersetCard_subset]
    · simp
    · simp
    · simp; omega
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  obtain ⟨k, rfl⟩ : ∃ k, B = k + 1 := ⟨B - 1, by omega⟩
  have hid := Nat.add_one_mul_choose_eq m k
  have hC : (0 : ℝ) < ((m + 1).choose (k + 1) : ℝ) := by
    exact_mod_cast Nat.choose_pos hBn
  have hidR : ((m : ℝ) + 1) * (m.choose k : ℝ) = ((m + 1).choose (k + 1) : ℝ) * ((k : ℝ) + 1) := by
    exact_mod_cast hid
  rw [← Finset.smul_sum, hswap]
  simp only [hcard, Nat.add_sub_cancel, Finset.smul_sum, smul_smul, hf]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← Nat.cast_smul_eq_nsmul ℝ, smul_smul, smul_smul]
  congr 1
  push_cast
  field_simp
  linear_combination (θ ⬝ᵥ x i - y i) * hidR

/-! The card's exact worked numbers. -/

-- A full step costs 13 + 13 multiply-adds per order, over 20,000 orders: 520,000.
example : 2 * 20000 * 13 = 520000 := by norm_num
-- Batches of 100: 200 steps per pass, and 10,000 steps in 50 passes.
example : 20000 / 100 = 200 ∧ 50 * (20000 / 100) = 10000 := by norm_num
-- The step limit 2 / 8.0732 = 0.2477 lies between the steps 0.24 (settles) and 0.25 (blows up).
example : (24 / 100 : ℚ) < 2 / (80732 / 10000) ∧ 2 / (80732 / 10000) < (25 / 100 : ℚ) := by
  norm_num
-- Momentum 0.8 piles pushes up to 1 / (1 − 0.8) = 5 times one step.
example : (1 : ℚ) / (1 - 4 / 5) = 5 := by norm_num
-- Number 1 at 100 times its size: its curvature grows 100² = 10,000-fold.
example : (100 : ℕ) ^ 2 = 10000 := by norm_num
-- A quarter of the step 0.05 is 0.0125.
example : (5 / 100 : ℚ) / 4 = 125 / 10000 := by norm_num

#print axioms gradient_descent_converges_iff_step_below_limit
#print axioms gradient_step_shrinks_each_direction
#print axioms minibatch_gradient_is_unbiased
