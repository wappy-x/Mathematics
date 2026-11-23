-- BQP: Deutsch-Jozsa's circuit asks the box once and reads all zeros with chance (average of the signs (-1)^f(x)) squared, so it tells a constant f from a balanced one with certainty, where an exact classical test needs 2^(n-1) + 1 queries.
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Basic.Complex.BigOperators
import Mathlib.Tactic.NormNum

open Matrix Kronecker

namespace QuantumBQP

/-- A function `f` on `n` input bits is constant: the same answer for every input. -/
def IsConstant {n : ℕ} (f : (Fin n → Bool) → Bool) : Prop :=
  ∀ x x', f x = f x'

/-- A function `f` on `n` input bits is balanced: it answers 1 on exactly half of the
`2 ^ n` inputs. -/
def IsBalanced {n : ℕ} (f : (Fin n → Bool) → Bool) : Prop :=
  2 * (Finset.univ.filter (fun x => f x = true)).card = 2 ^ n

instance {n : ℕ} : DecidablePred (IsConstant (n := n)) :=
  fun f => by unfold IsConstant; infer_instance

instance {n : ℕ} : DecidablePred (IsBalanced (n := n)) :=
  fun f => by unfold IsBalanced; infer_instance

/-- The Hadamard gate `H` on one qubit, rows and columns indexed by the bit values 0 and 1:
entries `1/√2`, except `-1/√2` in the 1, 1 corner. -/
noncomputable def hadamard : Matrix Bool Bool ℂ :=
  Matrix.of fun a b => ((Real.sqrt 2 : ℂ)⁻¹) * (if a && b then -1 else 1)

/-- The NOT gate `X` on one qubit: it swaps 0 and 1. -/
def pauliX : Matrix Bool Bool ℂ :=
  Matrix.of fun a b => if a = !b then 1 else 0

/-- `H` on every one of `n` input qubits: the `n`-fold Kronecker (tensor) power of `H`, whose
entry in row `z`, column `x` is the product over the qubits `i` of `H (z i) (x i)`. -/
noncomputable def hadamardAll (n : ℕ) : Matrix (Fin n → Bool) (Fin n → Bool) ℂ :=
  Matrix.of fun z x => ∏ i, hadamard (z i) (x i)

/-- The oracle `U_f`, the box as a reversible gate on `n` input qubits and one answer qubit:
`(x, y) ↦ (x, y xor f x)`. Column `(x, y)` has its single 1 in row `(x, y xor f x)`. -/
def oracle {n : ℕ} (f : (Fin n → Bool) → Bool) :
    Matrix ((Fin n → Bool) × Bool) ((Fin n → Bool) × Bool) ℂ :=
  Matrix.of fun p q => if p = (q.1, xor q.2 (f q.1)) then 1 else 0

/-- The Deutsch-Jozsa circuit as one matrix, gates applied right to left: `X` on the answer
qubit, `H` on every qubit, the one query `U_f`, then `H` on every input qubit. -/
noncomputable def circuit {n : ℕ} (f : (Fin n → Bool) → Bool) :
    Matrix ((Fin n → Bool) × Bool) ((Fin n → Bool) × Bool) ℂ :=
  (hadamardAll n ⊗ₖ (1 : Matrix Bool Bool ℂ)) * oracle f * (hadamardAll n ⊗ₖ hadamard) *
    ((1 : Matrix (Fin n → Bool) (Fin n → Bool) ℂ) ⊗ₖ pauliX)

/-- The state the circuit leaves when every qubit starts at 0. -/
noncomputable def finalState {n : ℕ} (f : (Fin n → Bool) → Bool) :
    (Fin n → Bool) × Bool → ℂ :=
  circuit f *ᵥ Pi.single ((fun _ => false), false) 1

/-- The chance that the `n` input qubits all read 0: the squared sizes of the two amplitudes
with every input bit 0, one for each value of the answer qubit. -/
noncomputable def probAllZero {n : ℕ} (f : (Fin n → Bool) → Bool) : ℝ :=
  ∑ y : Bool, Complex.normSq (finalState f ((fun _ => false), y))

lemma step1 (n : ℕ) :
    ((1 : Matrix (Fin n → Bool) (Fin n → Bool) ℂ) ⊗ₖ pauliX) *ᵥ
      Pi.single ((fun _ => false), false) 1 = Pi.single ((fun _ => false), true) 1 := by
  ext ⟨x, y⟩
  simp [Matrix.mulVec, dotProduct, Pi.single_apply, kroneckerMap_apply, pauliX, Matrix.one_apply]
  split_ifs <;> simp_all

#print axioms step1

lemma step2 (n : ℕ) :
    (hadamardAll n ⊗ₖ hadamard) *ᵥ Pi.single ((fun _ => false), true) 1 =
      fun p => ((Real.sqrt 2 : ℂ)⁻¹) ^ (n + 1) * (if p.2 then -1 else 1) := by
  ext ⟨x, y⟩
  simp [Matrix.mulVec, dotProduct, Pi.single_apply, kroneckerMap_apply, hadamardAll, hadamard]
  cases y <;> simp [pow_succ, mul_comm]

#print axioms step2

lemma step3 {n : ℕ} (f : (Fin n → Bool) → Bool) (v : (Fin n → Bool) × Bool → ℂ) :
    oracle f *ᵥ v = fun p => v (p.1, xor p.2 (f p.1)) := by
  ext ⟨x, y⟩
  simp only [Matrix.mulVec, dotProduct, oracle, Matrix.of_apply]
  have h : ∀ i : (Fin n → Bool) × Bool,
      ((x, y) = (i.1, xor i.2 (f i.1))) ↔ (x, xor y (f x)) = i := by
    rintro ⟨a, b⟩
    constructor
    · rintro h
      simp only [Prod.mk.injEq] at h ⊢
      obtain ⟨rfl, rfl⟩ := h
      simp
    · rintro h
      simp only [Prod.mk.injEq] at h ⊢
      obtain ⟨rfl, rfl⟩ := h
      simp
  simp_rw [h, ite_mul, one_mul, zero_mul]
  simp

#print axioms step3

lemma finalState_zero {n : ℕ} (f : (Fin n → Bool) → Bool) (y : Bool) :
    finalState f ((fun _ => false), y) =
      (((Real.sqrt 2)⁻¹ ^ (2 * n + 1) * (if y then -1 else 1) *
        ∑ x, (-1 : ℝ) ^ (f x).toNat : ℝ) : ℂ) := by
  unfold finalState circuit
  rw [← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec, step1, step2,
    step3]
  simp [Matrix.mulVec, dotProduct, kroneckerMap_apply, hadamardAll, hadamard,
    Fintype.sum_prod_type, Matrix.one_apply]
  cases y
  · push_cast
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun x _ => ?_
    cases f x <;> simp <;> ring
  · simp only [ite_true]
    push_cast
    rw [Finset.mul_sum, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun x _ => ?_
    cases f x <;> simp <;> ring

#print axioms finalState_zero

lemma card_inputs (n : ℕ) : Fintype.card (Fin n → Bool) = 2 ^ n := by
  simp

#print axioms card_inputs

/-- Helper: the card's formula. -/
lemma prob_formula {n : ℕ} (f : (Fin n → Bool) → Bool) :
    probAllZero f = ((∑ x, (-1 : ℝ) ^ (f x).toNat) / 2 ^ n) ^ 2 := by
  simp only [probAllZero, finalState_zero, Complex.normSq_ofReal, Fintype.sum_bool, ite_true]
  simp only [Bool.false_eq_true, ite_false]
  set S := ∑ x, (-1 : ℝ) ^ (f x).toNat
  have h : ((Real.sqrt 2)⁻¹ ^ (2 * n + 1)) ^ 2 = (1 / 2) ^ (2 * n + 1) := by
    rw [← pow_mul, mul_comm, pow_mul, inv_pow, Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
    norm_num
  have e : ((Real.sqrt 2)⁻¹ ^ (2 * n + 1) * -1 * S) * ((Real.sqrt 2)⁻¹ ^ (2 * n + 1) * -1 * S) +
      ((Real.sqrt 2)⁻¹ ^ (2 * n + 1) * 1 * S) * ((Real.sqrt 2)⁻¹ ^ (2 * n + 1) * 1 * S) =
      2 * ((Real.sqrt 2)⁻¹ ^ (2 * n + 1)) ^ 2 * S ^ 2 := by ring
  rw [e, h]
  field_simp
  ring_nf
  rw [mul_assoc, ← mul_pow]
  norm_num

#print axioms prob_formula

lemma sign_sum_balanced {n : ℕ} (f : (Fin n → Bool) → Bool) (hb : IsBalanced f) :
    ∑ x, (-1 : ℝ) ^ (f x).toNat = 0 := by
  have h1 : ∀ x, (-1 : ℝ) ^ (f x).toNat = 1 - 2 * (if f x = true then 1 else 0) := by
    intro x; cases f x <;> norm_num
  simp_rw [h1]
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_boole]
  have hb' : (2 : ℝ) * ((Finset.univ.filter (fun x => f x = true)).card : ℝ) = 2 ^ n := by
    exact_mod_cast hb
  simp only [Finset.sum_const, Finset.card_univ, card_inputs, nsmul_eq_mul, mul_one]
  rw [hb']
  push_cast
  ring

#print axioms sign_sum_balanced

lemma sign_sum_constant {n : ℕ} (f : (Fin n → Bool) → Bool) (hc : IsConstant f) :
    ((∑ x, (-1 : ℝ) ^ (f x).toNat) / 2 ^ n) ^ 2 = 1 := by
  have h : ∀ x, (-1 : ℝ) ^ (f x).toNat = (-1 : ℝ) ^ (f (fun _ => false)).toNat :=
    fun x => by rw [hc x (fun _ => false)]
  simp_rw [h]
  simp only [Finset.sum_const, Finset.card_univ, card_inputs, nsmul_eq_mul]
  push_cast
  rw [mul_div_cancel_left₀ _ (by positivity)]
  rw [← pow_mul, mul_comm, pow_mul]
  norm_num

#print axioms sign_sum_constant

/-- Deutsch-Jozsa, one query decides: if the box `f` on `n` input bits is promised to be
constant or balanced, then the circuit's input qubits read all zeros with chance exactly 0 or
1: chance 1 when `f` is constant and chance 0 when `f` is balanced. With `n = 1` this is
Deutsch's test. -/
theorem deutsch_jozsa_one_query_decides {n : ℕ} (f : (Fin n → Bool) → Bool)
    (hpromise : IsConstant f ∨ IsBalanced f) :
    (probAllZero f = 0 ∨ probAllZero f = 1) ∧
      (IsConstant f → probAllZero f = 1) ∧ (IsBalanced f → probAllZero f = 0) := by
  have hC : IsConstant f → probAllZero f = 1 := fun hc => by
    rw [prob_formula]; exact sign_sum_constant f hc
  have hB : IsBalanced f → probAllZero f = 0 := fun hb => by
    rw [prob_formula, sign_sum_balanced f hb]; simp
  refine ⟨?_, hC, hB⟩
  rcases hpromise with hc | hb
  · exact Or.inr (hC hc)
  · exact Or.inl (hB hb)

/-- The card's formula: the chance that the input qubits all read 0 is the average of the
signs `(-1)^f(x)` over all `2 ^ n` inputs, squared. -/
theorem prob_all_zero_eq_sign_average_sq {n : ℕ} (f : (Fin n → Bool) → Bool) :
    probAllZero f = ((∑ x, (-1 : ℝ) ^ (f x).toNat) / 2 ^ n) ^ 2 := by
  exact prob_formula f

/-- The classical count: with `n ≥ 1` input bits, a set `S` of query points fits both a
constant and a balanced function (so the answers seen there cannot tell them apart) exactly
when `S` has at most `2 ^ (n - 1)` points. So an exact classical test needs `2 ^ (n - 1) + 1`
queries in the worst case: an adversary answering 0 every time keeps both possible until then. -/
theorem classical_fooled_iff_at_most_half {n : ℕ} (hn : 1 ≤ n) (S : Finset (Fin n → Bool)) :
    (∃ c g : (Fin n → Bool) → Bool, IsConstant c ∧ IsBalanced g ∧ ∀ x ∈ S, c x = g x) ↔
      S.card ≤ 2 ^ (n - 1) := by
  have hpow : 2 ^ n = 2 * 2 ^ (n - 1) := by
    rw [← pow_succ']; congr 1; omega
  constructor
  · rintro ⟨c, g, hc, hg, hS⟩
    set v := c (fun _ => false)
    have hsub : S ⊆ Finset.univ.filter (fun x => g x = v) := by
      intro x hx
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      rw [← hS x hx]; exact hc x _
    have hsplit := Finset.card_filter_add_card_filter_not
      (s := (Finset.univ : Finset (Fin n → Bool))) (fun x => g x = true)
    rw [Finset.card_univ, card_inputs] at hsplit
    unfold IsBalanced at hg
    have hcard : (Finset.univ.filter (fun x => g x = v)).card = 2 ^ (n - 1) := by
      cases hv : v
      · have : (Finset.univ.filter (fun x => g x = false)) =
            Finset.univ.filter (fun x => ¬ (g x = true)) := by
          ext x; simp
        rw [this]; omega
      · omega
    exact hcard ▸ Finset.card_le_card hsub
  · intro hS
    have hc : 2 ^ (n - 1) ≤ Sᶜ.card := by
      rw [Finset.card_compl, card_inputs]; omega
    obtain ⟨T, hT, hTc⟩ := Finset.exists_subset_card_eq hc
    refine ⟨fun _ => false, fun x => decide (x ∈ T), fun _ _ => rfl, ?_, ?_⟩
    · unfold IsBalanced
      have : Finset.univ.filter (fun x => decide (x ∈ T) = true) = T := by
        ext x; simp
      rw [this, hTc, hpow]
    · intro x hx
      have : x ∉ T := fun h => Finset.mem_compl.1 (hT h) hx
      simp [this]

/-- Every classical one-query strategy for Deutsch's problem (ask at input `b`, then answer
"balanced" or "constant" by a rule `ans` on the bit seen) is right on at most 2 of the 4
one-bit functions. -/
example : ∀ b : Bool, ∀ ans : Bool → Bool,
    (Finset.univ.filter (fun f : Bool → Bool => ans (f b) = (f false != f true))).card ≤ 2 := by
  decide

/-- Two input bits: of the 16 functions, 2 are constant and 6 are balanced. -/
example : (Finset.univ.filter (fun f : (Fin 2 → Bool) → Bool => IsConstant f)).card = 2 ∧
    (Finset.univ.filter (fun f : (Fin 2 → Bool) → Bool => IsBalanced f)).card = 6 := by
  decide

/-- Exact classical queries `2 ^ (n - 1) + 1` for n = 2, 10, 20, 40, against 1 quantum query. -/
example : 2 ^ (2 - 1) + 1 = 3 ∧ 2 ^ (10 - 1) + 1 = 513 ∧ 2 ^ (20 - 1) + 1 = 524289 ∧
    2 ^ (40 - 1) + 1 = 549755813889 := by norm_num

/-- Ten random queries with repeats call a balanced function constant with chance
`2 * (1/2)^10 = 1/512`, the card's 0.1953%. -/
example : (2 : ℚ) * (1 / 2) ^ 10 = 1 / 512 := by norm_num

/-- The memory a classical simulator needs at 16 bytes per amplitude: 30 qubits and 50 qubits. -/
example : 16 * 2 ^ 30 = 17179869184 ∧ 16 * 2 ^ 50 = 18014398509481984 := by norm_num

#print axioms deutsch_jozsa_one_query_decides
#print axioms prob_all_zero_eq_sign_average_sq
#print axioms classical_fooled_iff_at_most_half

end QuantumBQP
