-- Convolutional networks: on a wrap-round image, shifting the input of a convolutional layer shifts every output map by the same amount, the map sums do not move at all, and the output side is the floor formula plus one.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Group.MinMax
import Mathlib.Data.Fintype.Sum
import Mathlib.Basic.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum

open Finset

namespace ConvNet

/-- The convolutional layer on a wrap-round image (a torus): rows are counted modulo `n`,
columns modulo `n'`, and pixel `(r, c)` of the image is `x r c`. Filter `f` (one of `F`) has a
`k` by `k` grid of weights `w f a b` and a bias `bias f`; the layer lays the filter's top-left
corner at `(i, j)`, multiplies each weight by the pixel under it, adds them up, adds the bias,
and applies the squashing function `σ` (ReLU on the card) to that one number. The same weights
are used at every position, and the filter stops at every position (stride 1). -/
def conv {n n' k F : ℕ} (w : Fin F → Fin k → Fin k → ℝ) (bias : Fin F → ℝ) (σ : ℝ → ℝ)
    (x : ZMod n → ZMod n' → ℝ) : Fin F → ZMod n → ZMod n' → ℝ :=
  fun f i j => σ (bias f + ∑ a : Fin k, ∑ b : Fin k,
    w f a b * x (i + ((a : ℕ) : ZMod n)) (j + ((b : ℕ) : ZMod n')))

/-- The shift `T_{u,v}`: move the picture down `u` rows and right `v` columns, so
`(T_{u,v} x)[r, c] = x[r - u, c - v]`, with indices taken round the torus. -/
def shift {α : Type*} {n n' : ℕ} (u : ZMod n) (v : ZMod n') (x : ZMod n → ZMod n' → α) :
    ZMod n → ZMod n' → α :=
  fun r c => x (r - u) (c - v)

/-- The shift rule (translation equivariance). On a wrap-round image, a layer that uses the
same weights and bias at every position, stops at every position, and squashes one number at
a time gives, for an input shifted by a whole number of pixels, exactly the original output
maps shifted by the same amount: `conv (T_{u,v} x) = T_{u,v} (conv x)`, for every filter. -/
theorem conv_shift_eq_shift_conv {n n' k F : ℕ} (w : Fin F → Fin k → Fin k → ℝ)
    (bias : Fin F → ℝ) (σ : ℝ → ℝ) (x : ZMod n → ZMod n' → ℝ) (u : ZMod n) (v : ZMod n') :
    conv w bias σ (shift u v x) = fun f => shift u v (conv w bias σ x f) := by
  funext f i j
  simp only [conv, shift, sub_add_eq_add_sub]

/-- Global pooling is fully invariant: adding up each whole output map gives the same map sums
whether or not the input was shifted, because a sum does not care about the order of its terms. -/
theorem map_sums_shift_invariant {n n' k F : ℕ} [NeZero n] [NeZero n']
    (w : Fin F → Fin k → Fin k → ℝ) (bias : Fin F → ℝ) (σ : ℝ → ℝ)
    (x : ZMod n → ZMod n' → ℝ) (u : ZMod n) (v : ZMod n') (f : Fin F) :
    ∑ i : ZMod n, ∑ j : ZMod n', conv w bias σ (shift u v x) f i j
      = ∑ i : ZMod n, ∑ j : ZMod n', conv w bias σ x f i j := by
  rw [conv_shift_eq_shift_conv]
  simp only [shift]
  exact Fintype.sum_equiv (Equiv.subRight u) _ _
    (fun i => Fintype.sum_equiv (Equiv.subRight v) _ _ (fun j => rfl))

/-- Counting the stops: on an image of side `n` padded with `p` rings of zeros, a filter of
side `k` that fits (`k ≤ n + 2p`) and moves `s ≥ 1` pixels between stops has its left edge at
the multiples of `s` from `0` to `n + 2p - k`, and there are `⌊(n + 2p - k)/s⌋ + 1` of them. -/
theorem output_side_eq_count_of_stops (n k p s : ℕ) (hs : 0 < s) (hk : k ≤ n + 2 * p) :
    ((range (n + 2 * p + 1)).filter (fun t => s ∣ t ∧ t + k ≤ n + 2 * p)).card
      = (n + 2 * p - k) / s + 1 := by
  have key : (range (n + 2 * p + 1)).filter (fun t => s ∣ t ∧ t + k ≤ n + 2 * p)
      = (range ((n + 2 * p - k) / s + 1)).map ⟨fun q => q * s, mul_left_injective₀ hs.ne'⟩ := by
    ext t
    simp only [mem_filter, mem_range, mem_map, Function.Embedding.coeFn_mk]
    constructor
    · rintro ⟨-, ⟨q, rfl⟩, h⟩
      refine ⟨q, ?_, mul_comm q s⟩
      have h1 : q * s ≤ n + 2 * p - k := by rw [mul_comm]; omega
      have h2 : q ≤ (n + 2 * p - k) / s := (Nat.le_div_iff_mul_le hs).2 h1
      omega
    · rintro ⟨q, hq, rfl⟩
      have h2 : q ≤ (n + 2 * p - k) / s := by omega
      have h1 : q * s ≤ n + 2 * p - k := (Nat.le_div_iff_mul_le hs).1 h2
      refine ⟨by omega, ⟨q, mul_comm q s⟩, by omega⟩
  rw [key, card_map, card_range]

-- The card's six settings (n, k, p, s) and their map sides, by the formula.
example : (28 + 2 * 0 - 3) / 1 + 1 = 26 := by norm_num
example : (28 + 2 * 1 - 3) / 1 + 1 = 28 := by norm_num
example : (28 + 2 * 0 - 5) / 1 + 1 = 24 := by norm_num
example : (28 + 2 * 0 - 3) / 2 + 1 = 13 := by norm_num
example : (26 + 2 * 0 - 2) / 2 + 1 = 13 := by norm_num
example : (224 + 2 * 3 - 7) / 2 + 1 = 112 := by norm_num

-- The digit's stops counted directly: 26 window starts fit along a row of 28 pixels.
example : ((range (28 + 2 * 0 + 1)).filter (fun t => 1 ∣ t ∧ t + 3 ≤ 28 + 2 * 0)).card = 26 := by
  decide

-- Parameters: 8 filters, each with 3 x 3 weight slots and one bias, give 8 x (9 + 1) = 80.
example : Fintype.card (Fin 8 × (Fin 3 × Fin 3 ⊕ Unit)) = 80 := by decide
example : 8 * (3 ^ 2 * 1 + 1) = 80 := by norm_num

-- Output numbers, the dense layer and the matrix entries the layer can set.
example : 26 * 26 * 8 = 5408 := by norm_num
example : 784 * 5408 = 4239872 := by norm_num
example : 784 * 5408 + 5408 = 4245280 := by norm_num
example : 5408 * 9 = 48672 := by norm_num
example : 4239872 / 80 = 52998 := by norm_num
example : 13 * 13 * 8 = 1352 := by norm_num

-- By hand: filter 1 ("ink below") on the patch at row 5, column 9 scores 3, minus the bias 1, ReLU 2.
example :
    max 0 ((-1 : ℤ) + ∑ a : Fin 3, ∑ b : Fin 3,
      (![![-1, -1, -1], ![0, 0, 0], ![1, 1, 1]] : Fin 3 → Fin 3 → ℤ) a b *
      (![![0, 0, 0], ![1, 1, 1], ![1, 1, 1]] : Fin 3 → Fin 3 → ℤ) a b) = 2 := by
  decide

-- The mistakes: forgetting the bias gives 72; taking the side as n - k gives 25 and 5,000 numbers.
example : 8 * 9 = 72 := by norm_num
example : 28 - 3 = 25 ∧ 25 * 25 * 8 = 5000 := by norm_num

#print axioms conv_shift_eq_shift_conv
#print axioms map_sums_shift_invariant
#print axioms output_side_eq_count_of_stops

end ConvNet
