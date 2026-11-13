-- Permutation tests: when every way of choosing which n of N visitors get the new page is equally likely and the amounts do not depend on the labels, a p-value at or below α turns up in at most a share α of the assignments, the gap's shuffle law has mean 0 and spread √(S²(1/n + 1/(N−n))), and the card's 16 visitors give 12,870 assignments with 274 + 274 = 548 as extreme as the observed gap.
import Mathlib.Data.Finset.Powerset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Fin.VecNotation

open Finset

/-- The gap under assignment `a`: the average of the visitors in `a` (the new group of size n)
minus the average of the other `N - n` visitors. -/
noncomputable def gap (N n : ℕ) (y : Fin N → ℝ) (a : Finset (Fin N)) : ℝ :=
  (∑ i ∈ a, y i) / (n : ℝ) - (∑ i ∈ aᶜ, y i) / ((N - n : ℕ) : ℝ)

lemma tail_count_le {ι : Type*} (A : Finset ι) (f : ι → ℝ) (k : ℝ) (hk : 0 ≤ k) :
    ((A.filter (fun a => (((A.filter (fun b => f a ≤ f b)).card : ℝ) ≤ k))).card : ℝ) ≤ k := by
  classical
  set S := A.filter (fun a => (((A.filter (fun b => f a ≤ f b)).card : ℝ) ≤ k)) with hS
  rcases S.eq_empty_or_nonempty with h | h
  · simp [h, hk]
  · obtain ⟨a0, ha0, hmin⟩ := S.exists_min_image f h
    have hsub : S ⊆ A.filter (fun b => f a0 ≤ f b) := by
      intro a ha
      exact mem_filter.mpr ⟨(mem_filter.mp ha).1, hmin a ha⟩
    have h1 : ((A.filter (fun b => f a0 ≤ f b)).card : ℝ) ≤ k := (mem_filter.mp ha0).2
    calc (S.card : ℝ) ≤ (A.filter (fun b => f a0 ≤ f b)).card := by
          exact_mod_cast card_le_card hsub
      _ ≤ k := h1

lemma sum_mem_swap {N : ℕ} {β : Type*} [AddCommMonoid β] (B : Finset (Finset (Fin N)))
    (F : Fin N → Finset (Fin N) → β) :
    ∑ a ∈ B, ∑ i ∈ a, F i a = ∑ i, ∑ a ∈ B.filter (fun a => i ∈ a), F i a := by
  apply Finset.sum_comm'
  intro a i
  simp

lemma sum_mem_const {N : ℕ} (B : Finset (Finset (Fin N))) (w : Fin N → ℝ) :
    ∑ a ∈ B, ∑ i ∈ a, w i = ∑ i, w i * ((B.filter (fun a => i ∈ a)).card : ℝ) := by
  rw [sum_mem_swap B (fun i _ => w i)]
  simp [mul_comm]

lemma card_filter_perm {N n : ℕ} (σ : Equiv.Perm (Fin N)) (P : Finset (Fin N) → Prop)
    [DecidablePred P] :
    (((univ : Finset (Fin N)).powersetCard n).filter (fun a => P (a.map σ.toEmbedding))).card =
      (((univ : Finset (Fin N)).powersetCard n).filter P).card := by
  apply Finset.card_nbij' (fun a => a.map σ.toEmbedding) (fun a => a.map σ.symm.toEmbedding)
  · intro a ha
    simp only [coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at ha ⊢
    exact ⟨⟨subset_univ _, by rw [card_map]; exact ha.1.2⟩, ha.2⟩
  · intro a ha
    simp only [coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at ha ⊢
    refine ⟨⟨subset_univ _, by rw [card_map]; exact ha.1.2⟩, ?_⟩
    rw [map_map]; simpa using ha.2
  · intro a _; simp [map_map]
  · intro a _; simp [map_map]

#print axioms tail_count_le
#print axioms sum_mem_swap
#print axioms sum_mem_const
#print axioms card_filter_perm

/-- The permutation test's guarantee. Fix the N amounts `y` (under the sharp null they do not
depend on the assignment). The lottery picks which n visitors see the new page, every one of the
`M = C(N, n)` assignments equally likely. The p-value of an assignment `a` is the share of
assignments `b` whose gap is at least as far from zero as that of `a`, ties counted. Then for
every level α between 0 and 1, the share of assignments whose p-value is at or below α (the
false alarms) is at most α, whatever the amounts look like. -/
theorem permutation_test_false_alarm_rate_le_level (N n : ℕ) (y : Fin N → ℝ) (α : ℝ)
    (hα0 : 0 ≤ α) (hα1 : α ≤ 1) :
    let A := (univ : Finset (Fin N)).powersetCard n
    let M : ℝ := (A.card : ℝ)
    let p : Finset (Fin N) → ℝ := fun a =>
      ((A.filter (fun b => |gap N n y a| ≤ |gap N n y b|)).card : ℝ) / M
    ((A.filter (fun a => p a ≤ α)).card : ℝ) / M ≤ α := by
  intro A M p
  rcases eq_or_lt_of_le (Nat.cast_nonneg A.card : (0:ℝ) ≤ A.card) with hM | hM
  · show _ / (A.card : ℝ) ≤ α
    rw [← hM]; simp [hα0]
  · have key := tail_count_le A (fun a => |gap N n y a|) (α * M) (by positivity)
    have hfilt : A.filter (fun a => p a ≤ α) = A.filter (fun a =>
        ((A.filter (fun b => |gap N n y a| ≤ |gap N n y b|)).card : ℝ) ≤ α * M) := by
      apply filter_congr; intro a _; simp only [p]; rw [div_le_iff₀ hM]
    rw [hfilt, div_le_iff₀ hM]; exact key

/-- The spread of the shuffle law, by formula. With both groups non-empty, the gap averaged over
all `C(N, n)` equally likely assignments is 0, and its standard deviation over them is
`√(S² (1/n + 1/(N − n)))`, where `S² = Σ (yᵢ − ȳ)² / (N − 1)` is the spread of all N amounts. -/
theorem shuffle_law_mean_zero_and_sd (N n : ℕ) (y : Fin N → ℝ) (hn : 0 < n) (hnN : n < N) :
    let A := (univ : Finset (Fin N)).powersetCard n
    let M : ℝ := (A.card : ℝ)
    let ybar : ℝ := (∑ i, y i) / (N : ℝ)
    let S2 : ℝ := (∑ i, (y i - ybar) ^ 2) / ((N : ℝ) - 1)
    let mean : ℝ := (∑ a ∈ A, gap N n y a) / M
    mean = 0 ∧
      Real.sqrt ((∑ a ∈ A, (gap N n y a - mean) ^ 2) / M) =
        Real.sqrt (S2 * (1 / (n : ℝ) + 1 / ((N : ℝ) - n))) := by
  intro A M ybar S2 mean
  have hnNR : (n:ℝ) < N := by exact_mod_cast hnN
  have hN1 : (1:ℝ) < N := by exact_mod_cast (show 1 < N by omega)
  have hnR : (0:ℝ) < n := by exact_mod_cast hn
  have hNnR : (0:ℝ) < (N:ℝ) - n := by linarith
  have hNR : (0:ℝ) < N := by linarith
  have hMpos : (0:ℝ) < M := by
    show (0:ℝ) < (A.card : ℝ)
    simp only [A, card_powersetCard, card_univ, Fintype.card_fin]
    exact_mod_cast Nat.choose_pos hnN.le
  let z : Fin N → ℝ := fun i => y i - ybar
  have hzsum : ∑ i, z i = 0 := by
    simp only [z, sum_sub_distrib, sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
    simp only [ybar]; field_simp; ring
  have hgap : ∀ a ∈ A, gap N n y a = (N:ℝ) / (n * ((N:ℝ) - n)) * ∑ i ∈ a, z i := by
    intro a ha
    have hca : a.card = n := (mem_powersetCard.mp ha).2
    have hcompl : ∑ i ∈ aᶜ, y i = ∑ i, y i - ∑ i ∈ a, y i := by
      rw [← sum_compl_add_sum a]; ring
    have hza : ∑ i ∈ a, z i = ∑ i ∈ a, y i - n * ybar := by
      simp [z, sum_sub_distrib, hca]
    have hT : ∑ i, y i = N * ybar := by simp only [ybar]; field_simp
    unfold gap
    rw [hcompl, hza, hT, Nat.cast_sub hnN.le]
    field_simp
    ring
  have hc1const : ∀ i j, (A.filter (fun a => i ∈ a)).card = (A.filter (fun a => j ∈ a)).card := by
    intro i j
    have := card_filter_perm (n := n) (Equiv.swap i j) (fun a => i ∈ a)
    simp only [mem_map_equiv, Equiv.symm_swap, Equiv.swap_apply_left] at this
    exact this.symm
  have hc1val : ∀ i, ((A.filter (fun a => i ∈ a)).card : ℝ) = n * M / N := by
    intro i
    have h := sum_mem_const A (fun _ => (1:ℝ))
    have hL : ∑ a ∈ A, ∑ j ∈ a, (fun _ => (1:ℝ)) j = M * n := by
      simp only [sum_const, nsmul_eq_mul, mul_one]
      rw [sum_congr rfl (fun a ha => by rw [(mem_powersetCard.mp ha).2])]
      simp [M]
    have hR : ∑ j, (fun _ => (1:ℝ)) j * ((A.filter (fun a => j ∈ a)).card : ℝ) =
        N * ((A.filter (fun a => i ∈ a)).card : ℝ) := by
      simp only [one_mul]
      rw [sum_congr rfl (fun j _ => by rw [hc1const j i])]
      simp
    rw [hL, hR] at h
    field_simp; linarith
  have hc2const : ∀ i j l, j ≠ i → l ≠ i →
      (A.filter (fun a => i ∈ a ∧ j ∈ a)).card = (A.filter (fun a => i ∈ a ∧ l ∈ a)).card := by
    intro i j l hj hl
    have := card_filter_perm (n := n) (Equiv.swap j l) (fun a => i ∈ a ∧ j ∈ a)
    simp only [mem_map_equiv, Equiv.symm_swap, Equiv.swap_apply_left,
      Equiv.swap_apply_of_ne_of_ne (Ne.symm hj) (Ne.symm hl)] at this
    exact this.symm
  have hc2val : ∀ i j, j ≠ i →
      ((A.filter (fun a => i ∈ a ∧ j ∈ a)).card : ℝ) = n * M / N * (n - 1) / (N - 1) := by
    intro i j hji
    have h := sum_mem_const (A.filter (fun a => i ∈ a)) (fun _ => (1:ℝ))
    simp only [filter_filter, one_mul] at h
    have hL : ∑ a ∈ A.filter (fun a => i ∈ a), ∑ k ∈ a, (1:ℝ) = (n * M / N) * n := by
      simp only [sum_const, nsmul_eq_mul, mul_one]
      rw [sum_congr rfl (fun a ha => by rw [(mem_powersetCard.mp (mem_filter.mp ha).1).2])]
      rw [sum_const, nsmul_eq_mul, hc1val]
    rw [hL, ← add_sum_erase _ _ (mem_univ i)] at h
    rw [sum_congr rfl (fun k hk => by rw [hc2const i k j (ne_of_mem_erase hk) hji])] at h
    simp only [and_self, sum_const, card_erase_of_mem (mem_univ i), card_univ,
      Fintype.card_fin, nsmul_eq_mul, hc1val] at h
    rw [Nat.cast_sub (by omega : 1 ≤ N)] at h
    rw [eq_div_iff (by linarith)]
    push_cast at h
    linear_combination -h
  have hsum1 : ∑ a ∈ A, ∑ i ∈ a, z i = 0 := by
    rw [sum_mem_const]
    simp_rw [hc1val]
    rw [← sum_mul, hzsum, zero_mul]
  have hinner : ∀ i, ∑ j, z j * (((A.filter (fun a => i ∈ a)).filter (fun a => j ∈ a)).card : ℝ) =
      z i * (n * M / N - n * M / N * (n - 1) / (N - 1)) := by
    intro i
    simp only [filter_filter]
    rw [← add_sum_erase _ _ (mem_univ i)]
    rw [sum_congr rfl (fun k hk => by rw [hc2val i k (ne_of_mem_erase hk)])]
    rw [← sum_mul]
    have he : ∑ k ∈ univ.erase i, z k = - z i := by
      have := add_sum_erase univ z (mem_univ i); rw [hzsum] at this; linarith
    rw [he]; simp only [and_self, hc1val]; ring
  have hsum2 : ∑ a ∈ A, (∑ i ∈ a, z i) ^ 2 =
      (n * M / N - n * M / N * (n - 1) / (N - 1)) * ∑ i, z i ^ 2 := by
    have e1 : ∀ a : Finset (Fin N), (∑ i ∈ a, z i) ^ 2 = ∑ i ∈ a, z i * ∑ j ∈ a, z j := by
      intro a; rw [sq, sum_mul]
    simp_rw [e1]
    have := sum_mem_swap A (fun i a => z i * ∑ j ∈ a, z j)
    beta_reduce at this
    rw [this]
    simp_rw [← mul_sum]
    have e2 : ∀ i, ∑ a ∈ A.filter (fun a => i ∈ a), ∑ j ∈ a, z j =
        z i * (n * M / N - n * M / N * (n - 1) / (N - 1)) := by
      intro i; rw [sum_mem_const]; exact hinner i
    simp_rw [e2, mul_sum]
    apply sum_congr rfl; intro i _; ring
  have hmean : mean = 0 := by
    simp only [mean]; rw [sum_congr rfl hgap, ← mul_sum, hsum1]; simp
  refine ⟨hmean, ?_⟩
  congr 1
  rw [hmean]; simp only [sub_zero]
  have e3 : ∑ a ∈ A, gap N n y a ^ 2 =
      ∑ a ∈ A, ((N:ℝ) / (n * ((N:ℝ) - n))) ^ 2 * (∑ i ∈ a, z i) ^ 2 :=
    sum_congr rfl (fun a ha => by rw [hgap a ha, mul_pow])
  rw [e3, ← mul_sum, hsum2]
  have hS2 : S2 = (∑ i, z i ^ 2) / ((N : ℝ) - 1) := rfl
  rw [hS2]
  have hN1' : (0:ℝ) < (N:ℝ) - 1 := by linarith
  field_simp
  ring

/-- The mirror symmetry of the shuffle law when both groups have the same size: swapping every
label turns a gap of `t` into `-t`, so the assignments with a gap of `t` or more are exactly as
many as those with a gap of `-t` or less. -/
theorem shuffle_law_symmetric_of_equal_groups (N n : ℕ) (y : Fin N → ℝ) (hN : N = 2 * n)
    (t : ℝ) :
    let A := (univ : Finset (Fin N)).powersetCard n
    (A.filter (fun a => t ≤ gap N n y a)).card =
      (A.filter (fun a => gap N n y a ≤ -t)).card := by
  intro A
  subst hN
  have hsub : (2 * n - n : ℕ) = n := by omega
  have hneg : ∀ a : Finset (Fin (2*n)), gap (2*n) n y aᶜ = - gap (2*n) n y a := by
    intro a; simp only [gap, compl_compl, hsub]; ring
  apply Finset.card_nbij' (fun a => aᶜ) (fun a => aᶜ)
  · intro a ha
    simp only [A, coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at ha ⊢
    refine ⟨⟨subset_univ _, ?_⟩, ?_⟩
    · rw [card_compl, Fintype.card_fin, ha.1.2]; omega
    · rw [hneg]; linarith [ha.2]
  · intro a ha
    simp only [A, coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at ha ⊢
    refine ⟨⟨subset_univ _, ?_⟩, ?_⟩
    · rw [card_compl, Fintype.card_fin, ha.1.2]; omega
    · rw [hneg]; linarith [ha.2]
  · intro a _; simp
  · intro a _; simp

/-- The card's sixteen visitors: the eight old-page amounts, then the eight new-page amounts. -/
def spend : Fin 16 → ℕ := ![0, 8, 0, 12, 0, 8, 0, 8, 22, 0, 95, 0, 22, 27, 0, 22]

/-- The observed new-page group: visitors 8 to 15. -/
def newGroup : Finset (Fin 16) := univ.filter (fun i => 8 ≤ i.val)

-- 12,870 possible lotteries: C(16, 8).
example : Nat.choose 16 8 = 12870 := by decide
example : ((univ : Finset (Fin 16)).powersetCard 8).card = 12870 := by simp [card_powersetCard]; decide

-- The new-page total is 188, the old-page total 36, the pooled total 224.
example : ∑ i ∈ newGroup, spend i = 188 := by decide +kernel
example : ∑ i ∈ newGroupᶜ, spend i = 36 := by decide +kernel
example : ∑ i, spend i = 224 := by decide +kernel

-- The observed gap: 188/8 − 36/8 = 19 dollars.
example : (188 : ℚ) / 8 - 36 / 8 = 19 := by norm_num

-- 274 lotteries give a new-group total of 188 or more (a gap of +19 or more).
example : (((univ : Finset (Fin 16)).powersetCard 8).filter
    (fun a => 188 ≤ ∑ i ∈ a, spend i)).card = 274 := by decide +kernel

-- 274 give a total of 36 or less (a gap of −19 or less).
example : (((univ : Finset (Fin 16)).powersetCard 8).filter
    (fun a => ∑ i ∈ a, spend i ≤ 36)).card = 274 := by decide +kernel

-- As extreme in either direction: 548 of 12,870, the p-value.
example : (((univ : Finset (Fin 16)).powersetCard 8).filter
    (fun a => 188 ≤ ∑ i ∈ a, spend i ∨ ∑ i ∈ a, spend i ≤ 36)).card = 548 := by decide +kernel

-- Counting only gaps strictly beyond 19 drops the ties: 478 lotteries.
example : (((univ : Finset (Fin 16)).powersetCard 8).filter
    (fun a => 188 < ∑ i ∈ a, spend i ∨ ∑ i ∈ a, spend i < 36)).card = 478 := by decide +kernel

#print axioms permutation_test_false_alarm_rate_le_level
#print axioms shuffle_law_mean_zero_and_sd
#print axioms shuffle_law_symmetric_of_equal_groups
