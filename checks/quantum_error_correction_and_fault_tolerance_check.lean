-- Quantum error correction: the 3-qubit bit-flip code's checks repair every single flip and fail exactly on two or more, so a block fails with chance 3p² − 2p³, and nesting the code drives the failure rate to 0 exactly when p < 1/2, with the squaring bound pₖ ≤ (m p)^(2^k)/m behind the threshold.
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic

open Filter Topology

/-- A flip pattern on the three data qubits: `e i = true` when qubit `i` was flipped (an X error). -/
abbrev FlipPattern := Fin 3 → Bool

/-- The flip of one qubit `j` only. -/
def single (j : Fin 3) : FlipPattern := fun i => decide (i = j)

/-- The two checks Z₁Z₂ and Z₂Z₃: each entry is `true` when that check reads −1, that is, when
its two qubits disagree. -/
def syndrome (e : FlipPattern) : Bool × Bool := (xor (e 0) (e 1), xor (e 1) (e 2))

/-- The repair table of Step 3: (+1, +1) repairs nothing, (−1, +1) flips qubit 1 back,
(−1, −1) flips qubit 2 back, (+1, −1) flips qubit 3 back. -/
def repairOf : Bool × Bool → FlipPattern
  | (false, false) => fun _ => false
  | (true, false) => single 0
  | (true, true) => single 1
  | (false, true) => single 2

/-- The flips left after the repair: the error and the repair together. -/
def leftover (e : FlipPattern) : FlipPattern := fun i => xor (e i) (repairOf (syndrome e) i)

/-- The repaired block holds the wrong logical state: the leftover flips are X₁X₂X₃, which swaps
|000⟩ and |111⟩. (The only other possible leftover is no flip at all, a correct repair.) -/
def logicalFailure (e : FlipPattern) : Bool := decide (∀ i, leftover e i = true)

/-- The number of flipped qubits in a pattern. -/
def flips (e : FlipPattern) : ℕ := (Finset.univ.filter fun i => e i = true).card

/-- One level of the 3-qubit code: a block of three parts, each failing with chance p, fails with
chance f(p) = 3p² − 2p³. -/
def levelMap (p : ℝ) : ℝ := 3 * p ^ 2 - 2 * p ^ 3

/-- The threshold of the nested 3-qubit code is exactly 1/2. Let each physical qubit fail with
chance p, between 0 and 1, and nest the code k levels deep, so the failure rate after k levels is
f applied k times to p, with f(p) = 3p² − 2p³. Then the failure rate falls to 0 as the number of
levels grows exactly when p is below the threshold 1/2. -/
theorem nested_bit_flip_code_threshold (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    Tendsto (fun k : ℕ => levelMap^[k] p) atTop (𝓝 0) ↔ p < 1 / 2 := by
  constructor
  · intro h
    by_contra hlt
    rw [not_lt] at hlt
    have hinv : ∀ k : ℕ, 1 / 2 ≤ levelMap^[k] p ∧ levelMap^[k] p ≤ 1 := by
      intro k
      induction k with
      | zero => exact ⟨hlt, hp1⟩
      | succ n ih =>
        rw [Function.iterate_succ_apply']
        obtain ⟨h1, h2⟩ := ih
        set x := levelMap^[n] p
        unfold levelMap
        constructor
        · nlinarith [mul_nonneg (sub_nonneg.2 h1) (sub_nonneg.2 h2),
            mul_nonneg (mul_nonneg (sub_nonneg.2 h1) (sub_nonneg.2 h2)) (sub_nonneg.2 h1)]
        · nlinarith [mul_nonneg (sub_nonneg.2 h2) (sub_nonneg.2 h2),
            mul_nonneg (mul_nonneg (sub_nonneg.2 h2) (sub_nonneg.2 h2)) (sub_nonneg.2 h1)]
    have := ge_of_tendsto' h (fun k => (hinv k).1)
    linarith
  · intro hlt
    set r := 3 * p - 2 * p ^ 2 with hr
    have hr0 : 0 ≤ r := by nlinarith
    have hr1 : r < 1 := by nlinarith
    have hinv : ∀ k : ℕ, 0 ≤ levelMap^[k] p ∧ levelMap^[k] p ≤ r ^ k * p := by
      intro k
      induction k with
      | zero => simpa using hp0
      | succ n ih =>
        rw [Function.iterate_succ_apply']
        obtain ⟨h1, h2⟩ := ih
        set x := levelMap^[n] p
        have hrk : r ^ n ≤ 1 := pow_le_one₀ hr0 hr1.le
        have hxp : x ≤ p := le_trans h2 (by nlinarith [pow_nonneg hr0 n])
        unfold levelMap
        constructor
        · nlinarith [mul_nonneg (mul_nonneg h1 h1) (by linarith : (0:ℝ) ≤ 3 - 2 * x)]
        · have : 3 * x ^ 2 - 2 * x ^ 3 ≤ r * x := by
            have := mul_nonneg (mul_nonneg h1 (sub_nonneg.2 hxp))
              (by linarith : (0:ℝ) ≤ 3 - 2 * (p + x))
            nlinarith
          calc 3 * x ^ 2 - 2 * x ^ 3 ≤ r * x := this
            _ ≤ r * (r ^ n * p) := mul_le_mul_of_nonneg_left h2 hr0
            _ = r ^ (n + 1) * p := by ring
    have hlim : Tendsto (fun k : ℕ => r ^ k * p) atTop (𝓝 0) := by
      simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hr0 hr1).mul_const p
    exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hlim
      (fun k => (hinv k).1) (fun k => (hinv k).2)

/-- The checks Z₁Z₂ and Z₂Z₃ and the repair table fix every pattern of at most one flip and fail
on every pattern of two or more flips. So, with each qubit flipped independently with chance p,
the block fails with chance 3p²(1 − p) + p³ = 3p² − 2p³. -/
theorem bit_flip_code_logical_error (p : ℝ) :
    (∀ e : FlipPattern, logicalFailure e = true ↔ 2 ≤ flips e) ∧
      ∑ e ∈ Finset.univ.filter (fun e : FlipPattern => logicalFailure e = true),
          p ^ flips e * (1 - p) ^ (3 - flips e)
        = 3 * p ^ 2 * (1 - p) + p ^ 3 ∧
      3 * p ^ 2 * (1 - p) + p ^ 3 = 3 * p ^ 2 - 2 * p ^ 3 := by
  refine ⟨by decide, ?_, by ring⟩
  have hset : Finset.univ.filter (fun e : FlipPattern => logicalFailure e = true)
      = {![true, true, false], ![true, false, true], ![false, true, true], ![true, true, true]} := by
    decide
  rw [hset]
  rw [Finset.sum_insert (by decide), Finset.sum_insert (by decide), Finset.sum_insert (by decide),
    Finset.sum_singleton]
  have h1 : flips ![true, true, false] = 2 := by decide
  have h2 : flips ![true, false, true] = 2 := by decide
  have h3 : flips ![false, true, true] = 2 := by decide
  have h4 : flips ![true, true, true] = 3 := by decide
  rw [h1, h2, h3, h4]
  norm_num
  ring

/-- The shape of the threshold theorem. If at each level a block fails only when two faults hit
it, and there are at most m pairs of places for them, then p_{k+1} ≤ m pₖ². Squaring k times gives
pₖ ≤ (m p₀)^(2^k) / m, which is p_th (p₀ / p_th)^(2^k) with threshold p_th = 1/m. -/
theorem threshold_squaring_bound (m : ℝ) (hm : 0 < m) (q : ℕ → ℝ) (hq : ∀ k, 0 ≤ q k)
    (hstep : ∀ k, q (k + 1) ≤ m * q k ^ 2) (k : ℕ) :
    q k ≤ (m * q 0) ^ (2 ^ k) / m := by
  induction k with
  | zero => rw [pow_zero, pow_one, mul_div_cancel_left₀ _ hm.ne']
  | succ n ih =>
    calc q (n + 1) ≤ m * q n ^ 2 := hstep n
      _ ≤ m * ((m * q 0) ^ (2 ^ n) / m) ^ 2 := by
        gcongr
        exact hq n
      _ = (m * q 0) ^ (2 ^ (n + 1)) / m := by
        rw [pow_succ 2 n, pow_mul]
        field_simp

-- Step 3's syndrome table: no flip reads (+1, +1); X₁ reads (−1, +1); X₂ reads (−1, −1); X₃ reads (+1, −1).
example : syndrome (fun _ => false) = (false, false) := by decide
example : syndrome (single 0) = (true, false) := by decide
example : syndrome (single 1) = (true, true) := by decide
example : syndrome (single 2) = (false, true) := by decide
-- Each single flip is repaired: nothing is left over.
example : ∀ j, leftover (single j) = fun _ => false := by decide
-- Two flips, X₁X₂, give qubit 3's syndrome, and the "repair" completes the logical flip X₁X₂X₃.
example : syndrome (fun i => decide (i ≠ 2)) = (false, true) := by decide
example : logicalFailure (fun i => decide (i ≠ 2)) = true := by decide

-- Worked numbers at p = 1/100: chances of 0, 1, 2, 3 flips, which add to 1.
example : ((99 : ℚ) / 100) ^ 3 = 970299 / 1000000 := by norm_num
example : 3 * ((1 : ℚ) / 100) * (99 / 100) ^ 2 = 29403 / 1000000 := by norm_num
example : 3 * ((1 : ℚ) / 100) ^ 2 * (99 / 100) = 297 / 1000000 := by norm_num
example : ((1 : ℚ) / 100) ^ 3 = 1 / 1000000 := by norm_num
example : (970299 : ℚ) / 1000000 + 29403 / 1000000 + 297 / 1000000 + 1 / 1000000 = 1 := by norm_num
-- The block fails with chance 3p² − 2p³ = 298/1,000,000 (0.0298%) at p = 1/100.
example : levelMap (1 / 100) = 298 / 1000000 := by norm_num [levelMap]
-- Try: p = 1/10 gives 7/250 (0.028); p = 3/5 gives 81/125 (0.648), worse than 3/5.
example : levelMap (1 / 10) = 7 / 250 := by norm_num [levelMap]
example : levelMap (3 / 5) = 81 / 125 := by norm_num [levelMap]
-- The bound (3p)^(2^k)/3 at p = 1/100, level 1: 3/10,000.
example : (3 * ((1 : ℚ) / 100)) ^ 2 / 3 = 3 / 10000 := by norm_num
-- The sign error Z₁ on 0.8|000⟩ + 0.6|111⟩ leaves fidelity (0.64 − 0.36)² = 49/625 (0.0784).
example : ((16 : ℚ) / 25 - 9 / 25) ^ 2 = 49 / 625 := by norm_num
-- The messy error's branch chances 0.9², 0.3², 0.3², 0.1² add to 1.
example : ((9 : ℚ) / 10) ^ 2 + (3 / 10) ^ 2 + (3 / 10) ^ 2 + (1 / 10) ^ 2 = 1 := by norm_num

-- Steane's code from Hamming's [7, 4] check matrix: each row has weight 4, each pair of rows
-- overlaps in 2 places (all even, so the X and Z checks commute), and column j spells j in binary.
example : ([[1,0,1,0,1,0,1], [0,1,1,0,0,1,1], [0,0,0,1,1,1,1]] : List (List ℕ)).map List.sum
    = [4, 4, 4] := by decide
example : (List.zipWith (· * ·) [1,0,1,0,1,0,1] [0,1,1,0,0,1,1] : List ℕ).sum = 2 ∧
    (List.zipWith (· * ·) [1,0,1,0,1,0,1] [0,0,0,1,1,1,1] : List ℕ).sum = 2 ∧
    (List.zipWith (· * ·) [0,1,1,0,0,1,1] [0,0,0,1,1,1,1] : List ℕ).sum = 2 := by decide
example : (List.range 7).map (fun j =>
      [1,0,1,0,1,0,1].getD j 0 + 2 * [0,1,1,0,0,1,1].getD j 0 + 4 * [0,0,0,1,1,1,1].getD j 0)
    = [1, 2, 3, 4, 5, 6, 7] := by decide

-- Overheads: three levels cost 3³ = 27 qubits (Steane 7³ = 343); a surface-code patch of
-- distance 3, 5, 7 uses (2d − 1)² = 25, 81, 169 qubits, with error powers (d + 1)/2 = 2, 3, 4.
example : 3 ^ 3 = 27 ∧ 7 ^ 3 = 343 := by norm_num
example : [3, 5, 7].map (fun d => (2 * d - 1) ^ 2) = [25, 81, 169] := by decide
example : [3, 5, 7].map (fun d => (d + 1) / 2) = [2, 3, 4] := by decide

#print axioms nested_bit_flip_code_threshold
#print axioms bit_flip_code_logical_error
#print axioms threshold_squaring_bound
