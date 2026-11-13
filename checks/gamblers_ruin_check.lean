-- Gambler's ruin: betting one chip a round with win chance p, from k chips the chance of reaching L before 0 is k/L when fair and (1 - r^k)/(1 - r^L) with r = q/p otherwise, ruin has the rest of the chance, and the average game length is k(L - k) when fair and (k - L h_k)/(q - p) otherwise.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib

open MeasureTheory ProbabilityTheory

/-! Setting. `Ω` with probability measure `μ`. Round `i + 1` is `ξ i ω` (`true` = she wins one
chip, `false` = she loses one chip). The rounds are independent and each is won with the same
chance `p`, with `0 < p < 1` and `q = 1 - p`. She starts with `k` chips, `0 ≤ k ≤ L`, and the walls
are the floor 0 and the target `L > 0`. -/

/-- The chips after the first `n` rounds, from a start of `k` chips, if she kept playing. -/
def chips {Ω : Type*} (k : ℕ) (ξ : ℕ → Ω → Bool) (n : ℕ) (ω : Ω) : ℤ :=
  (k : ℤ) + ∑ i ∈ Finset.range n, if ξ i ω then 1 else -1

/-- The round at which the game ends: the first `n` with the chips at 0 or at `L`. -/
noncomputable def exitRound {Ω : Type*} (k L : ℕ) (ξ : ℕ → Ω → Bool) (ω : Ω) : ℕ :=
  sInf {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}

/-- The card's formula `h_k`: `k/L` at a fair table (`p = q = 1/2`), and
`(1 - r^k)/(1 - r^L)` with `r = q/p` otherwise. -/
noncomputable def targetChance (p : ℝ) (L k : ℕ) : ℝ :=
  if p = 1 / 2 then (k : ℝ) / L else (1 - ((1 - p) / p) ^ k) / (1 - ((1 - p) / p) ^ L)

lemma gr_denom_ne {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (hp : ¬ p = 1 / 2) {L : ℕ} (hL : 0 < L) :
    1 - ((1 - p) / p) ^ L ≠ 0 := by
  intro h
  have h1 : ((1 - p) / p) ^ L = 1 := by linarith
  rw [pow_eq_one_iff_of_nonneg (div_pos (by linarith) hp0).le hL.ne'] at h1
  rw [div_eq_one_iff_eq hp0.ne'] at h1
  exact hp (by linarith)

lemma gr_target_zero (p : ℝ) (L : ℕ) : targetChance p L 0 = 0 := by
  unfold targetChance; split_ifs <;> simp

lemma gr_target_L {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) {L : ℕ} (hL : 0 < L) :
    targetChance p L L = 1 := by
  unfold targetChance; split_ifs with h
  · have : (L : ℝ) ≠ 0 := by exact_mod_cast hL.ne'
    exact div_self this
  · exact div_self (gr_denom_ne hp0 hp1 h hL)

lemma gr_target_harm {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (L : ℕ) (k : ℕ) (hk : 0 < k) :
    targetChance p L k = p * targetChance p L (k + 1) + (1 - p) * targetChance p L (k - 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  simp only [Nat.add_sub_cancel]
  unfold targetChance
  split_ifs with h
  · subst h; push_cast; ring
  · set r := (1 - p) / p with hr_def
    have hr : p * r = 1 - p := by rw [hr_def]; field_simp
    have key : p * r ^ (j + 1 + 1) + (1 - p) * r ^ j = r ^ (j + 1) := by
      linear_combination (r ^ (j + 1) - r ^ j) * hr
    rw [mul_div_assoc', mul_div_assoc', ← add_div]
    congr 1
    linear_combination key

/-- One round of the game, stopped once the chips are at a wall. -/
def grStep (L x : ℕ) (b : Bool) : ℕ :=
  if 0 < x ∧ x < L then (if b then x + 1 else x - 1) else x

/-- The game stopped at the walls, driven by a sequence of round results. -/
def grWalk (L k : ℕ) (b : ℕ → Bool) : ℕ → ℕ
  | 0 => k
  | n + 1 => grStep L (grWalk L k b n) (b n)

/-- The stopped chips after `n` rounds. -/
def grY {Ω : Type*} (L k : ℕ) (ξ : ℕ → Ω → Bool) (n : ℕ) (ω : Ω) : ℕ :=
  grWalk L k (fun i => ξ i ω) n

section walk
variable {Ω : Type*} {ξ : ℕ → Ω → Bool} {L k : ℕ}

lemma gr_chips_zero (ω : Ω) : chips k ξ 0 ω = k := by simp [chips]

lemma gr_chips_succ (n : ℕ) (ω : Ω) :
    chips k ξ (n + 1) ω = chips k ξ n ω + (if ξ n ω then 1 else -1) := by
  simp [chips, Finset.sum_range_succ, add_assoc]

lemma grWalk_congr (L k : ℕ) {b b' : ℕ → Bool} (n : ℕ) (h : ∀ i < n, b i = b' i) :
    grWalk L k b n = grWalk L k b' n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    simp only [grWalk]; rw [ih (fun i hi => h i (by omega)), h n (by omega)]

lemma grY_succ (n : ℕ) (ω : Ω) : grY L k ξ (n + 1) ω = grStep L (grY L k ξ n ω) (ξ n ω) := rfl

lemma grY_zero (ω : Ω) : grY L k ξ 0 ω = k := rfl

lemma grY_le (hk : k ≤ L) (n : ℕ) (ω : Ω) : grY L k ξ n ω ≤ L := by
  induction n with
  | zero => simpa [grY_zero]
  | succ n ih =>
    rw [grY_succ, grStep]
    split_ifs <;> omega

lemma grY_absorb {n : ℕ} {ω : Ω} (h : ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L)) :
    ∀ m, n ≤ m → grY L k ξ m ω = grY L k ξ n ω := by
  intro m hm
  induction m, hm using Nat.le_induction with
  | base => rfl
  | succ m hm ih => rw [grY_succ, grStep, ih, if_neg h]

lemma grY_eq_chips {n : ℕ} {ω : Ω} (h : ∀ m < n, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L) :
    (grY L k ξ n ω : ℤ) = chips k ξ n ω := by
  induction n with
  | zero => simp [grY_zero, gr_chips_zero]
  | succ n ih =>
    have hn := h n (by omega)
    rw [grY_succ, gr_chips_succ, ← ih (fun m hm => h m (by omega)), grStep, if_pos hn]
    cases ξ n ω <;> simp <;> omega

lemma gr_pathA (hL : 0 < L) (hk : k ≤ L) (ω : Ω) :
    (∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω) ↔ ∃ n, grY L k ξ n ω = L := by
  classical
  constructor
  · rintro ⟨n, hn, hpos⟩
    have hex : ∃ n, chips k ξ n ω = L := ⟨n, hn⟩
    have hn0le : Nat.find hex ≤ n := Nat.find_min' hex hn
    have hlt : ∀ m < Nat.find hex, chips k ξ m ω < L := by
      intro m
      induction m with
      | zero =>
        intro h0
        have h1 := Nat.find_min hex h0
        have h2 := hpos 0 (by omega)
        rw [gr_chips_zero] at h1 h2 ⊢
        omega
      | succ m ih =>
        intro hm
        have h1 := Nat.find_min hex hm
        have h2 := ih (by omega)
        rw [gr_chips_succ] at h1 ⊢
        split_ifs at h1 ⊢ <;> omega
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m
      induction m using Nat.strong_induction_on with
      | _ m ih =>
        intro hm
        have e := grY_eq_chips (n := m) (fun j hj => ih j hj (by omega))
        have h1 := hpos m (by omega)
        have h2 := hlt m hm
        omega
    refine ⟨Nat.find hex, ?_⟩
    have e := grY_eq_chips hal
    have := Nat.find_spec hex
    omega
  · rintro ⟨n, hn⟩
    have hex : ∃ n, grY L k ξ n ω = L := ⟨n, hn⟩
    have hspec := Nat.find_spec hex
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m hm
      have h1 := Nat.find_min hex hm
      have hle := grY_le (ξ := ξ) hk m ω
      refine ⟨?_, by omega⟩
      by_contra h0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (n := m) (ω := ω) (by omega) (Nat.find hex) hm.le
      omega
    refine ⟨Nat.find hex, ?_, ?_⟩
    · have e := grY_eq_chips hal
      omega
    · intro m hm
      have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
      have := hal m hm
      omega

lemma gr_pathB (hL : 0 < L) (hk : k ≤ L) (ω : Ω) :
    (∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L) ↔ ∃ n, grY L k ξ n ω = 0 := by
  classical
  constructor
  · rintro ⟨n, hn, hlt⟩
    have hex : ∃ n, chips k ξ n ω = 0 := ⟨n, hn⟩
    have hn0le : Nat.find hex ≤ n := Nat.find_min' hex hn
    have hpos : ∀ m < Nat.find hex, 0 < chips k ξ m ω := by
      intro m
      induction m with
      | zero =>
        intro h0
        have h1 := Nat.find_min hex h0
        rw [gr_chips_zero] at h1 ⊢
        omega
      | succ m ih =>
        intro hm
        have h1 := Nat.find_min hex hm
        have h2 := ih (by omega)
        rw [gr_chips_succ] at h1 ⊢
        split_ifs at h1 ⊢ <;> omega
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m
      induction m using Nat.strong_induction_on with
      | _ m ih =>
        intro hm
        have e := grY_eq_chips (n := m) (fun j hj => ih j hj (by omega))
        have h1 := hpos m hm
        have h2 := hlt m (by omega)
        omega
    refine ⟨Nat.find hex, ?_⟩
    have e := grY_eq_chips hal
    have := Nat.find_spec hex
    omega
  · rintro ⟨n, hn⟩
    have hex : ∃ n, grY L k ξ n ω = 0 := ⟨n, hn⟩
    have hspec := Nat.find_spec hex
    have hal : ∀ m < Nat.find hex, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
      intro m hm
      have h1 := Nat.find_min hex hm
      have hle := grY_le (ξ := ξ) hk m ω
      refine ⟨by omega, ?_⟩
      by_contra h0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (n := m) (ω := ω) (by omega) (Nat.find hex) hm.le
      omega
    refine ⟨Nat.find hex, ?_, ?_⟩
    · have e := grY_eq_chips hal
      omega
    · intro m hm
      have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
      have := hal m hm
      omega

lemma gr_pathC (hk : k ≤ L) (ω : Ω) (h : ∃ n, ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L)) :
    (chips k ξ (Nat.find h) ω = 0 ∨ chips k ξ (Nat.find h) ω = L) ∧
      exitRound k L ξ ω = Nat.find h ∧
      ∀ m, (0 < grY L k ξ m ω ∧ grY L k ξ m ω < L) ↔ m < Nat.find h := by
  have hal : ∀ m < Nat.find h, 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L := by
    intro m hm
    have := Nat.find_min h hm
    simpa using this
  have hN : chips k ξ (Nat.find h) ω = 0 ∨ chips k ξ (Nat.find h) ω = L := by
    have e := grY_eq_chips hal
    have h1 := Nat.find_spec h
    have h2 := grY_le (ξ := ξ) hk (Nat.find h) ω
    omega
  refine ⟨hN, ?_, ?_⟩
  · unfold exitRound
    apply le_antisymm (Nat.sInf_le hN)
    by_contra hlt0
    have hlt := not_le.mp hlt0
    have hmem := Nat.sInf_mem (s := {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}) ⟨_, hN⟩
    set m := sInf {n : ℕ | chips k ξ n ω = 0 ∨ chips k ξ n ω = L}
    have e := grY_eq_chips (n := m) (fun j hj => hal j (by omega))
    have := hal m hlt
    simp only [Set.mem_setOf_eq] at hmem
    omega
  · intro m
    constructor
    · intro hm
      by_contra hge0
      have hge := not_lt.mp hge0
      have := grY_absorb (L := L) (k := k) (ξ := ξ) (Nat.find_spec h) m hge
      rw [this] at hm
      exact Nat.find_spec h hm
    · exact hal m

end walk

/-- The card's average game length, as a function of the start. -/
noncomputable def grDur (p : ℝ) (L x : ℕ) : ℝ :=
  if p = 1 / 2 then (x : ℝ) * ((L : ℝ) - x) else ((x : ℝ) - L * targetChance p L x) / ((1 - p) - p)

lemma gr_dur_zero (p : ℝ) (L : ℕ) : grDur p L 0 = 0 := by
  unfold grDur; split_ifs <;> simp [gr_target_zero]

lemma gr_dur_L {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) {L : ℕ} (hL : 0 < L) : grDur p L L = 0 := by
  unfold grDur; split_ifs <;> simp [gr_target_L hp0 hp1 hL]

lemma gr_dur_harm {p : ℝ} (hp0 : 0 < p) (hp1 : p < 1) (L x : ℕ) (hx : 0 < x) :
    grDur p L x = 1 + p * grDur p L (x + 1) + (1 - p) * grDur p L (x - 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, x = j + 1 := ⟨x - 1, by omega⟩
  have ht := gr_target_harm hp0 hp1 L (j + 1) (by omega)
  simp only [Nat.add_sub_cancel] at ht ⊢
  unfold grDur
  split_ifs with h
  · subst h; push_cast; ring
  · have hd : (1 - p) - p ≠ 0 := by intro h'; apply h; linarith
    field_simp
    push_cast
    linear_combination (-(L : ℝ)) * ht

section prob
variable {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
  {ξ : ℕ → Ω → Bool} {L k : ℕ}

lemma grY_measurable (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) : Measurable (grY L k ξ n) := by
  induction n with
  | zero => exact measurable_const
  | succ n ih =>
    have : grY L k ξ (n + 1) =
        (fun z : ℕ × Bool => grStep L z.1 z.2) ∘ (fun ω => (grY L k ξ n ω, ξ n ω)) := rfl
    rw [this]
    exact (measurable_of_countable _).comp (ih.prodMk (hmeas n))

lemma gr_integrable (hmeas : ∀ i, Measurable (ξ i)) (hk : k ≤ L) (Φ : ℕ → Bool → ℝ) (n : ℕ) :
    Integrable (fun ω => Φ (grY L k ξ n ω) (ξ n ω)) μ := by
  refine Integrable.of_bound ?_ (∑ x ∈ Finset.range (L + 1), (|Φ x true| + |Φ x false|))
    (ae_of_all _ fun ω => ?_)
  · exact ((measurable_of_countable (fun z : ℕ × Bool => Φ z.1 z.2)).comp
      ((grY_measurable hmeas n).prodMk (hmeas n))).aestronglyMeasurable
  · have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
      Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
    refine le_trans ?_ (Finset.single_le_sum (f := fun x => |Φ x true| + |Φ x false|)
      (fun x _ => by positivity) hx)
    rw [Real.norm_eq_abs]
    have h1 := abs_nonneg (Φ (grY L k ξ n ω) true)
    have h2 := abs_nonneg (Φ (grY L k ξ n ω) false)
    cases ξ n ω <;> linarith

lemma gr_measurableSet (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) (P : ℕ → Prop) :
    MeasurableSet {ω | P (grY L k ξ n ω)} :=
  (grY_measurable hmeas n) (Set.to_countable _).measurableSet

lemma gr_int_ind (hmeas : ∀ i, Measurable (ξ i)) (n : ℕ) (P : ℕ → Prop) [DecidablePred P] :
    ∫ ω, (if P (grY L k ξ n ω) then (1 : ℝ) else 0) ∂μ = μ.real {ω | P (grY L k ξ n ω)} := by
  rw [← integral_indicator_one (gr_measurableSet hmeas n P)]
  congr 1
  funext ω
  simp [Set.indicator]

lemma gr_indep (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) (n : ℕ) :
    IndepFun (grY L k ξ n) (ξ n) μ := by
  have hdisj : Disjoint (Finset.range n) {n} := by simp
  have h := hind.indepFun_finset (Finset.range n) {n} hdisj hmeas
  let F : (Finset.range n → Bool) → ℕ := fun v =>
    grWalk L k (fun i => if hi : i ∈ Finset.range n then v ⟨i, hi⟩ else false) n
  have h2 := h.comp (measurable_of_countable F)
    (measurable_pi_apply (⟨n, Finset.mem_singleton_self n⟩ : ({n} : Finset ℕ)))
  convert h2 using 1
  · funext ω
    simp only [Function.comp, F, grY]
    apply grWalk_congr
    intro i hi
    simp [hi]
  · rfl

lemma gr_step_int (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) (Φ : ℕ → Bool → ℝ) (n : ℕ) :
    ∫ ω, Φ (grY L k ξ n ω) (ξ n ω) ∂μ =
      ∫ ω, (p * Φ (grY L k ξ n ω) true + (1 - p) * Φ (grY L k ξ n ω) false) ∂μ := by
  have hβ : ∫ ω, (if ξ n ω = true then (1 : ℝ) else 0) ∂μ = p := by
    rw [← hp n, ← integral_indicator_one (s := {ω | ξ n ω = true}) (hmeas n (measurableSet_singleton true))]
    congr 1
    funext ω
    simp [Set.indicator]
  have hβ' : ∫ ω, (1 - if ξ n ω = true then (1 : ℝ) else 0) ∂μ = 1 - p := by
    rw [integral_sub (integrable_const 1) (gr_integrable (k := k) hmeas hk
      (fun _ b => if b = true then (1 : ℝ) else 0) n), hβ]
    simp
  have hpt : ∀ ω, Φ (grY L k ξ n ω) (ξ n ω) =
      Φ (grY L k ξ n ω) true * (if ξ n ω = true then (1 : ℝ) else 0) +
        Φ (grY L k ξ n ω) false * (1 - if ξ n ω = true then (1 : ℝ) else 0) := by
    intro ω; cases ξ n ω <;> simp
  have hI := gr_indep (k := k) (L := L) hmeas hind n
  have i1 : IndepFun (fun ω => Φ (grY L k ξ n ω) true)
      (fun ω => if ξ n ω = true then (1 : ℝ) else 0) μ :=
    hI.comp (measurable_from_nat (f := fun x => Φ x true))
      (measurable_of_countable (fun b : Bool => if b = true then (1 : ℝ) else 0))
  have i2 : IndepFun (fun ω => Φ (grY L k ξ n ω) false)
      (fun ω => 1 - if ξ n ω = true then (1 : ℝ) else 0) μ :=
    hI.comp (measurable_from_nat (f := fun x => Φ x false))
      (measurable_of_countable (fun b : Bool => 1 - if b = true then (1 : ℝ) else 0))
  have m1 : AEStronglyMeasurable (fun ω => Φ (grY L k ξ n ω) true) μ :=
    (gr_integrable (k := k) hmeas hk (fun x _ => Φ x true) n).aestronglyMeasurable
  have m2 : AEStronglyMeasurable (fun ω => Φ (grY L k ξ n ω) false) μ :=
    (gr_integrable (k := k) hmeas hk (fun x _ => Φ x false) n).aestronglyMeasurable
  have m3 : AEStronglyMeasurable (fun ω => if ξ n ω = true then (1 : ℝ) else 0) μ :=
    (gr_integrable (k := k) hmeas hk (fun _ b => if b = true then (1 : ℝ) else 0) n).aestronglyMeasurable
  have m4 : AEStronglyMeasurable (fun ω => 1 - if ξ n ω = true then (1 : ℝ) else 0) μ :=
    (gr_integrable (k := k) hmeas hk (fun _ b => 1 - if b = true then (1 : ℝ) else 0) n).aestronglyMeasurable
  rw [integral_congr_ae (ae_of_all _ hpt)]
  rw [integral_add (gr_integrable (k := k) hmeas hk
      (fun x b => Φ x true * (if b = true then (1 : ℝ) else 0)) n)
    (gr_integrable (k := k) hmeas hk
      (fun x b => Φ x false * (1 - if b = true then (1 : ℝ) else 0)) n)]
  rw [i1.integral_fun_mul_eq_mul_integral m1 m3, i2.integral_fun_mul_eq_mul_integral m2 m4, hβ, hβ']
  rw [integral_add (gr_integrable (k := k) hmeas hk (fun x _ => p * Φ x true) n)
    (gr_integrable (k := k) hmeas hk (fun x _ => (1 - p) * Φ x false) n),
    integral_const_mul, integral_const_mul]
  ring

lemma gr_identity (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) (f : ℕ → ℝ) (c : ℝ)
    (hf : ∀ x, 0 < x → x < L → f x = c + p * f (x + 1) + (1 - p) * f (x - 1)) (n : ℕ) :
    ∫ ω, f (grY L k ξ n ω) ∂μ +
      c * ∑ m ∈ Finset.range n, μ.real {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L} = f k := by
  induction n with
  | zero => simp [grY_zero]
  | succ n ih =>
    rw [Finset.sum_range_succ, ← ih]
    have h1 := gr_step_int hmeas hind hp hk (fun x b => f (grStep L x b)) n
    have h2 : ∀ x, p * f (grStep L x true) + (1 - p) * f (grStep L x false) =
        f x - c * (if 0 < x ∧ x < L then (1 : ℝ) else 0) := by
      intro x
      by_cases hx : 0 < x ∧ x < L
      · rw [show grStep L x true = x + 1 by simp [grStep, hx],
          show grStep L x false = x - 1 by simp [grStep, hx], if_pos hx, hf x hx.1 hx.2]
        ring
      · rw [show grStep L x true = x by simp [grStep, hx],
          show grStep L x false = x by simp [grStep, hx], if_neg hx]
        ring
    simp only [h2] at h1
    have h3 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => 0 < x ∧ x < L)
    have h1' : ∫ ω, f (grY L k ξ (n + 1) ω) ∂μ =
        ∫ ω, (f (grY L k ξ n ω) - c * (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then (1 : ℝ) else 0)) ∂μ :=
      h1
    rw [h1', integral_sub (gr_integrable (k := k) hmeas hk (fun x _ => f x) n)
      (gr_integrable (k := k) hmeas hk (fun x _ => c * (if 0 < x ∧ x < L then (1 : ℝ) else 0)) n),
      integral_const_mul, h3]
    ring

lemma gr_middle (hmeas : ∀ i, Measurable (ξ i)) (hk : k ≤ L)
    (hdecay : Filter.Tendsto (fun n => μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L})
      Filter.atTop (nhds 0)) (f : ℕ → ℝ) :
    Filter.Tendsto (fun n => ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L
      then f (grY L k ξ n ω) else 0) ∂μ) Filter.atTop (nhds 0) := by
  set M := ∑ x ∈ Finset.range (L + 1), |f x|
  have hb : ∀ n, ‖∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L
      then f (grY L k ξ n ω) else 0) ∂μ‖ ≤
      M * μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} := by
    intro n
    have h3 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => 0 < x ∧ x < L)
    rw [← h3, ← integral_const_mul]
    refine norm_integral_le_of_norm_le
      (gr_integrable (k := k) hmeas hk (fun x _ => M * (if 0 < x ∧ x < L then (1 : ℝ) else 0)) n)
      (ae_of_all _ fun ω => ?_)
    have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
      Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
    have := Finset.single_le_sum (f := fun x => |f x|) (fun x _ => abs_nonneg _) hx
    split_ifs
    · simpa using this
    · simp
  refine squeeze_zero_norm hb ?_
  simpa using hdecay.const_mul M

lemma gr_decay (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hk : k ≤ L) :
    Filter.Tendsto (fun n => μ.real {ω | 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L})
      Filter.atTop (nhds 0) := by
  set M := ∑ x ∈ Finset.range (L + 1), |grDur p L x|
  set f : ℕ → ℝ := fun x => grDur p L x + M with hfdef
  have hf : ∀ x, 0 < x → x < L → f x = 1 + p * f (x + 1) + (1 - p) * f (x - 1) := by
    intro x hx _
    simp only [hfdef]
    rw [gr_dur_harm hp0 hp1 L x hx]
    ring
  have hid := gr_identity hmeas hind hp hk f 1 hf
  have hnonneg : ∀ n, 0 ≤ ∫ ω, f (grY L k ξ n ω) ∂μ := fun n =>
    integral_nonneg (fun ω => by
      show (0 : ℝ) ≤ f (grY L k ξ n ω)
      have hx : grY L k ξ n ω ∈ Finset.range (L + 1) :=
        Finset.mem_range.mpr (Nat.lt_succ_of_le (grY_le hk n ω))
      have h1 := Finset.single_le_sum (f := fun x => |grDur p L x|) (fun x _ => abs_nonneg _) hx
      have h2 := neg_abs_le (grDur p L (grY L k ξ n ω))
      simp only [hfdef]
      linarith)
  have hsum : Summable (fun m => μ.real {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L}) :=
    summable_of_sum_range_le (c := f k) (fun m => measureReal_nonneg) (fun n => by
      have := hid n; have := hnonneg n; linarith)
  exact hsum.tendsto_atTop_zero

lemma gr_boundary (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ) {p : ℝ}
    (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p) (hL : 0 < L)
    (hk : k ≤ L) (f : ℕ → ℝ)
    (hf : ∀ x, 0 < x → x < L → f x = p * f (x + 1) + (1 - p) * f (x - 1)) :
    Filter.Tendsto (fun n => f 0 * μ.real {ω | grY L k ξ n ω = 0} +
      f L * μ.real {ω | grY L k ξ n ω = L}) Filter.atTop (nhds (f k)) := by
  have hid := gr_identity hmeas hind hp hk f 0 (fun x hx hxL => by rw [hf x hx hxL]; ring)
  have hmid := gr_middle hmeas hk (gr_decay hmeas hind hp0 hp1 hp hk) f
  have heq : ∀ n, f 0 * μ.real {ω | grY L k ξ n ω = 0} + f L * μ.real {ω | grY L k ξ n ω = L} =
      f k - ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) ∂μ := by
    intro n
    have hdec : ∀ ω, f (grY L k ξ n ω) =
        f 0 * (if grY L k ξ n ω = 0 then (1 : ℝ) else 0) +
          f L * (if grY L k ξ n ω = L then (1 : ℝ) else 0) +
          (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) := by
      intro ω
      have hle := grY_le (ξ := ξ) hk n ω
      generalize grY L k ξ n ω = y at hle ⊢
      by_cases h0 : y = 0
      · subst h0; simp [hL.ne]
      · by_cases h1 : y = L
        · subst h1; simp [h0]
        · have h2 : 0 < y ∧ y < L := ⟨by omega, by omega⟩
          simp [h0, h1, h2]
    have e1 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => x = 0)
    have e2 := gr_int_ind (μ := μ) (L := L) (k := k) hmeas n (fun x => x = L)
    have hI : ∫ ω, f (grY L k ξ n ω) ∂μ = f 0 * μ.real {ω | grY L k ξ n ω = 0} +
        f L * μ.real {ω | grY L k ξ n ω = L} +
        ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then f (grY L k ξ n ω) else 0) ∂μ := by
      rw [integral_congr_ae (ae_of_all _ hdec),
        integral_add (by
          exact (gr_integrable (k := k) hmeas hk
            (fun x _ => f 0 * (if x = 0 then (1 : ℝ) else 0)) n).add
            (gr_integrable (k := k) hmeas hk (fun x _ => f L * (if x = L then (1 : ℝ) else 0)) n))
          (gr_integrable (k := k) hmeas hk
            (fun x _ => if 0 < x ∧ x < L then f x else 0) n),
        integral_add (gr_integrable (k := k) hmeas hk
            (fun x _ => f 0 * (if x = 0 then (1 : ℝ) else 0)) n)
            (gr_integrable (k := k) hmeas hk (fun x _ => f L * (if x = L then (1 : ℝ) else 0)) n),
        integral_const_mul, integral_const_mul, e1, e2]
    have := hid n
    simp only [zero_mul, add_zero] at this
    linarith
  refine Filter.Tendsto.congr (fun n => (heq n).symm) ?_
  simpa using (tendsto_const_nhds (x := f k)).sub hmid

end prob

#print axioms gr_denom_ne
#print axioms gr_target_zero
#print axioms gr_target_L
#print axioms gr_target_harm
#print axioms grStep
#print axioms grWalk
#print axioms grY
#print axioms gr_chips_zero
#print axioms gr_chips_succ
#print axioms grWalk_congr
#print axioms grY_succ
#print axioms grY_zero
#print axioms grY_le
#print axioms grY_absorb
#print axioms grY_eq_chips
#print axioms gr_pathA
#print axioms gr_pathB
#print axioms gr_pathC
#print axioms grDur
#print axioms gr_dur_zero
#print axioms gr_dur_L
#print axioms gr_dur_harm
#print axioms grY_measurable
#print axioms gr_integrable
#print axioms gr_measurableSet
#print axioms gr_int_ind
#print axioms gr_indep
#print axioms gr_step_int
#print axioms gr_identity
#print axioms gr_middle
#print axioms gr_decay
#print axioms gr_boundary

/-- Gambler's ruin. Betting one chip a round on independent rounds, each won with the same
chance `p`, from `k` chips (between 0 and the target `L`): the chance of reaching `L` before 0 is
`k/L` at a fair table and `(1 - r^k)/(1 - r^L)` with `r = q/p` otherwise, and the chance of
reaching 0 first (ruin) is 1 minus that. -/
theorem chance_reach_target_before_floor
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ξ : ℕ → Ω → Bool) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ)
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p)
    (L k : ℕ) (hL : 0 < L) (hk : k ≤ L) :
    μ.real {ω | ∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω} = targetChance p L k ∧
      μ.real {ω | ∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L} = 1 - targetChance p L k := by
  have hbA := gr_boundary hmeas hind hp0 hp1 hp hL hk (targetChance p L)
    (fun x hx _ => gr_target_harm hp0 hp1 L x hx)
  have hbB := gr_boundary hmeas hind hp0 hp1 hp hL hk (fun x => 1 - targetChance p L x)
    (fun x hx _ => by rw [gr_target_harm hp0 hp1 L x hx]; ring)
  simp only [gr_target_zero, gr_target_L hp0 hp1 hL, zero_mul, one_mul, zero_add, sub_zero,
    sub_self, add_zero] at hbA hbB
  have hmonoL : Monotone (fun n => {ω | grY L k ξ n ω = L}) := by
    intro a b hab ω hω
    simp only [Set.mem_setOf_eq] at hω ⊢
    rw [grY_absorb (by omega) b hab, hω]
  have hmono0 : Monotone (fun n => {ω | grY L k ξ n ω = 0}) := by
    intro a b hab ω hω
    simp only [Set.mem_setOf_eq] at hω ⊢
    rw [grY_absorb (by omega) b hab, hω]
  have hlimA := (ENNReal.tendsto_toReal (measure_ne_top μ _)).comp
    (tendsto_measure_iUnion_atTop (μ := μ) hmonoL)
  have hlimB := (ENNReal.tendsto_toReal (measure_ne_top μ _)).comp
    (tendsto_measure_iUnion_atTop (μ := μ) hmono0)
  have hsetA : {ω | ∃ n, chips k ξ n ω = L ∧ ∀ m < n, 0 < chips k ξ m ω} =
      ⋃ n, {ω | grY L k ξ n ω = L} := by
    ext ω
    simp only [Set.mem_setOf_eq, Set.mem_iUnion]
    exact gr_pathA hL hk ω
  have hsetB : {ω | ∃ n, chips k ξ n ω = 0 ∧ ∀ m < n, chips k ξ m ω < L} =
      ⋃ n, {ω | grY L k ξ n ω = 0} := by
    ext ω
    simp only [Set.mem_setOf_eq, Set.mem_iUnion]
    exact gr_pathB hL hk ω
  refine ⟨?_, ?_⟩
  · rw [hsetA]; exact tendsto_nhds_unique hlimA hbA
  · rw [hsetB]; exact tendsto_nhds_unique hlimB hbB


/-- The expected length. In the same game, play ends at 0 or `L` with chance 1, the number of
rounds `T` has a finite average, and that average is `k(L - k)` at a fair table and
`(k - L h_k)/(q - p)` otherwise. -/
theorem expected_rounds_until_a_wall
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ξ : ℕ → Ω → Bool) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ μ)
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hp : ∀ i, μ.real {ω | ξ i ω = true} = p)
    (L k : ℕ) (hL : 0 < L) (hk : k ≤ L) :
    (∀ᵐ ω ∂μ, ∃ n, chips k ξ n ω = 0 ∨ chips k ξ n ω = L) ∧
      Integrable (fun ω => (exitRound k L ξ ω : ℝ)) μ ∧
      ∫ ω, (exitRound k L ξ ω : ℝ) ∂μ =
        if p = 1 / 2 then (k : ℝ) * ((L : ℝ) - k)
        else ((k : ℝ) - L * targetChance p L k) / ((1 - p) - p) := by
  have hdecay := gr_decay hmeas hind hp0 hp1 hp hk
  set A : ℕ → Set Ω := fun m => {ω | 0 < grY L k ξ m ω ∧ grY L k ξ m ω < L} with hA
  have hnull : μ {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} = 0 := by
    have hle : ∀ n, μ.real {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} ≤ μ.real (A n) :=
      fun n => measureReal_mono (fun ω hω => hω n)
    have h0 : μ.real {ω | ∀ n, 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L} ≤ 0 :=
      ge_of_tendsto' hdecay hle
    exact (measureReal_eq_zero_iff).mp (le_antisymm h0 measureReal_nonneg)
  have hae : ∀ᵐ ω ∂μ, ∃ n, ¬(0 < grY L k ξ n ω ∧ grY L k ξ n ω < L) := by
    rw [ae_iff]
    refine measure_mono_null (fun ω hω => ?_) hnull
    simp only [Set.mem_setOf_eq, not_exists, not_not] at hω ⊢
    exact hω
  have hD := gr_identity hmeas hind hp hk (grDur p L) 1
    (fun x hx _ => gr_dur_harm hp0 hp1 L x hx)
  have hmid := gr_middle hmeas hk hdecay (grDur p L)
  have hDeq : ∀ n, ∫ ω, grDur p L (grY L k ξ n ω) ∂μ =
      ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then grDur p L (grY L k ξ n ω) else 0) ∂μ := by
    intro n
    congr 1
    funext ω
    have hle := grY_le (ξ := ξ) hk n ω
    split_ifs with h
    · rfl
    · rcases (show grY L k ξ n ω = 0 ∨ grY L k ξ n ω = L by omega) with h' | h' <;> rw [h']
      · exact gr_dur_zero p L
      · exact gr_dur_L hp0 hp1 hL
  have htend : Filter.Tendsto (fun n => ∑ m ∈ Finset.range n, μ.real (A m)) Filter.atTop
      (nhds (grDur p L k)) := by
    have e : ∀ n, ∑ m ∈ Finset.range n, μ.real (A m) = grDur p L k -
        ∫ ω, (if 0 < grY L k ξ n ω ∧ grY L k ξ n ω < L then grDur p L (grY L k ξ n ω) else 0) ∂μ := by
      intro n
      have := hD n
      rw [hDeq] at this
      simp only [hA]
      linarith
    refine Filter.Tendsto.congr (fun n => (e n).symm) ?_
    simpa using (tendsto_const_nhds (x := grDur p L k)).sub hmid
  have hsum : HasSum (fun m => μ.real (A m)) (grDur p L k) :=
    (hasSum_iff_tendsto_nat_of_nonneg (fun m => measureReal_nonneg) _).mpr htend
  have hDk : 0 ≤ grDur p L k := hsum.nonneg (fun m => measureReal_nonneg)
  have hAmeas : ∀ m, MeasurableSet (A m) := fun m =>
    gr_measurableSet hmeas m (fun x => 0 < x ∧ x < L)
  have hT : ∀ᵐ ω ∂μ, (exitRound k L ξ ω : ENNReal) = ∑' m, (A m).indicator 1 ω := by
    filter_upwards [hae] with ω h
    obtain ⟨-, hex, hiff⟩ := gr_pathC hk ω h
    rw [hex]
    have e : ∀ m, (A m).indicator (1 : Ω → ENNReal) ω = if m < Nat.find h then 1 else 0 := by
      intro m
      by_cases hm : m < Nat.find h
      · rw [if_pos hm]
        exact Set.indicator_of_mem (show ω ∈ A m from (hiff m).mpr hm) _
      · rw [if_neg hm]
        exact Set.indicator_of_notMem (show ω ∉ A m from fun h' => hm ((hiff m).mp h')) _
    simp_rw [e]
    rw [tsum_eq_sum (s := Finset.range (Nat.find h)) (fun m hm => by
      rw [Finset.mem_range] at hm; rw [if_neg hm])]
    rw [Finset.sum_congr rfl (fun m hm => if_pos (Finset.mem_range.mp hm))]
    simp
  have hmeasT : AEMeasurable (fun ω => (exitRound k L ξ ω : ENNReal)) μ :=
    (Measurable.ennreal_tsum (fun m => measurable_one.indicator (hAmeas m))).aemeasurable.congr
      (hT.mono fun ω h => h.symm)
  have hlin : ∫⁻ ω, (exitRound k L ξ ω : ENNReal) ∂μ = ENNReal.ofReal (grDur p L k) := by
    rw [lintegral_congr_ae hT,
      lintegral_tsum (fun m => (measurable_one.indicator (hAmeas m)).aemeasurable)]
    simp_rw [lintegral_indicator_one (hAmeas _)]
    rw [← hsum.tsum_eq, ENNReal.ofReal_tsum_of_nonneg (fun m => measureReal_nonneg) hsum.summable]
    congr 1
    funext m
    exact (ofReal_measureReal).symm
  have hcast : (fun ω => (exitRound k L ξ ω : ℝ)) = fun ω => ((exitRound k L ξ ω : ENNReal)).toReal := by
    funext ω; simp
  refine ⟨?_, ?_, ?_⟩
  · filter_upwards [hae] with ω h
    exact ⟨_, (gr_pathC hk ω h).1⟩
  · rw [hcast]
    exact integrable_toReal_of_lintegral_ne_top hmeasT (by rw [hlin]; exact ENNReal.ofReal_ne_top)
  · rw [hcast, integral_toReal hmeasT (ae_of_all _ fun ω => by simp), hlin, ENNReal.toReal_ofReal hDk]
    rfl

/-- The first-step equations have exactly one solution, the card's formula: a list of numbers
`h_0, …, h_L` satisfies `h_k = p h_{k+1} + q h_{k-1}` for `0 < k < L` with `h_0 = 0` and
`h_L = 1` exactly when each `h_k` equals `k/L` (fair) or `(1 - r^k)/(1 - r^L)` (tilted). -/
theorem first_step_equations_solution_unique
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (L : ℕ) (hL : 0 < L) (h : ℕ → ℝ) :
    (h 0 = 0 ∧ h L = 1 ∧ ∀ k, 0 < k → k < L → h k = p * h (k + 1) + (1 - p) * h (k - 1)) ↔
      ∀ k ≤ L, h k = targetChance p L k := by
  constructor
  · rintro ⟨h0, hL1, hrec⟩
    set g : ℕ → ℝ := fun k => h k - targetChance p L k with hg
    have e0 : g 0 = 0 := by simp [hg, h0, gr_target_zero]
    have eL : g L = 0 := by simp [hg, hL1, gr_target_L hp0 hp1 hL]
    have erec : ∀ k, 0 < k → k < L → p * g (k + 1) = g k - (1 - p) * g (k - 1) := by
      intro k hk hkL
      simp only [hg]
      rw [hrec k hk hkL, gr_target_harm hp0 hp1 L k hk]; ring
    set r := (1 - p) / p with hr_def
    have hr : p * r = 1 - p := by rw [hr_def]; field_simp
    set S : ℕ → ℝ := fun k => ∑ i ∈ Finset.range k, r ^ i with hS
    have Srec : ∀ k, p * S (k + 2) = S (k + 1) - (1 - p) * S k := by
      intro k
      simp only [hS, Finset.sum_range_succ]
      linear_combination r ^ k * hr
    have key : ∀ k, k + 1 ≤ L → g k = g 1 * S k ∧ g (k + 1) = g 1 * S (k + 1) := by
      intro k
      induction k with
      | zero => intro _; simp [hS, e0]
      | succ k ih =>
        intro hk
        obtain ⟨ih1, ih2⟩ := ih (by omega)
        refine ⟨ih2, ?_⟩
        have e := erec (k + 1) (by omega) (by omega)
        simp only [Nat.add_sub_cancel] at e
        have hp' : p ≠ 0 := hp0.ne'
        apply mul_left_cancel₀ hp'
        rw [e, ih1, ih2]
        have := Srec k
        linear_combination (-(g 1)) * this
    have rpos : 0 < r := div_pos (by linarith) hp0
    have SLpos : 0 < S L := by
      simp only [hS]
      apply Finset.sum_pos (fun i _ => pow_pos rpos i)
      exact ⟨0, by simp [hL]⟩
    have g1 : g 1 = 0 := by
      have := (key (L - 1) (by omega)).2
      rw [Nat.sub_add_cancel hL, eL] at this
      rcases mul_eq_zero.mp this.symm with h1 | h1
      · exact h1
      · exact absurd h1 SLpos.ne'
    intro k hk
    rcases eq_or_lt_of_le hk with rfl | hlt
    · have := eL; simp only [hg] at this; linarith
    · have := (key k (by omega)).1
      rw [g1, zero_mul] at this
      simp only [hg] at this; linarith
  · intro H
    refine ⟨by rw [H 0 (Nat.zero_le _), gr_target_zero], by rw [H L le_rfl, gr_target_L hp0 hp1 hL],
      fun k hk hkL => ?_⟩
    rw [H k hkL.le, H (k + 1) hkL, H (k - 1) (by omega)]
    exact gr_target_harm hp0 hp1 L k hk

-- Fair table, 10 chips, target 20: chance 10/20 = 1/2 and 10 × 10 = 100 rounds.
example : ((10 : ℚ) / 20 = 1 / 2) ∧ 10 * (20 - 10) = 100 := by norm_num
-- At 49 in 100 the tilt is r = 0.51/0.49 = 51/49.
example : ((1 : ℚ) - 49 / 100) / (49 / 100) = 51 / 49 := by norm_num
-- The shortcut when the target is twice the start: (1 - r^10)/(1 - r^20) = 1/(1 + r^10).
example : ((1 : ℚ) - (51 / 49) ^ 10) / (1 - (51 / 49) ^ 20) = 1 / (1 + (51 / 49) ^ 10) := by
  norm_num
-- The fair duration check: (1/2)(k+1)(L-k-1) + (1/2)(k-1)(L-k+1) = k(L-k) - 1.
example (k L : ℚ) :
    (1 / 2) * (k + 1) * (L - k - 1) + (1 / 2) * (k - 1) * (L - k + 1) = k * (L - k) - 1 := by
  ring
-- Moving the top wall up, fair, from 10 chips: chances 10/30, 10/40, 10/80, 10/160, 10/1000.
example : ((10 : ℚ) / 30 = 1 / 3) ∧ ((10 : ℚ) / 40 = 1 / 4) ∧ ((10 : ℚ) / 80 = 1 / 8) ∧
    ((10 : ℚ) / 160 = 1 / 16) ∧ ((10 : ℚ) / 1000 = 1 / 100) := by norm_num
-- … and lengths 10(L - 10): 200, 300, 700, 1500, 9900 rounds.
example : 10 * (30 - 10) = 200 ∧ 10 * (40 - 10) = 300 ∧ 10 * (80 - 10) = 700 ∧
    10 * (160 - 10) = 1500 ∧ 10 * (1000 - 10) = 9900 := by norm_num
-- Fair from 10 chips to 40: the average chips at the end equal the start, 40 × 1/4 = 10.
example : (40 : ℚ) * (1 / 4) = 10 := by norm_num

#print axioms chance_reach_target_before_floor
#print axioms expected_rounds_until_a_wall
#print axioms first_step_equations_solution_unique
