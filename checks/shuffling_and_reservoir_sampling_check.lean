-- Fair choices from a list you cannot hold: with exactly uniform independent draws, the Fisher-Yates shuffle gives every order of n items chance 1/n!, and the k-slot reservoir keeps every set of k items with chance 1/(n choose k) and each single item with chance k/n.
import Mathlib.Probability.Distributions.Uniform
import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Factorial.BigOperators

open scoped Nat
open MeasureTheory

/-- The Fisher-Yates shuffle of the positions `0, …, n-1`. The draws `d` give, for each
position `i`, a whole number `d i` from `0` to `i`. Walking from position `n - 1` down to
`0`, swap the items at positions `i` and `d i`. The result `σ` says which item ends at each
position: `σ p` is the item at position `p`. (Position `0` has only one choice, so its swap
does nothing, as on the card.) -/
def fisherYates (n : ℕ) (d : (i : Fin n) → Fin (i.val + 1)) : Equiv.Perm (Fin n) :=
  (List.finRange n).reverse.foldl
    (fun σ i => σ * Equiv.swap i ⟨(d i).val, by have := (d i).isLt; have := i.isLt; omega⟩) 1

/-- The reservoir with `k` slots over a stream of items `0, 1, …, n-1`. Slot `i` starts
holding item `i` (the first `k` items fill the slots). Item `k + t` then gets a draw
`d t` from `0` to `k + t` (that is, from 0 to one less than its 1-based number): if the
draw is a slot number below `k`, the item replaces that slot's occupant; otherwise it is
dropped. The result says which item each slot holds at the end. -/
def reservoir (n k : ℕ) (d : (t : Fin (n - k)) → Fin (k + t.val + 1)) : Fin k → ℕ :=
  (List.finRange (n - k)).foldl
    (fun r t => if h : (d t).val < k then Function.update r ⟨(d t).val, h⟩ (k + t.val) else r)
    (fun i => i.val)

/-- The set of items the reservoir holds at the end. -/
def reservoirSet (n k : ℕ) (d : (t : Fin (n - k)) → Fin (k + t.val + 1)) : Finset ℕ :=
  Finset.univ.image (reservoir n k d)

theorem fy_foldl_mul {α G : Type*} [Monoid G] (g : α → G) (l : List α) (a : G) :
    l.foldl (fun σ i => σ * g i) a = a * (l.map g).prod := by
  induction l generalizing a with
  | nil => simp
  | cons b l ih => simp [ih, mul_assoc]

/-- One swap of the shuffle. -/
def fySwap (n : ℕ) (d : (i : Fin n) → Fin (i.val + 1)) (i : Fin n) : Equiv.Perm (Fin n) :=
  Equiv.swap i ⟨(d i).val, by have := (d i).isLt; have := i.isLt; omega⟩

theorem fisherYates_eq_prod (n : ℕ) (d : (i : Fin n) → Fin (i.val + 1)) :
    fisherYates n d = ((List.finRange n).reverse.map (fySwap n d)).prod := by
  unfold fisherYates
  exact (fy_foldl_mul (fySwap n d) _ 1).trans (one_mul _)

theorem fy_prod_fix (n : ℕ) (d : (i : Fin n) → Fin (i.val + 1)) (p : Fin n) :
    ∀ l : List (Fin n), (∀ i ∈ l, i < p) → (l.map (fySwap n d)).prod p = p := by
  intro l
  induction l with
  | nil => simp
  | cons a l ih =>
    intro h
    simp only [List.map_cons, List.prod_cons, Equiv.Perm.mul_apply]
    rw [ih (fun i hi => h i (List.mem_cons_of_mem _ hi))]
    have ha := h a (List.mem_cons_self ..)
    have := (d a).isLt
    unfold fySwap
    apply Equiv.swap_apply_of_ne_of_ne
    · exact ne_of_gt ha
    · intro hp; rw [Fin.lt_def] at ha; rw [hp] at ha; simp at ha; omega

theorem fy_prod_inj (n : ℕ) (d d' : (i : Fin n) → Fin (i.val + 1)) :
    ∀ l : List (Fin n), l.Pairwise (· > ·) →
      (l.map (fySwap n d)).prod = (l.map (fySwap n d')).prod → ∀ i ∈ l, d i = d' i := by
  intro l
  induction l with
  | nil => simp
  | cons a l ih =>
    intro hl heq
    rw [List.pairwise_cons] at hl
    simp only [List.map_cons, List.prod_cons] at heq
    have hfix : ∀ e : (i : Fin n) → Fin (i.val + 1), (l.map (fySwap n e)).prod a = a :=
      fun e => fy_prod_fix n e a l (fun i hi => hl.1 i hi)
    have hval := congrArg (fun σ : Equiv.Perm (Fin n) => σ a) heq
    simp only [Equiv.Perm.mul_apply, hfix] at hval
    unfold fySwap at hval
    rw [Equiv.swap_apply_left, Equiv.swap_apply_left] at hval
    have hda : d a = d' a := Fin.ext (by simpa using congrArg Fin.val hval)
    have hs : fySwap n d a = fySwap n d' a := by simp only [fySwap, hda]
    rw [hs] at heq
    have := ih hl.2 (mul_left_cancel heq)
    intro i hi
    rcases List.mem_cons.1 hi with rfl | hi
    · exact hda
    · exact this i hi

theorem fisherYates_injective (n : ℕ) : Function.Injective (fisherYates n) := by
  intro d d' h
  rw [fisherYates_eq_prod, fisherYates_eq_prod] at h
  funext i
  refine fy_prod_inj n d d' _ ?_ h i (by simp)
  rw [List.pairwise_reverse]
  exact List.pairwise_lt_finRange n

theorem fy_card (n : ℕ) : Fintype.card ((i : Fin n) → Fin (i.val + 1)) = n ! := by
  rw [Fintype.card_pi]
  simp only [Fintype.card_fin]
  rw [Fin.prod_univ_eq_prod_range (fun i => i + 1) n, Finset.prod_range_add_one_eq_factorial]

theorem fisherYates_bijective (n : ℕ) : Function.Bijective (fisherYates n) := by
  rw [Fintype.bijective_iff_injective_and_card]
  refine ⟨fisherYates_injective n, ?_⟩
  rw [fy_card, Fintype.card_perm, Fintype.card_fin]

/-- Draw sequences for `m` stream steps after `k` slots. -/
abbrev ResDraws (k m : ℕ) := (t : Fin m) → Fin (k + t.val + 1)

/-- The reservoir after `m` steps. -/
def resM (k m : ℕ) (d : ResDraws k m) : Fin k → ℕ :=
  (List.finRange m).foldl
    (fun r t => if h : (d t).val < k then Function.update r ⟨(d t).val, h⟩ (k + t.val) else r)
    (fun i => i.val)

/-- One reservoir step for item `k + m` with draw `x`. -/
def resStep (k m : ℕ) (r : Fin k → ℕ) (x : Fin (k + m + 1)) : Fin k → ℕ :=
  if h : x.val < k then Function.update r ⟨x.val, h⟩ (k + m) else r

theorem resM_zero (k : ℕ) (d : ResDraws k 0) : resM k 0 d = fun i => i.val := by
  simp [resM]

theorem resM_snoc (k m : ℕ) (d : ResDraws k m) (x : Fin (k + m + 1)) :
    resM k (m + 1) (Fin.snoc (α := fun t : Fin (m + 1) => Fin (k + t.val + 1)) d x)
      = resStep k m (resM k m d) x := by
  unfold resM resStep
  rw [List.finRange_succ_last, List.foldl_append, List.foldl_map]
  simp

theorem resM_spec (k m : ℕ) (d : ResDraws k m) :
    Function.Injective (resM k m d) ∧ ∀ i, resM k m d i < k + m := by
  induction m with
  | zero =>
    rw [resM_zero]
    exact ⟨Fin.val_injective, fun i => by simp⟩
  | succ m ih =>
    have hd : d = Fin.snoc (α := fun t : Fin (m + 1) => Fin (k + t.val + 1))
        (Fin.init d) (d (Fin.last m)) := (Fin.snoc_init_self d).symm
    rw [hd, resM_snoc]
    obtain ⟨hinj, hlt⟩ := ih (Fin.init d)
    unfold resStep
    split_ifs with h
    · refine ⟨?_, ?_⟩
      · intro i j hij
        by_cases hi : i = ⟨_, h⟩ <;> by_cases hj : j = ⟨_, h⟩
        · rw [hi, hj]
        · rw [hi, Function.update_self, Function.update_of_ne hj] at hij
          have := hlt j; omega
        · rw [hj, Function.update_self, Function.update_of_ne hi] at hij
          have := hlt i; omega
        · rw [Function.update_of_ne hi, Function.update_of_ne hj] at hij
          exact hinj hij
      · intro i
        by_cases hi : i = ⟨_, h⟩
        · rw [hi, Function.update_self]; omega
        · rw [Function.update_of_ne hi]; have := hlt i; omega
    · exact ⟨hinj, fun i => by have := hlt i; omega⟩

theorem resM_mem (k m : ℕ) (d : ResDraws k m) :
    Finset.univ.image (resM k m d) ∈ (Finset.range (k + m)).powersetCard k := by
  obtain ⟨hinj, hlt⟩ := resM_spec k m d
  rw [Finset.mem_powersetCard]
  refine ⟨?_, ?_⟩
  · intro y hy
    simp only [Finset.mem_image, Finset.mem_univ, true_and] at hy
    obtain ⟨i, rfl⟩ := hy
    simpa using hlt i
  · rw [Finset.card_image_of_injective _ hinj, Finset.card_univ, Fintype.card_fin]

theorem sum_resDraws_succ (k m : ℕ) (f : ResDraws k (m + 1) → ℕ) :
    ∑ d, f d = ∑ x : Fin (k + m + 1), ∑ d : ResDraws k m,
      f (Fin.snoc (α := fun t : Fin (m + 1) => Fin (k + t.val + 1)) d x) := by
  rw [← (Fin.snocEquiv (fun t : Fin (m + 1) => Fin (k + t.val + 1))).sum_comp,
    Fintype.sum_prod_type]
  rfl

theorem image_update_of_injective (k : ℕ) (r : Fin k → ℕ) (hinj : Function.Injective r)
    (j : Fin k) (v : ℕ) :
    Finset.univ.image (Function.update r j v) = insert v ((Finset.univ.image r).erase (r j)) := by
  ext y
  simp only [Finset.mem_image, Finset.mem_univ, true_and, Finset.mem_insert, Finset.mem_erase]
  constructor
  · rintro ⟨i, rfl⟩
    by_cases hi : i = j
    · subst hi; left; simp
    · right; rw [Function.update_of_ne hi]
      exact ⟨fun h => hi (hinj h), i, rfl⟩
  · rintro (rfl | ⟨hne, i, rfl⟩)
    · exact ⟨j, by simp⟩
    · refine ⟨i, ?_⟩
      have hi : i ≠ j := fun h => hne (h ▸ rfl)
      rw [Function.update_of_ne hi]

theorem sum_resStep (k m : ℕ) (r : Fin k → ℕ) (hinj : Function.Injective r) (S : Finset ℕ) :
    ∑ x : Fin (k + m + 1), (if Finset.univ.image (resStep k m r x) = S then 1 else 0)
      = (m + 1) * (if Finset.univ.image r = S then 1 else 0)
        + ∑ i : Fin k,
          (if insert (k + m) ((Finset.univ.image r).erase (r i)) = S then 1 else 0) := by
  refine (Fin.sum_univ_add (a := k) (b := m + 1)
    (fun x => (if Finset.univ.image (resStep k m r x) = S then 1 else 0 : ℕ))).trans ?_
  rw [add_comm]
  congr 1
  · have : ∀ i : Fin (m + 1), resStep k m r (Fin.natAdd k i) = r := by
      intro i; unfold resStep; simp
    simp only [this, Finset.sum_const, Finset.card_univ, Fintype.card_fin, smul_eq_mul]
  · refine Finset.sum_congr rfl fun i _ => ?_
    have : resStep k m r (Fin.castAdd (m + 1) i) = Function.update r i (k + m) := by
      unfold resStep; simp
    rw [this, image_update_of_injective k r hinj]

theorem res_count (k m : ℕ) (S : Finset ℕ)
    (hS : S ∈ (Finset.range (k + m)).powersetCard k) :
    (∑ d : ResDraws k m, if Finset.univ.image (resM k m d) = S then 1 else 0) = m ! := by
  induction m generalizing S with
  | zero =>
    rw [Fintype.sum_unique, resM_zero]
    rw [Finset.mem_powersetCard] at hS
    have : Finset.univ.image (fun i : Fin k => i.val) = S := by
      have himg : Finset.univ.image (fun i : Fin k => i.val) = Finset.range k := by
        ext y; simp only [Finset.mem_image, Finset.mem_univ, true_and, Finset.mem_range]
        exact ⟨fun ⟨a, h⟩ => h ▸ a.isLt, fun h => ⟨⟨y, h⟩, rfl⟩⟩
      rw [himg]
      exact (Finset.eq_of_subset_of_card_le hS.1 (by simp [hS.2])).symm
    simp [this]
  | succ m ih =>
    rw [sum_resDraws_succ]
    simp only [resM_snoc]
    rw [Finset.sum_comm]
    rw [Finset.sum_congr rfl (fun d _ => sum_resStep k m (resM k m d) (resM_spec k m d).1 S)]
    rw [Finset.sum_add_distrib, ← Finset.mul_sum]
    rw [Finset.mem_powersetCard] at hS
    by_cases hkm : k + m ∈ S
    · have h1 : ∀ d : ResDraws k m, Finset.univ.image (resM k m d) ≠ S := by
        intro d h
        have := (Finset.mem_powersetCard.1 (resM_mem k m d)).1 (h ▸ hkm)
        simp at this
      simp only [h1, ite_false, Finset.sum_const_zero, mul_zero, zero_add]
      have h2 : ∀ d : ResDraws k m,
          (∑ i : Fin k, if insert (k + m) ((Finset.univ.image (resM k m d)).erase
              (resM k m d i)) = S then 1 else 0)
          = ∑ y ∈ Finset.range (k + m + 1) \ S,
              if Finset.univ.image (resM k m d) = insert y (S.erase (k + m)) then 1 else 0 := by
        intro d
        obtain ⟨hinj, hlt⟩ := resM_spec k m d
        have hTlt : ∀ z ∈ Finset.univ.image (resM k m d), z < k + m := by
          intro z hz; simp only [Finset.mem_image, Finset.mem_univ, true_and] at hz
          obtain ⟨i, rfl⟩ := hz; exact hlt i
        generalize hT : Finset.univ.image (resM k m d) = T at hTlt ⊢
        rw [← Finset.sum_image (f := fun y => if insert (k + m) (T.erase y) = S then 1 else 0)
          (fun i _ j _ h => hinj h), hT]
        rw [Finset.sum_boole, Finset.sum_boole]
        congr 2
        ext y
        simp only [Finset.mem_filter, Finset.mem_sdiff, Finset.mem_range]
        constructor
        · rintro ⟨hy, hP⟩
          have hyl := hTlt y hy
          have hyS : y ∉ S := by
            intro hyS; rw [← hP] at hyS
            simp at hyS
            omega
          refine ⟨⟨by omega, hyS⟩, ?_⟩
          have hnot : k + m ∉ T.erase y := fun h => by
            have := hTlt _ (Finset.mem_of_mem_erase h); omega
          rw [← hP, Finset.erase_insert hnot, Finset.insert_erase hy]
        · rintro ⟨⟨hy, hyS⟩, hTe⟩
          refine ⟨by rw [hTe]; exact Finset.mem_insert_self _ _, ?_⟩
          rw [hTe, Finset.erase_insert (fun h => hyS (Finset.mem_of_mem_erase h)),
            Finset.insert_erase hkm]
      rw [Finset.sum_congr rfl (fun d _ => h2 d), Finset.sum_comm]
      have h3 : ∀ y ∈ Finset.range (k + m + 1) \ S,
          (∑ d : ResDraws k m, if Finset.univ.image (resM k m d) = insert y (S.erase (k + m))
            then 1 else 0) = m ! := by
        intro y hy
        rw [Finset.mem_sdiff, Finset.mem_range] at hy
        apply ih
        rw [Finset.mem_powersetCard]
        have hk : 0 < k := by rw [← hS.2]; exact Finset.card_pos.2 ⟨_, hkm⟩
        refine ⟨?_, ?_⟩
        · intro z hz
          rw [Finset.mem_insert, Finset.mem_erase] at hz
          rw [Finset.mem_range]
          rcases hz with rfl | ⟨hne, hz⟩
          · have : z ≠ k + m := fun h => hy.2 (h ▸ hkm)
            omega
          · have := Finset.mem_range.1 (hS.1 hz); omega
        · rw [Finset.card_insert_of_notMem (fun h => hy.2 (Finset.mem_of_mem_erase h)),
            Finset.card_erase_of_mem hkm, hS.2]
          omega
      rw [Finset.sum_congr rfl h3, Finset.sum_const, smul_eq_mul,
        Finset.card_sdiff_of_subset (show S ⊆ Finset.range (k + m + 1) from hS.1), Finset.card_range, hS.2, Nat.factorial_succ]
      congr 1
      omega
    · have h2 : ∀ d : ResDraws k m, ∀ i : Fin k,
          insert (k + m) ((Finset.univ.image (resM k m d)).erase (resM k m d i)) ≠ S :=
        fun d i h => hkm (h ▸ Finset.mem_insert_self _ _)
      simp only [h2, ite_false, Finset.sum_const_zero, add_zero]
      rw [ih S ?_, Nat.factorial_succ]
      rw [Finset.mem_powersetCard]
      refine ⟨fun z hz => ?_, hS.2⟩
      have := Finset.mem_range.1 (hS.1 hz)
      have : z ≠ k + m := fun h => hkm (h ▸ hz)
      rw [Finset.mem_range]; omega

theorem res_count' (k m : ℕ) (S : Finset ℕ) (hS : S ∈ (Finset.range (k + m)).powersetCard k)
    (p : ResDraws k m → Prop) (inst : DecidablePred p)
    (hp : ∀ d, p d ↔ Finset.univ.image (resM k m d) = S) :
    (@Finset.filter _ p inst Finset.univ).card = m ! := by
  rw [Finset.card_filter, ← res_count k m S hS]
  refine Finset.sum_congr rfl fun d _ => ?_
  by_cases h : Finset.univ.image (resM k m d) = S <;> simp [hp, h]

theorem res_total (k m : ℕ) :
    Fintype.card (ResDraws k m) = (k + m).choose k * m ! := by
  classical
  rw [← Finset.card_univ,
    Finset.card_eq_sum_card_fiberwise (f := fun d : ResDraws k m => Finset.univ.image (resM k m d))
      (t := (Finset.range (k + m)).powersetCard k) (by intro d _; exact resM_mem k m d)]
  rw [Finset.sum_congr rfl (g := fun _ => m !)
    (fun S hS => res_count' k m S hS _ _ (fun d => Iff.rfl))]
  rw [Finset.sum_const, smul_eq_mul, Finset.card_powersetCard, Finset.card_range]

theorem card_filter_mem_powersetCard (N k a : ℕ) (ha : a < N) :
    (((Finset.range N).powersetCard k).filter (a ∈ ·)).card * N = k * N.choose k := by
  cases k with
  | zero => simp
  | succ k =>
    obtain ⟨N, rfl⟩ : ∃ N', N = N' + 1 := ⟨N - 1, by omega⟩
    have himg : ((Finset.range (N + 1)).powersetCard (k + 1)).filter (a ∈ ·)
        = (((Finset.range (N + 1)).erase a).powersetCard k).image (insert a) := by
      ext S
      simp only [Finset.mem_filter, Finset.mem_powersetCard, Finset.mem_image]
      constructor
      · rintro ⟨⟨hsub, hcard⟩, haS⟩
        refine ⟨S.erase a, ⟨Finset.erase_subset_erase a hsub, ?_⟩, Finset.insert_erase haS⟩
        rw [Finset.card_erase_of_mem haS, hcard]; rfl
      · rintro ⟨A, ⟨hsub, hcard⟩, rfl⟩
        have haA : a ∉ A := fun h => by simpa using hsub h
        refine ⟨⟨?_, by rw [Finset.card_insert_of_notMem haA, hcard]⟩, Finset.mem_insert_self _ _⟩
        intro z hz
        rw [Finset.mem_insert] at hz
        rcases hz with rfl | hz
        · simpa using ha
        · exact Finset.mem_of_mem_erase (hsub hz)
    rw [himg, Finset.card_image_of_injOn, Finset.card_powersetCard,
      Finset.card_erase_of_mem (by simpa using ha), Finset.card_range]
    · have := Nat.add_one_mul_choose_eq N k
      simp only [Nat.add_sub_cancel]
      linarith
    · intro A hA B hB h
      simp only [Finset.mem_coe,
        Finset.mem_powersetCard] at hA hB
      have haA : a ∉ A := fun h => by simpa using hA.1 h
      have haB : a ∉ B := fun h => by simpa using hB.1 h
      rw [← Finset.erase_insert haA, ← Finset.erase_insert haB]
      exact congrArg (fun s => Finset.erase s a) h

theorem res_item_count (k m a : ℕ) (p : ResDraws k m → Prop) (inst : DecidablePred p)
    (hp : ∀ d, p d ↔ a ∈ Finset.univ.image (resM k m d)) :
    (@Finset.filter _ p inst Finset.univ).card
      = (((Finset.range (k + m)).powersetCard k).filter (a ∈ ·)).card * m ! := by
  classical
  rw [Finset.card_eq_sum_card_fiberwise (f := fun d => Finset.univ.image (resM k m d))
    (t := ((Finset.range (k + m)).powersetCard k).filter (a ∈ ·)) ?_]
  · rw [Finset.card_eq_sum_ones (((Finset.range (k + m)).powersetCard k).filter (a ∈ ·)),
      Finset.sum_mul, Finset.sum_congr rfl (fun _ _ => one_mul _)]
    refine Finset.sum_congr rfl fun S hS => ?_
    rw [Finset.mem_filter] at hS
    rw [Finset.filter_filter]
    apply res_count' k m S hS.1 _ _
    intro d
    rw [hp]
    constructor
    · rintro ⟨_, h⟩; exact h
    · intro h; exact ⟨h ▸ hS.2, h⟩
  · intro d hd
    have hd' := (Finset.mem_filter.1 (Finset.mem_coe.1 hd)).2
    exact Finset.mem_coe.2 (Finset.mem_filter.2 ⟨resM_mem k m d, (hp d).1 hd'⟩)

theorem res_set_uniform_aux (k m : ℕ) (S : Finset ℕ)
    (hS : S ∈ (Finset.range (k + m)).powersetCard k) :
    Measure.uniformOfFinset (Finset.univ : Finset (ResDraws k m))
        {d | Finset.univ.image (resM k m d) = S}
      = 1 / ((k + m).choose k : ENNReal) := by
  rw [Measure.uniformOfFinset_apply, res_count' k m S hS
    (fun x => x ∈ {d : ResDraws k m | Finset.univ.image (resM k m d) = S}) _ (fun d => Iff.rfl),
    Finset.card_univ, res_total, Nat.cast_mul]
  have h1 : ((m ! : ℕ) : ENNReal) ≠ 0 := by exact_mod_cast (Nat.factorial_pos m).ne'
  have h2 : ((m ! : ℕ) : ENNReal) ≠ ⊤ := ENNReal.natCast_ne_top _
  rw [← ENNReal.mul_div_mul_right 1 _ h1 h2, one_mul]

theorem res_item_aux (k m a : ℕ) (ha : a < k + m) :
    Measure.uniformOfFinset (Finset.univ : Finset (ResDraws k m))
        {d | a ∈ Finset.univ.image (resM k m d)}
      = (k : ENNReal) / ((k + m : ℕ) : ENNReal) := by
  rw [Measure.uniformOfFinset_apply, res_item_count k m a
    (fun x => x ∈ {d : ResDraws k m | a ∈ Finset.univ.image (resM k m d)}) _ (fun d => Iff.rfl),
    Finset.card_univ, res_total, Nat.cast_mul, Nat.cast_mul]
  have h1 : ((m ! : ℕ) : ENNReal) ≠ 0 := by exact_mod_cast (Nat.factorial_pos m).ne'
  have h2 : ((m ! : ℕ) : ENNReal) ≠ ⊤ := ENNReal.natCast_ne_top _
  rw [ENNReal.mul_div_mul_right _ _ h1 h2]
  have hN0 : ((k + m : ℕ) : ENNReal) ≠ 0 := by exact_mod_cast (show k + m ≠ 0 by omega)
  have hC0 : (((k + m).choose k : ℕ) : ENNReal) ≠ 0 := by
    exact_mod_cast (Nat.choose_pos (by omega)).ne'
  rw [ENNReal.div_eq_div_iff hN0 (ENNReal.natCast_ne_top _) hC0 (ENNReal.natCast_ne_top _)]
  have := card_filter_mem_powersetCard (k + m) k a ha
  rw [← Nat.cast_mul, ← Nat.cast_mul]
  congr 1
  rw [mul_comm, this, mul_comm]

#print axioms fy_foldl_mul
#print axioms fySwap
#print axioms fisherYates_eq_prod
#print axioms fy_prod_fix
#print axioms fy_prod_inj
#print axioms fisherYates_injective
#print axioms fy_card
#print axioms fisherYates_bijective
#print axioms ResDraws
#print axioms resM
#print axioms resStep
#print axioms resM_zero
#print axioms resM_snoc
#print axioms resM_spec
#print axioms resM_mem
#print axioms sum_resDraws_succ
#print axioms image_update_of_injective
#print axioms sum_resStep
#print axioms res_count
#print axioms res_count'
#print axioms res_total
#print axioms card_filter_mem_powersetCard
#print axioms res_item_count
#print axioms res_set_uniform_aux
#print axioms res_item_aux

/-- Fisher-Yates is fair: when every draw is exactly uniform over its stated range and the
draws are independent (so every sequence of draws is equally likely: Mathlib's uniform
distribution on all draw sequences), every one of the
`n!` orders of `n` items comes out with the same chance, `1 / n!`. -/
theorem fisherYates_uniform (n : ℕ) (σ : Equiv.Perm (Fin n)) :
    Measure.uniformOfFinset (Finset.univ : Finset ((i : Fin n) → Fin (i.val + 1)))
        {d | fisherYates n d = σ}
      = 1 / (n ! : ENNReal) := by
  classical
  rw [Measure.uniformOfFinset_apply]
  obtain ⟨d0, hd0⟩ := (fisherYates_bijective n).2 σ
  rw [Finset.card_eq_one.2 ⟨d0, ?_⟩, Finset.card_univ, fy_card]
  · simp
  ext d
  simp only [Finset.mem_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq,
    Finset.mem_singleton]
  constructor
  · intro h; exact fisherYates_injective n (h.trans hd0.symm)
  · rintro rfl; exact hd0

/-- Reservoir sampling is fair for whole sets: with exactly uniform independent draws, every
set of `k` items from a stream of `n` comes out as the kept set with the same chance,
`1 / (n choose k)`. -/
theorem reservoir_set_uniform (n k : ℕ) (S : Finset ℕ)
    (hS : S ∈ (Finset.range n).powersetCard k) :
    Measure.uniformOfFinset (Finset.univ : Finset ((t : Fin (n - k)) → Fin (k + t.val + 1)))
        {d | reservoirSet n k d = S}
      = 1 / (n.choose k : ENNReal) := by
  have hkn : k ≤ n := by
    rw [Finset.mem_powersetCard] at hS
    have := Finset.card_le_card hS.1
    rw [hS.2, Finset.card_range] at this; exact this
  change Measure.uniformOfFinset (Finset.univ : Finset (ResDraws k (n - k)))
      {d | Finset.univ.image (resM k (n - k) d) = S} = 1 / (n.choose k : ENNReal)
  have hn : n = k + (n - k) := by omega
  rw [hn] at hS
  conv_rhs => rw [hn]
  generalize n - k = m at hS ⊢
  exact res_set_uniform_aux k m S hS

/-- Each request is kept with chance `k / n`, whenever it arrived: once the `k` slots are
full (`k ≤ n`), every item `a` of the stream ends in the reservoir with probability `k / n`. -/
theorem reservoir_item_kept (n k : ℕ) (hk : k ≤ n) (a : ℕ) (ha : a < n) :
    Measure.uniformOfFinset (Finset.univ : Finset ((t : Fin (n - k)) → Fin (k + t.val + 1)))
        {d | a ∈ reservoirSet n k d}
      = (k : ENNReal) / n := by
  change Measure.uniformOfFinset (Finset.univ : Finset (ResDraws k (n - k)))
      {d | a ∈ Finset.univ.image (resM k (n - k) d)} = (k : ENNReal) / ((n : ℕ) : ENNReal)
  have hn : n = k + (n - k) := by omega
  rw [hn] at ha
  conv_rhs => rw [hn]
  generalize n - k = m at ha ⊢
  exact res_item_aux k m a ha

/-! Worked numbers from the card, checked exactly. -/

-- 4! = 24 and 10! = 3,628,800 orders.
example : 4 ! = 24 := by decide
example : 10 ! = 3628800 := by decide
-- Fisher-Yates on 4 items has 4 × 3 × 2 × 1 = 24 draw sequences.
example : Fintype.card ((i : Fin 4) → Fin (i.val + 1)) = 24 := by simp [Fintype.card_pi, Fin.prod_univ_four]
-- By hand: items 1234 (here 0123), draws 1, 2, 0 at positions 3, 2, 1 give 4132 (here 3021).
example : List.ofFn (fisherYates 4 (fun i => ⟨[0, 0, 2, 1].getD i.val 0 % (i.val + 1),
    Nat.mod_lt _ (Nat.succ_pos _)⟩)) = [3, 0, 2, 1] := by decide
-- Swap with any of n positions: 3^3 = 27 paths cannot split evenly over 3! = 6 orders.
example : 3 ^ 3 = 27 ∧ 27 % 3 ! ≠ 0 := by decide
-- For ten items, 10^10 paths over 10! orders leave remainder 2,656,000.
example : 10 ^ 10 % 10 ! = 2656000 := by norm_num [Nat.factorial]
-- Sattolo's slip reaches only (n-1)! orders: 9! = 362,880 for ten items.
example : 9 ! = 362880 := by decide
-- Reservoir keeping 2 of 6: 720 inside-out paths, 15 pairs, 48 paths each; each item in 240.
example : Nat.choose 6 2 = 15 ∧ 6 ! = 15 * 48 ∧ 6 ! * 2 / 6 = 240 := by decide
-- Squeezing a 32-bit draw into 0..9,999,999: remainder 4,967,296; 430 ways against 429.
example : 2 ^ 32 % 10000000 = 4967296 ∧ 2 ^ 32 / 10000000 = 429 := by norm_num

#print axioms fisherYates_uniform
#print axioms reservoir_set_uniform
#print axioms reservoir_item_kept
