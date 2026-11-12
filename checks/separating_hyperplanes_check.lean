-- Separating hyperplanes: a point outside a closed convex set in n-dimensional space is cut off from it by a flat wall at right angles to the gap to the set's closest point, and Farkas' lemma follows.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.LinearAlgebra.Matrix.DotProduct

open Matrix

theorem farkas_aux {m : ℕ} {ι : Type*} [DecidableEq ι] (s : Finset ι) :
    ∀ (a : ι → (Fin m → ℝ)) (b : Fin m → ℝ),
      (∃ θ : ι → ℝ, (∀ j, 0 ≤ θ j) ∧ ∑ j ∈ s, θ j • a j = b) ∨
      ∃ y : Fin m → ℝ, (∀ j ∈ s, 0 ≤ a j ⬝ᵥ y) ∧ b ⬝ᵥ y < 0 := by
  induction s using Finset.induction_on with
  | empty =>
    intro a b
    by_cases hb : b = 0
    · left; exact ⟨0, fun _ => le_rfl, by simp [hb]⟩
    · right
      refine ⟨-b, by simp, ?_⟩
      have h1 : 0 ≤ b ⬝ᵥ b := Finset.sum_nonneg fun i _ => mul_self_nonneg (b i)
      have h2 : b ⬝ᵥ b ≠ 0 := by simpa using hb
      rw [dotProduct_neg]
      exact neg_neg_of_pos (lt_of_le_of_ne h1 (Ne.symm h2))
  | insert i s hi ih =>
    intro a b
    rcases ih a b with ⟨θ, hθ, hsum⟩ | ⟨y, hy, hby⟩
    · left
      refine ⟨Function.update θ i 0, fun j => ?_, ?_⟩
      · by_cases hj : j = i
        · subst hj; simp
        · simp [Function.update_of_ne hj, hθ j]
      · rw [Finset.sum_insert hi]
        simp only [Function.update_self, zero_smul, zero_add]
        rw [← hsum]
        refine Finset.sum_congr rfl fun j hj => ?_
        have : j ≠ i := fun h => hi (h ▸ hj)
        rw [Function.update_of_ne this]
    by_cases hc : 0 ≤ a i ⬝ᵥ y
    · right
      refine ⟨y, fun j hj => ?_, hby⟩
      rcases Finset.mem_insert.1 hj with rfl | hj
      · exact hc
      · exact hy j hj
    rw [not_le] at hc
    set c := a i ⬝ᵥ y with hcdef
    have hcne : c ≠ 0 := hc.ne
    rcases ih (fun j => (a j ⬝ᵥ y) • a i - c • a j) ((b ⬝ᵥ y) • a i - c • b) with
      ⟨θ, hθ, hsum⟩ | ⟨y', hy', hby'⟩
    · left
      set T := ∑ j ∈ s, θ j * (a j ⬝ᵥ y) with hT
      have hTnn : 0 ≤ T := Finset.sum_nonneg fun j hj => mul_nonneg (hθ j) (hy j hj)
      refine ⟨Function.update θ i ((T - b ⬝ᵥ y) / (-c)), fun j => ?_, ?_⟩
      · by_cases hj : j = i
        · subst hj
          simp only [Function.update_self]
          apply div_nonneg <;> linarith
        · simp [Function.update_of_ne hj, hθ j]
      · rw [Finset.sum_insert hi, Function.update_self]
        have hs : ∑ j ∈ s, Function.update θ i ((T - b ⬝ᵥ y) / (-c)) j • a j
            = ∑ j ∈ s, θ j • a j := by
          refine Finset.sum_congr rfl fun j hj => ?_
          have : j ≠ i := fun h => hi (h ▸ hj)
          rw [Function.update_of_ne this]
        rw [hs]
        funext k
        have hk := congrFun hsum k
        simp only [Finset.sum_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul, Pi.add_apply]
          at hk ⊢
        have e1 : ∑ j ∈ s, θ j * ((a j ⬝ᵥ y) * a i k - c * a j k)
            = T * a i k - c * ∑ j ∈ s, θ j * a j k := by
          rw [hT, Finset.sum_mul, Finset.mul_sum, ← Finset.sum_sub_distrib]
          refine Finset.sum_congr rfl fun j _ => ?_
          ring
        rw [e1] at hk
        field_simp
        linear_combination (-1 : ℝ) * hk
    · right
      refine ⟨y' - ((a i ⬝ᵥ y') / c) • y, fun j hj => ?_, ?_⟩
      · rcases Finset.mem_insert.1 hj with rfl | hj
        · rw [dotProduct_sub, dotProduct_smul, smul_eq_mul, ← hcdef]
          field_simp
          simp
        · have h := hy' j hj
          simp only [sub_dotProduct, smul_dotProduct, smul_eq_mul] at h
          rw [dotProduct_sub, dotProduct_smul, smul_eq_mul]
          have : a j ⬝ᵥ y' - a i ⬝ᵥ y' / c * (a j ⬝ᵥ y)
              = ((a j ⬝ᵥ y) * (a i ⬝ᵥ y') - c * (a j ⬝ᵥ y')) / (-c) := by
            field_simp
            ring
          rw [this]
          apply div_nonneg h
          linarith
      · have h := hby'
        simp only [sub_dotProduct, smul_dotProduct, smul_eq_mul] at h
        rw [dotProduct_sub, dotProduct_smul, smul_eq_mul]
        have : b ⬝ᵥ y' - a i ⬝ᵥ y' / c * (b ⬝ᵥ y)
            = ((b ⬝ᵥ y) * (a i ⬝ᵥ y') - c * (b ⬝ᵥ y')) / (-c) := by
          field_simp
          ring
        rw [this]
        apply div_neg_of_neg_of_pos h
        linarith

#print axioms farkas_aux

/-- If a point `x₀` lies outside a closed convex set `C` of points described by `n` numbers,
then `C` has exactly one point `p` closest to `x₀`, and with the arrow `a = p - x₀` every point
`x` of `C` satisfies `aᵀx ≥ aᵀp > aᵀx₀`, the gap being exactly `aᵀp - aᵀx₀ = ‖a‖²`.
(`C` must have at least one point for "the closest point" to exist.) -/
theorem separating_hyperplane_closest_point {n : ℕ} (C : Set (EuclideanSpace ℝ (Fin n)))
    (hconv : Convex ℝ C) (hclosed : IsClosed C) (hne : C.Nonempty)
    (x₀ : EuclideanSpace ℝ (Fin n)) (hx₀ : x₀ ∉ C) :
    ∃ p ∈ C, (∀ q ∈ C, dist x₀ p ≤ dist x₀ q) ∧
      (∀ p' ∈ C, (∀ q ∈ C, dist x₀ p' ≤ dist x₀ q) → p' = p) ∧
      (∀ x ∈ C, inner ℝ (p - x₀) p ≤ inner ℝ (p - x₀) x) ∧
      inner ℝ (p - x₀) x₀ < inner ℝ (p - x₀) p ∧
      inner ℝ (p - x₀) p - inner ℝ (p - x₀) x₀ = ‖p - x₀‖ ^ 2 := by
  obtain ⟨p, hpC, hp⟩ := exists_norm_eq_iInf_of_complete_convex hne hclosed.isComplete hconv x₀
  have hbdd : BddBelow (Set.range fun w : C => ‖x₀ - (w : EuclideanSpace ℝ (Fin n))‖) :=
    ⟨0, Set.forall_mem_range.2 fun _ => norm_nonneg _⟩
  have hvar := (norm_eq_iInf_iff_real_inner_le_zero hconv hpC).1 hp
  have hgap : inner ℝ (p - x₀) p - inner ℝ (p - x₀) x₀ = ‖p - x₀‖ ^ 2 := by
    rw [← inner_sub_right, real_inner_self_eq_norm_sq]
  have hpne : p - x₀ ≠ 0 := by
    intro h
    rw [sub_eq_zero] at h
    exact hx₀ (h ▸ hpC)
  have hpos : 0 < ‖p - x₀‖ ^ 2 := by positivity
  refine ⟨p, hpC, ?_, ?_, ?_, by linarith, hgap⟩
  · intro q hq
    rw [dist_eq_norm, dist_eq_norm, hp]
    exact ciInf_le hbdd ⟨q, hq⟩
  · intro p' hp'C hp'
    have hp'eq : ‖x₀ - p'‖ = ⨅ w : C, ‖x₀ - w‖ := by
      apply le_antisymm
      · have : Nonempty C := ⟨⟨p', hp'C⟩⟩
        refine le_ciInf fun w => ?_
        have := hp' w w.2
        rwa [dist_eq_norm, dist_eq_norm] at this
      · exact ciInf_le hbdd ⟨p', hp'C⟩
    have hvar' := (norm_eq_iInf_iff_real_inner_le_zero hconv hp'C).1 hp'eq
    have h1 := hvar p' hp'C
    have h2 := hvar' p hpC
    have h3 : inner ℝ (p' - p) (p' - p) ≤ (0 : ℝ) := by
      have e : inner ℝ (p' - p) (p' - p)
          = inner ℝ (x₀ - p) (p' - p) + inner ℝ (x₀ - p') (p - p') := by
        simp only [inner_sub_left, inner_sub_right, real_inner_comm]
        ring
      linarith
    rw [real_inner_self_eq_norm_sq] at h3
    have : ‖p' - p‖ = 0 := by nlinarith [norm_nonneg (p' - p)]
    exact sub_eq_zero.1 (norm_eq_zero.1 this)
  · intro x hx
    have h := hvar x hx
    have e : inner ℝ (p - x₀) x - inner ℝ (p - x₀) p = - inner ℝ (x₀ - p) (x - p) := by
      simp only [inner_sub_left, inner_sub_right]
      ring
    linarith

/-- The wall itself: if a point `x₀` lies outside a closed convex set `C` in `n` dimensions,
there is a direction `a` and a level `β` with `x₀` strictly on one side of the wall
`{x : aᵀx = β}` and every point of `C` strictly on the other. -/
theorem separating_hyperplane_exists {n : ℕ} (C : Set (EuclideanSpace ℝ (Fin n)))
    (hconv : Convex ℝ C) (hclosed : IsClosed C)
    (x₀ : EuclideanSpace ℝ (Fin n)) (hx₀ : x₀ ∉ C) :
    ∃ (a : EuclideanSpace ℝ (Fin n)) (β : ℝ),
      inner ℝ a x₀ < β ∧ ∀ x ∈ C, β < inner ℝ a x := by
  rcases C.eq_empty_or_nonempty with hC | hne
  · exact ⟨0, 1, by simp, by simp [hC]⟩
  obtain ⟨p, hpC, -, -, hle, hlt, -⟩ :=
    separating_hyperplane_closest_point C hconv hclosed hne x₀ hx₀
  refine ⟨p - x₀, (inner ℝ (p - x₀) x₀ + inner ℝ (p - x₀) p) / 2, by linarith, fun x hx => ?_⟩
  have := hle x hx
  linarith

/-- Farkas' lemma: for a matrix `A` and a column `b`, exactly one of these holds:
(i) `Aθ = b` for some `θ ≥ 0`, or (ii) `Aᵀy ≥ 0` and `bᵀy < 0` for some `y`
(vector inequalities entry by entry). -/
theorem farkas_lemma {m k : ℕ} (A : Matrix (Fin m) (Fin k) ℝ) (b : Fin m → ℝ) :
    Xor' (∃ θ : Fin k → ℝ, 0 ≤ θ ∧ A *ᵥ θ = b)
      (∃ y : Fin m → ℝ, 0 ≤ Aᵀ *ᵥ y ∧ b ⬝ᵥ y < 0) := by
  have hnot : ¬ ((∃ θ : Fin k → ℝ, 0 ≤ θ ∧ A *ᵥ θ = b) ∧
      (∃ y : Fin m → ℝ, 0 ≤ Aᵀ *ᵥ y ∧ b ⬝ᵥ y < 0)) := by
    rintro ⟨⟨θ, hθ, hAθ⟩, ⟨y, hy, hby⟩⟩
    have : b ⬝ᵥ y = (Aᵀ *ᵥ y) ⬝ᵥ θ := by
      rw [← hAθ, dotProduct_comm, dotProduct_mulVec, mulVec_transpose]
    have h0 : 0 ≤ (Aᵀ *ᵥ y) ⬝ᵥ θ := dotProduct_nonneg_of_nonneg hy hθ
    linarith
  have hor : (∃ θ : Fin k → ℝ, 0 ≤ θ ∧ A *ᵥ θ = b) ∨
      (∃ y : Fin m → ℝ, 0 ≤ Aᵀ *ᵥ y ∧ b ⬝ᵥ y < 0) := by
    rcases farkas_aux (Finset.univ : Finset (Fin k)) (fun j => Aᵀ j) b with
      ⟨θ, hθ, hsum⟩ | ⟨y, hy, hby⟩
    · left
      refine ⟨θ, fun j => hθ j, ?_⟩
      rw [← hsum]
      funext i
      simp only [mulVec, dotProduct, Finset.sum_apply, Pi.smul_apply, smul_eq_mul, transpose_apply]
      exact Finset.sum_congr rfl fun j _ => mul_comm _ _
    · right
      exact ⟨y, fun j => hy j (Finset.mem_univ j), hby⟩
  rcases hor with h | h
  · exact Or.inl ⟨h, fun h' => hnot ⟨h, h'⟩⟩
  · exact Or.inr ⟨h, fun h' => hnot ⟨h', h⟩⟩

-- The card's worked numbers, in exact fractions (caffeine in g/kg, cost in pounds/kg).

-- Bean scores under caffeine + 3 × cost, the spec's score, and the gap.
example : (22 : ℚ) + 3 * 5 = 37 ∧ (13 : ℚ) + 3 * 8 = 37 ∧ (11 : ℚ) + 3 * 14 = 53 := by norm_num
example : (18 : ℚ) + 3 * (11 / 2) = 69 / 2 ∧ (37 : ℚ) - 69 / 2 = 5 / 2 := by norm_num

-- Half Robusta, half Brazil lands at (17.5, 6.50).
example : (1 / 2 : ℚ) * 22 + 1 / 2 * 13 = 35 / 2 ∧ (1 / 2 : ℚ) * 5 + 1 / 2 * 8 = 13 / 2 := by
  norm_num

-- The closest blend: 7/12 Robusta, 5/12 Brazil at (18.25, 6.25); squared gap 5/8;
-- the gap arrow (1/4, 3/4) is at right angles to the Robusta–Brazil edge; 2.5 = 4 × 5/8.
example : (7 / 12 : ℚ) * 22 + 5 / 12 * 13 = 73 / 4 ∧ (7 / 12 : ℚ) * 5 + 5 / 12 * 8 = 25 / 4 := by
  norm_num
example : ((73 / 4 : ℚ) - 18) ^ 2 + ((25 / 4 : ℚ) - 11 / 2) ^ 2 = 5 / 8 := by norm_num
example : (1 / 4 : ℚ) * (13 - 22) + 3 / 4 * (8 - 5) = 0 := by norm_num
example : (5 / 2 : ℚ) = 4 * (5 / 8) := by norm_num

-- The price line: at 18 g/kg the cost is at least 19/3, met by 5/9 Robusta, 4/9 Brazil;
-- at 5.50 a kilo the caffeine is at least 20.5.
example : ((37 : ℚ) - 18) / 3 = 19 / 3 := by norm_num
example : (5 / 9 : ℚ) * 22 + 4 / 9 * 13 = 18 ∧ (5 / 9 : ℚ) * 5 + 4 / 9 * 8 = 19 / 3 := by norm_num
example : (37 : ℚ) - 3 * (11 / 2) = 41 / 2 := by norm_num

-- Farkas' certificate y = (-37, 1, 3): Aᵀy = (0, 0, 16) and bᵀy = -2.5.
example : (!![1, 1, 1; 22, 13, 11; 5, 8, 14] : Matrix (Fin 3) (Fin 3) ℚ)ᵀ *ᵥ ![-37, 1, 3]
    = ![0, 0, 16] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]
example : (![1, 18, 11 / 2] : Fin 3 → ℚ) ⬝ᵥ ![-37, 1, 3] = -5 / 2 := by
  norm_num [dotProduct, Fin.sum_univ_three]

-- The only exact mix, 25/48, 61/96, -5/32, hits the spec but needs a negative weight.
example : (!![1, 1, 1; 22, 13, 11; 5, 8, 14] : Matrix (Fin 3) (Fin 3) ℚ) *ᵥ ![25 / 48, 61 / 96, -5 / 32]
    = ![1, 18, 11 / 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- The reachable spec (15, 10): weights 1/3, 1/6, 1/2, and the certificate gives 8, not negative.
example : (!![1, 1, 1; 22, 13, 11; 5, 8, 14] : Matrix (Fin 3) (Fin 3) ℚ) *ᵥ ![1 / 3, 1 / 6, 1 / 2]
    = ![1, 15, 10] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]
example : (![1, 15, 10] : Fin 3 → ℚ) ⬝ᵥ ![-37, 1, 3] = 8 := by
  norm_num [dotProduct, Fin.sum_univ_three]

-- The nearest-bean mistake: normal (8, -1) scores the beans 171, 96, 74 against the spec's 138.5.
example : (8 : ℚ) * 22 - 5 = 171 ∧ (8 : ℚ) * 13 - 8 = 96 ∧ (8 : ℚ) * 11 - 14 = 74 ∧
    (8 : ℚ) * 18 - 11 / 2 = 277 / 2 := by norm_num

#print axioms separating_hyperplane_closest_point
#print axioms separating_hyperplane_exists
#print axioms farkas_lemma
