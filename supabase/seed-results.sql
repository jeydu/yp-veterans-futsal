-- One-time copy of the results that were written into the website (2026 and 2025).
-- Run AFTER setup.sql. It only adds a year if that year has no matches yet, so running it twice is harmless.

-- 2026
insert into public.seasons (year, champion, champion_dv, partial) values (2026, 'Royal Knights Sports Club', 'ރޯޔަލް ނައިޓްސް ސްޕޯޓްސް ކްލަބް', false)
  on conflict (year) do nothing;
insert into public.matches (year, day, no, home, away, home_score, away_score, pen_home, pen_away, stage, video, goals)
select * from (values
  (2026, 1, 1, 'Stelco SC', 'FT Nakasole', 4, 1, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2026, 1, 2, 'RK SC', 'BHC', 1, 1, null::int, null::int, null::text, '8jg50urgM_s', '[{"s":393,"t":418,"team":"RK SC","score":"1–0"},{"s":2346,"t":2371,"team":"BHC","score":"1–1"}]'::jsonb),
  (2026, 2, 3, 'RBG SC', 'FT Nakasole', 9, 0, null::int, null::int, null::text, '6VxFF4_yx0I', '[{"s":1489,"t":1514,"team":"RBG SC","score":"1–0"},{"s":1798,"t":1823,"team":"RBG SC","score":"2–0"},{"s":1897,"t":1922,"team":"RBG SC","score":"3–0"},{"s":2077,"t":2102,"team":"RBG SC","score":"4–0"},{"s":2156,"t":2181,"team":"RBG SC","score":"5–0"},{"s":2376,"t":2401,"team":"RBG SC","score":"6–0"},{"s":3511,"t":3536,"team":"RBG SC","score":"7–0"},{"s":3641,"t":3666,"team":"RBG SC","score":"8–0"},{"s":3770,"t":3795,"team":"RBG SC","score":"9–0"}]'::jsonb),
  (2026, 2, 4, 'RK SC', 'Stelco SC', 3, 0, null::int, null::int, null::text, 'V770mPlY_D0', '[{"s":781,"t":806,"team":"RK SC","score":"1–0"},{"s":1706,"t":1731,"team":"RK SC","score":"2–0"},{"s":3070,"t":3095,"team":"RK SC","score":"3–0"}]'::jsonb),
  (2026, 3, 5, 'BHC', 'RBG SC', 3, 4, null::int, null::int, null::text, 'AReZVN3RM7Q', '[{"s":1261,"t":1286,"team":"RBG SC","score":"0–1"},{"s":1330,"t":1365,"team":"BHC","score":"1–1"},{"s":1729,"t":1754,"team":"RBG SC","score":"1–2"},{"s":1958,"t":1993,"team":"RBG SC","score":"1–3"},{"s":2566,"t":2591,"team":"RBG SC","score":"1–4"},{"s":2935,"t":2960,"team":"BHC","score":"2–4"},{"s":3413,"t":3438,"team":"BHC","score":"3–4"}]'::jsonb),
  (2026, 3, 6, 'FT Nakasole', 'RK SC', 3, 12, null::int, null::int, null::text, 'aGY2Vw9ycEM', '[{"s":572,"t":597,"team":"RK SC","score":"0–1"},{"s":771,"t":796,"team":"RK SC","score":"0–2"},{"s":930,"t":955,"team":"RK SC","score":"0–3"},{"s":1408,"t":1433,"team":"RK SC","score":"0–4"},{"s":1527,"t":1552,"team":"RK SC","score":"0–5"},{"s":1627,"t":1652,"team":"RK SC","score":"0–6"},{"s":2144,"t":2169,"team":"RK SC","score":"0–7"},{"s":2204,"t":2229,"team":"RK SC","score":"0–8"},{"s":2234,"t":2259,"team":"FT Nakasole","score":"1–8"},{"s":2413,"t":2438,"team":"FT Nakasole","score":"2–8"},{"s":2523,"t":2547,"team":"RK SC","score":"2–9"},{"s":2652,"t":2677,"team":"RK SC","score":"2–10"},{"s":2851,"t":2876,"team":"FT Nakasole","score":"3–10"},{"s":3130,"t":3154,"team":"RK SC","score":"3–11"},{"s":3169,"t":3194,"team":"RK SC","score":"3–12"}]'::jsonb),
  (2026, 4, 7, 'Stelco SC', 'BHC', 7, 3, null::int, null::int, null::text, 'ekxGhUoblAI', '[{"s":1339,"t":1364,"team":"Stelco SC","score":"1–0"},{"s":1449,"t":1494,"team":"Stelco SC","score":"2–0"},{"s":1489,"t":1514,"team":"Stelco SC","score":"3–0"},{"s":1708,"t":1743,"team":"BHC","score":"3–1"},{"s":1937,"t":1962,"team":"Stelco SC","score":"4–1"},{"s":2216,"t":2241,"team":"Stelco SC","score":"5–1"},{"s":2246,"t":2280,"team":"Stelco SC","score":"6–1"},{"s":3062,"t":3107,"team":"BHC","score":"6–2"},{"s":3988,"t":4013,"team":"BHC","score":"6–3"},{"s":4367,"t":4392,"team":"Stelco SC","score":"7–3"}]'::jsonb),
  (2026, 4, 8, 'RBG SC', 'RK SC', 4, 0, null::int, null::int, null::text, '7FJ3AcWjcm8', '[{"s":961,"t":986,"team":"RBG SC","score":"1–0"},{"s":2175,"t":2200,"team":"RBG SC","score":"2–0"},{"s":2683,"t":2708,"team":"RBG SC","score":"3–0"},{"s":2793,"t":2818,"team":"RBG SC","score":"4–0"}]'::jsonb),
  (2026, 5, 9, 'FT Nakasole', 'BHC', 1, 13, null::int, null::int, null::text, 's5p9ymG6mqg', '[{"s":1448,"t":1472,"team":"BHC","score":"0–1"},{"s":1587,"t":1612,"team":"BHC","score":"0–2"},{"s":2204,"t":2229,"team":"BHC","score":"0–3"},{"s":2701,"t":2726,"team":"BHC","score":"0–4"},{"s":2731,"t":2756,"team":"BHC","score":"0–5"},{"s":2791,"t":2816,"team":"BHC","score":"0–6"},{"s":3000,"t":3025,"team":"BHC","score":"0–7"},{"s":3099,"t":3124,"team":"BHC","score":"0–8"},{"s":3209,"t":3233,"team":"BHC","score":"0–9"},{"s":3437,"t":3462,"team":"BHC","score":"0–10"},{"s":3477,"t":3502,"team":"BHC","score":"0–11"},{"s":3557,"t":3582,"team":"BHC","score":"0–12"},{"s":3606,"t":3631,"team":"FT Nakasole","score":"1–12"},{"s":3776,"t":3801,"team":"BHC","score":"1–13"}]'::jsonb),
  (2026, 5, 10, 'RBG SC', 'Stelco SC', 1, 1, null::int, null::int, null::text, 'Z5juxVWGrcw', '[{"s":652,"t":677,"team":"Stelco SC","score":"0–1"},{"s":2981,"t":3006,"team":"RBG SC","score":"1–1"}]'::jsonb),
  (2026, 6, 11, 'RBG SC', 'BHC', 4, 2, null::int, null::int, 'semi', 'o85FGjK_z5c', '[{"s":1429,"t":1474,"team":"RBG SC","score":"1–0"},{"s":1529,"t":1563,"team":"RBG SC","score":"2–0"},{"s":1907,"t":1942,"team":"RBG SC","score":"3–0"},{"s":2883,"t":2908,"team":"BHC","score":"3–1"},{"s":3251,"t":3276,"team":"RBG SC","score":"4–1"},{"s":3371,"t":3396,"team":"BHC","score":"4–2"}]'::jsonb),
  (2026, 6, 12, 'Stelco SC', 'RK SC', 1, 2, null::int, null::int, 'semi', 'ReUamnQOm2g', '[{"s":552,"t":597,"team":"RK SC","score":"0–1"},{"s":3188,"t":3213,"team":"Stelco SC","score":"1–1"},{"s":3238,"t":3263,"team":"RK SC","score":"1–2"}]'::jsonb),
  (2026, 7, 13, 'RBG SC', 'RK SC', 1, 3, null::int, null::int, 'final', 'bq5I3BMnh-E', '[{"s":2017,"t":2042,"team":"RK SC","score":"0–1"},{"s":3412,"t":3436,"team":"RK SC","score":"0–2"},{"s":3750,"t":3775,"team":"RK SC","score":"0–3"},{"s":4258,"t":4293,"team":"RBG SC","score":"1–3"}]'::jsonb)
) v(year, day, no, home, away, home_score, away_score, pen_home, pen_away, stage, video, goals)
where not exists (select 1 from public.matches m where m.year = 2026);

-- 2025
insert into public.seasons (year, champion, champion_dv, partial) values (2025, 'Afiyns Sports Club', 'އަފީންސް ސްޕޯޓްސް ކްލަބް', false)
  on conflict (year) do nothing;
insert into public.matches (year, day, no, home, away, home_score, away_score, pen_home, pen_away, stage, video, goals)
select * from (values
  (2025, 1, 1, 'KK Kandumathi', 'RK SC', 7, 2, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 1, 2, 'Afiyns SC', 'FC Mathiveri', 9, 0, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 2, 3, 'Old Stars', 'KK Kandumathi', 3, 0, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 2, 4, 'RK SC', 'Afiyns SC', 5, 5, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 3, 5, 'Old Stars', 'FC Mathiveri', 6, 0, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 3, 6, 'Afiyns SC', 'KK Kandumathi', 7, 2, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 4, 7, 'RK SC', 'Old Stars', 10, 3, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 4, 8, 'FC Mathiveri', 'KK Kandumathi', 2, 10, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 5, 9, 'Afiyns SC', 'Old Stars', 4, 2, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 5, 10, 'RK SC', 'FC Mathiveri', 12, 3, null::int, null::int, null::text, null::text, '[]'::jsonb),
  (2025, 6, 11, 'KK Kandumathi', 'RK SC', 4, 2, null::int, null::int, 'playoff', null::text, '[]'::jsonb),
  (2025, 7, 12, 'Afiyns SC', 'KK Kandumathi', 4, 3, null::int, null::int, 'final', null::text, '[]'::jsonb)
) v(year, day, no, home, away, home_score, away_score, pen_home, pen_away, stage, video, goals)
where not exists (select 1 from public.matches m where m.year = 2025);

-- 2027 TEST fixtures (upcoming, no score yet) so the website's Fixtures section can be tried out.
-- Edit or delete them in the organiser portal: Fixtures & Results → season 2027.
insert into public.seasons (year) values (2027) on conflict (year) do nothing;
insert into public.matches (year, day, no, home, away, kickoff, stage)
select * from (values
  (2027, 1, 1, 'RK SC',       'BHC',           '2026-11-05 20:45+05'::timestamptz, null::text),
  (2027, 1, 2, 'RBG SC',      'Stelco SC',     '2026-11-05 21:45+05'::timestamptz, null::text),
  (2027, 2, 3, 'FT Nakasole', 'Afiyns SC',     '2026-11-06 20:45+05'::timestamptz, null::text),
  (2027, 2, 4, 'Old Stars',   'KK Kandumathi', '2026-11-06 21:45+05'::timestamptz, null::text),
  (2027, 3, 5, 'RBG SC',      'RK SC',         '2026-11-08 21:00+05'::timestamptz, 'final')
) v(year, day, no, home, away, kickoff, stage)
where not exists (select 1 from public.matches m where m.year = 2027);
