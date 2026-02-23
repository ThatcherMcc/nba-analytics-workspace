# NBA full-game over/under player props API (reference)

## Source
NBA Basketball full game over/under Player props. Example bookmaker in docs is espnbet (placeholder); you typically use **fair** and **book** odds from the check.

## Identifiers (from API docs)
- **oddID** pattern: `{statID}-PLAYER_ID-game-ou-{over|under}`  
  Example: `points-PLAYER_ID-game-ou-over`, `threePointersMade-PLAYER_ID-game-ou-under`.
- **statID** (what to map to `prop_markets.market_code` via `prop_market_mapping.API_STAT_ID_TO_MARKET_CODE`):

| statID | market_code | Market name |
|--------|-------------|-------------|
| points | PTS | Points |
| rebounds | REB | Rebounds |
| assists | AST | Assists |
| steals | STL | Steals |
| blocks | BLK | Blocks |
| turnovers | TOV | Turnovers |
| threePointersMade | FG3 | 3-Pointers Made |
| freeThrowsMade | FTM | Free Throws Made |
| points+rebounds | PR | Points + Rebounds |
| points+assists | PA | Points + Assists |
| rebounds+assists | RA | Rebounds + Assists |
| points+rebounds+assists | PRA | Points + Rebounds + Assists |
| blocks+steals | SB | Blocks + Steals |

Other fields: **statEntityID**: PLAYER_ID, **periodID**: game, **betTypeID**: ou, **sideID**: over | under. Market Group: Player Props. Leagues: NBA.

## Parsing strategy
Call for **one event** (or a few) and parse the return output for **all prop markets** of a full game. Use fair and book odds from the response; map each line’s statID to `market_code` then look up `prop_markets.market_id` for `player_props` (ML pipeline later).
