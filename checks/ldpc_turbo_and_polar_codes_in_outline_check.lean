-- LDPC, turbo and polar codes: a parity check's verdict on independent bits is the product of their tanh(L/2) certainties, and one polar step splits an erasure chance ε into 2ε - ε² and ε² without losing any.
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.Group.Nat.Even

open Real Finset

/-- The chance that a bit with confidence `L` was `b`. Confidence `L` is the log of
`Pr(0) / Pr(1)`, so `Pr(0) = e^L / (1 + e^L)` and `Pr(1) = 1 / (1 + e^L)`. Here `false` is 0
and `true` is 1. -/
noncomputable def bitProb (L : ℝ) (b : Bool) : ℝ :=
  if b then 1 / (1 + exp L) else exp L / (1 + exp L)

theorem tanh_half_eq (L : ℝ) : tanh (L / 2) = (exp L - 1) / (exp L + 1) := by
  rw [Real.tanh_eq_sinh_div_cosh, Real.sinh_eq, Real.cosh_eq]
  have h1 : exp L = exp (L/2) * exp (L/2) := by rw [← Real.exp_add]; ring_nf
  have h2 : exp (-(L/2)) = (exp (L/2))⁻¹ := Real.exp_neg _
  have hp : 0 < exp (L/2) := exp_pos _
  rw [h1, h2]
  field_simp

#print axioms tanh_half_eq

/-- The check rule of belief propagation. Take independent bits, bit `i` with confidence
`L i`, and their sum modulo 2. The chance that the sum is 0 (an even number of ones) minus the
chance that it is 1 (an odd number) is the product of the separate `tanh(L i / 2)` values. -/
theorem check_rule_tanh_product {ι : Type*} [Fintype ι] [DecidableEq ι] (L : ι → ℝ) :
    (∑ f : ι → Bool with Even #{i | f i = true}, ∏ i, bitProb (L i) (f i)) -
        (∑ f : ι → Bool with ¬ Even #{i | f i = true}, ∏ i, bitProb (L i) (f i)) =
      ∏ i, tanh (L i / 2) := by
  have key : ∀ i, tanh (L i / 2) = ∑ b : Bool, (if b then (-1 : ℝ) else 1) * bitProb (L i) b := by
    intro i
    have hp : 0 < 1 + exp (L i) := by positivity
    rw [tanh_half_eq, Fintype.sum_bool]; simp only [bitProb, Bool.false_eq_true, ite_false, ite_true]
    rw [add_comm (exp (L i)) 1]; field_simp; ring
  simp_rw [key]
  rw [Fintype.prod_sum]
  have hterm : ∀ f : ι → Bool, (∏ i, (if f i then (-1 : ℝ) else 1) * bitProb (L i) (f i)) =
      (-1) ^ #{i | f i = true} * ∏ i, bitProb (L i) (f i) := by
    intro f
    rw [Finset.prod_mul_distrib, Finset.prod_ite]
    simp
  simp_rw [hterm]
  rw [← Finset.sum_filter_add_sum_filter_not univ (fun f : ι → Bool => Even #{i | f i = true})]
  rw [sub_eq_add_neg]
  congr 1
  · apply Finset.sum_congr rfl
    intro f hf
    rw [Finset.mem_filter] at hf
    rw [hf.2.neg_one_pow, one_mul]
  · rw [← Finset.sum_neg_distrib]
    apply Finset.sum_congr rfl
    intro f hf
    rw [Finset.mem_filter, Nat.not_even_iff_odd] at hf
    rw [hf.2.neg_one_pow]; ring

/-- One bit's confidence. The chances `e^L / (1 + e^L)` and `1 / (1 + e^L)` add to 1, the log
of their ratio is the confidence `L` itself, and their difference is `tanh(L / 2)`: a number
from -1 (surely 1) to +1 (surely 0). -/
theorem bit_confidence_tanh (L : ℝ) :
    bitProb L false + bitProb L true = 1 ∧
      log (bitProb L false / bitProb L true) = L ∧
      bitProb L false - bitProb L true = tanh (L / 2) := by
  have hp : 0 < 1 + exp L := by positivity
  refine ⟨?_, ?_, ?_⟩
  · simp only [bitProb, Bool.false_eq_true, ite_false, ite_true]; rw [← add_div, add_comm]; exact div_self hp.ne'
  · simp only [bitProb, Bool.false_eq_true, ite_false, ite_true]
    rw [div_div_div_cancel_right₀ hp.ne', div_one, Real.log_exp]
  · rw [tanh_half_eq]; simp only [bitProb, Bool.false_eq_true, ite_false, ite_true]
    rw [add_comm (exp L) 1]; field_simp

/-- The chance of an erasure pattern on two copies of an erasure channel: output `i` is
erased (`f i = true`) with chance `ε`, independently. -/
noncomputable def erasurePatternProb (ε : ℝ) (f : Fin 2 → Bool) : ℝ :=
  ∏ i, if f i then ε else 1 - ε

/-- One polar step on an erasure channel with erasure chance `ε`. Send `u₁ + u₂` on one copy
and `u₂` on the other. `u₁` is lost unless both outputs arrive, which happens with chance
`z⁻ = 1 - (1 - ε)² = 2ε - ε²`. With `u₁` known, `u₂` is lost only if both outputs are erased,
with chance `z⁺ = ε²`. The two chances average to `ε`: nothing lost, only redistributed. -/
theorem polar_one_step_erasure (ε : ℝ) :
    (∑ f : Fin 2 → Bool with ∃ i, f i = true, erasurePatternProb ε f) = 1 - (1 - ε) ^ 2 ∧
      1 - (1 - ε) ^ 2 = 2 * ε - ε ^ 2 ∧
      (∑ f : Fin 2 → Bool with ∀ i, f i = true, erasurePatternProb ε f) = ε ^ 2 ∧
      ((2 * ε - ε ^ 2) + ε ^ 2) / 2 = ε := by
  refine ⟨?_, by ring, ?_, by ring⟩
  · rw [Finset.sum_filter, ← (finTwoArrowEquiv Bool).symm.sum_comp, Fintype.sum_prod_type]
    simp [erasurePatternProb, Fin.exists_fin_two, Fin.prod_univ_two]
    ring
  · rw [Finset.sum_filter, ← (finTwoArrowEquiv Bool).symm.sum_comp, Fintype.sum_prod_type]
    simp [erasurePatternProb, Fin.forall_fin_two, Fin.prod_univ_two]
    ring

-- The Hamming (7,4) Tanner graph: checks A, B, C on bits {1,3,5,7}, {2,3,6,7}, {4,5,6,7}, 12 edges.
def hammingChecks : List (List ℕ) := [[1, 3, 5, 7], [2, 3, 6, 7], [4, 5, 6, 7]]

/-- The parity of one check on a word given as a list of bits, positions counted from 1. -/
def checkParity (w : List ℕ) (c : List ℕ) : ℕ := (c.map fun v => w.getD (v - 1) 0).sum % 2

example : (hammingChecks.map List.length).sum = 12 := by decide
-- The sent word 0110011 meets all three checks.
example : hammingChecks.map (checkParity [0, 1, 1, 0, 0, 1, 1]) = [0, 0, 0] := by decide
-- Hard decisions 0100111 give syndrome 0, 1, 1, pointing at bit 0 + 2 + 4 = 6; flipping it gives
-- 0100101, 3 bits away from the sent word.
example : hammingChecks.map (checkParity [0, 1, 0, 0, 1, 1, 1]) = [0, 1, 1] ∧ 0 + 2 * 1 + 4 * 1 = 6 ∧
    (List.zipWith (fun a b => if a = b then 0 else 1) [0, 1, 0, 0, 1, 0, 1] [0, 1, 1, 0, 0, 1, 1]).sum = 3 := by
  decide

/-- Min-sum, no offset: the message from a check to its `t`-th bit is the sign of the product
of the other bits' confidences times the smallest other size. -/
def minSumMsg (ins : List ℤ) (t : ℕ) : ℤ :=
  let o := ins.eraseIdx t
  (if (o.filter (· < 0)).length % 2 = 0 then 1 else -1) * ((o.map Int.natAbs).min?.getD 0 : ℕ)

-- Round 1 of min-sum on the confidences +4, −5, +1, +3, −1, −4, −6.
-- Check A (bits 1, 3, 5, 7) sends 1, 1, −1, −1.
example : [0, 1, 2, 3].map (minSumMsg [4, 1, -1, -6]) = [1, 1, -1, -1] := by decide
-- Check B (bits 2, 3, 6, 7) sends 1, −4, 1, 1.
example : [0, 1, 2, 3].map (minSumMsg [-5, 1, -4, -6]) = [1, -4, 1, 1] := by decide
-- Check C (bits 4, 5, 6, 7) sends −1, 3, 1, 1.
example : [0, 1, 2, 3].map (minSumMsg [3, -1, -4, -6]) = [-1, 3, 1, 1] := by decide
-- Totals: each L plus its checks' messages, +5, −4, −2, +2, +1, −2, −5; signs give 0110011.
example : ((4 : ℤ) + 1, (-5 : ℤ) + 1, (1 : ℤ) + 1 - 4, (3 : ℤ) - 1, (-1 : ℤ) - 1 + 3, (-4 : ℤ) + 1 + 1,
    (-6 : ℤ) - 1 + 1 + 1) = (5, -4, -2, 2, 1, -2, -5) := by decide

/-- The (7,5) convolutional encoder: two output bits per input bit, `u + a + b` and `u + b`,
with `a`, `b` the last two inputs; two 0s are fed at the end to empty the memory. -/
def conv75 (u : List Bool) : List Bool :=
  ((u ++ [false, false]).foldl
      (fun (s : Bool × Bool × List Bool) x =>
        (x, s.1, s.2.2 ++ [xor (xor x s.1) s.2.1, xor x s.2.1]))
      (false, false, [])).2.2

-- 23 °C is 00010111; with two 0s added its codeword is the 20 bits 00000011100001100111.
example : (0 * 128 + 0 * 64 + 0 * 32 + 1 * 16 + 0 * 8 + 1 * 4 + 1 * 2 + 1 : ℕ) = 23 := by decide
example : conv75 [false, false, false, true, false, true, true, true] =
    [false, false, false, false, false, false, true, true, true, false,
     false, false, false, true, true, false, false, true, true, true] := by decide

/-- The polar recursion: each erasure chance `z` becomes the worse `2z - z²` and the better `z²`. -/
def polarZ : ℕ → ℚ → List ℚ
  | 0, e => [e]
  | n + 1, e => (polarZ n e).flatMap fun q => [2 * q - q * q, q * q]

-- At N = 8 and ε = 1/2, the sub-channels are lost 255, 225, 207, 81, 175, 49, 31 and 1 time
-- in 256; the best four are u₄, u₆, u₇, u₈.
example : (polarZ 3 (1 / 2)).map (· * 256) = [255, 225, 207, 81, 175, 49, 31, 1] := by
  norm_num [polarZ]

-- The LDPC code: 504 bits, 3 checks per bit and 6 bits per check give 252 checks and 1512 edges;
-- rank 250 leaves 254 data bits, a rate 254/504 a shade above 1/2.
example : 504 * 3 = 252 * 6 ∧ 504 * 3 = 1512 ∧ 504 - 250 = 254 := by decide
example : (1 / 2 : ℚ) < 254 / 504 := by norm_num
-- The Hamming frame: 63 blocks of 7 bits carry 252 data bits in 441 bits sent.
example : 63 * 7 = 441 ∧ 63 * 4 = 252 := by decide

#print axioms check_rule_tanh_product
#print axioms bit_confidence_tanh
#print axioms polar_one_step_erasure
