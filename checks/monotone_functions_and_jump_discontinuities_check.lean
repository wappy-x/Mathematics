-- Monotone functions: a function increasing on [a, b] has a left and a right limit at every inner point, breaks only by jumping, has jumps that add up to at most its total rise, and (increasing or decreasing) breaks at only countably many points.
import Mathlib.Topology.Order.Monotone
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Set Filter Topology

/-- Froda's theorem, as on the card: if f is monotone (increasing or decreasing) on the
interval [a, b], then the points of [a, b] where f breaks (is not continuous on the interval)
are countable: they can be listed one by one. -/
theorem countable_breaks_of_monotone {f : ℝ → ℝ} {a b : ℝ}
    (hf : MonotoneOn f (Icc a b) ∨ AntitoneOn f (Icc a b)) :
    {c ∈ Icc a b | ¬ContinuousWithinAt f (Icc a b) c}.Countable := by
  rcases hf with hf | hf
  · exact hf.countable_not_continuousWithinAt
  · exact hf.countable_not_continuousWithinAt

/-- One-sided limits and the jump: if f is increasing on [a, b] and c lies strictly inside,
then f heads for the left limit f(c⁻) = sup of f on [a, c) from the left and for the right
limit f(c⁺) = inf of f on (c, b] from the right, f(c⁻) ≤ f(c) ≤ f(c⁺), and f breaks at c
exactly when the two limits differ, that is, when it jumps: f(c⁻) < f(c⁺). -/
theorem one_sided_limits_and_every_break_is_a_jump {f : ℝ → ℝ} {a b c : ℝ}
    (hf : MonotoneOn f (Icc a b)) (hc : c ∈ Ioo a b) :
    Tendsto f (𝓝[<] c) (𝓝 (sSup (f '' Ico a c))) ∧
    Tendsto f (𝓝[>] c) (𝓝 (sInf (f '' Ioc c b))) ∧
    sSup (f '' Ico a c) ≤ f c ∧ f c ≤ sInf (f '' Ioc c b) ∧
    (¬ContinuousAt f c ↔ sSup (f '' Ico a c) < sInf (f '' Ioc c b)) := by
  obtain ⟨hac, hcb⟩ := hc
  have hcI : c ∈ Icc a b := ⟨hac.le, hcb.le⟩
  have hbddL : BddAbove (f '' Ioo a c) := ⟨f c, by
    rintro _ ⟨x, hx, rfl⟩; exact hf ⟨hx.1.le, hx.2.le.trans hcb.le⟩ hcI hx.2.le⟩
  have hbddR : BddBelow (f '' Ioo c b) := ⟨f c, by
    rintro _ ⟨x, hx, rfl⟩; exact hf hcI ⟨hac.le.trans hx.1.le, hx.2.le⟩ hx.1.le⟩
  have hneL : (Ioo a c).Nonempty := nonempty_Ioo.2 hac
  have hneR : (Ioo c b).Nonempty := nonempty_Ioo.2 hcb
  have hL : sSup (f '' Ico a c) = sSup (f '' Ioo a c) := by
    rw [← Ioo_insert_left hac, image_insert_eq, csSup_insert hbddL (hneL.image f)]
    apply sup_eq_right.2
    obtain ⟨x, hx⟩ := hneL
    exact (hf ⟨le_rfl, hac.le.trans hcb.le⟩ ⟨hx.1.le, hx.2.le.trans hcb.le⟩ hx.1.le).trans
      (le_csSup hbddL (mem_image_of_mem f hx))
  have hR : sInf (f '' Ioc c b) = sInf (f '' Ioo c b) := by
    rw [← Ioo_insert_right hcb, image_insert_eq, csInf_insert hbddR (hneR.image f)]
    apply inf_eq_right.2
    obtain ⟨x, hx⟩ := hneR
    exact (csInf_le hbddR (mem_image_of_mem f hx)).trans
      (hf ⟨hac.le.trans hx.1.le, hx.2.le⟩ ⟨hac.le.trans hcb.le, le_rfl⟩ hx.2.le)
  have tL : Tendsto f (𝓝[<] c) (𝓝 (sSup (f '' Ico a c))) := by
    rw [hL]
    exact MonotoneOn.tendsto_nhdsWithin_Ioo_left hneL
      (hf.mono fun x hx => ⟨hx.1.le, hx.2.le.trans hcb.le⟩) hbddL
  have tR : Tendsto f (𝓝[>] c) (𝓝 (sInf (f '' Ioc c b))) := by
    rw [hR]
    exact MonotoneOn.tendsto_nhdsWithin_Ioo_right hneR
      (hf.mono fun x hx => ⟨hac.le.trans hx.1.le, hx.2.le⟩) hbddR
  have le1 : sSup (f '' Ico a c) ≤ f c := by
    apply csSup_le ((nonempty_Ico.2 hac).image f)
    rintro _ ⟨x, hx, rfl⟩; exact hf ⟨hx.1, hx.2.le.trans hcb.le⟩ hcI hx.2.le
  have le2 : f c ≤ sInf (f '' Ioc c b) := by
    apply le_csInf ((nonempty_Ioc.2 hcb).image f)
    rintro _ ⟨x, hx, rfl⟩; exact hf hcI ⟨hac.le.trans hx.1.le, hx.2⟩ hx.1.le
  refine ⟨tL, tR, le1, le2, ?_⟩
  constructor
  · intro hnc
    by_contra hlt
    apply hnc
    have e1 : sSup (f '' Ico a c) = f c := le_antisymm le1 (le_trans le2 (not_lt.1 hlt))
    have e2 : sInf (f '' Ioc c b) = f c := le_antisymm (le_trans (not_lt.1 hlt) le1) le2
    rw [continuousAt_iff_continuous_left'_right']
    exact ⟨by rw [ContinuousWithinAt, ← e1]; exact tL,
      by rw [ContinuousWithinAt, ← e2]; exact tR⟩
  · intro hlt hcont
    rw [continuousAt_iff_continuous_left'_right'] at hcont
    have e1 : sSup (f '' Ico a c) = f c := tendsto_nhds_unique tL hcont.1
    have e2 : sInf (f '' Ioc c b) = f c := tendsto_nhds_unique tR hcont.2
    rw [e1, e2] at hlt; exact lt_irrefl _ hlt

/-- The jumps fit inside the rise: let f be increasing on [a, b] and let J(c) be the jump at c,
right limit minus left limit, where at the end a the left side is the value f(a) and at the end b
the right side is the value f(b). For any finitely many points of [a, b], their jumps add up to at
most the total rise f(b) − f(a); so if each of N of them is at least h > 0, then N · h ≤ f(b) − f(a). -/
theorem jumps_sum_le_rise {f : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) (hf : MonotoneOn f (Icc a b))
    (s : Finset ℝ) (hs : ∀ c ∈ s, c ∈ Icc a b) :
    let J : ℝ → ℝ := fun c =>
      sInf (insert (f b) (f '' Ioc c b)) - sSup (insert (f a) (f '' Ico a c))
    (∑ c ∈ s, J c ≤ f b - f a) ∧
    ∀ h : ℝ, 0 < h → (∀ c ∈ s, h ≤ J c) → (s.card : ℝ) * h ≤ f b - f a := by
  intro J
  set L : ℝ → ℝ := fun t => sSup (insert (f a) (f '' Ico a t)) with hL
  set R : ℝ → ℝ := fun x => sInf (insert (f b) (f '' Ioc x b)) with hR
  have hJ : ∀ c, J c = R c - L c := fun c => rfl
  have bddL : ∀ t ∈ Icc a b, BddAbove (insert (f a) (f '' Ico a t)) := by
    intro t ht
    refine ⟨f t, ?_⟩
    rintro _ (rfl | ⟨x, hx, rfl⟩)
    · exact hf ⟨le_rfl, hab⟩ ht ht.1
    · exact hf ⟨hx.1, (hx.2.trans_le ht.2).le⟩ ht hx.2.le
  have bddR : ∀ x ∈ Icc a b, BddBelow (insert (f b) (f '' Ioc x b)) := by
    intro x hx
    refine ⟨f x, ?_⟩
    rintro _ (rfl | ⟨y, hy, rfl⟩)
    · exact hf hx ⟨hab, le_rfl⟩ hx.2
    · exact hf hx ⟨(hx.1.trans_lt hy.1).le, hy.2⟩ hy.1.le
  have aL : ∀ t ∈ Icc a b, f a ≤ L t := fun t ht => le_csSup (bddL t ht) (mem_insert _ _)
  have Rb : ∀ x ∈ Icc a b, R x ≤ f b := fun x hx => csInf_le (bddR x hx) (mem_insert _ _)
  have RL : ∀ x ∈ Icc a b, ∀ t ∈ Icc a b, x < t → R x ≤ L t := by
    intro x hx t ht hxt
    set y := (x + t) / 2
    have hy1 : x < y := by simp only [y]; linarith
    have hy2 : y < t := by simp only [y]; linarith
    calc R x ≤ f y := csInf_le (bddR x hx)
            (mem_insert_of_mem _ ⟨y, ⟨hy1, (hy2.trans_le ht.2).le⟩, rfl⟩)
      _ ≤ L t := le_csSup (bddL t ht)
            (mem_insert_of_mem _ ⟨y, ⟨(hx.1.trans_lt hy1).le, hy2⟩, rfl⟩)
  -- main telescoping bound
  have key : ∀ s : Finset ℝ, (∀ c ∈ s, c ∈ Icc a b) →
      ∀ t ∈ Icc a b, (∀ c ∈ s, c < t) → ∑ c ∈ s, J c ≤ L t - f a := by
    intro s
    induction s using Finset.induction_on_max with
    | empty =>
      intro _ t ht _
      simp only [Finset.sum_empty]
      linarith [aL t ht]
    | insert x s hlt ih =>
      intro hs t ht hxt
      have hxs : x ∉ s := fun hx => lt_irrefl x (hlt x hx)
      rw [Finset.sum_insert hxs]
      have hx : x ∈ Icc a b := hs x (Finset.mem_insert_self _ _)
      have h1 := ih (fun c hc => hs c (Finset.mem_insert_of_mem hc)) x hx hlt
      have h2 := RL x hx t ht (hxt x (Finset.mem_insert_self _ _))
      rw [hJ x]
      linarith
  have sum_le : ∑ c ∈ s, J c ≤ f b - f a := by
    rcases s.eq_empty_or_nonempty with rfl | hne
    · simp only [Finset.sum_empty]
      linarith [hf ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ hab]
    · set m := s.max' hne
      have hm : m ∈ s := s.max'_mem hne
      have hmI := hs m hm
      rw [← Finset.add_sum_erase s J hm]
      have h1 := key (s.erase m) (fun c hc => hs c (Finset.mem_of_mem_erase hc)) m hmI
        (fun c hc => lt_of_le_of_ne (s.le_max' c (Finset.mem_of_mem_erase hc))
          (Finset.ne_of_mem_erase hc))
      rw [hJ m]
      linarith [Rb m hmI]
  refine ⟨sum_le, fun h _ hh => ?_⟩
  have := Finset.card_nsmul_le_sum s J h hh
  rw [nsmul_eq_mul] at this
  linarith

/-! The card's worked numbers, in cents: the fare is 250 + 120 · ⌈x⌉ cents at x km. -/

-- The fare never goes down.
example : Monotone (fun x : ℝ => (250 : ℝ) + 120 * (⌈x⌉ : ℝ)) := by
  intro x y hxy
  have := Int.ceil_mono hxy
  have : ((⌈x⌉ : ℤ) : ℝ) ≤ ((⌈y⌉ : ℤ) : ℝ) := by exact_mod_cast this
  linarith

-- Just before 2 km (from 1 km up to 2 km) the meter reads 490 cents: the left limit at 2 km.
example : ∀ x ∈ Ioc (1 : ℝ) 2, (250 : ℝ) + 120 * (⌈x⌉ : ℝ) = 490 := by
  intro x hx
  have h : ⌈x⌉ = 2 := by
    rw [Int.ceil_eq_iff]; constructor <;> push_cast <;> linarith [hx.1, hx.2]
  rw [h]; norm_num

-- Just after 2 km (up to 3 km) it reads 610 cents: the right limit at 2 km.
example : ∀ x ∈ Ioc (2 : ℝ) 3, (250 : ℝ) + 120 * (⌈x⌉ : ℝ) = 610 := by
  intro x hx
  have h : ⌈x⌉ = 3 := by
    rw [Int.ceil_eq_iff]; constructor <;> push_cast <;> linarith [hx.1, hx.2]
  rw [h]; norm_num

-- The jump at 2 km is 610 − 490 = 120 cents; the rise on [0, 5] is 850 − 250 = 600 cents.
example : (610 : ℕ) - 490 = 120 ∧ (850 : ℕ) - 250 = 600 := by decide

-- Five jumps of 120 fill the rise of 600 exactly; dropping the kerb jump leaves 4 · 120 = 480.
example : 5 * 120 = 600 ∧ 4 * 120 = 480 := by decide

-- The bound on jumps of at least 120 cents is 600 / 120 = 5; of at least 50 cents, 12.
example : 600 / 120 = 5 ∧ 600 / 50 = 12 := by decide

-- The test staircase g jumps 2⁻ⁿ at 1/n. Jumps of at least 1/10: those n with 2ⁿ ≤ 10, which are 3.
example : ((Finset.Icc 1 40).filter (fun n => 2 ^ n ≤ 10)).card = 3 := by decide

-- Jumps of at least 1/1000000: those n with 2ⁿ ≤ 1000000, which are 19.
example : ((Finset.Icc 1 40).filter (fun n => 2 ^ n ≤ 1000000)).card = 19 := by decide

#print axioms countable_breaks_of_monotone
#print axioms one_sided_limits_and_every_break_is_a_jump
#print axioms jumps_sum_le_rise
