-- Submodular functions: for a monotone set function with diminishing returns and value 0 on the empty set, greedy's k picks reach at least 1 - (1 - 1/k)^k, and so at least 1 - 1/e, of every set of at most k items; the gain test and the overlap test are equivalent; and the Lovász extension is convex on the cube exactly when the overlap test holds.
import Mathlib.Data.Fintype.Powerset
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Convex.Function
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

/-! The card's notation.
* `α` holds the items (the ground set `V`); a set of items is a `Finset α`.
* `f : Finset α → ℝ` is the set function; the gain of `j` on top of `S` is
  `f (insert j S) - f S`, the card's `f(j | S)`.
* "Monotone" is Mathlib's `Monotone f`, for the order `S ⊆ T` on sets.
* Greedy's set after `i` picks is `S i`, with `S 0 = ∅`. Pick `i + 1` adds one item `x` not yet
  in `S i` whose gain is at least the gain of every other item not yet in `S i`; ties may go
  either way.
* "The best value any k items reach" is written as a bound against every set `O` of at most `k`
  items, which is the same as a bound against OPT.
* The Lovász extension is the card's threshold form: `f_L(x) = ∫₀¹ f({j : x_j ≥ t}) dt`, for
  `x` in the cube `[0, 1]ⁿ`, written `Set.Icc 0 1` in `α → ℝ`. -/

theorem submod_gain_sum_le {α : Type*} [DecidableEq α]
    (f : Finset α → ℝ)
    (hdr : ∀ (S T : Finset α) (j : α), S ⊆ T → j ∉ T →
      f (insert j T) - f T ≤ f (insert j S) - f S)
    (S O : Finset α) :
    f (S ∪ O) - f S ≤ ∑ o ∈ O \ S, (f (insert o S) - f S) := by
  induction O using Finset.induction_on with
  | empty => simp
  | @insert a O ha ih =>
    by_cases haS : a ∈ S
    · rw [Finset.insert_sdiff_of_mem _ haS]
      have : S ∪ insert a O = S ∪ O := by
        rw [Finset.union_insert, Finset.insert_eq_of_mem (Finset.mem_union_left _ haS)]
      rw [this]; exact ih
    · rw [Finset.insert_sdiff_of_notMem _ haS, Finset.sum_insert (by simp [ha])]
      have h1 : a ∉ S ∪ O := by simp [ha, haS]
      have h2 := hdr S (S ∪ O) a Finset.subset_union_left h1
      rw [Finset.union_insert]
      linarith

#print axioms submod_gain_sum_le

/-- The greedy promise. Let `f` give 0 to the empty set, never fall when items are added, and
have diminishing returns: an item's gain on top of `S` is at least its gain on top of any bigger
`T ⊇ S` that does not contain it. Run greedy for `k` picks, each time adding the item not yet
chosen with the largest gain. Then for every set `O` of at most `k` items,
`f(S_k) ≥ (1 - (1 - 1/k)^k) f(O)` and `f(S_k) ≥ (1 - 1/e) f(O)`. -/
theorem greedy_reaches_one_minus_inv_e_of_best {α : Type*} [DecidableEq α]
    (f : Finset α → ℝ) (hempty : f ∅ = 0) (hmono : Monotone f)
    (hdr : ∀ (S T : Finset α) (j : α), S ⊆ T → j ∉ T →
      f (insert j T) - f T ≤ f (insert j S) - f S)
    (k : ℕ) (S : ℕ → Finset α) (hS0 : S 0 = ∅)
    (hgreedy : ∀ i < k, ∃ x, x ∉ S i ∧ S (i + 1) = insert x (S i) ∧
      ∀ y, y ∉ S i → f (insert y (S i)) - f (S i) ≤ f (insert x (S i)) - f (S i))
    (O : Finset α) (hO : O.card ≤ k) :
    (1 - (1 - 1 / (k : ℝ)) ^ k) * f O ≤ f (S k) ∧
      (1 - Real.exp (-1)) * f O ≤ f (S k) := by
  have hO0 : 0 ≤ f O := by
    have := hmono (Finset.empty_subset O); rw [hempty] at this; exact this
  -- one step
  have step : ∀ i < k, f O - f (S (i + 1)) ≤ (1 - 1 / (k : ℝ)) * (f O - f (S i)) := by
    intro i hi
    obtain ⟨x, hx, hSx, hbest⟩ := hgreedy i hi
    have hkpos : (0 : ℝ) < k := by exact_mod_cast (show 0 < k by omega)
    set δ := f (insert x (S i)) - f (S i) with hδ
    have hδ0 : 0 ≤ δ := by
      have := hmono (Finset.subset_insert x (S i)); simp only [hδ]; linarith
    have h1 : f O ≤ f (S i ∪ O) := hmono Finset.subset_union_right
    have h2 := submod_gain_sum_le f hdr (S i) O
    have h3 : ∑ o ∈ O \ S i, (f (insert o (S i)) - f (S i)) ≤ (O \ S i).card * δ := by
      have := Finset.sum_le_sum (s := O \ S i) (fun o ho => hbest o (Finset.mem_sdiff.1 ho).2)
      simpa [Finset.sum_const, nsmul_eq_mul] using this
    have h4 : ((O \ S i).card : ℝ) ≤ k := by
      exact_mod_cast (Finset.card_le_card Finset.sdiff_subset).trans hO
    have h5 : ((O \ S i).card : ℝ) * δ ≤ k * δ := mul_le_mul_of_nonneg_right h4 hδ0
    have key : f O - f (S i) ≤ k * δ := by linarith
    rw [hSx]
    have : (1 - 1 / (k : ℝ)) * (f O - f (S i)) = (f O - f (S i)) - (f O - f (S i)) / k := by
      field_simp
    rw [this]
    have : (f O - f (S i)) / k ≤ δ := by
      rw [div_le_iff₀ hkpos]; linarith
    linarith
  have ind : ∀ i ≤ k, f O - f (S i) ≤ (1 - 1 / (k : ℝ)) ^ i * f O := by
    intro i
    induction i with
    | zero => intro _; simp [hS0, hempty]
    | succ i ih =>
      intro hi
      have hk1 : (1 : ℝ) ≤ k := by exact_mod_cast (show 1 ≤ k by omega)
      have hnn : 0 ≤ 1 - 1 / (k : ℝ) := by
        rw [sub_nonneg, div_le_one (by linarith)]; exact hk1
      calc f O - f (S (i + 1)) ≤ (1 - 1 / (k : ℝ)) * (f O - f (S i)) := step i (by omega)
        _ ≤ (1 - 1 / (k : ℝ)) * ((1 - 1 / (k : ℝ)) ^ i * f O) :=
          mul_le_mul_of_nonneg_left (ih (by omega)) hnn
        _ = (1 - 1 / (k : ℝ)) ^ (i + 1) * f O := by ring
  have first : (1 - (1 - 1 / (k : ℝ)) ^ k) * f O ≤ f (S k) := by
    have := ind k le_rfl; linarith
  refine ⟨first, ?_⟩
  rcases Nat.eq_zero_or_pos k with hk | hk
  · subst hk
    have : O = ∅ := Finset.card_eq_zero.1 (by omega)
    subst this; simp [hempty, hS0]
  · have hkR : (0 : ℝ) < k := by exact_mod_cast hk
    have hnn : 0 ≤ 1 - 1 / (k : ℝ) := by
      rw [sub_nonneg, div_le_one hkR]; exact_mod_cast hk
    have hle : (1 - 1 / (k : ℝ)) ^ k ≤ Real.exp (-1) := by
      have h1 : 1 - 1 / (k : ℝ) ≤ Real.exp (-(1 / (k : ℝ))) := by
        have := Real.add_one_le_exp (-(1 / (k : ℝ))); linarith
      calc (1 - 1 / (k : ℝ)) ^ k ≤ Real.exp (-(1 / (k : ℝ))) ^ k := pow_le_pow_left₀ hnn h1 k
        _ = Real.exp (-1) := by
          rw [← Real.exp_nat_mul]; congr 1; field_simp
    have : (1 - Real.exp (-1)) * f O ≤ (1 - (1 - 1 / (k : ℝ)) ^ k) * f O :=
      mul_le_mul_of_nonneg_right (by linarith) hO0
    linarith

/-- The two tests say the same thing: gains shrink (an item adds at least as much to `S` as to
any bigger `T ⊇ S` that does not contain it) exactly when every two sets together are worth at
least their union and their overlap together, `f(S) + f(T) ≥ f(S ∪ T) + f(S ∩ T)`. -/
theorem diminishing_returns_iff_union_inter_le {α : Type*} [DecidableEq α]
    (f : Finset α → ℝ) :
    (∀ (S T : Finset α) (j : α), S ⊆ T → j ∉ T →
        f (insert j T) - f T ≤ f (insert j S) - f S) ↔
      ∀ S T : Finset α, f (S ∪ T) + f (S ∩ T) ≤ f S + f T := by
  constructor
  · intro hdr
    have gen : ∀ D : Finset α, ∀ A B : Finset α, A ⊆ B → Disjoint D B →
        f (B ∪ D) - f B ≤ f (A ∪ D) - f A := by
      intro D
      induction D using Finset.induction_on with
      | empty => intro A B _ _; simp
      | @insert d D hd ih =>
        intro A B hAB hdis
        rw [Finset.disjoint_insert_left] at hdis
        have h1 := ih A B hAB hdis.2
        have hdB : d ∉ B ∪ D := by simp [hdis.1, hd]
        have h2 := hdr (A ∪ D) (B ∪ D) d (Finset.union_subset_union hAB le_rfl) hdB
        rw [Finset.union_insert, Finset.union_insert]
        linarith
    intro S T
    have := gen (S \ T) (S ∩ T) T Finset.inter_subset_right Finset.sdiff_disjoint
    rw [Finset.union_sdiff_self_eq_union, Finset.union_comm T S,
      Finset.union_comm (S ∩ T), Finset.sdiff_union_inter] at this
    linarith
  · intro hsub S T j hST hjT
    have h := hsub (insert j S) T
    have hu : insert j S ∪ T = insert j T := by
      rw [Finset.insert_union, Finset.union_eq_right.2 hST]
    have hi : insert j S ∩ T = S := by
      rw [Finset.insert_inter_of_notMem hjT, Finset.inter_eq_left.2 hST]
    rw [hu, hi] at h
    linarith

/-- The Lovász extension of `f`, in the card's threshold form: the average over thresholds `t`
from 0 to 1 of `f` at the set of items whose entry is at least `t`. -/
noncomputable def lovaszExtension {α : Type*} [Fintype α] [DecidableEq α]
    (f : Finset α → ℝ) (x : α → ℝ) : ℝ :=
  ∫ t in (0 : ℝ)..1, f (Finset.univ.filter fun j => t ≤ x j)

/-- The greedy gain vector for the order given by the key `κ` (smaller key comes first). -/
noncomputable def lovaszGain {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ) (κ : α → β) (j : α) : ℝ :=
  f (insert j (Finset.univ.filter fun i => κ i < κ j)) - f (Finset.univ.filter fun i => κ i < κ j)

theorem lovaszGain_sum_prefix {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ) (κ : α → β) (hκ : Function.Injective κ) :
    ∀ n : ℕ, ∀ A : Finset α, A.card = n → (∀ j ∈ A, ∀ i, κ i < κ j → i ∈ A) →
      f A = f ∅ + ∑ j ∈ A, lovaszGain f κ j := by
  intro n
  induction n with
  | zero => intro A hA _; simp [Finset.card_eq_zero.1 hA]
  | succ n ih =>
    intro A hA hpre
    have hne : A.Nonempty := Finset.card_pos.1 (by omega)
    obtain ⟨m, hmA, hmax⟩ := Finset.exists_max_image A κ hne
    have hcard : (A.erase m).card = n := by rw [Finset.card_erase_of_mem hmA]; omega
    have hpre' : ∀ j ∈ A.erase m, ∀ i, κ i < κ j → i ∈ A.erase m := by
      intro j hj i hij
      rw [Finset.mem_erase] at hj ⊢
      refine ⟨?_, hpre j hj.2 i hij⟩
      rintro rfl
      exact absurd (hmax j hj.2) (not_le.2 hij)
    have hP : (Finset.univ.filter fun i => κ i < κ m) = A.erase m := by
      ext i
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_erase]
      constructor
      · intro h
        exact ⟨fun hi => by subst hi; exact lt_irrefl _ h, hpre m hmA i h⟩
      · rintro ⟨hne, hi⟩
        exact lt_of_le_of_ne (hmax i hi) (fun h => hne (hκ h))
    have hg : lovaszGain f κ m = f A - f (A.erase m) := by
      unfold lovaszGain; rw [hP, Finset.insert_erase hmA]
    rw [← Finset.add_sum_erase A _ hmA, hg]
    have := ih (A.erase m) hcard hpre'
    linarith

theorem lovaszGain_sum_le {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ) (κ : α → β) (hκ : Function.Injective κ)
    (hdr : ∀ (S T : Finset α) (j : α), S ⊆ T → j ∉ T →
      f (insert j T) - f T ≤ f (insert j S) - f S) :
    ∀ n : ℕ, ∀ A : Finset α, A.card = n → ∑ j ∈ A, lovaszGain f κ j ≤ f A - f ∅ := by
  intro n
  induction n with
  | zero => intro A hA; simp [Finset.card_eq_zero.1 hA]
  | succ n ih =>
    intro A hA
    have hne : A.Nonempty := Finset.card_pos.1 (by omega)
    obtain ⟨m, hmA, hmax⟩ := Finset.exists_max_image A κ hne
    have hcard : (A.erase m).card = n := by rw [Finset.card_erase_of_mem hmA]; omega
    have hsub : A.erase m ⊆ Finset.univ.filter fun i => κ i < κ m := by
      intro i hi
      rw [Finset.mem_erase] at hi
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      exact lt_of_le_of_ne (hmax i hi.2) (fun h => hi.1 (hκ h))
    have hm : m ∉ Finset.univ.filter fun i => κ i < κ m := by simp
    have h1 := hdr _ _ m hsub hm
    rw [Finset.insert_erase hmA] at h1
    have h2 := ih (A.erase m) hcard
    have hgm : lovaszGain f κ m = f (insert m (Finset.univ.filter fun i => κ i < κ m)) -
        f (Finset.univ.filter fun i => κ i < κ m) := rfl
    rw [← Finset.add_sum_erase A _ hmA, hgm]
    linarith

theorem lovasz_level_eq {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ) (κ : α → β) (hκ : Function.Injective κ) (x : α → ℝ)
    (hcomp : ∀ i j, κ i < κ j → x j ≤ x i) (t : ℝ) :
    f (Finset.univ.filter fun j => t ≤ x j) =
      f ∅ + ∑ j, lovaszGain f κ j * (if t ≤ x j then 1 else 0) := by
  rw [lovaszGain_sum_prefix f κ hκ _ _ rfl]
  · simp [Finset.sum_filter, mul_ite]
  · intro j hj i hij
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hj ⊢
    exact hj.trans (hcomp i j hij)

theorem lovasz_step_integrable {α : Type*} [Fintype α] (a : ℝ) (c x : α → ℝ) :
    IntervalIntegrable (fun t : ℝ => a + ∑ j, c j * (if t ≤ x j then 1 else 0))
      MeasureTheory.volume 0 1 := by
  refine intervalIntegrable_const.add ?_
  have := IntervalIntegrable.sum (μ := MeasureTheory.volume) (a := 0) (b := 1)
    (Finset.univ : Finset α)
    (f := fun j (t : ℝ) => c j * (if t ≤ x j then (1 : ℝ) else 0)) (fun j _ => by
      refine IntervalIntegrable.const_mul ?_ _
      refine Antitone.intervalIntegrable ?_
      intro s t hst
      by_cases ht : t ≤ x j
      · simp [ht, hst.trans ht]
      · simp only [ht, ite_false]; split_ifs <;> norm_num)
  convert this using 1
  ext t; simp [Finset.sum_apply]

theorem lovasz_step_integral {α : Type*} [Fintype α] (a : ℝ) (c x : α → ℝ)
    (hx : ∀ j, 0 ≤ x j ∧ x j ≤ 1) :
    ∫ t in (0 : ℝ)..1, (a + ∑ j, c j * (if t ≤ x j then 1 else 0)) = a + ∑ j, c j * x j := by
  have hint : ∀ j, IntervalIntegrable (fun t : ℝ => c j * (if t ≤ x j then (1 : ℝ) else 0))
      MeasureTheory.volume 0 1 := by
    intro j
    refine IntervalIntegrable.const_mul ?_ _
    refine Antitone.intervalIntegrable ?_
    intro s t hst
    by_cases ht : t ≤ x j
    · simp [ht, hst.trans ht]
    · simp only [ht, ite_false]; split_ifs <;> norm_num
  have hsum : IntervalIntegrable (fun t : ℝ => ∑ j, c j * (if t ≤ x j then (1 : ℝ) else 0))
      MeasureTheory.volume 0 1 := by
    have := IntervalIntegrable.sum (Finset.univ : Finset α) (fun j _ => hint j)
    convert this using 1
    ext t; simp [Finset.sum_apply]
  rw [intervalIntegral.integral_add intervalIntegrable_const hsum,
    intervalIntegral.integral_finsetSum (fun j _ => hint j)]
  congr 1
  · simp
  · refine Finset.sum_congr rfl fun j _ => ?_
    rw [intervalIntegral.integral_const_mul]
    congr 1
    have : (fun t : ℝ => if t ≤ x j then (1 : ℝ) else 0) =
        Set.indicator {t | t ≤ x j} (fun _ => 1) := by
      ext t; simp [Set.indicator]
    rw [this, intervalIntegral.integral_indicator ⟨(hx j).1, (hx j).2⟩]
    simp

theorem lovasz_exists_key {α : Type*} [Fintype α] (x : α → ℝ) :
    ∃ κ : α → Lex (ℝ × ℕ), Function.Injective κ ∧ ∀ i j, κ i < κ j → x j ≤ x i := by
  classical
  let e := Fintype.equivFin α
  refine ⟨fun j => toLex (-x j, ((e j : Fin _) : ℕ)), ?_, ?_⟩
  · intro i j h
    have h2 := congrArg (fun p => (ofLex p).2) h
    simp only [ofLex_toLex] at h2
    exact e.injective (Fin.ext h2)
  · intro i j h
    have := (Prod.Lex.toLex_lt_toLex'.1 h).1
    simp only at this
    linarith

theorem lovasz_eq_gain {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ) (κ : α → β) (hκ : Function.Injective κ) (x : α → ℝ)
    (hcomp : ∀ i j, κ i < κ j → x j ≤ x i) (hx : ∀ j, 0 ≤ x j ∧ x j ≤ 1) :
    lovaszExtension f x = f ∅ + ∑ j, lovaszGain f κ j * x j := by
  unfold lovaszExtension
  simp_rw [lovasz_level_eq f κ hκ x hcomp]
  exact lovasz_step_integral _ _ _ hx

theorem lovasz_ge_gain {α β : Type*} [Fintype α] [DecidableEq α] [LinearOrder β]
    (f : Finset α → ℝ)
    (hdr : ∀ (S T : Finset α) (j : α), S ⊆ T → j ∉ T →
      f (insert j T) - f T ≤ f (insert j S) - f S)
    (κ : α → β) (hκ : Function.Injective κ) (x : α → ℝ) (hx : ∀ j, 0 ≤ x j ∧ x j ≤ 1) :
    f ∅ + ∑ j, lovaszGain f κ j * x j ≤ lovaszExtension f x := by
  obtain ⟨κ', hκ', hcomp'⟩ := lovasz_exists_key x
  rw [← lovasz_step_integral (f ∅) (lovaszGain f κ) x hx]
  unfold lovaszExtension
  have hF : (fun t : ℝ => f (Finset.univ.filter fun j => t ≤ x j)) =
      fun t => f ∅ + ∑ j, lovaszGain f κ' j * (if t ≤ x j then 1 else 0) := by
    funext t; exact lovasz_level_eq f κ' hκ' x hcomp' t
  have hFint : IntervalIntegrable (fun t : ℝ => f (Finset.univ.filter fun j => t ≤ x j))
      MeasureTheory.volume 0 1 := by
    rw [hF]; exact lovasz_step_integrable _ _ _
  refine intervalIntegral.integral_mono_on zero_le_one (lovasz_step_integrable _ _ _) hFint ?_
  intro t _
  have h := lovaszGain_sum_le f κ hκ hdr _ (Finset.univ.filter fun j => t ≤ x j) rfl
  rw [Finset.sum_filter] at h
  have : ∑ j, lovaszGain f κ j * (if t ≤ x j then 1 else 0) =
      ∑ j, (if t ≤ x j then lovaszGain f κ j else 0) := by
    refine Finset.sum_congr rfl fun j _ => ?_
    split_ifs <;> simp
  rw [this]
  linarith

#print axioms lovaszGain_sum_prefix
#print axioms lovaszGain_sum_le
#print axioms lovasz_level_eq
#print axioms lovasz_step_integrable
#print axioms lovasz_step_integral
#print axioms lovasz_exists_key
#print axioms lovasz_eq_gain
#print axioms lovasz_ge_gain

/-- The Lovász extension is convex on the cube `[0, 1]ⁿ` exactly when `f` is submodular, that is,
when `f(S) + f(T) ≥ f(S ∪ T) + f(S ∩ T)` for all sets `S` and `T`. -/
theorem lovaszExtension_convexOn_iff_submodular {α : Type*} [Fintype α] [DecidableEq α]
    (f : Finset α → ℝ) :
    ConvexOn ℝ (Set.Icc (0 : α → ℝ) 1) (lovaszExtension f) ↔
      ∀ S T : Finset α, f (S ∪ T) + f (S ∩ T) ≤ f S + f T := by
  have cube : ∀ x : α → ℝ, x ∈ Set.Icc (0 : α → ℝ) 1 ↔ ∀ j, 0 ≤ x j ∧ x j ≤ 1 := by
    intro x
    simp only [Set.mem_Icc, Pi.le_def, Pi.zero_apply, Pi.one_apply]
    exact ⟨fun h j => ⟨h.1 j, h.2 j⟩, fun h => ⟨fun j => (h j).1, fun j => (h j).2⟩⟩
  constructor
  · intro hconv S T
    let ind : Finset α → α → ℝ := fun A j => if j ∈ A then 1 else 0
    have ind_cube : ∀ A, ind A ∈ Set.Icc (0 : α → ℝ) 1 := by
      intro A; rw [cube]; intro j; simp only [ind]; split_ifs <;> norm_num
    have hind : ∀ A, lovaszExtension f (ind A) = f A := by
      intro A
      obtain ⟨κ, hκ, hcomp⟩ := lovasz_exists_key (ind A)
      rw [lovasz_eq_gain f κ hκ _ hcomp ((cube _).1 (ind_cube A))]
      have hA : (Finset.univ.filter fun j => (1 : ℝ) ≤ ind A j) = A := by
        ext j; simp only [Finset.mem_filter, Finset.mem_univ, true_and, ind]
        split_ifs with h <;> simp [h]
      rw [← hA, lovasz_level_eq f κ hκ _ hcomp 1, hA]
      congr 1
      refine Finset.sum_congr rfl fun j _ => ?_
      simp only [ind]; by_cases h : j ∈ A <;> simp [h]
    have hmid := hconv.2 (ind_cube S) (ind_cube T) (by norm_num : (0 : ℝ) ≤ 1 / 2)
      (by norm_num : (0 : ℝ) ≤ 1 / 2) (by norm_num)
    rw [hind S, hind T] at hmid
    set m := (1 / 2 : ℝ) • ind S + (1 / 2 : ℝ) • ind T with hm
    have hmj : ∀ j, m j = 1 / 2 * ind S j + 1 / 2 * ind T j := by
      intro j; simp [hm]
    have mcube : ∀ j, 0 ≤ m j ∧ m j ≤ 1 := by
      intro j; rw [hmj]; simp only [ind]; split_ifs <;> norm_num
    obtain ⟨κ, hκ, hcomp⟩ := lovasz_exists_key m
    rw [lovasz_eq_gain f κ hκ _ hcomp mcube] at hmid
    have hU : (Finset.univ.filter fun j => (1 / 2 : ℝ) ≤ m j) = S ∪ T := by
      ext j; simp only [Finset.mem_filter, Finset.mem_univ, true_and, hmj, ind,
        Finset.mem_union]
      by_cases hS : j ∈ S <;> by_cases hT : j ∈ T <;> simp [hS, hT]
    have hI : (Finset.univ.filter fun j => (1 : ℝ) ≤ m j) = S ∩ T := by
      ext j; simp only [Finset.mem_filter, Finset.mem_univ, true_and, hmj, ind,
        Finset.mem_inter]
      by_cases hS : j ∈ S <;> by_cases hT : j ∈ T <;> simp [hS, hT] <;> norm_num
    have e1 := lovasz_level_eq f κ hκ m hcomp (1 / 2)
    have e2 := lovasz_level_eq f κ hκ m hcomp 1
    rw [hU] at e1
    rw [hI] at e2
    have hsum : ∑ j, lovaszGain f κ j * m j =
        (1 / 2) * ∑ j, lovaszGain f κ j * (if (1 / 2 : ℝ) ≤ m j then 1 else 0) +
        (1 / 2) * ∑ j, lovaszGain f κ j * (if (1 : ℝ) ≤ m j then 1 else 0) := by
      rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [hmj]; simp only [ind]
      by_cases hS : j ∈ S <;> by_cases hT : j ∈ T <;> simp [hS, hT] <;> norm_num <;> ring
    rw [hsum] at hmid
    simp only [smul_eq_mul] at hmid
    linarith
  · intro hsub
    have hdr := (diminishing_returns_iff_union_inter_le f).2 hsub
    refine ⟨convex_Icc 0 1, ?_⟩
    intro x hx y hy a b ha hb hab
    have hw := (convex_Icc (0 : α → ℝ) 1) hx hy ha hb hab
    obtain ⟨κ, hκ, hcomp⟩ := lovasz_exists_key (a • x + b • y)
    rw [lovasz_eq_gain f κ hκ _ hcomp ((cube _).1 hw)]
    have h1 := lovasz_ge_gain f hdr κ hκ x ((cube _).1 hx)
    have h2 := lovasz_ge_gain f hdr κ hκ y ((cube _).1 hy)
    have hsplit : f ∅ + ∑ j, lovaszGain f κ j * (a • x + b • y) j =
        a * (f ∅ + ∑ j, lovaszGain f κ j * x j) + b * (f ∅ + ∑ j, lovaszGain f κ j * y j) := by
      rw [mul_add, mul_add, Finset.mul_sum, Finset.mul_sum]
      have hs : ∑ j, lovaszGain f κ j * (a • x + b • y) j =
          ∑ j, a * (lovaszGain f κ j * x j) + ∑ j, b * (lovaszGain f κ j * y j) := by
        rw [← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun j _ => ?_
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]; ring
      rw [hs]; linear_combination (-(f ∅)) * hab
    rw [hsplit, smul_eq_mul, smul_eq_mul]
    have := mul_le_mul_of_nonneg_left h1 ha
    have := mul_le_mul_of_nonneg_left h2 hb
    linarith

/-! The festival, exactly. Acts A, B, C are `0, 1, 2` in `Fin 3`. -/

/-- The fan groups each act reaches: A {1, 2, 3, 4}, B {1, 2, 5}, C {3, 4, 6}. -/
def festivalActs : Fin 3 → Finset ℕ := ![{1, 2, 3, 4}, {1, 2, 5}, {3, 4, 6}]

/-- The number of fan groups a lineup reaches, each group counted once. -/
def festivalCoverage (S : Finset (Fin 3)) : ℕ := (S.biUnion festivalActs).card

/-- The stage cost in £ thousand: A moving saves 3, B saves 1, C costs 3, and each fan group
shared by two acts on different stages costs 1 (A and B share 2, A and C share 2). -/
def stageCost (S : Finset (Fin 3)) : ℤ :=
  (if 0 ∈ S then -3 else 0) + (if 1 ∈ S then -1 else 0) + (if 2 ∈ S then 3 else 0)
    + (if (0 ∈ S ↔ 1 ∈ S) then 0 else 2) + (if (0 ∈ S ↔ 2 ∈ S) then 0 else 2)

-- Coverage of every lineup: none 0, A 4, B 3, AB 5, C 3, AC 5, BC 6, ABC 6.
example : festivalCoverage ∅ = 0 ∧ festivalCoverage {0} = 4 ∧ festivalCoverage {1} = 3 ∧
    festivalCoverage {0, 1} = 5 ∧ festivalCoverage {2} = 3 ∧ festivalCoverage {0, 2} = 5 ∧
    festivalCoverage {1, 2} = 6 ∧ festivalCoverage {0, 1, 2} = 6 := by decide

-- Coverage passes the overlap test on all 64 pairs of lineups.
example : ∀ S T : Finset (Fin 3),
    festivalCoverage (S ∪ T) + festivalCoverage (S ∩ T) ≤ festivalCoverage S + festivalCoverage T := by
  decide

-- Greedy: first gains A 4, B 3, C 3, so it takes A; then B and C each add 1, so it ends at 5.
-- The best of all 3 pairs is B and C at 6; the run bounds are 0 + 4 + 3 = 7 and 4 + 1 + 1 = 6.
example : festivalCoverage {0, 1} - festivalCoverage {0} = 1 ∧
    festivalCoverage {0, 2} - festivalCoverage {0} = 1 ∧
    (∀ S : Finset (Fin 3), S.card = 2 → festivalCoverage S ≤ 6) ∧
    0 + 4 + 3 = 7 ∧ 4 + 1 + 1 = 6 := by decide

-- The step inequality OPT ≤ f(S) + k × gain: 6 ≤ 0 + 2 × 4 and 6 ≤ 4 + 2 × 1.
example : 6 ≤ 0 + 2 * 4 ∧ 6 ≤ 4 + 2 * 1 := by norm_num

-- The ratio 5/6 is above the promise 1 - (1 - 1/2)² = 3/4 for k = 2.
example : (1 : ℚ) - (1 - 1 / 2) ^ 2 = 3 / 4 ∧ (3 : ℚ) / 4 ≤ 5 / 6 := by norm_num

-- The overlap test on S = {A, B}, T = {B, C}: 5 + 6 ≥ 6 + 3.
example : festivalCoverage ({0, 1} ∪ {1, 2}) + festivalCoverage ({0, 1} ∩ {1, 2}) = 6 + 3 ∧
    6 + 3 ≤ 5 + 6 := by decide

-- The tight case: G {1, 3}, H {2} reach 3 groups; P {1, 2}, Q {3, 4} reach 4; ratio 3/4.
example : (({1, 3} : Finset ℕ) ∪ {2}).card = 3 ∧ (({1, 2} : Finset ℕ) ∪ {3, 4}).card = 4 := by
  decide

-- The reunion bonus: greedy's 5 against a best of 6 + 4 = 10 is 1/2, below 3/4.
example : (5 : ℚ) / 10 = 1 / 2 ∧ (1 : ℚ) / 2 < 3 / 4 := by norm_num

-- The stage cost of every move: none 0, A 1, B 1, AB -2, C 5, AC 2, BC 6, ABC -1.
example : stageCost ∅ = 0 ∧ stageCost {0} = 1 ∧ stageCost {1} = 1 ∧ stageCost {0, 1} = -2 ∧
    stageCost {2} = 5 ∧ stageCost {0, 2} = 2 ∧ stageCost {1, 2} = 6 ∧
    stageCost {0, 1, 2} = -1 := by decide

-- The stage cost passes the overlap test on all 64 pairs, and moving A and B is the cheapest.
example : (∀ S T : Finset (Fin 3), stageCost (S ∪ T) + stageCost (S ∩ T) ≤ stageCost S + stageCost T) ∧
    ∀ S : Finset (Fin 3), stageCost {0, 1} ≤ stageCost S := by decide

-- The Lovász extension at (A, B, C) = (1/5, 9/10, 1/2): the sorted sum and the threshold average
-- both give 2.
example : (9 : ℚ) / 10 * 1 + 1 / 2 * 5 + 1 / 5 * (-7) = 2 ∧
    (1 : ℚ) / 5 * (-1) + 3 / 10 * 6 + 2 / 5 * 1 = 2 := by norm_num

-- The certificate: the greedy vectors for the orders A, B, C and B, A, C are (1, -3, 1) and
-- (-3, 1, 1); their average y = (-1, -1, 1) has y(S) ≤ f(S) for all 8 sets, and its negative
-- prices add to -2, the least stage cost.
example : stageCost {0} = 1 ∧ stageCost {0, 1} - stageCost {0} = -3 ∧
    stageCost {0, 1, 2} - stageCost {0, 1} = 1 ∧
    stageCost {1} = 1 ∧ stageCost {0, 1} - stageCost {1} = -3 ∧
    ((1 : ℤ) + -3) / 2 = -1 ∧ ((-3 : ℤ) + 1) / 2 = -1 ∧ ((1 : ℤ) + 1) / 2 = 1 ∧
    (∀ S : Finset (Fin 3),
      (if 0 ∈ S then -1 else 0) + (if 1 ∈ S then -1 else 0) + (if 2 ∈ S then 1 else 0)
        ≤ stageCost S) ∧
    (-1 : ℤ) + -1 = -2 := by decide

#print axioms greedy_reaches_one_minus_inv_e_of_best
#print axioms diminishing_returns_iff_union_inter_le
#print axioms lovaszExtension_convexOn_iff_submodular
