-- Pseudorandomness: a majority vote over every seed of a generator that fools the program's error test is right, the parity generator gives every pair of coins each pattern on exactly a quarter of the seeds, an expander walk fails all its tries with chance at most μ(μ + λ)^(k-1), and the card's 12-staff rota numbers come out as printed.
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

namespace DerandomisationAndPseudorandomness

open Finset

/-! ## The vote over all seeds -/

/-- The majority vote over every seed: answer `true` when more than half of all seeds make the
program `A` answer `true` on the fake coins `G z`. -/
def majorityVote {S R : Type*} [Fintype S] (G : S → R) (A : R → Bool) : Bool :=
  decide (Fintype.card S < 2 * (univ.filter fun z : S => A (G z) = true).card)

/-- **A vote over all seeds removes the coins.** A program `A` reads coins `r` (all of a finite
set `R`, drawn evenly) and should answer `right` on its fixed input; it is wrong on real coins with
chance at most `δ`. A generator `G` from seeds `S` fools the program's own test "is the answer
wrong with these coins?" to within `ε`: the chance of a wrong answer on `G z`, for an even random
seed `z`, is within `ε` of the chance on real coins. If `δ + ε` is below one half, then more
than half of all seeds give the right answer, and the majority vote over every seed is right,
with no coins at all. -/
theorem majority_vote_over_seeds_is_right {S R : Type*} [Fintype S] [Fintype R] [Nonempty S]
    [Nonempty R] (G : S → R) (A : R → Bool) (right : Bool) (δ ε : ℝ)
    (herr : ((univ.filter fun r : R => A r ≠ right).card : ℝ) / Fintype.card R ≤ δ)
    (hfool : |((univ.filter fun z : S => A (G z) ≠ right).card : ℝ) / Fintype.card S
        - ((univ.filter fun r : R => A r ≠ right).card : ℝ) / Fintype.card R| ≤ ε)
    (hhalf : δ + ε < 1 / 2) :
    Fintype.card S < 2 * (univ.filter fun z : S => A (G z) = right).card ∧
      majorityVote G A = right := by
  classical
  have hS : (0:ℝ) < Fintype.card S := by exact_mod_cast Fintype.card_pos
  have hsum : (univ.filter fun z : S => A (G z) = right).card
      + (univ.filter fun z : S => A (G z) ≠ right).card = Fintype.card S := by
    rw [← Finset.card_univ]; exact Finset.card_filter_add_card_filter_not _
  have h1 : ((univ.filter fun z : S => A (G z) ≠ right).card : ℝ) / Fintype.card S < 1 / 2 := by
    have := (abs_le.mp hfool).2
    linarith
  have h2 : 2 * (univ.filter fun z : S => A (G z) ≠ right).card < Fintype.card S := by
    rw [div_lt_iff₀ hS] at h1
    exact_mod_cast (by linarith : (2 * ((univ.filter fun z : S => A (G z) ≠ right).card : ℝ))
      < Fintype.card S)
  refine ⟨by omega, ?_⟩
  unfold majorityVote
  cases right
  · have : (univ.filter fun z : S => A (G z) = true)
        = (univ.filter fun z : S => A (G z) ≠ false) := by
      ext z; simp
    rw [this, decide_eq_false_iff_not, not_lt]; omega
  · rw [decide_eq_true_eq]; omega

/-! ## The parity generator: every pair of coins looks real -/

/-- For two different coin numbers with `j ≠ 0`, some seed gives coin `i` the value 0 and
coin `j` the value 1. -/
lemma exists_dot_zero_one {s : ℕ} (i j : Fin s → ZMod 2) (hj : j ≠ 0) (hij : i ≠ j) :
    ∃ u : Fin s → ZMod 2, u ⬝ᵥ i = 0 ∧ u ⬝ᵥ j = 1 := by
  have h2 : ∀ x : ZMod 2, x = 0 ∨ x = 1 := by decide
  obtain ⟨q, hq⟩ : ∃ q, j q ≠ 0 := by
    by_contra h; push Not at h; exact hj (funext h)
  have hq1 : j q = 1 := (h2 _).resolve_left hq
  rcases h2 (i q) with hiq | hiq
  · exact ⟨Pi.single q 1, by simp [single_dotProduct, hiq], by simp [single_dotProduct, hq1]⟩
  · obtain ⟨k, hk⟩ : ∃ k, i k ≠ j k := by
      by_contra h; push Not at h; exact hij (funext h)
    rcases h2 (i k) with hik | hik <;> rcases h2 (j k) with hjk | hjk
    · exact absurd (hik.trans hjk.symm) hk
    · exact ⟨Pi.single k 1, by simp [single_dotProduct, hik], by simp [single_dotProduct, hjk]⟩
    · refine ⟨Pi.single q 1 + Pi.single k 1, ?_, ?_⟩
      · rw [add_dotProduct, single_dotProduct, single_dotProduct, hiq, hik]; decide
      · rw [add_dotProduct, single_dotProduct, single_dotProduct, hq1, hjk]; decide
    · exact absurd (hik.trans hjk.symm) hk

#print axioms exists_dot_zero_one

/-- **The parity generator is pairwise independent.** A seed `z` is `s` bits; coin number `i` is
written in binary as `s` bits (bit `k` of `i` is entry `k`), and the coin is the parity of
`z AND i`, which is the dot product `z ⬝ᵥ i` taken mod 2. For any two different nonzero coin
numbers `i ≠ j`, each of the four outcomes `(a, b)` = 00, 01, 10, 11 of the two coins comes from
exactly `2^(s-2)` of the `2^s` seeds. -/
theorem parity_generator_pairwise_independent (s : ℕ) (i j : Fin s → ZMod 2) (hi : i ≠ 0)
    (hj : j ≠ 0) (hij : i ≠ j) (a b : ZMod 2) :
    (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = a ∧ z ⬝ᵥ j = b).card = 2 ^ (s - 2) := by
  classical
  obtain ⟨u2, hu2i, hu2j⟩ := exists_dot_zero_one i j hj hij
  obtain ⟨u1, hu1j, hu1i⟩ := exists_dot_zero_one j i hi (Ne.symm hij)
  have hfib : ∀ a b : ZMod 2,
      (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = a ∧ z ⬝ᵥ j = b).card
        = (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = 0 ∧ z ⬝ᵥ j = 0).card := by
    intro a b
    have hui : (a • u1 + b • u2) ⬝ᵥ i = a := by
      simp [add_dotProduct, smul_dotProduct, hu1i, hu2i]
    have huj : (a • u1 + b • u2) ⬝ᵥ j = b := by
      simp [add_dotProduct, smul_dotProduct, hu1j, hu2j]
    symm
    apply Finset.card_bij (fun z _ => z + (a • u1 + b • u2))
    · intro z hz
      simp only [mem_filter, mem_univ, true_and] at hz ⊢
      rw [add_dotProduct z _ i, add_dotProduct z _ j, hz.1, hz.2, hui, huj]; simp
    · intro z1 _ z2 _ h; exact add_right_cancel h
    · intro z hz
      refine ⟨z - (a • u1 + b • u2), ?_, by simp⟩
      simp only [mem_filter, mem_univ, true_and] at hz ⊢
      rw [sub_dotProduct z _ i, sub_dotProduct z _ j, hz.1, hz.2, hui, huj]; simp
  have htot : Fintype.card (Fin s → ZMod 2)
      = 4 * (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = 0 ∧ z ⬝ᵥ j = 0).card := by
    rw [← Finset.card_univ, Finset.card_eq_sum_card_fiberwise
      (f := fun z => (z ⬝ᵥ i, z ⬝ᵥ j)) (t := univ) (fun _ _ => mem_univ _)]
    have hc : ∀ ab ∈ (univ : Finset (ZMod 2 × ZMod 2)),
        (univ.filter fun z : Fin s → ZMod 2 => (z ⬝ᵥ i, z ⬝ᵥ j) = ab).card
          = (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = 0 ∧ z ⬝ᵥ j = 0).card := by
      intro ab _
      rw [← hfib ab.1 ab.2]
      congr 1
    rw [Finset.sum_congr rfl hc, sum_const, card_univ]
    simp [Fintype.card_prod, ZMod.card]
  have hcard : Fintype.card (Fin s → ZMod 2) = 2 ^ s := by simp
  rw [hfib a b]
  rw [hcard] at htot
  generalize (univ.filter fun z : Fin s → ZMod 2 => z ⬝ᵥ i = 0 ∧ z ⬝ᵥ j = 0).card = c at htot ⊢
  rcases s with _ | _ | s
  · rw [pow_zero] at htot; omega
  · rw [pow_one] at htot; omega
  · rw [show s + 2 - 2 = s by omega]
    rw [pow_add] at htot
    omega

/-! ## The expander walk: repeated tries on few bits -/

/-- One step of the walk's table `W` on a list `v` with one number per coin string: the new
entry at `y` is the average of `v` over the `d` neighbours `y + g c`, each step pattern `g c`
flipping the coins where it has a 1. -/
noncomputable def walkStep {n d : ℕ} (g : Fin d → (Fin n → ZMod 2))
    (v : (Fin n → ZMod 2) → ℝ) : (Fin n → ZMod 2) → ℝ :=
  fun y => (∑ c, v (y + g c)) / d

/-- Where the walk stands at try number `t + 1`: the first coin string `y` with the step patterns
of the first `t` steps flipped in. -/
def walkPosition {n d m : ℕ} (g : Fin d → (Fin n → ZMod 2)) (y : Fin n → ZMod 2)
    (steps : Fin m → Fin d) (t : ℕ) : Fin n → ZMod 2 :=
  y + ∑ l ∈ univ.filter (fun l : Fin m => (l : ℕ) < t), g (steps l)

/-- The share of `r`-step walks from `y` whose `r + 1` spots all lie in `B`. -/
noncomputable def stayTable {n d : ℕ} (g : Fin d → (Fin n → ZMod 2))
    (B : Finset (Fin n → ZMod 2)) : ℕ → (Fin n → ZMod 2) → ℝ
  | 0 => fun y => if y ∈ B then 1 else 0
  | r + 1 => fun y => if y ∈ B then walkStep g (stayTable g B r) y else 0

lemma walkPosition_zero {n d m : ℕ} (g : Fin d → (Fin n → ZMod 2)) (y : Fin n → ZMod 2)
    (steps : Fin m → Fin d) : walkPosition g y steps 0 = y := by
  simp [walkPosition]

#print axioms walkPosition_zero

lemma walkPosition_cons {n d m : ℕ} (g : Fin d → (Fin n → ZMod 2)) (y : Fin n → ZMod 2)
    (c : Fin d) (rest : Fin m → Fin d) (t : ℕ) :
    walkPosition g y (Fin.cons c rest : Fin (m + 1) → Fin d) (t + 1)
      = walkPosition g (y + g c) rest t := by
  simp only [walkPosition, Finset.sum_filter, Fin.sum_univ_succ, Fin.cons_zero, Fin.cons_succ,
    Fin.val_zero, Fin.val_succ]
  simp [add_assoc]

#print axioms walkPosition_cons

lemma stayTable_count {n d : ℕ} (hd : 0 < d) (g : Fin d → (Fin n → ZMod 2))
    (B : Finset (Fin n → ZMod 2)) : ∀ (r : ℕ) (y : Fin n → ZMod 2),
    ((univ.filter fun steps : Fin r → Fin d =>
        ∀ t : Fin (r + 1), walkPosition g y steps t ∈ B).card : ℝ)
      = (d : ℝ) ^ r * stayTable g B r y
  | 0, y => by
    rw [natCast_card_filter]
    simp [walkPosition_zero, stayTable]
  | r + 1, y => by
    have key : ∀ (c : Fin d) (rest : Fin r → Fin d),
        (∀ t : Fin (r + 2), walkPosition g y (Fin.cons c rest : Fin (r + 1) → Fin d) t ∈ B)
          ↔ y ∈ B ∧ ∀ t : Fin (r + 1), walkPosition g (y + g c) rest t ∈ B := by
      intro c rest
      rw [Fin.forall_fin_succ]
      simp only [Fin.val_zero, walkPosition_zero, Fin.val_succ, walkPosition_cons]
    rw [natCast_card_filter, ← (Fin.consEquiv (fun _ : Fin (r + 1) => Fin d)).sum_comp,
      Fintype.sum_prod_type]
    simp only [Fin.consEquiv_apply, key]
    by_cases hy : y ∈ B
    · simp only [hy, true_and]
      have : ∀ c : Fin d, (∑ rest : Fin r → Fin d,
          if ∀ t : Fin (r + 1), walkPosition g (y + g c) rest t ∈ B then (1 : ℝ) else 0)
            = (d : ℝ) ^ r * stayTable g B r (y + g c) := by
        intro c
        rw [← stayTable_count hd g B r (y + g c), natCast_card_filter]
      rw [Finset.sum_congr rfl (fun c _ => this c)]
      have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
      simp only [stayTable, hy, ite_true, walkStep]
      rw [← Finset.mul_sum]
      field_simp
      ring
    · simp [hy, stayTable]

#print axioms stayTable_count

lemma stayTable_supp {n d : ℕ} (g : Fin d → (Fin n → ZMod 2)) (B : Finset (Fin n → ZMod 2)) :
    ∀ (r : ℕ) (y : Fin n → ZMod 2), y ∉ B → stayTable g B r y = 0
  | 0, y, h => by simp [stayTable, h]
  | r + 1, y, h => by simp [stayTable, h]

#print axioms stayTable_supp

lemma energy_step {n d : ℕ} (hd : 0 < d) (g : Fin d → (Fin n → ZMod 2))
    (B : Finset (Fin n → ZMod 2)) (lam : ℝ) (hlam0 : 0 ≤ lam)
    (hlam : ∀ v : (Fin n → ZMod 2) → ℝ, ∑ y, v y = 0 →
      ∑ y, walkStep g v y ^ 2 ≤ lam ^ 2 * ∑ y, v y ^ 2)
    (f : (Fin n → ZMod 2) → ℝ) (hf : ∀ y, y ∉ B → f y = 0) :
    ∑ y, (if y ∈ B then walkStep g f y else 0) ^ 2
      ≤ ((B.card : ℝ) / 2 ^ n + lam) ^ 2 * ∑ y, f y ^ 2 := by
  classical
  have hN : ((Fintype.card (Fin n → ZMod 2) : ℕ) : ℝ) = 2 ^ n := by simp
  have hNpos : (0 : ℝ) < 2 ^ n := by positivity
  have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
  obtain ⟨Q, hQ⟩ : ∃ Q, Q = ∑ y, f y ^ 2 := ⟨_, rfl⟩
  obtain ⟨α, hα⟩ : ∃ α : ℝ, α = (∑ y, f y) / 2 ^ n := ⟨_, rfl⟩
  obtain ⟨μ, hμ⟩ : ∃ μ : ℝ, μ = (B.card : ℝ) / 2 ^ n := ⟨_, rfl⟩
  obtain ⟨w, hw⟩ : ∃ w : (Fin n → ZMod 2) → ℝ, w = fun y => f y - α := ⟨_, rfl⟩
  rw [← hμ, ← hQ]
  have hsumf : ∑ y, f y = 2 ^ n * α := by rw [hα]; field_simp
  have hw0 : ∑ y, w y = 0 := by
    simp only [hw, Finset.sum_sub_distrib, sum_const, card_univ, nsmul_eq_mul, hN, hsumf]; ring
  have hQw : ∑ y, w y ^ 2 = Q - 2 ^ n * α ^ 2 := by
    have : ∀ y, w y ^ 2 = f y ^ 2 - 2 * α * f y + α ^ 2 := by intro y; simp only [hw]; ring
    simp only [this, Finset.sum_add_distrib, Finset.sum_sub_distrib, sum_const, card_univ,
      nsmul_eq_mul, hN, ← Finset.mul_sum, hsumf, hQ]
    ring
  have hWf : ∀ y, walkStep g f y = α + walkStep g w y := by
    intro y
    simp only [walkStep, hw, Finset.sum_sub_distrib, sum_const, card_univ, Fintype.card_fin,
      nsmul_eq_mul]
    field_simp
    ring
  -- the two parts
  obtain ⟨a, ha⟩ : ∃ a : (Fin n → ZMod 2) → ℝ, a = fun y => if y ∈ B then α else 0 := ⟨_, rfl⟩
  obtain ⟨b, hb⟩ : ∃ b : (Fin n → ZMod 2) → ℝ,
      b = fun y => if y ∈ B then walkStep g w y else 0 := ⟨_, rfl⟩
  have hsplit : ∀ y, (if y ∈ B then walkStep g f y else 0) = a y + b y := by
    intro y; simp only [ha, hb]; split_ifs <;> simp [hWf]
  have hind : ∀ y, (if y ∈ B then (1 : ℝ) else 0) ^ 2 = if y ∈ B then 1 else 0 := by
    intro y; split_ifs <;> simp
  have hBcard : ∑ y, (if y ∈ B then (1 : ℝ) else 0) = B.card := by
    rw [Finset.sum_boole, Finset.filter_mem_eq_inter, Finset.univ_inter]
  -- Cauchy-Schwarz on B
  have hCS : (∑ y, f y) ^ 2 ≤ B.card * Q := by
    have hfe : ∑ y, f y = ∑ y, (if y ∈ B then (1 : ℝ) else 0) * f y := by
      congr 1; ext y; by_cases hy : y ∈ B
      · simp [hy]
      · simp [hy, hf y hy]
    rw [hfe]
    calc (∑ y, (if y ∈ B then (1 : ℝ) else 0) * f y) ^ 2
        ≤ (∑ y, (if y ∈ B then (1 : ℝ) else 0) ^ 2) * ∑ y, f y ^ 2 :=
          Finset.sum_mul_sq_le_sq_mul_sq _ _ _
      _ = B.card * Q := by simp only [hind, hBcard, hQ]
  have hQ0 : 0 ≤ Q := by rw [hQ]; exact Finset.sum_nonneg (fun y _ => sq_nonneg _)
  have hB0 : (0 : ℝ) ≤ B.card := Nat.cast_nonneg _
  have hμ0 : 0 ≤ μ := by rw [hμ]; exact div_nonneg hB0 hNpos.le
  have hA : ∑ y, a y ^ 2 = B.card * α ^ 2 := by
    have : ∀ y, a y ^ 2 = (if y ∈ B then (1 : ℝ) else 0) * α ^ 2 := by
      intro y; simp only [ha]; split_ifs <;> simp
    simp only [this, ← Finset.sum_mul, hBcard]
  have hAle : ∑ y, a y ^ 2 ≤ μ ^ 2 * Q := by
    rw [hA, hα, hμ, div_pow, div_pow]
    have hN2 : (0 : ℝ) < (2 ^ n) ^ 2 := pow_pos hNpos 2
    rw [mul_div_assoc', div_le_iff₀ hN2, div_mul_eq_mul_div, div_mul_cancel₀ _ hN2.ne']
    calc (B.card : ℝ) * (∑ y, f y) ^ 2 ≤ B.card * (B.card * Q) :=
          mul_le_mul_of_nonneg_left hCS hB0
      _ = (B.card : ℝ) ^ 2 * Q := by ring
  have hBle : ∑ y, b y ^ 2 ≤ lam ^ 2 * Q := by
    calc ∑ y, b y ^ 2 ≤ ∑ y, walkStep g w y ^ 2 := by
          apply Finset.sum_le_sum; intro y _; simp only [hb]; split_ifs
          · exact le_rfl
          · simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow]
            exact sq_nonneg _
      _ ≤ lam ^ 2 * ∑ y, w y ^ 2 := hlam w hw0
      _ ≤ lam ^ 2 * Q := by
          apply mul_le_mul_of_nonneg_left _ (sq_nonneg _)
          rw [hQw]; nlinarith [sq_nonneg α]
  have hcross : ∑ y, a y * b y ≤ μ * lam * Q := by
    have h1 : (∑ y, a y * b y) ^ 2 ≤ (∑ y, a y ^ 2) * ∑ y, b y ^ 2 :=
      Finset.sum_mul_sq_le_sq_mul_sq _ _ _
    have h2 : (∑ y, a y ^ 2) * ∑ y, b y ^ 2 ≤ (μ ^ 2 * Q) * (lam ^ 2 * Q) :=
      mul_le_mul hAle hBle (Finset.sum_nonneg (fun y _ => sq_nonneg _)) (by positivity)
    have h3 : 0 ≤ μ * lam * Q := by positivity
    nlinarith
  calc ∑ y, (if y ∈ B then walkStep g f y else 0) ^ 2
      = ∑ y, a y ^ 2 + 2 * ∑ y, a y * b y + ∑ y, b y ^ 2 := by
        simp only [hsplit, add_sq, Finset.sum_add_distrib, Finset.mul_sum]
        congr 1; congr 1; apply Finset.sum_congr rfl; intro y _; ring
    _ ≤ μ ^ 2 * Q + 2 * (μ * lam * Q) + lam ^ 2 * Q := by linarith
    _ = (μ + lam) ^ 2 * Q := by ring

#print axioms energy_step

lemma energy_bound {n d : ℕ} (hd : 0 < d) (g : Fin d → (Fin n → ZMod 2))
    (B : Finset (Fin n → ZMod 2)) (lam : ℝ) (hlam0 : 0 ≤ lam)
    (hlam : ∀ v : (Fin n → ZMod 2) → ℝ, ∑ y, v y = 0 →
      ∑ y, walkStep g v y ^ 2 ≤ lam ^ 2 * ∑ y, v y ^ 2) :
    ∀ r : ℕ, ∑ y, stayTable g B r y ^ 2
      ≤ ((B.card : ℝ) / 2 ^ n + lam) ^ (2 * r) * B.card
  | 0 => by
    have : ∀ y, stayTable g B 0 y ^ 2 = if y ∈ B then (1 : ℝ) else 0 := by
      intro y; simp only [stayTable]; split_ifs <;> simp
    simp only [this, Finset.sum_boole, mul_zero, pow_zero, one_mul]
    rw [Finset.filter_mem_eq_inter, Finset.univ_inter]
  | r + 1 => by
    have hstep := energy_step hd g B lam hlam0 hlam (stayTable g B r) (stayTable_supp g B r)
    have hprev := energy_bound hd g B lam hlam0 hlam r
    have hsq : 0 ≤ ((B.card : ℝ) / 2 ^ n + lam) ^ 2 := sq_nonneg _
    calc ∑ y, stayTable g B (r + 1) y ^ 2
        = ∑ y, (if y ∈ B then walkStep g (stayTable g B r) y else 0) ^ 2 := rfl
      _ ≤ ((B.card : ℝ) / 2 ^ n + lam) ^ 2 * ∑ y, stayTable g B r y ^ 2 := hstep
      _ ≤ ((B.card : ℝ) / 2 ^ n + lam) ^ 2
            * (((B.card : ℝ) / 2 ^ n + lam) ^ (2 * r) * B.card) :=
          mul_le_mul_of_nonneg_left hprev hsq
      _ = ((B.card : ℝ) / 2 ^ n + lam) ^ (2 * (r + 1)) * B.card := by ring

#print axioms energy_bound

/-- **An expander walk can stay inside a small set only with small chance.** The coin strings are
all `2^n` strings of `n` bits; the walk picks a first string `y` evenly, then for each of `m`
further steps picks one of `d` fixed step patterns evenly and flips it in, making `k = m + 1`
tries in all. `B` is the set of failing strings, a share `μ` of all strings. `λ ≥ 0` bounds how
much one step can stretch any list that adds to zero (for this symmetric table, that is the
largest eigenvalue in size after the flat 1). Then the chance that every one of the `k` tries
lands in `B` is at most `μ (μ + λ)^(k-1)`. -/
theorem expander_walk_all_tries_fail_le {n d m : ℕ} (hd : 0 < d) (g : Fin d → (Fin n → ZMod 2))
    (B : Finset (Fin n → ZMod 2)) (lam : ℝ) (hlam0 : 0 ≤ lam)
    (hlam : ∀ v : (Fin n → ZMod 2) → ℝ, ∑ y, v y = 0 →
      ∑ y, walkStep g v y ^ 2 ≤ lam ^ 2 * ∑ y, v y ^ 2) :
    ((univ.filter fun p : (Fin n → ZMod 2) × (Fin m → Fin d) =>
        ∀ t : Fin (m + 1), walkPosition g p.1 p.2 t ∈ B).card : ℝ) / (2 ^ n * d ^ m)
      ≤ ((B.card : ℝ) / 2 ^ n) * ((B.card : ℝ) / 2 ^ n + lam) ^ m := by
  classical
  have hcount : ((univ.filter fun p : (Fin n → ZMod 2) × (Fin m → Fin d) =>
        ∀ t : Fin (m + 1), walkPosition g p.1 p.2 t ∈ B).card : ℝ)
      = (d : ℝ) ^ m * ∑ y, stayTable g B m y := by
    rw [natCast_card_filter, Fintype.sum_prod_type, Finset.mul_sum]
    apply Finset.sum_congr rfl; intro y _
    rw [← stayTable_count hd g B m y, natCast_card_filter]
  have hdpos : (0 : ℝ) < (d : ℝ) ^ m := by
    have : (0 : ℝ) < d := by exact_mod_cast hd
    positivity
  have hNpos : (0 : ℝ) < 2 ^ n := by positivity
  obtain ⟨μ, hμ⟩ : ∃ μ : ℝ, μ = (B.card : ℝ) / 2 ^ n := ⟨_, rfl⟩
  rw [← hμ]
  have hc0 : 0 ≤ μ + lam := by rw [hμ]; positivity
  -- Cauchy-Schwarz on B for the last table
  have hfe : ∑ y, stayTable g B m y
      = ∑ y, (if y ∈ B then (1 : ℝ) else 0) * stayTable g B m y := by
    congr 1; ext y; by_cases hy : y ∈ B
    · simp [hy]
    · simp [hy, stayTable_supp g B m y hy]
  have hind : ∀ y, (if y ∈ B then (1 : ℝ) else 0) ^ 2 = if y ∈ B then 1 else 0 := by
    intro y; split_ifs <;> simp
  have hBcard : ∑ y, (if y ∈ B then (1 : ℝ) else 0) = B.card := by
    rw [Finset.sum_boole, Finset.filter_mem_eq_inter, Finset.univ_inter]
  have hCS : (∑ y, stayTable g B m y) ^ 2 ≤ B.card * ∑ y, stayTable g B m y ^ 2 := by
    rw [hfe]
    calc (∑ y, (if y ∈ B then (1 : ℝ) else 0) * stayTable g B m y) ^ 2
        ≤ (∑ y, (if y ∈ B then (1 : ℝ) else 0) ^ 2) * ∑ y, stayTable g B m y ^ 2 :=
          Finset.sum_mul_sq_le_sq_mul_sq _ _ _
      _ = B.card * ∑ y, stayTable g B m y ^ 2 := by simp only [hind, hBcard]
  have hE := energy_bound hd g B lam hlam0 hlam m
  rw [← hμ] at hE
  have hB0 : (0 : ℝ) ≤ B.card := by positivity
  have hsq : (∑ y, stayTable g B m y) ^ 2 ≤ (B.card * (μ + lam) ^ m) ^ 2 := by
    calc (∑ y, stayTable g B m y) ^ 2 ≤ B.card * ∑ y, stayTable g B m y ^ 2 := hCS
      _ ≤ B.card * ((μ + lam) ^ (2 * m) * B.card) := mul_le_mul_of_nonneg_left hE hB0
      _ = (B.card * (μ + lam) ^ m) ^ 2 := by ring
  have hsum : ∑ y, stayTable g B m y ≤ B.card * (μ + lam) ^ m :=
    (abs_le_of_sq_le_sq' hsq (by positivity)).2
  rw [hcount, div_le_iff₀ (by positivity)]
  calc (d : ℝ) ^ m * ∑ y, stayTable g B m y ≤ (d : ℝ) ^ m * (B.card * (μ + lam) ^ m) :=
        mul_le_mul_of_nonneg_left hsum hdpos.le
    _ = μ * (μ + lam) ^ m * (2 ^ n * d ^ m) := by
        rw [hμ]; field_simp

/-! ## The card's rota: 12 staff, 20 cover pairs, coin `i` puts staff member `i` on lates -/

/-- Coin `i` (staff member `i`, from 1) of a coin string `x`, stored as the bits of a number. -/
def coin (x i : ℕ) : ℕ := (x >>> (i - 1)) % 2

/-- The 20 cover pairs: a ring of 12, six across, and two extra. -/
def pairs : List (ℕ × ℕ) :=
  (List.range 12).map (fun k => (k + 1, (k + 1) % 12 + 1)) ++
    (List.range 6).map (fun k => (k + 1, k + 7)) ++ [(1, 4), (7, 10)]

/-- The number of cover pairs on different shifts. -/
def separated (x : ℕ) : ℕ := (pairs.map fun p => if coin x p.1 = coin x p.2 then 0 else 1).sum

/-- Parity of the 1 bits of a number below 16. -/
def parity4 (v : ℕ) : ℕ := ((List.range 4).map fun k => (v >>> k) % 2).sum % 2

/-- The card's 4-bit generator: coin `i` = parity of (seed AND `i`), for staff 1 to 12. -/
def fake (seed : ℕ) : ℕ := ((List.range 12).map fun k => parity4 (seed &&& (k + 1)) * 2 ^ k).sum

/-- The staff on the late shift. -/
def late (x : ℕ) : List ℕ := (List.range' 1 12).filter fun i => coin x i = 1

example : pairs.length = 20 := by decide

-- coin 8 and coin 9 for seed 9: 1000 AND 1001 = 1000 (one 1), 1001 AND 1001 = 1001 (two 1s)
example : 8 &&& 9 = 8 ∧ 9 &&& 9 = 9 ∧ coin (fake 9) 8 = 1 ∧ coin (fake 9) 9 = 0 := by decide

-- pairs kept apart for seeds 0 to 15, their total 160 (average 10), and 8 seeds missing the goal
example : (List.range 16).map (fun s => separated (fake s)) =
    [0, 14, 12, 14, 9, 11, 9, 11, 8, 16, 8, 8, 7, 15, 7, 11] := by decide
example : ((List.range 16).map fun s => separated (fake s)).sum = 16 * 10 := by decide
example : ((List.range 16).filter fun s => separated (fake s) < 10).length = 8 := by decide

-- best seed 9 and last night's seed 13; seed 0 alone puts nobody on lates
example : late (fake 9) = [1, 3, 5, 7, 8, 10, 12] ∧ separated (fake 9) = 16 := by decide
example : late (fake 13) = [1, 3, 4, 6, 8, 10] ∧ separated (fake 13) = 15 := by decide
example : late (fake 0) = [] ∧ separated (fake 0) = 0 := by decide

-- every one of the 66 coin pairs shows 00, 01, 10, 11 on exactly 4 of the 16 seeds
example : ∀ i ∈ List.range' 1 12, ∀ j ∈ List.range' 1 12, i < j → ∀ a ∈ [0, 1], ∀ b ∈ [0, 1],
    ((List.range 16).filter fun s => coin (fake s) i = a ∧ coin (fake s) j = b).length = 4 := by
  decide

-- a three-coin test sees through it: staff 1, 2, 3 put an even number on lates on every seed
example : ∀ s ∈ List.range 16, (coin (fake s) 1 + coin (fake s) 2 + coin (fake s) 3) % 2 = 0 := by
  decide

-- real coins: 4,096 strings, total kept apart 40,960 (average 10), best 18, 1,664 miss the goal
set_option maxRecDepth 20000 in
example : ((List.range 4096).map separated).sum = 4096 * 10 := by decide
set_option maxRecDepth 20000 in
example : ((List.range 4096).filter fun x => separated x < 10).length = 1664 := by decide
-- best real split: no string beats 18, and string 693 reaches it
set_option maxRecDepth 20000 in
example : (∀ x ∈ List.range 4096, separated x ≤ 18) ∧ separated 693 = 18 := by decide
example : (1664 : ℚ) / 4096 = 13 / 32 := by norm_num

-- seed lengths: 4 bits for 12 coins, 7 for 100, 10 for 1,000 (coins 1 to 2^s - 1)
example : 2 ^ 3 - 1 < 12 ∧ 12 ≤ 2 ^ 4 - 1 ∧ 2 ^ 4 = 16 := by decide
example : 2 ^ 6 - 1 < 100 ∧ 100 ≤ 2 ^ 7 - 1 ∧ 2 ^ 7 = 128 := by decide
example : 2 ^ 9 - 1 < 1000 ∧ 1000 ≤ 2 ^ 10 - 1 ∧ 2 ^ 10 = 1024 := by decide

-- walk bits: 64 patterns are 6 bits a step; four tries cost 48 fresh, 30 walking; eight, 96 and 54
example : 2 ^ 6 = 64 ∧ 4 * 12 = 48 ∧ 12 + 3 * 6 = 30 ∧ 8 * 12 = 96 ∧ 12 + 7 * 6 = 54 := by decide

#print axioms majority_vote_over_seeds_is_right
#print axioms parity_generator_pairwise_independent
#print axioms expander_walk_all_tries_fail_le

end DerandomisationAndPseudorandomness
