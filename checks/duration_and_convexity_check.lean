-- Duration and convexity: for a bond with fixed non-negative payments, modified duration and convexity are minus the price's first derivative and its second derivative, each divided by the price, and a yield move changes the price by the duration and convexity terms plus a leftover no bigger than M times the cube of the move over six, with the leftover's sign set by the move's direction.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Finset

/-! A bond pays `A t` dollars at the end of year `t`, for `t = 1, …, N`; the face is part of the
last payment. At a yield `y` every payment is discounted at the one rate `y`. -/

/-- The price: `P(y) = ∑_{t=1}^{N} A_t / (1 + y)^t`. -/
noncomputable def price (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, A t / (1 + y) ^ t

/-- A payment's weight: its share of today's price, `w_t = (A_t / (1 + y)^t) / P`. -/
noncomputable def weight (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (t : ℕ) : ℝ :=
  A t / (1 + y) ^ t / price A N y

/-- Macaulay duration: the payment years averaged under the weights, `∑ t w_t`. -/
noncomputable def macaulay (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, (t : ℝ) * weight A N y t

/-- Modified duration: Macaulay duration divided by `1 + y`. -/
noncomputable def modDuration (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  macaulay A N y / (1 + y)

/-- Convexity: `C = (1/P) ∑_{t=1}^{N} t (t + 1) A_t / (1 + y)^(t + 2)`. -/
noncomputable def convexity (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  1 / price A N y * ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2)

/-- The card's `M`, read at the move's floor:
`M = ∑_{t=1}^{N} t (t + 1) (t + 2) A_t / (1 + y_floor)^(t + 3)`. -/
noncomputable def thirdCap (A : ℕ → ℝ) (N : ℕ) (yFloor : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + yFloor) ^ (t + 3)

lemma hasDerivAt_term (c : ℝ) (n : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => c / (1 + x) ^ n) (-(n * c) / (1 + x) ^ (n + 1)) x := by
  have h0 : (1 + x) ≠ 0 := by linarith
  have h1 : HasDerivAt (fun y : ℝ => (1 + y) ^ n) (n * (1 + x) ^ (n - 1) * 1) x :=
    ((hasDerivAt_id' x).const_add 1).fun_pow n
  have h2 := (h1.fun_inv (pow_ne_zero n h0)).const_mul c
  convert h2 using 1
  · funext y; simp [div_eq_mul_inv]
  · rcases n with _ | k
    · simp
    · simp only [Nat.add_sub_cancel]
      field_simp
      ring

lemma anti_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Icc a b, g' x ≤ 0) : AntitoneOn g (Set.Icc a b) :=
  antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (interior_subset hx))

lemma mono_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Icc a b, 0 ≤ g' x) : MonotoneOn g (Set.Icc a b) :=
  monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (interior_subset hx))

lemma smono_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Ioo a b, 0 < g' x) : StrictMonoOn g (Set.Icc a b) :=
  strictMonoOn_of_hasDerivWithinAt_pos (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (by simpa using hx))

lemma santi_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Ioo a b, g' x < 0) : StrictAntiOn g (Set.Icc a b) :=
  strictAntiOn_of_hasDerivWithinAt_neg (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (by simpa using hx))

lemma chain_up {g g1 g2 g3 : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (d0 : ∀ x ∈ Set.Icc a b, HasDerivAt g (g1 x) x)
    (d1 : ∀ x ∈ Set.Icc a b, HasDerivAt g1 (g2 x) x)
    (d2 : ∀ x ∈ Set.Icc a b, HasDerivAt g2 (g3 x) x)
    (h3 : ∀ x ∈ Set.Icc a b, g3 x ≤ 0) (e0 : g a = 0) (e1 : g1 a = 0) (e2 : g2 a = 0) :
    g b ≤ 0 := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have A2 := anti_of d2 h3
  have n2 : ∀ x ∈ Set.Icc a b, g2 x ≤ 0 := fun x hx => (A2 ha hx hx.1).trans e2.le
  have A1 := anti_of d1 n2
  have n1 : ∀ x ∈ Set.Icc a b, g1 x ≤ 0 := fun x hx => (A1 ha hx hx.1).trans e1.le
  have A0 := anti_of d0 n1
  exact (A0 ha ⟨hab, le_rfl⟩ hab).trans e0.le

lemma chain_down {g g1 g2 g3 : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (d0 : ∀ x ∈ Set.Icc a b, HasDerivAt g (g1 x) x)
    (d1 : ∀ x ∈ Set.Icc a b, HasDerivAt g1 (g2 x) x)
    (d2 : ∀ x ∈ Set.Icc a b, HasDerivAt g2 (g3 x) x)
    (h3 : ∀ x ∈ Set.Icc a b, g3 x ≤ 0) (e0 : g b = 0) (e1 : g1 b = 0) (e2 : g2 b = 0) :
    0 ≤ g a := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have hb : b ∈ Set.Icc a b := ⟨hab, le_rfl⟩
  have A2 := anti_of d2 h3
  have n2 : ∀ x ∈ Set.Icc a b, 0 ≤ g2 x := fun x hx => e2.symm.le.trans (A2 hx hb hx.2)
  have M1 := mono_of d1 n2
  have n1 : ∀ x ∈ Set.Icc a b, g1 x ≤ 0 := fun x hx => (M1 hx hb hx.2).trans e1.le
  have A0 := anti_of d0 n1
  exact e0.symm.le.trans (A0 ha hb hab)

lemma hd_poly {φ : ℝ → ℝ} {φ' x : ℝ} (h : HasDerivAt φ φ' x) (a c0 c1 c2 c3 : ℝ) :
    HasDerivAt (fun x => φ x - c0 - c1 * (x - a) - c2 * (x - a) ^ 2 / 2 - c3 * (x - a) ^ 3 / 6)
      (φ' - c1 - c2 * (x - a) - c3 * (x - a) ^ 2 / 2) x := by
  have hl : HasDerivAt (fun x : ℝ => x - a) 1 x := (hasDerivAt_id' x).sub_const a
  have := (((h.sub_const c0).sub (hl.const_mul c1)).sub
    (((hl.fun_pow 2).const_mul c2).div_const 2)).sub (((hl.fun_pow 3).const_mul c3).div_const 6)
  convert this using 1
  push_cast
  ring

lemma taylor3_up {f f1 f2 f3 : ℝ → ℝ} {a b K : ℝ} (hab : a ≤ b)
    (h0 : ∀ x ∈ Set.Icc a b, HasDerivAt f (f1 x) x)
    (h1 : ∀ x ∈ Set.Icc a b, HasDerivAt f1 (f2 x) x)
    (h2 : ∀ x ∈ Set.Icc a b, HasDerivAt f2 (f3 x) x)
    (hK : ∀ x ∈ Set.Icc a b, f3 x ≤ K) :
    f b - (f a + f1 a * (b - a) + f2 a * (b - a) ^ 2 / 2) ≤ K * (b - a) ^ 3 / 6 := by
  have := chain_up (g := fun x => f x - f a - f1 a * (x - a) - f2 a * (x - a) ^ 2 / 2 - K * (x - a) ^ 3 / 6)
    (g1 := fun x => f1 x - f1 a - f2 a * (x - a) - K * (x - a) ^ 2 / 2 - 0 * (x - a) ^ 3 / 6)
    (g2 := fun x => f2 x - f2 a - K * (x - a) - 0 * (x - a) ^ 2 / 2 - 0 * (x - a) ^ 3 / 6)
    (g3 := fun x => f3 x - K) hab
    (fun x hx => (hd_poly (h0 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h1 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h2 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => by linarith [hK x hx]) (by simp) (by simp) (by simp)
  linarith

lemma taylor3_down {f f1 f2 f3 : ℝ → ℝ} {a b K : ℝ} (hab : a ≤ b)
    (h0 : ∀ x ∈ Set.Icc a b, HasDerivAt f (f1 x) x)
    (h1 : ∀ x ∈ Set.Icc a b, HasDerivAt f1 (f2 x) x)
    (h2 : ∀ x ∈ Set.Icc a b, HasDerivAt f2 (f3 x) x)
    (hK : ∀ x ∈ Set.Icc a b, f3 x ≤ K) :
    K * (a - b) ^ 3 / 6 ≤ f a - (f b + f1 b * (a - b) + f2 b * (a - b) ^ 2 / 2) := by
  have := chain_down (g := fun x => f x - f b - f1 b * (x - b) - f2 b * (x - b) ^ 2 / 2 - K * (x - b) ^ 3 / 6)
    (g1 := fun x => f1 x - f1 b - f2 b * (x - b) - K * (x - b) ^ 2 / 2 - 0 * (x - b) ^ 3 / 6)
    (g2 := fun x => f2 x - f2 b - K * (x - b) - 0 * (x - b) ^ 2 / 2 - 0 * (x - b) ^ 3 / 6)
    (g3 := fun x => f3 x - K) hab
    (fun x hx => (hd_poly (h0 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h1 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h2 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => by linarith [hK x hx]) (by simp) (by simp) (by simp)
  linarith

lemma hasDerivAt_price (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (price A N) (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N) (A := fun t x => A t / (1 + x) ^ t)
    (fun t _ => hasDerivAt_term (A t) t hx)
  exact this

lemma hasDerivAt_d1 (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1))
      (∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N) (A := fun t x => -((t : ℝ) * A t) / (1 + x) ^ (t + 1))
    (fun t _ => hasDerivAt_term _ (t + 1) hx)
  refine this.congr_deriv (Finset.sum_congr rfl fun t _ => ?_)
  push_cast
  ring

lemma hasDerivAt_d2 (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2))
      (-∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N)
    (A := fun t x => (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2))
    (fun t _ => hasDerivAt_term _ (t + 2) hx)
  refine this.congr_deriv ?_
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun t _ => ?_
  push_cast
  ring

lemma deriv_price (A : ℕ → ℝ) (N : ℕ) {y : ℝ} (hy : -1 < y) :
    deriv (price A N) y = ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1) :=
  (hasDerivAt_price A N hy).deriv

lemma deriv2_price (A : ℕ → ℝ) (N : ℕ) {y : ℝ} (hy : -1 < y) :
    deriv (deriv (price A N)) y = ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2) := by
  have hev : deriv (price A N) =ᶠ[nhds y]
      (fun x : ℝ => ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1)) := by
    filter_upwards [Ioi_mem_nhds hy] with x hx using deriv_price A N hx
  rw [hev.deriv_eq, (hasDerivAt_d1 A N hy).deriv]

lemma dur_id (A : ℕ → ℝ) (N : ℕ) (y : ℝ) :
    -(1 / price A N y) * (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) =
      modDuration A N y := by
  unfold modDuration macaulay weight
  rw [Finset.mul_sum, Finset.sum_div]
  refine Finset.sum_congr rfl fun t _ => ?_
  generalize 1 + y = u
  rw [pow_succ]
  ring

lemma zero_of_price_zero (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y)
    (hP : price A N y = 0) : ∀ t ∈ Icc 1 N, A t = 0 := by
  have hz := (Finset.sum_eq_zero_iff_of_nonneg
    (fun t ht => div_nonneg (hA t ht) (pow_pos (by linarith : (0 : ℝ) < 1 + y) t).le)).mp hP
  intro t ht
  have h1 := hz t ht
  have hpos : (0 : ℝ) < (1 + y) ^ t := pow_pos (by linarith) t
  rcases div_eq_zero_iff.mp h1 with h | h
  · exact h
  · exact absurd h hpos.ne'

lemma P_mul_dur (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) :
    price A N y * modDuration A N y =
      -∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1) := by
  by_cases hP : price A N y = 0
  · have hz := zero_of_price_zero A N y hA hy hP
    rw [hP, zero_mul, eq_comm, neg_eq_zero]
    exact Finset.sum_eq_zero fun t ht => by simp [hz t ht]
  · rw [← dur_id]
    field_simp

lemma P_mul_conv (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) :
    price A N y * convexity A N y =
      ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2) := by
  by_cases hP : price A N y = 0
  · have hz := zero_of_price_zero A N y hA hy hP
    rw [hP, zero_mul, eq_comm]
    exact Finset.sum_eq_zero fun t ht => by simp [hz t ht]
  · unfold convexity
    field_simp

lemma third_bounds (A : ℕ → ℝ) (N : ℕ) (m : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hm : -1 < m)
    (x : ℝ) (hx : m ≤ x) :
    -thirdCap A N m ≤ -∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3) ∧
      -∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3) ≤ 0 := by
  have hnum : ∀ t ∈ Icc 1 N, 0 ≤ (t : ℝ) * (t + 1) * (t + 2) * A t := fun t ht =>
    mul_nonneg (by positivity) (hA t ht)
  constructor
  · rw [neg_le_neg_iff]
    unfold thirdCap
    refine Finset.sum_le_sum fun t ht => ?_
    exact div_le_div_of_nonneg_left (hnum t ht) (pow_pos (by linarith) _)
      (pow_le_pow_left₀ (by linarith) (by linarith) _)
  · rw [neg_nonpos]
    exact Finset.sum_nonneg fun t ht => div_nonneg (hnum t ht) (pow_pos (by linarith) _).le

/-- **A yield move turns into a price move by arithmetic, with a certified leftover.** For fixed
payments that are never negative, and a starting yield `y` and new yield `y + Δy` both above
minus one hundred percent,
`P(y + Δy) = P(y) [1 - D_mod Δy + ½ C (Δy)²] + R` with `|R| ≤ M |Δy|³ / 6`, where `M` is read
at the move's floor, the lower of the two yields. The leftover also has a sign: the two-term
estimate is never below the true price on a rise and never above it on a fall. -/
theorem price_move_by_duration_and_convexity (A : ℕ → ℝ) (N : ℕ) (y Δy : ℝ)
    (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) (hy' : -1 < y + Δy) :
    |price A N (y + Δy) -
        price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)|
      ≤ thirdCap A N (min y (y + Δy)) * |Δy| ^ 3 / 6 ∧
    (0 < Δy → price A N (y + Δy) ≤
        price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)) ∧
    (Δy < 0 → price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)
        ≤ price A N (y + Δy)) := by
  have e : price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2) =
      price A N y + (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) * Δy +
        (∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2)) * Δy ^ 2 / 2 := by
    linear_combination (-Δy) * P_mul_dur A N y hA hy + (Δy ^ 2 / 2) * P_mul_conv A N y hA hy
  rw [e]
  have hm : -1 < min y (y + Δy) := lt_min hy hy'
  have hM0 : 0 ≤ thirdCap A N (min y (y + Δy)) := by
    have := third_bounds A N _ hA hm _ le_rfl
    linarith [this.1, this.2]
  rcases lt_trichotomy Δy 0 with h | rfl | h
  · have hmin : min y (y + Δy) = y + Δy := min_eq_right (by linarith)
    rw [hmin] at hM0 ⊢
    have hab : y + Δy ≤ y := by linarith
    have hI : ∀ x ∈ Set.Icc (y + Δy) y, -1 < x := fun x hx => by linarith [hx.1]
    have L := taylor3_down (K := 0) hab
      (fun x hx => hasDerivAt_price A N (hI x hx))
      (fun x hx => hasDerivAt_d1 A N (hI x hx))
      (fun x hx => hasDerivAt_d2 A N (hI x hx))
      (fun x hx => (third_bounds A N _ hA hy' x hx.1).2)
    have U := taylor3_down (f := fun x => -price A N x) (K := thirdCap A N (y + Δy)) hab
      (fun x hx => (hasDerivAt_price A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d1 A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d2 A N (hI x hx)).neg)
      (fun x hx => by linarith [(third_bounds A N _ hA hy' x hx.1).1])
    have hs : y + Δy - y = Δy := by ring
    rw [hs] at L U
    rw [abs_of_neg h]
    have hc : (-Δy) ^ 3 = -Δy ^ 3 := by ring
    have hp : 0 ≤ thirdCap A N (y + Δy) * (-Δy) ^ 3 :=
      mul_nonneg hM0 (pow_nonneg (by linarith) 3)
    refine ⟨abs_le.mpr ⟨?_, ?_⟩, fun h' => absurd h' (by linarith), fun _ => by linarith⟩
    · linarith
    · rw [hc]; linarith
  · simp
  · have hmin : min y (y + Δy) = y := min_eq_left (by linarith)
    rw [hmin] at hM0 ⊢
    have hab : y ≤ y + Δy := by linarith
    have hI : ∀ x ∈ Set.Icc y (y + Δy), -1 < x := fun x hx => by linarith [hx.1]
    have L := taylor3_up (K := 0) hab
      (fun x hx => hasDerivAt_price A N (hI x hx))
      (fun x hx => hasDerivAt_d1 A N (hI x hx))
      (fun x hx => hasDerivAt_d2 A N (hI x hx))
      (fun x hx => (third_bounds A N _ hA hy x hx.1).2)
    have U := taylor3_up (f := fun x => -price A N x) (K := thirdCap A N y) hab
      (fun x hx => (hasDerivAt_price A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d1 A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d2 A N (hI x hx)).neg)
      (fun x hx => by linarith [(third_bounds A N _ hA hy x hx.1).1])
    have hs : y + Δy - y = Δy := by ring
    rw [hs] at L U
    rw [abs_of_pos h]
    have hp : 0 ≤ thirdCap A N y * Δy ^ 3 := mul_nonneg hM0 (pow_nonneg h.le 3)
    refine ⟨abs_le.mpr ⟨?_, ?_⟩, fun _ => by linarith, fun h' => absurd h' (by linarith)⟩
    · linarith
    · linarith

/-- **Duration and convexity are the price's slope and bend.** For any fixed payments and a
yield above minus one hundred percent, `-(1/P) dP/dy` is the modified duration and
`(1/P) d²P/dy²` is the convexity. -/
theorem duration_and_convexity_from_derivatives (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hy : -1 < y) :
    -(1 / price A N y) * deriv (price A N) y = modDuration A N y ∧
    1 / price A N y * deriv (deriv (price A N)) y = convexity A N y := by
  rw [deriv_price A N hy, deriv2_price A N hy]
  exact ⟨dur_id A N y, rfl⟩

/-- **The bend is always upward.** For a bond with at least one payment and every payment
positive, at any yield above minus one hundred percent the second derivative of the price and
the convexity are positive, and the price curve sits strictly above the duration line at every
other yield above minus one hundred percent: a rise costs less than duration alone says, a fall
pays more. -/
theorem convexity_pos_and_price_above_duration_line (A : ℕ → ℝ) (N : ℕ) (y Δy : ℝ)
    (hN : 1 ≤ N) (hA : ∀ t ∈ Icc 1 N, 0 < A t) (hy : -1 < y) (hy' : -1 < y + Δy)
    (hΔ : Δy ≠ 0) :
    0 < deriv (deriv (price A N)) y ∧ 0 < convexity A N y ∧
    price A N y * (1 - modDuration A N y * Δy) < price A N (y + Δy) := by
  have hA' : ∀ t ∈ Icc 1 N, 0 ≤ A t := fun t ht => (hA t ht).le
  have hP : 0 < price A N y :=
    Finset.sum_pos (fun t ht => div_pos (hA t ht) (pow_pos (by linarith) t))
      (Finset.nonempty_Icc.mpr hN)
  have hd2 : ∀ x : ℝ, -1 < x →
      0 < ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2) := fun x hx =>
    Finset.sum_pos (fun t ht => by
      have ht1 : (1 : ℝ) ≤ t := by exact_mod_cast (Finset.mem_Icc.mp ht).1
      exact div_pos (mul_pos (mul_pos (by linarith) (by linarith)) (hA t ht))
        (pow_pos (by linarith) _))
      (Finset.nonempty_Icc.mpr hN)
  refine ⟨?_, ?_, ?_⟩
  · rw [deriv2_price A N hy]; exact hd2 y hy
  · unfold convexity
    exact mul_pos (one_div_pos.mpr hP) (hd2 y hy)
  · have e : price A N y * (1 - modDuration A N y * Δy) =
        price A N y + (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) * Δy := by
      linear_combination (-Δy) * P_mul_dur A N y hA' hy
    rw [e]
    rcases lt_or_gt_of_ne hΔ with h | h
    · have hab : y + Δy ≤ y := by linarith
      have hI : ∀ x ∈ Set.Icc (y + Δy) y, -1 < x := fun x hx => by linarith [hx.1]
      have S1 := smono_of (fun x hx => hasDerivAt_d1 A N (hI x hx))
        (fun x hx => hd2 x (hI x (Set.Ioo_subset_Icc_self hx)))
      have S0 := santi_of
        (fun x hx => hd_poly (hasDerivAt_price A N (hI x hx)) y (price A N y)
          (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) 0 0)
        (fun x hx => by
          have := S1 (Set.Ioo_subset_Icc_self hx) ⟨hab, le_rfl⟩ hx.2
          simp only [zero_mul, zero_div, sub_zero]
          linarith)
      have := S0 ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ (by linarith)
      simp only [sub_self, mul_zero, zero_mul, zero_div, sub_zero, add_sub_cancel_left] at this
      linarith
    · have hab : y ≤ y + Δy := by linarith
      have hI : ∀ x ∈ Set.Icc y (y + Δy), -1 < x := fun x hx => by linarith [hx.1]
      have S1 := smono_of (fun x hx => hasDerivAt_d1 A N (hI x hx))
        (fun x hx => hd2 x (hI x (Set.Ioo_subset_Icc_self hx)))
      have S0 := smono_of
        (fun x hx => hd_poly (hasDerivAt_price A N (hI x hx)) y (price A N y)
          (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) 0 0)
        (fun x hx => by
          have := S1 ⟨le_rfl, hab⟩ (Set.Ioo_subset_Icc_self hx) hx.1
          simp only [zero_mul, zero_div, sub_zero]
          linarith)
      have := S0 ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ (by linarith)
      simp only [sub_self, mul_zero, zero_mul, zero_div, sub_zero, add_sub_cancel_left] at this
      linarith

/-! The card's house bond: 60 a year for five years, with the face of 1,000 paid alongside the
last coupon, so 60, 60, 60, 60, 1060. A 5% yield is `1/20`. Decimals on the card are checked as
windows of half a unit in their last place. -/

-- Repriced at 6%, the house bond is worth exactly its face, 1,000.
example : price (fun t => if t = 5 then 1060 else 60) 5 (6 / 100) = 1000 := by
  simp [price, Finset.sum_Icc_succ_top]
  norm_num

-- A five-year zero-coupon bond has a Macaulay duration of exactly 5 years.
example : macaulay (fun t => if t = 5 then 1000 else 0) 5 (1 / 20) = 5 := by
  simp [macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- The house bond's Macaulay duration rounds to 4.477751 years.
example : (44777505 / 10000000 : ℝ) ≤ macaulay (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    macaulay (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 44777515 / 10000000 := by
  simp [macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- Its modified duration rounds to 4.264525.
example : (42645245 / 10000000 : ℝ) ≤
      modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 42645255 / 10000000 := by
  simp [modDuration, macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- Its convexity rounds to 23.444091.
example : (234440905 / 10000000 : ℝ) ≤
      convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 234440915 / 10000000 := by
  simp [convexity, price, Finset.sum_Icc_succ_top]
  norm_num

-- On the one-point rise, duration plus convexity predicts 1,000.026155 against a true 1,000.
example :
    let P := price (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    let D := modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    let C := convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    (10000261545 / 10000000 : ℝ) ≤ P * (1 - D * (1 / 100) + 1 / 2 * C * (1 / 100) ^ 2) ∧
      P * (1 - D * (1 / 100) + 1 / 2 * C * (1 / 100) ^ 2) < 10000261555 / 10000000 := by
  simp [modDuration, macaulay, weight, convexity, price, Finset.sum_Icc_succ_top]
  norm_num

-- The certified bound on that rise, read at the 5% floor, rounds to 0.026649 dollars.
example : (266485 / 10000000 : ℝ) ≤
      thirdCap (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) * |(1 / 100 : ℝ)| ^ 3 / 6 ∧
    thirdCap (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) * |(1 / 100 : ℝ)| ^ 3 / 6
      < 266495 / 10000000 := by
  simp [thirdCap, Finset.sum_Icc_succ_top]
  norm_num

#print axioms price_move_by_duration_and_convexity
#print axioms duration_and_convexity_from_derivatives
#print axioms convexity_pos_and_price_above_duration_line
#print axioms hasDerivAt_term
#print axioms anti_of
#print axioms mono_of
#print axioms smono_of
#print axioms santi_of
#print axioms chain_up
#print axioms chain_down
#print axioms hd_poly
#print axioms taylor3_up
#print axioms taylor3_down
#print axioms hasDerivAt_price
#print axioms hasDerivAt_d1
#print axioms hasDerivAt_d2
#print axioms deriv_price
#print axioms deriv2_price
#print axioms dur_id
#print axioms zero_of_price_zero
#print axioms P_mul_dur
#print axioms P_mul_conv
#print axioms third_bounds
