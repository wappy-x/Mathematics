-- Channel capacity: a link that flips each bit with chance p carries at most 1 - h(p) bits per use, reached when 0 and 1 are sent equally often, and a code above that rate keeps a floor under its error chance.
import Mathlib.Analysis.SpecialFunctions.BinaryEntropy
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Pi
import Mathlib.Order.Bounds.Basic
import Mathlib.Data.Nat.Choose.Sum

open Real Finset

/-- The chance that the sent bit is `x`, when the sender sends a 1 with chance `q`. -/
noncomputable def inputProb (q : ℝ) : Bool → ℝ := fun x => if x then q else 1 - q

/-- One use of the binary symmetric channel: the chance of receiving `y` when `x` was sent.
The bit arrives unchanged with chance `1 - p` and flipped with chance `p`. -/
noncomputable def bscTransition (p : ℝ) : Bool → Bool → ℝ := fun x y => if x = y then 1 - p else p

/-- The joint chance that `x` is sent and `y` received. -/
noncomputable def bscJoint (p q : ℝ) (x y : Bool) : ℝ := inputProb q x * bscTransition p x y

/-- The chance that `y` is received. -/
noncomputable def bscOutput (p q : ℝ) (y : Bool) : ℝ := ∑ x : Bool, bscJoint p q x y

/-- The mutual information `I(X; Y)` in bits, straight from the table of joint chances:
the sum of `P(x, y) log₂ (P(x, y) / (P(x) P(y)))`. Terms with `P(x, y) = 0` count as 0. -/
noncomputable def bscMutualInfo (p q : ℝ) : ℝ :=
  ∑ x : Bool, ∑ y : Bool,
    bscJoint p q x y * logb 2 (bscJoint p q x y / (inputProb q x * bscOutput p q y))

lemma mi_term_aux (a b o : ℝ) (hab : 0 ≤ a * b) (ho : a * b ≤ o) :
    a * b * logb 2 (a * b / (a * o)) = a * b * (log b - log o) / log 2 := by
  rcases eq_or_lt_of_le hab with h | h
  · rw [← h]; simp
  · have ha : a ≠ 0 := by rintro rfl; simp at h
    have hb : b ≠ 0 := by rintro rfl; simp at h
    have ho' : o ≠ 0 := by intro h'; rw [h'] at ho; linarith
    rw [mul_div_mul_left _ _ ha, logb, log_div hb ho', mul_div_assoc]

lemma bsc_mi_formula (p q : ℝ) (hp₀ : 0 ≤ p) (hp₁ : p ≤ 1) (hq₀ : 0 ≤ q) (hq₁ : q ≤ 1) :
    bscMutualInfo p q = (binEntropy (bscOutput p q true) - binEntropy p) / log 2 := by
  have hnn : ∀ x y, 0 ≤ bscJoint p q x y := by
    intro x y
    unfold bscJoint inputProb bscTransition
    split_ifs <;> nlinarith
  have hterm : ∀ x y, bscJoint p q x y * logb 2 (bscJoint p q x y / (inputProb q x * bscOutput p q y))
      = inputProb q x * bscTransition p x y * (log (bscTransition p x y) - log (bscOutput p q y)) / log 2 := by
    intro x y
    have h1 := hnn x y
    have h2 : bscJoint p q x y ≤ bscOutput p q y :=
      single_le_sum (f := fun x' => bscJoint p q x' y) (fun x' _ => hnn x' y) (mem_univ x)
    unfold bscJoint at h1 h2 ⊢
    exact mi_term_aux _ _ _ h1 h2
  have hot : bscOutput p q true = q * (1 - p) + (1 - q) * p := by
    simp [bscOutput, bscJoint, inputProb, bscTransition]
  have hof : bscOutput p q false = 1 - bscOutput p q true := by
    rw [hot]; simp [bscOutput, bscJoint, inputProb, bscTransition]; ring
  unfold bscMutualInfo
  simp only [hterm]
  simp only [Fintype.sum_bool, inputProb, bscTransition, Bool.false_eq_true, ite_true, ite_false,
    Bool.true_eq_false]
  rw [hof]
  unfold binEntropy
  rw [log_inv, log_inv, log_inv, log_inv]
  generalize hA : log (bscOutput p q true) = A
  generalize hB : log (1 - bscOutput p q true) = B
  rw [hot]
  field_simp
  ring

#print axioms mi_term_aux
#print axioms bsc_mi_formula

/-- The capacity of the binary symmetric channel. For a link that flips each bit with chance
`p`, the most information one use can carry, over every input mix `q` (the chance of sending a
1), is `C = 1 - h(p)` bits, where `h(p)` is the binary entropy in bits. The best mix is
`q = 1/2`. -/
theorem bsc_capacity_eq_one_sub_binary_entropy (p : ℝ) (hp₀ : 0 ≤ p) (hp₁ : p ≤ 1) :
    IsGreatest (bscMutualInfo p '' Set.Icc 0 1) (1 - binEntropy p / log 2) ∧
      bscMutualInfo p (1 / 2) = 1 - binEntropy p / log 2 := by
  have hl : 0 < log 2 := log_pos one_lt_two
  have hhalf : bscMutualInfo p (1 / 2) = 1 - binEntropy p / log 2 := by
    rw [bsc_mi_formula p _ hp₀ hp₁ (by norm_num) (by norm_num)]
    have : bscOutput p (1 / 2) true = 2⁻¹ := by
      simp [bscOutput, bscJoint, inputProb, bscTransition]; ring
    rw [this, binEntropy_two_inv, sub_div, div_self hl.ne']
  refine ⟨⟨⟨1 / 2, ⟨by norm_num, by norm_num⟩, hhalf⟩, ?_⟩, hhalf⟩
  rintro _ ⟨q, ⟨hq₀, hq₁⟩, rfl⟩
  rw [bsc_mi_formula p q hp₀ hp₁ hq₀ hq₁, sub_div, ← div_self hl.ne']
  gcongr
  exact binEntropy_le_log_two

/-- The converse, its last step. If the `nR` message bits are at most the `nC` bits the link
can tell plus Fano's `1 + P_e nR` bits still unknown, then every code of rate `R` and block
length `n` fails with chance `P_e ≥ 1 - C/R - 1/(nR)`. -/
theorem error_floor_above_capacity (n : ℕ) (R C Pe : ℝ) (hn : 0 < n) (hR : 0 < R)
    (hfano : n * R ≤ n * C + 1 + Pe * (n * R)) :
    1 - C / R - 1 / (n * R) ≤ Pe := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hnR : 0 < (n : ℝ) * R := mul_pos hn' hR
  have hC : 1 - C / R - 1 / (n * R) = (n * R - n * C - 1) / (n * R) := by field_simp
  rw [hC, div_le_iff₀ hnR]
  linarith

/-- Majority vote over `r` copies. Each copy flips on its own with chance `p`; the vote is
wrong exactly when more than half the copies flip. Summing the chances of those flip patterns
gives `∑_{k > r/2} C(r, k) p^k (1 - p)^(r - k)`. -/
theorem majority_vote_error (r : ℕ) (p : ℝ) :
    ∑ f : Fin r → Bool with r < 2 * #{i | f i = true},
        ∏ i, (if f i then p else 1 - p) =
      ∑ k ∈ Icc (r / 2 + 1) r, (r.choose k : ℝ) * p ^ k * (1 - p) ^ (r - k) := by
  set g : ℕ → ℝ := fun k => if r < 2 * k then p ^ k * (1 - p) ^ (r - k) else 0 with hg
  have h1 : ∑ f : Fin r → Bool with r < 2 * #{i | f i = true}, ∏ i, (if f i then p else 1 - p)
      = ∑ s ∈ (univ : Finset (Fin r)).powerset, g #s := by
    rw [sum_filter]
    refine sum_nbij' (fun f => ({i | f i = true} : Finset (Fin r))) (fun s i => decide (i ∈ s))
      ?_ ?_ ?_ ?_ ?_
    · intro f _; simp
    · intro s _; simp
    · intro f _; funext i; simp
    · intro s _; ext i; simp
    · intro f _
      simp only [hg]
      split_ifs with h
      · rw [prod_ite, prod_const, prod_const]
        congr 2
        have := card_filter_add_card_filter_not (s := (univ : Finset (Fin r)))
          (fun i => f i = true)
        simp only [card_univ, Fintype.card_fin] at this
        omega
      · rfl
  rw [h1, sum_powerset_apply_card, card_univ, Fintype.card_fin]
  have h2 : Icc (r / 2 + 1) r = (range (r + 1)).filter (fun k => r < 2 * k) := by
    ext k; simp; omega
  rw [h2, sum_filter]
  refine sum_congr rfl fun k _ => ?_
  simp only [hg, nsmul_eq_mul]
  split_ifs <;> ring

-- The day's log: 86,400 readings of 16 bits is 1,382,400 bits.
example : 86400 * 16 = 1382400 := by decide
-- At 1,000 bits a second: 23.04 minutes plain, 69.12 with three copies, 115.2 with five.
example : (1382400 : ℚ) / 1000 / 60 = 576 / 25 ∧ 3 * ((1382400 : ℚ) / 1000 / 60) = 1728 / 25 ∧
    5 * ((1382400 : ℚ) / 1000 / 60) = 576 / 5 := by norm_num
-- A plain upload at p = 1/100 has 13,824 wrong bits expected.
example : (1382400 : ℚ) * (1 / 100) = 13824 := by norm_num
-- Three copies: a bit is wrong with chance 3 p² (1 - p) + p³ = 0.000298, so 411.9552 wrong bits.
example : 3 * (1 / 100 : ℚ) ^ 2 * (99 / 100) + (1 / 100) ^ 3 = 149 / 500000 ∧
    (1382400 : ℚ) * (149 / 500000) = 257472 / 625 := by norm_num
-- Five copies: three or more flips, chance 49253/5000000000, so about 13.6 wrong bits.
example : 10 * (1 / 100 : ℚ) ^ 3 * (99 / 100) ^ 2 + 5 * (1 / 100) ^ 4 * (99 / 100) +
      (1 / 100) ^ 5 = 49253 / 5000000000 ∧
    (1382400 : ℚ) * (49253 / 5000000000) = 5319324 / 390625 := by norm_num
-- At p = 1/2 the capacity is 0: the received bit is a coin toss.
example : 1 - binEntropy 2⁻¹ / log 2 = 0 := by
  rw [binEntropy_two_inv, div_self (log_pos one_lt_two).ne', sub_self]
-- A link that flips 99 bits in 100 has the same capacity as one that flips 1 in 100.
example : 1 - binEntropy (99 / 100) / log 2 = 1 - binEntropy (1 / 100) / log 2 := by
  rw [show (99 / 100 : ℝ) = 1 - 1 / 100 by norm_num, binEntropy_one_sub]

#print axioms bsc_capacity_eq_one_sub_binary_entropy
#print axioms error_floor_above_capacity
#print axioms majority_vote_error
