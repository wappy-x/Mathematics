-- Proximal gradient: for the lasso, the prox of the sum of sizes is soft thresholding, ISTA never goes uphill and its gap above the minimum after k steps is at most L‖x₀ − x*‖²/(2k), and ISTA's resting points are exactly the minimisers.
import Mathlib.Data.Real.Sign
import Mathlib.Data.Matrix.Mul
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib

open Matrix

/-! The coefficients are `x : Fin n → ℝ`, one per signal. The table is `A`, a matrix with one
row per week (`m` weeks) and one column per signal, and `y : Fin m → ℝ` is the weekly sales.
`A *ᵥ x` is the matrix times the list, and `Aᵀ` is the transpose. The smooth part is
`f(x) = ½‖y − Ax‖²`, its gradient is `Aᵀ(Ax − y)`, and the charge is `λ‖x‖₁ = λ ∑ |x_j|`.

The step is `α = 1/L`. "The slope of the smooth part changes at rate at most `L`" is the card's
Step 1 bowl: `‖Ad‖² ≤ L‖d‖²` for every move `d`. The card takes `L` to be the largest
eigenvalue of `AᵀA`; any `L` with this bound is allowed here, which includes that one and covers
every step `1/L` at most one over the largest eigenvalue. "The charge is convex" is `0 ≤ λ`. -/

/-- Soft thresholding `S_τ(v) = sign(v) · max(|v| − τ, 0)`: pull `v` toward zero by `τ`
and stop at zero. -/
noncomputable def softThreshold (τ v : ℝ) : ℝ := Real.sign v * max (|v| - τ) 0

/-- The lasso total `F(x) = ½‖y − Ax‖² + λ‖x‖₁`. -/
noncomputable def lassoTotal {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ)
    (lam : ℝ) (x : Fin n → ℝ) : ℝ :=
  (1 / 2) * ∑ i, (y i - (A *ᵥ x) i) ^ 2 + lam * ∑ j, |x j|

/-- One ISTA step with step length `1/L`: a gradient step on the squared misses,
`x − (1/L) Aᵀ(Ax − y)`, then soft thresholding of every entry by `λ/L`. -/
noncomputable def istaStep {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ)
    (lam L : ℝ) (x : Fin n → ℝ) : Fin n → ℝ :=
  fun j => softThreshold (lam / L) (x j - (1 / L) * (Aᵀ *ᵥ (A *ᵥ x - y)) j)

/-- One coordinate: soft thresholding minimises `τ|w| + ½(w − v)²`, with a quadratic margin. -/
theorem soft_threshold_one_dim {τ : ℝ} (hτ : 0 ≤ τ) (v w : ℝ) :
    τ * |softThreshold τ v| + (1 / 2) * (softThreshold τ v - v) ^ 2 +
        (1 / 2) * (w - softThreshold τ v) ^ 2 ≤
      τ * |w| + (1 / 2) * (w - v) ^ 2 := by
  unfold softThreshold
  rcases lt_or_ge τ v with h | h
  · have hv : 0 < v := lt_of_le_of_lt hτ h
    rw [Real.sign_of_pos hv, abs_of_pos hv, max_eq_left (by linarith), one_mul,
      abs_of_nonneg (by linarith)]
    have := le_abs_self w
    nlinarith
  · rcases lt_or_ge v (-τ) with h' | h'
    · have hv : v < 0 := by linarith
      rw [Real.sign_of_neg hv, abs_of_neg hv, max_eq_left (by linarith),
        abs_of_nonpos (by linarith)]
      have := neg_abs_le w
      nlinarith
    · have hav : |v| - τ ≤ 0 := by rw [sub_nonpos, abs_le]; constructor <;> linarith
      rw [max_eq_right hav, mul_zero]
      simp only [abs_zero, mul_zero, zero_sub, zero_add, sub_zero]
      have h1 : w * v ≤ τ * |w| := by
        rcases abs_cases w with ⟨hw, _⟩ | ⟨hw, _⟩ <;> rw [hw] <;> nlinarith
      have e1 : (w - v) ^ 2 = w ^ 2 - 2 * (w * v) + v ^ 2 := by ring
      have e2 : (-v) ^ 2 = v ^ 2 := by ring
      rw [e1, e2]
      linarith
#print axioms soft_threshold_one_dim

/-- A sum of squares that is at most zero forces equality. -/
theorem eq_of_sum_sq_sub_nonpos {n : ℕ} (u v : Fin n → ℝ)
    (h : ∑ j, (u j - v j) ^ 2 ≤ 0) : u = v := by
  have h0 : ∑ j, (u j - v j) ^ 2 = 0 :=
    le_antisymm h (Finset.sum_nonneg fun j _ => sq_nonneg _)
  rw [Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sq_nonneg _)] at h0
  funext j
  have := h0 j (Finset.mem_univ j)
  have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
  linarith
#print axioms eq_of_sum_sq_sub_nonpos

/-- The transpose moves across the dot product. -/
theorem sum_transpose_mulVec_mul {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (r : Fin m → ℝ)
    (d : Fin n → ℝ) : ∑ j, (Aᵀ *ᵥ r) j * d j = ∑ i, r i * (A *ᵥ d) i := by
  change (Aᵀ *ᵥ r) ⬝ᵥ d = r ⬝ᵥ (A *ᵥ d)
  rw [mulVec_transpose, dotProduct_mulVec]
#print axioms sum_transpose_mulVec_mul

/-- Exact expansion of the squared misses around `x`. -/
theorem sq_misses_expand {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ)
    (x z : Fin n → ℝ) :
    ∑ i, (y i - (A *ᵥ z) i) ^ 2 = ∑ i, (y i - (A *ᵥ x) i) ^ 2 +
      2 * ∑ j, (Aᵀ *ᵥ (A *ᵥ x - y)) j * (z j - x j) + ∑ i, ((A *ᵥ (z - x)) i) ^ 2 := by
  have hc : ∑ j, (Aᵀ *ᵥ (A *ᵥ x - y)) j * (z j - x j) =
      ∑ j, (Aᵀ *ᵥ (A *ᵥ x - y)) j * (z - x) j := rfl
  rw [hc, sum_transpose_mulVec_mul, Finset.mul_sum, ← Finset.sum_add_distrib,
    ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp only [mulVec_sub, Pi.sub_apply]
  ring
#print axioms sq_misses_expand

/-- The prox step inequality for one ISTA step (needs no curvature bound): with
`g = Aᵀ(Ax − y)` and `x⁺ = T x`, for every `w`,
`λ‖x⁺‖₁ + (L/2)‖x⁺ − x‖² + ⟨g, x⁺ − x⟩ + (L/2)‖w − x⁺‖² ≤ λ‖w‖₁ + (L/2)‖w − x‖² + ⟨g, w − x⟩`. -/
theorem ista_prox_ineq {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ) {lam L : ℝ}
    (hlam : 0 ≤ lam) (hL : 0 < L) (x w : Fin n → ℝ) :
    lam * ∑ j, |istaStep A y lam L x j| +
        L / 2 * ∑ j, (istaStep A y lam L x j - x j) ^ 2 +
        ∑ j, (Aᵀ *ᵥ (A *ᵥ x - y)) j * (istaStep A y lam L x j - x j) +
        L / 2 * ∑ j, (w j - istaStep A y lam L x j) ^ 2 ≤
      lam * ∑ j, |w j| + L / 2 * ∑ j, (w j - x j) ^ 2 +
        ∑ j, (Aᵀ *ᵥ (A *ᵥ x - y)) j * (w j - x j) := by
  set g := Aᵀ *ᵥ (A *ᵥ x - y) with hg
  set xp := istaStep A y lam L x with hxp
  have hτ : 0 ≤ lam / L := div_nonneg hlam hL.le
  have hpt : ∀ j, lam * |xp j| + L / 2 * (xp j - x j) ^ 2 + g j * (xp j - x j) +
      L / 2 * (w j - xp j) ^ 2 ≤ lam * |w j| + L / 2 * (w j - x j) ^ 2 + g j * (w j - x j) := by
    intro j
    have h1 := soft_threshold_one_dim hτ (x j - 1 / L * g j) (w j)
    have hxpj : xp j = softThreshold (lam / L) (x j - 1 / L * g j) := rfl
    rw [← hxpj] at h1
    have h2 := mul_le_mul_of_nonneg_left h1 hL.le
    have e1 : L * (lam / L * |w j| + 1 / 2 * (w j - (x j - 1 / L * g j)) ^ 2) =
        lam * |w j| + L / 2 * (w j - x j) ^ 2 + g j * (w j - x j) + g j ^ 2 / (2 * L) := by
      field_simp; ring
    have e2 : L * (lam / L * |xp j| + 1 / 2 * (xp j - (x j - 1 / L * g j)) ^ 2 +
        1 / 2 * (w j - xp j) ^ 2) =
        lam * |xp j| + L / 2 * (xp j - x j) ^ 2 + g j * (xp j - x j) + g j ^ 2 / (2 * L) +
          L / 2 * (w j - xp j) ^ 2 := by
      field_simp; ring
    linarith
  have hsum := Finset.sum_le_sum fun j (_ : j ∈ Finset.univ) => hpt j
  simp only [Finset.sum_add_distrib, ← Finset.mul_sum] at hsum
  exact hsum
#print axioms ista_prox_ineq

/-- The basic ISTA inequality: for every `w`,
`F(T x) ≤ F(w) + (L/2)‖w − x‖² − (L/2)‖w − T x‖²`. -/
theorem ista_key_ineq {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ) {lam L : ℝ}
    (hlam : 0 ≤ lam) (hL : 0 < L)
    (hcurv : ∀ d : Fin n → ℝ, ∑ i, ((A *ᵥ d) i) ^ 2 ≤ L * ∑ j, (d j) ^ 2)
    (x w : Fin n → ℝ) :
    lassoTotal A y lam (istaStep A y lam L x) ≤ lassoTotal A y lam w +
      L / 2 * ∑ j, (w j - x j) ^ 2 - L / 2 * ∑ j, (w j - istaStep A y lam L x j) ^ 2 := by
  have hsum := ista_prox_ineq A y hlam hL x w
  set xp := istaStep A y lam L x with hxp
  have ex := sq_misses_expand A y x xp
  have ew := sq_misses_expand A y x w
  have hc := hcurv (xp - x)
  have hnn : 0 ≤ ∑ i, ((A *ᵥ (w - x)) i) ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
  have hcx : ∑ j, ((xp - x) j) ^ 2 = ∑ j, (xp j - x j) ^ 2 := rfl
  rw [hcx] at hc
  unfold lassoTotal
  nlinarith
#print axioms ista_key_ineq

/-- **ISTA never goes uphill and closes the gap like 1/k.** Take any table `A`, sales `y`,
charge `λ ≥ 0`, and a curvature bound `L > 0` with `‖Ad‖² ≤ L‖d‖²` for every move `d`.
Run ISTA with step `1/L` from any start `x₀`, and let `x*` be a minimiser of the lasso total `F`.
Then the total never rises from one step to the next, and after `k ≥ 1` steps
`F(x_k) − F(x*) ≤ L‖x₀ − x*‖² / (2k)`. -/
theorem ista_never_uphill_and_gap_le_L_dist_sq_div_two_k {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (y : Fin m → ℝ) {lam L : ℝ} (hlam : 0 ≤ lam) (hL : 0 < L)
    (hcurv : ∀ d : Fin n → ℝ, ∑ i, ((A *ᵥ d) i) ^ 2 ≤ L * ∑ j, (d j) ^ 2)
    (x₀ xstar : Fin n → ℝ) (hmin : ∀ u, lassoTotal A y lam xstar ≤ lassoTotal A y lam u) :
    (∀ k : ℕ, lassoTotal A y lam ((istaStep A y lam L)^[k + 1] x₀) ≤
        lassoTotal A y lam ((istaStep A y lam L)^[k] x₀)) ∧
    (∀ k : ℕ, 0 < k →
      lassoTotal A y lam ((istaStep A y lam L)^[k] x₀) - lassoTotal A y lam xstar ≤
        L * (∑ j, (x₀ j - xstar j) ^ 2) / (2 * k)) := by
  have key := fun x w => ista_key_ineq A y hlam hL hcurv x w
  set T := istaStep A y lam L
  set F := lassoTotal A y lam
  have mono : ∀ k : ℕ, F (T^[k + 1] x₀) ≤ F (T^[k] x₀) := by
    intro k
    have h := key (T^[k] x₀) (T^[k] x₀)
    rw [Function.iterate_succ_apply']
    have h0 : ∑ j, ((T^[k] x₀) j - (T^[k] x₀) j) ^ 2 = 0 := by simp
    have h1 : 0 ≤ ∑ j, ((T^[k] x₀) j - T (T^[k] x₀) j) ^ 2 :=
      Finset.sum_nonneg fun j _ => sq_nonneg _
    rw [h0] at h
    nlinarith
  refine ⟨mono, ?_⟩
  have ind : ∀ k : ℕ, (k : ℝ) * (F (T^[k] x₀) - F xstar) +
      L / 2 * ∑ j, (xstar j - (T^[k] x₀) j) ^ 2 ≤ L / 2 * ∑ j, (xstar j - x₀ j) ^ 2 := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      have h := key (T^[k] x₀) xstar
      rw [← Function.iterate_succ_apply' T k x₀] at h
      have hm := mono k
      have hk : (0 : ℝ) ≤ k := Nat.cast_nonneg k
      have h2 : (k : ℝ) * (F (T^[k + 1] x₀) - F xstar) ≤ (k : ℝ) * (F (T^[k] x₀) - F xstar) :=
        mul_le_mul_of_nonneg_left (by linarith) hk
      push_cast
      nlinarith
  intro k hk
  have h := ind k
  have hD : 0 ≤ ∑ j, (xstar j - (T^[k] x₀) j) ^ 2 := Finset.sum_nonneg fun j _ => sq_nonneg _
  have hswap : ∑ j, (xstar j - x₀ j) ^ 2 = ∑ j, (x₀ j - xstar j) ^ 2 :=
    Finset.sum_congr rfl fun j _ => by ring
  rw [hswap] at h
  have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
  rw [le_div_iff₀ (by positivity)]
  nlinarith

/-- **The prox of the sum of sizes is soft thresholding.** For a shrink `τ ≥ 0` and any point
`v`, the points `u` that minimise `τ‖u‖₁ + ½‖u − v‖²` are exactly one: the list that applies
`S_τ` to every entry of `v`. -/
theorem prox_sum_of_sizes_eq_soft_threshold {n : ℕ} {τ : ℝ} (hτ : 0 ≤ τ) (v u : Fin n → ℝ) :
    (∀ w : Fin n → ℝ, τ * ∑ j, |u j| + (1 / 2) * ∑ j, (u j - v j) ^ 2 ≤
        τ * ∑ j, |w j| + (1 / 2) * ∑ j, (w j - v j) ^ 2) ↔
      u = fun j => softThreshold τ (v j) := by
  constructor
  · intro h
    have h1 := h (fun j => softThreshold τ (v j))
    have h2 := Finset.sum_le_sum fun j (_ : j ∈ Finset.univ) =>
      soft_threshold_one_dim hτ (v j) (u j)
    simp only [Finset.sum_add_distrib, ← Finset.mul_sum] at h2
    apply eq_of_sum_sq_sub_nonpos
    nlinarith
  · rintro rfl w
    have h2 := Finset.sum_le_sum fun j (_ : j ∈ Finset.univ) =>
      soft_threshold_one_dim hτ (v j) (w j)
    simp only [Finset.sum_add_distrib, ← Finset.mul_sum] at h2
    have h3 : 0 ≤ ∑ j, (w j - softThreshold τ (v j)) ^ 2 :=
      Finset.sum_nonneg fun j _ => sq_nonneg _
    nlinarith

/-- **ISTA stops exactly at the minimisers.** For a charge `λ ≥ 0` and a step `1/L` with
`L > 0`, a list `x` is left unchanged by an ISTA step exactly when it minimises the lasso
total. -/
theorem ista_fixed_point_iff_minimiser {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (y : Fin m → ℝ) {lam L : ℝ} (hlam : 0 ≤ lam) (hL : 0 < L) (x : Fin n → ℝ) :
    istaStep A y lam L x = x ↔ ∀ u, lassoTotal A y lam x ≤ lassoTotal A y lam u := by
  have hsum := fun w => ista_prox_ineq A y hlam hL x w
  set g := Aᵀ *ᵥ (A *ᵥ x - y) with hg
  set xp := istaStep A y lam L x with hxp
  constructor
  · intro hfix w
    have h := hsum w
    rw [hfix] at h
    simp only [sub_self, mul_zero, Finset.sum_const_zero, ne_eq, OfNat.ofNat_ne_zero,
      not_false_eq_true, zero_pow, add_zero] at h
    have ew := sq_misses_expand A y x w
    have hnn : 0 ≤ ∑ i, ((A *ᵥ (w - x)) i) ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
    unfold lassoTotal
    nlinarith
  · intro hmin
    have h := hsum x
    simp only [sub_self, mul_zero, Finset.sum_const_zero, ne_eq, OfNat.ofNat_ne_zero,
      not_false_eq_true, zero_pow, add_zero] at h
    set d : Fin n → ℝ := fun j => xp j - x j with hd
    set D := ∑ j, (xp j - x j) ^ 2 with hD
    set K := ∑ i, ((A *ᵥ d) i) ^ 2 with hK
    set a := ∑ j, g j * (xp j - x j) + lam * ∑ j, |xp j| - lam * ∑ j, |x j| with ha
    have hswap : ∑ j, (x j - xp j) ^ 2 = D := Finset.sum_congr rfl fun j _ => by ring
    rw [hswap] at h
    have haD : a ≤ -(L * D) := by rw [ha]; linarith
    have hK0 : 0 ≤ K := Finset.sum_nonneg fun i _ => sq_nonneg _
    have hD0 : 0 ≤ D := Finset.sum_nonneg fun j _ => sq_nonneg _
    -- minimality along the segment from `x` toward `xp`
    have hseg : ∀ t : ℝ, 0 < t → t ≤ 1 → 0 ≤ t * a + t ^ 2 * K / 2 := by
      intro t ht0 ht1
      have hm := hmin (fun j => x j + t * d j)
      have ex := sq_misses_expand A y x (fun j => x j + t * d j)
      have hdiff : (fun j => x j + t * d j) - x = t • d := by
        funext j; simp
      rw [hdiff, mulVec_smul] at ex
      have hK' : ∑ i, ((t • (A *ᵥ d)) i) ^ 2 = t ^ 2 * K := by
        rw [hK, Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        simp only [Pi.smul_apply, smul_eq_mul]; ring
      have hg' : ∑ j, g j * (x j + t * d j - x j) = t * ∑ j, g j * (xp j - x j) := by
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun j _ => ?_
        simp only [hd]; ring
      have habs : ∑ j, |x j + t * d j| ≤ (1 - t) * ∑ j, |x j| + t * ∑ j, |xp j| := by
        rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
        refine Finset.sum_le_sum fun j _ => ?_
        have e : x j + t * d j = (1 - t) * x j + t * xp j := by simp only [hd]; ring
        rw [e]
        calc |(1 - t) * x j + t * xp j| ≤ |(1 - t) * x j| + |t * xp j| := abs_add_le _ _
          _ = (1 - t) * |x j| + t * |xp j| := by
            rw [abs_mul, abs_mul, abs_of_nonneg (by linarith), abs_of_pos ht0]
      rw [hK', hg'] at ex
      unfold lassoTotal at hm
      have hl := mul_le_mul_of_nonneg_left habs hlam
      rw [ha]
      nlinarith
    have ha0 : 0 ≤ a := by
      by_contra hneg
      rw [not_le] at hneg
      set t := min 1 (-a / (K + 1)) with ht
      have ht0 : 0 < t := lt_min one_pos (div_pos (by linarith) (by linarith))
      have ht1 : t ≤ 1 := min_le_left _ _
      have ht2 : t ≤ -a / (K + 1) := min_le_right _ _
      rw [le_div_iff₀ (by linarith)] at ht2
      have := hseg t ht0 ht1
      nlinarith [mul_pos ht0 ht0]
    have hDle : D ≤ 0 := by nlinarith
    exact eq_of_sum_sq_sub_nonpos xp x hDle

#print axioms ista_never_uphill_and_gap_le_L_dist_sq_div_two_k
#print axioms prox_sum_of_sizes_eq_soft_threshold
#print axioms ista_fixed_point_iff_minimiser
