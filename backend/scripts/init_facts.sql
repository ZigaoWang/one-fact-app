-- Start a transaction
BEGIN;

-- Insert Science Facts if they don't exist
INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The speed of light in a vacuum is exactly 299,792,458 meters per second.', 'Science', 'Physics Facts', CURRENT_DATE, true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%speed of light%' AND category = 'Science'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'DNA, which contains our genetic code, is a double helix structure first described by Watson and Crick in 1953.', 'Science', 'Biology Facts', CURRENT_DATE + INTERVAL '1 day', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%DNA%' AND category = 'Science'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The human brain contains approximately 86 billion neurons.', 'Science', 'Neuroscience Facts', CURRENT_DATE + INTERVAL '2 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%human brain%' AND category = 'Science'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'Quantum entanglement allows particles to be connected regardless of distance, a phenomenon Einstein called "spooky action at a distance."', 'Science', 'Quantum Physics Facts', CURRENT_DATE + INTERVAL '3 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Quantum entanglement%' AND category = 'Science'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The Milky Way galaxy contains an estimated 100-400 billion stars.', 'Science', 'Astronomy Facts', CURRENT_DATE + INTERVAL '4 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Milky Way%' AND category = 'Science'
);

-- Insert History Facts if they don't exist
INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The Great Wall of China construction began over 2,000 years ago during the Spring and Autumn Period.', 'History', 'Ancient History Facts', CURRENT_DATE, true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Great Wall of China%' AND category = 'History'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The printing press was invented by Johannes Gutenberg around 1440, revolutionizing communication.', 'History', 'Medieval History Facts', CURRENT_DATE + INTERVAL '1 day', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%printing press%' AND category = 'History'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The first successful powered flight was achieved by the Wright brothers on December 17, 1903.', 'History', 'Modern History Facts', CURRENT_DATE + INTERVAL '2 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Wright brothers%' AND category = 'History'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The Internet was created in 1969 as ARPANET by the US Department of Defense.', 'History', 'Technology History Facts', CURRENT_DATE + INTERVAL '3 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Internet%' AND category = 'History'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The first human to walk on the moon was Neil Armstrong on July 20, 1969.', 'History', 'Space History Facts', CURRENT_DATE + INTERVAL '4 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%first human to walk on the moon%' AND category = 'History'
);

-- Insert Space Facts if they don't exist
INSERT INTO facts (content, category, source, display_date, active)
SELECT 'Mars has two moons: Phobos and Deimos.', 'Space', 'Planetary Facts', CURRENT_DATE, true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Mars has two moons%' AND category = 'Space'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'A day on Venus is longer than its year. It takes Venus 243 Earth days to rotate on its axis.', 'Space', 'Solar System Facts', CURRENT_DATE + INTERVAL '1 day', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Venus%' AND category = 'Space'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'Black holes are regions of spacetime where gravity is so strong that nothing can escape from them.', 'Space', 'Astronomy Facts', CURRENT_DATE + INTERVAL '2 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Black holes%' AND category = 'Space'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The Sun loses about 4 million tons of mass every second due to nuclear fusion.', 'Space', 'Solar Facts', CURRENT_DATE + INTERVAL '3 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%Sun loses%' AND category = 'Space'
);

INSERT INTO facts (content, category, source, display_date, active)
SELECT 'The nearest star system to Earth is Alpha Centauri, about 4.37 light-years away.', 'Space', 'Stellar Facts', CURRENT_DATE + INTERVAL '4 days', true
WHERE NOT EXISTS (
    SELECT 1 FROM facts WHERE content LIKE '%nearest star system%' AND category = 'Space'
);

-- Insert Related Articles if they don't exist
INSERT INTO related_articles (fact_id, title, url, source, snippet)
SELECT f.id, 'Speed of Light - Wikipedia', 'https://en.wikipedia.org/wiki/Speed_of_light', 'Wikipedia', 'Comprehensive article about the speed of light and its significance in physics.'
FROM facts f
WHERE f.content LIKE '%speed of light%'
AND NOT EXISTS (
    SELECT 1 FROM related_articles ra WHERE ra.fact_id = f.id
);

INSERT INTO related_articles (fact_id, title, url, source, snippet)
SELECT f.id, 'DNA Structure and Function', 'https://www.nature.com/scitable/topic/dna-structure-and-function-14122428/', 'Nature', 'Detailed explanation of DNA structure and its role in genetics.'
FROM facts f
WHERE f.content LIKE '%DNA%'
AND NOT EXISTS (
    SELECT 1 FROM related_articles ra WHERE ra.fact_id = f.id
);

INSERT INTO related_articles (fact_id, title, url, source, snippet)
SELECT f.id, 'Great Wall of China - UNESCO', 'https://whc.unesco.org/en/list/438/', 'UNESCO', 'Official UNESCO World Heritage listing for the Great Wall of China.'
FROM facts f
WHERE f.content LIKE '%Great Wall of China%'
AND NOT EXISTS (
    SELECT 1 FROM related_articles ra WHERE ra.fact_id = f.id
);

INSERT INTO related_articles (fact_id, title, url, source, snippet)
SELECT f.id, 'Mars Moons - NASA', 'https://solarsystem.nasa.gov/moons/mars-moons/overview/', 'NASA', 'NASA''s comprehensive guide to Mars'' moons Phobos and Deimos.'
FROM facts f
WHERE f.content LIKE '%Mars has two moons%'
AND NOT EXISTS (
    SELECT 1 FROM related_articles ra WHERE ra.fact_id = f.id
);

-- Commit the transaction
COMMIT;
