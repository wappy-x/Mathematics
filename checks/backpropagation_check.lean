-- Backpropagation: for a network with n inputs, H tanh hidden units and one plain output, scored by half the squared miss, the backward-pass formulas give the exact slope of the loss against every weight and bias, at two multiplications per parameter.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open Finset

namespace Backprop

variable {n H : ℕ}

/-- Hidden unit `j`'s sum: its bias plus its weighted inputs, `z_j = b_j + ∑ᵢ w_ji x_i`. -/
def hiddenSum (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (x : Fin n → ℝ) (j : Fin H) : ℝ :=
  b j + ∑ i, W j i * x i

/-- Hidden unit `j`'s output, `h_j = tanh z_j`. -/
noncomputable def hidden (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (x : Fin n → ℝ) (j : Fin H) : ℝ :=
  Real.tanh (hiddenSum W b x j)

/-- The prediction: the output does not squash, `ŷ = c + ∑ⱼ v_j h_j`. -/
noncomputable def predict (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) : ℝ :=
  c + ∑ j, v j * hidden W b x j

/-- The loss, half the squared miss, `ℓ = ½ (ŷ - y)²`. -/
noncomputable def loss (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) (y : ℝ) : ℝ :=
  (predict W b v c x - y) ^ 2 / 2

/-- The output's backpropagated error, the miss: `δ_out = ŷ - y`. -/
noncomputable def deltaOut (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) (y : ℝ) : ℝ :=
  predict W b v c x - y

/-- Hidden unit `j`'s backpropagated error, read from the kept forward values:
`δ_j = v_j δ_out (1 - h_j²)`. -/
noncomputable def deltaHidden (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) (y : ℝ) (j : Fin H) : ℝ :=
  v j * deltaOut W b v c x y * (1 - hidden W b x j ^ 2)

/-- Weights and biases in an `n`-`H`-1 network: `P = nH + 2H + 1`. -/
def paramCount (n H : ℕ) : ℕ := n * H + 2 * H + 1

/-- Multiplications in one forward pass, as the card counts them: `(n + 1)H + 2`. -/
def forwardCost (n H : ℕ) : ℕ := (n + 1) * H + 2

/-- Multiplications in one backward pass, as the card counts them: `(n + 3)H`. -/
def backwardCost (n H : ℕ) : ℕ := (n + 3) * H

/-- Multiplications for a full central-difference gradient: two forward passes per parameter. -/
def centralCost (n H : ℕ) : ℕ := 2 * paramCount n H * forwardCost n H

end Backprop

open Backprop

/-- The slope of `tanh` is `1 - tanh² `. -/
theorem backprop_tanh_hasDerivAt (z : ℝ) : HasDerivAt Real.tanh (1 - Real.tanh z ^ 2) z := by
  have h := (Real.hasDerivAt_sinh z).div (Real.hasDerivAt_cosh z) (Real.cosh_pos z).ne'
  have hf : Real.tanh = fun s => Real.sinh s / Real.cosh s := by
    funext s; exact Real.tanh_eq_sinh_div_cosh s
  rw [hf]
  convert h using 1
  have hc := (Real.cosh_pos z).ne'
  field_simp

/-- Chain rule for half the squared miss. -/
theorem backprop_halfsq_hasDerivAt {g : ℝ → ℝ} {g' t : ℝ} (y : ℝ) (hg : HasDerivAt g g' t) :
    HasDerivAt (fun s => (g s - y) ^ 2 / 2) ((g t - y) * g') t := by
  have h := ((hg.sub_const y).pow 2).div_const 2
  convert h using 1
  push_cast
  ring

/-- A sum whose `j`-th term alone moves has the slope of that term. -/
theorem backprop_sum_single_hasDerivAt {ι : Type*} [Fintype ι] [DecidableEq ι]
    (φ : ι → ℝ → ℝ) (j : ι) (d t : ℝ)
    (h : ∀ k, HasDerivAt (φ k) (if k = j then d else 0) t) :
    HasDerivAt (fun s => ∑ k, φ k s) d t := by
  have := HasDerivAt.fun_sum (u := Finset.univ) (fun k _ => h k)
  simpa [Finset.sum_ite_eq'] using this


/-- The card's main claim, for the hidden layer. Run the network forward once at the current
weights and keep every `z_j` and `h_j`. Then the slope of the loss against the weight `w_ji`
(all other weights held still) is `δ_j x_i`, the error at the unit it feeds times the value
that entered it, and the slope against the bias `b_j` is `δ_j`, where
`δ_j = v_j (ŷ - y)(1 - h_j²)`. -/
theorem backprop_hidden_weight_and_bias_slopes
    (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) (y : ℝ) (j : Fin H) (i : Fin n) :
    HasDerivAt (fun t => loss (Function.update W j (Function.update (W j) i t)) b v c x y)
        (deltaHidden W b v c x y j * x i) (W j i) ∧
      HasDerivAt (fun t => loss W (Function.update b j t) v c x y)
        (deltaHidden W b v c x y j) (b j) := by
  constructor
  · have hz : HasDerivAt (fun t => hiddenSum (Function.update W j (Function.update (W j) i t)) b x j)
        (x i) (W j i) := by
      unfold hiddenSum
      simp only [Function.update_self]
      apply HasDerivAt.const_add
      apply backprop_sum_single_hasDerivAt _ i
      intro k
      by_cases hk : k = i
      · subst hk; simp only [Function.update_self, ite_true]
        simpa using (hasDerivAt_id (W j k)).mul_const (x k)
      · simp only [Function.update_of_ne hk, hk, ite_false]
        exact hasDerivAt_const _ _
    have hp : HasDerivAt (fun t => predict (Function.update W j (Function.update (W j) i t)) b v c x)
        (v j * ((1 - hidden W b x j ^ 2) * x i)) (W j i) := by
      unfold predict
      apply HasDerivAt.const_add
      apply backprop_sum_single_hasDerivAt _ j
      intro k
      by_cases hk : k = j
      · subst hk; simp only [ite_true]
        apply HasDerivAt.const_mul
        have h2 := (backprop_tanh_hasDerivAt
          (hiddenSum (Function.update W k (Function.update (W k) i (W k i))) b x k)).comp (W k i) hz
        simpa [Backprop.hidden, Function.comp_def, Function.update_eq_self] using h2
      · simp only [hk, ite_false]
        unfold Backprop.hidden hiddenSum
        simp only [Function.update_of_ne hk]
        exact hasDerivAt_const _ _
    have h := backprop_halfsq_hasDerivAt y hp
    simp only [Function.update_eq_self] at h
    unfold loss deltaHidden deltaOut
    convert h using 1
    ring
  · have hp : HasDerivAt (fun t => predict W (Function.update b j t) v c x)
        (v j * (1 - hidden W b x j ^ 2)) (b j) := by
      unfold predict
      apply HasDerivAt.const_add
      apply backprop_sum_single_hasDerivAt _ j
      intro k
      by_cases hk : k = j
      · subst hk; simp only [ite_true]
        apply HasDerivAt.const_mul
        have hz : HasDerivAt (fun t => hiddenSum W (Function.update b k t) x k) 1 (b k) := by
          unfold hiddenSum
          simp only [Function.update_self]
          exact (hasDerivAt_id (b k)).add_const _
        have h2 := (backprop_tanh_hasDerivAt
          (hiddenSum W (Function.update b k (b k)) x k)).comp (b k) hz
        simpa [Backprop.hidden, Function.comp_def, Function.update_eq_self] using h2
      · simp only [hk, ite_false]
        unfold Backprop.hidden hiddenSum
        simp only [Function.update_of_ne hk]
        exact hasDerivAt_const _ _
    have h := backprop_halfsq_hasDerivAt y hp
    simp only [Function.update_eq_self] at h
    unfold loss deltaHidden deltaOut
    convert h using 1
    ring

/-- The output layer. The slope of the loss against the output weight `v_j` is
`δ_out h_j`, and against the output bias `c` it is `δ_out = ŷ - y`. -/
theorem backprop_output_weight_and_bias_slopes
    (W : Fin H → Fin n → ℝ) (b : Fin H → ℝ) (v : Fin H → ℝ) (c : ℝ)
    (x : Fin n → ℝ) (y : ℝ) (j : Fin H) :
    HasDerivAt (fun t => loss W b (Function.update v j t) c x y)
        (deltaOut W b v c x y * hidden W b x j) (v j) ∧
      HasDerivAt (fun t => loss W b v t x y) (deltaOut W b v c x y) c := by
  constructor
  · have hp : HasDerivAt (fun t => predict W b (Function.update v j t) c x)
        (hidden W b x j) (v j) := by
      unfold predict
      apply HasDerivAt.const_add
      apply backprop_sum_single_hasDerivAt _ j
      intro k
      by_cases hk : k = j
      · subst hk; simp only [Function.update_self, ite_true]
        simpa using (hasDerivAt_id (v k)).mul_const (hidden W b x k)
      · simp only [Function.update_of_ne hk, hk, ite_false]
        exact hasDerivAt_const _ _
    have h := backprop_halfsq_hasDerivAt y hp
    simp only [Function.update_eq_self] at h
    unfold loss deltaOut
    exact h
  · have hp : HasDerivAt (fun t => predict W b v t x) 1 c := by
      unfold predict
      exact (hasDerivAt_id c).add_const _
    have h := backprop_halfsq_hasDerivAt y hp
    unfold loss deltaOut
    simpa using h

/-- The cost count. One forward pass, `(n + 1)H + 2` multiplications, plus one backward pass,
`(n + 3)H`, is exactly two multiplications per parameter, `2P` with `P = nH + 2H + 1`. -/
theorem forward_plus_backward_is_two_per_parameter (n H : ℕ) :
    forwardCost n H + backwardCost n H = 2 * paramCount n H := by
  unfold forwardCost backwardCost paramCount
  ring

-- The 2-3-1 network: 13 parameters, 11 + 15 = 26 multiplications, 286 by central differences.
example : paramCount 2 3 = 13 := by decide
example : forwardCost 2 3 = 11 := by decide
example : forwardCost 2 3 + backwardCost 2 3 = 26 := by decide
example : centralCost 2 3 = 286 := by decide
-- The 12-4-1 network.
example : paramCount 12 4 = 57 ∧ forwardCost 12 4 = 54 := by decide
example : forwardCost 12 4 + backwardCost 12 4 = 114 ∧ centralCost 12 4 = 6156 := by decide
-- The shop's 12-16-1 network: 225 parameters, 450 by backprop, 94,500 by nudging, ratio 210.
example : paramCount 12 16 = 225 ∧ forwardCost 12 16 = 210 := by decide
example : forwardCost 12 16 + backwardCost 12 16 = 450 := by decide
example : centralCost 12 16 = 94500 := by norm_num [centralCost, paramCount, forwardCost]
example : centralCost 12 16 / (forwardCost 12 16 + backwardCost 12 16) = 210 := by
  norm_num [centralCost, paramCount, forwardCost, backwardCost]
-- All 20,000 orders.
example : 20000 * (forwardCost 12 16 + backwardCost 12 16) = 9000000 := by
  norm_num [forwardCost, backwardCost]
example : 20000 * centralCost 12 16 = 1890000000 := by
  norm_num [centralCost, paramCount, forwardCost]
-- The 12-64-1 network: ratio 834.
example : paramCount 12 64 = 897 ∧ forwardCost 12 64 = 834 := by decide
example : forwardCost 12 64 + backwardCost 12 64 = 1794 := by decide
example : centralCost 12 64 = 1496196 := by norm_num [centralCost, paramCount, forwardCost]

#print axioms backprop_tanh_hasDerivAt
#print axioms backprop_halfsq_hasDerivAt
#print axioms backprop_sum_single_hasDerivAt
#print axioms backprop_hidden_weight_and_bias_slopes
#print axioms backprop_output_weight_and_bias_slopes
#print axioms forward_plus_backward_is_two_per_parameter
