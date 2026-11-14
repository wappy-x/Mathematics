-- Nash equilibrium: in a 2 by 2 zero-sum game with no pure equilibrium, the indifference mixes p* = (c - d)/(b + c - a - d) and q* = (b - d)/(b + c - a - d) form the one and only Nash equilibrium, worth V = (bc - ad)/(b + c - a - d).
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic

/-- A cell `(i, j)` of a 2 by 2 game is a pure equilibrium when the row player cannot do better
by switching rows alone and the column player cannot do better by switching columns alone.
`R` is the row player's payoff and `C` the column player's. -/
def IsPureEquilibrium {α : Type*} [LE α] (R C : Fin 2 → Fin 2 → α) (i j : Fin 2) : Prop :=
  (∀ i', R i' j ≤ R i j) ∧ (∀ j', C i j' ≤ C i j)

/-- The kicker's expected scoring chance when the kicker shoots Left with chance `p` and the
keeper dives Left with chance `q`. Entries: `a` (Left, Left), `b` (Left, Right),
`c` (Right, Left), `d` (Right, Right). -/
def payoff (a b c d p q : ℝ) : ℝ :=
  p * q * a + p * (1 - q) * b + (1 - p) * q * c + (1 - p) * (1 - q) * d

/-- Helper: with no pure equilibrium, the diagonal entries both sit below, or both above,
the off-diagonal entries. -/
theorem no_pure_cases (a b c d : ℝ)
    (h_no_pure : ∀ i j, ¬ IsPureEquilibrium ![![a, b], ![c, d]]
      (fun i j => -(![![a, b], ![c, d]] i j)) i j) :
    (a < b ∧ a < c ∧ d < b ∧ d < c) ∨ (b < a ∧ c < a ∧ b < d ∧ c < d) := by
  have h00 := h_no_pure 0 0
  have h01 := h_no_pure 0 1
  have h10 := h_no_pure 1 0
  have h11 := h_no_pure 1 1
  simp [IsPureEquilibrium, Fin.forall_fin_two] at h00 h01 h10 h11
  rcases lt_or_ge a b with hab | hba
  · have hac : a < c := by
      by_contra h
      rw [not_lt] at h
      linarith [h00 h]
    have hdc : d < c := h10 hac.le
    have hdb : d < b := by
      by_contra h
      rw [not_lt] at h
      linarith [h11 h]
    exact Or.inl ⟨hab, hac, hdb, hdc⟩
  · have hbd : b < d := by
      by_contra h
      rw [not_lt] at h
      linarith [h01 h]
    have hcd : c < d := h11 hbd.le
    have hca : c < a := by
      by_contra h
      rw [not_lt] at h
      linarith [h10 h]
    have hba' : b < a := h00 hca.le
    exact Or.inr ⟨hba', hca, hbd, hcd⟩

/-- Helper: against the keeper's mix `q*`, every kicker mix scores `V`. -/
theorem payoff_at_q_star (a b c d x : ℝ) (h : b + c - a - d ≠ 0) :
    payoff a b c d x ((b - d) / (b + c - a - d)) = (b * c - a * d) / (b + c - a - d) := by
  unfold payoff
  field_simp
  ring

/-- Helper: against the kicker's mix `p*`, every keeper mix concedes `V`. -/
theorem payoff_at_p_star (a b c d y : ℝ) (h : b + c - a - d ≠ 0) :
    payoff a b c d ((c - d) / (b + c - a - d)) y = (b * c - a * d) / (b + c - a - d) := by
  unfold payoff
  field_simp
  ring

/-- Helper: the payoff is linear in the kicker's mix. -/
theorem payoff_sub_kicker (a b c d x x' y : ℝ) :
    payoff a b c d x y - payoff a b c d x' y
      = (x - x') * ((b - d) - y * (b + c - a - d)) := by
  unfold payoff
  ring

/-- Helper: the payoff is linear in the keeper's mix. -/
theorem payoff_sub_keeper (a b c d x y y' : ℝ) :
    payoff a b c d x y - payoff a b c d x y'
      = (y - y') * ((c - d) - x * (b + c - a - d)) := by
  unfold payoff
  ring

#print axioms no_pure_cases
#print axioms payoff_at_q_star
#print axioms payoff_at_p_star
#print axioms payoff_sub_kicker
#print axioms payoff_sub_keeper

/-- The 2 by 2 mixed equilibrium. In a zero-sum 2 by 2 game (the kicker gets the table entry,
the keeper gets its negative) with no equilibrium in plain choices, let
`p* = (c - d)/(b + c - a - d)` and `q* = (b - d)/(b + c - a - d)`. Then the denominator is not
zero, both chances lie strictly between 0 and 1, no kicker mix scores more than `p*` against `q*`,
no keeper mix concedes less than `q*` against `p*`, and the scoring chance at the equilibrium is
`V = (bc - ad)/(b + c - a - d)`. -/
theorem two_by_two_mixed_nash_equilibrium (a b c d : ℝ)
    (h_no_pure : ∀ i j, ¬ IsPureEquilibrium ![![a, b], ![c, d]]
      (fun i j => -(![![a, b], ![c, d]] i j)) i j) :
    let den := b + c - a - d
    let p := (c - d) / den
    let q := (b - d) / den
    den ≠ 0 ∧ 0 < p ∧ p < 1 ∧ 0 < q ∧ q < 1 ∧
    (∀ x ∈ Set.Icc (0 : ℝ) 1, payoff a b c d x q ≤ payoff a b c d p q) ∧
    (∀ y ∈ Set.Icc (0 : ℝ) 1, payoff a b c d p q ≤ payoff a b c d p y) ∧
    payoff a b c d p q = (b * c - a * d) / den := by
  intro den p q
  have hcases := no_pure_cases a b c d h_no_pure
  have hden : den ≠ 0 := by
    rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
    · have : 0 < den := by simp only [den]; linarith
      exact this.ne'
    · have : den < 0 := by simp only [den]; linarith
      exact this.ne
  have hpq : 0 < p ∧ p < 1 ∧ 0 < q ∧ q < 1 := by
    rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
    · have hd : 0 < den := by simp only [den]; linarith
      refine ⟨div_pos (by linarith) hd, (div_lt_one hd).2 (by simp only [den]; linarith),
        div_pos (by linarith) hd, (div_lt_one hd).2 (by simp only [den]; linarith)⟩
    · have hd : den < 0 := by simp only [den]; linarith
      refine ⟨div_pos_of_neg_of_neg (by linarith) hd,
        (div_lt_one_of_neg hd).2 (by simp only [den]; linarith),
        div_pos_of_neg_of_neg (by linarith) hd,
        (div_lt_one_of_neg hd).2 (by simp only [den]; linarith)⟩
  have hq : ∀ x, payoff a b c d x q = (b * c - a * d) / den :=
    fun x => payoff_at_q_star a b c d x hden
  have hp : ∀ y, payoff a b c d p y = (b * c - a * d) / den :=
    fun y => payoff_at_p_star a b c d y hden
  refine ⟨hden, hpq.1, hpq.2.1, hpq.2.2.1, hpq.2.2.2, ?_, ?_, hq p⟩
  · intro x _
    rw [hq x, hq p]
  · intro y _
    rw [hp y, hp q]

/-- The equilibrium is the only one. In a zero-sum 2 by 2 game with no equilibrium in plain
choices, any pair of mixes from which neither player gains by changing alone is exactly
`(p*, q*)`: the two best-reply lines meet only once. -/
theorem two_by_two_mixed_equilibrium_unique (a b c d : ℝ)
    (h_no_pure : ∀ i j, ¬ IsPureEquilibrium ![![a, b], ![c, d]]
      (fun i j => -(![![a, b], ![c, d]] i j)) i j)
    (x y : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) (hy : y ∈ Set.Icc (0 : ℝ) 1)
    (h_kicker : ∀ x' ∈ Set.Icc (0 : ℝ) 1, payoff a b c d x' y ≤ payoff a b c d x y)
    (h_keeper : ∀ y' ∈ Set.Icc (0 : ℝ) 1, payoff a b c d x y ≤ payoff a b c d x y') :
    x = (c - d) / (b + c - a - d) ∧ y = (b - d) / (b + c - a - d) := by
  have hcases := no_pure_cases a b c d h_no_pure
  obtain ⟨hx0, hx1⟩ := hx
  obtain ⟨hy0, hy1⟩ := hy
  set den := b + c - a - d with hden_def
  set S := (b - d) - y * den with hS
  set T := (c - d) - x * den with hT
  -- Four comparisons against the plain choices.
  have k0 : 0 ≤ x * S := by
    have h := h_kicker 0 ⟨le_refl _, zero_le_one⟩
    have e := payoff_sub_kicker a b c d x 0 y
    rw [sub_zero] at e
    linarith
  have k1 : (1 - x) * S ≤ 0 := by
    have h := h_kicker 1 ⟨zero_le_one, le_refl _⟩
    have e := payoff_sub_kicker a b c d 1 x y
    linarith
  have g0 : y * T ≤ 0 := by
    have h := h_keeper 0 ⟨le_refl _, zero_le_one⟩
    have e := payoff_sub_keeper a b c d x y 0
    rw [sub_zero] at e
    linarith
  have g1 : 0 ≤ (1 - y) * T := by
    have h := h_keeper 1 ⟨zero_le_one, le_refl _⟩
    have e := payoff_sub_keeper a b c d x 1 y
    linarith
  -- Forcing lemmas: a nonzero slope pushes a mix to an end point.
  have y_one : T < 0 → y = 1 := by
    intro hTn
    by_contra hne
    have : 0 < 1 - y := by
      rcases lt_or_eq_of_le hy1 with h | h
      · linarith
      · exact absurd h hne
    have := mul_neg_of_pos_of_neg this hTn
    linarith
  have y_zero : 0 < T → y = 0 := by
    intro hTp
    by_contra hne
    have : 0 < y := lt_of_le_of_ne hy0 (Ne.symm hne)
    have := mul_pos this hTp
    linarith
  have x_zero : S < 0 → x = 0 := by
    intro hSn
    by_contra hne
    have : 0 < x := lt_of_le_of_ne hx0 (Ne.symm hne)
    have := mul_neg_of_pos_of_neg this hSn
    linarith
  have x_one : 0 < S → x = 1 := by
    intro hSp
    by_contra hne
    have : 0 < 1 - x := by
      rcases lt_or_eq_of_le hx1 with h | h
      · linarith
      · exact absurd h hne
    have := mul_pos this hSp
    linarith
  have hden : den ≠ 0 := by
    rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
    · have : 0 < den := by rw [hden_def]; linarith
      exact this.ne'
    · have : den < 0 := by rw [hden_def]; linarith
      exact this.ne
  -- The keeper's slope is zero.
  have hT0 : T = 0 := by
    rcases lt_trichotomy T 0 with hTn | hTz | hTp
    · exfalso
      have hy := y_one hTn
      rw [hS, hy] at x_zero x_one
      rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
      · have hx := x_zero (by rw [hden_def]; linarith)
        rw [hT, hx] at hTn
        linarith
      · have hx := x_one (by rw [hden_def]; linarith)
        rw [hT, hx] at hTn
        rw [hden_def] at hTn
        linarith
    · exact hTz
    · exfalso
      have hy := y_zero hTp
      rw [hS, hy] at x_zero x_one
      rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
      · have hx := x_one (by linarith)
        rw [hT, hx] at hTp
        rw [hden_def] at hTp
        linarith
      · have hx := x_zero (by linarith)
        rw [hT, hx] at hTp
        linarith
  have hxeq : x = (c - d) / den := by
    rw [eq_div_iff hden]
    rw [hT] at hT0
    linarith
  -- So the kicker mixes strictly, which forces the kicker's slope to zero.
  have hxin : 0 < x ∧ x < 1 := by
    rw [hxeq]
    rcases hcases with ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩
    · have hd : 0 < den := by rw [hden_def]; linarith
      exact ⟨div_pos (by linarith) hd, (div_lt_one hd).2 (by rw [hden_def]; linarith)⟩
    · have hd : den < 0 := by rw [hden_def]; linarith
      exact ⟨div_pos_of_neg_of_neg (by linarith) hd,
        (div_lt_one_of_neg hd).2 (by rw [hden_def]; linarith)⟩
  have hS0 : S = 0 := by
    rcases lt_trichotomy S 0 with hSn | hSz | hSp
    · have := x_zero hSn
      linarith [hxin.1]
    · exact hSz
    · have := x_one hSp
      linarith [hxin.2]
  have hyeq : y = (b - d) / den := by
    rw [eq_div_iff hden]
    rw [hS] at hS0
    linarith
  exact ⟨hxeq, hyeq⟩

/-- Step 2: a mix pays the weighted average, so no kicker mix beats the better plain choice. -/
theorem mix_never_beats_best_plain_choice (a b c d x y : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) :
    payoff a b c d x y ≤ max (payoff a b c d 1 y) (payoff a b c d 0 y) := by
  obtain ⟨hx0, hx1⟩ := hx
  have e : payoff a b c d x y = x * payoff a b c d 1 y + (1 - x) * payoff a b c d 0 y := by
    unfold payoff
    ring
  rw [e]
  have h1 : x * payoff a b c d 1 y ≤ x * max (payoff a b c d 1 y) (payoff a b c d 0 y) :=
    mul_le_mul_of_nonneg_left (le_max_left _ _) hx0
  have h2 : (1 - x) * payoff a b c d 0 y ≤
      (1 - x) * max (payoff a b c d 1 y) (payoff a b c d 0 y) :=
    mul_le_mul_of_nonneg_left (le_max_right _ _) (by linarith)
  linarith

/-! The card's worked numbers. Penalty table: a = 58, b = 95, c = 93, d = 70 (percent). -/

-- The penalty has no pure equilibrium: no cell is a best reply for both players.
example : ∀ i j, ¬ IsPureEquilibrium (![![58, 95], ![93, 70]] : Fin 2 → Fin 2 → ℤ)
    (fun i j => -(![![58, 95], ![93, 70]] : Fin 2 → Fin 2 → ℤ) i j) i j := by
  unfold IsPureEquilibrium; decide

-- Denominator 60, p* = 23/60, q* = 25/60, bc - ad = 8835 - 4060 = 4775, V = 4775/60.
example : (95 + 93 - 58 - 70 : ℤ) = 60 := by norm_num
example : ((93 - 70) / (95 + 93 - 58 - 70) : ℚ) = 23 / 60 := by norm_num
example : ((95 - 70) / (95 + 93 - 58 - 70) : ℚ) = 25 / 60 := by norm_num
example : (95 * 93 : ℤ) = 8835 ∧ (58 * 70 : ℤ) = 4060 ∧ (8835 - 4060 : ℤ) = 4775 := by norm_num
example : payoff 58 95 93 70 (23 / 60) (25 / 60) = 4775 / 60 := by norm_num [payoff]

-- Against q* = 25/60 the kicker scores 4775/60 going Left and going Right.
example : payoff 58 95 93 70 1 (25 / 60) = 4775 / 60 := by norm_num [payoff]
example : payoff 58 95 93 70 0 (25 / 60) = 4775 / 60 := by norm_num [payoff]

-- Against p* = 23/60 the keeper lets in 4775/60 diving Left and diving Right.
example : payoff 58 95 93 70 (23 / 60) 1 = 4775 / 60 := by norm_num [payoff]
example : payoff 58 95 93 70 (23 / 60) 0 = 4775 / 60 := by norm_num [payoff]

-- Mistakes. Kicker 50-50: a Left dive lets in 151/2 (75.50%), a Right dive 165/2 (82.50%).
example : payoff 58 95 93 70 (1 / 2) 1 = 151 / 2 := by norm_num [payoff]
example : payoff 58 95 93 70 (1 / 2) 0 = 165 / 2 := by norm_num [payoff]
-- Kicker uses the keeper's number 25/60: a Left dive lets in 4705/60 (78.42%).
example : payoff 58 95 93 70 (25 / 60) 1 = 4705 / 60 := by norm_num [payoff]
-- Keeper 50-50: shooting Right scores 163/2 (81.50%).
example : payoff 58 95 93 70 0 (1 / 2) = 163 / 2 := by norm_num [payoff]

/-! Bakery price war, row = our bakery, column = the rival; index 0 = High, 1 = Low. -/

-- (Low, Low) is a pure equilibrium, and it is the only one.
example : IsPureEquilibrium (![![1200, 700], ![1500, 900]] : Fin 2 → Fin 2 → ℤ)
    (![![1200, 1500], ![700, 900]] : Fin 2 → Fin 2 → ℤ) 1 1 := by
  unfold IsPureEquilibrium; decide
example : ∀ i j, IsPureEquilibrium (![![1200, 700], ![1500, 900]] : Fin 2 → Fin 2 → ℤ)
    (![![1200, 1500], ![700, 900]] : Fin 2 → Fin 2 → ℤ) i j → i = 1 ∧ j = 1 := by
  unfold IsPureEquilibrium; decide
-- From (High, High), our bakery gains 300 by cutting alone.
example : (1500 - 1200 : ℤ) = 300 := by norm_num

#print axioms two_by_two_mixed_nash_equilibrium
#print axioms two_by_two_mixed_equilibrium_unique
#print axioms mix_never_beats_best_plain_choice
