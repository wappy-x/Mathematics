-- Softmax and cross-entropy: softmax turns any scores into positive chances that add to 1 whose ratios are the exponentials of the score gaps, the slope of the loss in each score is "predicted minus actual", and the average cross-entropy charge is smallest exactly when the model reports the true chances.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

namespace SoftmaxCard

open Real

/-- Softmax of a list of scores `z`: each class's chance is its exponentiated score as a share
of all the exponentiated scores, ŷ_k = e^{z_k} / Σ_j e^{z_j}. -/
noncomputable def softmax {ι : Type*} [Fintype ι] (z : ι → ℝ) (k : ι) : ℝ :=
  exp (z k) / ∑ j, exp (z j)

/-- The entropy in bits of a list of chances `p`: H(p) = -Σ p_k log2 p_k. A class of chance 0
adds nothing, since its term is 0 · log2 0 = 0. -/
noncomputable def entropy {ι : Type*} [Fintype ι] (p : ι → ℝ) : ℝ :=
  -∑ k, p k * logb 2 (p k)

/-- The cross-entropy in bits: the average surprise H(p, q) = -Σ p_k log2 q_k when the truth
is `p` and the model bets on `q`. -/
noncomputable def crossEntropy {ι : Type*} [Fintype ι] (p q : ι → ℝ) : ℝ :=
  -∑ k, p k * logb 2 (q k)

/-- Helper: one class's share of Gibbs' inequality, in nats. -/
theorem gibbs_term (p q : ℝ) (hp : 0 ≤ p) (hq : 0 ≤ q) (hpos : 0 < p → 0 < q) :
    p * log q - p * log p ≤ q - p ∧ (p * log q - p * log p = q - p → q = p) := by
  rcases hp.eq_or_lt with h0 | hp'
  · subst h0
    simp only [zero_mul, sub_zero, sub_self]
    exact ⟨hq, fun h => h.symm⟩
  · have hq' := hpos hp'
    have hx : 0 < q / p := div_pos hq' hp'
    have hlog : log q - log p = log (q / p) := (log_div hq'.ne' hp'.ne').symm
    have key : p * log q - p * log p = p * log (q / p) := by rw [← hlog]; ring
    have hqp : p * (q / p - 1) = q - p := by field_simp
    refine ⟨?_, ?_⟩
    · rw [key, ← hqp]
      exact mul_le_mul_of_nonneg_left (log_le_sub_one_of_pos hx) hp'.le
    · intro h
      by_contra hne
      have hx1 : q / p ≠ 1 := by
        intro h1; apply hne; field_simp at h1; linarith
      have := mul_lt_mul_of_pos_left (log_lt_sub_one_of_pos hx hx1) hp'
      rw [hqp, ← key] at this
      linarith

#print axioms gibbs_term

/-- **Telling the truth wins (cross-entropy is a proper scoring rule).** Let the classes be
any finite set, exactly one of which happens: the true chances `p` and the model's chances `q`
are each at least 0 and add to 1. Let `q` give a chance above zero to every class that `p` can
produce (otherwise some order is charged without limit, H(p, q) is infinite, and there is
nothing to prove). Then the model's average charge H(p, q) is at least the entropy H(p), and it
equals H(p) exactly when the model reports the true chances, `q = p`. -/
theorem cross_entropy_minimized_exactly_by_true_chances {ι : Type*} [Fintype ι]
    (p q : ι → ℝ) (hp : ∀ k, 0 ≤ p k) (hp1 : ∑ k, p k = 1)
    (hq : ∀ k, 0 ≤ q k) (hq1 : ∑ k, q k = 1) (hpos : ∀ k, 0 < p k → 0 < q k) :
    entropy p ≤ crossEntropy p q ∧ (crossEntropy p q = entropy p ↔ q = p) := by
  have hl2 : 0 < log 2 := log_pos (by norm_num)
  have hT := fun k => gibbs_term (p k) (q k) (hp k) (hq k) (hpos k)
  have hdiff : crossEntropy p q - entropy p
      = -(∑ k, (p k * log (q k) - p k * log (p k))) / log 2 := by
    simp only [crossEntropy, entropy, logb, Finset.sum_sub_distrib]
    ring_nf
    rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_neg_distrib, ← Finset.sum_neg_distrib,
      ← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun x _ => by ring
  have hsum : ∑ k, (q k - p k) = 0 := by rw [Finset.sum_sub_distrib, hq1, hp1]; ring
  have hle : ∑ k, (p k * log (q k) - p k * log (p k)) ≤ 0 := by
    rw [← hsum]; exact Finset.sum_le_sum fun k _ => (hT k).1
  refine ⟨?_, ?_, ?_⟩
  · have : 0 ≤ crossEntropy p q - entropy p := by
      rw [hdiff]; exact div_nonneg (by linarith) hl2.le
    linarith
  · intro h
    have h0 : ∑ k, (p k * log (q k) - p k * log (p k)) = 0 := by
      have : crossEntropy p q - entropy p = 0 := by linarith
      rw [hdiff, div_eq_zero_iff] at this
      rcases this with h1 | h1
      · linarith
      · exact absurd h1 hl2.ne'
    have hz : ∑ k, ((q k - p k) - (p k * log (q k) - p k * log (p k))) = 0 := by
      rw [Finset.sum_sub_distrib, hsum, h0]; ring
    have hall := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => sub_nonneg.mpr (hT k).1)).mp hz
    funext k
    exact (hT k).2 (by linarith [hall k (Finset.mem_univ k)])
  · rintro rfl; rfl

/-- **Scores become odds.** For any scores `z` on a finite, nonempty set of classes, softmax
gives every class a chance above 0, the chances add to 1, the odds between two classes are the
exponential of their score gap, ŷ_j / ŷ_k = e^{z_j - z_k}, adding the same number `a` to every
score leaves the chances unchanged, and with two classes softmax is the logistic curve at the
score gap: ŷ_1 = 1 / (1 + e^{-(z_1 - z_0)}). -/
theorem softmax_chances_odds_and_shift {ι : Type*} [Fintype ι] [Nonempty ι] (z : ι → ℝ) :
    (∀ k, 0 < softmax z k) ∧ ∑ k, softmax z k = 1 ∧
      (∀ j k, softmax z j / softmax z k = exp (z j - z k)) ∧
      (∀ a : ℝ, softmax (fun k => z k + a) = softmax z) ∧
      (∀ w : Fin 2 → ℝ, softmax w 1 = 1 / (1 + exp (-(w 1 - w 0)))) := by
  have hS : 0 < ∑ j, exp (z j) := Finset.sum_pos (fun j _ => exp_pos _) Finset.univ_nonempty
  refine ⟨fun k => div_pos (exp_pos _) hS, ?_, ?_, ?_, ?_⟩
  · simp only [softmax, ← Finset.sum_div]; exact div_self hS.ne'
  · intro j k
    simp only [softmax]
    rw [exp_sub]; field_simp
  · intro a
    funext k
    simp only [softmax, exp_add, ← Finset.sum_mul]
    rw [mul_div_mul_right _ _ (exp_pos a).ne']
  · intro w
    simp only [softmax, Fin.sum_univ_two]
    rw [exp_neg, exp_sub]
    have h0 := exp_pos (w 0)
    have h1 := exp_pos (w 1)
    field_simp
    ring

/-- **The slope is "predicted minus actual".** For one order that went as class `c`, measure
its loss in nats, -ln ŷ_c. Move score `z_k` alone, holding the other scores still. The slope of
the loss is ŷ_k - y_k, where y_k is 1 if `k = c` and 0 otherwise. -/
theorem softmax_cross_entropy_slope {ι : Type*} [Fintype ι] [DecidableEq ι]
    (z : ι → ℝ) (c k : ι) :
    HasDerivAt (fun t => -log (softmax (Function.update z k t) c))
      (softmax z k - if k = c then 1 else 0) (z k) := by
  set S : ℝ → ℝ := fun t => ∑ j, exp (Function.update z k t j) with hSdef
  have hSpos : ∀ t, 0 < S t := fun t =>
    Finset.sum_pos (fun j _ => exp_pos _) ⟨k, Finset.mem_univ k⟩
  have hfun : (fun t => -log (softmax (Function.update z k t) c))
      = fun t => -(Function.update z k t c) + log (S t) := by
    funext t
    simp only [softmax, hSdef]
    rw [log_div (exp_pos _).ne' (hSpos t).ne', log_exp]
    ring
  have hterm : ∀ j ∈ (Finset.univ : Finset ι),
      HasDerivAt (fun t => exp (Function.update z k t j)) (if j = k then exp (z k) else 0) (z k) := by
    intro j _
    by_cases hj : j = k
    · subst hj
      simp only [Function.update_self, ite_true]
      exact hasDerivAt_exp _
    · simp only [Function.update_of_ne hj, hj, ite_false]
      exact hasDerivAt_const _ _
  have hSd : HasDerivAt S (exp (z k)) (z k) := by
    have := HasDerivAt.fun_sum hterm
    simpa [Finset.sum_ite_eq'] using this
  have hc : HasDerivAt (fun t => Function.update z k t c) (if k = c then 1 else 0) (z k) := by
    by_cases hkc : k = c
    · subst hkc
      simp only [Function.update_self, ite_true]
      exact hasDerivAt_id' _
    · simp only [Function.update_of_ne (Ne.symm hkc), hkc, ite_false]
      exact hasDerivAt_const _ _
  have hlog := hSd.log (hSpos (z k)).ne'
  have hall := hc.neg.add hlog
  rw [hfun]
  convert hall using 1
  have : S (z k) = ∑ j, exp (z j) := by simp [hSdef, Function.update_eq_self]
  rw [this]
  simp only [softmax]
  ring

end SoftmaxCard

open SoftmaxCard Real

-- The 20,000 orders: 7,883 letters, 9,151 parcels and 2,966 pallets.
example : (7883 : ℕ) + 9151 + 2966 = 20000 := by norm_num
-- A chance of 1/2 costs exactly 1 bit.
example : -logb 2 (1 / 2 : ℝ) = 1 := by norm_num [logb_div, logb_self_eq_one]
-- The blind guess: all scores 0 give each of the three classes chance 1/3.
example : softmax (fun _ : Fin 3 => (0 : ℝ)) 1 = 1 / 3 := by norm_num [softmax]
-- A blind guess among three classes costs log2 3 bits whatever happens.
example : -logb 2 (1 / 3 : ℝ) = logb 2 3 := by norm_num [logb_div, logb_self_eq_one]

#print axioms cross_entropy_minimized_exactly_by_true_chances
#print axioms softmax_chances_odds_and_shift
#print axioms softmax_cross_entropy_slope
