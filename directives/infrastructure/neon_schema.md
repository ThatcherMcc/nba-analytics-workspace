# Neon Postgres schema (exported)

Use this file when you need the current DB schema (e.g. populating tables, writing SQL).
Refresh by running from nba-data-backend:
  `source .venv/bin/activate && python3 scripts/export_neon_schema.py`

---

## Table: `auth_accounts`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| user_id | text | NO |  |
| type | text | NO |  |
| provider | text | NO |  |
| provider_account_id | text | NO |  |
| refresh_token | text | YES |  |
| access_token | text | YES |  |
| expires_at | integer | YES |  |
| token_type | text | YES |  |
| scope | text | YES |  |
| id_token | text | YES |  |
| session_state | text | YES |  |

**Constraints:**
- `auth_accounts_provider_provider_account_id_pk`: `PRIMARY KEY (provider, provider_account_id)`
- `auth_accounts_user_id_auth_users_id_fk`: `FOREIGN KEY (user_id) REFERENCES auth_users(id) ON DELETE CASCADE`

**Indexes:**
- `auth_accounts_provider_provider_account_id_pk`

---

## Table: `auth_sessions`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| session_token | text | NO |  |
| user_id | text | NO |  |
| expires | timestamp with time zone | NO |  |

**Constraints:**
- `auth_sessions_pkey`: `PRIMARY KEY (session_token)`
- `auth_sessions_user_id_auth_users_id_fk`: `FOREIGN KEY (user_id) REFERENCES auth_users(id) ON DELETE CASCADE`

**Indexes:**
- `auth_sessions_pkey`

---

## Table: `auth_users`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| id | text | NO |  |
| name | text | YES |  |
| email | text | YES |  |
| email_verified | timestamp with time zone | YES |  |
| image | text | YES |  |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

**Constraints:**
- `auth_users_pkey`: `PRIMARY KEY (id)`
- `auth_users_email_unique`: `UNIQUE (email)`

**Indexes:**
- `auth_users_pkey`
- `auth_users_email_unique`

---

## Table: `auth_verification_tokens`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| identifier | text | NO |  |
| token | text | NO |  |
| expires | timestamp with time zone | NO |  |

**Constraints:**
- `auth_verification_tokens_identifier_token_pk`: `PRIMARY KEY (identifier, token)`

**Indexes:**
- `auth_verification_tokens_identifier_token_pk`

---

## Table: `games`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| game_id | integer | NO | nextval('games_game_id_seq'::regclass) |
| game_date | date | NO |  |
| home_team_id | integer | NO |  |
| away_team_id | integer | NO |  |
| season | character varying(9) | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `games_pkey`: `PRIMARY KEY (game_id)`
- `unique_game`: `UNIQUE (game_date, home_team_id, away_team_id)`
- `games_home_team_id_teams_team_id_fk`: `FOREIGN KEY (home_team_id) REFERENCES teams(team_id)`
- `games_away_team_id_teams_team_id_fk`: `FOREIGN KEY (away_team_id) REFERENCES teams(team_id)`

**Indexes:**
- `games_pkey`
- `unique_game`
- `idx_games_date`

---

## Table: `ml_backtest_results`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| id | integer | NO | nextval('ml_backtest_results_id_seq'::regclass) |
| game_date | date | NO |  |
| player_name | text | NO |  |
| market_code | text | NO |  |
| prediction | text | NO |  |
| book_line | numeric | YES |  |
| p_over | numeric | YES |  |
| confidence | numeric | YES |  |
| actual_value | numeric | YES |  |
| hit | boolean | YES |  |
| avg_last_5 | numeric | YES |  |
| opp_def_rank | integer | YES |  |
| pick_rank | integer | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `ml_backtest_results_pkey`: `PRIMARY KEY (id)`
- `ml_backtest_results_game_date_player_name_market_code_key`: `UNIQUE (game_date, player_name, market_code)`

**Indexes:**
- `ml_backtest_results_pkey`
- `ml_backtest_results_game_date_player_name_market_code_key`
- `idx_ml_backtest_date`

---

## Table: `ml_predictions`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| prediction_id | integer | NO | nextval('ml_predictions_prediction_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| market_id | integer | NO |  |
| p_over | numeric | NO |  |
| prediction | character varying(5) | NO |  |
| confidence | numeric | NO |  |
| book_line | numeric | YES |  |
| avg_last_5 | numeric | YES |  |
| avg_season | numeric | YES |  |
| opp_def_rank | integer | YES |  |
| line_zscore | numeric | YES |  |
| model_version | character varying(50) | YES |  |
| predicted_at | timestamp with time zone | NO | now() |

**Constraints:**
- `ml_predictions_pkey`: `PRIMARY KEY (prediction_id)`
- `ml_predictions_player_id_players_player_id_fk`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `ml_predictions_game_id_games_game_id_fk`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `ml_predictions_market_id_prop_markets_market_id_fk`: `FOREIGN KEY (market_id) REFERENCES prop_markets(market_id)`
- `unq_ml_player_game_market`: `UNIQUE (player_id, game_id, market_id)`

**Indexes:**
- `ml_predictions_pkey`
- `idx_ml_predictions_game`
- `idx_ml_predictions_player_game`
- `unq_ml_player_game_market`

---

## Table: `mlb_batter_game_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| gamelog_id | integer | NO | nextval('mlb_batter_game_stats_gamelog_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| team_id | integer | NO |  |
| is_home | boolean | NO |  |
| plate_appearances | integer | YES | 0 |
| at_bats | integer | YES | 0 |
| hits | integer | YES | 0 |
| doubles | integer | YES | 0 |
| triples | integer | YES | 0 |
| home_runs | integer | YES | 0 |
| rbi | integer | YES | 0 |
| runs | integer | YES | 0 |
| walks | integer | YES | 0 |
| strikeouts | integer | YES | 0 |
| stolen_bases | integer | YES | 0 |
| caught_stealing | integer | YES | 0 |
| hit_by_pitch | integer | YES | 0 |
| sac_fly | integer | YES | 0 |
| total_bases | integer | YES | 0 |
| batting_order | integer | YES |  |
| opp_pitcher_id | integer | YES |  |
| opp_pitcher_hand | character varying(1) | YES |  |
| created_at | timestamp with time zone | YES | now() |

**Constraints:**
- `mlb_batter_game_stats_game_id_fkey`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `mlb_batter_game_stats_opp_pitcher_id_fkey`: `FOREIGN KEY (opp_pitcher_id) REFERENCES players(player_id)`
- `mlb_batter_game_stats_pkey`: `PRIMARY KEY (gamelog_id)`
- `mlb_batter_game_stats_player_id_fkey`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `mlb_batter_game_stats_player_id_game_id_key`: `UNIQUE (player_id, game_id)`
- `mlb_batter_game_stats_team_id_fkey`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`

**Indexes:**
- `mlb_batter_game_stats_pkey`
- `mlb_batter_game_stats_player_id_game_id_key`
- `idx_batter_game_id`
- `idx_batter_player_game`
- `idx_batter_team_id`

---

## Table: `mlb_park_factors`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| park_id | integer | NO | nextval('mlb_park_factors_park_id_seq'::regclass) |
| team_id | integer | NO |  |
| season | character varying(4) | NO |  |
| pf_runs | numeric | YES |  |
| pf_hr | numeric | YES |  |
| pf_hits | numeric | YES |  |
| pf_so | numeric | YES |  |

**Constraints:**
- `mlb_park_factors_pkey`: `PRIMARY KEY (park_id)`
- `mlb_park_factors_team_id_fkey`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`
- `mlb_park_factors_team_id_season_key`: `UNIQUE (team_id, season)`

**Indexes:**
- `mlb_park_factors_pkey`
- `mlb_park_factors_team_id_season_key`
- `idx_park_factors_team_season`

---

## Table: `mlb_pitcher_game_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| gamelog_id | integer | NO | nextval('mlb_pitcher_game_stats_gamelog_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| team_id | integer | NO |  |
| is_home | boolean | NO |  |
| is_starter | boolean | NO | true |
| outs_recorded | integer | YES | 0 |
| hits_allowed | integer | YES | 0 |
| earned_runs | integer | YES | 0 |
| walks_allowed | integer | YES | 0 |
| strikeouts | integer | YES | 0 |
| home_runs_allowed | integer | YES | 0 |
| batters_faced | integer | YES | 0 |
| pitches | integer | YES | 0 |
| strikes | integer | YES | 0 |
| decision | character varying(5) | YES |  |
| created_at | timestamp with time zone | YES | now() |

**Constraints:**
- `mlb_pitcher_game_stats_game_id_fkey`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `mlb_pitcher_game_stats_pkey`: `PRIMARY KEY (gamelog_id)`
- `mlb_pitcher_game_stats_player_id_fkey`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `mlb_pitcher_game_stats_player_id_game_id_key`: `UNIQUE (player_id, game_id)`
- `mlb_pitcher_game_stats_team_id_fkey`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`

**Indexes:**
- `mlb_pitcher_game_stats_pkey`
- `mlb_pitcher_game_stats_player_id_game_id_key`
- `idx_pitcher_game_id`
- `idx_pitcher_player_game`
- `idx_pitcher_team_id`

---

## Table: `mlb_pitcher_splits`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| split_id | integer | NO | nextval('mlb_pitcher_splits_split_id_seq'::regclass) |
| player_id | integer | NO |  |
| season | character varying(9) | NO |  |
| vs_lhb_avg | numeric | YES |  |
| vs_lhb_obp | numeric | YES |  |
| vs_lhb_slg | numeric | YES |  |
| vs_lhb_k_pct | numeric | YES |  |
| vs_lhb_bb_pct | numeric | YES |  |
| vs_rhb_avg | numeric | YES |  |
| vs_rhb_obp | numeric | YES |  |
| vs_rhb_slg | numeric | YES |  |
| vs_rhb_k_pct | numeric | YES |  |
| vs_rhb_bb_pct | numeric | YES |  |
| updated_at | timestamp with time zone | YES | now() |

**Constraints:**
- `mlb_pitcher_splits_pkey`: `PRIMARY KEY (split_id)`
- `mlb_pitcher_splits_player_id_fkey`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `mlb_pitcher_splits_player_id_season_key`: `UNIQUE (player_id, season)`

**Indexes:**
- `mlb_pitcher_splits_pkey`
- `mlb_pitcher_splits_player_id_season_key`
- `idx_pitcher_splits_player_season`

---

## Table: `mlb_team_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| team_stat_id | integer | NO | nextval('mlb_team_stats_team_stat_id_seq'::regclass) |
| team_id | integer | NO |  |
| season | character varying(9) | NO |  |
| team_k_pct | numeric | YES |  |
| team_bb_pct | numeric | YES |  |
| team_avg | numeric | YES |  |
| team_obp | numeric | YES |  |
| team_slg | numeric | YES |  |
| team_wrc_plus | integer | YES |  |
| team_era | numeric | YES |  |
| team_whip | numeric | YES |  |
| team_k9 | numeric | YES |  |
| team_bb9 | numeric | YES |  |
| team_hr9 | numeric | YES |  |
| team_def | numeric | YES |  |
| updated_at | timestamp with time zone | YES | now() |

**Constraints:**
- `mlb_team_stats_pkey`: `PRIMARY KEY (team_stat_id)`
- `mlb_team_stats_team_id_fkey`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`
- `mlb_team_stats_team_id_season_key`: `UNIQUE (team_id, season)`

**Indexes:**
- `mlb_team_stats_pkey`
- `mlb_team_stats_team_id_season_key`
- `idx_team_stats_team_season`

---

## Table: `nba_advanced_team_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| stat_id | integer | NO | nextval('nba_advanced_team_stats_stat_id_seq'::regclass) |
| team_id | integer | NO |  |
| season | character varying(9) | NO | '2025-26'::character varying |
| gp | integer | YES |  |
| w | integer | YES |  |
| l | integer | YES |  |
| w_pct | numeric | YES |  |
| off_rating | numeric | YES |  |
| def_rating | numeric | YES |  |
| net_rating | numeric | YES |  |
| e_off_rating | numeric | YES |  |
| e_def_rating | numeric | YES |  |
| e_net_rating | numeric | YES |  |
| pace | numeric | YES |  |
| ts_pct | numeric | YES |  |
| efg_pct | numeric | YES |  |
| ast_pct | numeric | YES |  |
| ast_to | numeric | YES |  |
| ast_ratio | numeric | YES |  |
| oreb_pct | numeric | YES |  |
| dreb_pct | numeric | YES |  |
| reb_pct | numeric | YES |  |
| tm_tov_pct | numeric | YES |  |
| pie | numeric | YES |  |
| off_rating_rank | integer | YES |  |
| def_rating_rank | integer | YES |  |
| net_rating_rank | integer | YES |  |
| pace_rank | integer | YES |  |
| updated_at | timestamp with time zone | NO | now() |

**Constraints:**
- `nba_advanced_team_stats_pkey`: `PRIMARY KEY (stat_id)`
- `nba_advanced_team_stats_team_id_teams_team_id_fk`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`
- `unq_adv_team_season`: `UNIQUE (team_id, season)`

**Indexes:**
- `nba_advanced_team_stats_pkey`
- `unq_adv_team_season`

---

## Table: `player_game_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| gamelog_id | integer | NO | nextval('player_game_stats_gamelog_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| team_id | integer | NO |  |
| is_home | boolean | NO |  |
| minutes_played | character varying(5) | YES |  |
| field_goals_made | integer | YES | 0 |
| field_goals_attempted | integer | YES | 0 |
| field_goal_pct | numeric | YES |  |
| three_pointers_made | integer | YES | 0 |
| three_pointers_attempted | integer | YES | 0 |
| three_point_pct | numeric | YES |  |
| two_pointers_made | integer | YES | 0 |
| two_pointers_attempted | integer | YES | 0 |
| two_point_pct | numeric | YES |  |
| free_throws_made | integer | YES | 0 |
| free_throws_attempted | integer | YES | 0 |
| free_throw_pct | numeric | YES |  |
| effective_fg_pct | numeric | YES |  |
| offensive_rebounds | integer | YES | 0 |
| defensive_rebounds | integer | YES | 0 |
| total_rebounds | integer | YES | 0 |
| assists | integer | YES | 0 |
| steals | integer | YES | 0 |
| blocks | integer | YES | 0 |
| turnovers | integer | YES | 0 |
| personal_fouls | integer | YES | 0 |
| points | integer | YES | 0 |
| pts_reb_ast | integer | YES |  |
| pts_reb | integer | YES |  |
| pts_ast | integer | YES |  |
| reb_ast | integer | YES |  |
| stl_blk | integer | YES |  |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

**Constraints:**
- `player_game_stats_pkey`: `PRIMARY KEY (gamelog_id)`
- `unq_player_game`: `UNIQUE (player_id, game_id)`
- `player_game_stats_player_id_players_player_id_fk`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `player_game_stats_game_id_games_game_id_fk`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `player_game_stats_team_id_teams_team_id_fk`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`

**Indexes:**
- `player_game_stats_pkey`
- `unq_player_game`
- `idx_stats_lookup`

---

## Table: `player_props`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| prop_id | integer | NO | nextval('player_props_prop_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| market_id | integer | NO |  |
| over_under | character varying(5) | YES |  |
| fair_line | numeric | YES |  |
| fair_odds | integer | YES |  |
| book_line | numeric | YES |  |
| book_odds | integer | YES |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `player_props_pkey`: `PRIMARY KEY (prop_id)`
- `unq_player_game_market`: `UNIQUE (player_id, game_id, market_id)`
- `player_props_player_id_players_player_id_fk`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `player_props_game_id_games_game_id_fk`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `player_props_market_id_prop_markets_market_id_fk`: `FOREIGN KEY (market_id) REFERENCES prop_markets(market_id)`

**Indexes:**
- `player_props_pkey`
- `unq_player_game_market`
- `idx_props_lookup`

---

## Table: `players`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| player_id | integer | NO | nextval('players_player_id_seq'::regclass) |
| player_name | character varying(100) | NO |  |
| url | character varying(120) | NO |  |
| created_at | timestamp with time zone | NO | now() |
| player_abbreviation | character varying(9) | YES |  |

**Constraints:**
- `players_pkey`: `PRIMARY KEY (player_id)`
- `players_player_name_unique`: `UNIQUE (player_name)`
- `players_url_unique`: `UNIQUE (url)`

**Indexes:**
- `players_pkey`
- `idx_player_names`
- `players_player_name_unique`
- `players_url_unique`

---

## Table: `prop_markets`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| market_id | integer | NO | nextval('prop_markets_market_id_seq'::regclass) |
| market_code | character varying(20) | NO |  |
| market_name | character varying(50) | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `prop_markets_pkey`: `PRIMARY KEY (market_id)`
- `prop_markets_market_code_unique`: `UNIQUE (market_code)`

**Indexes:**
- `prop_markets_pkey`
- `prop_markets_market_code_unique`

---

## Table: `subscribers`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| subscriber_id | integer | NO | nextval('subscribers_subscriber_id_seq'::regclass) |
| email | character varying(255) | NO |  |
| subscribed_at | timestamp with time zone | NO | now() |
| unsubscribed_at | timestamp with time zone | YES |  |

**Constraints:**
- `subscribers_pkey`: `PRIMARY KEY (subscriber_id)`
- `subscribers_email_unique`: `UNIQUE (email)`

**Indexes:**
- `subscribers_pkey`
- `subscribers_email_unique`

---

## Table: `team_defensive_ratings`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| rating_id | integer | NO | nextval('team_defensive_ratings_rating_id_seq'::regclass) |
| team_id | integer | NO |  |
| season | character varying(9) | NO | '2025-2026'::character varying |
| games_played | integer | YES |  |
| opp_fg | numeric | YES |  |
| opp_fga | numeric | YES |  |
| opp_fg_pct | numeric | YES |  |
| opp_3p | numeric | YES |  |
| opp_3pa | numeric | YES |  |
| opp_3p_pct | numeric | YES |  |
| opp_2p | numeric | YES |  |
| opp_2pa | numeric | YES |  |
| opp_2p_pct | numeric | YES |  |
| opp_ft | numeric | YES |  |
| opp_fta | numeric | YES |  |
| opp_ft_pct | numeric | YES |  |
| opp_orb | numeric | YES |  |
| opp_drb | numeric | YES |  |
| opp_trb | numeric | YES |  |
| opp_ast | numeric | YES |  |
| opp_stl | numeric | YES |  |
| opp_blk | numeric | YES |  |
| opp_tov | numeric | YES |  |
| opp_pf | numeric | YES |  |
| opp_pts | numeric | YES |  |
| updated_at | timestamp with time zone | NO | now() |

**Constraints:**
- `team_defensive_ratings_pkey`: `PRIMARY KEY (rating_id)`
- `team_defensive_ratings_team_id_teams_team_id_fk`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`
- `unq_team_season_rating`: `UNIQUE (team_id, season)`

**Indexes:**
- `team_defensive_ratings_pkey`
- `unq_team_season_rating`

---

## Table: `teams`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| team_id | integer | NO | nextval('teams_team_id_seq'::regclass) |
| team_code | character varying(6) | NO |  |
| team_name | character varying(50) | NO |  |
| created_at | timestamp with time zone | NO | now() |
| sport | character varying(10) | YES | 'NBA'::character varying |

**Constraints:**
- `teams_pkey`: `PRIMARY KEY (team_id)`
- `teams_team_name_unique`: `UNIQUE (team_name)`
- `teams_team_code_unique`: `UNIQUE (team_code)`

**Indexes:**
- `teams_pkey`
- `teams_team_name_unique`
- `teams_team_code_unique`
- `idx_team_abbr`

---
