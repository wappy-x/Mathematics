-- Many users: decoding one radio first and then the other reaches the two-radio channel's total cap exactly, decoding one station first puts the Slepian-Wolf corner on the line of the pair's entropy, and a week's 3-bit Hamming label recovers any week within one disagreement.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic

open Finset

namespace SlepianWolfMAC

/-! ## The two-radio channel in normal noise -/

/-- `C(x) = ½ log₂ (1 + x)`: one user's bits per pulse at signal-to-noise ratio `x`. -/
noncomputable def C (x : ℝ) : ℝ := (1 / 2) * Real.logb 2 (1 + x)

/-- Successive decoding reaches the corner of the two-radio region. Two radios of powers
`P₁, P₂ ≥ 0` share one receiver with normal noise of power `N > 0`. The receiver decodes radio 2
first, with radio 1 counted as extra noise, at `R₂ = C(P₂ / (P₁ + N))`; it subtracts radio 2 and
decodes radio 1 against the noise alone, at `R₁ = C(P₁ / N)`. Then radio 2's rate stays within its
own cap, `R₂ ≤ C(P₂ / N)`, and the two rates add up exactly to the total cap:
`R₁ + R₂ = C((P₁ + P₂) / N)`. -/
theorem successive_decoding_reaches_sum_capacity (P₁ P₂ N : ℝ) (hP₁ : 0 ≤ P₁) (hP₂ : 0 ≤ P₂)
    (hN : 0 < N) :
    C (P₂ / (P₁ + N)) ≤ C (P₂ / N) ∧
      C (P₁ / N) + C (P₂ / (P₁ + N)) = C ((P₁ + P₂) / N) := by
  have hPN : 0 < P₁ + N := by linarith
  have h2 : 0 < 1 + P₂ / (P₁ + N) := by positivity
  have h1 : 0 < 1 + P₁ / N := by positivity
  refine ⟨?_, ?_⟩
  · unfold C
    have : P₂ / (P₁ + N) ≤ P₂ / N := div_le_div_of_nonneg_left hP₂ hN (by linarith)
    have := Real.logb_le_logb_of_le (b := 2) (x := 1 + P₂ / (P₁ + N)) (y := 1 + P₂ / N) (by norm_num) h2 (by linarith)
    linarith
  · unfold C
    rw [← mul_add, ← Real.logb_mul h1.ne' h2.ne']
    congr 2
    field_simp
    ring

/-! ## Two stations coded apart, decoded together -/

variable {α β : Type*} [Fintype α] [Fintype β]

/-- Entropy in bits of a table of chances `q`: `H = -Σ q i · log₂ (q i)`
(Mathlib's `Real.logb 2 0 = 0`, so empty cells add nothing). -/
noncomputable def entropy {ι : Type*} [Fintype ι] (q : ι → ℝ) : ℝ :=
  -∑ i, q i * Real.logb 2 (q i)

/-- Station A's chances: the row sums of the joint table. -/
def margA (p : α × β → ℝ) (a : α) : ℝ := ∑ b, p (a, b)

/-- Station B's chances: the column sums of the joint table. -/
def margB (p : α × β → ℝ) (b : β) : ℝ := ∑ a, p (a, b)

/-- `H(B | A) = Σ_a P(A = a) · H(B | A = a)`. -/
noncomputable def condEntBA (p : α × β → ℝ) : ℝ :=
  ∑ a, margA p a * entropy (fun b => p (a, b) / margA p a)

/-- `H(A | B) = Σ_b P(B = b) · H(A | B = b)`. -/
noncomputable def condEntAB (p : α × β → ℝ) : ℝ :=
  ∑ b, margB p b * entropy (fun a => p (a, b) / margB p b)

omit [Fintype α] in
/-- A cell's chance is at most its row total. -/
lemma le_margA (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) (a : α) (b : β) : p (a, b) ≤ margA p a :=
  single_le_sum (f := fun b => p (a, b)) (fun b _ => hp (a, b)) (mem_univ b)

omit [Fintype β] in
/-- A cell's chance is at most its column total. -/
lemma le_margB (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) (a : α) (b : β) : p (a, b) ≤ margB p b :=
  single_le_sum (f := fun a => p (a, b)) (fun a _ => hp (a, b)) (mem_univ a)

/-- `m · (x/m) · logb (x/m) = x · logb (x/m)` whenever `0 ≤ x ≤ m`. -/
lemma mul_div_cell (x m : ℝ) (hx : 0 ≤ x) (hm : x ≤ m) :
    m * (x / m * Real.logb 2 (x / m)) = x * Real.logb 2 (x / m) := by
  rcases eq_or_lt_of_le hx with h | h
  · subst h; simp
  · have : m ≠ 0 := by linarith
    rw [← mul_assoc, mul_div_cancel₀ _ this]

/-- `x · logb (x/m) = x · logb x - x · logb m` whenever `0 ≤ x ≤ m`. -/
lemma cell_log_div (x m : ℝ) (hx : 0 ≤ x) (hm : x ≤ m) :
    x * Real.logb 2 (x / m) = x * Real.logb 2 x - x * Real.logb 2 m := by
  rcases eq_or_lt_of_le hx with h | h
  · subst h; simp
  · rw [Real.logb_div h.ne' (by linarith)]; ring

lemma condEntAB_eq (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) :
    condEntAB p = -∑ a, ∑ b, p (a, b) * Real.logb 2 (p (a, b) / margB p b) := by
  unfold condEntAB entropy
  rw [sum_comm, ← sum_neg_distrib]
  refine sum_congr rfl fun b _ => ?_
  rw [mul_neg, mul_sum]
  congr 1
  refine sum_congr rfl fun a _ => ?_
  exact mul_div_cell _ _ (hp _) (le_margB p hp a b)

lemma condEntBA_eq (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) :
    condEntBA p = -∑ a, ∑ b, p (a, b) * Real.logb 2 (p (a, b) / margA p a) := by
  unfold condEntBA entropy
  rw [← sum_neg_distrib]
  refine sum_congr rfl fun a _ => ?_
  rw [mul_neg, mul_sum]
  congr 1
  refine sum_congr rfl fun b _ => ?_
  exact mul_div_cell _ _ (hp _) (le_margA p hp a b)

lemma entropy_margA_eq (p : α × β → ℝ) :
    entropy (margA p) = -∑ a, ∑ b, p (a, b) * Real.logb 2 (margA p a) := by
  unfold entropy
  congr 1
  refine sum_congr rfl fun a _ => ?_
  rw [← sum_mul]; rfl

/-- The pointwise Gibbs bound: `x · (logb mA - logb (x/mB)) ≤ (mA · mB - x) / ln 2`. -/
lemma cell_gibbs (x mA mB : ℝ) (hx : 0 ≤ x) (hA : x ≤ mA) (hB : x ≤ mB) :
    x * Real.logb 2 mA - x * Real.logb 2 (x / mB) ≤ (mA * mB - x) / Real.log 2 := by
  have hl : 0 < Real.log 2 := Real.log_pos (by norm_num)
  rcases eq_or_lt_of_le hx with h | h
  · subst h
    have : 0 ≤ mA * mB := mul_nonneg hA hB
    simp only [zero_mul, sub_zero, zero_div]
    positivity
  · have hA' : 0 < mA := lt_of_lt_of_le h hA
    have hB' : 0 < mB := lt_of_lt_of_le h hB
    have key : x * Real.log (mA * mB / x) ≤ mA * mB - x := by
      have := Real.log_le_sub_one_of_pos (show 0 < mA * mB / x by positivity)
      calc x * Real.log (mA * mB / x) ≤ x * (mA * mB / x - 1) :=
            mul_le_mul_of_nonneg_left this hx
        _ = mA * mB - x := by field_simp
    rw [Real.log_div (by positivity) h.ne', Real.log_mul hA'.ne' hB'.ne'] at key
    rw [le_div_iff₀ hl]
    simp only [Real.logb, Real.log_div h.ne' hB'.ne']
    have e : (x * (Real.log mA / Real.log 2) - x * ((Real.log x - Real.log mB) / Real.log 2))
        * Real.log 2 = x * (Real.log mA + Real.log mB - Real.log x) := by
      field_simp; ring
    rw [e]; exact key

/-- The Slepian-Wolf corner reached by decoding station A first. For any joint table of chances
`p` on two stations' readings with finitely many values (each chance at least 0, all adding to 1),
the rate pair `(R_A, R_B) = (H(A), H(B | A))` lies in the Slepian-Wolf region
`R_A ≥ H(A | B)`, `R_B ≥ H(B | A)`, `R_A + R_B ≥ H(A, B)`: the first because `H(A | B) ≤ H(A)`,
the second with equality, and the third because the pair sits exactly on the line of the total,
`H(A) + H(B | A) = H(A, B)` (the chain rule). -/
theorem slepian_wolf_corner_on_sum_line (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z)
    (hsum : ∑ z, p z = 1) :
    condEntAB p ≤ entropy (margA p) ∧ entropy (margA p) + condEntBA p = entropy p := by
  have hA1 : ∑ a, margA p a = 1 := by
    rw [← hsum, Fintype.sum_prod_type]; rfl
  have hB1 : ∑ b, margB p b = 1 := by
    rw [← hsum, Fintype.sum_prod_type, sum_comm]; rfl
  refine ⟨?_, ?_⟩
  · rw [condEntAB_eq p hp, entropy_margA_eq]
    have hle : ∑ a, ∑ b, (p (a, b) * Real.logb 2 (margA p a)
        - p (a, b) * Real.logb 2 (p (a, b) / margB p b)) ≤
        ∑ a, ∑ b, (margA p a * margB p b - p (a, b)) / Real.log 2 :=
      sum_le_sum fun a _ => sum_le_sum fun b _ =>
        cell_gibbs _ _ _ (hp _) (le_margA p hp a b) (le_margB p hp a b)
    have hzero : ∑ a, ∑ b, (margA p a * margB p b - p (a, b)) / Real.log 2 = 0 := by
      simp only [← sum_div, sum_sub_distrib, ← mul_sum, ← sum_mul, hB1, hA1]
      rw [show (∑ a, ∑ b, p (a, b)) = 1 from hA1]
      simp
    simp only [sum_sub_distrib] at hle
    linarith
  · rw [condEntBA_eq p hp, entropy_margA_eq]
    unfold entropy
    rw [Fintype.sum_prod_type]
    have : ∀ a b, p (a, b) * Real.logb 2 (p (a, b) / margA p a)
        = p (a, b) * Real.logb 2 (p (a, b)) - p (a, b) * Real.logb 2 (margA p a) :=
      fun a b => cell_log_div _ _ (hp _) (le_margA p hp a b)
    simp only [this, sum_sub_distrib]
    ring

/-! ## A week of it: bins from the Hamming (7,4) parity check -/

/-- A week is 7 bits in a whole number, day `i + 1` being bit `i` (1 for rain). Its label is the
XOR of the numbers of its rainy days: the syndrome under the Hamming (7,4) check, whose column
`i` is the number `i` in binary. -/
def syndrome (w : ℕ) : ℕ :=
  (List.range 7).foldl (fun s i => if w.testBit i then s ^^^ (i + 1) else s) 0

/-- The office holds A's week `a` and B's 3-bit label `s`. It XORs A's own label with `s`; a
result of 0 means the weeks agree, and any other value `t` names the one day to flip. -/
def decode (a s : ℕ) : ℕ :=
  if syndrome a ^^^ s = 0 then a else a ^^^ 2 ^ ((syndrome a ^^^ s) - 1)

/-- Checked case by case: for every week `a` and every day `i`, flipping day `i + 1` gives a week
the office rebuilds from `a` and that week's label. -/
theorem flips_ok : ∀ a < 128, ∀ i < 7, decode a (syndrome (a ^^^ 2 ^ i)) = a ^^^ 2 ^ i := by
  decide

/-- The week-long label works whenever the week has at most one disagreement: for any weeks `a`
(station A) and `b` (station B) of 7 days, if they agree on every day or differ on exactly one,
the office rebuilds B's week from A's week and B's 3-bit label alone. -/
theorem hamming_label_recovers_week (a b : ℕ) (ha : a < 128) (hb : b < 128)
    (h1 : a ^^^ b = 0 ∨ ∃ i, i < 7 ∧ a ^^^ b = 2 ^ i) :
    decode a (syndrome b) = b := by
  clear hb
  have hb' : b = a ^^^ (a ^^^ b) := by
    rw [← Nat.xor_assoc, Nat.xor_self, Nat.zero_xor]
  rcases h1 with h | ⟨i, hi, h⟩
  · rw [h, Nat.xor_zero] at hb'
    subst hb'
    simp [decode]
  · rw [h] at hb'
    rw [hb']
    exact flips_ok a ha i hi

end SlepianWolfMAC

open SlepianWolfMAC

-- The card's worked week: A rains on days 1, 3, 4, 7 and B on days 1, 3, 4, 5, 7.
-- B sends 1 XOR 3 XOR 4 XOR 5 XOR 7 = 4; A's label is 1 XOR 3 XOR 4 XOR 7 = 1; 4 XOR 1 = 5.
example : 1 ^^^ 3 ^^^ 4 ^^^ 5 ^^^ 7 = 4 ∧ 1 ^^^ 3 ^^^ 4 ^^^ 7 = 1 ∧ 4 ^^^ 1 = 5 := by decide
-- The same with the definitions: days 1..7 are bits 0..6, so A's week is 0b1001101 and B's is
-- 0b1011101; the office flips day 5 and gets B's week right.
example : syndrome 0b1011101 = 4 ∧ syndrome 0b1001101 = 1 ∧
    decode 0b1001101 (syndrome 0b1011101) = 0b1011101 := by decide
-- 3 bits buy 2^3 = 8 labels, fewer than the 2^7 = 128 disagreement patterns of a week.
example : 2 ^ 3 = 8 ∧ 2 ^ 7 = 128 ∧ 8 < 128 := by decide
-- The label works in 0.9^7 + 7 × 0.1 × 0.9^6 = 0.8503056 of weeks (card: 0.850306).
example : (9 / 10 : ℚ) ^ 7 + 7 * (1 / 10) * (9 / 10) ^ 6 = 8503056 / 10 ^ 7 := by norm_num
-- B alone at 0.55 bits a day over 1,000 days: log₂ of the best success is 550 - 1000 = -450.
example : (550 : ℤ) - 1000 = -450 := by norm_num
-- The radio corner: 0.292 + 0.5 = 0.792 because (1 + 1/2) × (1 + 1) = 1 + 2 inside the logs.
example : (1 + 1 / 2 : ℚ) * (1 + 1) = 1 + 2 := by norm_num

#print axioms le_margA
#print axioms le_margB
#print axioms mul_div_cell
#print axioms cell_log_div
#print axioms condEntAB_eq
#print axioms condEntBA_eq
#print axioms entropy_margA_eq
#print axioms cell_gibbs
#print axioms flips_ok
#print axioms successive_decoding_reaches_sum_capacity
#print axioms slepian_wolf_corner_on_sum_line
#print axioms hamming_label_recovers_week
