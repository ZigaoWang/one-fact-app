-- Insert facts for Fun Facts category
INSERT INTO facts (content, category, source, active, display_date) VALUES
('A day on Venus is longer than its year. Venus takes 243 Earth days to rotate on its axis but only 225 Earth days to orbit the Sun.', 'Fun Facts', 'NASA', true, '2025-01-24'),
('The shortest war in history was between Britain and Zanzibar on August 27, 1896. Zanzibar surrendered after just 38 minutes.', 'Fun Facts', 'Guinness World Records', true, '2025-01-25'),
('Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.', 'Fun Facts', 'National Geographic', true, '2025-01-26');

-- Insert facts for History category
INSERT INTO facts (content, category, source, active, display_date) VALUES
('The Great Wall of China is not visible from space with the naked eye, contrary to popular belief.', 'History', 'NASA', true, '2025-01-24'),
('Cleopatra lived closer in time to the first Pizza Hut opening than to the building of the Great Pyramids.', 'History', 'Historical Archives', true, '2025-01-25'),
('The first Olympic Games were held in 776 BCE in Olympia, Greece.', 'History', 'Olympic Committee Archives', true, '2025-01-26');

-- Insert facts for Space category
INSERT INTO facts (content, category, source, active, display_date) VALUES
('There is a planet made of diamonds twice the size of Earth. The planet, 55 Cancri e, is likely covered in graphite and diamond.', 'Space', 'NASA', true, '2025-01-24'),
('A year on Mercury is just 88 Earth days long.', 'Space', 'Space.com', true, '2025-01-25'),
('The largest known star, UY Scuti, is so big that it would take 1,700 years for a passenger jet to fly around it.', 'Space', 'Astronomy Magazine', true, '2025-01-26');

-- Insert related articles
INSERT INTO related_articles (fact_id, title, url, source, snippet) VALUES
((SELECT id FROM facts WHERE content LIKE '%Venus%'), 'Venus Day Length', 'https://science.nasa.gov/venus', 'NASA', 'Why Venus has such a long day'),
((SELECT id FROM facts WHERE content LIKE '%shortest war%'), 'Anglo-Zanzibar War', 'https://www.history.com/shortest-war', 'History.com', 'The story of the shortest recorded war'),
((SELECT id FROM facts WHERE content LIKE '%Honey never%'), 'Ancient Egyptian Honey', 'https://www.natgeo.com/honey', 'National Geographic', 'The incredible preservation properties of honey'),
((SELECT id FROM facts WHERE content LIKE '%Great Wall%'), 'Great Wall Myths', 'https://www.nasa.gov/great-wall', 'NASA', 'Common myths about the Great Wall of China'),
((SELECT id FROM facts WHERE content LIKE '%Cleopatra%'), 'Timeline of Ancient Egypt', 'https://www.history.com/cleopatra', 'History.com', 'The fascinating timeline of ancient Egyptian history'),
((SELECT id FROM facts WHERE content LIKE '%Olympic Games%'), 'First Olympics', 'https://olympics.com/history', 'Olympic Committee', 'The origin of the Olympic Games'),
((SELECT id FROM facts WHERE content LIKE '%diamonds%'), 'Diamond Planet', 'https://www.nasa.gov/55-cancri-e', 'NASA', 'The incredible diamond planet 55 Cancri e'),
((SELECT id FROM facts WHERE content LIKE '%Mercury%'), 'Mercury Facts', 'https://www.space.com/mercury', 'Space.com', 'Why Mercury has such a short year'),
((SELECT id FROM facts WHERE content LIKE '%UY Scuti%'), 'Largest Stars', 'https://www.astronomy.com/stars', 'Astronomy Magazine', 'The largest known stars in our universe');
