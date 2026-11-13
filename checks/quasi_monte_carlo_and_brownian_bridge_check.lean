-- Quasi-Monte Carlo: on a budget of 2^w points every Sobol coordinate visits each of the 2^w grid cells exactly once, each Brownian-bridge midpoint step keeps the path's covariance equal to the earlier date's time, and the card's direction numbers, four-point table and wiggle shares check out exactly.
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Data.Set.Finite.Basic

namespace QuasiMonteCarloAndBrownianBridge

open Matrix

/-- One coordinate of Sobol point `i` on a budget of `2 ^ w` points, counted in whole grid steps:
XOR together the direction numbers `m k * 2 ^ (w - k)` picked out by the binary digits of `i`,
digit `k` (counting the lowest digit as digit 1) picking rung `k`. This is the card's
`a_{i,j} = ⊕_{k : digit k of i is 1} m_{k,j} 2^(w-k)` for one coordinate `j`. -/
def sobolCoord (w : ℕ) (m : ℕ → ℕ) (i : ℕ) : ℕ :=
  (List.range w).foldl
    (fun a k => if i.testBit k then a ^^^ m (k + 1) * 2 ^ (w - (k + 1)) else a) 0

theorem two_mul_xor_aux (x y : ℕ) : 2 * (x ^^^ y) = 2 * x ^^^ 2 * y := by
  have h := @Nat.shiftLeft_xor_distrib 1 x y
  simp only [Nat.shiftLeft_eq, pow_one] at h
  rw [mul_comm 2, h, mul_comm x, mul_comm y]

theorem xorFold_succ_aux (n : ℕ) (g : ℕ → ℕ) (i : ℕ) :
    (List.range (n + 1)).foldl (fun a k => if i.testBit k then a ^^^ g k else a) 0 =
      (List.range n).foldl (fun a k => if i.testBit k then a ^^^ g k else a) 0 ^^^
        (if i.testBit n then g n else 0) := by
  rw [List.range_succ, List.foldl_append]
  simp only [List.foldl_cons, List.foldl_nil]
  split <;> simp

theorem xorFold_congr_aux (n : ℕ) (g g' : ℕ → ℕ) (i j : ℕ)
    (hg : ∀ k < n, g k = g' k) (hij : ∀ k < n, i.testBit k = j.testBit k) :
    (List.range n).foldl (fun a k => if i.testBit k then a ^^^ g k else a) 0 =
      (List.range n).foldl (fun a k => if j.testBit k then a ^^^ g' k else a) 0 := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [xorFold_succ_aux, xorFold_succ_aux,
      ih (fun k hk => hg k (by omega)) (fun k hk => hij k (by omega)),
      hg n (by omega), hij n (by omega)]

theorem xorFold_double_aux (n : ℕ) (g : ℕ → ℕ) (i : ℕ) :
    (List.range n).foldl (fun a k => if i.testBit k then a ^^^ 2 * g k else a) 0 =
      2 * (List.range n).foldl (fun a k => if i.testBit k then a ^^^ g k else a) 0 := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [xorFold_succ_aux, xorFold_succ_aux (g := g), ih, two_mul_xor_aux]
    split <;> simp

theorem sobolCoord_succ_aux (w : ℕ) (m : ℕ → ℕ) (i : ℕ) :
    sobolCoord (w + 1) m i =
      2 * sobolCoord w m i ^^^ (if i.testBit w then m (w + 1) else 0) := by
  unfold sobolCoord
  rw [xorFold_succ_aux, ← xorFold_double_aux]
  congr 1
  · apply xorFold_congr_aux
    · intro k hk
      have : w + 1 - (k + 1) = (w - (k + 1)) + 1 := by omega
      rw [this, pow_succ]; ring
    · intro k _; rfl
  · simp

theorem sobolCoord_lt_aux (w : ℕ) (m : ℕ → ℕ)
    (hm : ∀ k, 1 ≤ k → k ≤ w → Odd (m k) ∧ m k < 2 ^ k) (i : ℕ) :
    sobolCoord w m i < 2 ^ w := by
  induction w with
  | zero => simp [sobolCoord]
  | succ w ih =>
    rw [sobolCoord_succ_aux]
    have h1 := ih (fun k hk1 hk2 => hm k hk1 (by omega))
    apply Nat.xor_lt_two_pow
    · rw [pow_succ]; omega
    · split
      · exact (hm (w + 1) (by omega) le_rfl).2
      · positivity

theorem sobolCoord_mod_aux (w : ℕ) (m : ℕ → ℕ) (i : ℕ) :
    sobolCoord w m (i % 2 ^ w) = sobolCoord w m i := by
  unfold sobolCoord
  apply xorFold_congr_aux
  · intro k _; rfl
  · intro k hk; simp [Nat.testBit_mod_two_pow, hk]

theorem sobolCoord_injOn_aux (w : ℕ) (m : ℕ → ℕ)
    (hm : ∀ k, 1 ≤ k → k ≤ w → Odd (m k) ∧ m k < 2 ^ k) :
    Set.InjOn (sobolCoord w m) (Set.Iio (2 ^ w)) := by
  induction w with
  | zero =>
    intro i hi j hj _
    simp at hi hj; omega
  | succ w ih =>
    intro i hi j hj hij
    simp only [Set.mem_Iio] at hi hj
    rw [sobolCoord_succ_aux, sobolCoord_succ_aux] at hij
    have hodd := (hm (w + 1) (by omega) le_rfl).1
    have hb : i.testBit w = j.testBit w := by
      have := congrArg (fun x => x.testBit 0) hij
      simp only [Nat.testBit_xor] at this
      have h2 : ∀ x : ℕ, (2 * x).testBit 0 = false := by
        intro x; simp [Nat.testBit_zero]
      rw [h2, h2] at this
      have hm1 : (m (w + 1)).testBit 0 = true := by
        rw [Nat.testBit_zero]; simpa [Nat.odd_iff] using hodd
      cases hi' : i.testBit w <;> cases hj' : j.testBit w <;> simp_all
    rw [hb] at hij
    have hX : sobolCoord w m i = sobolCoord w m j := by
      have := congrArg (· ^^^ (if j.testBit w = true then m (w + 1) else 0)) hij
      simp only [Nat.xor_assoc, Nat.xor_self, Nat.xor_zero] at this
      omega
    rw [← sobolCoord_mod_aux w m i, ← sobolCoord_mod_aux w m j] at hX
    have hmod := ih (fun k hk1 hk2 => hm k hk1 (by omega))
      (Set.mem_Iio.mpr (Nat.mod_lt _ (by positivity)))
      (Set.mem_Iio.mpr (Nat.mod_lt _ (by positivity))) hX
    apply Nat.eq_of_testBit_eq
    intro k
    rcases lt_trichotomy k w with hk | hk | hk
    · have := congrArg (fun x => x.testBit k) hmod
      simpa [Nat.testBit_mod_two_pow, hk] using this
    · subst hk; exact hb
    · have h2 : 2 ^ (w + 1) ≤ 2 ^ k := Nat.pow_le_pow_right (by norm_num) hk
      rw [Nat.testBit_lt_two_pow (by omega), Nat.testBit_lt_two_pow (by omega)]

/-- The card's even-cover claim. Take a budget that is a power of two, `N = 2 ^ w`, and a ladder
of direction numbers `v_k = m_k / 2 ^ k` whose `k`-th binary digit is 1 (so `m_k` is odd and
less than `2 ^ k`). Then as the point number `i` runs over `0, 1, ..., N - 1`, the coordinate
`a_i` hits every grid value `0, 1, ..., N - 1` exactly once. -/
theorem sobol_coordinate_covers_grid_once (w : ℕ) (m : ℕ → ℕ)
    (hm : ∀ k, 1 ≤ k → k ≤ w → Odd (m k) ∧ m k < 2 ^ k) :
    Set.BijOn (sobolCoord w m) (Set.Iio (2 ^ w)) (Set.Iio (2 ^ w)) := by
  have hmaps : Set.MapsTo (sobolCoord w m) (Set.Iio (2 ^ w)) (Set.Iio (2 ^ w)) :=
    fun i _ => sobolCoord_lt_aux w m hm i
  exact ((Set.finite_Iio _).injOn_iff_bijOn_of_mapsTo hmaps).mp (sobolCoord_injOn_aux w m hm)

/-- The bridge's step draws the right process. Write each date's value of the path as a fixed
combination of the independent unit kicks, so a date is a vector of coefficients and the wiggle
two dates share is the dot product of their vectors. Suppose the path is already correct at the
two ends of a gap, times `tl` and `tr` (shared wiggle `a ⬝ a = tl`, `a ⬝ b = tl`, `b ⬝ b = tr`),
and a fresh kick `e` of unit spread is independent of everything drawn so far. Fill the middle
with `c = (a + b) / 2 + (√(tr - tl) / 2) e`. Then the middle has spread equal to its own time
`(tl + tr) / 2`, and it shares with every already-filled date `x` outside the gap, at time `tx`,
exactly the earlier of the two times: `x ⬝ c = min tx ((tl + tr) / 2)`. -/
theorem bridge_midpoint_keeps_brownian_covariance {n : ℕ} (tl tr : ℝ) (a b e : Fin n → ℝ)
    (haa : a ⬝ᵥ a = tl) (hab : a ⬝ᵥ b = tl) (hbb : b ⬝ᵥ b = tr)
    (hee : e ⬝ᵥ e = 1) (hea : e ⬝ᵥ a = 0) (heb : e ⬝ᵥ b = 0) :
    let c := (1 / 2 : ℝ) • (a + b) + (Real.sqrt (tr - tl) / 2) • e
    c ⬝ᵥ c = (tl + tr) / 2 ∧
      ∀ (x : Fin n → ℝ) (tx : ℝ), e ⬝ᵥ x = 0 → x ⬝ᵥ a = min tx tl → x ⬝ᵥ b = min tx tr →
        (tx ≤ tl ∨ tr ≤ tx) → x ⬝ᵥ c = min tx ((tl + tr) / 2) := by
  intro c
  have hba : b ⬝ᵥ a = tl := by rw [dotProduct_comm]; exact hab
  have hae : a ⬝ᵥ e = 0 := by rw [dotProduct_comm]; exact hea
  have hbe : b ⬝ᵥ e = 0 := by rw [dotProduct_comm]; exact heb
  have hle : tl ≤ tr := by
    have h : 0 ≤ (b - a) ⬝ᵥ (b - a) :=
      Finset.sum_nonneg (fun i _ => mul_self_nonneg ((b - a) i))
    simp only [sub_dotProduct, dotProduct_sub, haa, hab, hbb, hba] at h
    linarith
  have hs : Real.sqrt (tr - tl) ^ 2 = tr - tl := Real.sq_sqrt (by linarith)
  refine ⟨?_, ?_⟩
  · simp only [c, add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul, smul_eq_mul,
      haa, hab, hbb, hba, hee, hea, heb, hae, hbe]
    nlinarith [hs]
  · intro x tx hex hxa hxb htx
    have hxe : x ⬝ᵥ e = 0 := by rw [dotProduct_comm]; exact hex
    simp only [c, dotProduct_add, dotProduct_smul, smul_eq_mul, hxa, hxb, hxe]
    rcases htx with h | h
    · rw [min_eq_left h, min_eq_left (by linarith), min_eq_left (by linarith)]; ring
    · rw [min_eq_right (by linarith), min_eq_right h, min_eq_right (by linarith)]; ring

/-! The card's worked numbers. -/

/-- Coordinate 2's ladder, polynomial `x + 1`: `m_1 = 1`, then `m_k = 2 m_{k-1} ⊕ m_{k-1}`.
`ladder2 k` is rung `k + 1`. -/
def ladder2 : ℕ → ℕ
  | 0 => 1
  | k + 1 => 2 * ladder2 k ^^^ ladder2 k

/-- Coordinate 3's ladder, polynomial `x ^ 2 + x + 1`: `m_1 = m_2 = 1`, then
`m_k = 2 m_{k-1} ⊕ 4 m_{k-2} ⊕ m_{k-2}`. `ladder3 k` is rung `k + 1`. -/
def ladder3 : ℕ → ℕ
  | 0 => 1
  | 1 => 1
  | k + 2 => 2 * ladder3 (k + 1) ^^^ 4 * ladder3 k ^^^ ladder3 k

/-- `x ^ k` reduced modulo the polynomial `p` over the two-element field, polynomials written as
bit patterns (`x + 1` is `3`, `x ^ 2 + x + 1` is `7`): multiply by `x`, and when the top digit
appears, XOR `p` away. -/
def xPowMod (p : ℕ) : ℕ → ℕ
  | 0 => 1
  | k + 1 =>
    let y := xPowMod p k <<< 1
    if y.testBit (Nat.log2 p) then y ^^^ p else y

/-- The fifteen polynomials for coordinates 2 to 16. -/
def polys : List ℕ := [3, 7, 11, 13, 19, 25, 37, 41, 47, 55, 59, 61, 67, 91, 97]

-- The budget: 4,096 = 2 ^ 12, so w = 12.
example : (4096 : ℕ) = 2 ^ 12 := by norm_num
-- Their degrees: 1, 2, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6.
example : polys.map Nat.log2 = [1, 2, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6] := by decide
-- Every one is primitive: x returns to 1 after exactly 2 ^ degree - 1 multiplications
-- (31 for degree 5), and not before.
example : polys.all (fun p => xPowMod p (2 ^ Nat.log2 p - 1) == 1 &&
    (List.range' 1 (2 ^ Nat.log2 p - 2)).all (fun k => xPowMod p k != 1)) = true := by
  decide +kernel
example : xPowMod 37 31 = 1 ∧ ∀ k ∈ Finset.Icc 1 30, xPowMod 37 k ≠ 1 := by decide +kernel
-- The polynomial 5 = x ^ 2 + 1 the card warns about is not primitive: x returns to 1 after 2 steps.
example : xPowMod 5 2 = 1 := by decide
-- Direction numbers m_1 to m_5: coordinate 2 is 1, 3, 5, 15, 17; coordinate 3 is 1, 1, 7, 11, 13.
example : (List.range 5).map ladder2 = [1, 3, 5, 15, 17] := by decide
example : (List.range 5).map ladder3 = [1, 1, 7, 11, 13] := by decide
-- Each rung is odd and below 2 ^ k, as the main theorem asks.
example : (List.range 5).all (fun k => ladder2 k % 2 == 1 && decide (ladder2 k < 2 ^ (k + 1))) = true := by
  decide
example : (List.range 5).all (fun k => ladder3 k % 2 == 1 && decide (ladder3 k < 2 ^ (k + 1))) = true := by
  decide
-- The four points of coordinate 1 (every rung 1: a half, a quarter) are 0, 2, 1, 3 quarters.
example : (List.range 4).map (sobolCoord 2 (fun _ => 1)) = [0, 2, 1, 3] := by decide
-- On 32 points, coordinates 2 and 3 each visit all 32 cells once: no value repeats, and every
-- value is one of the 32 cells.
example : ((List.range 32).map (sobolCoord 5 (fun k => ladder2 (k - 1)))).Nodup ∧
    ∀ i ∈ List.range 32, sobolCoord 5 (fun k => ladder2 (k - 1)) i < 32 := by decide +kernel
example : ((List.range 32).map (sobolCoord 5 (fun k => ladder3 (k - 1)))).Nodup ∧
    ∀ i ∈ List.range 32, sobolCoord 5 (fun k => ladder3 (k - 1)) i < 32 := by decide +kernel
-- The half-cell nudge on a budget of 4 turns 0, 2, 1, 3 quarters into 1/8, 5/8, 3/8, 7/8.
example : ([0, 2, 1, 3] : List ℚ).map (fun a => (a + 1 / 2) / 4) = [1 / 8, 5 / 8, 3 / 8, 7 / 8] := by
  norm_num
-- The drift inside the exponent: r - q - σ^2 / 2 = 5% - 2% - (20%)^2 / 2 = 1%.
example : (5 / 100 : ℚ) - 2 / 100 - (20 / 100) ^ 2 / 2 = 1 / 100 := by norm_num
-- Wiggle shares on 16 dates of 1/16 year. The path's whole wiggle is the sum of the dates' times,
-- 136/16. Bridge order: draw 1 moves date k by k/16, so it carries 68.75 per cent = 11/16.
example : (∑ k ∈ Finset.range 16, ((k + 1 : ℚ) / 16) ^ 2) /
    (∑ k ∈ Finset.range 16, ((k + 1 : ℚ) / 16)) = 6875 / 10000 := by
  norm_num [Finset.sum_range_succ]
-- Date-by-date order: draw j moves dates j to 16 by √(1/16), so it carries (17 - j)/16; draws
-- 1, 1 to 2, 1 to 4 and 1 to 8 carry 16, 31, 58 and 100 parts of 136 (11.76, 22.79, 42.65, 73.53).
example : (List.map (fun d => ∑ j ∈ Finset.range d, ((16 - j : ℚ) / 16)) [1, 2, 4, 8]).map
    (· / (∑ k ∈ Finset.range 16, ((k + 1 : ℚ) / 16))) = [16 / 136, 31 / 136, 58 / 136, 100 / 136] := by
  norm_num [Finset.sum_range_succ]

#print axioms two_mul_xor_aux
#print axioms xorFold_succ_aux
#print axioms xorFold_congr_aux
#print axioms xorFold_double_aux
#print axioms sobolCoord_succ_aux
#print axioms sobolCoord_lt_aux
#print axioms sobolCoord_mod_aux
#print axioms sobolCoord_injOn_aux
#print axioms sobol_coordinate_covers_grid_once
#print axioms bridge_midpoint_keeps_brownian_covariance

end QuasiMonteCarloAndBrownianBridge
