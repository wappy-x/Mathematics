-- Sum-product: the sumset of a finite set of numbers has at least |A|^4 / E+(A) members, Solymosi's bound |A·A| |A+A|^2 ≥ |A|^4 / (4⌈log₂|A|⌉) holds for positive reals, and some fixed power 1 + δ makes max(|A+A|, |A·A|) at least c|A|^(1+δ) for whole numbers.
import Mathlib.Combinatorics.Additive.Energy
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Log
import Mathlib.Data.ZMod.Defs
import Mathlib.Tactic.NormNum

/-! Notation: for a finite set `A`, `A + A` and `A * A` are Mathlib's pointwise sumset and
product set (repeats counted once), and `A.card` is `|A|`. Mathlib's `Finset.addEnergy A A`
counts quadruples `(a₁, a₂, b₁, b₂)` from `A` with `a₁ + b₁ = a₂ + b₂`; renaming
`(a, b, c, d) = (a₁, b₁, a₂, b₂)` makes it the card's count of ordered quadruples with
`a + b = c + d`, dull quadruples included. `Finset.mulEnergy A A` is the same with products.
`Nat.clog 2 n` is `⌈log₂ n⌉` for `n ≥ 1`. Division in `ℝ` by zero gives zero, so the bounds
read `0 ≤ …` for the empty set (and Solymosi's for a one-element set), where the card's
fractions are undefined. -/

open scoped Pointwise

/-! Helper lemmas for the proofs below. -/

lemma sp_between (l m a b : ℝ) (ha : 0 < a) (hb : 0 < b) (h : l ≠ m) :
    (l < (l * a + m * b) / (a + b) ∧ (l * a + m * b) / (a + b) < m) ∨
      (m < (l * a + m * b) / (a + b) ∧ (l * a + m * b) / (a + b) < l) := by
  have hab : 0 < a + b := by linarith
  rcases lt_or_gt_of_ne h with h | h
  · left; constructor
    · rw [lt_div_iff₀ hab]; nlinarith
    · rw [div_lt_iff₀ hab]; nlinarith
  · right; constructor
    · rw [lt_div_iff₀ hab]; nlinarith
    · rw [div_lt_iff₀ hab]; nlinarith

#print axioms sp_between

lemma sp_region (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) (T : Finset ℝ) (nb : ℝ → ℝ)
    (hne : ∀ l ∈ T, nb l ≠ l)
    (hdisj : ∀ l ∈ T, ∀ l' ∈ T, ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → l = l') :
    ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
      ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card ≤ (A + A).card ^ 2 := by
  classical
  have hF : (T.sigma (fun l => ((A ×ˢ A).filter (fun p => p.2 = l * p.1)) ×ˢ
    ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)))).card = ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
      ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by
    simp [Finset.card_sigma, Finset.card_product]
  rw [← hF, sq, ← Finset.card_product]
  refine Finset.card_le_card_of_injOn
    (fun x => (x.2.1.1 + x.2.2.1, x.2.1.2 + x.2.2.2)) ?_ ?_
  · intro x hx
    simp only [Finset.mem_coe, Finset.mem_sigma, Finset.mem_product, Finset.mem_filter] at hx
    simp only [Finset.coe_product, Set.mem_prod, Finset.mem_coe]
    exact ⟨Finset.add_mem_add hx.2.1.1.1 hx.2.2.1.1, Finset.add_mem_add hx.2.1.1.2 hx.2.2.1.2⟩
  · rintro ⟨l, ⟨a, a2⟩, ⟨b, b2⟩⟩ hx ⟨l', ⟨a', a2'⟩, ⟨b', b2'⟩⟩ hx' heq
    simp only [Finset.mem_coe, Finset.mem_sigma, Finset.mem_product,
      Finset.mem_filter] at hx hx'
    simp only [Prod.mk.injEq] at heq
    obtain ⟨hl, ⟨⟨ha, ha2⟩, e1⟩, ⟨⟨hb, hb2⟩, e2⟩⟩ := hx
    obtain ⟨hl', ⟨⟨ha', ha2'⟩, e1'⟩, ⟨⟨hb', hb2'⟩, e2'⟩⟩ := hx'
    subst e1 e2 e1' e2'
    have hapos := hA a ha
    have hbpos := hA b hb
    have hapos' := hA a' ha'
    have hbpos' := hA b' hb'
    have B1 := sp_between l (nb l) a b hapos hbpos (hne l hl).symm
    have B2 := sp_between l' (nb l') a' b' hapos' hbpos' (hne l' hl').symm
    have hs : (l * a + nb l * b) / (a + b) = (l' * a' + nb l' * b') / (a' + b') := by
      rw [heq.1, heq.2]
    rw [hs] at B1
    have hll := hdisj l hl l' hl' _ B1 B2
    subst hll
    have hd : (nb l - l) * (b - b') = 0 := by
      have h1 := heq.1
      have h2 := heq.2
      linear_combination h2 - l * h1
    have hlm : nb l - l ≠ 0 := sub_ne_zero.mpr (hne l hl)
    have hbb : b = b' := by
      rcases mul_eq_zero.mp hd with h | h
      · exact absurd h hlm
      · linarith
    have haa : a = a' := by linarith [heq.1]
    subst hbb; subst haa
    rfl

#print axioms sp_region

lemma sp_nb (T : Finset ℝ) :
    ∃ nb : ℝ → ℝ, (∀ l ∈ T, nb l ∈ insert 1 T) ∧
      (∀ l ∈ T, l < 1 → l < nb l ∧ ∀ x ∈ insert 1 T, l < x → nb l ≤ x) ∧
      (∀ l ∈ T, 1 < l → nb l < l ∧ ∀ x ∈ insert 1 T, x < l → x ≤ nb l) := by
  classical
  refine ⟨fun l => if h : l < 1 then ((insert 1 T).filter (l < ·)).min' ⟨1, by simp [h]⟩
    else if h' : 1 < l then ((insert 1 T).filter (· < l)).max' ⟨1, by simp [h']⟩ else 1,
    ?_, ?_, ?_⟩
  · intro l hl
    by_cases h : l < 1
    · simp only [h, dite_eq_left]
      exact (Finset.mem_filter.mp (Finset.min'_mem _ _)).1
    · by_cases h' : 1 < l
      · simp only [h, h', dite_eq_left, dite_eq_right, not_false_eq_true]
        exact (Finset.mem_filter.mp (Finset.max'_mem _ _)).1
      · simp only [h, h', dite_eq_right, not_false_eq_true]; simp
  · intro l hl h
    simp only [h, dite_eq_left]
    refine ⟨(Finset.mem_filter.mp (Finset.min'_mem _ _)).2, fun x hx hlx => ?_⟩
    exact Finset.min'_le _ _ (Finset.mem_filter.mpr ⟨hx, hlx⟩)
  · intro l hl h
    have h' : ¬ l < 1 := by linarith
    simp only [h, h', dite_eq_left, dite_eq_right, not_false_eq_true]
    have hm := Finset.max'_mem ((insert 1 T).filter (· < l)) ⟨1, by simp [h]⟩
    rw [Finset.mem_filter] at hm
    refine ⟨hm.2, fun x hx hlx => ?_⟩
    exact Finset.le_max' _ _ (Finset.mem_filter.mpr ⟨hx, hlx⟩)

#print axioms sp_nb

lemma sp_disj (T : Finset ℝ) (h1 : (1 : ℝ) ∉ T) (nb : ℝ → ℝ)
    (hlo : ∀ l ∈ T, l < 1 → l < nb l ∧ ∀ x ∈ insert 1 T, l < x → nb l ≤ x)
    (hhi : ∀ l ∈ T, 1 < l → nb l < l ∧ ∀ x ∈ insert 1 T, x < l → x ≤ nb l) :
    ∀ l ∈ T, ∀ l' ∈ T, ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → l = l' := by
  have key : ∀ l ∈ T, ∀ l' ∈ T, l < l' → ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → False := by
    intro l hl l' hl' hlt σ hb hb'
    have hl1 : l ≠ 1 := fun h => h1 (h ▸ hl)
    have hl1' : l' ≠ 1 := fun h => h1 (h ▸ hl')
    have mem1 : (1 : ℝ) ∈ insert 1 T := Finset.mem_insert_self _ _
    have memT : ∀ x ∈ T, x ∈ insert 1 T := fun x hx => Finset.mem_insert_of_mem hx
    rcases lt_or_gt_of_ne hl1 with h | h
    · obtain ⟨n1, n2⟩ := hlo l hl h
      have c1 := n2 l' (memT l' hl') hlt
      have c2 := n2 1 mem1 h
      rcases lt_or_gt_of_ne hl1' with h' | h'
      · obtain ⟨m1, _⟩ := hlo l' hl' h'
        rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
      · obtain ⟨m1, m2⟩ := hhi l' hl' h'
        have c3 := m2 1 mem1 h'
        rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
    · have h' : 1 < l' := by linarith
      obtain ⟨n1, _⟩ := hhi l hl h
      obtain ⟨m1, m2⟩ := hhi l' hl' h'
      have c3 := m2 l (memT l hl) hlt
      rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
  intro l hl l' hl' σ hb hb'
  rcases lt_trichotomy l l' with h | h | h
  · exact (key l hl l' hl' h σ hb hb').elim
  · exact h
  · exact (key l' hl' l hl h σ hb' hb).elim

#print axioms sp_disj

lemma sp_r_le_one (A : Finset ℝ) (l : ℝ) :
    ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤
      ((A ×ˢ A).filter (fun p => p.2 = 1 * p.1)).card := by
  refine Finset.card_le_card_of_injOn (fun p => (p.1, p.1)) ?_ ?_
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp ⊢
    exact ⟨⟨hp.1.1, hp.1.1⟩, by ring⟩
  · intro p hp q hq h
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp hq
    simp only [Prod.mk.injEq] at h
    exact Prod.ext h.1 (by rw [hp.2, hq.2, h.1])

#print axioms sp_r_le_one

lemma sp_r_le_card (A : Finset ℝ) (l : ℝ) :
    ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤ A.card := by
  refine Finset.card_le_card_of_injOn (fun p => p.1) ?_ ?_
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp ⊢
    exact hp.1.1
  · intro p hp q hq h
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp hq
    simp only at h
    exact Prod.ext h (by rw [hp.2, hq.2, h])

#print axioms sp_r_le_card

lemma sp_class (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) (T : Finset ℝ) (h1 : (1 : ℝ) ∉ T) (i : ℕ)
    (hT : ∀ l ∈ T, 2 ^ i ≤ ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ∧
      ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card < 2 ^ (i + 1)) :
    ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 ≤ 2 * (A + A).card ^ 2 := by
  obtain ⟨nb, hmem, hlo, hhi⟩ := sp_nb T
  have hne : ∀ l ∈ T, nb l ≠ l := by
    intro l hl
    have : l ≠ 1 := fun h => h1 (h ▸ hl)
    rcases lt_or_gt_of_ne this with h | h
    · exact (hlo l hl h).1.ne'
    · exact (hhi l hl h).1.ne
  have hreg := sp_region A hA T nb hne (sp_disj T h1 nb hlo hhi)
  calc ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2
      ≤ ∑ l ∈ T, 2 * (((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
          ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card) := by
        refine Finset.sum_le_sum (fun l hl => ?_)
        have key : ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤
            2 * ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by
          rcases Finset.mem_insert.mp (hmem l hl) with h | h
          · rw [h]; have := sp_r_le_one A l; omega
          · have h2 := (hT l hl).2
            have h3 := (hT (nb l) h).1
            rw [pow_succ] at h2
            omega
        rw [sq]
        calc _ ≤ ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
              (2 * ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card) :=
                Nat.mul_le_mul_left _ key
          _ = _ := by ring
    _ = 2 * ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
          ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by rw [Finset.mul_sum]
    _ ≤ 2 * (A + A).card ^ 2 := Nat.mul_le_mul_left _ hreg

#print axioms sp_class

lemma sp_energy_le (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    ∃ S : Finset ℝ, (∀ l ∈ S, 0 < ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card) ∧
      A.mulEnergy A ≤ ∑ l ∈ S, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 := by
  classical
  set Q := ((A ×ˢ A) ×ˢ (A ×ˢ A)).filter
    (fun pq : (ℝ × ℝ) × (ℝ × ℝ) => pq.1.2 / pq.1.1 = pq.2.2 / pq.2.1) with hQ
  have hmemQ : ∀ pq ∈ Q, pq.1 ∈ (A ×ˢ A).filter (fun p => p.2 = pq.1.2 / pq.1.1 * p.1) ∧
      pq.2 ∈ (A ×ˢ A).filter (fun p => p.2 = pq.1.2 / pq.1.1 * p.1) := by
    intro pq hpq
    simp only [Q, Finset.mem_filter, Finset.mem_product] at hpq
    obtain ⟨⟨⟨h11, h12⟩, h21, h22⟩, he⟩ := hpq
    have p1 := hA _ h11
    have p2 := hA _ h21
    simp only [Finset.mem_filter, Finset.mem_product]
    refine ⟨⟨⟨h11, h12⟩, by field_simp⟩, ⟨⟨h21, h22⟩, ?_⟩⟩
    rw [he]; field_simp
  refine ⟨Q.image (fun pq => pq.1.2 / pq.1.1), ?_, ?_⟩
  · intro l hl
    obtain ⟨pq, hpq, rfl⟩ := Finset.mem_image.mp hl
    exact Finset.card_pos.mpr ⟨_, (hmemQ pq hpq).1⟩
  · have h1 : A.mulEnergy A ≤ Q.card := by
      unfold Finset.mulEnergy
      refine Finset.card_le_card_of_injOn (fun x => ((x.1.1, x.1.2), (x.2.2, x.2.1))) ?_ ?_
      · intro x hx
        simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hx
        obtain ⟨⟨⟨h11, h12⟩, h21, h22⟩, he⟩ := hx
        simp only [Q, Finset.mem_coe, Finset.mem_filter, Finset.mem_product]
        refine ⟨⟨⟨h11, h12⟩, h22, h21⟩, ?_⟩
        have p1 := hA _ h11
        have p2 := hA _ h22
        rw [div_eq_div_iff p1.ne' p2.ne']
        linarith
      · intro x _ y _ h
        simp only [Prod.mk.injEq] at h
        ext <;> simp [h]
    rw [Finset.card_eq_sum_card_image (fun pq => pq.1.2 / pq.1.1) Q] at h1
    refine h1.trans (Finset.sum_le_sum (fun l _ => ?_))
    rw [sq, ← Finset.card_product]
    refine Finset.card_le_card (fun pq hpq => ?_)
    rw [Finset.mem_filter] at hpq
    have := hmemQ pq hpq.1
    rw [hpq.2] at this
    exact Finset.mem_product.mpr this

#print axioms sp_energy_le

lemma sp_energy_bound (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    A.mulEnergy A ≤ A.card ^ 2 + (Nat.log 2 A.card + 1) * (2 * (A + A).card ^ 2) := by
  classical
  obtain ⟨S, hSpos, hE⟩ := sp_energy_le A hA
  refine hE.trans ?_
  have hsplit : ∑ l ∈ S, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 ≤
      A.card ^ 2 + ∑ l ∈ S.erase 1, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 := by
    by_cases h : (1 : ℝ) ∈ S
    · rw [← Finset.add_sum_erase S _ h]
      have := sp_r_le_card A 1
      gcongr
    · rw [Finset.erase_eq_of_notMem h]; omega
  refine hsplit.trans (Nat.add_le_add_left ?_ _)
  rw [← Finset.sum_fiberwise_of_maps_to (s := S.erase 1) (t := Finset.range (Nat.log 2 A.card + 1))
    (g := fun l => Nat.log 2 ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card)]
  · calc _ ≤ ∑ i ∈ Finset.range (Nat.log 2 A.card + 1), 2 * (A + A).card ^ 2 := by
          refine Finset.sum_le_sum (fun i _ => ?_)
          refine sp_class A hA _ (by simp) i (fun l hl => ?_)
          rw [Finset.mem_filter] at hl
          have hpos := hSpos l (Finset.mem_of_mem_erase hl.1)
          rw [← hl.2]
          exact ⟨Nat.pow_log_le_self 2 hpos.ne', Nat.lt_pow_succ_log_self (by norm_num) _⟩
      _ = _ := by simp
  · intro l _
    rw [Finset.mem_range, Nat.lt_succ_iff]
    exact Nat.log_mono_right (sp_r_le_card A l)

#print axioms sp_energy_bound

lemma es_sq_le_two_pow (k : ℕ) : k ^ 2 ≤ 2 ^ (k + 1) ∧ 2 * k + 1 ≤ 2 ^ (k + 1) := by
  induction k with
  | zero => norm_num
  | succ k ih =>
    have h2 : 2 ≤ 2 ^ (k + 1) := by
      calc 2 = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ (k + 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [pow_succ 2 (k + 1)]
    constructor <;> nlinarith [ih.1, ih.2]

#print axioms es_sq_le_two_pow

lemma es_clog_sq_le (q : ℕ) (hq : 1 ≤ q) : (Nat.clog 2 q) ^ 2 ≤ 4 * q := by
  rcases Nat.eq_or_lt_of_le hq with h | h
  · rw [← h]; simp [Nat.clog_one_right]
  · have h1 := Nat.pow_pred_clog_lt_self (b := 2) (by norm_num) h
    have hpos := Nat.clog_pos (b := 2) (by norm_num) h
    have h2 := (es_sq_le_two_pow (Nat.clog 2 q)).1
    obtain ⟨j, hj⟩ : ∃ j, Nat.clog 2 q = j + 1 := ⟨Nat.clog 2 q - 1, by omega⟩
    rw [hj] at h1 h2 ⊢
    simp only [Nat.pred_succ] at h1
    have e : 2 ^ (j + 1 + 1) = 4 * 2 ^ j := by ring
    rw [e] at h2
    linarith

#print axioms es_clog_sq_le

lemma es_pos_part (Q : Finset ℝ) (M : ℝ)
    (hadd : ((Q + Q).card : ℝ) ≤ M) (hmul : ((Q * Q).card : ℝ) ≤ M)
    (hS : (Q.card : ℝ) ^ 4 / (4 * (Nat.clog 2 Q.card : ℝ)) ≤
      ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2) :
    (Q.card : ℝ) ^ 7 ≤ 64 * M ^ 6 := by
  have hq0 : (0 : ℝ) ≤ Q.card := by positivity
  rcases Nat.eq_zero_or_pos Q.card with h0 | hpos
  · rw [h0]; norm_num; positivity
  have hqM : (Q.card : ℝ) ≤ M := by
    have : Q.card ≤ (Q + Q).card := Finset.card_le_card_add_left (Finset.card_pos.mp hpos)
    have : (Q.card : ℝ) ≤ (Q + Q).card := by exact_mod_cast this
    linarith
  have hM0 : 0 ≤ M := le_trans hq0 hqM
  rcases Nat.eq_zero_or_pos (Nat.clog 2 Q.card) with hL | hL
  · have hq1 : Q.card ≤ 1 := by
      by_contra hc
      have := Nat.clog_pos (b := 2) (by norm_num) (by omega : 1 < Q.card)
      omega
    have hq1' : (Q.card : ℝ) = 1 := by
      have : Q.card = 1 := by omega
      rw [this]; norm_num
    rw [hq1'] at hqM ⊢
    have : (1 : ℝ) ≤ M ^ 6 := one_le_pow₀ hqM
    linarith
  · 
    have hLr : (0 : ℝ) < 4 * (Nat.clog 2 Q.card : ℝ) := by
      have : (1 : ℝ) ≤ Nat.clog 2 Q.card := by exact_mod_cast hL
      linarith
    rw [div_le_iff₀ hLr] at hS
    have hprod : ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2 ≤ M ^ 3 := by
      have h1 : ((Q + Q).card : ℝ) ^ 2 ≤ M ^ 2 := pow_le_pow_left₀ (by positivity) hadd 2
      calc ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2 ≤ M * M ^ 2 :=
            mul_le_mul hmul h1 (by positivity) hM0
        _ = M ^ 3 := by ring
    have hlog : ((Nat.clog 2 Q.card : ℕ) : ℝ) ^ 2 ≤ 4 * Q.card := by
      exact_mod_cast es_clog_sq_le Q.card hpos
    set q : ℝ := (Q.card : ℝ)
    set L : ℝ := (Nat.clog 2 Q.card : ℝ)
    have hL0 : 0 ≤ L := by positivity
    have h4 : q ^ 4 ≤ 4 * L * M ^ 3 := by nlinarith
    have hq4 : 0 ≤ q ^ 4 := by positivity
    have h8 : q ^ 8 ≤ 16 * L ^ 2 * M ^ 6 := by
      have := pow_le_pow_left₀ hq4 h4 2
      calc q ^ 8 = (q ^ 4) ^ 2 := by ring
        _ ≤ (4 * L * M ^ 3) ^ 2 := this
        _ = 16 * L ^ 2 * M ^ 6 := by ring
    have hM6 : 0 ≤ M ^ 6 := by positivity
    have h8' : q ^ 8 ≤ 64 * q * M ^ 6 := by nlinarith
    have hqpos : 0 < q := by simp only [q]; exact_mod_cast hpos
    have : q * q ^ 7 ≤ q * (64 * M ^ 6) := by nlinarith
    exact le_of_mul_le_mul_left this hqpos

#print axioms es_pos_part

/-- **The energy bound.** For any finite set `A` of real numbers (so also of whole or rational
numbers), the number of different pair sums is at least the fourth power of the set's size
divided by the additive energy: `|A + A| ≥ |A|^4 / E₊(A)`. -/
theorem card_add_ge_card_pow_four_div_addEnergy (A : Finset ℝ) :
    (A.card : ℝ) ^ 4 / (A.addEnergy A : ℝ) ≤ ((A + A).card : ℝ) := by
  have h := Finset.le_card_add_mul_addEnergy A A
  have h' : ((A.card : ℝ)) ^ 4 ≤ ((A + A).card : ℝ) * (A.addEnergy A : ℝ) := by
    have : (A.card ^ 2 * A.card ^ 2 : ℕ) = A.card ^ 4 := by ring
    exact_mod_cast this ▸ h
  rcases (Nat.zero_le (A.addEnergy A)).eq_or_lt with h0 | h0
  · rw [← h0]; simp
  · rw [div_le_iff₀ (by exact_mod_cast h0)]; exact h'

/-- **Solymosi's sum-product bound (2009).** For any finite set `A` of positive real numbers,
the product set times the square of the sumset is at least the fourth power of the set's size
over four times the rounded-up base-2 logarithm of that size:
`|A · A| |A + A|^2 ≥ |A|^4 / (4 ⌈log₂ |A|⌉)`. -/
theorem card_mul_mul_card_add_sq_ge (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    (A.card : ℝ) ^ 4 / (4 * (Nat.clog 2 A.card : ℝ)) ≤
      ((A * A).card : ℝ) * ((A + A).card : ℝ) ^ 2 := by
  classical
  have hCS := Finset.le_card_mul_mul_mulEnergy A A
  have hn : A.card ≤ (A + A).card := by
    rcases A.eq_empty_or_nonempty with h | h
    · simp [h]
    · exact Finset.card_le_card_add_left h
  rcases Nat.lt_or_ge A.card 3 with hsmall | hbig
  · obtain hc | hc | hc : A.card = 0 ∨ A.card = 1 ∨ A.card = 2 := by omega
    · rw [hc]; simp; positivity
    · rw [hc]; simp; positivity
    · rw [hc] at hn ⊢
      have hne : A.Nonempty := Finset.card_pos.mp (by omega)
      have hm : 1 ≤ (A * A).card := Finset.card_pos.mpr (hne.mul hne)
      have hc2 : (Nat.clog 2 2 : ℝ) = 1 := by
        have : Nat.clog 2 2 = 1 := by decide
        rw [this]; norm_num
      rw [hc2]
      have hm' : (1 : ℝ) ≤ (A * A).card := by exact_mod_cast hm
      have hn' : (2 : ℝ) ≤ (A + A).card := by exact_mod_cast hn
      push_cast
      nlinarith
  · have hL : 2 ≤ Nat.clog 2 A.card := by
      have := Nat.clog_mono_right 2 hbig
      have h3 : Nat.clog 2 3 = 2 := by decide
      omega
    have hlog := Nat.log_le_clog 2 A.card
    have hE := sp_energy_bound A hA
    have hE' : A.mulEnergy A ≤ 4 * Nat.clog 2 A.card * (A + A).card ^ 2 := by
      have : A.card ^ 2 ≤ (A + A).card ^ 2 := Nat.pow_le_pow_left hn 2
      have h5 : (Nat.log 2 A.card + 1) * (2 * (A + A).card ^ 2) ≤
          (Nat.clog 2 A.card + 1) * (2 * (A + A).card ^ 2) := by gcongr
      nlinarith
    have key : A.card ^ 4 ≤ 4 * Nat.clog 2 A.card * ((A * A).card * (A + A).card ^ 2) := by
      calc A.card ^ 4 = A.card ^ 2 * A.card ^ 2 := by ring
        _ ≤ (A * A).card * A.mulEnergy A := hCS
        _ ≤ (A * A).card * (4 * Nat.clog 2 A.card * (A + A).card ^ 2) :=
            Nat.mul_le_mul_left _ hE'
        _ = _ := by ring
    have hLpos : (0 : ℝ) < 4 * (Nat.clog 2 A.card : ℝ) := by
      have : (2 : ℝ) ≤ Nat.clog 2 A.card := by exact_mod_cast hL
      linarith
    rw [div_le_iff₀ hLpos]
    have : ((A.card ^ 4 : ℕ) : ℝ) ≤ ((4 * Nat.clog 2 A.card * ((A * A).card * (A + A).card ^ 2) : ℕ) : ℝ) :=
      by exact_mod_cast key
    push_cast at this
    linarith

/-- **The Erdős–Szemerédi sum-product theorem (1983).** There are fixed numbers `c > 0` and
`δ > 0` such that every finite set `A` of whole numbers has
`max(|A + A|, |A · A|) ≥ c |A|^(1+δ)`: no set can be small for adding and for multiplying
at once. -/
theorem exists_max_card_add_card_mul_ge :
    ∃ c δ : ℝ, 0 < c ∧ 0 < δ ∧ ∀ A : Finset ℤ,
      c * (A.card : ℝ) ^ (1 + δ) ≤ max ((A + A).card : ℝ) ((A * A).card : ℝ) := by
  classical
  refine ⟨1 / 8, 1 / 6, by norm_num, by norm_num, fun A => ?_⟩
  set M : ℝ := max ((A + A).card : ℝ) ((A * A).card : ℝ) with hMdef
  have hM1 : ((A + A).card : ℝ) ≤ M := le_max_left _ _
  have hM2 : ((A * A).card : ℝ) ≤ M := le_max_right _ _
  have hn0 : (0 : ℝ) ≤ A.card := by positivity
  have hnM : (A.card : ℝ) ≤ M := by
    rcases A.eq_empty_or_nonempty with h | h
    · rw [h]; simp only [Finset.card_empty, Nat.cast_zero]; exact le_trans (by positivity) hM1
    · have : A.card ≤ (A + A).card := Finset.card_le_card_add_left h
      have : (A.card : ℝ) ≤ (A + A).card := by exact_mod_cast this
      linarith
  have hM0 : 0 ≤ M := le_trans hn0 hnM
  -- positive and negative parts, moved into the positive reals
  set P : Finset ℝ := (A.filter (fun z => 0 < z)).image (fun z : ℤ => (z : ℝ)) with hP
  set N : Finset ℝ := (A.filter (fun z => z < 0)).image (fun z : ℤ => -(z : ℝ)) with hN
  have hPpos : ∀ a ∈ P, 0 < a := by
    intro a ha
    obtain ⟨z, hz, rfl⟩ := Finset.mem_image.mp ha
    have := (Finset.mem_filter.mp hz).2
    exact_mod_cast this
  have hNpos : ∀ a ∈ N, 0 < a := by
    intro a ha
    obtain ⟨z, hz, rfl⟩ := Finset.mem_image.mp ha
    have := (Finset.mem_filter.mp hz).2
    have : (z : ℝ) < 0 := by exact_mod_cast this
    linarith
  have hPcard : P.card = (A.filter (fun z => 0 < z)).card :=
    Finset.card_image_of_injective _ Int.cast_injective
  have hNcard : N.card = (A.filter (fun z => z < 0)).card :=
    Finset.card_image_of_injective _ (fun x y h => by simpa using h)
  have hsplit : A.card ≤ P.card + N.card + 1 := by
    rw [hPcard, hNcard]
    have h1 := Finset.card_filter_add_card_filter_not (s := A) (fun z : ℤ => 0 < z)
    have h2 : (A.filter (fun z : ℤ => ¬ 0 < z)) ⊆ insert 0 (A.filter (fun z => z < 0)) := by
      intro z hz
      rw [Finset.mem_filter] at hz
      rw [Finset.mem_insert, Finset.mem_filter]
      rcases lt_or_eq_of_le (not_lt.mp hz.2) with h | h
      · exact Or.inr ⟨hz.1, h⟩
      · exact Or.inl h
    have h3 := Finset.card_le_card h2
    have h4 := Finset.card_insert_le (0 : ℤ) (A.filter (fun z => z < 0))
    omega
  -- sums and products of the parts sit inside images of A + A and A * A
  have hPadd : ((P + P).card : ℝ) ≤ M := by
    have : (P + P) ⊆ (A + A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_add.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' + b', Finset.add_mem_add (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((P + P).card : ℝ) ≤ (A + A).card := by exact_mod_cast h
    linarith
  have hPmul : ((P * P).card : ℝ) ≤ M := by
    have : (P * P) ⊆ (A * A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_mul.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' * b', Finset.mul_mem_mul (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((P * P).card : ℝ) ≤ (A * A).card := by exact_mod_cast h
    linarith
  have hNadd : ((N + N).card : ℝ) ≤ M := by
    have : (N + N) ⊆ (A + A).image (fun z : ℤ => -(z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_add.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' + b', Finset.add_mem_add (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((N + N).card : ℝ) ≤ (A + A).card := by exact_mod_cast h
    linarith
  have hNmul : ((N * N).card : ℝ) ≤ M := by
    have : (N * N) ⊆ (A * A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_mul.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' * b', Finset.mul_mem_mul (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((N * N).card : ℝ) ≤ (A * A).card := by exact_mod_cast h
    linarith
  have hPb := es_pos_part P M hPadd hPmul (card_mul_mul_card_add_sq_ge P hPpos)
  have hNb := es_pos_part N M hNadd hNmul (card_mul_mul_card_add_sq_ge N hNpos)
  -- the larger part has at least a third of the elements, or A has at most one element
  have key : (A.card : ℝ) ^ 7 ≤ 8 ^ 6 * M ^ 6 := by
    set m := max P.card N.card with hm
    have hmb : (m : ℝ) ^ 7 ≤ 64 * M ^ 6 := by
      rcases max_choice P.card N.card with h | h
      · rw [hm, h]; exact hPb
      · rw [hm, h]; exact hNb
    have hnm : A.card ≤ 2 * m + 1 := by
      have := le_max_left P.card N.card
      have := le_max_right P.card N.card
      omega
    have hM6 : 0 ≤ M ^ 6 := by positivity
    rcases Nat.eq_zero_or_pos m with h0 | hmpos
    · have hn1 : A.card ≤ 1 := by omega
      have hn1' : (A.card : ℝ) ≤ 1 := by exact_mod_cast hn1
      have h7 : (A.card : ℝ) ^ 7 ≤ (A.card : ℝ) ^ 6 := by
        rw [pow_succ]
        nlinarith [pow_nonneg hn0 6]
      have h6 : (A.card : ℝ) ^ 6 ≤ M ^ 6 := pow_le_pow_left₀ hn0 hnM 6
      nlinarith
    · have h3 : (A.card : ℝ) ≤ 3 * m := by
        have : A.card ≤ 3 * m := by omega
        exact_mod_cast this
      have h7 : (A.card : ℝ) ^ 7 ≤ (3 * (m : ℝ)) ^ 7 := pow_le_pow_left₀ hn0 h3 7
      have : (3 * (m : ℝ)) ^ 7 = 3 ^ 7 * (m : ℝ) ^ 7 := by ring
      nlinarith
  have hpow : ((1 : ℝ) / 8 * (A.card : ℝ) ^ (1 + (1 : ℝ) / 6)) ^ 6 = (A.card : ℝ) ^ 7 / 8 ^ 6 := by
    rw [mul_pow, ← Real.rpow_natCast ((A.card : ℝ) ^ (1 + (1 : ℝ) / 6)) 6,
      ← Real.rpow_mul hn0]
    norm_num
    ring
  refine le_of_pow_le_pow_left₀ (n := 6) (by norm_num) hM0 ?_
  rw [hpow, div_le_iff₀ (by norm_num)]
  linarith

/-! The card's worked counts. -/

/-- The geometric run 1, 2, 4, …, 512 (the powers 2⁰ to 2⁹). -/
def geomRun : Finset ℕ := (Finset.range 10).image (2 ^ ·)

-- 55 sums, 19 products, additive energy 190, multiplicative energy 670.
example : (geomRun + geomRun).card = 55 := by decide +kernel
example : (geomRun * geomRun).card = 19 := by decide +kernel
example : geomRun.addEnergy geomRun = 190 := by decide +kernel
example : geomRun.mulEnergy geomRun = 670 := by decide +kernel

-- The run 1 to 10: 19 sums (2 to 20), 42 products, energies 670 and 278.
example : (Finset.Icc 1 10 + Finset.Icc 1 10 : Finset ℕ).card = 19 := by decide +kernel
example : (Finset.Icc 1 10 * Finset.Icc 1 10 : Finset ℕ).card = 42 := by decide +kernel
example : (Finset.Icc 1 10 : Finset ℕ).addEnergy (Finset.Icc 1 10) = 670 := by decide +kernel
example : (Finset.Icc 1 10 : Finset ℕ).mulEnergy (Finset.Icc 1 10) = 278 := by decide +kernel

-- The mixed set 1, 2, 3, 4, 6, 8: 13 sums, 15 products, energies 114 and 106.
example : (({1, 2, 3, 4, 6, 8} : Finset ℕ) + {1, 2, 3, 4, 6, 8}).card = 13 := by decide +kernel
example : (({1, 2, 3, 4, 6, 8} : Finset ℕ) * {1, 2, 3, 4, 6, 8}).card = 15 := by decide +kernel
example : ({1, 2, 3, 4, 6, 8} : Finset ℕ).addEnergy {1, 2, 3, 4, 6, 8} = 114 := by decide +kernel
example : ({1, 2, 3, 4, 6, 8} : Finset ℕ).mulEnergy {1, 2, 3, 4, 6, 8} = 106 := by decide +kernel

-- Closed forms at n = 10: n(n+1)/2 = 55, 2n − 1 = 19, 2n² − n = 190, (2n³ + n)/3 = 670.
example : 10 * 11 / 2 = 55 ∧ 2 * 10 - 1 = 19 ∧ 2 * 10 ^ 2 - 10 = 190 ∧
    (2 * 10 ^ 3 + 10) / 3 = 670 := by decide +kernel

-- Solymosi at ten numbers: ⌈log₂ 10⌉ = 4, and 19 × 55² = 57,475 is at least 10⁴ / 16 = 625.
example : Nat.clog 2 10 = 4 := by decide +kernel
example : 19 * 55 ^ 2 = 57475 ∧ 10 ^ 4 / (4 * 4) = 625 ∧ 625 ≤ 57475 := by decide +kernel

-- What breaks: all 13 remainders mod 13 give 13 sums and 13 products, no growth.
example : ((Finset.univ : Finset (ZMod 13)) + Finset.univ).card = 13 := by decide +kernel
example : ((Finset.univ : Finset (ZMod 13)) * Finset.univ).card = 13 := by decide +kernel

-- What breaks: ordered pairs from ten numbers number 100, not the 55 sums.
example : ((Finset.range 10) ×ˢ (Finset.range 10)).card = 100 := by decide +kernel

#print axioms card_add_ge_card_pow_four_div_addEnergy
#print axioms card_mul_mul_card_add_sq_ge
#print axioms exists_max_card_add_card_mul_ge
