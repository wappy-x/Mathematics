-- Arranging with repeats: a line of n places filled with a₁ copies of kind 1, a₂ of kind 2, and so on (the counts adding to n) can be filled in exactly n! / (a₁! a₂! ⋯ aₘ!) distinct ways, which is also C(n, a₁) C(n − a₁, a₂) ⋯, one kind's places at a time.
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.BigOperators
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Tactic.NormNum
import Mathlib

open Finset Nat

/-- An arrangement of a line with repeats: each of the `n` places gets a kind from `Fin m`
(only the kind is recorded, so copies of one kind are interchangeable), and kind `i` is used
exactly `a i` times. -/
def arrangements (n m : ℕ) (a : Fin m → ℕ) : Finset (Fin n → Fin m) :=
  univ.filter (fun f => ∀ i, (univ.filter (fun j => f j = i)).card = a i)

lemma fiber_card_comp_perm {n m : ℕ} (f : Fin n → Fin m) (σ : Equiv.Perm (Fin n)) (i : Fin m) :
    (univ.filter (fun j => f (σ j) = i)).card = (univ.filter (fun j => f j = i)).card := by
  rw [← Fintype.card_subtype, ← Fintype.card_subtype]
  exact Fintype.card_congr (σ.subtypeEquiv (fun _ => Iff.rfl))

lemma exists_fun_with_fibers {n m : ℕ} (a : Fin m → ℕ) (h : ∑ i, a i = n) :
    ∃ f : Fin n → Fin m, ∀ i, (univ.filter (fun j => f j = i)).card = a i := by
  classical
  have hc : Fintype.card (Fin n) = Fintype.card (Σ i : Fin m, Fin (a i)) := by simp [h]
  let e := Fintype.equivOfCardEq hc
  refine ⟨fun j => (e j).1, fun i => ?_⟩
  rw [← Fintype.card_subtype]
  rw [Fintype.card_congr (e.subtypeEquiv (p := fun j => (e j).1 = i) (q := fun s => s.1 = i)
    (fun _ => Iff.rfl))]
  rw [Fintype.card_congr (Equiv.sigmaSubtype i)]
  simp

lemma multinomial_univ_eq_prod_choose : ∀ (m : ℕ) (a : Fin m → ℕ),
    Nat.multinomial univ a = ∏ i, (∑ j ∈ Ici i, a j).choose (a i)
  | 0, a => by simp
  | m + 1, a => by
    have hmap : ∀ e : Fin m ↪ Fin (m + 1), (∀ i, e i = i.succ) →
        Nat.multinomial (univ.map e) a = Nat.multinomial univ (fun i : Fin m => a i.succ) := by
      intro e he
      simp [Nat.multinomial, Finset.sum_map, Finset.prod_map, he]
    have hsum : ∀ e : Fin m ↪ Fin (m + 1), (∀ i, e i = i.succ) →
        ∑ i ∈ univ.map e, a i = ∑ i : Fin m, a i.succ := by
      intro e he
      simp [Finset.sum_map, he]
    have hIci : ∀ i : Fin m, ∑ j ∈ Ici i.succ, a j = ∑ j ∈ Ici i, a j.succ := by
      intro i
      rw [← Fin.map_succEmb_Ici, Finset.sum_map]
      simp
    have hrec := multinomial_univ_eq_prod_choose m (fun i : Fin m => a i.succ)
    conv_lhs => rw [Fin.univ_succ, Nat.multinomial_cons, hmap _ (fun _ => rfl), hsum _ (fun _ => rfl), hrec]
    rw [Fin.prod_univ_succ]
    simp only [hIci]
    congr 2
    rw [show (Ici (0 : Fin (m + 1))) = univ from by ext; simp, Fin.sum_univ_succ]

lemma card_mul_prod_factorial_aux (n m : ℕ) (a : Fin m → ℕ) (h : ∑ i, a i = n) :
    (arrangements n m a).card * ∏ i, (a i)! = n ! := by
  classical
  obtain ⟨f0, hf0⟩ := exists_fun_with_fibers a h
  have hstab : Fintype.card {τ : Equiv.Perm (Fin n) // f0 ∘ τ = f0} = ∏ i, (a i)! := by
    rw [DomMulAct.stabilizer_card]
    refine Finset.prod_congr rfl (fun i _ => ?_)
    rw [Fintype.card_subtype, hf0]
  have hcard := Finset.card_eq_sum_card_fiberwise (f := fun σ : Equiv.Perm (Fin n) => f0 ∘ ⇑σ)
    (s := univ) (t := arrangements n m a) (by
      intro σ _
      simp only [arrangements, Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq,
        Function.comp_apply]
      intro i
      rw [fiber_card_comp_perm f0 σ i, hf0])
  rw [Finset.card_univ, Fintype.card_perm, Fintype.card_fin] at hcard
  rw [hcard, ← hstab]
  symm
  apply Finset.sum_const_nat
  intro g hg
  simp only [arrangements, Finset.mem_filter, Finset.mem_univ, true_and] at hg
  have e : ∀ c, {x // g x = c} ≃ {x // f0 x = c} := fun c =>
    Fintype.equivOfCardEq (by rw [Fintype.card_subtype, Fintype.card_subtype, hg, hf0])
  let σ0 : Equiv.Perm (Fin n) := Equiv.ofFiberEquiv e
  have hσ0 : ∀ x, f0 (σ0 x) = g x := Equiv.ofFiberEquiv_map e
  rw [← Fintype.card_subtype]
  refine Fintype.card_congr (Equiv.subtypeEquiv (Equiv.mulRight σ0.symm) (fun σ => ?_))
  constructor
  · intro hs
    funext x
    have h1 := congrFun hs (σ0.symm x)
    have h2 := hσ0 (σ0.symm x)
    simp only [Function.comp_apply, Equiv.apply_symm_apply] at h1 h2
    simp only [Function.comp_apply, Equiv.coe_mulRight, Equiv.Perm.coe_mul]
    rw [h1, ← h2]
  · intro ht
    funext x
    have h1 := congrFun ht (σ0 x)
    simp only [Function.comp_apply, Equiv.coe_mulRight, Equiv.Perm.coe_mul,
      Equiv.symm_apply_apply] at h1
    simp only [Function.comp_apply]
    rw [h1, hσ0]

/-- Arranging with repeats. A line of `n` distinguishable places is filled with items of `m`
kinds, `a₁` interchangeable copies of the first kind, `a₂` of the second, and so on, the copies
together filling the line exactly (`a₁ + ⋯ + aₘ = n`). Then the number of distinct arrangements
is `n!` divided by `a₁! a₂! ⋯ aₘ!`. -/
theorem card_arrangements_eq_factorial_div_prod_factorial (n m : ℕ) (a : Fin m → ℕ)
    (h : ∑ i, a i = n) :
    (arrangements n m a).card = n ! / ∏ i, (a i)! := by
  rw [← card_mul_prod_factorial_aux n m a h,
    Nat.mul_div_cancel _ (Finset.prod_pos (fun i _ => Nat.factorial_pos _))]

/-- The numbering road, with no division. Each distinct arrangement answers to exactly
`a₁! a₂! ⋯ aₘ!` numbered orderings, so the arrangements times that product is `n!`, the count
of orderings of `n` distinct things. -/
theorem card_arrangements_mul_prod_factorial_eq_factorial (n m : ℕ) (a : Fin m → ℕ)
    (h : ∑ i, a i = n) :
    (arrangements n m a).card * ∏ i, (a i)! = n ! := by
  exact card_mul_prod_factorial_aux n m a h

/-- The position road. Choose the `a₁` places for kind 1 out of all `n`, then the `a₂` places
for kind 2 out of the `n − a₁` left, and so on: the number of arrangements is
`C(n, a₁) · C(n − a₁, a₂) ⋯ C(aₘ, aₘ)`. The places still free when kind `i` is placed number
`aᵢ + aᵢ₊₁ + ⋯ + aₘ`. -/
theorem card_arrangements_eq_prod_choose (n m : ℕ) (a : Fin m → ℕ) (h : ∑ i, a i = n) :
    (arrangements n m a).card = ∏ i, (∑ j ∈ Ici i, a j).choose (a i) := by
  have h2 := card_arrangements_mul_prod_factorial_eq_factorial n m a h
  have hm := Nat.multinomial_spec (univ : Finset (Fin m)) a
  rw [h] at hm
  rw [← multinomial_univ_eq_prod_choose]
  apply Nat.eq_of_mul_eq_mul_right (Finset.prod_pos (fun i _ => Nat.factorial_pos (a i)))
  rw [h2, ← hm, Nat.mul_comm]

-- The drum bar: 3 kicks, 2 snares, 1 hat in 6 slots. 6! = 720, each bar counted 3! 2! 1! = 12 times, 60 bars.
example : 6 ! = 720 ∧ 3 ! * 2 ! * 1 ! = 12 ∧ 720 / 12 = 60 := by decide
example : (arrangements 6 3 ![3, 2, 1]).card = 60 := by decide
-- The drum bar one kind at a time: C(6, 3) × C(3, 2) × C(1, 1) = 20 × 3 × 1 = 60.
example : choose 6 3 = 20 ∧ choose 3 2 = 3 ∧ choose 1 1 = 1 ∧ 20 * 3 * 1 = 60 := by decide
-- MISSISSIPPI: M 1, I 4, S 4, P 2, eleven letters. 11! = 39,916,800, 4! 4! 2! = 1,152, 34,650 words.
example : 1 + 4 + 4 + 2 = 11 := by decide
example : 11 ! = 39916800 := by decide
example : 4 ! * 4 ! * 2 ! = 1152 ∧ 39916800 / 1152 = 34650 := by decide
example : 11 ! / (1 ! * 4 ! * 4 ! * 2 !) = 34650 := by decide
-- MISSISSIPPI one kind at a time: C(11, 1) × C(10, 4) × C(6, 4) × C(2, 2) = 11 × 210 × 15 × 1 = 34,650.
example : choose 11 1 = 11 ∧ choose 10 4 = 210 ∧ choose 6 4 = 15 ∧ choose 2 2 = 1 := by decide
example : 11 * 210 * 15 * 1 = 34650 := by decide
-- Street grid: 5 blocks east, 3 north, 8! / (5! 3!) = 56 = C(8, 3).
example : 8 ! / (5 ! * 3 !) = 56 ∧ choose 8 3 = 56 := by decide
-- The mistakes: no division 39,916,800; dropping 2! gives 69,300; dividing by 4! + 4! + 2! = 50 gives 798,336; C(11, 4) = 330.
example : 11 ! / (4 ! * 4 !) = 69300 ∧ 69300 = 2 * 34650 := by decide
example : 4 ! + 4 ! + 2 ! = 50 ∧ 39916800 / 50 = 798336 := by decide
example : choose 11 4 = 330 := by decide
-- Try changing: 3 kicks and 3 snares give 20; a second M in MISSISSIPPI gives 207,900.
example : 6 ! / (3 ! * 3 !) = 20 := by decide
example : 12 ! / (2 ! * 4 ! * 4 ! * 2 !) = 207900 := by decide

#print axioms fiber_card_comp_perm
#print axioms exists_fun_with_fibers
#print axioms multinomial_univ_eq_prod_choose
#print axioms card_mul_prod_factorial_aux
#print axioms card_arrangements_eq_factorial_div_prod_factorial
#print axioms card_arrangements_mul_prod_factorial_eq_factorial
#print axioms card_arrangements_eq_prod_choose
